import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/challenge_icons.dart';
import '../../core/user_facing_errors.dart';
import '../../core/local_notification_service.dart';
import '../../core/streak_calculator.dart';
import '../../models/challenge.dart';
import '../../models/check_in.dart';
import '../../models/life_aspect.dart';
import '../../models/life_assessment.dart';
import '../../repositories/challenge_repository.dart';
import '../../repositories/check_in_repository.dart';
import '../../repositories/life_assessment_repository.dart';
import '../../models/profile.dart';
import '../../repositories/profile_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/life_wheel_chart.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/streak_badge.dart';

const _keyReminderHour = 'pref_reminder_hour';
const _keyReminderMinute = 'pref_reminder_minute';
const _keyReminderEnabled = 'pref_reminder_enabled';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repo = ChallengeRepository();
  final _checkInRepo = CheckInRepository();
  final _assessmentRepo = LifeAssessmentRepository();
  final _profileRepo = ProfileRepository();

  List<Challenge> _challenges = [];
  List<Challenge> _featured = [];
  List<LifeAssessment> _assessments = [];
  Map<String, int> _streaks = {};
  Map<String, bool> _checkedInToday = {};
  final Set<String> _checkingIn = {};
  LifeAspect? _selectedAspect;
  int _zenitBalance = 0;

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (Supabase.instance.client.auth.currentUser == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<dynamic>([
        _repo.getMyChallenges(),
        _repo.getFeaturedChallenges(),
        _assessmentRepo.getMyAssessments(),
        _profileRepo.getMyProfile(),
      ]);

      final challenges = results[0] as List<Challenge>;
      final featured = results[1] as List<Challenge>;
      final assessments = results[2] as List<LifeAssessment>;
      final profile = results[3] as AppProfile?;

      // Batch: 2 queries para N retos en lugar de 2N queries
      final today = DateTime.now();
      final ids = challenges.map((c) => c.id).toList();
      final batchResults = await Future.wait<dynamic>([
        _checkInRepo.getBatchByChallengeIds(ids),
        _checkInRepo.getCheckedInTodayBatch(ids, today),
      ]);
      final allCheckIns = batchResults[0] as Map<String, List<CheckIn>>;
      final todaySet = batchResults[1] as Set<String>;

      final streaks = <String, int>{};
      final checkedInToday = <String, bool>{};
      for (final c in challenges) {
        streaks[c.id] = computeStreak(allCheckIns[c.id] ?? []);
        checkedInToday[c.id] = todaySet.contains(c.id);
      }

      if (mounted) {
        setState(() {
          _challenges = challenges;
          _featured = featured;
          _assessments = assessments;
          _streaks = streaks;
          _checkedInToday = checkedInToday;
          _zenitBalance = profile?.zenitBalance ?? 0;
          _loading = false;
        });
        await _scheduleReminderIfNeeded(challenges);
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

  Future<void> _scheduleReminderIfNeeded(List<Challenge> challenges) async {
    if (challenges.isEmpty) {
      await LocalNotificationService().cancelDailyReminder();
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_keyReminderEnabled) ?? true;
    if (!enabled) {
      await LocalNotificationService().cancelDailyReminder();
      return;
    }
    final hour = prefs.getInt(_keyReminderHour) ?? 9;
    final minute = prefs.getInt(_keyReminderMinute) ?? 0;
    await LocalNotificationService().scheduleDailyReminder(
      hour: hour,
      minute: minute,
      title: '¡No olvides registrar tu reto!',
      body: 'Es momento de registrar tu progreso diario',
    );
  }

  Future<void> _quickCheckIn(String challengeId) async {
    if (_checkingIn.contains(challengeId)) return;
    setState(() => _checkingIn.add(challengeId));
    try {
      await _checkInRepo.insert(
        challengeId: challengeId,
        date: DateTime.now(),
        value: 1,
      );
      if (mounted) {
        setState(() {
          _checkedInToday[challengeId] = true;
          _checkingIn.remove(challengeId);
          // Incrementar streak en 1 localmente
          _streaks[challengeId] = (_streaks[challengeId] ?? 0) + 1;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Check-in registrado! 🎉')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _checkingIn.remove(challengeId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFacingErrorMessage(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis retos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.explore_outlined),
            tooltip: 'Lugares',
            onPressed: () => context.push('/professionals'),
          ),
        ],
      ),
      body: _loading
          ? const SkeletonChallengeList()
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _load,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: CustomScrollView(
                    slivers: [
                      _LifeWheelSection(
                        assessments: _assessments,
                        zenitBalance: _zenitBalance,
                        selectedAspect: _selectedAspect,
                        onAspectTap: (aspect) => setState(() {
                          _selectedAspect =
                              _selectedAspect == aspect ? null : aspect;
                        }),
                        onEdit: () => context
                            .push('/life-wheel')
                            .then((_) => _load()),
                        theme: theme,
                        colorScheme: colorScheme,
                      ),
                      if (_featured.isNotEmpty)
                        _FeaturedSection(
                          challenges: _featured,
                          theme: theme,
                          colorScheme: colorScheme,
                        ),
                      Builder(builder: (context) {
                        if (_selectedAspect != null) {
                          return SliverToBoxAdapter(
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 8, 16, 0),
                              child: Row(
                                children: [
                                  Icon(Icons.filter_list,
                                      size: 16,
                                      color: _selectedAspect!.color),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Filtrando: ${_selectedAspect!.label}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: _selectedAspect!.color,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () => setState(
                                        () => _selectedAspect = null),
                                    child: Icon(Icons.close,
                                        size: 16,
                                        color: _selectedAspect!.color),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return const SliverToBoxAdapter(child: SizedBox.shrink());
                      }),
                      Builder(builder: (context) {
                        final filtered = _selectedAspect == null
                            ? _challenges
                            : _challenges
                                .where((c) => c.lifeAspect == _selectedAspect)
                                .toList();
                        if (filtered.isEmpty) {
                          return SliverFillRemaining(
                            child: EmptyState(
                              icon: _selectedAspect != null
                                  ? Icons.search_off
                                  : Icons.flag_outlined,
                              title: _selectedAspect != null
                                  ? 'Sin retos en este aspecto'
                                  : 'Crea tu primer reto',
                              subtitle: _selectedAspect != null
                                  ? 'No tienes retos vinculados a este aspecto de vida. Crea uno o cambia el aspecto al editar un reto.'
                                  : 'Define una meta, registra tu avance y mira tu progreso.',
                            ),
                          );
                        }
                        return SliverPadding(
                          padding: const EdgeInsets.all(16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, i) {
                                final c = filtered[i];
                                return _ChallengeCard(
                                  challenge: c,
                                  theme: theme,
                                  colorScheme: colorScheme,
                                  streak: _streaks[c.id] ?? 0,
                                  checkedInToday:
                                      _checkedInToday[c.id] ?? false,
                                  checkingIn: _checkingIn.contains(c.id),
                                  onTap: () =>
                                      context.push('/challenges/${c.id}'),
                                  onQuickCheckIn: () => _quickCheckIn(c.id),
                                );
                              },
                              childCount: filtered.length,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/challenges/new').then((_) => _load()),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo reto'),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rueda de Vida
// ─────────────────────────────────────────────────────────────────────────────

class _LifeWheelSection extends StatelessWidget {
  const _LifeWheelSection({
    required this.assessments,
    required this.onEdit,
    required this.theme,
    required this.colorScheme,
    required this.zenitBalance,
    this.selectedAspect,
    this.onAspectTap,
  });

  final List<LifeAssessment> assessments;
  final VoidCallback onEdit;
  final AppThemeExtension? theme;
  final ColorScheme colorScheme;
  final int zenitBalance;
  final LifeAspect? selectedAspect;
  final ValueChanged<LifeAspect>? onAspectTap;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(theme?.radiusLg ?? 12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      'Rueda de Vida',
                      style:
                          Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Editar'),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                if (assessments.isEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Descubre cómo te sientes en cada área de tu vida.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: theme?.mutedForeground,
                        ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: onEdit,
                    child: const Text('Completar Rueda de Vida'),
                  ),
                ] else ...[
                  const SizedBox(height: 4),
                  Text(
                    'Toca un aspecto para filtrar tus retos',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: theme?.mutedForeground,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: LifeWheelChart(
                      assessments: assessments,
                      size: 240,
                      zenitBalance: zenitBalance,
                      selectedAspect: selectedAspect,
                      onAspectTap: onAspectTap,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Sección horizontal de retos destacados.
class _FeaturedSection extends StatelessWidget {
  const _FeaturedSection({
    required this.challenges,
    required this.theme,
    required this.colorScheme,
  });

  final List<Challenge> challenges;
  final AppThemeExtension? theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Retos de la semana',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
            ),
          ),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: challenges.length,
              itemBuilder: (context, i) {
                final c = challenges[i];
                return _FeaturedCard(
                  challenge: c,
                  theme: theme,
                  colorScheme: colorScheme,
                );
              },
            ),
          ),
          const Divider(height: 24),
        ],
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({
    required this.challenge,
    required this.theme,
    required this.colorScheme,
  });

  final Challenge challenge;
  final AppThemeExtension? theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final iconData =
        ChallengeIcons.fromCodePoint(challenge.iconCodePoint) ?? Icons.star;
    return GestureDetector(
      onTap: () => context.push('/challenges/${challenge.id}'),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius:
              BorderRadius.circular(theme?.radiusLg ?? 12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(iconData,
                color: colorScheme.onPrimaryContainer, size: 28),
            const Spacer(),
            Text(
              challenge.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onPrimaryContainer,
                  ),
            ),
            if (challenge.objective != null) ...[
              const SizedBox(height: 2),
              Text(
                challenge.objective!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimaryContainer
                          .withValues(alpha: 0.7),
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({
    required this.challenge,
    required this.theme,
    required this.colorScheme,
    required this.streak,
    required this.checkedInToday,
    required this.checkingIn,
    required this.onTap,
    required this.onQuickCheckIn,
  });

  final Challenge challenge;
  final AppThemeExtension? theme;
  final ColorScheme colorScheme;
  final int streak;
  final bool checkedInToday;
  final bool checkingIn;
  final VoidCallback onTap;
  final VoidCallback onQuickCheckIn;

  @override
  Widget build(BuildContext context) {
    final subtitle = _subtitle(challenge);
    final iconData =
        ChallengeIcons.fromCodePoint(challenge.iconCodePoint) ?? Icons.flag;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme?.radiusLg ?? 8),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(theme?.radiusLg ?? 8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(iconData,
                    color: colorScheme.onPrimaryContainer, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.name,
                      style:
                          Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: theme?.mutedForeground,
                          ),
                    ),
                    if (streak > 0) ...[
                      const SizedBox(height: 6),
                      StreakBadge(count: streak),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _CheckInButton(
                checkedIn: checkedInToday,
                loading: checkingIn,
                onTap: onQuickCheckIn,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitle(Challenge c) {
    final unitStr = c.unit != null ? ' · ${c.unitAmount ?? "?"} ${c.unit}' : '';
    switch (c.type) {
      case ChallengeType.streak:
        return '${c.target.toInt()} días seguidos$unitStr';
      case ChallengeType.countTimes:
        return '${c.target.toInt()} ${c.frequency?.label ?? "por periodo"}$unitStr';
      case ChallengeType.countUnits:
        return '${c.target} ${c.unit ?? "unidades"}';
    }
  }
}

class _CheckInButton extends StatelessWidget {
  const _CheckInButton({
    required this.checkedIn,
    required this.loading,
    required this.onTap,
  });

  final bool checkedIn;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (loading) {
      return const SizedBox(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (checkedIn) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check, size: 14, color: Colors.green.shade700),
            const SizedBox(width: 4),
            Text(
              'Hoy',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade700,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 14, color: colorScheme.primary),
            const SizedBox(width: 4),
            Text(
              'Hoy',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
