import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Resultado del flujo Sign in with Apple (éxito o error con mensaje).
sealed class AppleSignInResult {
  const AppleSignInResult();
}

class AppleSignInSuccess extends AppleSignInResult {
  const AppleSignInSuccess();
}

class AppleSignInFailure extends AppleSignInResult {
  const AppleSignInFailure(this.message);
  final String message;
}

class AppleSignInCancelled extends AppleSignInResult {
  const AppleSignInCancelled();
}

/// Servicio para Sign in with Apple en iOS/macOS.
/// Autentica con Apple de forma nativa y crea/actualiza sesión en Supabase.
class AppleAuthService {
  AppleAuthService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Realiza el flujo completo: credencial Apple → signInWithIdToken → actualizar nombre si aplica.
  /// Solo debe usarse en plataformas donde Sign in with Apple está disponible (iOS/macOS).
  Future<AppleSignInResult> signInWithApple() async {
    try {
      final rawNonce = _client.auth.generateRawNonce();
      final hashedNonce = _sha256Hex(rawNonce);

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null || idToken.isEmpty) {
        return const AppleSignInFailure(
          'No se recibió el token de Apple. Intenta de nuevo.',
        );
      }

      final authResponse = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );

      if (authResponse.user == null) {
        return const AppleSignInFailure(
          'No se pudo crear la sesión. Intenta de nuevo.',
        );
      }

      // Apple solo envía nombre en el primer inicio de sesión.
      final givenName = credential.givenName;
      final familyName = credential.familyName;
      if (givenName != null || familyName != null) {
        final parts = <String>[];
        if (givenName != null) parts.add(givenName);
        if (familyName != null) parts.add(familyName);
        final fullName = parts.join(' ').trim();
        if (fullName.isNotEmpty) {
          await _client.auth.updateUser(
            UserAttributes(
              data: {
                'full_name': fullName,
                'given_name': givenName,
                'family_name': familyName,
              },
            ),
          );
        }
      }

      return const AppleSignInSuccess();
    } on SignInWithAppleAuthorizationException catch (e) {
      switch (e.code) {
        case AuthorizationErrorCode.canceled:
          return const AppleSignInCancelled();
        case AuthorizationErrorCode.unknown:
          return AppleSignInFailure(
            'Error inesperado de Apple (${e.message}).',
          );
        case AuthorizationErrorCode.invalidResponse:
          return const AppleSignInFailure(
            'Respuesta inválida de Apple. Intenta de nuevo.',
          );
        case AuthorizationErrorCode.notHandled:
          return const AppleSignInCancelled();
        case AuthorizationErrorCode.failed:
          return const AppleSignInFailure(
            'No se pudo completar el inicio de sesión con Apple. Intenta de nuevo.',
          );
        case AuthorizationErrorCode.notInteractive:
          return const AppleSignInFailure(
            'No se pudo mostrar la pantalla de Apple. Intenta de nuevo.',
          );
      }
    } on SignInWithAppleNotSupportedException catch (_) {
      return const AppleSignInFailure(
        'Sign in with Apple no está disponible en este dispositivo.',
      );
    } on SignInWithAppleException catch (_) {
      return const AppleSignInFailure('Error con Apple. Intenta de nuevo.');
    } on AuthException catch (_) {
      return const AppleSignInFailure('No se pudo iniciar sesión. Intenta de nuevo.');
    } catch (_) {
      return const AppleSignInFailure('Error al iniciar sesión con Apple. Intenta de nuevo.');
    }
  }

  static String _sha256Hex(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

}
