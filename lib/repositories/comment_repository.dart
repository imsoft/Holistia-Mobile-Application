import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/comment.dart';

class CommentRepository {
  CommentRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  /// Obtiene los comentarios de una publicación (con conteo de corazones y si el usuario reaccionó).
  Future<List<PostComment>> getByPostId(String postId) async {
    final res = await _client
        .from('post_comments')
        .select()
        .eq('post_id', postId)
        .order('created_at', ascending: true);

    final rows = res as List<dynamic>;
    if (rows.isEmpty) return [];

    final comments = rows
        .map((e) => PostComment.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    final commentIds = comments.map((c) => c.id).toList();

    final userIds = comments.map((c) => c.userId).toSet().toList();
    final profilesRes = await _client
        .from('profiles')
        .select('id, display_name')
        .inFilter('id', userIds);

    final profiles = <String, String>{};
    for (final p in profilesRes as List<dynamic>) {
      final m = Map<String, dynamic>.from(p);
      profiles[m['id'] as String] = m['display_name'] as String? ?? 'Usuario';
    }

    final heartCounts = <String, int>{};
    final userHeartedCommentIds = <String>{};

    if (commentIds.isNotEmpty) {
      final reactionsRes = await _client
          .from('comment_reactions')
          .select('comment_id')
          .inFilter('comment_id', commentIds);
      for (final r in reactionsRes as List<dynamic>) {
        final cid = (r as Map<String, dynamic>)['comment_id'] as String?;
        if (cid != null) heartCounts[cid] = (heartCounts[cid] ?? 0) + 1;
      }

      final uid = _userId;
      if (uid != null) {
        final myRes = await _client
            .from('comment_reactions')
            .select('comment_id')
            .inFilter('comment_id', commentIds)
            .eq('user_id', uid);
        for (final r in myRes as List<dynamic>) {
          final cid = (r as Map<String, dynamic>)['comment_id'] as String?;
          if (cid != null) userHeartedCommentIds.add(cid);
        }
      }
    }

    return comments.map((c) => PostComment(
          id: c.id,
          postId: c.postId,
          userId: c.userId,
          body: c.body,
          createdAt: c.createdAt,
          displayName: profiles[c.userId],
          heartCount: heartCounts[c.id] ?? 0,
          hasCurrentUserHeart: userHeartedCommentIds.contains(c.id),
        )).toList();
  }

  /// Añade un comentario.
  Future<PostComment> insert({
    required String postId,
    required String body,
  }) async {
    final uid = _userId;
    if (uid == null) throw Exception('No hay usuario autenticado');

    final res = await _client
        .from('post_comments')
        .insert({'post_id': postId, 'user_id': uid, 'body': body})
        .select()
        .single();

    return PostComment.fromJson(Map<String, dynamic>.from(res));
  }

  /// Elimina un comentario (solo el autor).
  Future<void> delete(String id) async {
    final uid = _userId;
    if (uid == null) return;

    await _client
        .from('post_comments')
        .delete()
        .eq('id', id)
        .eq('user_id', uid);
  }

  /// Alterna la reacción de corazón del usuario en un comentario.
  /// Devuelve true si el comentario queda con corazón, false si no.
  Future<bool> toggleCommentHeart(String commentId) async {
    final uid = _userId;
    if (uid == null) throw Exception('No hay usuario autenticado');

    final existing = await _client
        .from('comment_reactions')
        .select('id')
        .eq('comment_id', commentId)
        .eq('user_id', uid)
        .maybeSingle();

    if (existing != null) {
      await _client
          .from('comment_reactions')
          .delete()
          .eq('comment_id', commentId)
          .eq('user_id', uid);
      return false;
    } else {
      await _client.from('comment_reactions').insert({
        'comment_id': commentId,
        'user_id': uid,
      });
      return true;
    }
  }
}
