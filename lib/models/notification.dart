import 'package:flutter/foundation.dart';

enum NotificationType {
  follow,
  comment,
  zenit,
  dailyReminder,
  challengeInvitation,
  expertApproved,
  expertRejected;

  static NotificationType fromString(String? v) {
    switch (v) {
      case 'follow':
        return NotificationType.follow;
      case 'comment':
        return NotificationType.comment;
      case 'zenit':
        return NotificationType.zenit;
      case 'daily_reminder':
        return NotificationType.dailyReminder;
      case 'challenge_invitation':
        return NotificationType.challengeInvitation;
      case 'expert_approved':
        return NotificationType.expertApproved;
      case 'expert_rejected':
        return NotificationType.expertRejected;
      default:
        return NotificationType.follow;
    }
  }

  String get value {
    switch (this) {
      case NotificationType.follow:
        return 'follow';
      case NotificationType.comment:
        return 'comment';
      case NotificationType.zenit:
        return 'zenit';
      case NotificationType.dailyReminder:
        return 'daily_reminder';
      case NotificationType.challengeInvitation:
        return 'challenge_invitation';
      case NotificationType.expertApproved:
        return 'expert_approved';
      case NotificationType.expertRejected:
        return 'expert_rejected';
    }
  }
}

@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.relatedUserId,
    this.relatedPostId,
    this.relatedChallengeId,
  });

  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final String? relatedUserId;
  final String? relatedPostId;
  final String? relatedChallengeId;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: NotificationType.fromString(json['type'] as String?),
      title: json['title'] as String,
      body: json['body'] as String,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      relatedUserId: json['related_user_id'] as String?,
      relatedPostId: json['related_post_id'] as String?,
      relatedChallengeId: json['related_challenge_id'] as String?,
    );
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? body,
    bool? isRead,
    DateTime? createdAt,
    String? relatedUserId,
    String? relatedPostId,
    String? relatedChallengeId,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      relatedUserId: relatedUserId ?? this.relatedUserId,
      relatedPostId: relatedPostId ?? this.relatedPostId,
      relatedChallengeId: relatedChallengeId ?? this.relatedChallengeId,
    );
  }
}
