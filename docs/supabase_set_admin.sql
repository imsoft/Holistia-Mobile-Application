-- Asignar rol admin al usuario holistia.io@gmail.com
-- Ejecutar en el editor SQL de Supabase.

UPDATE public.profiles
SET role = 'admin'
WHERE id = (SELECT id FROM auth.users WHERE email = 'holistia.io@gmail.com');
