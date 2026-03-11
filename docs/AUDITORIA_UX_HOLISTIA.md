# Auditoría UX – Holistia (App Flutter)

**Fecha:** Marzo 2025  
**Alcance:** Experiencia de usuario, flujos, navegación, claridad, eficiencia y coherencia en la app móvil Holistia.

---

## A. Resumen general de la experiencia actual

La app está bien estructurada a nivel técnico (GoRouter, StatefulShellRoute, skeletons, empty states en varios puntos) y cubre bien los flujos core: onboarding → auth → life wheel → feed/home. Hay **inconsistencias importantes** entre lo que el usuario espera y lo que encuentra:

- **Navegación:** La tercera pestaña del bottom bar se llama **"Perfil"** pero lleva a **Ajustes/Configuración**, no a “mi perfil público”. El perfil del usuario actual solo se ve implícitamente dentro de esa pantalla (avatar, stats). No existe una ruta tipo “Mi perfil” como en redes sociales.
- **Destino tras login:** Login redirige a `/home`, registro a `/feed`. El redirect del router, cuando el usuario entra por `/` o por una ruta de auth, envía a `/feed` (o life-wheel). Resultado: **comportamiento distinto según si entras por login o por registro**, y la “home” del producto después de login es en la práctica la pestaña Retos (`/home`), no el Feed.
- **Explorar vs Descubrir:** En Home, el ícono de la AppBar “Explorar lugares” lleva a **Professionals** (lugares/centros). En el bottom nav, “Descubrir” es el **Feed**. Para el usuario, “Explorar” y “Descubrir” pueden sonar a lo mismo; en la app son flujos distintos (lugares vs publicaciones).
- **Carga y feedback:** Donde hay skeletons (Home, Feed, Settings, Challenge detail) la experiencia es buena. Donde no (Professionals, User profile) se usa `CircularProgressIndicator` centrado y la pantalla se siente más en blanco y lenta.
- **Formularios largos:** Registro y creación/edición de retos concentran muchos campos en una sola pantalla; en móvil implica mucho scroll y decisión en bloque, lo que aumenta carga mental y abandono.
- **Tono y coherencia con bienestar:** Los textos son claros y en español. En algunos puntos (errores técnicos mostrados en crudo, pantallas muy densas en Settings) la experiencia se vuelve más “fría” y menos alineada con un producto de bienestar.

En conjunto, la base es sólida pero la **navegación y la nomenclatura** generan fricción y la **unificación de patrones** (errores, loaders, edición de perfil) mejoraría claridad y sensación de producto cuidado.

---

## B. Principales problemas UX detectados

| # | Problema | Dónde | Impacto |
|---|----------|--------|---------|
| 1 | Tab “Perfil” lleva a Ajustes, no a “mi perfil” | MainShell | Usuario espera ver su perfil público; encuentra configuración. Confusión y expectativa incumplida. |
| 2 | Login → `/home`, Register → `/feed`; redirect post-login va a `/feed` | app_router, login_screen, register_screen | Comportamiento distinto según forma de entrada. Sensación de inconsistencia. |
| 3 | No hay ruta “Mi perfil” (vista pública del usuario actual) | Router, Settings | No se puede compartir “mi perfil” ni ver cómo lo ven otros. |
| 4 | “Explorar” (lugares) vs “Descubrir” (feed) suenan igual | Home AppBar vs bottom nav | Confusión: ¿dónde exploro profesionales/centros y dónde el feed? |
| 5 | Onboarding: en la última pantalla dos CTAs hacen lo mismo (“Comenzar” y “Listo”) | onboarding_screen | Redundancia y duda sobre cuál es la acción principal. |
| 6 | Error mostrado en crudo (`e.toString()`) en SnackBars y pantallas de error | Varias pantallas | Mensajes técnicos (excepciones) asustan y no guían. No transmite calma ni confianza. |
| 7 | Settings es una sola lista muy larga (perfil + cuenta + apariencia + notificaciones + sesión + legal + eliminar) | settings_screen | Sobrecarga visual y cognitiva; difícil encontrar algo concreto. |
| 8 | Editar perfil: cada campo abre diálogo/sheet distinto | settings_screen | Muchos taps y cierres para cambiar nombre, username, sexo, fecha. Sensación lenta. |
| 9 | Notificación de post lleva a `/feed`, no al post concreto | notifications_screen | Usuario toca “alguien comentó” y llega al feed genérico, no al hilo. Frustrante. |
| 10 | Detalle de post en bottom sheet; al cerrar se hace refresh completo del feed | feed_screen | Recarga innecesaria; puede parpadear la lista. Peor performance percibida. |
| 11 | Loader genérico (spinner) en Professionals y User profile | professionals_screen, user_profile_screen | Sensación de espera mayor que con skeletons. |
| 12 | Formulario de reto (crear/editar) muy largo en una sola pantalla | challenge_form_screen | Scroll largo, muchos campos y opciones; abrumador en móvil. |
| 13 | Registro de avance (check-in) abre pantalla completa en lugar de sheet | challenge_detail_screen | Más invasivo; un sheet sería más rápido y contextual. |
| 14 | Reset password: “Cancelar e ir a iniciar sesión” hace signOut | reset_password_screen | “Cancelar” suele significar “no cambiar contraseña”, no “cerrar sesión”. Riesgo de cierre accidental. |
| 15 | Inconsistencia: ErrorRetry vs Column manual “Reintentar” | Varias pantallas | Algunas pantallas usan widget reutilizable, otras duplican el patrón. |

