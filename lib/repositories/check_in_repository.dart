import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/check_in.dart';

/// Entrada del ranking de un reto.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.total,
  });

  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int total;
}

/// Progreso diario para el gráfico semanal.
class DayStat {
  const DayStat({required this.date, required this.value});
  final DateTime date;
  final num value; // 1 para streak, suma para count_units
}

class CheckInRepository {
  CheckInRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  Future<List<CheckIn>> getByChallengeId(String challengeId) async {
    final res = await _client
        .from('check_ins')
        .select()
        .eq('challenge_id', challengeId)
        .order('date', ascending: false);

    return (res as List<dynamic>)
        .map((e) => CheckIn.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Obtiene todos los check-ins de una lista de retos en una sola query.
  /// Devuelve un mapa challengeId → lista de check-ins (ordenados por fecha desc).
  Future<Map<String, List<CheckIn>>> getBatchByChallengeIds(
    List<String> challengeIds,
  ) async {
    if (challengeIds.isEmpty) return {};
    final res = await _client
        .from('check_ins')
        .select()
        .inFilter('challenge_id', challengeIds)
        .order('date', ascending: false);

    final grouped = <String, List<CheckIn>>{};
    for (final row in res as List<dynamic>) {
      final ci = CheckIn.fromJson(Map<String, dynamic>.from(row));
      (grouped[ci.challengeId] ??= []).add(ci);
    }
    return grouped;
  }

  /// Devuelve el conjunto de challengeIds en los que el usuario actual
  /// ya hizo check-in en [date]. Una sola query para N retos.
  Future<Set<String>> getCheckedInTodayBatch(
    List<String> challengeIds,
    DateTime date,
  ) async {
    final uid = _userId;
    if (uid == null || challengeIds.isEmpty) return {};
    final dateStr = _dateStr(date);
    final res = await _client
        .from('check_ins')
        .select('challenge_id')
        .inFilter('challenge_id', challengeIds)
        .eq('user_id', uid)
        .eq('date', dateStr);

    return {
      for (final row in res as List<dynamic>) row['challenge_id'] as String,
    };
  }

  Future<CheckIn?> getByChallengeAndDate(String challengeId, DateTime date) async {
    final dateStr = _dateStr(date);
    final res = await _client
        .from('check_ins')
        .select()
        .eq('challenge_id', challengeId)
        .eq('date', dateStr)
        .maybeSingle();
    if (res == null) return null;
    return CheckIn.fromJson(Map<String, dynamic>.from(res));
  }

  Future<CheckIn> insert({
    required String challengeId,
    required DateTime date,
    num? value,
    String? note,
    List<String> imageUrls = const [],
  }) async {
    final uid = _userId;
    if (uid == null) throw Exception('No hay usuario autenticado');

    final data = <String, dynamic>{
      'challenge_id': challengeId,
      'user_id': uid,
      'date': _dateStr(date),
      'image_urls': imageUrls,
    };
    if (value != null) data['value'] = value;
    if (note != null && note.isNotEmpty) data['note'] = note;

    final res = await _client.from('check_ins').insert(data).select().single();
    return CheckIn.fromJson(Map<String, dynamic>.from(res));
  }

  Future<void> delete(String id) async {
    await _client.from('check_ins').delete().eq('id', id);
  }

  /// Top 10 usuarios con más check-ins en un reto.
  ///
  /// Requiere la siguiente función en Supabase (ejecutar en SQL Editor):
  /// ```sql
  /// CREATE OR REPLACE FUNCTION get_challenge_leaderboard(p_challenge_id UUID)
  /// RETURNS TABLE (user_id UUID, display_name TEXT, avatar_url TEXT, total BIGINT)
  /// LANGUAGE sql STABLE AS $$
  ///   SELECT ci.user_id, p.display_name, p.avatar_url, COUNT(*) AS total
  ///   FROM check_ins ci
  ///   JOIN profiles p ON p.id = ci.user_id
  ///   WHERE ci.challenge_id = p_challenge_id
  ///   GROUP BY ci.user_id, p.display_name, p.avatar_url
  ///   ORDER BY total DESC
  ///   LIMIT 10;
  /// $$;
  /// ```
  Future<List<LeaderboardEntry>> getLeaderboard(String challengeId) async {
    final rows = await _client.rpc(
      'get_challenge_leaderboard',
      params: {'p_challenge_id': challengeId},
    ) as List<dynamic>;

    return rows
        .map((row) => LeaderboardEntry(
              userId: row['user_id'] as String,
              displayName: row['display_name'] as String? ?? 'Usuario',
              avatarUrl: row['avatar_url'] as String?,
              total: (row['total'] as num).toInt(),
            ))
        .toList();
  }

  /// Estadísticas de los últimos 7 días para un reto del usuario actual.
  Future<List<DayStat>> getWeeklyStats(String challengeId) async {
    final uid = _userId;
    if (uid == null) return [];

    final today = DateTime.now();
    final sevenDaysAgo = today.subtract(const Duration(days: 6));

    final res = await _client
        .from('check_ins')
        .select('date, value')
        .eq('challenge_id', challengeId)
        .eq('user_id', uid)
        .gte('date', _dateStr(sevenDaysAgo))
        .lte('date', _dateStr(today)) as List<dynamic>;

    // Mapa fecha → valor
    final map = <String, num>{};
    for (final row in res) {
      final d = row['date'] as String;
      final v = (row['value'] as num?) ?? 1;
      map[d] = (map[d] ?? 0) + v;
    }

    // Generar los 7 días (con 0 si no hay check-in)
    return List.generate(7, (i) {
      final date = sevenDaysAgo.add(Duration(days: i));
      final key = _dateStr(date);
      return DayStat(date: date, value: map[key] ?? 0);
    });
  }

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
