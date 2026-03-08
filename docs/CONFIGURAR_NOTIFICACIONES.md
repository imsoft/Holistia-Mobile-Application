# Configurar Push Notifications en Supabase

Para que las push notifications funcionen correctamente, necesitas hacer lo siguiente en tu proyecto de Supabase:

## 1. Ejecutar la migración SQL

1. Ve a tu proyecto en Supabase Dashboard
2. Abre **SQL Editor**
3. Ejecuta el contenido completo de `docs/supabase_migration_011_notifications.sql`
   - Esto crea la tabla `notifications`
   - Crea los triggers que generan notificaciones automáticamente
   - Configura las políticas RLS (Row Level Security)

**Dónde ver la tabla:** En el dashboard, la tabla `notifications` aparece en **Database → Tables**. No la busques en "Replication" (esa sección es para replicar datos a BigQuery u otros destinos externos).

## 2. Habilitar Realtime para la tabla `notifications`

**IMPORTANTE:** Para que las push notifications funcionen, la tabla `notifications` debe estar en la publicación Realtime.

### Opción A: Ya está en la migración (recomendado)

La migración `supabase_migration_011_notifications.sql` **ya incluye** al final este comando:

```sql
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
```

Si ejecutaste la migración completa, **no necesitas hacer nada más** en el dashboard.

### Opción B: Habilitarlo desde el dashboard

Si no ejecutaste esa línea o quieres comprobarlo desde la interfaz:

1. En el **menú izquierdo**, entra en **Database** (gestión de base de datos), **no** en "Realtime".
2. Dentro de Database, abre **Publications**.
   - **Replication** (en Platform) es para BigQuery y destinos externos.
   - **Realtime → Inspector** es para ver mensajes en vivo; no es donde se añaden tablas a la publicación.
3. Localiza la publicación **supabase_realtime**.
4. Añade o marca la tabla **notifications** para que forme parte de esa publicación.

### Opción C: Solo ejecutar el SQL

En **SQL Editor** ejecuta:

```sql
-- Habilitar Realtime para la tabla notifications
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
```

## 3. Verificar que los triggers funcionen

Puedes probar que los triggers funcionan ejecutando:

```sql
-- Probar trigger de follow (reemplaza los UUIDs con IDs reales)
INSERT INTO public.user_follows (follower_id, following_id)
VALUES ('usuario-que-sigue-id', 'usuario-seguido-id');

-- Debería crear automáticamente una notificación en la tabla notifications
SELECT * FROM public.notifications ORDER BY created_at DESC LIMIT 1;
```

## 4. Verificar políticas RLS

Asegúrate de que las políticas RLS permitan:
- ✅ Lectura de notificaciones propias (`user_id = auth.uid()`)
- ✅ Inserción por triggers/funciones (`WITH CHECK (true)`)
- ✅ Actualización para marcar como leídas (`user_id = auth.uid()`)

Las políticas están incluidas en la migración, pero puedes verificarlas en:
**Authentication → Policies → notifications**

## 5. Configurar permisos de notificaciones en la app

### Android

En `android/app/src/main/AndroidManifest.xml`, asegúrate de tener:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

### iOS

En `ios/Runner/Info.plist`, añade (si no está):

```xml
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>
```

## 6. Probar las notificaciones

1. **Inicia sesión** en la app con dos usuarios diferentes (o desde dos dispositivos)
2. **Usuario A** sigue a **Usuario B** → Usuario B debería recibir una push notification
3. **Usuario A** comenta en un post de **Usuario B** → Usuario B debería recibir una push notification
4. **Usuario A** da zenit a un post de **Usuario B** → Usuario B debería recibir una push notification

## 7. Recordatorios diarios

Los recordatorios diarios se programan automáticamente cuando:
- El usuario tiene retos activos
- Se ejecuta a las **9:00 AM** por defecto
- Se cancela si el usuario no tiene retos activos

## Notas importantes

- **Realtime funciona cuando la app está abierta o en segundo plano** (depende del sistema operativo)
- **Cuando la app está completamente cerrada**, Realtime puede no funcionar. Para push notifications reales cuando la app está cerrada, necesitarías:
  - Firebase Cloud Messaging (FCM) + Supabase Edge Functions, o
  - Un servicio de push notifications externo

## Troubleshooting

### Las notificaciones no llegan

1. Verifica que Realtime esté habilitado para `notifications`:
   ```sql
   SELECT * FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'notifications';
   ```
   Debería devolver una fila.

2. Verifica que los triggers existan:
   ```sql
   SELECT trigger_name, event_object_table 
   FROM information_schema.triggers 
   WHERE trigger_name LIKE 'trigger_notify%';
   ```
   Deberías ver 3 triggers: `trigger_notify_on_follow`, `trigger_notify_on_comment`, `trigger_notify_on_zenit`.

3. Revisa los logs de la app en modo debug para ver si hay errores de conexión Realtime.

4. Verifica que el usuario tenga permisos para leer sus notificaciones (las políticas RLS deberían permitirlo).
