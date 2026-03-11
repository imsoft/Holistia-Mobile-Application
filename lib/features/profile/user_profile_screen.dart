import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/challenge_icons.dart';
import '../../core/share_service.dart';
import '../../core/user_facing_errors.dart';
import '../../core/zenit_level.dart';
import '../../models/post.dart';
import '../../models/profile.dart';
import '../../repositories/follow_repository.dart';
import '../../repositories/post_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/challenge_badges.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_retry.dart';
import '../../widgets/expert_badge.dart';
import '../../widgets/skeleton.dart';
import '../feed/post_detail_sheet.dart';

/// Perfil público de un usuario: publicaciones, seguidores, siguiendo y botón Seguir.
class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _profileRepo = ProfileRepository();
  final _postRepo = PostRepository();
  final _followRepo = FollowRepository();
  final _shareService = ShareService();

  AppProfile? _profile;
  int _followerCount = 0;
  int _followingCount = 0;
  bool _isFollowing = false;
  List<Post> _posts = [];
  String? _myUserId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _myUserId = Supabase.instance.client.auth.currentUser?.id;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await _profileRepo.getProfile(widget.userId);
      final followerCount = await _followRepo.getFollowerCount(widget.userId);
      final followingCount = await _followRepo.getFollowingCount(widget.userId);
      final isFollowing = await _followRepo.isFollowing(widget.userId);
      final posts = await _postRepo.getPostsByUser(widget.userId);

      if (mounted) {
        setState(() {
          _profile = profile;
          _followerCount = followerCount;
          _followingCount = followingCount;
          _isFollowing = isFollowing;
          _posts = posts;
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

  Future<void> _toggleFollow() async {
    if (_myUserId == null || widget.userId == _myUserId) return;
    final wasFollowing = _isFollowing;
    setState(() {
      _isFollowing = !_isFollowing;
      _followerCount += _isFollowing ? 1 : -1;
    });
    try {
      if (wasFollowing) {
        await _followRepo.unfollow(widget.userId);
      } else {
        await _followRepo.follow(widget.userId);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isFollowing = wasFollowing;
          _followerCount += wasFollowing ? 1 : -1;
        });
      }
    }
  }

  void _openPostDetail(Post post) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => PostDetailSheet(
        post: post,
      ),
    ).then((_) => _load());
  }

  Future<void> _sharePost(Post post) async {
    await _shareService.sharePostToStories(post, context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>();
    final colorScheme = Theme.of(context).colorScheme;
    final isMe = _myUserId == widget.userId;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loading
          ? const SkeletonUserProfile()
          : _error != null
              ? ErrorRetry(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 44,
                                backgroundColor: theme?.muted,
                                backgroundImage: _profile?.avatarUrl != null &&
                                        _profile!.avatarUrl!.isNotEmpty
                                    ? NetworkImage(_profile!.avatarUrl!)
                                    : null,
                                child: _profile?.avatarUrl == null ||
                                        _profile!.avatarUrl!.isEmpty
                                    ? Text(
                                        (_profile?.displayName ?? '?')[0].toUpperCase(),
                                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                              color: theme?.mutedForeground,
                                            ),
                                      )
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _profile?.displayName ?? 'Usuario',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              if (_profile?.username != null && _profile!.username!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '@${_profile!.username}',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: theme?.mutedForeground,
                                      ),
                                ),
                              ],
                              if (_profile?.role.isAtLeastExpert == true) ...[
                                const SizedBox(height: 8),
                                ExpertBadge(
                                  label: _profile!.role.isAdmin ? 'Admin' : 'Experto',
                                ),
                              ],
                              const SizedBox(height: 8),
                              _ZenitChip(balance: _profile?.zenitBalance ?? 0),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _CountChip(
                                    label: 'Seguidores',
                                    value: _followerCount,
                                  ),
                                  const SizedBox(width: 24),
                                  _CountChip(
                                    label: 'Siguiendo',
                                    value: _followingCount,
                                  ),
                                ],
                              ),
                              if (!isMe && _myUserId != null) ...[
                                const SizedBox(height: 20),
                                FilledButton.tonal(
                                  onPressed: _toggleFollow,
                                  child: Text(_isFollowing ? 'Siguiendo' : 'Seguir'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _BadgesSection(
                          totalCheckIns: _posts.length,
                          followerCount: _followerCount,
                          wasInvited: false,
                          recentCheckIn: _posts.isNotEmpty &&
                              _posts.first.createdAt
                                      .isAfter(DateTime.now().subtract(const Duration(days: 7))),
                          theme: theme,
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Publicaciones',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme?.mutedForeground,
                                ),
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 8)),
                      _posts.isEmpty
                          ? SliverFillRemaining(
                              hasScrollBody: false,
                              child: EmptyState(
                                icon: Icons.article_outlined,
                                title: 'Aún no hay publicaciones',
                                subtitle: 'Cuando publique avances de sus retos, aparecerán aquí.',
                              ),
                            )
                          : SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final post = _posts[index];
                                  return _ProfilePostCard(
                                    post: post,
                                    theme: theme,
                                    colorScheme: colorScheme,
                                    onTap: () => _openPostDetail(post),
                                    onShare: () => _sharePost(post),
                                  );
                                },
                                childCount: _posts.length,
                              ),
                            ),
                    ],
                  ),
                ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$value',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).extension<AppThemeExtension>()?.mutedForeground,
              ),
        ),
      ],
    );
  }
}

