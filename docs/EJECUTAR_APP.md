# Ejecutar la app Holistia

## Requisitos

- [Flutter](https://flutter.dev/docs/get-started/install) instalado
- Android Studio / Xcode (para emulador o dispositivo físico)
- Supabase configurado (ver [CONFIGURAR_SUPABASE.md](./CONFIGURAR_SUPABASE.md))

## Comando básico

```bash
flutter run --dart-define=SUPABASE_URL=https://TU_PROYECTO.supabase.co --dart-define=SUPABASE_ANON_KEY=tu_anon_key
```

Reemplaza `TU_PROYECTO` y `tu_anon_key` por los valores de tu proyecto en Supabase → **Settings → API**.

## Ejecutar en un dispositivo concreto

```bash
# Listar dispositivos disponibles
flutter devices

# Ejecutar en el emulador/dispositivo indicado
flutter run -d <device_id> --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

Ejemplo con ID de emulador Android:

```bash
flutter run -d emulator-5554 --dart-define=SUPABASE_URL=https://abc.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ...
```

## Sin Supabase (modo demo)

Si no pasas las variables, la app arranca pero no se conecta a Supabase. Útil para probar la UI sin backend:

```bash
flutter run
```

## VS Code / Cursor

Crea `.vscode/launch.json` con una configuración que incluya los `args`:

```json
{
  "version": "0.2.0",
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

Guarda y ejecuta con **F5** o desde el panel Run and Debug.
