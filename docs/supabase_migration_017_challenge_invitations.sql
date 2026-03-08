-- Holistia – Migración 017: invitaciones a retos
-- Ejecutar después de las migraciones anteriores en el editor SQL de Supabase.

-- ============================================================
-- 1. Ampliar el CHECK de tipo en la tabla notifications
-- ============================================================
ALTER TABLE public.notifications
  DROP CONSTRAINT IF EXISTS notifications_type_check;

ALTER TABLE public.notifications
  ADD CONSTRAINT notifications_type_check
    CHECK (type IN (
      'follow',
      'comment',
      'zenit',
      'daily_reminder',
      'challenge_invitation'
    ));

-- ============================================================
-- 2. Tabla challenge_invitations
-- ============================================================
CREATE TABLE IF NOT EXISTS public.challenge_invitations (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge_id UUID        NOT NULL REFERENCES public.challenges(id)  ON DELETE CASCADE,
  inviter_id   UUID        NOT NULL REFERENCES auth.users(id)         ON DELETE CASCADE,
  invitee_id   UUID        NOT NULL REFERENCES auth.users(id)         ON DELETE CASCADE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT challenge_invitations_unique
    UNIQUE (challenge_id, inviter_id, invitee_id),

  CONSTRAINT challenge_invitations_no_self
    CHECK (inviter_id != invitee_id)
);

CREATE INDEX IF NOT EXISTS idx_challenge_invitations_challenge
  ON public.challenge_invitations(challenge_id);

CREATE INDEX IF NOT EXISTS idx_challenge_invitations_inviter
  ON public.challenge_invitations(challenge_id, inviter_id);

CREATE INDEX IF NOT EXISTS idx_challenge_invitations_invitee
  ON public.challenge_invitations(invitee_id);

ALTER TABLE public.challenge_invitations ENABLE ROW LEVEL SECURITY;

-- Solo el invitante o el invitado pueden ver sus filas
CREATE POLICY "Ver invitaciones propias"
  ON public.challenge_invitations FOR SELECT
  USING (inviter_id = auth.uid() OR invitee_id = auth.uid());

-- Solo el RPC (SECURITY DEFINER) puede insertar
CREATE POLICY "Sistema inserta invitaciones"
  ON public.challenge_invitations FOR INSERT
  WITH CHECK (true);

-- ============================================================
-- 3. RPC invite_to_challenge
--    Límite: 8 invitaciones por (challenge_id, inviter_id).
--    Crea notificación en-app para el invitado.
--    PushNotificationService en Flutter la recoge vía Realtime.
-- ============================================================
CREATE OR REPLACE FUNCTION public.invite_to_challenge(
  p_challenge_id UUID,
  p_invitee_id   UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_inviter_id     UUID;
  v_inviter_name   TEXT;
  v_challenge_name TEXT;
  v_invite_count   INT;
BEGIN
  v_inviter_id := auth.uid();

  IF v_inviter_id IS NULL THEN
    RAISE EXCEPTION 'No autenticado';
  END IF;

  IF v_inviter_id = p_invitee_id THEN
    RAISE EXCEPTION 'No puedes invitarte a ti mismo';
  END IF;

  -- Verificar límite de 8 por (reto, invitante)
  SELECT COUNT(*) INTO v_invite_count
  FROM public.challenge_invitations
  WHERE challenge_id = p_challenge_id
    AND inviter_id   = v_inviter_id;

  IF v_invite_count >= 8 THEN
    RAISE EXCEPTION 'Límite de 8 invitaciones alcanzado para este reto';
  END IF;

  -- Insertar invitación (UNIQUE evita duplicados silenciosamente)
  INSERT INTO public.challenge_invitations (challenge_id, inviter_id, invitee_id)
  VALUES (p_challenge_id, v_inviter_id, p_invitee_id)
  ON CONFLICT (challenge_id, inviter_id, invitee_id) DO NOTHING;

  -- Solo crear notificación si se insertó (evitar spam en re-invitaciones)
  IF NOT FOUND THEN
    RETURN;
  END IF;

  SELECT display_name INTO v_inviter_name
  FROM public.profiles WHERE id = v_inviter_id;

  SELECT name INTO v_challenge_name
  FROM public.challenges WHERE id = p_challenge_id;

  PERFORM public.create_notification(
    p_user_id             := p_invitee_id,
    p_type                := 'challenge_invitation',
    p_title               := '¡Te invitaron a un reto!',
    p_body                := COALESCE(v_inviter_name, 'Alguien')
                             || ' te invitó al reto "'
                             || COALESCE(v_challenge_name, 'Sin nombre')
                             || '"',
    p_related_user_id     := v_inviter_id,
    p_related_challenge_id := p_challenge_id
  );
END;
$$;
