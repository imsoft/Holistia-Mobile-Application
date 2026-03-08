import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Radio base (0.5rem ≈ 8px)
const double kRadius = 8.0;

/// Tokens de sombra para tema claro
class AppShadowsLight {
  AppShadowsLight._();

  static List<BoxShadow> get shadow2xs => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          offset: const Offset(0, 4),
          blurRadius: 8,
          spreadRadius: -1,
        ),
      ];
  static List<BoxShadow> get shadowXs => shadow2xs;
  static List<BoxShadow> get shadowSm => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          offset: const Offset(0, 4),
          blurRadius: 8,
          spreadRadius: -1,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          offset: const Offset(0, 1),
          blurRadius: 2,
          spreadRadius: -2,
        ),
      ];
  static List<BoxShadow> get shadow => shadowSm;
  static List<BoxShadow> get shadowMd => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          offset: const Offset(0, 4),
          blurRadius: 8,
          spreadRadius: -1,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          offset: const Offset(0, 2),
          blurRadius: 4,
          spreadRadius: -2,
        ),
      ];
  static List<BoxShadow> get shadowLg => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          offset: const Offset(0, 4),
          blurRadius: 8,
          spreadRadius: -1,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          offset: const Offset(0, 4),
          blurRadius: 6,
          spreadRadius: -2,
        ),
      ];
  static List<BoxShadow> get shadowXl => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          offset: const Offset(0, 4),
          blurRadius: 8,
          spreadRadius: -1,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          offset: const Offset(0, 8),
          blurRadius: 10,
          spreadRadius: -2,
        ),
      ];
  static List<BoxShadow> get shadow2xl => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          offset: const Offset(0, 4),
          blurRadius: 8,
          spreadRadius: -1,
        ),
      ];
}

/// Tokens de sombra para tema oscuro
class AppShadowsDark {
  AppShadowsDark._();

  static List<BoxShadow> get shadow2xs => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          offset: const Offset(0, 1),
          blurRadius: 3,
        ),
      ];
  static List<BoxShadow> get shadowXs => shadow2xs;
  static List<BoxShadow> get shadowSm => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          offset: const Offset(0, 1),
          blurRadius: 3,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          offset: const Offset(0, 1),
          blurRadius: 2,
          spreadRadius: -1,
        ),
      ];
  static List<BoxShadow> get shadow => shadowSm;
  static List<BoxShadow> get shadowMd => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          offset: const Offset(0, 1),
          blurRadius: 3,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          offset: const Offset(0, 2),
          blurRadius: 4,
          spreadRadius: -1,
        ),
      ];
  static List<BoxShadow> get shadowLg => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          offset: const Offset(0, 1),
          blurRadius: 3,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          offset: const Offset(0, 4),
          blurRadius: 6,
          spreadRadius: -1,
        ),
      ];
  static List<BoxShadow> get shadowXl => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          offset: const Offset(0, 1),
          blurRadius: 3,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          offset: const Offset(0, 8),
          blurRadius: 10,
          spreadRadius: -1,
        ),
      ];
  static List<BoxShadow> get shadow2xl => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          offset: const Offset(0, 1),
          blurRadius: 3,
        ),
      ];
}

