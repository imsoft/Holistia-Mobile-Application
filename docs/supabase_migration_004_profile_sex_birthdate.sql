-- Holistia – Migración 004: sexo y fecha de nacimiento en perfiles
-- Ejecutar después de la migración 003.

ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS sex TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS birth_date DATE;
