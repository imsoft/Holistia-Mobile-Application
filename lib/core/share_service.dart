import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../models/post.dart';
import '../theme/app_theme.dart';

/// Servicio para compartir publicaciones, incluyendo Instagram Stories.
/// Instagram Stories requiere compartir una imagen; el sistema mostrará
/// Instagram en la hoja de compartir nativa al compartir un archivo de imagen.
class ShareService {
  ShareService();

  static const double _shareCardWidth = 400;
  static const double _shareCardHeight = 500;

  /// Comparte un post como imagen para que aparezca en Instagram Stories
  /// (y otras apps que reciban imágenes en la hoja de compartir).
  Future<void> sharePostToStories(Post post, BuildContext context) async {
    final theme = Theme.of(context).extension<AppThemeExtension>();
    final textTheme = Theme.of(context).textTheme;

    File? imageFile;
    if (post.imageUrls.isNotEmpty) {
      imageFile = await _downloadImage(post.imageUrls.first);
    }

    if (imageFile == null || !await imageFile.exists()) {
      imageFile = await _generateShareCard(
        post: post,
        theme: theme,
        textTheme: textTheme,
      );
    }

    if (imageFile == null || !await imageFile.exists()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo preparar la imagen para compartir')),
        );
      }
      return;
    }

    final author = post.displayName ?? 'Usuario';
    final challenge = post.challengeName ?? 'Reto';
    final body = post.body ?? '';
    final caption = '$author compartió su avance en $challenge.\n$body\n\n— Holistia';

    try {
      await Share.shareXFiles(
        [XFile(imageFile.path)],
        text: caption,
        subject: 'Avance en Holistia',
      );
    } catch (e) {
      if (context.mounted) {
        try {
          await Share.share(caption, subject: 'Avance en Holistia');
        } catch (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Detén la app y ejecuta de nuevo con flutter run para habilitar compartir.'),
            ),
          );
        }
      }
    }

    try {
      await imageFile.delete();
    } catch (_) {}
  }

  Future<File?> _downloadImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return null;

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/holistia_share_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await file.writeAsBytes(response.bodyBytes);
      return file;
    } catch (_) {
      return null;
    }
  }

  Future<File?> _generateShareCard({
    required Post post,
    required AppThemeExtension? theme,
    required TextTheme textTheme,
  }) async {
    final controller = ScreenshotController();

    final widget = RepaintBoundary(
      child: Material(
        color: theme?.background ?? Colors.white,
        child: Container(
          width: _shareCardWidth,
          height: _shareCardHeight,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme?.card ?? Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme?.border ?? Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Holistia',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme?.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                post.displayName ?? 'Usuario',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme?.foreground,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                post.challengeName ?? 'Reto',
                style: textTheme.bodyMedium?.copyWith(
                  color: theme?.mutedForeground,
                ),
              ),
              if (post.body != null && post.body!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  post.body!,
                  style: textTheme.bodyLarge?.copyWith(
                    color: theme?.foreground,
                  ),
                ),
              ],
              const Spacer(),
              Text(
                '— Holistia',
                style: textTheme.bodySmall?.copyWith(
                  color: theme?.mutedForeground,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final image = await controller.captureFromWidget(
        MediaQuery(
          data: const MediaQueryData(devicePixelRatio: 2),
          child: Theme(
            data: ThemeData.light(),
            child: widget,
          ),
        ),
        pixelRatio: 2,
      );

      if (image.isEmpty) return null;

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/holistia_share_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(image);

      return file;
    } catch (_) {
      return null;
    }
  }
}
