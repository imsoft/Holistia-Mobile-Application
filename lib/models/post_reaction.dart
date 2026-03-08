/// Reacción emoji de un usuario en un post.
class PostReaction {
  const PostReaction({
    required this.id,
    required this.postId,
    required this.userId,
    required this.emoji,
    required this.createdAt,
  });

  final String id;
  final String postId;
  final String userId;
  final String emoji;
  final DateTime createdAt;

  factory PostReaction.fromJson(Map<String, dynamic> json) => PostReaction(
        id: json['id'] as String,
        postId: json['post_id'] as String,
        userId: json['user_id'] as String,
        emoji: json['emoji'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
