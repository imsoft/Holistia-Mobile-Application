import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Almacenamiento seguro para la sesión de Supabase (Keychain en iOS, Keystore en Android).
/// Mantiene la sesión al cerrar la app.
class SecureSessionStorage extends LocalStorage {
  SecureSessionStorage({required this.persistSessionKey});

  final String persistSessionKey;

  static const AndroidOptions _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: _androidOptions,
  );

  @override
  Future<void> initialize() async {
    if (kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(persistSessionKey)) {
        final value = prefs.getString(persistSessionKey);
        if (value != null && value.isNotEmpty) {
          await _storage.write(key: persistSessionKey, value: value);
          await prefs.remove(persistSessionKey);
        }
      }
    } catch (_) {
      // Si falla la migración, seguimos sin ella
    }
  }

  @override
  Future<bool> hasAccessToken() async {
    return await _storage.containsKey(key: persistSessionKey);
  }

  @override
  Future<String?> accessToken() async {
    return await _storage.read(key: persistSessionKey);
  }

  @override
  Future<void> removePersistedSession() async {
    await _storage.delete(key: persistSessionKey);
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    await _storage.write(key: persistSessionKey, value: persistSessionString);
  }
}
