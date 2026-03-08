-- Añadir nombre de usuario único a perfiles.
-- Los usuarios eligen su @username (único, 3–30 caracteres, solo letras, números y guión bajo).

-- Columna username: único, nullable para perfiles ya existentes.
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS username TEXT;

-- Índice único (case-insensitive: guardamos en minúsculas desde la app).
CREATE UNIQUE INDEX IF NOT EXISTS idx_profiles_username_lower
  ON public.profiles (LOWER(username))
  WHERE username IS NOT NULL;

-- Restricción: solo caracteres válidos y longitud (opcional, la app también valida).
ALTER TABLE public.profiles
  DROP CONSTRAINT IF EXISTS chk_username_format;

ALTER TABLE public.profiles
  ADD CONSTRAINT chk_username_format
  CHECK (
    username IS NULL
    OR (
      length(username) >= 3
      AND length(username) <= 30
      AND username ~ '^[a-z0-9_]+$'
    )
  );

-- Comentario para documentar.
COMMENT ON COLUMN public.profiles.username IS 'Nombre de usuario único (@username): 3-30 caracteres, solo minúsculas, números y _';

-- Función para comprobar si un username está disponible (llamable sin auth o con anon).
CREATE OR REPLACE FUNCTION public.check_username_available(wanted_username TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF wanted_username IS NULL OR length(trim(lower(wanted_username))) < 3 THEN
    RETURN false;
  END IF;
  RETURN NOT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE lower(trim(username)) = lower(trim(wanted_username))
  );
END;
$$;
