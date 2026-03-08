import 'package:flutter/material.dart';

/// Iconos disponibles para retos. Se guarda el codePoint en la base de datos.
class ChallengeIcons {
  ChallengeIcons._();

  static const List<IconData> icons = [
    Icons.flag,
    Icons.local_fire_department,
    Icons.directions_run,
    Icons.fitness_center,
    Icons.directions_walk,
    Icons.sports_soccer,
    Icons.menu_book,
    Icons.water_drop,
    Icons.bedtime,
    Icons.restaurant,
    Icons.self_improvement,
    Icons.psychology,
    Icons.eco,
    Icons.star,
    Icons.bolt,
    Icons.favorite,
    Icons.lightbulb_outline,
    Icons.school,
    Icons.music_note,
    Icons.language,
    Icons.emoji_events,
    Icons.directions_bike,
    Icons.wb_sunny_outlined,
  ];

  /// Devuelve el IconData correspondiente al codePoint buscándolo en la lista.
  /// Usar la lista evita construir IconData en runtime, permitiendo el tree-shaking.
  static IconData? fromCodePoint(int? codePoint) {
    if (codePoint == null) return null;
    for (final icon in icons) {
      if (icon.codePoint == codePoint) return icon;
    }
    return null;
  }
}
