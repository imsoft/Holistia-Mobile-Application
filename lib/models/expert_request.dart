import 'package:flutter/foundation.dart';

enum ExpertRequestStatus {
  pending,
  approved,
  rejected;

  static ExpertRequestStatus fromString(String? v) {
    switch (v) {
      case 'approved':
        return ExpertRequestStatus.approved;
      case 'rejected':
        return ExpertRequestStatus.rejected;
      default:
        return ExpertRequestStatus.pending;
    }
  }
}

@immutable
class ExpertRequest {
  const ExpertRequest({
    required this.id,
    required this.userId,
    required this.bio,
    required this.status,
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String bio;
  final ExpertRequestStatus status;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;

  factory ExpertRequest.fromJson(Map<String, dynamic> json) {
    return ExpertRequest(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      bio: json['bio'] as String,
      status: ExpertRequestStatus.fromString(json['status'] as String?),
      reviewedBy: json['reviewed_by'] as String?,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
