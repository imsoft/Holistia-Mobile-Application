import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/notification.dart';

class NotificationRepository {
  NotificationRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  /// Obtiene las notificaciones del usuario actual (más recientes primero).
  Future<List<AppNotification>> getMyNotifications({int limit = 50}) async {
    final uid = _userId;
    if (uid == null) return [];

    final res = await _client
        .from('notifications')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .limit(limit);

    return (res as List<dynamic>)
        .map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Cuenta las notificaciones no leídas del usuario actual.
  Future<int> getUnreadCount() async {
    final uid = _userId;
    if (uid == null) return 0;

    final res = await _client
        .from('notifications')
        .select('id')
        .eq('user_id', uid)
        .eq('is_read', false);
    return (res as List<dynamic>).length;
  }

  /// Marca una notificación como leída.
  Future<void> markAsRead(String notificationId) async {
    final uid = _userId;
    if (uid == null) return;

    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId)
        .eq('user_id', uid);
  }

  /// Marca todas las notificaciones del usuario como leídas.
  Future<void> markAllAsRead() async {
    final uid = _userId;
    if (uid == null) return;

    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', uid)
        .eq('is_read', false);
  }
}
