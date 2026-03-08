import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_date_utils.dart';
import '../../core/challenge_categories.dart';
import '../../core/challenge_icons.dart';
import '../../core/share_service.dart';
import '../../models/post.dart';
import '../../models/profile.dart';
import '../../repositories/challenge_invitation_repository.dart';
import '../../repositories/follow_repository.dart';
import '../../repositories/post_reaction_repository.dart';
import '../../repositories/post_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/emoji_reaction_bar.dart';

import '../../widgets/empty_state.dart';
import '../../widgets/error_retry.dart';
import '../../widgets/image_carousel.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/user_avatar.dart';
import 'post_detail_sheet.dart';

enum _FeedTab { siguiendo, descubrir }

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _postRepo = PostRepository();
  final _followRepo = FollowRepository();
  final _reactionRepo = PostReactionRepository();
  final _inviteRepo = ChallengeInvitationRepository();
  final _shareService = ShareService();
  final _scrollController = ScrollController();
  List<Post> _posts = [];
  final Set<String> _followingIds = {};
  Map<String, Map<String, int>> _reactionCounts = {};
  Map<String, Set<String>> _userReactions = {};
  Map<String, List<AppProfile>> _challengeInvitees = {};
  ChallengeCategory? _selectedCategory;
  String? _myUserId;
  _FeedTab _selectedTab = _FeedTab.descubrir;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 0;
  String? _error;

  static const _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _myUserId = Supabase.instance.client.auth.currentUser?.id;
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300 &&
        !_loadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _page = 0;
      _hasMore = true;
    });
    try {
      final followingIds = await _followRepo.getFollowingIds();
      final List<Post> posts = _selectedTab == _FeedTab.siguiendo
          ? await _postRepo.getFeedFromFollowing(followingIds)
          : await _postRepo.getFeed();
      final postIds = posts.map((p) => p.id).toList();
      final challengeIds = posts.map((p) => p.challengeId).toSet().toList();
      final results = await Future.wait([
        _reactionRepo.getReactionCounts(postIds),
        _reactionRepo.getUserReactions(postIds),
        _inviteRepo.getInviteesForChallenges(challengeIds),
      ]);
      if (mounted) {
        setState(() {
          _posts = posts;
          _followingIds
            ..clear()
            ..addAll(followingIds);
          _reactionCounts = results[0] as Map<String, Map<String, int>>;
          _userReactions = results[1] as Map<String, Set<String>>;
          _challengeInvitees = results[2] as Map<String, List<AppProfile>>;
          _hasMore = posts.length == _pageSize;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      _page++;
      final List<Post> newPosts = _selectedTab == _FeedTab.siguiendo
          ? await _postRepo.getFeedFromFollowing(
              _followingIds.toList(),
              page: _page,
            )
          : await _postRepo.getFeed(page: _page);
      if (newPosts.isEmpty) {
        if (mounted) setState(() { _hasMore = false; _loadingMore = false; });
        return;
      }
      final postIds = newPosts.map((p) => p.id).toList();
      final challengeIds = newPosts.map((p) => p.challengeId).toSet().toList();
      final results = await Future.wait([
        _reactionRepo.getReactionCounts(postIds),
        _reactionRepo.getUserReactions(postIds),
        _inviteRepo.getInviteesForChallenges(challengeIds),
      ]);
      if (mounted) {
        setState(() {
          _posts = [..._posts, ...newPosts];
          _reactionCounts = {
            ..._reactionCounts,
            ...(results[0] as Map<String, Map<String, int>>),
          };
          _userReactions = {
            ..._userReactions,
            ...(results[1] as Map<String, Set<String>>),
          };
          _challengeInvitees = {
            ..._challengeInvitees,
            ...(results[2] as Map<String, List<AppProfile>>),
          };
          _hasMore = newPosts.length == _pageSize;
          _loadingMore = false;
        });
      }
    } catch (_) {
      _page--;
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  List<Post> get _filteredPosts {
    if (_selectedCategory == null) return _posts;
    return _posts
        .where((p) => p.challengeCategory == _selectedCategory!.name)
        .toList();
  }

  Future<void> _toggleReaction(String postId, String emoji) async {
    final prev = Map<String, Map<String, int>>.from(_reactionCounts);
    final prevUser = Map<String, Set<String>>.from(_userReactions);
    setState(() {
      final counts = Map<String, int>.from(_reactionCounts[postId] ?? {});
      final userSet = Set<String>.from(_userReactions[postId] ?? {});
      if (userSet.contains(emoji)) {
        userSet.remove(emoji);
        counts[emoji] = (counts[emoji] ?? 1) - 1;
        if (counts[emoji]! <= 0) counts.remove(emoji);
      } else {
        userSet.add(emoji);
        counts[emoji] = (counts[emoji] ?? 0) + 1;
      }
      _reactionCounts[postId] = counts;
      _userReactions[postId] = userSet;
    });
    try {
      await _reactionRepo.toggle(postId, emoji);
    } catch (_) {
      if (mounted) {
        setState(() {
          _reactionCounts = prev;
          _userReactions = prevUser;
        });
      }
    }
  }

  Future<void> _toggleFollow(String userId) async {
    if (_myUserId == null || userId == _myUserId) return;
    final wasFollowing = _followingIds.contains(userId);
    setState(() {
      if (wasFollowing) {
        _followingIds.remove(userId);
      } else {
        _followingIds.add(userId);
      }
    });
    try {
      if (wasFollowing) {
        await _followRepo.unfollow(userId);
      } else {
        await _followRepo.follow(userId);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (wasFollowing) {
            _followingIds.add(userId);
          } else {
            _followingIds.remove(userId);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _openPostDetail(Post post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => PostDetailSheet(
        post: post,
        onAuthorTap: (userId) {
          Navigator.of(context).pop();
          context.push('/user/$userId');
        },
      ),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SegmentedButton<_FeedTab>(
                segments: const [
                  ButtonSegment(
                    value: _FeedTab.siguiendo,
                    label: Text('Siguiendo'),
                    icon: Icon(Icons.people_outline),
                  ),
                  ButtonSegment(
                    value: _FeedTab.descubrir,
                    label: Text('Descubrir'),
                    icon: Icon(Icons.explore_outlined),
                  ),
                ],
                selected: {_selectedTab},
                onSelectionChanged: (Set<_FeedTab> selected) {
                  setState(() {
                    _selectedTab = selected.first;
                    _load();
                  });
                },
              ),
            ),
          ),
        ),
      ),
      body: _buildBody(theme, colorScheme),
    );
  }

  Widget _buildBody(AppThemeExtension? theme, ColorScheme colorScheme) {
    if (_loading) return const SkeletonPostList();
    if (_error != null) return ErrorRetry(message: _error!, onRetry: _load);
    if (_posts.isEmpty) {
      return EmptyState(
        icon: _selectedTab == _FeedTab.siguiendo
            ? Icons.people_outline
            : Icons.explore_outlined,
        title: _selectedTab == _FeedTab.siguiendo
            ? 'Solo publicaciones de quien sigues'
            : 'Aún no hay publicaciones',
        subtitle: _selectedTab == _FeedTab.siguiendo
            ? 'Sigue a usuarios en Descubrir y sus publicaciones aparecerán aquí.'
            : 'Cuando tú u otros publiquen avances de retos públicos, aparecerán aquí.',
      );
    }
    final filtered = _filteredPosts;
    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('Todos'),
                    selected: _selectedCategory == null,
                    onSelected: (_) =>
                        setState(() => _selectedCategory = null),
                  ),
                  const SizedBox(width: 8),
                  ...ChallengeCategory.values.map((cat) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          avatar: Icon(cat.icon, size: 14),
                          label: Text(cat.label),
                          selected: _selectedCategory == cat,
                          onSelected: (_) => setState(
                              () => _selectedCategory =
                                  _selectedCategory == cat ? null : cat),
                        ),
                      )),
                ],
              ),
            ),
          ),
          if (filtered.isEmpty)
            SliverFillRemaining(
              child: EmptyState(
                icon: _selectedTab == _FeedTab.siguiendo
                    ? Icons.people_outline
                    : Icons.explore_outlined,
                title: _selectedTab == _FeedTab.siguiendo
                    ? 'Solo publicaciones de quien sigues'
                    : 'Aún no hay publicaciones',
                subtitle: _selectedTab == _FeedTab.siguiendo
                    ? 'Sigue a usuarios en Descubrir y sus publicaciones aparecerán aquí.'
                    : 'Cuando tú u otros publiquen avances de retos públicos, aparecerán aquí.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final post = filtered[i];
                    return _FeedPostCard(
                      post: post,
                      myUserId: _myUserId,
                      isFollowingAuthor: _followingIds.contains(post.userId),
                      reactionCounts: _reactionCounts[post.id] ?? {},
                      userReactionEmojis: _userReactions[post.id] ?? {},
                      invitees: _challengeInvitees[post.challengeId] ?? [],
                      onTap: () => _openPostDetail(post),
                      onShare: () =>
                          _shareService.sharePostToStories(post, context),
                      onFollowTap: () => _toggleFollow(post.userId),
                      onAuthorTap: (userId) => context.push('/user/$userId'),
                      onReactionToggle: (emoji) =>
                          _toggleReaction(post.id, emoji),
                      theme: theme,
                      colorScheme: colorScheme,
                    );
                  },
                  childCount: filtered.length,
                ),
              ),
            ),
          if (_loadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tarjeta de post
// ─────────────────────────────────────────────────────────────────────────────

class _FeedPostCard extends StatelessWidget {
  const _FeedPostCard({
    required this.post,
    required this.myUserId,
    required this.isFollowingAuthor,
    required this.reactionCounts,
    required this.userReactionEmojis,
    required this.invitees,
    required this.onTap,
    required this.onShare,
    required this.onFollowTap,
    required this.onReactionToggle,
    this.onAuthorTap,
    required this.theme,
    required this.colorScheme,
  });

  final Post post;
  final String? myUserId;
  final bool isFollowingAuthor;
  final Map<String, int> reactionCounts;
  final Set<String> userReactionEmojis;
  final List<AppProfile> invitees;
  final VoidCallback onTap;
  final VoidCallback onShare;
  final VoidCallback onFollowTap;
  final void Function(String emoji) onReactionToggle;
  final void Function(String userId)? onAuthorTap;
  final AppThemeExtension? theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
              _PostHeader(
                post: post,
                myUserId: myUserId,
                isFollowingAuthor: isFollowingAuthor,
                onAuthorTap: onAuthorTap,
                onFollowTap: onFollowTap,
                theme: theme,
                colorScheme: colorScheme,
              ),
              if (post.imageUrls.isNotEmpty) ...[
                const SizedBox(height: 12),
                ImageCarousel(imageUrls: post.imageUrls, height: 200),
              ],
              if (post.body != null && post.body!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(post.body!, style: Theme.of(context).textTheme.bodyMedium),
              ],
              if (invitees.isNotEmpty) ...[
                const SizedBox(height: 8),
                _InviteesRow(invitees: invitees, theme: theme),
              ],
              const SizedBox(height: 8),
              _PostActions(
                post: post,
                reactionCounts: reactionCounts,
                userReactionEmojis: userReactionEmojis,
                onReactionToggle: onReactionToggle,
                onCommentTap: onTap,
                onShare: onShare,
                theme: theme,
                colorScheme: colorScheme,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cabecera del post: avatar + nombre + reto + seguir + fecha
// ─────────────────────────────────────────────────────────────────────────────

class _PostHeader extends StatelessWidget {
  const _PostHeader({
    required this.post,
    required this.myUserId,
    required this.isFollowingAuthor,
    required this.onAuthorTap,
    required this.onFollowTap,
    required this.theme,
    required this.colorScheme,
  });

  final Post post;
  final String? myUserId;
  final bool isFollowingAuthor;
  final void Function(String userId)? onAuthorTap;
  final VoidCallback onFollowTap;
  final AppThemeExtension? theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final author = post.displayName ?? 'Usuario';
    final authorInfo = _AuthorInfo(post: post, author: author, theme: theme);

    return Row(
      children: [
        Expanded(
          child: onAuthorTap != null
              ? InkWell(
                  onTap: () => onAuthorTap!(post.userId),
                  borderRadius: BorderRadius.circular(24),
                  child: authorInfo,
                )
              : authorInfo,
        ),
        if (myUserId != null && post.userId != myUserId) ...[
          const SizedBox(width: 8),
          TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 28),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              visualDensity: VisualDensity.compact,
            ),
            onPressed: onFollowTap,
            child: Text(
              isFollowingAuthor ? 'Siguiendo' : 'Seguir',
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    isFollowingAuthor ? FontWeight.w600 : FontWeight.normal,
                color: isFollowingAuthor
                    ? theme?.mutedForeground
                    : colorScheme.primary,
              ),
            ),
          ),
        ],
        Text(
          AppDateUtils.formatRelative(post.createdAt),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: theme?.mutedForeground,
              ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fila avatar + nombre + sub-reto
// ─────────────────────────────────────────────────────────────────────────────

class _AuthorInfo extends StatelessWidget {
  const _AuthorInfo({
    required this.post,
    required this.author,
    required this.theme,
  });

  final Post post;
  final String author;
  final AppThemeExtension? theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        UserAvatar(name: author, avatarUrl: post.userAvatarUrl),
        const SizedBox(width: 12),
        Flexible(
          fit: FlexFit.loose,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                author,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (post.challengeIconCodePoint != null) ...[
                    Icon(
                      ChallengeIcons.fromCodePoint(
                              post.challengeIconCodePoint) ??
                          Icons.flag,
                      size: 14,
                      color: theme?.mutedForeground,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Flexible(
                    fit: FlexFit.loose,
                    child: Text(
                      post.challengeName ?? 'Reto',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: theme?.mutedForeground,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Barra de acciones: reacciones · comentarios · compartir
// ─────────────────────────────────────────────────────────────────────────────

class _PostActions extends StatelessWidget {
  const _PostActions({
    required this.post,
    required this.reactionCounts,
    required this.userReactionEmojis,
    required this.onReactionToggle,
    required this.onCommentTap,
    required this.onShare,
    required this.theme,
    required this.colorScheme,
  });

  final Post post;
  final Map<String, int> reactionCounts;
  final Set<String> userReactionEmojis;
  final void Function(String emoji) onReactionToggle;
  final VoidCallback onCommentTap;
  final VoidCallback onShare;
  final AppThemeExtension? theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        EmojiReactionTrigger(
          counts: reactionCounts,
          userEmojis: userReactionEmojis,
          onToggle: onReactionToggle,
          activeColor: colorScheme.primary,
          inactiveColor: theme?.mutedForeground,
        ),
        const SizedBox(width: 8),
        _ActionButton(
          icon: Icons.comment_outlined,
          count: post.commentCount,
          active: false,
          activeColor: colorScheme.primary,
          inactiveColor: theme?.mutedForeground,
          onTap: onCommentTap,
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.ios_share, size: 22),
          tooltip: 'Compartir (incl. Instagram Stories)',
          onPressed: onShare,
          style: IconButton.styleFrom(
            minimumSize: const Size(40, 40),
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.count,
    required this.active,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  final IconData icon;
  final int count;
  final bool active;
  final Color? activeColor;
  final Color? inactiveColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? activeColor : inactiveColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fila de invitados al reto
// ─────────────────────────────────────────────────────────────────────────────

class _InviteesRow extends StatelessWidget {
  const _InviteesRow({required this.invitees, required this.theme});

  final List<AppProfile> invitees;
  final AppThemeExtension? theme;

  String _name(AppProfile p) => p.displayName ?? p.username ?? 'alguien';

  String get _nameText {
    if (invitees.length == 1) return _name(invitees[0]);
    if (invitees.length == 2) {
      return '${_name(invitees[0])} y ${_name(invitees[1])}';
    }
    return '${_name(invitees[0])} y ${invitees.length - 1} más';
  }

  @override
  Widget build(BuildContext context) {
    const maxAvatars = 4;
    final shown = invitees.take(maxAvatars).toList();
    final stackWidth = (shown.length * 16 + 8).toDouble();

    return Row(
      children: [
        SizedBox(
          height: 24,
          width: stackWidth,
          child: Stack(
            children: [
              for (var i = 0; i < shown.length; i++)
                Positioned(
                  left: i * 16.0,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.surface,
                        width: 1.5,
                      ),
                    ),
                    child: UserAvatar(
                      name: _name(shown[i]),
                      avatarUrl: shown[i].avatarUrl,
                      radius: 10,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            'con $_nameText',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: theme?.mutedForeground,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
