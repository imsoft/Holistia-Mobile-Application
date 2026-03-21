# App Store Review — Guideline 4.8 y 5.1.2(i)

Este documento resume lo implementado en el código y lo que debes hacer **en App Store Connect** antes de volver a enviar a revisión.

## 4.8 — Login Services (Sign in with Apple)

**En la app (iOS):**

- Pantallas **Iniciar sesión** y **Registro**: botón nativo **Sign in with Apple** (`Continuar con Apple`) **encima** de Google, con tamaño y visibilidad equivalentes.
- Capacidad **Sign In with Apple** en `ios/Runner/Runner.entitlements`.
- Flujo: `lib/core/apple_auth_service.dart` → Supabase `signInWithIdToken` con proveedor Apple.

**Si Review sigue diciendo que no lo ven:**

1. Confirma en **Apple Developer** que el App ID del bundle tiene **Sign In with Apple** activado.
2. En **Supabase → Authentication → Apple**, el proveedor activo y el **Bundle ID** en Client IDs.
3. En **App Store Connect → Review Notes** (inglés), indica: *“On the Login and Register screens, tap ‘Continue with Apple’ (Sign in with Apple) above Google.”*

---

## 5.1.2(i) — Privacidad / Tracking (sin ATT en el binario)

**Coherencia App Store Connect ↔ app:**

- Si en **App Privacy** indicas que **no** usáis datos para **seguimiento** (tracking) según Apple, **no** debe incluirse el binario:
  - **`NSUserTrackingUsageDescription`** en `Info.plist`, ni
  - solicitud de **App Tracking Transparency (ATT)** al usuario.
- Eso **no** es lo mismo que usar **HTTPS** (TLS) o iniciar sesión: es normal y no exige ATT si no hay tracking.

**En esta app:** no hay `NSUserTrackingUsageDescription` ni plugin ATT; la app solo usa TLS/Keychain y flujos habituales de cuenta.

**Qué debes hacer en App Store Connect:**

1. Mantener **App Privacy** alineada con el uso real (sin “seguimiento” si no aplica).
2. Si en el futuro **sí** hicierais tracking según la definición de Apple, entonces habría que declararlo en privacidad **y** implementar ATT + texto en `Info.plist`.

---

## Texto sugerido para Review Notes (inglés, copiar/pegar)

```
Guideline 4.8: Sign in with Apple is available on both Login and Register screens. It appears as the first social sign-in option above “Continue with Google”, using the native Sign in with Apple button.

Guideline 5.1.2(i): App Privacy has been updated to reflect that we do not track users as defined by Apple. The app does not include App Tracking Transparency (no NSUserTrackingUsageDescription). Data collection is limited to account functionality and standard HTTPS; we do not link user data with third-party data for advertising or share with data brokers.
```

Ajusta si cambiáis políticas o SDKs.
