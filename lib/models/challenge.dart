import 'package:flutter/foundation.dart';

import '../core/challenge_categories.dart';
import 'life_aspect.dart';

enum ChallengeType {
  streak,
  countTimes,
  countUnits;

  String get value {
    switch (this) {
      case ChallengeType.streak:
        return 'streak';
      case ChallengeType.countTimes:
        return 'count_times';
      case ChallengeType.countUnits:
        return 'count_units';
    }
  }

  static ChallengeType fromString(String? v) {
    switch (v) {
      case 'streak':
        return ChallengeType.streak;
      case 'count_times':
        return ChallengeType.countTimes;
      case 'count_units':
        return ChallengeType.countUnits;
      default:
        return ChallengeType.streak;
    }
  }

  String get label {
    switch (this) {
      case ChallengeType.streak:
        return 'Días seguidos';
      case ChallengeType.countTimes:
        return 'Repeticiones por periodo';
      case ChallengeType.countUnits:
        return 'Unidades (kilómetros, páginas, etc.)';
    }
  }
}

enum ChallengeFrequency {
  daily,
  weekly,
  monthly;

  String get value {
    switch (this) {
      case ChallengeFrequency.daily:
        return 'daily';
      case ChallengeFrequency.weekly:
        return 'weekly';
      case ChallengeFrequency.monthly:
        return 'monthly';
    }
  }

  static ChallengeFrequency fromString(String? v) {
    switch (v) {
      case 'daily':
        return ChallengeFrequency.daily;
      case 'weekly':
        return ChallengeFrequency.weekly;
      case 'monthly':
        return ChallengeFrequency.monthly;
      default:
        return ChallengeFrequency.weekly;
    }
  }

  String get label {
    switch (this) {
      case ChallengeFrequency.daily:
        return 'por día';
      case ChallengeFrequency.weekly:
        return 'por semana';
      case ChallengeFrequency.monthly:
        return 'por mes';
    }
  }
}

@immutable
class Challenge {
  const Challenge({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.target,
    this.unit,
    this.unitAmount,
    this.frequency,
    this.iconCodePoint,
    this.isPublic = true,
    this.objective,
    this.weekdays,
    required this.createdAt,
    this.updatedAt,
    this.startDate,
    this.endDate,
    this.category = ChallengeCategory.otro,
    this.isFeatured = false,
    this.lifeAspect,
  });

  final String id;
  final String userId;
  final String name;
  final ChallengeType type;
  final num target;
  final String? unit;
  final num? unitAmount;
  final ChallengeFrequency? frequency;
  final int? iconCodePoint;
  final bool isPublic;
  final String? objective;
  /// Días de la semana seleccionados (0=Lunes, 1=Martes, ..., 6=Domingo).
  /// Si es null o vacío, significa todos los días.
  final List<int>? weekdays;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? startDate;
  final DateTime? endDate;
  final ChallengeCategory category;
  final bool isFeatured;
  final LifeAspect? lifeAspect;

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      type: ChallengeType.fromString(json['type'] as String?),
      target: (json['target'] as num?) ?? 0,
      unit: json['unit'] as String?,
      unitAmount: (json['unit_amount'] as num?),
      frequency: json['frequency'] != null
          ? ChallengeFrequency.fromString(json['frequency'] as String?)
          : null,
      iconCodePoint: (json['icon_code_point'] as num?)?.toInt(),
      isPublic: json['is_public'] as bool? ?? true,
      objective: json['objective'] as String?,
      weekdays: json['weekdays'] != null
          ? List<int>.from(json['weekdays'] as List)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      category: ChallengeCategory.fromString(json['category'] as String?),
      isFeatured: json['is_featured'] as bool? ?? false,
      lifeAspect: LifeAspect.fromString(json['life_aspect'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'type': type.value,
      'target': target,
      'unit': unit,
      'unit_amount': unitAmount,
      'frequency': frequency?.value,
      'icon_code_point': iconCodePoint,
      'is_public': isPublic,
      'objective': objective,
      'weekdays': weekdays,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'start_date': startDate?.toIso8601String().split('T').first,
      'end_date': endDate?.toIso8601String().split('T').first,
      'category': category.name,
      'is_featured': isFeatured,
      'life_aspect': lifeAspect?.name,
    };
  }

  Challenge copyWith({
    String? id,
    String? userId,
    String? name,
    ChallengeType? type,
    num? target,
    String? unit,
    num? unitAmount,
    ChallengeFrequency? frequency,
    int? iconCodePoint,
    bool? isPublic,
    String? objective,
    List<int>? weekdays,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? startDate,
    DateTime? endDate,
    ChallengeCategory? category,
    bool? isFeatured,
    LifeAspect? lifeAspect,
  }) {
    return Challenge(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      target: target ?? this.target,
      unit: unit ?? this.unit,
      unitAmount: unitAmount ?? this.unitAmount,
      frequency: frequency ?? this.frequency,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      isPublic: isPublic ?? this.isPublic,
      objective: objective ?? this.objective,
      weekdays: weekdays ?? this.weekdays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      category: category ?? this.category,
      isFeatured: isFeatured ?? this.isFeatured,
      lifeAspect: lifeAspect ?? this.lifeAspect,
    );
  }
}
