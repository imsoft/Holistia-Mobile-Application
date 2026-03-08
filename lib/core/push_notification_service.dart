import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/notification.dart';
import 'local_notification_service.dart';

/// Servicio para escuchar nuevas notificaciones desde Supabase Realtime
/// y mostrarlas como push notifications.
class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  RealtimeChannel? _channel;
  bool _isListening = false;
  
  /// Stream para notificar cuando llega una nueva notificación (para actualizar badges).
  final _notificationStreamController = StreamController<AppNotification>.broadcast();
  Stream<AppNotification> get notificationStream => _notificationStreamController.stream;

  /// Inicia la escucha de nuevas notificaciones para el usuario actual.
  /// Muestra push notifications cuando llegan nuevas.
  void startListening() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || _isListening) return;

    _isListening = true;

    // Suscribirse a cambios en la tabla notifications para este usuario
    _channel = Supabase.instance.client.channel('notifications:$userId')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (payload) {
          _handleNewNotification(payload);
        },
      )
      ..subscribe();

    if (kDebugMode) {
      print('PushNotificationService: Escuchando notificaciones para usuario $userId');
    }
  }

  /// Detiene la escucha de notificaciones.
  void stopListening() {
    if (_channel != null) {
      Supabase.instance.client.removeChannel(_channel!);
      _channel = null;
    }
    _isListening = false;
  }

  /// Maneja una nueva notificación recibida desde Realtime.
  void _handleNewNotification(PostgresChangePayload payload) {
    try {
      final newRecord = payload.newRecord;
      final notification = AppNotification.fromJson(newRecord);

      // Emitir al stream para que otros widgets puedan reaccionar (ej. actualizar badge)
      _notificationStreamController.add(notification);

      // Mostrar push notification local
      LocalNotificationService().showPushNotification(
        title: notification.title,
        body: notification.body,
        payload: notification.id, // Para navegar después
        id: DateTime.now().millisecondsSinceEpoch % 2147483647, // ID único
      );

      if (kDebugMode) {
        print('PushNotificationService: Nueva notificación recibida: ${notification.title}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('PushNotificationService: Error al procesar notificación: $e');
      }
    }
  }

  /// Limpia recursos.
  void dispose() {
    _notificationStreamController.close();
    stopListening();
  }

  /// Reinicia la escucha (útil cuando el usuario cambia de sesión).
  void restart() {
    stopListening();
    startListening();
  }
}
