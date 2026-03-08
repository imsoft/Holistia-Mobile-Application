-- Holistia – Migración 018: sistema de roles (user / expert / admin)
-- Ejecutar después de las migraciones anteriores en el editor SQL de Supabase.

-- ============================================================
-- 1. Columna role en profiles
-- ============================================================
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS role TEXT NOT NULL DEFAULT 'user'
    CHECK (role IN ('user', 'expert', 'admin'));

-- ============================================================
-- 2. Tabla expert_requests
-- ============================================================
CREATE TABLE IF NOT EXISTS public.expert_requests (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  bio         TEXT        NOT NULL,
  status      TEXT        NOT NULL DEFAULT 'pending'
                CHECK (status IN ('pending', 'approved', 'rejected')),
  reviewed_by UUID        REFERENCES auth.users(id) ON DELETE SET NULL,
  reviewed_at TIMESTAMPTZ,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT expert_requests_one_per_user UNIQUE (user_id)
);

CREATE INDEX IF NOT EXISTS idx_expert_requests_status
  ON public.expert_requests(status);
CREATE INDEX IF NOT EXISTS idx_expert_requests_user
  ON public.expert_requests(user_id);

ALTER TABLE public.expert_requests ENABLE ROW LEVEL SECURITY;

-- El propio usuario ve su solicitud
CREATE POLICY "User sees own request"
  ON public.expert_requests FOR SELECT
  USING (user_id = auth.uid());

-- El admin ve todas las solicitudes
CREATE POLICY "Admin sees all requests"
  ON public.expert_requests FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Solo RPCs SECURITY DEFINER pueden insertar/actualizar
CREATE POLICY "System insert expert_requests"
  ON public.expert_requests FOR INSERT
  WITH CHECK (true);

CREATE POLICY "System update expert_requests"
  ON public.expert_requests FOR UPDATE
  USING (true);

-- ============================================================
-- 3. Columna is_expert_challenge en challenges
-- ============================================================
ALTER TABLE public.challenges
  ADD COLUMN IF NOT EXISTS is_expert_challenge BOOLEAN NOT NULL DEFAULT false;

-- ============================================================
-- 4. Tabla challenge_participants (para retos de expertos)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.challenge_participants (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge_id UUID        NOT NULL REFERENCES public.challenges(id) ON DELETE CASCADE,
  user_id      UUID        NOT NULL REFERENCES auth.users(id)        ON DELETE CASCADE,
  joined_at    TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT challenge_participants_unique UNIQUE (challenge_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_challenge_participants_challenge
  ON public.challenge_participants(challenge_id);
CREATE INDEX IF NOT EXISTS idx_challenge_participants_user
  ON public.challenge_participants(user_id);

ALTER TABLE public.challenge_participants ENABLE ROW LEVEL SECURITY;

-- El participante y el dueño del reto pueden ver los participantes
CREATE POLICY "Participant or owner can view"
  ON public.challenge_participants FOR SELECT
  USING (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.challenges c
      WHERE c.id = challenge_id AND c.user_id = auth.uid()
    )
  );

CREATE POLICY "System insert participants"
  ON public.challenge_participants FOR INSERT
  WITH CHECK (true);

-- ============================================================
-- 5. Nuevos tipos de notificación
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
      'challenge_invitation',
      'expert_approved',
      'expert_rejected'
    ));

-- ============================================================
-- 6. RPC: submit_expert_request
-- ============================================================
CREATE OR REPLACE FUNCTION public.submit_expert_request(p_bio TEXT)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id        UUID;
  v_request_id     UUID;
  v_existing_status TEXT;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'No autenticado';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.profiles WHERE id = v_user_id AND role = 'expert'
  ) THEN
    RAISE EXCEPTION 'Ya eres experto';
  END IF;

  SELECT status INTO v_existing_status
  FROM public.expert_requests WHERE user_id = v_user_id;

  IF v_existing_status = 'pending' THEN
    RAISE EXCEPTION 'Ya tienes una solicitud pendiente';
  END IF;

  -- Permite reenviar tras un rechazo
  INSERT INTO public.expert_requests (user_id, bio, status, reviewed_by, reviewed_at)
  VALUES (v_user_id, p_bio, 'pending', NULL, NULL)
  ON CONFLICT (user_id) DO UPDATE
    SET bio         = EXCLUDED.bio,
        status      = 'pending',
        reviewed_by = NULL,
        reviewed_at = NULL,
        created_at  = now()
  RETURNING id INTO v_request_id;

  RETURN v_request_id;
END;
$$;

-- ============================================================
-- 7. RPC: review_expert_request (solo admin)
-- ============================================================
CREATE OR REPLACE FUNCTION public.review_expert_request(
  p_request_id UUID,
  p_approved   BOOLEAN
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_admin_id UUID;
  v_user_id  UUID;
BEGIN
  v_admin_id := auth.uid();

  IF NOT EXISTS (
    SELECT 1 FROM public.profiles WHERE id = v_admin_id AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'No autorizado';
  END IF;

  SELECT user_id INTO v_user_id
  FROM public.expert_requests
  WHERE id = p_request_id AND status = 'pending';

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Solicitud no encontrada o ya procesada';
  END IF;

  UPDATE public.expert_requests
  SET status      = CASE WHEN p_approved THEN 'approved' ELSE 'rejected' END,
      reviewed_by = v_admin_id,
      reviewed_at = now()
  WHERE id = p_request_id;

  IF p_approved THEN
    UPDATE public.profiles SET role = 'expert' WHERE id = v_user_id;
  END IF;

  PERFORM public.create_notification(
    p_user_id         := v_user_id,
    p_type            := CASE WHEN p_approved THEN 'expert_approved' ELSE 'expert_rejected' END,
    p_title           := CASE WHEN p_approved
                           THEN '¡Felicidades! Eres Experto'
                           ELSE 'Solicitud de Experto revisada'
                         END,
    p_body            := CASE WHEN p_approved
                           THEN 'Tu solicitud fue aprobada. Ya puedes crear retos para otros usuarios.'
                           ELSE 'Tu solicitud no fue aprobada en esta ocasión. Puedes volver a intentarlo.'
                         END,
    p_related_user_id := v_admin_id
  );
END;
$$;
