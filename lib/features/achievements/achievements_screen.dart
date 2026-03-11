import 'package:flutter/material.dart';

import '../../core/user_facing_errors.dart';
import '../../core/zenit_level.dart';
import '../../repositories/profile_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/error_retry.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final _profileRepo = ProfileRepository();
  int _zenitBalance = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await _profileRepo.getMyProfile();
      if (mounted) {
        setState(() {
          _zenitBalance = profile?.zenitBalance ?? 0;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = userFacingErrorMessage(e);
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Logros')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorRetry(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _CurrentLevelCard(
                        balance: _zenitBalance,
                        theme: theme,
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Tu viaje Zenit',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: theme?.mutedForeground,
                            ),
                      ),
                      const SizedBox(height: 12),
                      _LevelsTimeline(
                        balance: _zenitBalance,
                        theme: theme,
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Hitos',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: theme?.mutedForeground,
                            ),
                      ),
                      const SizedBox(height: 12),
                      _MilestonesGrid(
                        balance: _zenitBalance,
                        theme: theme,
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card de nivel actual con barra de progreso
// ─────────────────────────────────────────────────────────────────────────────

class _CurrentLevelCard extends StatelessWidget {
  const _CurrentLevelCard({
    required this.balance,
    required this.theme,
    required this.colorScheme,
  });

  final int balance;
  final AppThemeExtension? theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final level = ZenitLevel.fromBalance(balance);
    final progress = level.progress(balance);
    final nextAt = level.nextLevelAt;
    final remaining = nextAt != null ? nextAt - balance : null;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme?.radiusLg ?? 16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              level.emoji,
              style: const TextStyle(fontSize: 56),
            ),
            const SizedBox(height: 12),
            Text(
              level.label,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: level.color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '$balance zenits',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: theme?.mutedForeground,
                  ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: level.color.withValues(alpha: 0.15),
                color: level.color,
              ),
            ),
            const SizedBox(height: 8),
            if (remaining != null)
              Text(
                '$remaining zenits para ${_nextLevel(level)?.label ?? ''}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: theme?.mutedForeground,
                    ),
              )
            else
              Text(
                '¡Nivel máximo alcanzado! ✨',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: level.color,
                      fontWeight: FontWeight.w600,
                    ),
              ),
          ],
        ),
      ),
    );
  }

  ZenitLevel? _nextLevel(ZenitLevel current) {
    final idx = ZenitLevel.values.indexOf(current);
    if (idx < ZenitLevel.values.length - 1) {
      return ZenitLevel.values[idx + 1];
    }
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Timeline vertical de todos los niveles
// ─────────────────────────────────────────────────────────────────────────────

class _LevelsTimeline extends StatelessWidget {
  const _LevelsTimeline({
    required this.balance,
    required this.theme,
    required this.colorScheme,
  });

  final int balance;
  final AppThemeExtension? theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final current = ZenitLevel.fromBalance(balance);
    final levels = ZenitLevel.values;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme?.radiusLg ?? 12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            for (var i = 0; i < levels.length; i++) ...[
              _LevelRow(
                level: levels[i],
                isUnlocked: balance >= levels[i].startsAt,
                isCurrent: levels[i] == current,
                theme: theme,
                colorScheme: colorScheme,
              ),
              if (i < levels.length - 1)
                Padding(
                  padding: const EdgeInsets.only(left: 36),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 2,
                      height: 20,
                      color: (balance >= levels[i + 1].startsAt
                              ? levels[i].color
                              : theme?.muted)
                          ?.withValues(alpha: 0.5),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LevelRow extends StatelessWidget {
  const _LevelRow({
    required this.level,
    required this.isUnlocked,
    required this.isCurrent,
    required this.theme,
    required this.colorScheme,
  });

  final ZenitLevel level;
  final bool isUnlocked;
  final bool isCurrent;
  final AppThemeExtension? theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Círculo de nivel
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isUnlocked
                  ? level.color.withValues(alpha: 0.15)
                  : (theme?.muted ?? Colors.grey.withValues(alpha: 0.2)),
              border: isCurrent
                  ? Border.all(color: level.color, width: 2)
                  : null,
            ),
            child: Center(
              child: Text(
                isUnlocked ? level.emoji : '🔒',
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Nombre + requisito
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      level.label,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: isCurrent
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isUnlocked ? null : theme?.mutedForeground,
                          ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: level.color,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Actual',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  _desc(level),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: theme?.mutedForeground,
                      ),
                ),
              ],
            ),
          ),
          // Zenits requeridos
          Text(
            '${level.startsAt} ⚡',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isUnlocked ? level.color : theme?.mutedForeground,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  String _desc(ZenitLevel l) {
    switch (l) {
      case ZenitLevel.semilla:
        return 'Estás empezando tu viaje';
      case ZenitLevel.brote:
        return 'Estás construyendo hábitos';
      case ZenitLevel.raiz:
        return 'Tu constancia echa raíces';
      case ZenitLevel.arbol:
        return 'Tu crecimiento es sólido';
      case ZenitLevel.bosque:
        return 'Inspiras a quienes te rodean';
      case ZenitLevel.cosmos:
        return 'Has trascendido los límites';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Grid de hitos
// ─────────────────────────────────────────────────────────────────────────────

class _MilestonesGrid extends StatelessWidget {
  const _MilestonesGrid({
    required this.balance,
    required this.theme,
    required this.colorScheme,
  });

  final int balance;
  final AppThemeExtension? theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final milestones = _buildMilestones();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: milestones.length,
      itemBuilder: (ctx, i) => _MilestoneTile(
        milestone: milestones[i],
        theme: theme,
        colorScheme: colorScheme,
      ),
    );
  }

  List<_Milestone> _buildMilestones() => [
        _Milestone(
          emoji: '🎯',
          title: 'Primer paso',
          desc: '5 zenits',
          isUnlocked: balance >= 5,
          color: AppSemanticColors.milestone1,
        ),
        _Milestone(
          emoji: '🔟',
          title: 'Décimo check-in',
          desc: '50 zenits',
          isUnlocked: balance >= 50,
          color: AppSemanticColors.milestone2,
        ),
        _Milestone(
          emoji: '🔥',
          title: 'En racha',
          desc: '100 zenits',
          isUnlocked: balance >= 100,
          color: AppSemanticColors.milestone3,
        ),
        _Milestone(
          emoji: '💪',
          title: 'Constante',
          desc: '300 zenits',
          isUnlocked: balance >= 300,
          color: AppSemanticColors.milestone4,
        ),
        _Milestone(
          emoji: '🏆',
          title: 'Comprometido',
          desc: '700 zenits',
          isUnlocked: balance >= 700,
          color: AppSemanticColors.milestone5,
        ),
        _Milestone(
          emoji: '⭐',
          title: 'Inspirador',
          desc: '1500 zenits',
          isUnlocked: balance >= 1500,
          color: AppSemanticColors.milestone6,
        ),
        _Milestone(
          emoji: '🌟',
          title: 'Leyenda',
          desc: '3000 zenits',
          isUnlocked: balance >= 3000,
          color: AppSemanticColors.milestone7,
        ),
        _Milestone(
          emoji: '🌱',
          title: 'Nivel Semilla',
          desc: 'Alcanzado',
          isUnlocked: balance >= 0,
          color: const Color(0xFF81C784),
        ),
        _Milestone(
          emoji: '🌿',
          title: 'Nivel Brote',
          desc: '100 zenits',
          isUnlocked: balance >= 100,
          color: const Color(0xFF4CAF50),
        ),
      ];
}

class _Milestone {
  const _Milestone({
    required this.emoji,
    required this.title,
    required this.desc,
    required this.isUnlocked,
    required this.color,
  });

  final String emoji;
  final String title;
  final String desc;
  final bool isUnlocked;
  final Color color;
}

class _MilestoneTile extends StatelessWidget {
  const _MilestoneTile({
    required this.milestone,
    required this.theme,
    required this.colorScheme,
  });

  final _Milestone milestone;
  final AppThemeExtension? theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final unlocked = milestone.isUnlocked;
    return Container(
      decoration: BoxDecoration(
        color: unlocked
            ? milestone.color.withValues(alpha: 0.12)
            : (theme?.muted ?? Colors.grey.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(theme?.radiusMd ?? 12),
        border: unlocked
            ? Border.all(
                color: milestone.color.withValues(alpha: 0.4), width: 1.5)
            : null,
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            unlocked ? milestone.emoji : '🔒',
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(height: 6),
          Text(
            milestone.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: unlocked ? null : theme?.mutedForeground,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            milestone.desc,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: unlocked ? milestone.color : theme?.mutedForeground,
                  fontSize: 10,
                ),
          ),
        ],
      ),
    );
  }
}
