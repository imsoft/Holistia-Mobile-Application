import 'package:flutter/foundation.dart';

@immutable
class Post {
  const Post({
    required this.id,
    required this.userId,
    required this.challengeId,
    this.checkInId,
    this.body,
    this.imageUrls = const [],
    required this.createdAt,
    this.zenitCount = 0,
    this.commentCount = 0,
    this.displayName,
    this.challengeName,
    this.challengeUnit,
    this.challengeIconCodePoint,
    this.challengeCategory,
    this.userAvatarUrl,
  });

  final String id;
  final String userId;
  final String challengeId;
  final String? checkInId;
  final String? body;

  /// Lista de URLs de imágenes (vacía si no hay ninguna). Soporta hasta 6.
  final List<String> imageUrls;

  final DateTime createdAt;
  final int zenitCount;
  final int commentCount;
  final String? displayName;
  final String? challengeName;
  final String? challengeUnit;
  final int? challengeIconCodePoint;
  final String? challengeCategory;
  final String? userAvatarUrl;

  Post copyWith({
    String? id,
    String? userId,
    String? challengeId,
    String? checkInId,
    String? body,
    List<String>? imageUrls,
    DateTime? createdAt,
    int? zenitCount,
    int? commentCount,
    String? displayName,
    String? challengeName,
    String? challengeUnit,
    int? challengeIconCodePoint,
    String? challengeCategory,
    String? userAvatarUrl,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      challengeId: challengeId ?? this.challengeId,
      checkInId: checkInId ?? this.checkInId,
      body: body ?? this.body,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      zenitCount: zenitCount ?? this.zenitCount,
      commentCount: commentCount ?? this.commentCount,
      displayName: displayName ?? this.displayName,
      challengeName: challengeName ?? this.challengeName,
      challengeUnit: challengeUnit ?? this.challengeUnit,
      challengeIconCodePoint:
          challengeIconCodePoint ?? this.challengeIconCodePoint,
      challengeCategory: challengeCategory ?? this.challengeCategory,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
    );
  }

  factory Post.fromJson(Map<String, dynamic> json) {
    // image_urls es el array nuevo. Si está vacío, usamos image_url como fallback
    // para retrocompatibilidad con posts anteriores a la migración 016.
    final rawUrls = (json['image_urls'] as List<dynamic>?)?.cast<String>() ?? [];
    final legacyUrl = json['image_url'] as String?;
    final imageUrls = rawUrls.isNotEmpty
        ? rawUrls
        : (legacyUrl != null && legacyUrl.isNotEmpty ? [legacyUrl] : <String>[]);

    return Post(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      challengeId: json['challenge_id'] as String,
      checkInId: json['check_in_id'] as String?,
      body: json['body'] as String?,
      imageUrls: imageUrls,
      createdAt: DateTime.parse(json['created_at'] as String),
      zenitCount: (json['zenit_count'] as num?)?.toInt() ?? 0,
      commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
      displayName: json['display_name'] as String?,
      challengeName: json['challenge_name'] as String?,
      challengeUnit: json['challenge_unit'] as String?,
      challengeIconCodePoint:
          (json['challenge_icon_code_point'] as num?)?.toInt(),
      userAvatarUrl: json['user_avatar_url'] as String?,
    );
  }
}
