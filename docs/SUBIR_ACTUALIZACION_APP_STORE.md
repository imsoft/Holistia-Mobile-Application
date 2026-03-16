# Cómo subir una nueva actualización a la App Store

## 1. Subir la versión (build number)

Para que App Store Connect acepte un nuevo build, el **build number** debe ser mayor que el anterior.

En `pubspec.yaml` está:

```yaml
version: 1.0.0+1
#         ^^^^^ ^^^
#         |     build number (debe subir en cada subida)
#         version name (puedes dejarlo o cambiar ej. 1.0.1)
```

- **Misma versión, nuevo build**: por ejemplo `1.0.0+2` (solo cambia el número después del `+`).
- **Nueva versión**: por ejemplo `1.0.1+2` (cambias 1.0.0 → 1.0.1 y subes el build).

Edita `pubspec.yaml`, guarda y sigue.

---

## 2. Compilar para release

En la raíz del proyecto:

```bash
flutter build ios --release
```

O con las variables de Supabase (si las usas en build):

```bash
./build_ios_release.sh
```

---

## 3. Crear el Archive y subir desde Xcode

1. **Abre el workspace de iOS**
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Destino**
   - Arriba, en el esquema, elige **Any iOS Device (arm64)** (no el simulador ni un iPhone concreto).

3. **Archive**
   - Menú **Product → Archive**.
   - Espera a que termine; se abrirá el **Organizer**.

4. **Distribute**
   - En el Organizer, selecciona el archive que acabas de crear.
   - Pulsa **Distribute App**.
   - **App Store Connect** → Next.
   - **Upload** → Next.
   - **Importante (error de dSYM)**: Si Xcode muestra un error tipo *"The archive did not include a dSYM for the objective_c.framework..."*, en la pantalla de opciones de upload **desmarca** la casilla **"Upload your app's symbols to receive symbolicated crash logs"** (o similar). Así se evita la validación que exige ese dSYM del sistema. Luego Next.
   - Elige tu equipo y certificados si te los pide → Next.
   - **Upload** y espera a que termine.

5. **En App Store Connect**
   - Entra en [App Store Connect](https://appstoreconnect.apple.com) → tu app **Holistia**.
   - El nuevo build puede tardar unos minutos en aparecer en **TestFlight** y en la pestaña **App Store** (sección build).
   - Cuando aparezca, en la pestaña **App Store** selecciona ese build para la versión que quieras publicar y envía a revisión (o primero pruébalo en TestFlight).

---

## 4. (Opcional) Probar antes en TestFlight

- En App Store Connect → **TestFlight**.
- El build subido aparecerá ahí; añade testores internos o externos y prueba antes de enviar a revisión.

---

## 5. Responder a Apple (si es resubida por el rechazo 4.8)

Al enviar la nueva versión, en la nota para el revisor puedes pegar el texto que está en `docs/SIGN_IN_WITH_APPLE_SETUP.md` (sección “Texto sugerido para App Store Review”), explicando que añadiste Sign in with Apple.

---

## Resumen rápido

| Paso | Acción |
|------|--------|
| 1 | Subir `version` en `pubspec.yaml` (ej. `1.0.0+2`) |
| 2 | `flutter build ios --release` (o `./build_ios_release.sh`) |
| 3 | `open ios/Runner.xcworkspace` → **Any iOS Device** → **Product → Archive** |
| 4 | **Distribute App** → App Store Connect → **Upload** |
| 5 | En App Store Connect, asignar el build a la versión y enviar a revisión (o probar en TestFlight) |

---

## Error: "The archive did not include a dSYM for the objective_c.framework..."

Es un fallo conocido con Xcode 16: la validación pide un dSYM de un framework del sistema que no va en el archive.

**Solución:** Al hacer **Distribute App → Upload**, en la pantalla de opciones **desmarca** la casilla que dice algo como **"Upload your app's symbols to receive symbolicated crash logs"**. Vuelve a hacer Next y Upload.

- La app se sube bien; solo dejarás de subir símbolos con este build (los crash reports seguirán llegando, pero menos legibles hasta que subas dSYMs por otro medio si lo necesitas).
- Si en tu versión de Xcode no ves esa casilla, prueba: **flutter upgrade**, luego **flutter clean** y **flutter build ios --release**, y vuelve a hacer Archive y Distribute.
