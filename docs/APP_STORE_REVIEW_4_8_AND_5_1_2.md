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

## 5.1.2(i) — Privacidad / Tracking y App Tracking Transparency (ATT)

**En la app (iOS):**

- Tras el arranque, si el estado de tracking es `notDetermined`, se llama a **`requestTrackingAuthorization()`** (ver `lib/core/app_tracking_transparency_helper.dart` y llamada en `lib/main.dart`).
- `Info.plist` incluye **`NSUserTrackingUsageDescription`** (texto del diálogo del sistema).

**Para que coincida con la ley y con Apple:**

1. **Si la app NO hace “tracking”** según Apple (no vinculáis datos con terceros para publicidad ni compartís con data brokers), el **Account Holder** o **Admin** debe **actualizar App Privacy** en App Store Connect y **quitar o marcar correctamente** los datos que no se usan para tracking.
2. **Si sí hay tracking** (o SDKs que accedan al IDFA para eso), el prompt ATT ya solicitado cumple el requisito; en **Review Notes** indica: *“ATT appears shortly after launch on first install (iOS 14+).”*

---

## Texto sugerido para Review Notes (inglés, copiar/pegar)

```
Guideline 4.8: Sign in with Apple is available on both Login and Register screens. It appears as the first social sign-in option above “Continue with Google”, using the native Sign in with Apple button.

Guideline 5.1.2(i): The app requests App Tracking Transparency permission on the first launch when the authorization status is not determined (see AppTrackingTransparency). The prompt is shown shortly after the app starts. NSUserTrackingUsageDescription is set in Info.plist.
```

Ajusta si cambiáis el momento exacto del prompt o el flujo de login.
