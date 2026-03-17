import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'secure_session_storage.dart';

/// Inicializa Supabase si hay URL y anon key configurados.
/// La sesión se persiste en Keychain (iOS) / Keystore cifrado (Android).
Future<void> initSupabase() async {
  if (!Config.isSupabaseConfigured) return;
  await Supabase.initialize(
    url: Config.supabaseUrl,
    anonKey: Config.supabaseAnonKey,
    authOptions: FlutterAuthClientOptions(
      localStorage: SecureSessionStorage(
        persistSessionKey: 'supabase_session',
      ),
    ),
  );
}
