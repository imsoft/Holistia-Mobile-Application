import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/life_aspect.dart';
import '../models/life_assessment.dart';

class LifeAssessmentRepository {
  LifeAssessmentRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  /// Devuelve true si el usuario ya completó (o guardó) la encuesta al menos una vez.
  Future<bool> hasMyAssessments() async {
    final uid = _userId;
    if (uid == null) return false;
    final res = await _client
        .from('life_assessments')
        .select('user_id')
        .eq('user_id', uid)
        .limit(1);
    return (res as List<dynamic>).isNotEmpty;
  }

  Future<List<LifeAssessment>> getMyAssessments() async {
    final uid = _userId;
    if (uid == null) return [];
    final res = await _client
        .from('life_assessments')
        .select('aspect, score, reason, check_in_count')
        .eq('user_id', uid);
    return (res as List<dynamic>)
        .map((e) => LifeAssessment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Devuelve el assessment de un aspecto concreto del usuario, o null si no existe.
  Future<LifeAssessment?> getMyAspectAssessment(LifeAspect aspect) async {
    final uid = _userId;
    if (uid == null) return null;
    final res = await _client
        .from('life_assessments')
        .select('aspect, score, reason, check_in_count')
        .eq('user_id', uid)
        .eq('aspect', aspect.name)
        .maybeSingle();
    if (res == null) return null;
    return LifeAssessment.fromJson(res);
  }

  Future<void> upsertAll(
    Map<LifeAspect, ({int score, String? reason})> entries,
  ) async {
    if (entries.isEmpty) return;
    final userId = _userId;
    if (userId == null) return;

    final now = DateTime.now().toIso8601String();
    final rows = entries.entries.map((e) {
      final reason = e.value.reason?.trim();
      return {
        'user_id': userId,
        'aspect': e.key.name,
        'score': e.value.score,
        'reason': (reason != null && reason.isNotEmpty) ? reason : null,
        'updated_at': now,
      };
    }).toList();

    await _client.from('life_assessments').upsert(rows, onConflict: 'user_id, aspect');
  }
}
