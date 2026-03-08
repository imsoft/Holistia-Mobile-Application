-- Holistia – Migración 023: hardening de seguridad (RLS + funciones)
-- Ejecutar en SQL Editor de Supabase.

-- ============================================================
-- 1) notifications: bloquear inserts directos desde cliente
-- ============================================================
DROP POLICY IF EXISTS "Sistema crea notificaciones" ON public.notifications;
CREATE POLICY "No direct insert notifications"
  ON public.notifications FOR INSERT
  WITH CHECK (false);

-- ============================================================
-- 2) challenge_invitations: bloquear inserts directos
--    (usar solo RPC invite_to_challenge)
-- ============================================================
DROP POLICY IF EXISTS "Sistema inserta invitaciones" ON public.challenge_invitations;
CREATE POLICY "No direct insert challenge_invitations"
  ON public.challenge_invitations FOR INSERT
  WITH CHECK (false);

-- ============================================================
-- 3) expert_requests: bloquear insert/update directos
--    (usar solo RPCs submit/review)
-- ============================================================
DROP POLICY IF EXISTS "System insert expert_requests" ON public.expert_requests;
CREATE POLICY "No direct insert expert_requests"
  ON public.expert_requests FOR INSERT
  WITH CHECK (false);

DROP POLICY IF EXISTS "System update expert_requests" ON public.expert_requests;
CREATE POLICY "No direct update expert_requests"
  ON public.expert_requests FOR UPDATE
  USING (false)
  WITH CHECK (false);

-- ============================================================
-- 4) create_notification: restringir ejecución pública
-- ============================================================
REVOKE ALL ON FUNCTION public.create_notification(UUID, TEXT, TEXT, TEXT, UUID, UUID, UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.create_notification(UUID, TEXT, TEXT, TEXT, UUID, UUID, UUID) FROM authenticated;
GRANT EXECUTE ON FUNCTION public.create_notification(UUID, TEXT, TEXT, TEXT, UUID, UUID, UUID) TO service_role;
