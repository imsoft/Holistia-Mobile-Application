# Mensajes de consola al probar la app (debug)

Cuando ejecutas la app en **modo debug** (sobre todo en el **simulador de iOS**), la consola muestra muchos mensajes. La mayoría son **normales** y no indican errores en tu app.

## Resumen rápido

| Mensaje | ¿Es problema? | Qué hacer |
|--------|----------------|-----------|
| Supabase init completed | No, es bueno | Nada. Supabase está bien configurado. |
| FlutterView / focusItemsInRect | No | Ignorar. Mensaje del sistema. |
| fopen failed / Invalidating cache | No | Ignorar. Caché del simulador; se reconstruye solo. |
| Dart VM service listening | No | Normal en debug. |
| unhandled element \<filter/\>; Svg loader | Advertencia menor | Los logos se ven bien; el paquete SVG no soporta filtros. |
| (501) Invalidation / usermanagerd | No | Típico del simulador iOS. |
| Client not entitled / RBSServiceErrorDomain | No | Simulador sin permisos de dispositivo real. |

---

## Explicación de cada mensaje

### ✅ Supabase init completed

- **Qué es:** Confirmación de que Supabase se inicializó correctamente.
- **Acción:** Ninguna. Tu backend está conectado.

### FlutterView implements focusItemsInRect...

- **Qué es:** Aviso del sistema sobre el comportamiento de foco en la vista Flutter (iOS/macOS).
- **Acción:** Ignorar. No afecta el funcionamiento.

### Dart execution mode: JIT

- **Qué es:** En debug, Dart usa JIT (compilación en tiempo de ejecución).
- **Acción:** Normal. En release se usa AOT y este mensaje no aparece.

### fopen failed for data file / Errors found! Invalidating cache...

- **Qué es:** El motor gráfico (Skia) o el simulador no encuentra un archivo de caché y lo invalida.
- **Acción:** Ignorar. La caché se regenera. Muy común en simulador.

### The Dart VM service is listening on http://127.0.0.1:...

- **Qué es:** El servidor de depuración de Flutter (hot reload, DevTools, etc.).
- **Acción:** Normal en debug.

### unhandled element \<filter/\>; Picture key: Svg loader

- **Qué es:** Los logos de Holistia (SVG) usan `<filter>` (p. ej. `feColorMatrix`). El paquete `flutter_svg` no implementa filtros SVG y muestra esta advertencia.
- **Efecto:** Los logos se renderizan; solo se ignoran los efectos de filtro. Visualmente suele ser igual.
- **Acción (opcional):** Si quieres quitar el mensaje, habría que usar SVGs sin `<filter>` o cambiar a PNG para los logos. No es necesario para que la app funcione.

### (501) Invalidation handler invoked / usermanagerd.xpc invalidated

- **Qué es:** Mensajes del sistema iOS relacionados con servicios del simulador.
- **Acción:** Ignorar. Muy habitual en simulador.

### Client not entitled / RBSServiceErrorDomain / elapsedCPUTimeForFrontBoard

- **Qué es:** El simulador no tiene los mismos “entitlements” que un iPhone real (p. ej. RunningBoard, gestión de procesos).
- **Acción:** Ignorar. En dispositivo físico o en build de release suelen no aparecer.

---

## Cómo tener menos ruido en consola

1. **Probar en dispositivo físico**  
   `flutter run` con el iPhone conectado. Muchos mensajes del simulador desaparecen.

2. **Probar en modo release**  
   ```bash
   flutter run --release
   ```
   No se conecta el VM service ni JIT; salen menos mensajes de Flutter/Dart.

3. **Filtrar por “flutter:”**  
   En la terminal o en el panel de run, filtra por `flutter:` para ver solo los logs de tu app y de Flutter.

4. **No hacer caso a mensajes del sistema**  
   Los que mencionan “entitled”, “usermanagerd”, “FrontBoard”, “RBSService” son del sistema/simulador, no de tu código.

---

## Conclusión

Tu app está funcionando correctamente. Esos mensajes son típicos del entorno de desarrollo (debug + simulador iOS). Si la app abre, navega y Supabase responde, no necesitas cambiar nada por ellos.  
Si quieres una consola más limpia, usa dispositivo físico y/o `flutter run --release` cuando solo quieras probar comportamiento sin depurar.
