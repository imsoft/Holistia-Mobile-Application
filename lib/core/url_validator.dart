/// Valida URLs antes de abrirlas con url_launcher.
/// Previene open redirect hacia URLs maliciosas provenientes de la base de datos.
class UrlValidator {
  /// Retorna true si la URL es segura para abrir en el navegador externo.
  /// Solo permite HTTPS y rechaza localhost e IPs privadas.
  static bool isSafeToLaunch(String rawUrl) {
    if (rawUrl.isEmpty) return false;
    try {
      final url = rawUrl.startsWith('http') ? rawUrl : 'https://$rawUrl';
      final uri = Uri.parse(url);
      if (uri.scheme != 'https') return false;
      if (uri.host.isEmpty) return false;
      final host = uri.host;
      if (host == 'localhost' ||
          host == '127.0.0.1' ||
          host.startsWith('192.168.') ||
          host.startsWith('10.') ||
          host.startsWith('172.')) {
        return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
