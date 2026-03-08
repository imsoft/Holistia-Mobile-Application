-- Holistia – Migración 002: comentarios, imágenes en posts
-- Ejecutar después de la migración 001.

-- ========== 1. Añadir imagen a posts ==========
ALTER TABLE public.posts ADD COLUMN IF NOT EXISTS image_url TEXT;

-- ========== 2. Tabla post_comments ==========
CREATE TABLE IF NOT EXISTS public.post_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  body TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_post_comments_post_id ON public.post_comments(post_id);
CREATE INDEX IF NOT EXISTS idx_post_comments_user_id ON public.post_comments(user_id);

ALTER TABLE public.post_comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Comentarios visibles en posts publicos"
  ON public.post_comments FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.posts p
      JOIN public.challenges c ON c.id = p.challenge_id
      WHERE p.id = post_comments.post_id AND c.is_public = true
    )
  );

CREATE POLICY "Usuario crea sus comentarios"
  ON public.post_comments FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Usuario elimina sus comentarios"
  ON public.post_comments FOR DELETE
  USING (user_id = auth.uid());

-- ========== 3. Actualizar vista feed (incluir comment_count) ==========
-- DROP necesario porque la estructura de columnas cambió (image_url en posts)
DROP VIEW IF EXISTS public.posts_with_zenit_count;

CREATE VIEW public.posts_with_zenit_count AS
SELECT
  p.*,
  COALESCE(z.cnt, 0)::int AS zenit_count,
  COALESCE(c.cnt, 0)::int AS comment_count
FROM public.posts p
LEFT JOIN (
  SELECT post_id, COUNT(*) AS cnt FROM public.zenits GROUP BY post_id
) z ON z.post_id = p.id
LEFT JOIN (
  SELECT post_id, COUNT(*) AS cnt FROM public.post_comments GROUP BY post_id
) c ON c.post_id = p.id
ORDER BY p.created_at DESC;

-- ========== 4. Bucket y políticas de Storage ==========
-- Crea el bucket "post-images" en Supabase Dashboard:
-- Storage → New bucket → id: post-images, Public: sí, File size limit: 5MB,
-- Allowed MIME types: image/jpeg, image/png, image/webp
--
-- Políticas (ejecutar después de crear el bucket):
