import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/image_validator.dart';
import '../models/profile.dart';

class ProfileRepository {
  ProfileRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  Future<AppProfile?> getMyProfile() async {
    final uid = _userId;
    if (uid == null) return null;

    final res = await _client.from('profiles').select().eq('id', uid).maybeSingle();
    if (res == null) return null;
    return AppProfile.fromJson(Map<String, dynamic>.from(res));
  }

  /// Obtiene el perfil público de cualquier usuario (nombre, avatar).
  /// Útil para pantallas de perfil público.
  Future<AppProfile?> getProfile(String userId) async {
    final res = await _client.from('profiles').select().eq('id', userId).maybeSingle();
    if (res == null) return null;
    return AppProfile.fromJson(Map<String, dynamic>.from(res));
  }

  /// Sube una imagen al bucket avatars y devuelve la URL pública.
  Future<String?> uploadAvatar(String localPath) async {
    final uid = _userId;
    if (uid == null) return null;

    final validationError = await ImageValidator.validate(localPath);
    if (validationError != null) throw Exception(validationError);

    final file = File(localPath);
    final ext = localPath.split('.').last.toLowerCase();
    final path = '$uid/${DateTime.now().millisecondsSinceEpoch}.$ext';

    await _client.storage.from('avatars').upload(
          path,
          file,
          fileOptions: const FileOptions(upsert: true),
        );

    return _client.storage.from('avatars').getPublicUrl(path);
  }

  /// Comprueba si un nombre de usuario está disponible (vía RPC, funciona sin sesión).
  Future<bool> checkUsernameAvailableRpc(String username) async {
    final normalized = username.trim().toLowerCase();
    if (normalized.length < 3) return false;
    final res = await _client.rpc('check_username_available', params: {'wanted_username': normalized});
    return res == true;
  }

  /// Comprueba si un nombre de usuario está disponible (único).
  /// Para usuarios ya logueados que cambian su username; excluye al actual.
  Future<bool> isUsernameAvailable(String username, {String? excludeUserId}) async {
    final normalized = username.trim().toLowerCase();
    if (normalized.isEmpty) return false;

    var query = _client
        .from('profiles')
        .select('id')
        .eq('username', normalized);
    if (excludeUserId != null) {
      query = query.neq('id', excludeUserId);
    }
    final res = await query.maybeSingle();
    return res == null;
  }

  Future<void> updateProfile({
    String? username,
    String? displayName,
    String? avatarUrl,
    String? sex,
    DateTime? birthDate,
    bool? isPublic,
  }) async {
    final uid = _userId;
    if (uid == null) return;

    final data = <String, dynamic>{'updated_at': DateTime.now().toIso8601String()};
    if (username != null) data['username'] = username.trim().toLowerCase();
    if (displayName != null) data['display_name'] = displayName;
    if (avatarUrl != null) data['avatar_url'] = avatarUrl;
    // sex: pass '' to clear, or value to set
    if (sex != null) data['sex'] = sex.isEmpty ? null : sex;
    if (birthDate != null) data['birth_date'] = birthDate.toIso8601String().split('T').first;
    if (isPublic != null) data['is_public'] = isPublic;

    await _client.from('profiles').update(data).eq('id', uid);
  }
}
