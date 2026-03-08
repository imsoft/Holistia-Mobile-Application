-- Migración 015: Función para eliminar cuenta de usuario
-- Requerido por Google Play y Apple App Store (usuarios deben poder borrar su cuenta).
--
-- INSTRUCCIONES:
-- Ejecuta este SQL en el SQL Editor de Supabase (https://app.supabase.com)
-- o mediante la CLI: supabase db push

-- Función que elimina al usuario autenticado y todos sus datos.
-- SECURITY DEFINER para poder borrar de auth.users usando el rol de servicio.
CREATE OR REPLACE FUNCTION public.delete_user()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _uid uuid := auth.uid();
BEGIN
  -- Verifica que el usuario esté autenticado
  IF _uid IS NULL THEN
    RAISE EXCEPTION 'No autenticado';
  END IF;

  -- Las tablas públicas se eliminan en cascada por las foreign keys.
  -- Solo necesitamos eliminar de auth.users.
  DELETE FROM auth.users WHERE id = _uid;
END;
$$;

-- Permisos: solo usuarios autenticados pueden llamar a esta función
REVOKE ALL ON FUNCTION public.delete_user() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.delete_user() TO authenticated;
