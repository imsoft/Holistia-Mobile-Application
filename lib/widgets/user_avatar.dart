import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Avatar circular reutilizable con caché de imagen en disco.
///
/// Muestra [avatarUrl] si existe (con CachedNetworkImage); si no, muestra
/// la inicial de [name] sobre un fondo neutro del tema.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    this.radius = 20,
    this.textStyle,
  });

  final String name;
  final String? avatarUrl;
  final double radius;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>();
    final hasImage = avatarUrl != null && avatarUrl!.isNotEmpty;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    if (hasImage) {
      return CachedNetworkImage(
        imageUrl: avatarUrl!,
        imageBuilder: (_, imageProvider) => CircleAvatar(
          radius: radius,
          backgroundImage: imageProvider,
        ),
        placeholder: (_, _) => _InitialAvatar(
          radius: radius,
          initial: initial,
          theme: theme,
          textStyle: textStyle,
        ),
        errorWidget: (_, _, _) => _InitialAvatar(
          radius: radius,
          initial: initial,
          theme: theme,
          textStyle: textStyle,
        ),
      );
    }

    return _InitialAvatar(
      radius: radius,
      initial: initial,
      theme: theme,
      textStyle: textStyle,
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({
    required this.radius,
    required this.initial,
    required this.theme,
    this.textStyle,
  });

  final double radius;
  final String initial;
  final AppThemeExtension? theme;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: theme?.muted,
      child: Text(
        initial,
        style: textStyle ??
            Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: theme?.mutedForeground,
                  fontSize: radius * 0.8,
                ),
      ),
    );
  }
}
