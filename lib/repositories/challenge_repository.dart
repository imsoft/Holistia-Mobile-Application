import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/challenge_categories.dart';
import '../models/challenge.dart';
import '../models/life_aspect.dart';

class ChallengeRepository {
  ChallengeRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  Future<List<Challenge>> getMyChallenges() async {
    final uid = _userId;
    if (uid == null) return [];

    final res = await _client
        .from('challenges')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false);

    return (res as List<dynamic>)
        .map((e) => Challenge.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Challenge?> getById(String id) async {
    final res = await _client.from('challenges').select().eq('id', id).maybeSingle();
    if (res == null) return null;
    return Challenge.fromJson(Map<String, dynamic>.from(res));
  }

  Future<Challenge> insert({
    required String name,
    required ChallengeType type,
    required num target,
    String? unit,
    num? unitAmount,
    ChallengeFrequency? frequency,
    int? iconCodePoint,
    bool isPublic = true,
    String? objective,
    List<int>? weekdays,
    DateTime? startDate,
    DateTime? endDate,
    ChallengeCategory category = ChallengeCategory.otro,
    LifeAspect? lifeAspect,
  }) async {
    final uid = _userId;
    if (uid == null) throw Exception('No hay usuario autenticado');

    final now = DateTime.now();
    final start = startDate ?? now;
    final data = <String, dynamic>{
      'user_id': uid,
      'name': name,
      'type': type.value,
      'target': target,
      'is_public': isPublic,
      'start_date': start.toIso8601String().split('T').first,
      'category': category.name,
      'life_aspect': lifeAspect?.name,
    };
    if (unit != null && unit.isNotEmpty) data['unit'] = unit;
    if (unitAmount != null) data['unit_amount'] = unitAmount;
    if (frequency != null) data['frequency'] = frequency.value;
    if (iconCodePoint != null) data['icon_code_point'] = iconCodePoint;
    if (objective != null && objective.trim().isNotEmpty) data['objective'] = objective.trim();
    if (weekdays != null && weekdays.isNotEmpty) data['weekdays'] = weekdays;
    if (endDate != null) data['end_date'] = endDate.toIso8601String().split('T').first;

    final res = await _client.from('challenges').insert(data).select().single();
    return Challenge.fromJson(Map<String, dynamic>.from(res));
  }

  Future<Challenge> update(
    String id, {
    String? name,
    ChallengeType? type,
    num? target,
    String? unit,
    num? unitAmount,
    ChallengeFrequency? frequency,
    int? iconCodePoint,
    bool? isPublic,
    String? objective,
    List<int>? weekdays,
    DateTime? startDate,
    DateTime? endDate,
    ChallengeCategory? category,
    LifeAspect? lifeAspect,
    bool updateLifeAspect = false,
  }) async {
    final data = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (name != null) data['name'] = name;
    if (type != null) data['type'] = type.value;
    if (target != null) data['target'] = target;
    if (unit != null) data['unit'] = unit;
    if (unitAmount != null) data['unit_amount'] = unitAmount;
    if (frequency != null) data['frequency'] = frequency.value;
    if (iconCodePoint != null) data['icon_code_point'] = iconCodePoint;
    if (isPublic != null) data['is_public'] = isPublic;
    if (objective != null) data['objective'] = objective.trim().isEmpty ? null : objective.trim();
    if (weekdays != null) data['weekdays'] = weekdays.isEmpty ? null : weekdays;
    if (startDate != null) data['start_date'] = startDate.toIso8601String().split('T').first;
    if (endDate != null) data['end_date'] = endDate.toIso8601String().split('T').first;
    if (category != null) data['category'] = category.name;
    if (updateLifeAspect) data['life_aspect'] = lifeAspect?.name;

    final res =
        await _client.from('challenges').update(data).eq('id', id).select().single();
    return Challenge.fromJson(Map<String, dynamic>.from(res));
  }

  Future<void> delete(String id) async {
    await _client.from('challenges').delete().eq('id', id);
  }

  /// Retos marcados como destacados (is_featured = true).
  Future<List<Challenge>> getFeaturedChallenges() async {
    final res = await _client
        .from('challenges')
        .select()
        .eq('is_featured', true)
        .eq('is_public', true)
        .order('created_at', ascending: false)
        .limit(10);

    return (res as List<dynamic>)
        .map((e) => Challenge.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Marca o desmarca un reto como destacado (solo admins).
  Future<void> setFeatured(String id, {required bool featured}) async {
    await _client
        .from('challenges')
        .update({'is_featured': featured})
        .eq('id', id);
  }

  /// Todos los retos públicos (para el panel de administración).
  Future<List<Challenge>> getAllPublicChallenges({int limit = 100}) async {
    final res = await _client
        .from('challenges')
        .select()
        .eq('is_public', true)
        .order('is_featured', ascending: false)
        .order('created_at', ascending: false)
        .limit(limit);

    return (res as List<dynamic>)
        .map((e) => Challenge.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
