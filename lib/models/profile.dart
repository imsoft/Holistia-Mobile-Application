import 'package:flutter/foundation.dart';

enum UserRole {
  user,
  expert,
  admin;

  static UserRole fromString(String? v) {
    switch (v) {
      case 'expert':
        return UserRole.expert;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.user;
    }
  }

  String get value {
    switch (this) {
      case UserRole.user:
        return 'user';
      case UserRole.expert:
        return 'expert';
      case UserRole.admin:
        return 'admin';
    }
  }

  bool get isExpert => this == UserRole.expert;
  bool get isAdmin => this == UserRole.admin;
  /// True para expert y admin.
  bool get isAtLeastExpert => this == UserRole.expert || this == UserRole.admin;
}

@immutable
class AppProfile {
  const AppProfile({
    required this.id,
    this.username,
    this.displayName,
    this.avatarUrl,
    this.sex,
    this.birthDate,
    this.isPublic = true,
    this.role = UserRole.user,
    this.zenitBalance = 0,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  /// Nombre de usuario único (@username). Solo minúsculas, números y _.
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final String? sex;
  final DateTime? birthDate;
  final bool isPublic;
  final UserRole role;
  /// Zenits acumulados (puntos de progreso personal).
  final int zenitBalance;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory AppProfile.fromJson(Map<String, dynamic> json) {
    return AppProfile(
      id: json['id'] as String,
      username: json['username'] as String?,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      sex: json['sex'] as String?,
      birthDate: json['birth_date'] != null
          ? DateTime.parse(json['birth_date'] as String)
          : null,
      isPublic: json['is_public'] as bool? ?? true,
      role: UserRole.fromString(json['role'] as String?),
      zenitBalance: (json['zenit_balance'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'sex': sex,
      'birth_date': birthDate?.toIso8601String().split('T').first,
      'is_public': isPublic,
      'role': role.value,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
