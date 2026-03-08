-- Añadir campo objetivo (descripción) a los retos.
ALTER TABLE public.challenges
  ADD COLUMN IF NOT EXISTS objective TEXT;

COMMENT ON COLUMN public.challenges.objective IS 'Objetivo o descripción del reto escrita por el usuario';