class _ProfilePostCard extends StatelessWidget {
  const _ProfilePostCard({
    required this.post,
    required this.theme,
    required this.colorScheme,
    required this.onTap,
    required this.onShare,
  });

  final Post post;
  final AppThemeExtension? theme;
  final ColorScheme colorScheme;
  final VoidCallback onTap;
  final VoidCallback onShare;

  static String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'Ahora';
  }

  @override
  Widget build(BuildContext context) {
    final challenge = post.challengeName ?? 'Reto';

    return Card(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme?.radiusLg ?? 8),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (post.challengeIconCodePoint != null) ...[
                    Icon(
                      ChallengeIcons.fromCodePoint(post.challengeIconCodePoint) ?? Icons.flag,
                      size: 18,
                      color: theme?.mutedForeground,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      challenge,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: theme?.mutedForeground,
                          ),
                    ),
                  ),
                  Text(
                    _formatDate(post.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: theme?.mutedForeground,
                        ),
                  ),
                ],
              ),
              if (post.imageUrls.isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(theme?.radiusMd ?? 8),
                  child: Image.network(
                    post.imageUrls.first,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 100,
                      color: theme?.muted,
                      child: Icon(Icons.broken_image_outlined, color: theme?.mutedForeground),
                    ),
                  ),
                ),
              ],
              if (post.body != null && post.body!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  post.body!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _ActionButton(
                    icon: Icons.comment_outlined,
                    label: '${post.commentCount}',
                    isActive: false,
                    colorScheme: colorScheme,
                    theme: theme,
                    onTap: null,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.ios_share),
                    onPressed: onShare,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.colorScheme,
    required this.theme,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final ColorScheme colorScheme;
  final AppThemeExtension? theme;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap != null ? () => onTap!() : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? colorScheme.primary : theme?.mutedForeground,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isActive ? colorScheme.primary : theme?.mutedForeground,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZenitChip extends StatelessWidget {
  const _ZenitChip({required this.balance});

  final int balance;

  @override
  Widget build(BuildContext context) {
    final level = ZenitLevel.fromBalance(balance);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: level.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: level.color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(level.emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            '${level.label} · $balance zenits',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: level.color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _BadgesSection extends StatelessWidget {
  const _BadgesSection({
    required this.totalCheckIns,
    required this.followerCount,
    required this.wasInvited,
    required this.recentCheckIn,
    required this.theme,
  });

  final int totalCheckIns;
  final int followerCount;
  final bool wasInvited;
  final bool recentCheckIn;
  final AppThemeExtension? theme;

  @override
  Widget build(BuildContext context) {
    final badges = ChallengeBadges(
      totalCheckIns: totalCheckIns,
      currentStreak: 0,
      followerCount: followerCount,
      wasInvited: wasInvited,
      recentCheckIn: recentCheckIn,
    );
    // Only show section if there are earned badges
    if (totalCheckIns == 0 && followerCount < 5 && !wasInvited && !recentCheckIn) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Logros',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme?.mutedForeground,
                ),
          ),
          const SizedBox(height: 8),
          badges,
        ],
      ),
    );
  }
}
