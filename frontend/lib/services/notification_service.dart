import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service de notifications locales (appel entrant, nouveau message).
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'cognicare_calls',
    'Appels & Messages',
    description: 'Notifications d\'appels entrants et de nouveaux messages',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
    );
    const initSettings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(_channel);
      await androidPlugin?.requestNotificationsPermission();
    }
    _initialized = true;
    debugPrint('🔔 [NOTIF] Notifications locales initialisées');
  }

  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    debugPrint('🔔 [NOTIF] Notification tapée payload=$payload');
  }

  /// Affiche une notification d'appel entrant.
  Future<void> showIncomingCall({
    required String callerName,
    required bool isVideo,
  }) async {
    if (!_initialized) await initialize();
    final title = isVideo ? 'Appel vidéo entrant' : 'Appel vocal entrant';
    final body = '$callerName vous appelle';
    await _plugin.show(
      1,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.call,
          fullScreenIntent: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      payload: 'call',
    );
  }

  /// Affiche une notification de nouveau message.
  Future<void> showNewMessage({
    required String senderName,
    required String preview,
  }) async {
    if (!_initialized) await initialize();
    await _plugin.show(
      2,
      senderName,
      preview,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.defaultPriority,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'message',
    );
  }
}
