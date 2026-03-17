import 'dart:io';

/// Valida imágenes antes de subirlas a Supabase Storage.
/// Verifica existencia, tamaño y extensión permitida.
class ImageValidator {
  static const int maxBytes = 10 * 1024 * 1024; // 10 MB
  static const Set<String> allowedExts = {
    'jpg', 'jpeg', 'png', 'webp', 'heic', 'heif',
  };

  /// Retorna null si el archivo es válido, o un mensaje de error si no.
  static Future<String?> validate(String localPath) async {
    final file = File(localPath);
    if (!await file.exists()) return 'El archivo no existe';

    final size = await file.length();
    if (size == 0) return 'El archivo está vacío';
    if (size > maxBytes) return 'La imagen no puede superar 10 MB';

    final ext = localPath.split('.').last.toLowerCase();
    if (!allowedExts.contains(ext)) return 'Formato no permitido ($ext)';

    return null;
  }
}
