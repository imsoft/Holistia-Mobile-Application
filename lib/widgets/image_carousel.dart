import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Carrusel horizontal de imágenes de red con indicadores de página animados.
///
/// - 1 imagen → se muestra directamente sin indicadores.
/// - 2-6 imágenes → PageView horizontal + dots animados abajo.
///
/// Uso:
/// ```dart
/// ImageCarousel(imageUrls: post.imageUrls, height: 200)
/// ```
class ImageCarousel extends StatefulWidget {
  const ImageCarousel({
    super.key,
    required this.imageUrls,
    this.height = 200,
  });

  final List<String> imageUrls;

  /// Altura del área de imagen (no incluye los dots).
  final double height;

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context).extension<AppThemeExtension>();
    final hasMultiple = widget.imageUrls.length > 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(theme?.radiusMd ?? 8),
          child: SizedBox(
            height: widget.height,
            width: double.infinity,
            child: PageView.builder(
              itemCount: widget.imageUrls.length,
              onPageChanged: hasMultiple
                  ? (i) => setState(() => _currentIndex = i)
                  : null,
              itemBuilder: (context, i) => _NetworkImage(
                url: widget.imageUrls[i],
                height: widget.height,
                theme: theme,
              ),
            ),
          ),
        ),
        if (hasMultiple) ...[
          const SizedBox(height: 8),
          _PageDots(
            count: widget.imageUrls.length,
            current: _currentIndex,
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _NetworkImage extends StatelessWidget {
  const _NetworkImage({
    required this.url,
    required this.height,
    required this.theme,
  });

  final String url;
  final double height;
  final AppThemeExtension? theme;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      width: double.infinity,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        height: height,
        color: theme?.muted,
        child: Icon(
          Icons.broken_image_outlined,
          color: theme?.mutedForeground,
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 16 : 6,
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: primary.withValues(alpha: isActive ? 1.0 : 0.3),
          ),
        );
      }),
    );
  }
}
