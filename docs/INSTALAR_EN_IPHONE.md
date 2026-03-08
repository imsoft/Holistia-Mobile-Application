# Instalar Holistia en iPhone físico

Esta guía te ayudará a instalar la app en tu iPhone físico para probarla.

## Requisitos previos

1. ✅ **Xcode instalado** (ya lo tienes: Xcode 26.2)
2. ✅ **Flutter configurado** (ya está configurado)
3. **iPhone físico** conectado por USB
4. **Cuenta de desarrollador de Apple** (gratuita es suficiente para desarrollo)

## Pasos para instalar

### 1. Conectar el iPhone

1. Conecta tu iPhone a la Mac con un cable USB.
2. Desbloquea el iPhone.
3. Si aparece el mensaje "¿Confiar en esta computadora?", toca **"Confiar"**.
4. En el iPhone, ve a **Configuración → General → Gestión de VPN y dispositivos** y verifica que tu Mac aparezca como confiable.

### 2. Verificar que el iPhone esté conectado

Ejecuta en la terminal:

```bash
flutter devices
```

Deberías ver tu iPhone listado, algo como:
```
iPhone de Brandon (00008030-001A...) • ios • iOS 18.1
```

### 3. Configurar el Bundle Identifier y Team

**Opción A: Desde Xcode (recomendado para primera vez)**

1. Abre el proyecto en Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. En Xcode:
   - Selecciona el proyecto **Runner** en el navegador izquierdo
   - Selecciona el target **Runner**
   - Ve a la pestaña **"Signing & Capabilities"**
   - Marca **"Automatically manage signing"**
   - Selecciona tu **Team** (tu cuenta de Apple)
   - Xcode generará automáticamente un Bundle Identifier único (ej: `com.tunombre.holistia`)

3. Si aparece un error de certificados, Xcode te pedirá que los genere automáticamente. Acepta.

**Opción B: Desde la terminal (más rápido si ya configuraste antes)**

Si ya tienes un Team configurado, puedes saltar este paso y pasar al siguiente.

### 4. Configurar credenciales de Supabase

La app necesita las credenciales de Supabase para funcionar. Ejecuta el comando con las variables de entorno:

```bash
flutter run -d <device-id> \
  --dart-define=SUPABASE_URL=https://imxzapeoxvdfheffxhwj.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlteHphcGVveHZkZmhlZmZ4aHdqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIxNDI5NjgsImV4cCI6MjA4NzcxODk2OH0.-DZpeRdGJxujjLPtF9PaeiEUCPR8njJe6oysubzFQ0k
```

O si solo tienes un iPhone conectado, puedes omitir `-d <device-id>`:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://imxzapeoxvdfheffxhwj.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlteHphcGVveHZkZmhlZmZ4aHdqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIxNDI5NjgsImV4cCI6MjA4NzcxODk2OH0.-DZpeRdGJxujjLPtF9PaeiEUCPR8njJe6oysubzFQ0k
```

**Nota:** Si prefieres no escribir estas credenciales cada vez, puedes crear un script o configurar Xcode (ver sección de solución de problemas).

### 5. Instalar la app

**Opción 1: Desde la terminal (más rápido)**

Usa el comando del paso anterior con las credenciales de Supabase.

**Opción 2: Crear un script para facilitar**

Crea un archivo `run_ios.sh` en la raíz del proyecto:

```bash
#!/bin/bash
flutter run \
  --dart-define=SUPABASE_URL=https://imxzapeoxvdfheffxhwj.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlteHphcGVveHZkZmhlZmZ4aHdqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIxNDI5NjgsImV4cCI6MjA4NzcxODk2OH0.-DZpeRdGJxujjLPtF9PaeiEUCPR8njJe6oysubzFQ0k
```

Luego ejecuta:
```bash
chmod +x run_ios.sh
./run_ios.sh
```

**Opción 3: Desde Xcode**

Para ejecutar desde Xcode con las credenciales de Supabase:

1. Abre `ios/Runner.xcworkspace` en Xcode
2. Ve a **Product → Scheme → Edit Scheme...**
3. Selecciona **Run** en el lado izquierdo
4. Ve a la pestaña **Arguments**
5. En **Arguments Passed On Launch**, añade:
   - `--dart-define=SUPABASE_URL=https://imxzapeoxvdfheffxhwj.supabase.co`
   - `--dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlteHphcGVveHZkZmhlZmZ4aHdqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIxNDI5NjgsImV4cCI6MjA4NzcxODk2OH0.-DZpeRdGJxujjLPtF9PaeiEUCPR8njJe6oysubzFQ0k`
