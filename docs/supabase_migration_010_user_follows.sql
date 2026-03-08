-- Holistia – Migración 010: seguir usuarios (seguidores / siguiendo)
-- Ejecutar después de la migración 001 (profiles).

-- ========== 1. Tabla user_follows ==========
CREATE TABLE IF NOT EXISTS public.user_follows (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  follower_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  following_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT user_follows_no_self CHECK (follower_id != following_id),
  UNIQUE(follower_id, following_id)
);

CREATE INDEX IF NOT EXISTS idx_user_follows_follower ON public.user_follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_user_follows_following ON public.user_follows(following_id);

ALTER TABLE public.user_follows ENABLE ROW LEVEL SECURITY;

-- Usuarios autenticados pueden ver relaciones de seguimiento (para contar y mostrar "siguiendo")
CREATE POLICY "Ver follows si autenticado"
  ON public.user_follows FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- Solo el usuario autenticado puede seguir (como follower_id)
CREATE POLICY "Seguir como yo"
  ON public.user_follows FOR INSERT
  WITH CHECK (follower_id = auth.uid());

-- Solo el usuario puede dejar de seguir (borrar su propia fila)
CREATE POLICY "Dejar de seguir"
  ON public.user_follows FOR DELETE
  USING (follower_id = auth.uid());
