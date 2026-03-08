import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Estado vacío reutilizable con icono, título y subtítulo opcional.
///
/// Uso:
/// ```dart
/// EmptyState(
///   icon: Icons.notifications_none,
///   title: 'Sin notificaciones',
///   subtitle: 'Aquí aparecerán cuando lleguen.',
/// )
/// ```
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.padding = 32,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  /// Widget opcional debajo del texto (p.ej. un botón de acción).
  final Widget? action;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>();
    return Center(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 80, color: theme?.mutedForeground),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: theme?.mutedForeground),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
