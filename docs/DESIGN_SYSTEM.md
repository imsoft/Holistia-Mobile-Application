# Holistia – Sistema de diseño

Guía de estilo para mantener coherencia visual y de tono en la app. Complementa el tema en código (`lib/theme/`).

---

## 1. Colores y tema

- Los colores están definidos en **oklch** y traducidos a Flutter en `lib/theme/app_colors.dart`.
- Tema claro (por defecto) y oscuro en `lib/theme/app_theme.dart`.
- Uso en UI:
  - `Theme.of(context).colorScheme` para primary, surface, error, etc.
  - `Theme.of(context).extension<AppThemeExtension>()` para tokens semánticos: `background`, `foreground`, `card`, `muted`, `accent`, `border`, `radiusLg`, `shadowMd`, etc.

### Tokens principales

| Token | Uso |
|-------|-----|
| `background` | Fondo de pantalla, scaffold |
| `foreground` | Texto principal |
| `primary` | Botones primarios, links, Zenit activo |
| `secondary` | Botones secundarios, chips |
| `muted` / `mutedForeground` | Texto secundario, hints |
| `accent` | Fondos destacados suaves, selección |
| `destructive` | Eliminar, abandonar reto |
| `border` / `input` | Bordes, campos |
| `card` | Cards de reto, contenedores elevados |

### Radios y sombras

- **Radios:** `radiusSm`, `radiusMd`, `radiusLg`, `radiusXl` (desde `AppThemeExtension`).
- **Sombras:** `shadowSm`, `shadow`, `shadowMd`, `shadowLg`, etc., para cards y elementos elevados.

---

## 2. Tono de voz (copy)

- **Cercano y claro:** Frases cortas. Evitar jerga de autoayuda genérica.
- **Motivador sin cursi:** Preferir datos y hechos (“7 días seguidos”) sobre consignas (“Tú puedes con todo”).
- **Ejemplos:**
  - Bien: “María te envió un Zenit”, “Tu racha: 12 días”, “¿Registramos hoy?”
  - Evitar: “¡Sé imparable!”, “Tu mejor versión te espera”.

### Contextos

- **Onboarding:** 2–3 pantallas; explicar retos, progreso visible, comunidad y Zenit en una frase cada una.
- **Empty states:** Una acción clara: “Crea tu primer reto”, “Comparte tu primer avance”.
- **Celebraciones:** Breves: “Racha de 7 días”, “Nueva insignia”, “¡Zenit recibido!”.
- **Errores:** Explicar qué pasó y qué hacer: “No se pudo guardar. Revisa tu conexión e inténtalo de nuevo.”

---

## 3. Iconografía

- **Estilo:** Consistente en toda la app (todo outline o todo filled según contexto).
  - **Outline:** Navegación, acciones secundarias, estados inactivos.
  - **Filled:** Estado activo (ej. tab seleccionado), Zenit dado, elementos primarios.
- **Zenit:** Icono distintivo (no un like genérico). Opciones: sol pequeño, estrella, rayo suave, o símbolo de “cumbre/zenit”. Debe ser reconocible en pequeño.
- **Retos y progreso:** Check, calendario, gráfica, trofeo/insignia, nivel (copa, medalla, etc.).
- **Fuente:** SF Symbols (iOS) / Material Icons; mismo set en toda la app. Color según `colorScheme` o tokens del tema.

---

## 4. Componentes y patrones

- **Card de reto:** Fondo `card`, borde `border`, `radiusLg`, sombra `shadowSm` o `shadow`. Título en `foreground`, subtítulo en `mutedForeground`.
- **Botón primario:** Fondo `primary`, texto `primaryForeground`. Para la acción principal de la pantalla.
- **Botón secundario:** `secondary` / `secondaryForeground` o outline con `border`.
- **Destructivo:** Solo para “Eliminar” o “Abandonar reto”; usar `destructive`.
- **Niveles e insignias:** Usar `chart1`–`chart5` para variedad sin salir de la paleta (tonos del primary/violeta).
- **Inputs:** Borde `input`, radio `radiusMd`. Placeholder en `mutedForeground`.

---

## 5. Zenit (nombre e identidad)

- **Nombre:** Zenit (en lugar de “like”).
- **Uso en copy:** “Dar un Zenit”, “Recibiste un Zenit”, “Zenits recibidos”.
- **UI:** Botón/icono claro para “dar Zenit” en cada publicación; contador de Zenits por publicación. Estado “ya diste Zenit” con estilo filled o color primary.

---

## 6. Referencia en código

- Tema: `lib/theme/app_theme.dart`, `lib/theme/app_colors.dart`.
- Uso del tema: `Theme.of(context).extension<AppThemeExtension>()` y `Theme.of(context).colorScheme`.
- Ejemplo de texto con color de tema: `Text('Holistia', style: TextStyle(color: Theme.of(context).colorScheme.primary))`.

---

*Actualizar este doc cuando se definan iconos finales (Zenit) o nuevos componentes.*
