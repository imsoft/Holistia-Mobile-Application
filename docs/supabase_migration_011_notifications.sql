-- Holistia – Migración 011: sistema de notificaciones
-- Ejecutar después de las migraciones anteriores.

-- ========== 1. Tabla notifications ==========
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('follow', 'comment', 'zenit', 'daily_reminder')),
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  related_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  related_post_id UUID REFERENCES public.posts(id) ON DELETE SET NULL,
  related_challenge_id UUID REFERENCES public.challenges(id) ON DELETE SET NULL,
  is_read BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_read ON public.notifications(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at DESC);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Usuarios solo ven sus propias notificaciones
CREATE POLICY "Ver mis notificaciones"
  ON public.notifications FOR SELECT
  USING (user_id = auth.uid());

-- Solo el sistema puede crear notificaciones (via triggers/functions)
CREATE POLICY "Sistema crea notificaciones"
  ON public.notifications FOR INSERT
  WITH CHECK (true);

-- Usuario marca sus notificaciones como leídas
CREATE POLICY "Marcar notificaciones como leídas"
  ON public.notifications FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ========== 2. Función para crear notificación ==========
CREATE OR REPLACE FUNCTION public.create_notification(
  p_user_id UUID,
  p_type TEXT,
  p_title TEXT,
  p_body TEXT,
  p_related_user_id UUID DEFAULT NULL,
  p_related_post_id UUID DEFAULT NULL,
  p_related_challenge_id UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_notification_id UUID;
BEGIN
  INSERT INTO public.notifications (
    user_id, type, title, body,
    related_user_id, related_post_id, related_challenge_id
  )
  VALUES (
    p_user_id, p_type, p_title, p_body,
    p_related_user_id, p_related_post_id, p_related_challenge_id
  )
  RETURNING id INTO v_notification_id;
  RETURN v_notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========== 3. Trigger: notificación cuando alguien te sigue ==========
CREATE OR REPLACE FUNCTION public.notify_on_follow()
RETURNS TRIGGER AS $$
DECLARE
  v_follower_name TEXT;
BEGIN
  -- Obtener nombre del seguidor
  SELECT display_name INTO v_follower_name
  FROM public.profiles
  WHERE id = NEW.follower_id;
  
  -- Crear notificación (no notificar si se sigue a sí mismo)
  IF NEW.follower_id != NEW.following_id THEN
    PERFORM public.create_notification(
      p_user_id := NEW.following_id,
      p_type := 'follow',
      p_title := 'Nuevo seguidor',
      p_body := COALESCE(v_follower_name, 'Alguien') || ' te está siguiendo',
      p_related_user_id := NEW.follower_id
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_notify_on_follow
  AFTER INSERT ON public.user_follows
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_on_follow();

-- ========== 4. Trigger: notificación cuando comentan tu post ==========
CREATE OR REPLACE FUNCTION public.notify_on_comment()
RETURNS TRIGGER AS $$
DECLARE
  v_commenter_name TEXT;
  v_post_owner_id UUID;
BEGIN
  -- Obtener dueño del post y nombre del comentarista
  SELECT p.user_id INTO v_post_owner_id
  FROM public.posts p
  WHERE p.id = NEW.post_id;
  
  SELECT display_name INTO v_commenter_name
  FROM public.profiles
  WHERE id = NEW.user_id;
  
  -- Crear notificación (no notificar si comentas tu propio post)
  IF v_post_owner_id IS NOT NULL AND v_post_owner_id != NEW.user_id THEN
    PERFORM public.create_notification(
      p_user_id := v_post_owner_id,
      p_type := 'comment',
      p_title := 'Nuevo comentario',
      p_body := COALESCE(v_commenter_name, 'Alguien') || ' comentó en tu publicación',
      p_related_user_id := NEW.user_id,
      p_related_post_id := NEW.post_id
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_notify_on_comment
  AFTER INSERT ON public.post_comments
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_on_comment();

-- ========== 5. Trigger: notificación cuando dan zenit a tu post ==========
CREATE OR REPLACE FUNCTION public.notify_on_zenit()
RETURNS TRIGGER AS $$
DECLARE
  v_zeniter_name TEXT;
  v_post_owner_id UUID;
BEGIN
  -- Obtener dueño del post y nombre del que da zenit
  SELECT p.user_id INTO v_post_owner_id
  FROM public.posts p
  WHERE p.id = NEW.post_id;
  
  SELECT display_name INTO v_zeniter_name
  FROM public.profiles
  WHERE id = NEW.from_user_id;
  
  -- Crear notificación (no notificar si te das zenit a ti mismo)
  IF v_post_owner_id IS NOT NULL AND v_post_owner_id != NEW.from_user_id THEN
    PERFORM public.create_notification(
      p_user_id := v_post_owner_id,
      p_type := 'zenit',
      p_title := 'Nuevo zenit',
      p_body := COALESCE(v_zeniter_name, 'Alguien') || ' le dio zenit a tu publicación',
      p_related_user_id := NEW.from_user_id,
      p_related_post_id := NEW.post_id
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_notify_on_zenit
  AFTER INSERT ON public.zenits
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_on_zenit();

-- ========== 6. Habilitar Realtime para la tabla notifications ==========
-- Esto permite que la app escuche cambios en tiempo real y muestre push notifications
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