---

## C. Flujos con más fricción

### 1. Onboarding
- **Qué está bien:** PageView con 3 pasos, indicador de página, “Omitir” para saltar.
- **Qué está mal:** En la última pantalla, “Comenzar” y “Listo” ejecutan la misma acción; sobra un CTA. No hay forma de volver atrás (solo avanzar u omitir).
- **Propuesta:** Un solo CTA principal en la última pantalla (“Comenzar”). Quitar el TextButton “Listo”. Opcional: flecha atrás en AppBar para revisar slides anteriores.

### 2. Registro
- **Qué está bien:** Google + email, términos enlazados, validación de username.
- **Qué está mal:** Cuatro campos en una pantalla + posible validación remota de username; mucho scroll; no hay indicador de fortaleza de contraseña.
- **Propuesta:** Mantener una sola pantalla pero: (1) agregar indicador de fortaleza de contraseña, (2) validar username on blur o al salir del campo (no solo al submit) para feedback temprano, (3) considerar registro en 2 pasos (email/contraseña → nombre y username) para reducir carga en la primera pantalla.

### 3. Inicio de sesión
- **Qué está bien:** Email, contraseña, “¿Olvidaste tu contraseña?”, Google, enlace a registro.
- **Qué está mal:** Tras login, `context.go('/home')` pero el redirect del router puede llevar a `/feed` en otros flujos; inconsistencia con registro que va a `/feed`.
- **Propuesta:** Unificar destino post-login y post-registro (p. ej. siempre `/feed` o siempre `/home`) y reflejarlo en router y pantallas de auth.

### 4. Recuperación de contraseña
- **Qué está bien:** Forgot: un campo, mensaje claro al enviar. Reset: dos campos de contraseña, validación.
- **Qué está mal:** Reset no tiene AppBar; “Cancelar e ir a iniciar sesión” hace signOut y puede sorprender.
- **Propuesta:** AppBar en Reset con “Atrás” que haga `pop` o vaya a login sin signOut. Renombrar el botón secundario a “Volver a iniciar sesión” y documentar que cierra sesión, o quitar signOut y solo navegar a login.

### 5. Navegación principal (shell)
- **Qué está bien:** Tres tabs con estado preservado (indexedStack), íconos y labels.
- **Qué está mal:** “Perfil” es en realidad Ajustes; no hay acceso directo a “mi perfil” como vista pública; “Explorar” (lugares) solo desde Home.
- **Propuesta:** (1) Renombrar tab a “Ajustes” o “Más” y/o añadir cuarto tab “Perfil” que sea `/user/:myId` o ruta ` /me`. (2) O mantener 3 tabs y que “Perfil” lleve a una pantalla que combine resumen de perfil (avatar, Zenit, stats) + accesos a “Ver mi perfil público” y “Ajustes”.

### 6. Exploración / descubrimiento
- **Qué está bien:** Feed con tabs Siguiendo/Descubrir y chips de categoría; Professionals con filtros por tipo y detalle en sheet.
- **Qué está mal:** “Explorar” en Home = lugares; “Descubrir” en nav = feed. Sin búsqueda por texto en Professionals.
- **Propuesta:** Nomenclatura clara: p. ej. “Lugares” o “Centros” para Professionals; “Descubrir” solo para feed. A medio plazo: búsqueda en Professionals.

