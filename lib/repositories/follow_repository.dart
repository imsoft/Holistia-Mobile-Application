import 'package:supabase_flutter/supabase_flutter.dart';

class FollowRepository {
  FollowRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  /// Sigue a un usuario. Lanza si no hay sesión.
  Future<void> follow(String followingId) async {
    final uid = _userId;
    if (uid == null) throw Exception('No hay usuario autenticado');
    if (uid == followingId) return;

    await _client.from('user_follows').upsert(
          {
            'follower_id': uid,
            'following_id': followingId,
          },
          onConflict: 'follower_id,following_id',
        );
  }

  /// Deja de seguir a un usuario.
  Future<void> unfollow(String followingId) async {
    final uid = _userId;
    if (uid == null) return;

    await _client
        .from('user_follows')
        .delete()
        .eq('follower_id', uid)
        .eq('following_id', followingId);
  }

  /// Indica si el usuario actual sigue a [targetUserId].
  Future<bool> isFollowing(String targetUserId) async {
    final uid = _userId;
    if (uid == null || uid == targetUserId) return false;

    final res = await _client
        .from('user_follows')
        .select('id')
        .eq('follower_id', uid)
        .eq('following_id', targetUserId)
        .maybeSingle();
    return res != null;
  }

  /// Número de seguidores de [userId].
  Future<int> getFollowerCount(String userId) async {
    final res = await _client
        .from('user_follows')
        .select('id')
        .eq('following_id', userId);
    return (res as List<dynamic>).length;
  }

  /// Número de usuarios que [userId] sigue.
  Future<int> getFollowingCount(String userId) async {
    final res = await _client
        .from('user_follows')
        .select('id')
        .eq('follower_id', userId);
    return (res as List<dynamic>).length;
  }

  /// Lista de user ids que el usuario actual sigue (para filtrar el feed).
  Future<List<String>> getFollowingIds() async {
    final uid = _userId;
    if (uid == null) return [];

    final res = await _client
        .from('user_follows')
        .select('following_id')
        .eq('follower_id', uid);
    return (res as List<dynamic>)
        .map((e) => (e as Map<String, dynamic>)['following_id'] as String)
        .toList();
  }
}
