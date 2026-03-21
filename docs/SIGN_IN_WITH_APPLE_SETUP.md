# Sign in with Apple — Configuración (Guideline 4.8)

Holistia incluye **Sign in with Apple** en iOS para cumplir con la Guideline 4.8 (Login Services) de App Store Review. Este documento describe los pasos manuales necesarios en Supabase, Apple Developer y Xcode.

## Resumen técnico

- **Flujo**: Sign in with Apple nativo en iOS/macOS → `identityToken` → Supabase `signInWithIdToken(provider: apple, idToken, nonce)`.
- **Código**: `lib/core/apple_auth_service.dart`, `lib/widgets/apple_sign_in_button.dart`; integrado en `login_screen.dart` y `register_screen.dart`. El botón solo se muestra en iOS (y macOS) para no afectar Android.
- **iOS**: `ios/Runner/Runner.entitlements` con capacidad `com.apple.developer.applesignin`; `CODE_SIGN_ENTITLEMENTS` en el proyecto Xcode.

---

## 1. Apple Developer

1. **App ID con Sign in with Apple**
   - En [Identifiers](https://developer.apple.com/account/resources/identifiers/list/bundleId) abre (o crea) el App ID con Bundle ID **io.holistia.mobile**.
   - Activa la capacidad **Sign In with Apple** (y guárdala si la acabas de añadir).
   - No es necesario crear Service ID ni clave `.p8` para **solo** login nativo en la app iOS.

2. **Provisioning**
   - Con “Automatically manage signing” en Xcode, los perfiles se actualizan solos.
   - Si usas perfiles manuales, regenera/descarga los que usen este App ID para que incluyan Sign in with Apple.

---

## 2. Supabase Dashboard

1. **Habilitar proveedor Apple**
   - En el proyecto: **Authentication → Providers → Apple** → activar el proveedor.

2. **Client IDs (App IDs)**
   - En la misma pantalla, en **Client IDs**, añade el Bundle ID de la app: **io.holistia.mobile**.
   - Para builds de desarrollo o variantes (ej. `io.holistia.mobile.dev`), añade también esos Bundle IDs a la lista.

3. **OAuth (solo si usas Apple en web/Android)**
   - Para **solo iOS nativo** no hace falta configurar Services ID, clave `.p8` ni secret. Si más adelante usas Apple en web o Android, entonces sí tendrás que configurar Service ID y secret en Supabase.

---

## 3. Xcode

1. **Capability**
   - El proyecto ya tiene `Runner/Runner.entitlements` con la capacidad **Sign in with Apple** y `CODE_SIGN_ENTITLEMENTS` apuntando a ese archivo en Debug/Release/Profile.
   - Si abres el proyecto en Xcode: **Runner** → **Signing & Capabilities** y comprueba que aparece “Sign in with Apple”. Si no, añade la capacidad y asegúrate de que usa el archivo `Runner.entitlements`.

2. **Bundle Identifier**
   - Debe coincidir con el App ID de Apple (ej. **io.holistia.mobile**).

---

## 4. Comportamiento en la app

- **Login / Registro**: En iOS se muestra primero el botón oficial “Sign in with Apple” y debajo “Continuar con Google” (prominencia equivalente a la Guideline 4.8). Email/contraseña siguen igual.
- **Primera vez con Apple**: Se crea el usuario en Supabase Auth y, si tu proyecto tiene trigger en `auth.users`, la fila en `profiles`. El nombre se guarda en `user_metadata` (full_name, given_name, family_name) cuando Apple lo envía (solo en el primer inicio de sesión).
- **Cancelación**: Si el usuario cancela en la pantalla de Apple, no se muestra error; el loading se quita y se queda en la misma pantalla.

---

## 5. Texto sugerido para App Store Review (inglés)

Puedes pegar algo como esto al responder a Apple sobre el rechazo 4.8:

```
We have added Sign in with Apple as an equivalent sign-in option on iOS, in line with Guideline 4.8 (Design - Login Services). Users can now sign in with Apple in addition to email/password and Google. The Sign in with Apple button is shown on both the login and registration screens with equivalent prominence to the other sign-in methods. We use the native Sign in with Apple flow and do not collect additional personal data beyond what is provided by Apple and required for the account (e.g. display name on first sign-in). Thank you for your feedback.
```

---

## Checklist rápida

- [ ] **Apple Developer**: App ID **io.holistia.mobile** con capacidad “Sign In with Apple” activada.
- [ ] **Supabase**: Proveedor Apple habilitado y **io.holistia.mobile** (y variantes si aplica) en Client IDs.
- [ ] **Xcode**: Capability “Sign in with Apple” en el target Runner (usando `Runner.entitlements`).
- [ ] Probar en dispositivo o simulador iOS: botón “Sign in with Apple” visible y flujo completo (inicio de sesión y navegación tras éxito).
