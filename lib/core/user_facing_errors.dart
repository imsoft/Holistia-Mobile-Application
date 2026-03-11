/// Mensajes de error amigables para el usuario (UX).
/// Evita mostrar excepciones técnicas en SnackBars y pantallas de error.
String userFacingErrorMessage(Object error) {
  final msg = error.toString().toLowerCase();
  if (msg.contains('socket') ||
      msg.contains('connection') ||
      msg.contains('network') ||
      msg.contains('internet') ||
      msg.contains('timeout') ||
      msg.contains('failed host lookup')) {
    return 'Revisa tu conexión a internet e inténtalo de nuevo.';
  }
  if (msg.contains('401') || msg.contains('unauthorized') || msg.contains('session')) {
    return 'Tu sesión pudo haber expirado. Vuelve a iniciar sesión.';
  }
  if (msg.contains('403') || msg.contains('forbidden')) {
    return 'No tienes permiso para hacer esto.';
  }
  if (msg.contains('404') || msg.contains('not found')) {
    return 'No encontrado. Puede que ya no exista.';
  }
  if (msg.contains('500') ||
      msg.contains('502') ||
      msg.contains('503') ||
      msg.contains('server') ||
      msg.contains('internal')) {
    return 'Algo falló en el servidor. Inténtalo más tarde.';
  }
  if (msg.contains('duplicate') || msg.contains('unique') || msg.contains('already exists')) {
    return 'Ese valor ya está en uso. Prueba con otro.';
  }
  return 'Algo salió mal. Reintenta.';
}
