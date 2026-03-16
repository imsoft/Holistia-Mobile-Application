import 'package:flutter/material.dart';

import '../../core/app_date_utils.dart';
import '../../core/user_facing_errors.dart';
import '../../models/challenge.dart';
import '../../models/profile.dart';
import '../../repositories/admin_repository.dart';
import '../../repositories/challenge_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/user_avatar.dart';
import 'places_tab.dart';

/// Panel de administración con 4 pestañas:
/// - Solicitudes de experto pendientes
/// - Lista de todos los usuarios
/// - Retos destacados
/// - Lugares (restaurantes, centros, eventos, comercios)
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panel de Administración'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.pending_actions), text: 'Solicitudes'),
              Tab(icon: Icon(Icons.people), text: 'Usuarios'),
              Tab(icon: Icon(Icons.star_outlined), text: 'Retos'),
              Tab(icon: Icon(Icons.place_outlined), text: 'Lugares'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ExpertRequestsTab(),
            _UsersTab(),
            _FeaturedChallengesTab(),
            PlacesTab(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1: Solicitudes de experto pendientes
// ─────────────────────────────────────────────────────────────────────────────

class _ExpertRequestsTab extends StatefulWidget {
  const _ExpertRequestsTab();

  @override
  State<_ExpertRequestsTab> createState() => _ExpertRequestsTabState();
}

class _ExpertRequestsTabState extends State<_ExpertRequestsTab>
    with AutomaticKeepAliveClientMixin {
  final _adminRepo = AdminRepository();
  List<ExpertRequestWithProfile>? _requests;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _requests = null;
      _error = null;
    });
    try {
      final list = await _adminRepo.getPendingRequests();
      if (mounted) setState(() => _requests = list);
    } catch (e) {
      if (mounted) setState(() => _error = userFacingErrorMessage(e));
    }
  }

  Future<void> _review(ExpertRequestWithProfile item, bool approve) async {
    // Optimistic remove
    setState(() => _requests = _requests!
        .where((r) => r.request.id != item.request.id)
        .toList());
    try {
      await _adminRepo.reviewRequest(item.request.id, approve: approve);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(approve
              ? '✅ ${item.profile?.displayName ?? 'Usuario'} aprobado como Experto'
              : '❌ Solicitud rechazada'),
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _requests = [..._requests!, item]);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(userFacingErrorMessage(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context).extension<AppThemeExtension>();

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }

    if (_requests == null) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    if (_requests!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline,
                  size: 64, color: theme?.mutedForeground),
              const SizedBox(height: 16),
              Text(
                'Sin solicitudes pendientes',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _requests!.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final item = _requests![i];
          return _RequestCard(
            item: item,
            theme: theme,
            onApprove: () => _review(item, true),
            onReject: () => _review(item, false),
          );
        },
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.item,
    required this.theme,
    required this.onApprove,
    required this.onReject,
  });

  final ExpertRequestWithProfile item;
  final AppThemeExtension? theme;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final profile = item.profile;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(
                  name: profile?.displayName ?? '?',
                  avatarUrl: profile?.avatarUrl,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile?.displayName ?? 'Usuario',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (profile?.username != null)
                        Text(
                          '@${profile!.username}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: theme?.mutedForeground),
                        ),
                    ],
                  ),
                ),
                Text(
                  AppDateUtils.formatRelative(item.request.createdAt),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: theme?.mutedForeground, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme?.muted,
                borderRadius: BorderRadius.circular(theme?.radiusMd ?? 8),
              ),
              child: Text(
                item.request.bio,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Rechazar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      side: BorderSide(color: colorScheme.error),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Aprobar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2: Lista de usuarios
// ─────────────────────────────────────────────────────────────────────────────

class _UsersTab extends StatefulWidget {
  const _UsersTab();

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab>
    with AutomaticKeepAliveClientMixin {
  final _adminRepo = AdminRepository();
  List<AppProfile>? _users;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _users = null;
      _error = null;
    });
    try {
      final list = await _adminRepo.getAllUsers();
      if (mounted) setState(() => _users = list);
    } catch (e) {
      if (mounted) setState(() => _error = userFacingErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context).extension<AppThemeExtension>();

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: _load, child: const Text('Reintentar')),
          ],
        ),
      );
    }

    if (_users == null) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _users!.length,
        itemBuilder: (context, i) {
          final u = _users![i];
          return ListTile(
            leading: UserAvatar(
              name: u.displayName ?? u.username ?? '?',
              avatarUrl: u.avatarUrl,
            ),
            title: Text(u.displayName ?? u.username ?? 'Usuario'),
            subtitle: u.username != null
                ? Text('@${u.username}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: theme?.mutedForeground))
                : null,
            trailing: _RoleBadge(role: u.role),
          );
        },
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (label, color) = switch (role) {
      UserRole.admin => ('Admin', colorScheme.error),
      UserRole.expert => ('Experto', colorScheme.primary),
      UserRole.user => ('Usuario', Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 3: Retos destacados (featured)
// ─────────────────────────────────────────────────────────────────────────────

class _FeaturedChallengesTab extends StatefulWidget {
  const _FeaturedChallengesTab();

  @override
  State<_FeaturedChallengesTab> createState() => _FeaturedChallengesTabState();
}

class _FeaturedChallengesTabState extends State<_FeaturedChallengesTab>
    with AutomaticKeepAliveClientMixin {
  final _repo = ChallengeRepository();
  List<Challenge>? _challenges;
  String? _error;
  final Set<String> _toggling = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _challenges = null;
      _error = null;
    });
    try {
      final list = await _repo.getAllPublicChallenges();
      if (mounted) setState(() => _challenges = list);
    } catch (e) {
      if (mounted) setState(() => _error = userFacingErrorMessage(e));
    }
  }

  Future<void> _toggleFeatured(Challenge c) async {
    if (_toggling.contains(c.id)) return;
    setState(() => _toggling.add(c.id));
    try {
      await _repo.setFeatured(c.id, featured: !c.isFeatured);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(userFacingErrorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _toggling.remove(c.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_challenges == null && _error == null) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Reintentar')),
          ],
        ),
      );
    }
    final challenges = _challenges!;
    if (challenges.isEmpty) {
      return const Center(child: Text('No hay retos públicos aún.'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        itemCount: challenges.length,
        itemBuilder: (context, i) {
          final c = challenges[i];
          final isToggling = _toggling.contains(c.id);
          return SwitchListTile(
            secondary: isToggling
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    c.isFeatured ? Icons.star : Icons.star_outline,
                    color: c.isFeatured ? Colors.amber : null,
                  ),
            title: Text(c.name),
            subtitle: Text(c.category.label),
            value: c.isFeatured,
            onChanged: isToggling ? null : (_) => _toggleFeatured(c),
          );
        },
      ),
    );
  }
}