6. En la barra superior, selecciona tu iPhone como destino (junto al botón Play)
7. Presiona el botón **▶️ Play** o `Cmd + R`

### 6. Confiar en el desarrollador en el iPhone

La primera vez que instales la app:

1. En el iPhone, ve a **Configuración → General → Gestión de VPN y dispositivos**
2. Busca tu cuenta de desarrollador (tu nombre o email)
3. Toca **"Confiar en [tu nombre]"**
4. Confirma tocando **"Confiar"**

### 7. Abrir la app

Ahora puedes abrir la app **Holistia** desde el home screen del iPhone.

## Solución de problemas

### Error: "No signing certificate found"

- Abre Xcode y configura el Team en Signing & Capabilities
- Asegúrate de estar logueado con tu Apple ID en Xcode (Preferences → Accounts)

### Error: "Device not trusted"

- Desbloquea el iPhone
- Ve a Configuración → General → Gestión de VPN y dispositivos → Confiar en esta computadora

### Error: "Unable to install"

- Verifica que el iPhone esté desbloqueado
- Asegúrate de que el iPhone tenga suficiente espacio
- Intenta desconectar y reconectar el cable USB

### La app se cierra inmediatamente

- Verifica los logs en la terminal donde ejecutaste `flutter run`
- Revisa que todas las dependencias estén instaladas: `flutter pub get`
- Asegúrate de que el Bundle Identifier sea único
- Verifica que ejecutaste el comando con las credenciales de Supabase (`--dart-define`)

### Error: "Configura Supabase"

Si ves la pantalla que dice "Configura Supabase", significa que las credenciales no se pasaron correctamente:

- Verifica que incluiste ambos `--dart-define` en el comando
- Si usas Xcode, asegúrate de haber añadido los argumentos en **Edit Scheme → Arguments**
- Si usas un script, verifica que las credenciales estén correctas

### La app no abre cuando desconecto el iPhone

**Problema:** Los builds de desarrollo (`flutter run`) requieren conexión a la computadora. Cuando desconectas el iPhone, la app puede dejar de funcionar.

**Solución:** Compila un build de Release que funcionará independientemente:

**Opción 1: Usar el script (más fácil)**

```bash
./build_ios_release.sh
```

Luego instala desde Xcode:
1. Abre `ios/Runner.xcworkspace` en Xcode (ya debería estar abierto)
2. En la barra superior de Xcode, selecciona tu iPhone físico como destino (no el simulador)
3. Presiona **▶️ Play** o `Cmd + R`
4. La app se instalará y abrirá automáticamente en tu iPhone

**Opción 2: Compilar manualmente**

```bash
flutter build ios --release \
  --no-tree-shake-icons \
  --dart-define=SUPABASE_URL=https://imxzapeoxvdfheffxhwj.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlteHphcGVveHZkZmhlZmZ4aHdqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIxNDI5NjgsImV4cCI6MjA4NzcxODk2OH0.-DZpeRdGJxujjLPtF9PaeiEUCPR8njJe6oysubzFQ0k
```

Luego instala desde Xcode como en la Opción 1.

**Nota:** Los builds de Release funcionan sin conexión a la computadora, pero con cuenta gratuita de Apple Developer expiran después de 7 días.

## Compilar para distribución (opcional)

Si quieres crear un archivo `.ipa` para distribuir:

```bash
flutter build ipa
```

El archivo se generará en `build/ios/ipa/holistia.ipa`

## Notas importantes

- **Cuenta gratuita de Apple Developer**: Permite instalar apps en tu iPhone por 7 días. Después de 7 días, necesitarás reinstalar.
- **Cuenta de pago ($99/año)**: Permite instalar apps por 1 año y publicar en App Store.
- **Para desarrollo diario**: La cuenta gratuita es suficiente si reinstalas cada semana.
