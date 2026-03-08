-- Holistia – Migración inicial
-- Ejecutar en el SQL Editor de Supabase (proyecto creado) en este orden.

-- ========== 1. Enums ==========
CREATE TYPE challenge_type AS ENUM (
  'streak',
  'count_times',
  'count_units'
);

CREATE TYPE challenge_frequency AS ENUM (
  'daily',
  'weekly',
  'monthly'
);

-- ========== 2. Profiles ==========
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT,
  avatar_url TEXT,
  is_public BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, display_name)
  VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'display_name', NEW.email));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Perfiles publicos visibles cuando is_public o propio"
  ON public.profiles FOR SELECT
  USING (is_public = true OR id = auth.uid());

CREATE POLICY "Usuario actualiza su propio perfil"
  ON public.profiles FOR UPDATE
  USING (id = auth.uid());

-- ========== 3. Challenges ==========
CREATE TABLE public.challenges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  type challenge_type NOT NULL,
  target NUMERIC NOT NULL CHECK (target > 0),
  unit TEXT,
  frequency challenge_frequency,
  is_public BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT frequency_for_count_times
    CHECK (type != 'count_times' OR frequency IS NOT NULL)
);

CREATE INDEX idx_challenges_user_id ON public.challenges(user_id);
CREATE INDEX idx_challenges_is_public ON public.challenges(is_public) WHERE is_public = true;

ALTER TABLE public.challenges ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Usuario gestiona sus retos"
  ON public.challenges FOR ALL
  USING (user_id = auth.uid());

CREATE POLICY "Retos publicos visibles por todos"
  ON public.challenges FOR SELECT
  USING (is_public = true);

-- ========== 4. Check-ins ==========
CREATE TABLE public.check_ins (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge_id UUID NOT NULL REFERENCES public.challenges(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  value NUMERIC,
  note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(challenge_id, date)
);

CREATE INDEX idx_check_ins_challenge_id ON public.check_ins(challenge_id);
CREATE INDEX idx_check_ins_user_id ON public.check_ins(user_id);
CREATE INDEX idx_check_ins_date ON public.check_ins(date);

ALTER TABLE public.check_ins ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Usuario gestiona sus check-ins"
  ON public.check_ins FOR ALL
  USING (user_id = auth.uid());

CREATE POLICY "Check-ins de retos publicos visibles"
  ON public.check_ins FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.challenges c
      WHERE c.id = check_ins.challenge_id AND c.is_public = true
    )
  );

-- ========== 5. Posts ==========
CREATE TABLE public.posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  challenge_id UUID NOT NULL REFERENCES public.challenges(id) ON DELETE CASCADE,
  check_in_id UUID REFERENCES public.check_ins(id) ON DELETE SET NULL,
  body TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_posts_user_id ON public.posts(user_id);
CREATE INDEX idx_posts_challenge_id ON public.posts(challenge_id);
CREATE INDEX idx_posts_created_at ON public.posts(created_at DESC);

ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Usuario gestiona sus posts"
  ON public.posts FOR ALL
  USING (user_id = auth.uid());

CREATE POLICY "Posts de retos publicos visibles"
  ON public.posts FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.challenges c
      WHERE c.id = posts.challenge_id AND c.is_public = true
    )
  );

-- ========== 6. Zenits ==========
CREATE TABLE public.zenits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  from_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(from_user_id, post_id)
);

CREATE INDEX idx_zenits_post_id ON public.zenits(post_id);
CREATE INDEX idx_zenits_from_user_id ON public.zenits(from_user_id);

ALTER TABLE public.zenits ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Usuario gestiona sus zenits"
  ON public.zenits FOR ALL
  USING (from_user_id = auth.uid());

CREATE POLICY "Zenits visibles para contador"
  ON public.zenits FOR SELECT
  USING (true);

-- ========== 7. Vista feed (opcional) ==========
CREATE OR REPLACE VIEW public.posts_with_zenit_count AS
SELECT
  p.*,
  COALESCE(z.cnt, 0)::int AS zenit_count
FROM public.posts p
LEFT JOIN (
  SELECT post_id, COUNT(*) AS cnt
  FROM public.zenits
  GROUP BY post_id
) z ON z.post_id = p.id
ORDER BY p.created_at DESC;
