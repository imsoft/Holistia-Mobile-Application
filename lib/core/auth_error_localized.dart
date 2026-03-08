import 'package:supabase_flutter/supabase_flutter.dart';

/// Traduce mensajes de error de Supabase Auth al español.
String localizedAuthMessage(AuthException e) {
  final msg = e.message.toLowerCase();

  if (msg.contains('email not confirmed') || msg.contains('email_not_confirmed')) {
    return 'Confirma tu correo antes de iniciar sesión. Revisa el enlace que te enviamos.';
  }
  if (msg.contains('invalid login') || msg.contains('invalid_credentials')) {
    return 'Correo o contraseña incorrectos.';
  }
  if (msg.contains('user already registered') || msg.contains('already registered')) {
    return 'Este correo ya está registrado.';
  }
  if (msg.contains('password') && msg.contains('6')) {
    return 'La contraseña debe tener al menos 6 caracteres.';
  }
  if (msg.contains('email rate limit') || msg.contains('rate limit')) {
    return 'Demasiados intentos. Espera unos minutos.';
  }
  if (msg.contains('token') && (msg.contains('expired') || msg.contains('invalid'))) {
    return 'El enlace ha caducado. Solicita uno nuevo.';
  }
  if (msg.contains('forbidden') || msg.contains('not allowed')) {
    return 'No tienes permiso para realizar esta acción.';
  }

  return e.message.isNotEmpty ? e.message : 'Ocurrió un error. Intenta de nuevo.';
}