### 7. Vista de detalle (reto, lugar, post)
- **Reto:** Bien: progreso, historial, ranking, check-in. Fricción: check-in abre pantalla completa.
- **Lugar:** Bien: sheet con imagen, datos, redes, teléfono. Sin reserva/agendamiento (si no aplica, está bien).
- **Post:** Bien: sheet con comentarios. Fricción: al cerrar se hace `_load()` completo del feed.
- **Propuesta:** Check-in en bottom sheet (manteniendo subida de fotos y opción “publicar en feed”). Al cerrar post detail, actualizar solo datos del post (comentarios/reacciones) si es posible, o al menos no recargar toda la lista de forma visible.

### 8. Reserva / agendamiento / pago
- No hay flujo de reserva ni pago en el código revisado; Professionals enlaza a teléfono/redes. Si el producto no contempla reservas, está coherente. Si en el futuro se añaden, conviene un flujo dedicado (pasos claros, confirmación, recordatorios).

### 9. Perfil del usuario
- **Propio:** Solo dentro de Settings (avatar, nombre, username, Zenit, seguidores, etc.). No hay vista “mi perfil” como la de otros.
- **De otros:** User profile screen bien (avatar, stats, seguir, publicaciones). Fricción: back manual con IconButton; loader spinner; empty “Aún no hay publicaciones” sin CTA.
- **Propuesta:** Ruta “Mi perfil” reutilizando la misma vista que `/user/:id` con `userId == currentUser.id`. En perfil ajeno: AppBar con `leading` por defecto; skeleton en carga; empty state con texto + opcional CTA “Descubrir retos”.

### 10. Configuración (Settings)
- **Qué está bien:** Secciones (perfil, cuenta, apariencia, notificaciones, sesión, legal, eliminar), tema, recordatorio, cerrar sesión.
- **Qué está mal:** Todo en un ListView muy largo; edición campo a campo con diálogos; sensación de “pantalla de ajustes de sistema” más que de perfil de bienestar.
- **Propuesta:** (1) Agrupar en subpantallas o tabs (Perfil, Notificaciones, Apariencia, Cuenta y legal). (2) Pantalla “Editar perfil” con todos los campos editables en una vista (formulario) con un solo “Guardar”, reduciendo taps.

### 11. Dashboard / área privada
- Home actúa como dashboard (mis retos, rueda de vida, destacados). Bien. Fricción: el destino por defecto tras login no está unificado con el resto del sistema de redirects.

### 12. Gestión de citas / reservas
- No existe en el código. Si se añade, debe ser un flujo claro con estados (pendiente, confirmada, cancelada) y notificaciones.

### 13. Chat / comunicación
- No hay chat; interacción vía comentarios en posts y notificaciones. Coherente con el modelo actual.

### 14. Estados vacíos
- **Qué está bien:** `EmptyState` reutilizable con icono, título, subtítulo y opcional `action`; usado en Feed, Home (retos), Notifications, Professionals.
- **Qué está mal:** En User profile el empty de publicaciones es solo texto, sin componente `EmptyState` ni CTA. Algunos empty states podrían incluir un CTA (ej. “Crear reto”, “Seguir a alguien”).
- **Propuesta:** Usar `EmptyState` también en perfil de usuario (publicaciones). Revisar cada empty y añadir `action` donde tenga sentido.

### 15. Errores
- **Qué está bien:** `ErrorRetry` con mensaje y “Reintentar” en Feed, Settings, Challenge detail.
- **Qué está mal:** Mensaje = `e.toString()` (excepciones en crudo). Otras pantallas no usan `ErrorRetry` (Professionals, User profile, Notifications) y duplican el patrón.
- **Propuesta:** (1) Mensajes amigables por tipo de error (red, servidor, no encontrado) en un helper. (2) Usar `ErrorRetry` en todas las pantallas que muestran error de carga. (3) En SnackBars, evitar `e.toString()`; usar “Algo falló. Reintenta.” o similar.

