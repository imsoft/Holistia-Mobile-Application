# Plan por fases – Holistia

**Misión:** Impulsar a las personas a cumplir sus metas personales a través de acción constante y comunidad activa.

**Fórmula:** comunidad + sistema + progreso visible

**Diferenciador:** "Zenit" en lugar de likes (solo en publicaciones de progreso).

---

## Decisiones de producto (cerradas)

| Tema | Decisión |
|------|----------|
| **Retos** | Un usuario puede tener **varios retos a la vez** (ej. meditación + correr + lectura). |
| **Tipos de reto** | Lo más **personalizado y flexible posible** (streaks, X veces en el mes, unidades como km/páginas, etc.). |
| **Zenit** | Solo a **publicaciones de progreso**, no a perfiles ni a personas. |
| **Privacidad** | **Público por defecto**; el usuario puede hacer retos/perfil **privado** si lo desea. |
| **Backend** | **Supabase**. |
| **Diseño** | Incluir **Fase 0.5** de guías de estilo (colores, tono, iconografía) alineadas con la marca. |

---

## Fase 0: Fundamentos técnicos y producto

**Objetivo:** Definir stack, modelo de datos y alcance del MVP.

- [ ] Configurar proyecto Supabase (auth, DB, storage si aplica).
- [ ] Definir modelo de datos: usuarios, retos, tipos de reto, check-ins/publicaciones, Zenit.
- [ ] Definir “reto” en datos: nombre, tipo (streak / cantidad / personalizado), meta, unidad, visibilidad (público/privado).
- [ ] Decidir autenticación: email + contraseña, ¿Apple/Google desde MVP?
- [ ] Documentar tipos de reto soportados en v1 (ej. días seguidos, veces por semana/mes, unidades numéricas).

**Entregable:** Documento de arquitectura (o sección en este doc) + proyecto Supabase listo para conectar Flutter.

---

## Fase 0.5: Guías de estilo y diseño (Holistia)

**Objetivo:** Colores, tono, iconografía y componentes alineados con la marca para que la app se sienta coherente.

### Colores y tema (ya en código)

- **Tema:** Definido en `lib/theme/` (oklch, light/dark).
- **Tokens:** `background`, `foreground`, `primary`, `secondary`, `muted`, `accent`, `destructive`, `border`, `card`, etc.
- **Uso:** Siempre usar `Theme.of(context)` o `Theme.of(context).extension<AppThemeExtension>()` para colores y radios/sombras.

### Tono de voz (copy)

- **Holistia:** Cercano, claro, motivador sin ser cursi.
- **Evitar:** “¡Tú puedes!”, “Sé tu mejor versión”, mensajes genéricos de autoayuda.
- **Preferir:** “7 días seguidos”, “María te envió un Zenit”, “Tu racha más larga: 12 días”, “¿Registramos hoy?”.
- **Onboarding:** Explicar en 2–3 pantallas: retos, progreso visible, comunidad y Zenit. Frases cortas.
- **Empty states:** Guiar con una acción concreta: “Crea tu primer reto”, “Comparte tu primer avance”.

### Iconografía

- **Estilo:** Consistente (outline o filled en toda la app). Preferir **outline** para navegación y acciones secundarias; **filled** para estado activo o primario (ej. Zenit dado).
- **Zenit:** Icono propio/distintivo (no un corazón genérico). Ideas: sol pequeño, estrella, rayo suave, o símbolo que evoque “pico”/cumbre (zenit).
- **Retos / progreso:** Iconos de “check”, “calendario”, “gráfica”, “trofeo/insignia”, “nivel”.
- **Fuente sugerida:** SF Symbols (iOS) / Material Icons con personalización de color según tema; o set custom si se diseña identidad fuerte para Zenit y niveles.

### Componentes y patrones

- **Cards de reto:** Fondo `card`, borde `border`, radio `radiusLg`, sombra `shadowSm` o `shadow`.
- **Botón primario:** `primary` / `primaryForeground`; secundario: `secondary` / `secondaryForeground`.
- **Destructivo:** Solo para “eliminar” o “abandonar reto”; usar `destructive`.
- **Niveles/insignias:** Colores de `chart1`–`chart5` para variedad sin salirse de la paleta.

### Documentación de diseño

- [ ] Redactar una página o doc interno (ej. `docs/DESIGN_SYSTEM.md`) con: paleta, ejemplos de copy, iconos usados y reglas de componentes.
- [ ] Opcional: Figma o archivo de referencia con componentes reutilizables.

