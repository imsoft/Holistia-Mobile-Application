# Configurar Supabase en Holistia

## 1. Crear proyecto en Supabase

1. Entra en [supabase.com](https://supabase.com) y crea un proyecto.
2. En **Settings → API** copia:
   - **Project URL** → será `SUPABASE_URL`
   - **anon public** key → será `SUPABASE_ANON_KEY`

## 2. Ejecutar la migración

1. En el dashboard de Supabase, abre **SQL Editor**.
2. Copia y ejecuta todo el contenido de `docs/supabase_migration_001_initial.sql`.
3. Verifica que existan las tablas: `profiles`, `challenges`, `check_ins`, `posts`, `zenits`.

## 3. Conectar la app Flutter

### Opción A: dart-define (recomendado para desarrollo)

Al ejecutar la app, pasa las variables:

```bash
flutter run --dart-define=SUPABASE_URL=https://TU_PROYECTO.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ...
```

En VS Code/Cursor puedes añadir en `.vscode/launch.json`:

```json
{
  "configurations": [
    {
      "name": "Holistia",
      "request": "launch",
      "type": "dart",
      "args": [
        "--dart-define=SUPABASE_URL=https://TU_PROYECTO.supabase.co",
        "--dart-define=SUPABASE_ANON_KEY=tu_anon_key"
      ]
    }
  ]
}
```

### Opción B: Archivo .env con flutter_dotenv

Si prefieres un archivo `.env`:

1. Añade la dependencia `flutter_dotenv` en `pubspec.yaml`.
2. Crea `.env` en la raíz del proyecto (y añádelo a `.gitignore`):
   ```
   SUPABASE_URL=https://TU_PROYECTO.supabase.co
   SUPABASE_ANON_KEY=eyJ...
   ```
3. En `pubspec.yaml` bajo `flutter:` → `assets:` añade `- .env`.
4. En `lib/core/config.dart` puedes leer con `dotenv.env['SUPABASE_URL']` en lugar de `String.fromEnvironment` (y cargar `dotenv.load()` en `main` antes de `initSupabase()`).

## 4. Comprobar que funciona

- Si las variables están vacías, la app arranca pero no se conecta a Supabase (no habrá error).
- Si están configuradas, `Supabase.initialize()` se ejecuta y podrás usar `Supabase.instance.client` para auth y datos.

## 5. Auth y Redirect URLs

En Supabase → **Authentication → Providers** activa **Email**. Opcional: **Apple** y **Google** para “continuar con…”.

### Confirmación de correo

Por defecto Supabase exige **confirmar el correo** antes de iniciar sesión. Si ves "Confirma tu correo antes de iniciar sesión":

1. Revisa tu bandeja de entrada (y spam) y haz clic en el enlace que te enviamos.
2. O desactiva la confirmación: **Authentication** → **Providers** → **Email** → desmarca **"Confirm email"**.

> Desactivar la confirmación es útil en desarrollo; en producción es recomendable mantenerla.

### Redirect URLs

En Supabase → **Authentication → URL Configuration** añade estas URLs en **Redirect URLs**:

| URL | Uso |
|-----|-----|
| `com.example.holistia://login-callback` | OAuth (Google Sign-In) |
| `com.example.holistia://reset-password` | Recuperar contraseña |

El esquema ya incluye el trigger que crea un perfil en `profiles` cuando un usuario se registra.

### Migración 002 (comentarios e imágenes en posts)

Para comentarios e imágenes en publicaciones:

1. Ejecuta en SQL Editor: `docs/supabase_migration_002_posts_comments_images.sql`
2. Crea el bucket **post-images** en **Storage** → New bucket:
   - id: `post-images`
   - Public: sí
   - File size limit: 5MB
   - Allowed MIME types: `image/jpeg`, `image/png`, `image/webp`

### Migración 003 (avatares y iconos de retos)

Para foto de perfil e iconos personalizados en retos:

1. Ejecuta en SQL Editor: `docs/supabase_migration_003_avatars_challenge_icons.sql`

### Migración 004 (sexo y fecha de nacimiento)

Para sexo y fecha de nacimiento en el perfil:

1. Ejecuta en SQL Editor: `docs/supabase_migration_004_profile_sex_birthdate.sql`

### Migración 005 (imágenes en avances)

Para subir imágenes al registrar avances:

1. Ejecuta en SQL Editor: `docs/supabase_migration_005_check_in_images.sql`

### Migración 006 (cantidad por día/sesión)

Para la cantidad por día o sesión (ej. 5 km por día):

1. Ejecuta en SQL Editor: `docs/supabase_migration_006_challenge_unit_amount.sql`

### Migración 007 (políticas Storage para post-images y avatars)

**Importante:** Si subes imágenes y ves "new row violates row-level security policy" (403 Unauthorized), ejecuta esta migración.

1. Crea los buckets `post-images` y `avatars` en Supabase Dashboard si no existen.
2. Ejecuta en SQL Editor: `docs/supabase_migration_007_storage_policies.sql`
2. Crea el bucket **avatars** en **Storage** → New bucket:
   - id: `avatars`
   - Public: sí
   - File size limit: 2MB
   - Allowed MIME types: `image/jpeg`, `image/png`, `image/webp`
