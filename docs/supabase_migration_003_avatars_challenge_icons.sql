-- Holistia – Migración 003: avatares y iconos de retos
-- Ejecutar después de la migración 002.

-- ========== 1. Icono en challenges ==========
ALTER TABLE public.challenges ADD COLUMN IF NOT EXISTS icon_code_point INTEGER;

-- ========== 2. Bucket avatars ==========
-- Crear en Supabase Dashboard:
-- Storage → New bucket → id: avatars, Public: sí, File size limit: 2MB,
-- Allowed MIME types: image/jpeg, image/png, image/webp
--
-- Políticas RLS para avatars (ejecutar después de crear el bucket):
--
-- CREATE POLICY "Usuarios suben su propio avatar"
--   ON storage.objects FOR INSERT
--   WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);
--
-- CREATE POLICY "Avatares son públicos"
--   ON storage.objects FOR SELECT
--   USING (bucket_id = 'avatars');
--
-- CREATE POLICY "Usuarios actualizan su propio avatar"
--   ON storage.objects FOR UPDATE
--   USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);