### 16. Loaders
- **Qué está bien:** Skeleton en Home, Feed, Settings, Challenge detail, Notifications.
- **Qué está mal:** Professionals y User profile usan `Center(CircularProgressIndicator())`.
- **Propuesta:** Skeleton para lista de lugares (Professionals) y para perfil de usuario (avatar + stats + lista de posts placeholder).

### 17. Confirmaciones y feedback visual
- **Qué está bien:** SnackBars en check-in, actualización de perfil, invitaciones; diálogo de confirmación para eliminar reto y eliminar cuenta; optimistic UI en seguir/dejar de seguir e invitaciones.
- **Qué está mal:** Algunos SnackBars muestran “Error: $e”. FAB de notificaciones en el shell solo cuando hay no leídas puede hacer que la barra inferior cambie de aspecto de forma brusca.
- **Propuesta:** SnackBars de error con mensaje genérico o por tipo. FAB de notificaciones: mantener o sustituir por badge en el tab “Perfil”/Ajustes y quitar FAB para simplificar la barra.

---

## D. Oportunidades para reducir taps y pasos

| Acción actual | Taps / pasos | Propuesta | Ahorro |
|---------------|--------------|-----------|--------|
| Editar nombre en Settings | Entrar a Settings → tocar Nombre → diálogo → Guardar | Pantalla “Editar perfil” con todos los campos → un Guardar | Varios taps y cierres de diálogo |
| Ver “mi perfil” como otros | No existe; solo datos en Settings | Tab o entrada “Mi perfil” → misma vista que /user/:id | Nuevo flujo directo |
| Check-in desde detalle de reto | Reto → “Registrar avance” → pantalla completa → Guardar | Reto → “Registrar avance” → bottom sheet → Guardar | Menos sensación de “salir” del contexto |
| Responder invitación a reto | Notificaciones → Aceptar/Rechazar | Igual (ya está bien) | — |
| Cambiar tema | Settings → Tema → sheet → elegir | Igual o tema en línea con chips (Claro / Oscuro / Sistema) | Opcional: un tap menos |
| Ir a notificaciones | Tab Perfil + FAB si hay badge, o desde dentro de Settings | Siempre visible el badge en tab; FAB opcional | Claridad sobre dónde están las notificaciones |
| Crear reto | Home → FAB “Nuevo reto” → formulario largo | FAB → wizard (nombre + tipo → meta + fechas → opcionales) | Menos carga por pantalla; sensación de progreso |
| Navegar al post desde notificación | Notificaciones → tap → Feed (genérico) | Notificaciones → tap → Post concreto (ruta /post/:id o deep link) | Un tap menos + expectativa cumplida |

---

## E. Recomendaciones concretas por pantalla o módulo

### Onboarding
- Eliminar el botón “Listo” en la última pantalla; dejar solo “Comenzar” como CTA principal.
- Opcional: permitir volver atrás (AppBar con `leading`).
- Revisar longitud de textos; priorizar frases cortas y escaneables.

### Login
- Unificar `context.go` con el redirect del router (p. ej. siempre `context.go('/feed')` y dejar que el router lleve a life-wheel si aplica).
- Mantener layout y “¿Olvidaste tu contraseña?”; no añadir más pasos.

### Register
- Añadir indicador de fortaleza de contraseña.
- Validar disponibilidad de username al salir del campo (on blur) o con debounce, mostrando “Disponible” / “En uso”.
- Mantener términos y política; considerar registro en 2 pasos si se quiere aligerar la primera pantalla.

### Forgot / Reset password
- Forgot: está bien.
- Reset: añadir AppBar con “Atrás”. Cambiar “Cancelar e ir a iniciar sesión” por “Volver a iniciar sesión” y no hacer signOut automático, o dejar signOut pero dejando muy claro que cerrarás sesión.

### MainShell (bottom nav)
- Cambiar label del tercer tab a “Ajustes” o “Cuenta” y/o añadir ruta “Mi perfil” (p. ej. primer ítem dentro de esa pestaña o cuarto tab).
- Revisar si el FAB de notificaciones es necesario o si basta con el badge en el tab.

### Home
- Mantener “Explorar lugares” en AppBar pero considerar renombrar a “Lugares” o “Centros” para no colisionar con “Descubrir”.
- Mantener Rueda de vida, destacados, lista de retos, FAB y check-in rápido desde card.

