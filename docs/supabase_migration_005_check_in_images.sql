-- Holistia – Migración 005: imágenes en check-ins
-- Ejecutar después de la migración 004.

ALTER TABLE public.check_ins ADD COLUMN IF NOT EXISTS image_url TEXT;
