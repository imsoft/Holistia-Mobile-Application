-- Holistia – Migración 024: corregir constraint unique en check_ins
-- Ejecutar en SQL Editor de Supabase.

-- El constraint inicial UNIQUE(challenge_id, date) colisiona entre usuarios.
-- La unicidad correcta es por reto + usuario + día.

ALTER TABLE public.check_ins
  DROP CONSTRAINT IF EXISTS check_ins_challenge_id_date_key;

ALTER TABLE public.check_ins
  ADD CONSTRAINT check_ins_unique_user_day
  UNIQUE (challenge_id, user_id, date);
