import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'push_notification_service.dart';

/// Notifier para que el router se actualice cuando cambie la sesión.
class HolistiaAuthState extends ChangeNotifier {
  HolistiaAuthState() {
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      // Iniciar/detener push notifications según el estado de autenticación
      if (event.session != null) {
        PushNotificationService().startListening();
      } else {
        PushNotificationService().stopListening();
      }
      notifyListeners();
    });

    // Iniciar si ya hay sesión al crear el estado
    if (Supabase.instance.client.auth.currentUser != null) {
      PushNotificationService().startListening();
    }
  }

  late final StreamSubscription<AuthState> _sub;

  User? get currentUser => Supabase.instance.client.auth.currentUser;
  bool get isSignedIn => currentUser != null;

  /// true si la app se abrió desde el enlace de recuperación de contraseña.
  bool _pendingPasswordReset = false;
  bool get pendingPasswordReset => _pendingPasswordReset;

  /// Revisa el URI inicial y marca si es un flujo de reset de contraseña.
  Future<void> checkInitialUriForPasswordReset() async {
    try {
      final uri = await AppLinks().getInitialLink();
      if (uri != null && uri.toString().contains('reset-password')) {
        _pendingPasswordReset = true;
        notifyListeners();
      }
    } catch (_) {
      // Ignorar si no se puede obtener el enlace
    }
  }

  void clearPendingPasswordReset() {
    if (_pendingPasswordReset) {
      _pendingPasswordReset = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
