import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_date_utils.dart';
import '../../core/user_facing_errors.dart';
import '../../core/challenge_icons.dart';
import '../../core/zenit_level.dart';
import '../../models/challenge.dart';
import '../../models/check_in.dart';
import '../../models/profile.dart';
import '../../repositories/challenge_invitation_repository.dart';
import '../../repositories/challenge_repository.dart';
import '../../repositories/check_in_repository.dart';
import '../../repositories/life_assessment_repository.dart';
import '../../repositories/post_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../widgets/level_up_overlay.dart';
import '../../theme/app_theme.dart';
import '../../widgets/error_retry.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/streak_badge.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/weekly_chart.dart';

class ChallengeDetailScreen extends StatefulWidget {
  const ChallengeDetailScreen({super.key, required this.challengeId});

  final String challengeId;

  @override
  State<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen> {
  final _challengeRepo = ChallengeRepository();
  final _checkInRepo = CheckInRepository();
  final _postRepo = PostRepository();
  final _inviteRepo = ChallengeInvitationRepository();
  final _profileRepo = ProfileRepository();
  final _lifeAssessmentRepo = LifeAssessmentRepository();

  Challenge? _challenge;
  List<CheckIn> _checkIns = [];
  List<DayStat> _weeklyStats = [];
  List<LeaderboardEntry> _leaderboard = [];
  bool _loading = true;
  bool _addingCheckIn = false;
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
      final c = await _challengeRepo.getById(widget.challengeId);
      final results = await Future.wait([
        _checkInRepo.getByChallengeId(widget.challengeId),
        _checkInRepo.getWeeklyStats(widget.challengeId),
        _checkInRepo.getLeaderboard(widget.challengeId),
      ]);
      if (mounted) {
        setState(() {
          _challenge = c;
          _checkIns = results[0] as List<CheckIn>;
          _weeklyStats = results[1] as List<DayStat>;
          _leaderboard = results[2] as List<LeaderboardEntry>;
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

  Future<void> _addCheckIn() async {
    if (_addingCheckIn) return;
    setState(() => _addingCheckIn = true);
    try {
      await _doAddCheckIn();
    } finally {
      if (mounted) setState(() => _addingCheckIn = false);
    }
  }

  Future<void> _doAddCheckIn() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final existing = await _checkInRepo.getByChallengeAndDate(widget.challengeId, today);
    if (existing != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ya registraste hoy')),
      );
      return;
    }

    final result = await _showCheckInForm();
    if (result == null || !mounted) return;

    try {
      // Capturar estado ANTES del check-in para detectar celebraciones
      final aspect = _challenge?.lifeAspect;
      final futures = await Future.wait([
        _profileRepo.getMyProfile(),
        if (aspect != null) _lifeAssessmentRepo.getMyAspectAssessment(aspect),
      ]);
      final profileBefore = futures[0] as AppProfile?;
      final assessmentBefore = aspect != null ? futures[1] as dynamic : null;
      final balanceBefore = profileBefore?.zenitBalance ?? 0;
      final levelBefore = ZenitLevel.fromBalance(balanceBefore);
      final countBefore = (assessmentBefore?.checkInCount as int?) ?? 0;
      final scoreBefore = (assessmentBefore?.score as int?) ?? 0;

      final imageUrls = result.imagePaths.isNotEmpty
          ? await _postRepo.uploadImages(result.imagePaths)
          : <String>[];

      final checkIn = await _checkInRepo.insert(
        challengeId: widget.challengeId,
        date: today,
        value: result.value,
        note: result.note?.trim().isEmpty ?? true ? null : result.note?.trim(),
        imageUrls: imageUrls,
      );

      if (result.publishToFeed == true) {
        final body = (result.note?.trim().isNotEmpty ?? false)
            ? result.note!.trim()
            : (result.value != null && (_challenge?.unit ?? '').isNotEmpty)
                ? '${result.value} ${_challenge?.unit} hoy'
                : 'Avance registrado';
        await _postRepo.insert(
          challengeId: widget.challengeId,
          checkInId: checkIn.id,
          body: body,
          imageUrls: imageUrls,
        );
      }

      if (!mounted) return;

      _load();

      // ── Detectar subida de nivel de zenits ──────────────────────────────
      const zenitsPerCheckIn = 5;
      final newBalance = balanceBefore + zenitsPerCheckIn;
      final levelAfter = ZenitLevel.fromBalance(newBalance);
      var celebrationShown = false;

      if (levelAfter != levelBefore) {
        celebrationShown = true;
        await LevelUpOverlay.show(
          context,
          level: levelAfter,
          newBalance: newBalance,
        );
        if (!mounted) return;
      }

      // ── Detectar mejora de aspecto (cada 10 check-ins) ─────────────────
      if (aspect != null && scoreBefore < 5 && (countBefore + 1) % 10 == 0) {
        celebrationShown = true;
        await AspectUpOverlay.show(
          context,
          aspect: aspect,
          newScore: scoreBefore + 1,
        );
        if (!mounted) return;
      }

      // ── Snackbar normal si no hubo celebración ──────────────────────────
      if (!celebrationShown) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.publishToFeed == true ? 'Avance publicado' : 'Avance registrado'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFacingErrorMessage(e))),
        );
      }
    }
  }

  void _showInviteSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(
            Theme.of(context).extension<AppThemeExtension>()?.radiusLg ?? 16,
          ),
        ),
      ),
      builder: (_) => _InviteSheet(
        challengeId: widget.challengeId,
        repo: _inviteRepo,
      ),
    );
  }

  Future<_CheckInFormResult?> _showCheckInForm() async {
    return showModalBottomSheet<_CheckInFormResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _CheckInFormScreen(
          challenge: _challenge!,
          theme: Theme.of(context).extension<AppThemeExtension>(),
          scrollController: scrollController,
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(Challenge c) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar reto'),
        content: Text('¿Estás seguro de que quieres eliminar "${c.name}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      try {
        await _challengeRepo.delete(c.id);
        if (mounted) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reto eliminado')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(userFacingErrorMessage(e))),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>();
    final colorScheme = Theme.of(context).colorScheme;

    if (_loading) {
      return const SkeletonChallengeDetail();
    }
    if (_error != null || _challenge == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: ErrorRetry(
          message: _error ?? 'Reto no encontrado',
          onRetry: _load,
        ),
      );
    }

    final c = _challenge!;
    final progress = _computeProgress(c);
    final canCheckInToday = _canCheckInToday();

    final iconData = ChallengeIcons.fromCodePoint(c.iconCodePoint);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (iconData != null) ...[
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(iconData, size: 24),
              ),
            ],
            Expanded(child: Text(c.name)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'Invitar a este reto',
            onPressed: _showInviteSheet,
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/challenges/${c.id}/edit').then((_) => _load()),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _showDeleteConfirmation(c),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
              Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(theme?.radiusLg ?? 8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        progress.summary,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: colorScheme.primary,
                            ),
                      ),
                      if (progress.currentStreak > 0) ...[
                        const SizedBox(height: 8),
                        StreakBadge(count: progress.currentStreak),
                      ],
                      if (progress.subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          progress.subtitle!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: theme?.mutedForeground,
                              ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (c.target > 0 && progress.remainingText != null) ...[
                        _PathRoadWidget(
                          progressValue: progress.progressValue,
                          remainingText: progress.remainingText!,
                          theme: theme,
                          colorScheme: colorScheme,
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Icon(Icons.calendar_today, size: 16, color: theme?.mutedForeground),
                                const SizedBox(height: 4),
                                Text(
                                  'Fecha de inicio',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: theme?.mutedForeground,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  AppDateUtils.formatDate(c.startDate ?? c.createdAt),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          if (c.endDate != null) ...[
                            Expanded(
                              child: Column(
                                children: [
                                  Icon(Icons.event, size: 16, color: theme?.mutedForeground),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Fecha de fin',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: theme?.mutedForeground,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    AppDateUtils.formatDate(c.endDate!),
                                    style: Theme.of(context).textTheme.bodyMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (_weeklyStats.any((s) => s.value > 0)) ...[
                const SizedBox(height: 20),
                Text(
                  'Esta semana',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: theme?.mutedForeground,
                      ),
                ),
                const SizedBox(height: 8),
                WeeklyChart(stats: _weeklyStats),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: canCheckInToday && !_addingCheckIn ? _addCheckIn : null,
                  icon: const Icon(Icons.add_circle_outline),
                  label: Text(canCheckInToday ? 'Registrar avance hoy' : 'Ya registraste hoy'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(theme?.radiusMd ?? 8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Historial',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: theme?.mutedForeground,
                    ),
              ),
              const SizedBox(height: 8),
              if (_checkIns.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Aún no hay registros. Registra tu primer avance.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: theme?.mutedForeground,
                        ),
                  ),
                )
              else
                ..._checkIns.take(30).map((ci) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: ci.imageUrls.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(theme?.radiusMd ?? 8),
                              child: Image.network(
                                ci.imageUrls.first,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Icon(Icons.image_not_supported_outlined, color: theme?.mutedForeground),
                              ),
                            )
                          : null,
                      title: Text(
                        AppDateUtils.formatRelativeDay(ci.date),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      subtitle: ci.note != null && ci.note!.isNotEmpty
                          ? Text(
                              ci.note!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: theme?.mutedForeground,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                      trailing: ci.value != null
                          ? Text(
                              '${ci.value} ${c.unit ?? ""}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: theme?.mutedForeground,
                                  ),
                            )
                          : const Icon(Icons.check_circle_outline, color: Colors.green),
                    )),
              if (_leaderboard.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Ranking',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: theme?.mutedForeground,
                      ),
                ),
                const SizedBox(height: 8),
                ..._leaderboard.take(10).toList().asMap().entries.map((e) {
                  final rank = e.key + 1;
                  final entry = e.value;
                  final medal = rank == 1
                      ? '🥇'
                      : rank == 2
                          ? '🥈'
                          : rank == 3
                              ? '🥉'
                              : '$rank.';
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: UserAvatar(
                      name: entry.displayName,
                      avatarUrl: entry.avatarUrl,
                    ),
                    title: Text(entry.displayName),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          medal,
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${entry.total}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  ({String summary, String? subtitle, int currentStreak, double progressValue, String? remainingText}) _computeProgress(Challenge c) {
    final unitStr = c.unit != null && c.unitAmount != null ? ' · ${c.unitAmount} ${c.unit} por día/sesión' : '';
    if (_checkIns.isEmpty) {
      final targetStr = c.type == ChallengeType.countUnits
          ? '${c.target} ${c.unit ?? ""}'
          : '${c.target}$unitStr';
      final remaining = c.type == ChallengeType.streak
          ? 'Te faltan ${c.target.toInt()} días'
          : c.type == ChallengeType.countUnits
              ? 'Te faltan ${c.target} ${c.unit ?? "unidades"}'
              : 'Meta: ${c.target.toInt()} ${c.frequency?.label ?? ""}';
      return (
        summary: '0 de $targetStr',
        subtitle: 'Comienza registrando tu primer avance',
        currentStreak: 0,
        progressValue: 0.0,
        remainingText: remaining,
      );
    }
    switch (c.type) {
      case ChallengeType.streak:
        final streak = _currentStreak();
        final target = c.target.toInt();
        final daysLeft = (target - streak).clamp(0, target);
        return (
          summary: 'Racha: $streak días',
          subtitle: 'Meta: $target días seguidos$unitStr',
          currentStreak: streak,
          progressValue: target > 0 ? (streak / target).clamp(0.0, 1.0) : 0.0,
          remainingText: daysLeft > 0 ? 'Te faltan $daysLeft días' : '¡Meta alcanzada!',
        );
      case ChallengeType.countTimes:
        final count = _countInCurrentPeriod(c.frequency);
        final target = c.target.toInt();
        final left = (target - count).clamp(0, target);
        final periodEnds = _getPeriodEndText(c.frequency);
        return (
          summary: '$count de $target ${c.frequency?.label ?? ""}$unitStr',
          subtitle: null,
          currentStreak: 0,
          progressValue: target > 0 ? (count / target).clamp(0.0, 1.0) : 0.0,
          remainingText: periodEnds != null
              ? 'Periodo termina $periodEnds'
              : (left > 0 ? 'Te faltan $left registros' : '¡Periodo completado!'),
        );
      case ChallengeType.countUnits:
        final total = _checkIns.fold<num>(0, (s, ci) => s + (ci.value ?? 0));
        final target = c.target;
        final unitsLeft = (target - total).clamp(0.0, target);
        return (
          summary: '$total ${c.unit ?? "unidades"}',
          subtitle: 'Meta: $target ${c.unit ?? ""}',
          currentStreak: 0,
          progressValue: target > 0 ? (total / target).clamp(0.0, 1.0) : 0.0,
          remainingText: unitsLeft > 0 ? 'Te faltan $unitsLeft ${c.unit ?? "unidades"}' : '¡Meta alcanzada!',
        );
    }
  }

  String? _getPeriodEndText(ChallengeFrequency? freq) {
    if (freq == null) return null;
    final now = DateTime.now();
    if (freq == ChallengeFrequency.daily) return 'mañana';
    if (freq == ChallengeFrequency.weekly) {
      final daysToSunday = 8 - now.weekday;
      if (daysToSunday == 7) return 'en 7 días';
      if (daysToSunday == 1) return 'mañana';
      return 'en $daysToSunday días';
    }
    if (freq == ChallengeFrequency.monthly) {
      final lastDay = DateTime(now.year, now.month + 1, 0);
      final daysLeft = lastDay.difference(now).inDays + 1;
      if (daysLeft == 1) return 'mañana';
      return 'en $daysLeft días';
    }
    return null;
  }

  int _currentStreak() {
    if (_checkIns.isEmpty) return 0;
    final dates = _checkIns.map((c) => DateTime(c.date.year, c.date.month, c.date.day)).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    if (dates.isEmpty) return 0;
    final mostRecent = dates.first;
    final diffFromToday = today.difference(mostRecent).inDays;
    if (diffFromToday > 1) return 0;
    var streak = 1;
    var prev = mostRecent;
    for (var i = 1; i < dates.length; i++) {
      final d = dates[i];
      if (prev.difference(d).inDays == 1) {
        streak++;
        prev = d;
      } else {
        break;
      }
    }
    return streak;
  }

  int _countInCurrentPeriod(ChallengeFrequency? freq) {
    if (freq == null) return _checkIns.length;
    final now = DateTime.now();
    DateTime start;
    if (freq == ChallengeFrequency.daily) {
      start = DateTime(now.year, now.month, now.day);
    } else if (freq == ChallengeFrequency.weekly) {
      final weekday = now.weekday;
      start = DateTime(now.year, now.month, now.day - (weekday - 1));
    } else {
      start = DateTime(now.year, now.month);
    }
    return _checkIns.where((c) => c.date.isAfter(start.subtract(const Duration(days: 1)))).length;
  }

  bool _canCheckInToday() {
    final today = DateTime.now();
    return !_checkIns.any((c) =>
        c.date.year == today.year && c.date.month == today.month && c.date.day == today.day);
  }

}

/// Visualización tipo "camino" con progreso y tiempo/unidades restantes.
class _PathRoadWidget extends StatelessWidget {
  const _PathRoadWidget({
    required this.progressValue,
    required this.remainingText,
    required this.theme,
    required this.colorScheme,
  });

  final double progressValue;
  final String remainingText;
  final AppThemeExtension? theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: (theme?.muted ?? Colors.grey.shade200).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme?.border ?? Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.timeline, size: 18, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        remainingText,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: theme?.foreground,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                CustomPaint(
                  size: const Size(double.infinity, 20),
                  painter: _PathRoadPainter(
                    progress: progressValue,
                    fillColor: colorScheme.primary,
                    trackColor: theme?.muted ?? Colors.grey.shade300,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${(progressValue * 100).toInt()}%',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
          ),
        ],
      ),
    );
  }
}

class _PathRoadPainter extends CustomPainter {
  _PathRoadPainter({
    required this.progress,
    required this.fillColor,
    required this.trackColor,
  });

  final double progress;
  final Color fillColor;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.fill;
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final r = size.height / 2;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(r),
    );
    canvas.drawRRect(rect, trackPaint);

    if (progress > 0) {
      final fillWidth = (size.width * progress).clamp(0.0, size.width);
      final fillRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, fillWidth, size.height),
        Radius.circular(r),
      );
      canvas.drawRRect(fillRect, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PathRoadPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _CheckInFormResult {
  const _CheckInFormResult({
    this.value,
    this.note,
    this.imagePaths = const [],
    this.publishToFeed = false,
  });
  final num? value;
  final String? note;
  final List<String> imagePaths;
  final bool publishToFeed;
}

// ─────────────────────────────────────────────────────────────────────────────
// Formulario de registro de avance con soporte para hasta 6 imágenes
// ─────────────────────────────────────────────────────────────────────────────

class _CheckInFormScreen extends StatefulWidget {
  const _CheckInFormScreen({
    required this.challenge,
    this.theme,
    this.scrollController,
  });
  final Challenge challenge;
  final AppThemeExtension? theme;
  final ScrollController? scrollController;

  @override
  State<_CheckInFormScreen> createState() => _CheckInFormScreenState();
}

class _CheckInFormScreenState extends State<_CheckInFormScreen> {
  static const int _maxImages = 6;

  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _noteController = TextEditingController();
  final List<String> _imagePaths = [];
  bool _publishToFeed = false;

  @override
  void dispose() {
    _valueController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool get _canAddMore => _imagePaths.length < _maxImages;

  Future<void> _pickFromSource(ImageSource source) async {
    if (!_canAddMore) return;
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: source,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (xFile != null && mounted) {
      setState(() => _imagePaths.add(xFile.path));
    }
  }

  void _removeImage(int index) {
    setState(() => _imagePaths.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final theme =
        widget.theme ?? Theme.of(context).extension<AppThemeExtension>();
    final c = widget.challenge;
    final needsValue = c.type == ChallengeType.countUnits;
    final isSheet = widget.scrollController != null;

    final formContent = Form(
      key: _formKey,
      child: ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.all(24),
            children: [
              // ── Cantidad ─────────────────────────────────────────────────
              TextFormField(
                controller: _valueController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: needsValue
                      ? '¿Cuánto cumpliste hoy? (${c.unit ?? "unidades"})'
                      : '¿Cuánto cumpliste hoy? (${c.unit ?? "opcional"})',
                  hintText: needsValue ? 'Ej. 5.2' : 'Ej. 5 kilómetros',
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(theme?.radiusMd ?? 8),
                  ),
                ),
                validator: needsValue
                    ? (v) {
                        if (v == null || v.trim().isEmpty) return 'Obligatorio';
                        if (num.tryParse(v.trim()) == null) {
                          return 'Escribe un número';
                        }
                        return null;
                      }
                    : null,
              ),
              const SizedBox(height: 24),

              // ── Nota ─────────────────────────────────────────────────────
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: 'Descripción (opcional)',
                  hintText: '¿Cómo te fue hoy?',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(theme?.radiusMd ?? 8),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // ── Imágenes (hasta 6) ────────────────────────────────────────
              Row(
                children: [
                  Text(
                    'Imágenes',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: theme?.mutedForeground,
                        ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_imagePaths.length}/$_maxImages',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: theme?.mutedForeground,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Miniaturas seleccionadas + botón añadir
              if (_imagePaths.isNotEmpty) ...[
                SizedBox(
                  height: 88,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount:
                        _imagePaths.length + (_canAddMore ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      if (i == _imagePaths.length) {
                        return _AddImageButton(
                          theme: theme,
                          onGallery: () =>
                              _pickFromSource(ImageSource.gallery),
                          onCamera: () =>
                              _pickFromSource(ImageSource.camera),
                        );
                      }
                      return _ImageThumbnail(
                        path: _imagePaths[i],
                        theme: theme,
                        onRemove: () => _removeImage(i),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ] else ...[
                // Sin imágenes: mostramos los botones directamente
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () => _pickFromSource(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library, size: 20),
                      label: const Text('Galería'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => _pickFromSource(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt, size: 20),
                      label: const Text('Cámara'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // ── Publicar en feed ──────────────────────────────────────────
              if (c.isPublic) ...[
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Publicar en el feed'),
                  subtitle:
                      const Text('Otros podrán ver tu avance y darte Zenit'),
                  value: _publishToFeed,
                  onChanged: (v) => setState(() => _publishToFeed = v),
                ),
              ],
              const SizedBox(height: 32),

              FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(theme?.radiusMd ?? 8),
                  ),
                ),
                child: const Text('Guardar avance'),
              ),
            ],
          ),
        );

    if (isSheet) {
      return Material(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  Text(
                    'Registrar avance',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(child: formContent),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar avance'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(child: formContent),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final valueStr = _valueController.text.trim();
    final value = valueStr.isEmpty ? null : num.tryParse(valueStr);

    if (widget.challenge.type == ChallengeType.countUnits && value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indica cuánto cumpliste hoy')),
      );
      return;
    }

    if (mounted) {
      Navigator.of(context).pop(_CheckInFormResult(
        value: value,
        note: _noteController.text.trim(),
        imagePaths: List.unmodifiable(_imagePaths),
        publishToFeed: _publishToFeed,
      ));
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets del formulario de imágenes
// ─────────────────────────────────────────────────────────────────────────────

class _ImageThumbnail extends StatelessWidget {
  const _ImageThumbnail({
    required this.path,
    required this.theme,
    required this.onRemove,
  });

  final String path;
  final AppThemeExtension? theme;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(theme?.radiusMd ?? 8),
          child: Image.file(
            File(path),
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(2),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddImageButton extends StatelessWidget {
  const _AddImageButton({
    required this.theme,
    required this.onGallery,
    required this.onCamera,
  });

  final AppThemeExtension? theme;
  final VoidCallback onGallery;
  final VoidCallback onCamera;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet<void>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galería'),
                onTap: () {
                  Navigator.pop(ctx);
                  onGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Cámara'),
                onTap: () {
                  Navigator.pop(ctx);
                  onCamera();
                },
              ),
            ],
          ),
        ),
      ),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: theme?.muted,
          borderRadius: BorderRadius.circular(theme?.radiusMd ?? 8),
          border: Border.all(
            color: theme?.border ?? Colors.grey.shade300,
          ),
        ),
        child: Icon(
          Icons.add_photo_alternate_outlined,
          color: theme?.mutedForeground,
          size: 28,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sheet para invitar seguidores al reto (límite: 8 por reto)
// ─────────────────────────────────────────────────────────────────────────────

class _InviteSheet extends StatefulWidget {
  const _InviteSheet({required this.challengeId, required this.repo});

  final String challengeId;
  final ChallengeInvitationRepository repo;

  @override
  State<_InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends State<_InviteSheet> {
  List<AppProfile>? _profiles;
  Set<String> _invitedIds = {};
  String? _error;

  static const _maxInvites = 8;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        widget.repo.getFollowingProfiles(),
        widget.repo.getInvitedUserIds(widget.challengeId),
      ]);
      if (mounted) {
        setState(() {
          _profiles = results[0] as List<AppProfile>;
          _invitedIds = results[1] as Set<String>;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = userFacingErrorMessage(e));
    }
  }

  Future<void> _invite(String userId) async {
    if (_invitedIds.length >= _maxInvites) return;
    // Optimistic update
    setState(() => _invitedIds = {..._invitedIds, userId});
    try {
      await widget.repo.invite(widget.challengeId, userId);
    } catch (e) {
      if (mounted) {
        setState(() => _invitedIds = Set.from(_invitedIds)..remove(userId));
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(userFacingErrorMessage(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>();
    final colorScheme = Theme.of(context).colorScheme;
    final atLimit = _invitedIds.length >= _maxInvites;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: theme?.mutedForeground,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Invitar a este reto',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: atLimit
                          ? colorScheme.errorContainer
                          : colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_invitedIds.length}/$_maxInvites',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: atLimit
                                ? colorScheme.onErrorContainer
                                : colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: theme?.mutedForeground),
                        ),
                      ),
                    )
                  : _profiles == null
                      ? const Center(child: CircularProgressIndicator.adaptive())
                      : _profiles!.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Text(
                                  'No sigues a nadie aún.\nSigue a otras personas para poder invitarlas.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: theme?.mutedForeground),
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              itemCount: _profiles!.length,
                              itemBuilder: (context, i) {
                                final p = _profiles![i];
                                final isInvited = _invitedIds.contains(p.id);
                                return ListTile(
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  leading: UserAvatar(
                                    name: p.displayName ?? p.username ?? '?',
                                    avatarUrl: p.avatarUrl,
                                    radius: 22,
                                  ),
                                  title: Text(
                                    p.displayName ?? p.username ?? 'Usuario',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w500),
                                  ),
                                  subtitle: p.username != null
                                      ? Text('@${p.username}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                  color: theme?.mutedForeground))
                                      : null,
                                  trailing: isInvited
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.check_circle,
                                                color: colorScheme.primary,
                                                size: 20),
                                            const SizedBox(width: 4),
                                            Text('Invitado',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                        color:
                                                            colorScheme.primary)),
                                          ],
                                        )
                                      : atLimit
                                          ? null
                                          : FilledButton.tonal(
                                              onPressed: () => _invite(p.id),
                                              style: FilledButton.styleFrom(
                                                  visualDensity:
                                                      VisualDensity.compact),
                                              child: const Text('Invitar'),
                                            ),
                                );
                              },
                            ),
            ),
          ],
        );
      },
    );
  }
}
