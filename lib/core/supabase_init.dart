import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';

/// Inicializa Supabase si hay URL y anon key configurados.
/// La sesión se persiste con el almacenamiento por defecto (SharedPreferences).
Future<void> initSupabase() async {
  if (!Config.isSupabaseConfigured) return;
  await Supabase.initialize(
    url: Config.supabaseUrl,
    anonKey: Config.supabaseAnonKey,
  );
}
