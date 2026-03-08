import 'package:flutter/foundation.dart';

@immutable
class PostComment {
  const PostComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.body,
    required this.createdAt,
    this.displayName,
    this.heartCount = 0,
    this.hasCurrentUserHeart = false,
  });

  final String id;
  final String postId;
  final String userId;
  final String body;
  final DateTime createdAt;
  final String? displayName;
  final int heartCount;
  final bool hasCurrentUserHeart;

  PostComment copyWith({
    String? id,
    String? postId,
    String? userId,
    String? body,
    DateTime? createdAt,
    String? displayName,
    int? heartCount,
    bool? hasCurrentUserHeart,
  }) {
    return PostComment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      displayName: displayName ?? this.displayName,
      heartCount: heartCount ?? this.heartCount,
      hasCurrentUserHeart: hasCurrentUserHeart ?? this.hasCurrentUserHeart,
    );
  }

  factory PostComment.fromJson(Map<String, dynamic> json) {
    return PostComment(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      userId: json['user_id'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      displayName: json['display_name'] as String?,
      heartCount: (json['heart_count'] as num?)?.toInt() ?? 0,
      hasCurrentUserHeart: json['has_current_user_heart'] as bool? ?? false,
    );
  }
}
