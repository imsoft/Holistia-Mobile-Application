-- Migración 016: Soporte para múltiples imágenes por post y check-in
-- Permite hasta 6 imágenes por registro.
--
-- INSTRUCCIONES:
-- Ejecuta este SQL en el SQL Editor de Supabase (https://app.supabase.com)
-- o mediante la CLI: supabase db push

-- Agrega columna de array de imágenes a posts.
-- La columna image_url original se conserva para retrocompatibilidad con posts antiguos.
ALTER TABLE posts
  ADD COLUMN IF NOT EXISTS image_urls text[] NOT NULL DEFAULT '{}';

-- Agrega columna de array de imágenes a check_ins.
ALTER TABLE check_ins
  ADD COLUMN IF NOT EXISTS image_urls text[] NOT NULL DEFAULT '{}';

-- Migración de datos existentes: copiar image_url → image_urls[0] si no tiene URLs todavía.
UPDATE posts
  SET image_urls = ARRAY[image_url]
  WHERE image_url IS NOT NULL
    AND image_url <> ''
    AND array_length(image_urls, 1) IS NULL;

UPDATE check_ins
  SET image_urls = ARRAY[image_url]
  WHERE image_url IS NOT NULL
    AND image_url <> ''
    AND array_length(image_urls, 1) IS NULL;
