import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';

/// Solicita el permiso de App Tracking Transparency (ATT) en iOS cuando aún no
/// se ha decidido ([TrackingStatus.notDetermined]).
///
/// Cumple con la Guideline **5.1.2(i)** cuando la app declara recopilar datos
/// usados para *tracking* en App Store Connect: el sistema debe mostrar el
/// diálogo de ATT **antes** de acceder al identificador de publicidad (IDFA).
///
/// Si en realidad no hacéis *tracking* según la definición de Apple, debéis
/// corregir las etiquetas de privacidad en App Store Connect; este prompt puede
/// mostrarse igualmente y el usuario puede denegar sin problema.
Future<void> requestAppTrackingTransparencyIfNeeded() async {
  if (kIsWeb) return;
  if (defaultTargetPlatform != TargetPlatform.iOS) return;

  try {
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status != TrackingStatus.notDetermined) return;

    // Breve espera para que el primer frame se pinte (mejor UX y revisión).
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await AppTrackingTransparency.requestTrackingAuthorization();
  } catch (_) {
    // Simulador antiguo, tests, o plugin no enlazado: no bloquear el arranque.
  }
}
