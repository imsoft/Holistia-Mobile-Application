import 'package:flutter/material.dart';

import '../core/theme_mode_controller.dart';

/// Expone [ThemeModeController] en el árbol de widgets para que pantallas
/// como Ajustes puedan cambiar el tema.
class ThemeModeScope extends InheritedWidget {
  const ThemeModeScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final ThemeModeController controller;

  static ThemeModeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeModeScope>();
    assert(scope != null, 'ThemeModeScope not found. Wrap app with ThemeModeScope.');
    return scope!.controller;
  }

  @override
  bool updateShouldNotify(ThemeModeScope oldWidget) =>
      controller != oldWidget.controller;
}