**Entregable:** Guías de estilo documentadas y tema Flutter ya aplicado (hecho). Icono y nombre “Zenit” definidos para la UI.

---

## Fase 1: MVP – Mi progreso visible

**Objetivo:** Varios retos por usuario, medir con flexibilidad (streak, veces, unidades), progreso claro en niveles e insignias. Sin comunidad aún.

- **Auth:** Registro e inicio de sesión (email; opcional Apple/Google si se definió en Fase 0).
- **Retos:** Crear varios retos; cada uno con nombre, tipo (streak / veces / unidades), meta, unidad opcional (días, km, páginas…), visibilidad (público/privado por defecto).
- **Check-ins:** Registrar avance según el tipo de reto (día cumplido, cantidad, etc.).
- **Progreso:** Ver niveles y insignias por reto; historial y rachas.
- **Pantallas:** Onboarding, Login/Registro, Home (mis retos + resumen), Crear/editar reto, Detalle de reto (progreso, siguiente meta).

**Entregable:** App instalable (Android/iOS) con Supabase: usuario puede tener varios retos, registrar avance y ver progreso con niveles e insignias.

---

## Fase 2: Comunidad y Zenit

**Objetivo:** Progreso público por defecto, feed o descubrir, Zenit solo en publicaciones.

- **Perfil:** Público por defecto; opción “perfil o retos privados” en ajustes.
- **Publicaciones:** Cada check-in o hito puede ser una “publicación” visible (si el reto es público); el usuario puede elegir no publicar algún avance.
- **Zenit:** Dar Zenit solo a publicaciones de progreso (no a personas). Notificación al autor.
- **Feed/Descubrir:** Ver avances de otros (y dar Zenit). Celebrar con micro-interacciones en la UI.

**Entregable:** Usuario puede mostrar sus retos, publicar avances, recibir Zenit y ver avances de otros.

---

## Fase 3: Rankings y reconocimiento

**Objetivo:** Comparar (rankings) y reconocimiento público (insignias, niveles visibles).

- **Rankings:** Por reto y por periodo (semanal/mensual); opción de no aparecer en rankings.
- **Reconocimiento:** Insignias y niveles visibles en perfil; posible “destacados” (ej. más Zenit esta semana).
- **Progreso compartido:** Resúmenes o gráficas en perfil para “progreso compartido”.

**Entregable:** Rankings, insignias públicas y sensación clara de progreso compartido.

---

## Fase 4: Sistema que acompaña (constancia)

**Objetivo:** Recordatorios, estructura y sugerencias para sostener lo que se empieza.

- **Recordatorios:** Configurables por reto (hora, días).
- **Sugerencias de retos:** Por categoría (wellness, hábitos, etc.).
- **Submetas y estructura:** Submetas dentro del reto; “qué sigue” visible.
- **Insights:** Mejor racha, días más activos, próximo nivel.

**Entregable:** App que acompaña con recordatorios, estructura y sugerencias.

---

## Fase 5: Escala y “donde está pasando”

**Objetivo:** Retos comunitarios, temas/trends, sensación de lugar de referencia.

- **Retos comunitarios:** Con fecha inicio/fin; muchos usuarios en el mismo reto.
- **Temas:** Secciones por categoría (meditación, movimiento, lectura, etc.).
- **Experiencias/eventos:** Si aplica (wellness, 25–45, ingresos medios-altos).
- **Monetización:** Opcional (premium: insights, retos exclusivos, sin anuncios).

**Entregable:** Comunidad activa, retos colectivos y posicionamiento como referencia wellness.

---

## Orden y duración orientativa

| Fase | Enfoque | Duración orientativa |
|------|---------|----------------------|
| 0 | Stack, Supabase, modelo de datos | 1–2 semanas |
| 0.5 | Guías de estilo (colores, tono, iconografía) | 1–2 semanas |
| 1 | MVP: varios retos, medición flexible, niveles e insignias | 6–10 semanas |
| 2 | Comunidad, Zenit en publicaciones, feed | 4–6 semanas |
| 3 | Rankings, reconocimiento público | 3–4 semanas |
| 4 | Recordatorios, estructura, sugerencias | 4–6 semanas |
| 5 | Retos comunitarios, temas, escala | Continuo |

---

## Stack

- **App:** Flutter (solo Android e iOS).
- **Backend / BBDD / Auth:** Supabase.
- **Tema:** `lib/theme/` (oklch, light/dark, AppThemeExtension).

---

*Documento vivo: actualizar según decisiones y avances del producto.*
