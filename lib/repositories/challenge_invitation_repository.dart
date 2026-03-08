import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';

class ChallengeInvitationRepository {
  ChallengeInvitationRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  /// Perfiles de los usuarios que el usuario actual sigue (para mostrar en el picker).
  Future<List<AppProfile>> getFollowingProfiles() async {
    final uid = _userId;
    if (uid == null) return [];

    final followRows = await _client
        .from('user_follows')
        .select('following_id')
        .eq('follower_id', uid) as List<dynamic>;

    if (followRows.isEmpty) return [];

    final ids = followRows.map((r) => r['following_id'] as String).toList();

    final profileRows = await _client
        .from('profiles')
        .select('id, display_name, avatar_url, username, created_at')
        .inFilter('id', ids) as List<dynamic>;

    return profileRows
        .map((r) => AppProfile.fromJson(Map<String, dynamic>.from(r)))
        .toList();
  }

  /// IDs de usuarios ya invitados por el usuario actual a un reto.
  Future<Set<String>> getInvitedUserIds(String challengeId) async {
    final uid = _userId;
    if (uid == null) return {};

    final rows = await _client
        .from('challenge_invitations')
        .select('invitee_id')
        .eq('challenge_id', challengeId)
        .eq('inviter_id', uid) as List<dynamic>;

    return rows.map((r) => r['invitee_id'] as String).toSet();
  }

  /// IDs de retos a los que el usuario actual tiene invitaciones pendientes.
  Future<Set<String>> getMyPendingInvitationChallengeIds() async {
    final uid = _userId;
    if (uid == null) return {};

    final rows = await _client
        .from('challenge_invitations')
        .select('challenge_id')
        .eq('invitee_id', uid)
        .eq('status', 'pending') as List<dynamic>;

    return rows.map((r) => r['challenge_id'] as String).toSet();
  }

  /// Responde a una invitación recibida. [accept] = true → 'accepted', false → 'declined'.
  Future<void> respond(String challengeId, {required bool accept}) async {
    await _client.rpc('respond_to_challenge_invitation', params: {
      'p_challenge_id': challengeId,
      'p_status': accept ? 'accepted' : 'declined',
    });
  }

  /// Mapa challenge_id → lista de invitados. Se usa en el feed para mostrar
  /// quiénes están invitados a cada reto (excluye rechazados).
  Future<Map<String, List<AppProfile>>> getInviteesForChallenges(
    List<String> challengeIds,
  ) async {
    if (challengeIds.isEmpty) return {};

    final inviteRows = await _client
        .from('challenge_invitations')
        .select('challenge_id, invitee_id')
        .inFilter('challenge_id', challengeIds)
        .neq('status', 'declined') as List<dynamic>;

    if (inviteRows.isEmpty) return {};

    final inviteeIds =
        inviteRows.map((r) => r['invitee_id'] as String).toSet().toList();

    final profileRows = await _client
        .from('profiles')
        .select('id, display_name, avatar_url, username, created_at')
        .inFilter('id', inviteeIds) as List<dynamic>;

    final profilesById = {
      for (final r in profileRows)
        (r as Map<String, dynamic>)['id'] as String:
            AppProfile.fromJson(Map<String, dynamic>.from(r)),
    };

    final result = <String, List<AppProfile>>{};
    for (final row in inviteRows) {
      final challengeId = row['challenge_id'] as String;
      final inviteeId = row['invitee_id'] as String;
      final profile = profilesById[inviteeId];
      if (profile != null) {
        result.putIfAbsent(challengeId, () => []).add(profile);
      }
    }
    return result;
  }

  /// Envía una invitación. Lanza excepción si se supera el límite o ya fue invitado.
  Future<void> invite(String challengeId, String inviteeId) async {
    await _client.rpc('invite_to_challenge', params: {
      'p_challenge_id': challengeId,
      'p_invitee_id': inviteeId,
    });
  }
}
