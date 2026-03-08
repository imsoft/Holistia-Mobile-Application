import 'package:supabase_flutter/supabase_flutter.dart';

class ZenitRepository {
  ZenitRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  /// Devuelve los IDs de publicaciones a las que el usuario actual dio Zenit.
  Future<Set<String>> getZenitedPostIds(List<String> postIds) async {
    final uid = _userId;
    if (uid == null || postIds.isEmpty) return {};

    final res = await _client
        .from('zenits')
        .select('post_id')
        .eq('from_user_id', uid)
        .inFilter('post_id', postIds);

    return (res as List<dynamic>)
        .map((e) => (e as Map<String, dynamic>)['post_id'] as String)
        .toSet();
  }

  /// Indica si el usuario actual ya dio Zenit a esta publicación.
  Future<bool> hasZenit(String postId) async {
    final uid = _userId;
    if (uid == null) return false;

    final res = await _client
        .from('zenits')
        .select('id')
        .eq('post_id', postId)
        .eq('from_user_id', uid)
        .maybeSingle();

    return res != null;
  }

  /// Da Zenit a una publicación. Si ya lo dio, no hace nada.
  Future<void> add(String postId) async {
    final uid = _userId;
    if (uid == null) throw Exception('No hay usuario autenticado');

    await _client.from('zenits').upsert(
      {'from_user_id': uid, 'post_id': postId},
      onConflict: 'from_user_id,post_id',
      ignoreDuplicates: true,
    );
  }

  /// Quita el Zenit de una publicación.
  Future<void> remove(String postId) async {
    final uid = _userId;
    if (uid == null) return;

    await _client.from('zenits').delete().eq('post_id', postId).eq('from_user_id', uid);
  }

  /// Alterna Zenit (da o quita según el estado actual).
  /// Devuelve true si tras el toggle la publicación tiene Zenit del usuario.
  Future<bool> toggle(String postId) async {
    final has = await hasZenit(postId);
    if (has) {
      await remove(postId);
      return false;
    } else {
      await add(postId);
      return true;
    }
  }
}
