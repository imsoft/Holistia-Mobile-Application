import 'package:flutter/material.dart';

import '../../core/app_date_utils.dart';
import '../../core/user_facing_errors.dart';
import '../../core/challenge_icons.dart';
import '../../core/share_service.dart';
import '../../widgets/image_carousel.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/user_avatar.dart';
import '../../models/comment.dart';
import '../../models/post.dart';
import '../../repositories/comment_repository.dart';
import '../../theme/app_theme.dart';

/// Bottom sheet con detalle del post: imagen, comentarios, compartir.
class PostDetailSheet extends StatefulWidget {
  const PostDetailSheet({
    super.key,
    required this.post,
    this.onAuthorTap,
  });

  final Post post;
  /// Si se proporciona, al tocar el autor se llama con su userId (ej. para ir a su perfil).
  final void Function(String userId)? onAuthorTap;

  @override
  State<PostDetailSheet> createState() => _PostDetailSheetState();
}

class _PostDetailSheetState extends State<PostDetailSheet> {
  final _commentRepo = CommentRepository();
  final _shareService = ShareService();
  final _textController = TextEditingController();
  List<PostComment> _comments = [];
  bool _loadingComments = true;
  bool _sendingComment = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() => _loadingComments = true);
    try {
      final list = await _commentRepo.getByPostId(widget.post.id);
      if (mounted) {
      setState(() {
        _comments = list;
        _loadingComments = false;
      });
    }
    } catch (_) {
      if (mounted) setState(() => _loadingComments = false);
    }
  }

  Future<void> _sendComment() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _sendingComment) return;

    setState(() => _sendingComment = true);
    _textController.clear();
    try {
      await _commentRepo.insert(postId: widget.post.id, body: text);
      if (mounted) {
        _loadComments();
        setState(() => _sendingComment = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sendingComment = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(userFacingErrorMessage(e))));
      }
    }
  }

  Future<void> _share() async {
    await _shareService.sharePostToStories(widget.post, context);
  }

  Future<void> _toggleCommentHeart(String commentId) async {
    try {
      await _commentRepo.toggleCommentHeart(commentId);
      if (mounted) _loadComments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo actualizar la reacción')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>();
    final colorScheme = Theme.of(context).colorScheme;
    final post = widget.post;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: theme?.mutedForeground,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: widget.onAuthorTap != null
                              ? () => widget.onAuthorTap!(post.userId)
                              : null,
                          borderRadius: BorderRadius.circular(24),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              UserAvatar(
                                name: post.displayName ?? '?',
                                avatarUrl: post.userAvatarUrl,
                                radius: 20,
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                fit: FlexFit.loose,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      post.displayName ?? 'Usuario',
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (post.challengeIconCodePoint != null) ...[
                                          Icon(
                                            ChallengeIcons.fromCodePoint(post.challengeIconCodePoint) ?? Icons.flag,
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
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (post.imageUrls.isNotEmpty) ...[
                    ImageCarousel(imageUrls: post.imageUrls, height: 240),
                    const SizedBox(height: 16),
                  ],
                  if (post.body != null && post.body!.isNotEmpty)
                    Text(post.body!, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _ActionButton(
                        icon: Icons.comment_outlined,
                        label: '${_comments.length}',
                        isActive: false,
                        colorScheme: colorScheme,
                        theme: theme,
                        onTap: null,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.ios_share),
                        tooltip: 'Compartir (incl. Instagram Stories)',
                        onPressed: _share,
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  Text(
                    'Comentarios',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: theme?.mutedForeground,
                        ),
                  ),
                  const SizedBox(height: 12),
                  if (_loadingComments)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: SkeletonComments(),
                    )
                  else if (_comments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Sé el primero en comentar',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: theme?.mutedForeground,
                            ),
                      ),
                    )
                  else
                    ..._comments.map((c) => _CommentTile(
                          comment: c,
                          theme: theme,
                          colorScheme: colorScheme,
                          onHeartTap: _toggleCommentHeart,
                        )),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          decoration: InputDecoration(
                            hintText: 'Escribe un comentario...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(theme?.radiusMd ?? 8),
                            ),
                          ),
                          maxLines: 1,
                          onSubmitted: (_) => _sendComment(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _sendingComment ? null : _sendComment,
                        icon: _sendingComment
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.send),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
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
    this.onTap,
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
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: isActive ? colorScheme.primary : theme?.mutedForeground),
            const SizedBox(width: 6),
            Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isActive ? colorScheme.primary : theme?.mutedForeground,
                )),
          ],
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.theme,
    required this.colorScheme,
    required this.onHeartTap,
  });

  final PostComment comment;
  final AppThemeExtension? theme;
  final ColorScheme colorScheme;
  final ValueChanged<String> onHeartTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(
            name: comment.displayName ?? '?',
            radius: 16,
            textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(color: theme?.mutedForeground),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment.displayName ?? 'Usuario',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(comment.body, style: Theme.of(context).textTheme.bodyMedium),
                Row(
                  children: [
                    Text(
                      AppDateUtils.formatRelative(comment.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: theme?.mutedForeground,
                            fontSize: 12,
                          ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: () => onHeartTap(comment.id),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              comment.hasCurrentUserHeart ? Icons.favorite : Icons.favorite_border,
                              size: 16,
                              color: comment.hasCurrentUserHeart ? colorScheme.error : theme?.mutedForeground,
                            ),
                            if (comment.heartCount > 0) ...[
                              const SizedBox(width: 4),
                              Text(
                                '${comment.heartCount}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontSize: 12,
                                      color: comment.hasCurrentUserHeart ? colorScheme.error : theme?.mutedForeground,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


}
