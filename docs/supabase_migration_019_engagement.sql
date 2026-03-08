-- Holistia – Migración 019: engagement features
-- Ejecutar en el editor SQL de Supabase.

-- ============================================================
-- 1. Categorías en retos
-- ============================================================
ALTER TABLE public.challenges
  ADD COLUMN IF NOT EXISTS category TEXT NOT NULL DEFAULT 'otro';

ALTER TABLE public.challenges
  DROP CONSTRAINT IF EXISTS challenges_category_check;

ALTER TABLE public.challenges
  ADD CONSTRAINT challenges_category_check
    CHECK (category IN ('salud','mente','deporte','social','creativo','otro'));

-- ============================================================
-- 2. Retos destacados (is_featured)
-- ============================================================
ALTER TABLE public.challenges
  ADD COLUMN IF NOT EXISTS is_featured BOOLEAN NOT NULL DEFAULT false;

CREATE INDEX IF NOT EXISTS idx_challenges_is_featured
  ON public.challenges(is_featured) WHERE is_featured = true;

-- ============================================================
-- 3. Tabla de reacciones en posts (🔥 💪 ⭐ 🙌)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.post_reactions (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id    UUID        NOT NULL REFERENCES public.posts(id)  ON DELETE CASCADE,
  user_id    UUID        NOT NULL REFERENCES auth.users(id)    ON DELETE CASCADE,
  emoji      TEXT        NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT post_reactions_unique UNIQUE (post_id, user_id, emoji),
  CONSTRAINT post_reactions_emoji_check CHECK (emoji IN ('🔥','💪','⭐','🙌'))
);

CREATE INDEX IF NOT EXISTS idx_post_reactions_post
  ON public.post_reactions(post_id);

CREATE INDEX IF NOT EXISTS idx_post_reactions_user
  ON public.post_reactions(user_id);

ALTER TABLE public.post_reactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Ver reacciones"
  ON public.post_reactions FOR SELECT
  USING (true);

CREATE POLICY "Insertar reacción propia"
  ON public.post_reactions FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Eliminar reacción propia"
  ON public.post_reactions FOR DELETE
  USING (user_id = auth.uid());
