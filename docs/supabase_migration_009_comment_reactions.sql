-- Holistia – Migración 009: reacciones de corazón en comentarios
-- Ejecutar después de la migración 002 (post_comments).

-- ========== 1. Tabla comment_reactions ==========
CREATE TABLE IF NOT EXISTS public.comment_reactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  comment_id UUID NOT NULL REFERENCES public.post_comments(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(comment_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_comment_reactions_comment_id ON public.comment_reactions(comment_id);
CREATE INDEX IF NOT EXISTS idx_comment_reactions_user_id ON public.comment_reactions(user_id);

ALTER TABLE public.comment_reactions ENABLE ROW LEVEL SECURITY;

-- Ver reacciones en comentarios de posts públicos
CREATE POLICY "Reacciones visibles en comentarios de posts publicos"
  ON public.comment_reactions FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.post_comments pc
      JOIN public.posts p ON p.id = pc.post_id
      JOIN public.challenges c ON c.id = p.challenge_id
      WHERE pc.id = comment_reactions.comment_id AND c.is_public = true
    )
  );

-- Cualquier usuario autenticado puede añadir o quitar su reacción
CREATE POLICY "Usuario inserta su reaccion"
  ON public.comment_reactions FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Usuario elimina su reaccion"
  ON public.comment_reactions FOR DELETE
  USING (user_id = auth.uid());
