-- Migration 021: Asociar retos con aspectos de la Rueda de Vida
-- Ejecutar en Supabase > SQL Editor

ALTER TABLE public.challenges
  ADD COLUMN IF NOT EXISTS life_aspect TEXT
  CHECK (life_aspect IN ('personal','fisico','laboral','familiar','pareja','alimentacion','social','dinero'));

-- Índice para consultas de filtrado por aspecto
CREATE INDEX IF NOT EXISTS idx_challenges_life_aspect
  ON public.challenges(life_aspect)
  WHERE life_aspect IS NOT NULL;
