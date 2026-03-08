import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Servicio para notificaciones locales (recordatorios diarios).
/// Solo funciona en iOS y Android; en escritorio/web no hace nada.
class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _pluginAvailable = true;

  /// Inicializa el servicio de notificaciones (solo en iOS/Android).
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('America/Mexico_City')); // Ajusta según tu zona horaria

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Solicitar permisos en Android 13+
      final android = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        await android.requestNotificationsPermission();
      }
    } on MissingPluginException {
      _pluginAvailable = false;
    } catch (_) {
      _pluginAvailable = false;
    }
    _initialized = true;
  }

  /// Programa un recordatorio diario a las [hour]:[minute].
  /// Si ya existe uno, lo cancela y crea uno nuevo.
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    String title = '¡No olvides registrar tu reto!',
    String body = 'Es momento de registrar tu progreso diario',
  }) async {
    if (!_initialized) await initialize();
    if (!_pluginAvailable) return;

    // Cancelar recordatorio anterior si existe
    await _notifications.cancel(id: 0);

    // Programar nuevo recordatorio diario
    await _notifications.zonedSchedule(
      id: 0, // ID único para este recordatorio
      title: title,
      body: body,
      scheduledDate: _nextInstanceOfTime(hour, minute),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Recordatorios diarios',
          channelDescription: 'Notificaciones para recordar registrar tu reto',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // Repetir diariamente a esta hora
    );
  }

  /// Cancela el recordatorio diario.
  Future<void> cancelDailyReminder() async {
    if (!_pluginAvailable) return;
    await _notifications.cancel(id: 0);
  }

  /// Calcula la próxima instancia de la hora especificada.
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Muestra una notificación push inmediata (cuando llega desde Realtime).
  Future<void> showPushNotification({
    required String title,
    required String body,
    String? payload,
    int id = 1, // ID diferente al recordatorio diario (0)
  }) async {
    if (!_initialized) await initialize();
    if (!_pluginAvailable) return;

    await _notifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'push_notifications',
          'Notificaciones push',
          channelDescription: 'Notificaciones cuando alguien te sigue, comenta o da zenit',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  /// Callback cuando se toca una notificación.
  void _onNotificationTapped(NotificationResponse response) {
    // Puedes navegar a una pantalla específica aquí si es necesario
    // Por ejemplo: GoRouter.of(context).go('/challenges');
  }
}
