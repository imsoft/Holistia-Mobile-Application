import 'package:supabase_flutter/supabase_flutter.dart';

class PostReactionRepository {
  PostReactionRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  /// Devuelve mapa postId → emoji → count para una lista de posts.
  Future<Map<String, Map<String, int>>> getReactionCounts(
      List<String> postIds) async {
    if (postIds.isEmpty) return {};

    final res = await _client
        .from('post_reactions')
        .select('post_id, emoji')
        .inFilter('post_id', postIds) as List<dynamic>;

    final result = <String, Map<String, int>>{};
    for (final row in res) {
      final postId = row['post_id'] as String;
      final emoji = row['emoji'] as String;
      result.putIfAbsent(postId, () => {});
      result[postId]![emoji] = (result[postId]![emoji] ?? 0) + 1;
    }
    return result;
  }

  /// Devuelve mapa postId → Set<emoji> que el usuario actual reaccionó.
  Future<Map<String, Set<String>>> getUserReactions(
      List<String> postIds) async {
    final uid = _userId;
    if (uid == null || postIds.isEmpty) return {};

    final res = await _client
        .from('post_reactions')
        .select('post_id, emoji')
        .inFilter('post_id', postIds)
        .eq('user_id', uid) as List<dynamic>;

    final result = <String, Set<String>>{};
    for (final row in res) {
      final postId = row['post_id'] as String;
      final emoji = row['emoji'] as String;
      result.putIfAbsent(postId, () => {});
      result[postId]!.add(emoji);
    }
    return result;
  }

  /// Agrega o elimina una reacción. Devuelve true si quedó activa.
  Future<bool> toggle(String postId, String emoji) async {
    final uid = _userId;
    if (uid == null) return false;

    // Verificar si ya existe
    final existing = await _client
        .from('post_reactions')
        .select('id')
        .eq('post_id', postId)
        .eq('user_id', uid)
        .eq('emoji', emoji)
        .maybeSingle();

    if (existing != null) {
      await _client
          .from('post_reactions')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', uid)
          .eq('emoji', emoji);
      return false;
    } else {
      await _client.from('post_reactions').insert({
        'post_id': postId,
        'user_id': uid,
        'emoji': emoji,
      });
      return true;
    }
  }
}
