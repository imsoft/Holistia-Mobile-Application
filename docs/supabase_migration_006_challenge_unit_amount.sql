-- Holistia – Migración 006: cantidad por día/sesión
-- Ejecutar después de la migración 005.

ALTER TABLE public.challenges ADD COLUMN IF NOT EXISTS unit_amount NUMERIC;
