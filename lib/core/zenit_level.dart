import 'package:flutter/material.dart';

/// Niveles de progreso basados en zenits acumulados.
enum ZenitLevel {
  semilla,
  brote,
  raiz,
  arbol,
  bosque,
  cosmos;

  static ZenitLevel fromBalance(int balance) {
    if (balance >= 3000) return ZenitLevel.cosmos;
    if (balance >= 1500) return ZenitLevel.bosque;
    if (balance >= 700) return ZenitLevel.arbol;
    if (balance >= 300) return ZenitLevel.raiz;
    if (balance >= 100) return ZenitLevel.brote;
    return ZenitLevel.semilla;
  }

  String get label {
    switch (this) {
      case ZenitLevel.semilla:
        return 'Semilla';
      case ZenitLevel.brote:
        return 'Brote';
      case ZenitLevel.raiz:
        return 'Raíz';
      case ZenitLevel.arbol:
        return 'Árbol';
      case ZenitLevel.bosque:
        return 'Bosque';
      case ZenitLevel.cosmos:
        return 'Cosmos';
    }
  }

  String get emoji {
    switch (this) {
      case ZenitLevel.semilla:
        return '🌱';
      case ZenitLevel.brote:
        return '🌿';
      case ZenitLevel.raiz:
        return '🪨';
      case ZenitLevel.arbol:
        return '🌳';
      case ZenitLevel.bosque:
        return '🌲';
      case ZenitLevel.cosmos:
        return '✨';
    }
  }

  /// Zenits necesarios para llegar al siguiente nivel. Null si ya es el máximo.
  int? get nextLevelAt {
    switch (this) {
      case ZenitLevel.semilla:
        return 100;
      case ZenitLevel.brote:
        return 300;
      case ZenitLevel.raiz:
        return 700;
      case ZenitLevel.arbol:
        return 1500;
      case ZenitLevel.bosque:
        return 3000;
      case ZenitLevel.cosmos:
        return null;
    }
  }

  /// Zenits del inicio de este nivel.
  int get startsAt {
    switch (this) {
      case ZenitLevel.semilla:
        return 0;
      case ZenitLevel.brote:
        return 100;
      case ZenitLevel.raiz:
        return 300;
      case ZenitLevel.arbol:
        return 700;
      case ZenitLevel.bosque:
        return 1500;
      case ZenitLevel.cosmos:
        return 3000;
    }
  }

  /// Progreso dentro del nivel actual (0.0 – 1.0).
  double progress(int balance) {
    final next = nextLevelAt;
    if (next == null) return 1.0;
    final range = next - startsAt;
    final current = balance - startsAt;
    return (current / range).clamp(0.0, 1.0);
  }

  Color get color {
    switch (this) {
      case ZenitLevel.semilla:
        return const Color(0xFF81C784); // verde claro
      case ZenitLevel.brote:
        return const Color(0xFF4CAF50); // verde
      case ZenitLevel.raiz:
        return const Color(0xFF8D6E63); // marrón
      case ZenitLevel.arbol:
        return const Color(0xFF388E3C); // verde oscuro
      case ZenitLevel.bosque:
        return const Color(0xFF1B5E20); // verde muy oscuro
      case ZenitLevel.cosmos:
        return const Color(0xFF7C4DFF); // violeta
    }
  }
}
