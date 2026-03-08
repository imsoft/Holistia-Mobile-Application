import 'package:flutter/material.dart';

/// Los 8 aspectos de la Rueda de Vida.
enum LifeAspect {
  personal,
  fisico,
  laboral,
  familiar,
  pareja,
  alimentacion,
  social,
  dinero;

  String get label => switch (this) {
        LifeAspect.personal => 'Personal',
        LifeAspect.fisico => 'Físico',
        LifeAspect.laboral => 'Laboral',
        LifeAspect.familiar => 'Familiar',
        LifeAspect.pareja => 'Pareja',
        LifeAspect.alimentacion => 'Alimentación',
        LifeAspect.social => 'Social',
        LifeAspect.dinero => 'Dinero',
      };

  Color get color => switch (this) {
        LifeAspect.personal => const Color(0xFF9C27B0),      // Púrpura
        LifeAspect.fisico => const Color(0xFFFF5722),        // Naranja profundo
        LifeAspect.laboral => const Color(0xFF2196F3),       // Azul
        LifeAspect.familiar => const Color(0xFF4CAF50),      // Verde
        LifeAspect.pareja => const Color(0xFFE91E63),        // Rosa
        LifeAspect.alimentacion => const Color(0xFFFF9800),  // Ámbar
        LifeAspect.social => const Color(0xFF00BCD4),        // Cian
        LifeAspect.dinero => const Color(0xFF8BC34A),        // Verde lima
      };

  static LifeAspect? fromString(String? value) {
    if (value == null) return null;
    return LifeAspect.values.where((a) => a.name == value).firstOrNull;
  }
}
