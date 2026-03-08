import 'package:flutter/material.dart';
import 'package:oklch/oklch.dart';

/// Convierte oklch(L, C, H) a Flutter Color.
/// L y C como en CSS (L 0-1); H en grados. El paquete oklch espera L en 0-100.
Color _oklch(double l, double c, double hDeg) {
  return OKLCHColor(l * 100, c, hDeg).color;
}

/// Colores y tokens de diseño para tema claro ( :root )
/// Usando `static final` en lugar de getters para que la conversión OKLCH→RGB
/// se compute una sola vez al arrancar, no en cada build.
class AppColorsLight {
  AppColorsLight._();

  static final Color background = _oklch(1.00, 0, 0);
  static final Color foreground = _oklch(0.28, 0.04, 260.33);
  static final Color card = _oklch(1.00, 0, 0);
  static final Color cardForeground = _oklch(0.28, 0.04, 260.33);
  static final Color popover = _oklch(1.00, 0, 0);
  static final Color popoverForeground = _oklch(0.28, 0.04, 260.33);
  static final Color primary = _oklch(0.59, 0.20, 277.06);
  static final Color primaryForeground = _oklch(1.00, 0, 0);
  static final Color secondary = _oklch(0.93, 0.01, 261.82);
  static final Color secondaryForeground = _oklch(0.37, 0.03, 259.73);
  static final Color muted = _oklch(0.97, 0, 0);
  static final Color mutedForeground = _oklch(0.55, 0.02, 264.41);
  static final Color accent = _oklch(0.93, 0.03, 273.66);
  static final Color accentForeground = _oklch(0.37, 0.03, 259.73);
  static final Color destructive = _oklch(0.64, 0.21, 25.39);
  static final Color border = _oklch(0.92, 0.01, 261.81);
  static final Color input = _oklch(0.92, 0.01, 261.81);
  static final Color ring = _oklch(0.59, 0.20, 277.06);
  static final Color chart1 = _oklch(0.59, 0.20, 277.06);
  static final Color chart2 = _oklch(0.51, 0.23, 276.97);
  static final Color chart3 = _oklch(0.46, 0.21, 277.06);
  static final Color chart4 = _oklch(0.40, 0.18, 277.16);
  static final Color chart5 = _oklch(0.36, 0.14, 278.65);
  static final Color sidebar = _oklch(1.00, 0, 0);
  static final Color sidebarForeground = _oklch(0.28, 0.04, 260.33);
  static final Color sidebarPrimary = _oklch(0.59, 0.20, 277.06);
  static final Color sidebarPrimaryForeground = _oklch(1.00, 0, 0);
  static final Color sidebarAccent = _oklch(0.93, 0.03, 273.66);
  static final Color sidebarAccentForeground = _oklch(0.37, 0.03, 259.73);
  static final Color sidebarBorder = _oklch(0.92, 0.01, 261.81);
  static final Color sidebarRing = _oklch(0.59, 0.20, 277.06);
}

/// Colores para tema oscuro ( .dark )
class AppColorsDark {
  AppColorsDark._();

  static final Color background = _oklch(0.21, 0.04, 264.04);
  static final Color foreground = _oklch(0.93, 0.01, 256.71);
  static final Color card = _oklch(0.28, 0.04, 260.33);
  static final Color cardForeground = _oklch(0.93, 0.01, 256.71);
  static final Color popover = _oklch(0.28, 0.04, 260.33);
  static final Color popoverForeground = _oklch(0.93, 0.01, 256.71);
  static final Color primary = _oklch(0.68, 0.16, 276.93);
  static final Color primaryForeground = _oklch(0.21, 0.04, 264.04);
  static final Color secondary = _oklch(0.34, 0.03, 261.83);
  static final Color secondaryForeground = _oklch(0.87, 0.01, 261.81);
  static final Color muted = _oklch(0.28, 0.04, 260.33);
  static final Color mutedForeground = _oklch(0.71, 0.02, 261.33);
  static final Color accent = _oklch(0.37, 0.03, 259.73);
  static final Color accentForeground = _oklch(0.87, 0.01, 261.81);
  static final Color destructive = _oklch(0.64, 0.21, 25.39);
  static final Color border = _oklch(0.45, 0.03, 257.68);
  static final Color input = _oklch(0.45, 0.03, 257.68);
  static final Color ring = _oklch(0.68, 0.16, 276.93);
  static final Color chart1 = _oklch(0.68, 0.16, 276.93);
  static final Color chart2 = _oklch(0.59, 0.20, 277.06);
  static final Color chart3 = _oklch(0.51, 0.23, 276.97);
  static final Color chart4 = _oklch(0.46, 0.21, 277.06);
  static final Color chart5 = _oklch(0.40, 0.18, 277.16);
  static final Color sidebar = _oklch(0.28, 0.04, 260.33);
  static final Color sidebarForeground = _oklch(0.93, 0.01, 256.71);
  static final Color sidebarPrimary = _oklch(0.68, 0.16, 276.93);
  static final Color sidebarPrimaryForeground = _oklch(0.21, 0.04, 264.04);
  static final Color sidebarAccent = _oklch(0.37, 0.03, 259.73);
  static final Color sidebarAccentForeground = _oklch(0.87, 0.01, 261.81);
  static final Color sidebarBorder = _oklch(0.45, 0.03, 257.68);
  static final Color sidebarRing = _oklch(0.68, 0.16, 276.93);
}

/// Colores semánticos para estados y tipos de notificación/milestone.
/// Usar estos en lugar de Colors.blue / Colors.orange / etc.
class AppSemanticColors {
  AppSemanticColors._();

  static const Color info = Color(0xFF2196F3);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color neutral = Color(0xFF9E9E9E);

  // Notificaciones
  static const Color notificationFollow = Color(0xFF7C52F5);   // usa primary
  static const Color notificationComment = Color(0xFF2196F3);  // info
  static const Color notificationZenit = Color(0xFFE53935);    // error
  static const Color notificationReminder = Color(0xFFFF9800); // warning
  static const Color notificationChallenge = Color(0xFF4CAF50);// success
  static const Color notificationExpertOk = Color(0xFFFFB300); // gold
  static const Color notificationExpertKo = Color(0xFF9E9E9E); // neutral

  // Milestones / logros
  static const Color milestone1 = Color(0xFF2196F3);
  static const Color milestone2 = Color(0xFF009688);
  static const Color milestone3 = Color(0xFFFF5722);
  static const Color milestone4 = Color(0xFF4CAF50);
  static const Color milestone5 = Color(0xFFFFB300);
  static const Color milestone6 = Color(0xFF9C27B0);
  static const Color milestone7 = Color(0xFF673AB7);
}