### Feed
- Al cerrar PostDetailSheet, no hacer `_load()` completo; actualizar solo el post en la lista (comentarios/counts) o marcar como “refresco suave” si técnicamente se puede.
- Mantener tabs y chips; revisar en móvil si SegmentedButton con icon+label es demasiado grande (opcional: solo icon en breakpoint pequeño).

### Settings
- Dividir en subpantallas o secciones colapsables: “Perfil” (edición en bloque), “Notificaciones”, “Apariencia”, “Cuenta y sesión”, “Legal”, “Zona de peligro”.
- Pantalla “Editar perfil”: nombre, username, sexo, fecha de nacimiento, foto en un solo formulario con un “Guardar”.
- Mensajes de error en SnackBars: no usar `e.toString()`; usar mensajes amigables.

### Professionals
- Skeleton de lista (cards de lugar con placeholder de imagen y texto).
- AppBar: mantener “Explorar”; en copy interno/documentación alinear con “Lugares” o “Centros” para no confundir con Descubrir.
- A futuro: búsqueda por texto.

### Challenge form (crear/editar reto)
- Valorar wizard: (1) Nombre + tipo + categoría/aspecto, (2) Meta + unidad + frecuencia/fechas, (3) Invitaciones + visibilidad. Reducir scroll y sensación de formulario infinito.
- Mantener validaciones y mensajes claros.

### Challenge detail
- Check-in: sustituir `MaterialPageRoute` por bottom sheet (DraggableScrollableSheet) con el mismo formulario (valor, nota, fotos, “publicar en feed”). Mantener celebraciones (level up, aspecto).
- Mantener invite sheet y confirmación de eliminación.

### User profile (de otro usuario)
- AppBar con `leading: BackButton()` o `automaticallyImplyLeading: true` en lugar de IconButton manual.
- Skeleton durante carga (avatar, stats, lista de cards de post).
- Empty state de publicaciones con `EmptyState` y opcional CTA “Descubrir retos” o “Ver feed”.

### Notifications
- Al tocar notificación de post: navegar a detalle del post si existe ruta (p. ej. `/feed?postId=...` o `/post/:id`). Si no, dejar comentario en código para implementarlo y no navegar solo a `/feed`.
- Mantener Aceptar/Rechazar en invitaciones; skeleton ya está.

### Post detail sheet
- Mantener sheet y comentarios. Si se implementa actualización parcial del feed al cerrar, no recargar toda la lista.

### Componentes compartidos
- **Error:** Usar `ErrorRetry` (o equivalente) en Professionals, User profile, Notifications con mensaje amigable.
- **Empty:** Usar `EmptyState` en perfil de usuario (publicaciones) y donde aún se use solo texto.
- **Loader:** Skeleton para Professionals y User profile; mantener skeletons actuales en el resto.

---

## F. Quick wins (fáciles de implementar)

1. **Onboarding:** Quitar el botón “Listo” en la última pantalla; dejar solo “Comenzar”.
2. **Unificar destino post-login:** Hacer que login y register usen el mismo `context.go` (p. ej. `/feed`) y asegurar que el redirect del router sea coherente.
3. **Reset password:** Añadir AppBar con back; cambiar texto del botón secundario a “Volver a iniciar sesión” y documentar o ajustar signOut.
4. **ErrorRetry y mensajes:** Usar `ErrorRetry` en Professionals y User profile; sustituir `e.toString()` por mensaje genérico en SnackBars (ej. “Algo falló. Reintenta.”).
5. **Skeleton en Professionals:** Crear `SkeletonPlaceList` (o reutilizar patrón de skeleton de cards) y usarlo en `ProfessionalsScreen` mientras carga.
6. **Skeleton en User profile:** Crear `SkeletonUserProfile` (avatar + chips + lista de placeholders) y usarlo en `UserProfileScreen`.
7. **User profile back:** Usar `AppBar(automaticallyImplyLeading: true)` y quitar el `SliverToBoxAdapter` con `IconButton` manual.
8. **Empty state en perfil:** En “Aún no hay publicaciones” usar widget `EmptyState` con icono y subtítulo; opcional CTA.
9. **Label del tab:** Cambiar “Perfil” a “Ajustes” o “Cuenta” en `MainShell` para que coincida con el contenido.
10. **Notificaciones → post:** Si existe o se añade ruta a post (ej. query param o path), usar esa ruta en `_handleNotificationTap` en lugar de solo `/feed`.

