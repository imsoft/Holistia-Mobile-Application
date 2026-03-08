# Prompt: Auditoría Técnica Flutter (Staff/Principal Engineer)

Actúa como un Staff/Principal Flutter Engineer y "performance & architecture reviewer".
Necesito que revises TODO mi proyecto Flutter (Dart) en este repo y me entregues una auditoría técnica con mejoras aplicables.

## OBJETIVO
- Asegurar mejores prácticas modernas de Flutter/Dart.
- Maximizar reusabilidad (componentes/widgets), aplicar DRY.
- Mejorar arquitectura y mantenibilidad.
- Optimizar performance (UI smooth, menos jank), tamaño del APK/AAB, y tiempos de arranque.
- Reducir dependencias innecesarias y mejorar tree-shaking.
- Detectar y corregir anti-patrones comunes.

## REGLAS DE ENTREGA (IMPORTANTE)
1. No me des teoría genérica: dame hallazgos concretos con referencias a rutas/archivos/clases/funciones.
2. Prioriza por impacto: "P0 crítico", "P1 alto", "P2 medio", "P3 bajo".
3. Para cada hallazgo, incluye:
   - Problema
   - Evidencia (archivo(s) y fragmento relevante)
   - Riesgo/Impacto
   - Solución recomendada
   - Ejemplo de código (antes/después) cuando aplique
4. Produce un "Plan de acción" en 3 fases:
   - Quick wins (1–2 días)
   - Refactor mediano (3–7 días)
   - Cambios estructurales (1–3 semanas)
5. Si propones cambios grandes, sugiere migración incremental (sin romper todo de golpe).

## CHECKLIST DE AUDITORÍA (CÚBRELA COMPLETA)

### A) Arquitectura / Estructura
- Organización por features vs capas, consistencia de carpetas.
- Separación UI / domain / data (o el patrón actual) y si está bien aplicado.
- Recomendación de patrón (Clean, MVVM, BLoC, Riverpod, etc.) según el estado real del proyecto.
- Manejo de routing, navegación y deep links (si existen).

### B) Reusabilidad / DRY
- Widgets repetidos que deben extraerse (botones, cards, inputs, layouts, loaders, empty states).
- "Design system" mínimo: spacing, typography, colors, theme extensions.
- Helpers duplicados, validadores repetidos, mappers repetidos.

### C) Performance UI
- Uso correcto de const constructors, keys, rebuilds innecesarios.
- Listas: ListView.builder, slivers, itemExtent, cacheExtent.
- Imágenes: caching, tamaños, placeholders, formatos.
- Animaciones: evitar overdraw, repaints excesivos.
- Detecta lugares donde falta memoización / split de widgets / selectors (según state mgmt).

### D) State Management
- Revisa la solución actual (Provider/Riverpod/BLoC/GetX/etc).
- Anti-patrones: lógica en UI, estados gigantes, rebuild masivo, side effects mal ubicados.
- Recomendaciones concretas para mejorar: scopes, providers, notifiers, streams.

### E) Tamaño de la app (APK/AAB) / Build
- Revisa pubspec.yaml y dependencias: elimina o reemplaza pesadas.
- Fonts: subsetting, assets no usados.
- Assets: compresión, tamaños, organización, remover duplicados.
- Flavors, build modes, proguard/r8, shrinkResources (Android), bitcode (iOS si aplica).
- Recomendaciones para tree shaking y reducción del bundle.

### F) Código y Estándares
- Análisis con lint (analysis_options.yaml): reglas faltantes.
- Null safety, late, dynamic, casts peligrosos.
- Errores silenciosos, try/catch inútiles.
- Logging, manejo de errores, excepciones.
- Testing: unit/widget/integration (si no hay, define mínimo set).

### G) Networking / Data
- Clients, interceptors, retries, timeouts.
- Serialización (json_serializable/freezed) y modelos consistentes.
- Cache local (si aplica) y estrategias.

### H) Seguridad y Robustez
- Secretos en repo, keys, endpoints.
- Validación de inputs y manejo seguro de storage.
- Permisos y configuraciones.

## MODO DE TRABAJO
1. Empieza haciendo un mapa del proyecto:
   - Principales features, capas, entry points, navegación, state mgmt, dependencias clave.
2. Después ejecuta una auditoría por secciones (A–H) y registra hallazgos.
3. Finalmente entrega:
   - Resumen ejecutivo (10–15 bullets)
   - Tabla de hallazgos priorizada (P0–P3)
   - Plan de acción por fases
   - Lista de PRs sugeridos (PR1, PR2, PR3...) con alcance y archivos tocados

## SALIDA
- Usa Markdown.
- Incluye snippets de código y paths completos.
- Si necesitas asumir algo, dilo explícitamente.

---

**Ahora: analiza el repo y comienza por el "Mapa del proyecto".**
