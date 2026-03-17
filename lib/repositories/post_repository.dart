import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_constants.dart';
import '../core/image_validator.dart';
import '../models/post.dart';

class PostRepository {
  PostRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  // ── Imágenes ──────────────────────────────────────────────────────────────

  /// Sube una imagen al bucket post-images y devuelve su URL pública.
  Future<String?> uploadImage(String localPath) async {
    final uid = _userId;
    if (uid == null) return null;

    final validationError = await ImageValidator.validate(localPath);
    if (validationError != null) throw Exception(validationError);

    final file = File(localPath);
    final ext = localPath.split('.').last.toLowerCase();
    final path = '$uid/${DateTime.now().millisecondsSinceEpoch}.$ext';

    await _client.storage.from(AppConstants.postImagesBucket).upload(
          path,
          file,
          fileOptions: const FileOptions(upsert: true),
        );

    return _client.storage
        .from(AppConstants.postImagesBucket)
        .getPublicUrl(path);
  }

  /// Sube hasta 6 imágenes en paralelo y devuelve sus URLs públicas.
  Future<List<String>> uploadImages(List<String> localPaths) async {
    final clamped = localPaths.take(6).toList();
    final results = await Future.wait(clamped.map(uploadImage));
    return results.whereType<String>().toList();
  }

  // ── Inserción ─────────────────────────────────────────────────────────────

  /// Inserta una publicación vinculada opcionalmente a un check-in.
  Future<Post> insert({
    required String challengeId,
    String? checkInId,
    String? body,
    List<String> imageUrls = const [],
  }) async {
    final uid = _userId;
    if (uid == null) throw Exception('No hay usuario autenticado');

    final data = <String, dynamic>{
      'user_id': uid,
      'challenge_id': challengeId,
      'image_urls': imageUrls,
    };
    if (checkInId != null) data['check_in_id'] = checkInId;
    if (body != null && body.isNotEmpty) data['body'] = body;

    final res = await _client.from('posts').insert(data).select().single();
    return Post.fromJson(Map<String, dynamic>.from(res));
  }

  // ── Consultas ─────────────────────────────────────────────────────────────

  /// Feed global de publicaciones de retos públicos con paginación.
  Future<List<Post>> getFeed({int page = 0, int pageSize = 20}) async {
    final from = page * pageSize;
    final to = from + pageSize - 1;
    final rows = await _client
        .from('posts_with_zenit_count')
        .select()
        .order('created_at', ascending: false)
        .range(from, to) as List<dynamic>;

    return _enrichPosts(rows);
  }

  /// Feed solo de usuarios que el actual sigue, con paginación.
  Future<List<Post>> getFeedFromFollowing(
    List<String> followingIds, {
    int page = 0,
    int pageSize = 20,
  }) async {
    if (followingIds.isEmpty) return [];

    final from = page * pageSize;
    final to = from + pageSize - 1;
    final rows = await _client
        .from('posts_with_zenit_count')
        .select()
        .inFilter('user_id', followingIds)
        .order('created_at', ascending: false)
        .range(from, to) as List<dynamic>;

    return _enrichPosts(rows);
  }

  /// Publicaciones de un usuario (perfil público).
  Future<List<Post>> getPostsByUser(String userId, {int limit = 50}) async {
    final rows = await _client
        .from('posts_with_zenit_count')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit) as List<dynamic>;

    if (rows.isEmpty) return [];

    final posts = rows.map(_postFromRow).toList();
    final challengeIds = posts.map((p) => p.challengeId).toSet().toList();

    final profileRes = await _client
        .from('profiles')
        .select('id, display_name, avatar_url')
        .eq('id', userId)
        .maybeSingle();
    final challengesRes = await _client
        .from('challenges')
        .select('id, name, unit, icon_code_point, category')
        .inFilter('id', challengeIds) as List<dynamic>;

    final profMap =
        profileRes != null ? Map<String, dynamic>.from(profileRes) : null;
    final displayName = profMap?['display_name'] as String? ?? 'Usuario';
    final avatarUrl = profMap?['avatar_url'] as String?;
    final challenges = _buildChallengeMap(challengesRes);

    return posts.map((p) {
      final ch = challenges[p.challengeId];
      return p.copyWith(
        displayName: displayName,
        userAvatarUrl: avatarUrl,
        challengeName: ch?['name'] as String?,
        challengeUnit: ch?['unit'] as String?,
        challengeIconCodePoint: ch?['icon_code_point'] as int?,
        challengeCategory: ch?['category'] as String?,
      );
    }).toList();
  }

  // ── Helpers privados ──────────────────────────────────────────────────────

  Post _postFromRow(dynamic row) =>
      Post.fromJson(Map<String, dynamic>.from(row as Map));

  /// Enriquece posts con datos de profiles y challenges.
  Future<List<Post>> _enrichPosts(List<dynamic> rows) async {
    if (rows.isEmpty) return [];

    final posts = rows.map(_postFromRow).toList();
    final userIds = posts.map((p) => p.userId).toSet().toList();
    final challengeIds = posts.map((p) => p.challengeId).toSet().toList();

    final profilesRes = await _client
        .from('profiles')
        .select('id, display_name, avatar_url')
        .inFilter('id', userIds) as List<dynamic>;
    final challengesRes = await _client
        .from('challenges')
        .select('id, name, unit, icon_code_point, category')
        .inFilter('id', challengeIds) as List<dynamic>;

    final profiles = _buildProfileMap(profilesRes);
    final challenges = _buildChallengeMap(challengesRes);

    return posts.map((p) {
      final prof = profiles[p.userId];
      final ch = challenges[p.challengeId];
      return p.copyWith(
        displayName: prof?['display_name'] as String? ?? 'Usuario',
        userAvatarUrl: prof?['avatar_url'] as String?,
        challengeName: ch?['name'] as String?,
        challengeUnit: ch?['unit'] as String?,
        challengeIconCodePoint: ch?['icon_code_point'] as int?,
        challengeCategory: ch?['category'] as String?,
      );
    }).toList();
  }

  Map<String, Map<String, dynamic>> _buildProfileMap(List<dynamic> rows) => {
        for (final row in rows)
          (row as Map)['id'] as String: {
            'display_name': row['display_name'] as String? ?? 'Usuario',
            'avatar_url': row['avatar_url'] as String?,
          },
      };

  Map<String, Map<String, dynamic>> _buildChallengeMap(List<dynamic> rows) => {
        for (final row in rows)
          (row as Map)['id'] as String: {
            'name': row['name'] as String?,
            'unit': row['unit'] as String?,
            'icon_code_point': (row['icon_code_point'] as num?)?.toInt(),
            'category': row['category'] as String?,
          },
      };
}
