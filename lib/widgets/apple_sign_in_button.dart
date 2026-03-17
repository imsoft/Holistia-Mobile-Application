import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../theme/app_theme.dart';

/// Botón oficial "Sign in with Apple" para iOS (y opcionalmente macOS).
/// En otras plataformas no se muestra (Guideline 4.8: opción equivalente en iOS).
class AppleSignInButton extends StatelessWidget {
  const AppleSignInButton({
    super.key,
    required this.onPressed,
    this.loading = false,
  });

  final VoidCallback? onPressed;
  final bool loading;

  /// True si la plataforma soporta Sign in with Apple nativo (iOS/macOS).
  static bool get isSupported => Platform.isIOS || Platform.isMacOS;

  @override
  Widget build(BuildContext context) {
    if (!isSupported) return const SizedBox.shrink();

    final theme = Theme.of(context).extension<AppThemeExtension>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (loading) {
      return SizedBox(
        height: 50,
        child: OutlinedButton(
          onPressed: null,
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(theme?.radiusMd ?? 8),
            ),
          ),
          child: const SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return SizedBox(
      height: 50,
      child: SignInWithAppleButton(
        onPressed: onPressed ?? () {},
        text: 'Continuar con Apple',
        height: 35,
        borderRadius: BorderRadius.circular(theme?.radiusMd ?? 8),
        style: isDark
            ? SignInWithAppleButtonStyle.black
            : SignInWithAppleButtonStyle.white,
      ),
    );
  }
}