/// Extensión del tema con colores semánticos y tokens (--color-*, --radius-*, --shadow-*)
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  const AppThemeExtension({
    required this.background,
    required this.foreground,
    required this.card,
    required this.cardForeground,
    required this.popover,
    required this.popoverForeground,
    required this.primary,
    required this.primaryForeground,
    required this.secondary,
    required this.secondaryForeground,
    required this.muted,
    required this.mutedForeground,
    required this.accent,
    required this.accentForeground,
    required this.destructive,
    required this.border,
    required this.input,
    required this.ring,
    required this.chart1,
    required this.chart2,
    required this.chart3,
    required this.chart4,
    required this.chart5,
    required this.sidebar,
    required this.sidebarForeground,
    required this.sidebarPrimary,
    required this.sidebarPrimaryForeground,
    required this.sidebarAccent,
    required this.sidebarAccentForeground,
    required this.sidebarBorder,
    required this.sidebarRing,
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusLg,
    required this.radiusXl,
    required this.shadow2xs,
    required this.shadowXs,
    required this.shadowSm,
    required this.shadow,
    required this.shadowMd,
    required this.shadowLg,
    required this.shadowXl,
    required this.shadow2xl,
  });

  final Color background;
  final Color foreground;
  final Color card;
  final Color cardForeground;
  final Color popover;
  final Color popoverForeground;
  final Color primary;
  final Color primaryForeground;
  final Color secondary;
  final Color secondaryForeground;
  final Color muted;
  final Color mutedForeground;
  final Color accent;
  final Color accentForeground;
  final Color destructive;
  final Color border;
  final Color input;
  final Color ring;
  final Color chart1;
  final Color chart2;
  final Color chart3;
  final Color chart4;
  final Color chart5;
  final Color sidebar;
  final Color sidebarForeground;
  final Color sidebarPrimary;
  final Color sidebarPrimaryForeground;
  final Color sidebarAccent;
  final Color sidebarAccentForeground;
  final Color sidebarBorder;
  final Color sidebarRing;
  final double radiusSm;
  final double radiusMd;
  final double radiusLg;
  final double radiusXl;
  final List<BoxShadow> shadow2xs;
  final List<BoxShadow> shadowXs;
  final List<BoxShadow> shadowSm;
  final List<BoxShadow> shadow;
  final List<BoxShadow> shadowMd;
  final List<BoxShadow> shadowLg;
  final List<BoxShadow> shadowXl;
  final List<BoxShadow> shadow2xl;

  static AppThemeExtension get light => AppThemeExtension(
        background: AppColorsLight.background,
        foreground: AppColorsLight.foreground,
        card: AppColorsLight.card,
        cardForeground: AppColorsLight.cardForeground,
        popover: AppColorsLight.popover,
        popoverForeground: AppColorsLight.popoverForeground,
        primary: AppColorsLight.primary,
        primaryForeground: AppColorsLight.primaryForeground,
        secondary: AppColorsLight.secondary,
        secondaryForeground: AppColorsLight.secondaryForeground,
        muted: AppColorsLight.muted,
        mutedForeground: AppColorsLight.mutedForeground,
        accent: AppColorsLight.accent,
        accentForeground: AppColorsLight.accentForeground,
        destructive: AppColorsLight.destructive,
        border: AppColorsLight.border,
        input: AppColorsLight.input,
        ring: AppColorsLight.ring,
        chart1: AppColorsLight.chart1,
        chart2: AppColorsLight.chart2,
        chart3: AppColorsLight.chart3,
        chart4: AppColorsLight.chart4,
        chart5: AppColorsLight.chart5,
        sidebar: AppColorsLight.sidebar,
        sidebarForeground: AppColorsLight.sidebarForeground,
        sidebarPrimary: AppColorsLight.sidebarPrimary,
        sidebarPrimaryForeground: AppColorsLight.sidebarPrimaryForeground,
        sidebarAccent: AppColorsLight.sidebarAccent,
        sidebarAccentForeground: AppColorsLight.sidebarAccentForeground,
        sidebarBorder: AppColorsLight.sidebarBorder,
        sidebarRing: AppColorsLight.sidebarRing,
        radiusSm: kRadius - 4,
        radiusMd: kRadius - 2,
        radiusLg: kRadius,
        radiusXl: kRadius + 4,
        shadow2xs: AppShadowsLight.shadow2xs,
        shadowXs: AppShadowsLight.shadowXs,
        shadowSm: AppShadowsLight.shadowSm,
        shadow: AppShadowsLight.shadow,
        shadowMd: AppShadowsLight.shadowMd,
        shadowLg: AppShadowsLight.shadowLg,
        shadowXl: AppShadowsLight.shadowXl,
        shadow2xl: AppShadowsLight.shadow2xl,
      );

  static AppThemeExtension get dark => AppThemeExtension(
        background: AppColorsDark.background,
        foreground: AppColorsDark.foreground,
        card: AppColorsDark.card,
        cardForeground: AppColorsDark.cardForeground,
        popover: AppColorsDark.popover,
        popoverForeground: AppColorsDark.popoverForeground,
        primary: AppColorsDark.primary,
        primaryForeground: AppColorsDark.primaryForeground,
        secondary: AppColorsDark.secondary,
        secondaryForeground: AppColorsDark.secondaryForeground,
        muted: AppColorsDark.muted,
        mutedForeground: AppColorsDark.mutedForeground,
        accent: AppColorsDark.accent,
        accentForeground: AppColorsDark.accentForeground,
        destructive: AppColorsDark.destructive,
        border: AppColorsDark.border,
        input: AppColorsDark.input,
        ring: AppColorsDark.ring,
        chart1: AppColorsDark.chart1,
        chart2: AppColorsDark.chart2,
        chart3: AppColorsDark.chart3,
        chart4: AppColorsDark.chart4,
        chart5: AppColorsDark.chart5,
        sidebar: AppColorsDark.sidebar,
        sidebarForeground: AppColorsDark.sidebarForeground,
        sidebarPrimary: AppColorsDark.sidebarPrimary,
        sidebarPrimaryForeground: AppColorsDark.sidebarPrimaryForeground,
        sidebarAccent: AppColorsDark.sidebarAccent,
        sidebarAccentForeground: AppColorsDark.sidebarAccentForeground,
        sidebarBorder: AppColorsDark.sidebarBorder,
        sidebarRing: AppColorsDark.sidebarRing,
        radiusSm: kRadius - 4,
        radiusMd: kRadius - 2,
        radiusLg: kRadius,
        radiusXl: kRadius + 4,
        shadow2xs: AppShadowsDark.shadow2xs,
        shadowXs: AppShadowsDark.shadowXs,
        shadowSm: AppShadowsDark.shadowSm,
        shadow: AppShadowsDark.shadow,
        shadowMd: AppShadowsDark.shadowMd,
        shadowLg: AppShadowsDark.shadowLg,
        shadowXl: AppShadowsDark.shadowXl,
        shadow2xl: AppShadowsDark.shadow2xl,
      );

  @override
  ThemeExtension<AppThemeExtension> copyWith() => this;

  @override
  ThemeExtension<AppThemeExtension> lerp(
    covariant ThemeExtension<AppThemeExtension>? other,
    double t,
  ) =>
      this;
}

