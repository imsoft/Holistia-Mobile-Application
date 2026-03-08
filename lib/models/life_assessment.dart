import 'life_aspect.dart';

class LifeAssessment {
  const LifeAssessment({
    required this.aspect,
    required this.score,
    this.reason,
    this.checkInCount = 0,
  });

  final LifeAspect aspect;

  /// Puntuación del 1 (muy mal) al 5 (excelente).
  final int score;

  final String? reason;

  /// Check-ins realizados en retos vinculados a este aspecto.
  final int checkInCount;

  factory LifeAssessment.fromJson(Map<String, dynamic> json) => LifeAssessment(
        aspect: LifeAspect.fromString(json['aspect'] as String?)!,
        score: (json['score'] as num).toInt(),
        reason: json['reason'] as String?,
        checkInCount: (json['check_in_count'] as num?)?.toInt() ?? 0,
      );
}