---

## G. Mejoras de alto impacto que requieren rediseño

1. **“Mi perfil” como vista pública:** Nueva ruta (ej. `/me` o `/user/me`) que muestre la misma vista que `/user/:id` para el usuario actual, con edición en Ajustes. Implica router, posible nuevo ítem en shell o en Ajustes, y coherencia con compartir perfil.
2. **Reorganización de Settings:** Dividir en subpantallas o tabs (Perfil, Notificaciones, Apariencia, Cuenta, Legal, Peligro) y pantalla “Editar perfil” con formulario único. Reduce carga cognitiva y número de taps.
3. **Check-in en bottom sheet:** Cambiar `_CheckInFormScreen` de pantalla completa a `DraggableScrollableSheet` en Challenge detail. Mejora sensación de fluidez y contexto.
4. **Formulario de reto en wizard:** Dividir crear/editar reto en 2–3 pasos (nombre/tipo → meta/fechas → invitaciones/opciones). Requiere refactor de `ChallengeFormScreen` y posible estado de pasos.
5. **Navegación al post desde notificación:** Ruta o deep link a post concreto (ej. `/post/:id` o feed con scroll a postId). Requiere soporte en backend y en router.
6. **Mensajes de error centralizados:** Capa de traducción de excepciones a mensajes amigables (red, servidor, validación, no encontrado) y uso en toda la app (pantallas de error y SnackBars).
7. **Consistencia de loaders:** Todas las pantallas con lista o contenido asíncrono usando skeleton en lugar de spinner; definir skeletons para cada tipo de pantalla que aún no lo tenga.

---

## H. Lista priorizada de cambios recomendados

### Prioridad alta
1. Unificar destino después de login/registro y alinear con redirect del router.
2. Renombrar tab “Perfil” a “Ajustes” (o “Cuenta”) o añadir flujo “Mi perfil” y dejar “Perfil” para eso.
3. Quitar doble CTA en última pantalla de onboarding (“Listo” / “Comenzar” → solo uno).
4. Reset password: AppBar + texto/claridad del botón “Volver a iniciar sesión” (y signOut).
5. Sustituir mensajes de error técnicos (`e.toString()`) por mensajes amigables en SnackBars y pantallas de error.
6. Usar ErrorRetry y skeletons en Professionals y User profile; EmptyState en publicaciones vacías del perfil.

### Prioridad media
7. Check-in desde detalle de reto en bottom sheet en lugar de pantalla completa.
8. Al cerrar post detail, no recargar todo el feed (actualización parcial o “suave”).
9. Navegación desde notificación de post al post concreto (ruta/deep link).
10. User profile: AppBar con back estándar y skeleton de carga.
11. Clarificar nomenclatura “Explorar” (lugares) vs “Descubrir” (feed) en UI y copy.

### Prioridad baja
12. Pantalla “Editar perfil” con todos los campos en un solo formulario.
13. Reorganizar Settings en subpantallas o secciones.
14. Wizard para crear/editar reto (2–3 pasos).
15. Indicador de fortaleza de contraseña en registro y validación de username on blur.
16. FAB de notificaciones: evaluar si se mantiene o solo badge en tab.

---

## Enfoque Holistia (bienestar, confianza, calma)

- **Errores y mensajes:** Evitar lenguaje técnico; mensajes cortos, calmados y orientados a acción (“Algo falló. Reintenta.” / “Revisa tu conexión.”).
- **Settings:** Menos “panel de control” y más “tu espacio”: agrupar por “Tu perfil”, “Preferencias”, “Cuenta”, “Legal”.
- **Onboarding y auth:** Mantener tono positivo (“Comienza a medir y celebrar tus retos”) y evitar pasos de más.
- **Empty states:** Textos que inviten sin presionar (“Cuando publiques tu primer avance, aparecerá aquí”) y CTAs opcionales (“Crear reto”, “Descubrir retos”).
- **Confirmaciones destructivas:** Mantener diálogos claros (eliminar reto, eliminar cuenta) con opción de cancelar destacada.

Con estos cambios, la app gana en coherencia, claridad y sensación de producto cuidado y alineado con bienestar, sin necesidad de rediseños visuales grandes en una primera fase.