/// Tema claro de la app
ThemeData get appThemeLight => ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: AppColorsLight.primary,
        onPrimary: AppColorsLight.primaryForeground,
        secondary: AppColorsLight.secondary,
        onSecondary: AppColorsLight.secondaryForeground,
        surface: AppColorsLight.background,
        onSurface: AppColorsLight.foreground,
        error: AppColorsLight.destructive,
        onError: AppColorsLight.primaryForeground,
        outline: AppColorsLight.border,
      ),
      scaffoldBackgroundColor: AppColorsLight.background,
      cardColor: AppColorsLight.card,
      cardTheme: CardThemeData(
        color: AppColorsLight.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadius),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColorsLight.primary,
        contentTextStyle: TextStyle(
          color: AppColorsLight.primaryForeground,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadius),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColorsLight.card,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColorsLight.accent,
        elevation: 0,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColorsLight.primary,
            );
          }
          return TextStyle(
            fontSize: 12,
            color: AppColorsLight.mutedForeground,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(size: 24, color: AppColorsLight.primary);
          }
          return IconThemeData(size: 24, color: AppColorsLight.mutedForeground);
        }),
      ),
      extensions: <ThemeExtension<dynamic>>[AppThemeExtension.light],
    );

/// Tema oscuro de la app
ThemeData get appThemeDark => ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: AppColorsDark.primary,
        onPrimary: AppColorsDark.primaryForeground,
        secondary: AppColorsDark.secondary,
        onSecondary: AppColorsDark.secondaryForeground,
        surface: AppColorsDark.background,
        onSurface: AppColorsDark.foreground,
        error: AppColorsDark.destructive,
        onError: AppColorsDark.primaryForeground,
        outline: AppColorsDark.border,
      ),
      scaffoldBackgroundColor: AppColorsDark.background,
      cardColor: AppColorsDark.card,
      cardTheme: CardThemeData(
        color: AppColorsDark.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadius),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColorsDark.primary,
        contentTextStyle: TextStyle(
          color: AppColorsDark.primaryForeground,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadius),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColorsDark.card,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColorsDark.accent,
        elevation: 0,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColorsDark.primary,
            );
          }
          return TextStyle(
            fontSize: 12,
            color: AppColorsDark.mutedForeground,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(size: 24, color: AppColorsDark.primary);
          }
          return IconThemeData(size: 24, color: AppColorsDark.mutedForeground);
        }),
      ),
      extensions: <ThemeExtension<dynamic>>[AppThemeExtension.dark],
    );
