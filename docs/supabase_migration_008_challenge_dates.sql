-- Holistia – Migración 008: fechas de inicio y fin para retos
-- Añade start_date y end_date a la tabla challenges

-- ========== 1. Añadir columnas ==========
ALTER TABLE challenges
  ADD COLUMN IF NOT EXISTS start_date DATE,
  ADD COLUMN IF NOT EXISTS end_date DATE;

-- ========== 2. Establecer start_date para retos existentes ==========
-- Para retos existentes, usar created_at como start_date
UPDATE challenges
SET start_date = created_at::date
WHERE start_date IS NULL;

-- ========== 3. Comentarios ==========
COMMENT ON COLUMN challenges.start_date IS 'Fecha de inicio del reto (se establece automáticamente al crear)';
COMMENT ON COLUMN challenges.end_date IS 'Fecha de fin del reto (opcional, establecida por el usuario)';
