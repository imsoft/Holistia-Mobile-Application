import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/expert_request.dart';
import '../models/profile.dart';

/// Repositorio exclusivo para administradores.
/// Todas las operaciones están protegidas en Supabase por RLS y RPCs SECURITY DEFINER.
class AdminRepository {
  AdminRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Solicitudes de experto pendientes de revisión.
  Future<List<ExpertRequestWithProfile>> getPendingRequests() async {
    final requestRows = await _client
        .from('expert_requests')
        .select('*')
        .eq('status', 'pending')
        .order('created_at', ascending: true) as List<dynamic>;

    if (requestRows.isEmpty) return [];

    final requests = requestRows
        .map((r) => ExpertRequest.fromJson(Map<String, dynamic>.from(r)))
        .toList();

    final userIds = requests.map((r) => r.userId).toList();

    final profileRows = await _client
        .from('profiles')
        .select('id, display_name, avatar_url, username, created_at')
        .inFilter('id', userIds) as List<dynamic>;

    final profilesById = {
      for (final r in profileRows)
        (r as Map<String, dynamic>)['id'] as String:
            AppProfile.fromJson(Map<String, dynamic>.from(r)),
    };

    return requests
        .map((req) => ExpertRequestWithProfile(
              request: req,
              profile: profilesById[req.userId],
            ))
        .toList();
  }

  /// Lista de todos los usuarios con su rol.
  Future<List<AppProfile>> getAllUsers({int limit = 100}) async {
    final rows = await _client
        .from('profiles')
        .select('id, display_name, avatar_url, username, role, created_at')
        .order('created_at', ascending: false)
        .limit(limit) as List<dynamic>;

    return rows
        .map((r) => AppProfile.fromJson(Map<String, dynamic>.from(r)))
        .toList();
  }

  /// Aprueba o rechaza una solicitud de experto.
  Future<void> reviewRequest(String requestId, {required bool approve}) async {
    await _client.rpc('review_expert_request', params: {
      'p_request_id': requestId,
      'p_approved': approve,
    });
  }
}

/// Solicitud de experto con el perfil del solicitante adjunto.
class ExpertRequestWithProfile {
  const ExpertRequestWithProfile({required this.request, this.profile});
  final ExpertRequest request;
  final AppProfile? profile;
}
