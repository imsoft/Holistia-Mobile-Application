import 'package:flutter/material.dart';

/// Categorías disponibles para un reto.
enum ChallengeCategory {
  saludMental,
  espiritual,
  actividadFisica,
  social,
  alimentacion,
  otro;

  String get label => switch (this) {
        ChallengeCategory.saludMental => 'Salud mental',
        ChallengeCategory.espiritual => 'Espiritual',
        ChallengeCategory.actividadFisica => 'Actividad física',
        ChallengeCategory.social => 'Social',
        ChallengeCategory.alimentacion => 'Alimentación',
        ChallengeCategory.otro => 'Otro',
      };

  /// Valor guardado en base de datos (snake_case).
  String get name => switch (this) {
        ChallengeCategory.saludMental => 'salud_mental',
        ChallengeCategory.espiritual => 'espiritual',
        ChallengeCategory.actividadFisica => 'actividad_fisica',
        ChallengeCategory.social => 'social',
        ChallengeCategory.alimentacion => 'alimentacion',
        ChallengeCategory.otro => 'otro',
      };

  IconData get icon => switch (this) {
        ChallengeCategory.saludMental => Icons.psychology,
        ChallengeCategory.espiritual => Icons.self_improvement,
        ChallengeCategory.actividadFisica => Icons.directions_run,
        ChallengeCategory.social => Icons.people,
        ChallengeCategory.alimentacion => Icons.restaurant,
        ChallengeCategory.otro => Icons.star,
      };

  /// Convierte el valor de la base de datos al enum.
  static ChallengeCategory fromString(String? value) => switch (value) {
        'salud_mental' => ChallengeCategory.saludMental,
        'espiritual' => ChallengeCategory.espiritual,
        'actividad_fisica' => ChallengeCategory.actividadFisica,
        'social' => ChallengeCategory.social,
        'alimentacion' => ChallengeCategory.alimentacion,
        'otro' => ChallengeCategory.otro,
        // Legacy: categorías antiguas
        'salud' => ChallengeCategory.saludMental,
        'mente' => ChallengeCategory.saludMental,
        'deporte' => ChallengeCategory.actividadFisica,
        'creativo' => ChallengeCategory.espiritual,
        _ => ChallengeCategory.otro,
      };
}
