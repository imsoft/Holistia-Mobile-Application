import 'package:flutter/material.dart';

/// Definición de una insignia computada.
class BadgeDefinition {
  const BadgeDefinition({
    required this.emoji,
    required this.label,
    required this.description,
  });

  final String emoji;
  final String label;
  final String description;
}

/// Lista de todas las insignias posibles.
const _allBadges = [
  BadgeDefinition(
    emoji: '🏆',
    label: 'Primer paso',
    description: 'Hiciste tu primer check-in',
  ),
  BadgeDefinition(
    emoji: '💪',
    label: 'Constante',
    description: 'Check-in en los últimos 7 días',
  ),
  BadgeDefinition(
    emoji: '🔥',
    label: 'Racha de 7',
    description: '7 días seguidos en un reto',
  ),
  BadgeDefinition(
    emoji: '📅',
    label: 'Mes completo',
    description: '30 días de racha',
  ),
  BadgeDefinition(
    emoji: '🌟',
    label: 'Social',
    description: '5 o más seguidores',
  ),
  BadgeDefinition(
    emoji: '🤝',
    label: 'Comunidad',
    description: 'Invitado a un reto por alguien',
  ),
];

/// Muestra las insignias ganadas por el usuario.
///
/// Parámetros:
/// - [totalCheckIns]: total de check-ins del usuario.
/// - [currentStreak]: racha actual máxima.
/// - [followerCount]: número de seguidores.
/// - [wasInvited]: si el usuario fue invitado a algún reto.
/// - [recentCheckIn]: si hubo check-in en los últimos 7 días.
class ChallengeBadges extends StatelessWidget {
  const ChallengeBadges({
    super.key,
    required this.totalCheckIns,
    required this.currentStreak,
    required this.followerCount,
    this.wasInvited = false,
    this.recentCheckIn = false,
  });

  final int totalCheckIns;
  final int currentStreak;
  final int followerCount;
  final bool wasInvited;
  final bool recentCheckIn;

  List<BadgeDefinition> get _earned {
    final earned = <BadgeDefinition>[];
    if (totalCheckIns >= 1) earned.add(_allBadges[0]);
    if (recentCheckIn) earned.add(_allBadges[1]);
    if (currentStreak >= 7) earned.add(_allBadges[2]);
    if (currentStreak >= 30) earned.add(_allBadges[3]);
    if (followerCount >= 5) earned.add(_allBadges[4]);
    if (wasInvited) earned.add(_allBadges[5]);
    return earned;
  }

  @override
  Widget build(BuildContext context) {
    final badges = _earned;
    if (badges.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: badges.map((b) => _BadgeChip(badge: b)).toList(),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.badge});

  final BadgeDefinition badge;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: badge.description,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(badge.emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 5),
            Text(
              badge.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
