-- Holistia – Migración 007: políticas RLS para Storage
-- Ejecutar después de crear los buckets post-images y avatars en Supabase Dashboard.
-- Resuelve: "new row violates row-level security policy" al subir imágenes.

-- ========== post-images (posts y avances con foto) ==========
DROP POLICY IF EXISTS "Usuarios suben a post-images (solo su carpeta)" ON storage.objects;
CREATE POLICY "Usuarios suben a post-images (solo su carpeta)"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'post-images'
    AND (storage.foldername(name))[1] = (SELECT auth.jwt()->>'sub')
  );

DROP POLICY IF EXISTS "post-images públicos para lectura" ON storage.objects;
CREATE POLICY "post-images públicos para lectura"
  ON storage.objects FOR SELECT
  TO public
  USING (bucket_id = 'post-images');

DROP POLICY IF EXISTS "Usuarios actualizan su carpeta en post-images" ON storage.objects;
CREATE POLICY "Usuarios actualizan su carpeta en post-images"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'post-images'
    AND (storage.foldername(name))[1] = (SELECT auth.jwt()->>'sub')
  );

-- ========== avatars (foto de perfil) ==========
DROP POLICY IF EXISTS "Usuarios suben a avatars (solo su carpeta)" ON storage.objects;
CREATE POLICY "Usuarios suben a avatars (solo su carpeta)"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = (SELECT auth.jwt()->>'sub')
  );

DROP POLICY IF EXISTS "avatars públicos para lectura" ON storage.objects;
CREATE POLICY "avatars públicos para lectura"
  ON storage.objects FOR SELECT
  TO public
  USING (bucket_id = 'avatars');

DROP POLICY IF EXISTS "Usuarios actualizan su carpeta en avatars" ON storage.objects;
CREATE POLICY "Usuarios actualizan su carpeta en avatars"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = (SELECT auth.jwt()->>'sub')
  );
