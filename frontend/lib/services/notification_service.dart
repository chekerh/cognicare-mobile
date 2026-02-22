import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/task_reminder.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
    );
  }

  /// Private helper for simple one-off notifications
  Future<void> _showBasicNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channelId = 'general_channel',
    String channelName = 'Général',
  }) async {
    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notificationsPlugin.show(id, title, body, notificationDetails,
        payload: payload);
  }

  // --- Call and Message Notifications ---

  Future<void> showIncomingCall(
      {required String callerName, required bool isVideo}) async {
    await _showBasicNotification(
      id: 1,
      title: 'Appel entrant',
      body: '$callerName vous appelle en ${isVideo ? 'vidéo' : 'audio'}',
      channelId: 'calls_channel',
      channelName: 'Appels',
    );
  }

  Future<void> showNewMessage(
      {required String senderName, required String preview}) async {
    await _showBasicNotification(
      id: 2,
      title: senderName,
      body: preview,
      channelId: 'messages_channel',
      channelName: 'Messages',
    );
  }

  Future<void> showPaymentConfirmation(
      {required String orderId, required String amount}) async {
    await _showBasicNotification(
      id: 3,
      title: 'Paiement confirmé',
      body: 'Commande #$orderId validée ($amount)',
      channelId: 'orders_channel',
      channelName: 'Commandes',
    );
  }

  // --- Routine Notifications ---

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'routine_channel',
          'Routines Quotidiennes',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> syncNotifications(List<TaskReminder> reminders) async {
    await cancelAll();

    int notificationId = 100;
    for (final reminder in reminders) {
      if (reminder.times.isEmpty) continue;

      for (final timeStr in reminder.times) {
        try {
          final parts = timeStr.split(':');
          final time = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );

          await scheduleNotification(
            id: notificationId++,
            title: reminder.title,
            body: reminder.description ?? 'C\'est l\'heure de votre tâche !',
            time: time,
          );
        } catch (e) {
          // Skip invalid
        }
      }
    }
  }

  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}
