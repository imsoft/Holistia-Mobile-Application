import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/expert_request.dart';

class ExpertRequestRepository {
  ExpertRequestRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  /// Solicitud del usuario actual (null si nunca envió una).
  Future<ExpertRequest?> getMyRequest() async {
    final uid = _userId;
    if (uid == null) return null;

    final res = await _client
        .from('expert_requests')
        .select()
        .eq('user_id', uid)
        .maybeSingle();

    return res != null
        ? ExpertRequest.fromJson(Map<String, dynamic>.from(res))
        : null;
  }

  /// Envía una nueva solicitud (o reenvía tras un rechazo).
  Future<void> submit(String bio) async {
    await _client.rpc('submit_expert_request', params: {'p_bio': bio});
  }
}
