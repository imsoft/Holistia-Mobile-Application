import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_constants.dart';
import '../models/place.dart';

class PlaceRepository {
  PlaceRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  // ── Imagen ────────────────────────────────────────────────────────────────

  /// Sube una imagen al bucket places y devuelve su URL pública.
  Future<String?> uploadImage(String localPath) async {
    final uid = _userId;
    if (uid == null) return null;

    final file = File(localPath);
    if (!await file.exists()) return null;

    final ext = localPath.split('.').last;
    final path = '$uid/${DateTime.now().millisecondsSinceEpoch}.$ext';

    await _client.storage.from(AppConstants.placesBucket).upload(
          path,
          file,
          fileOptions: const FileOptions(upsert: true),
        );

    return _client.storage.from(AppConstants.placesBucket).getPublicUrl(path);
  }

  // ── Consultas ─────────────────────────────────────────────────────────────

  /// Lista todos los lugares, opcionalmente filtrado por tipo.
  Future<List<Place>> getAll({PlaceType? type}) async {
    var query = _client.from('places').select();

    if (type != null) {
      query = query.eq('type', type.value);
    }

    final rows =
        await query.order('created_at', ascending: false) as List<dynamic>;

    return rows
        .map((r) => Place.fromJson(Map<String, dynamic>.from(r)))
        .toList();
  }

  /// Devuelve un lugar por su id.
  Future<Place?> getById(String id) async {
    final row = await _client
        .from('places')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (row == null) return null;
    return Place.fromJson(Map<String, dynamic>.from(row));
  }

  // ── Escritura ─────────────────────────────────────────────────────────────

  Future<Place> insert({
    required PlaceType type,
    required String name,
    String? description,
    String? address,
    String? phone,
    String? imageUrl,
    DateTime? eventDate,
    String? website,
    String? instagram,
    String? facebook,
    String? tiktok,
  }) async {
    final data = <String, dynamic>{
      'type': type.value,
      'name': name,
      'description': ?description,
      'address': ?address,
      'phone': ?phone,
      'image_url': ?imageUrl,
      if (eventDate != null) 'event_date': eventDate.toIso8601String(),
      'website': ?website,
      'instagram': ?instagram,
      'facebook': ?facebook,
      'tiktok': ?tiktok,
    };

    final row =
        await _client.from('places').insert(data).select().single();

    return Place.fromJson(Map<String, dynamic>.from(row));
  }

  Future<Place> update(
    String id, {
    PlaceType? type,
    String? name,
    String? description,
    String? address,
    String? phone,
    String? imageUrl,
    DateTime? eventDate,
    bool clearEventDate = false,
    String? website,
    String? instagram,
    String? facebook,
    String? tiktok,
  }) async {
    final data = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
      if (type != null) 'type': type.value,
      'name': ?name,
      'description': ?description,
      'address': ?address,
      'phone': ?phone,
      'image_url': ?imageUrl,
      if (clearEventDate) 'event_date': null,
      if (!clearEventDate && eventDate != null)
        'event_date': eventDate.toIso8601String(),
      'website': website,
      'instagram': instagram,
      'facebook': facebook,
      'tiktok': tiktok,
    };

    final row = await _client
        .from('places')
        .update(data)
        .eq('id', id)
        .select()
        .single();

    return Place.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> delete(String id) async {
    await _client.from('places').delete().eq('id', id);
  }
}
