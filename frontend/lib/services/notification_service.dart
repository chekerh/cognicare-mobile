import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/task_reminder.dart';
import '../utils/constants.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static GoRouter? _router;

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// À appeler après la création du routeur (ex. dans CogniCareApp) pour que le tap sur une notif ouvre l'écran cible.
  static void setRouter(GoRouter router) {
    _router = router;
  }

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
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload == 'appointment' && _router != null) {
          Future.microtask(() {
            _router!.go(AppConstants.familyExpertAppointmentsRoute);
          });
        }
      },
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

  /// Rappel de rendez-vous : notif à l'heure du RDV (ou 10 min avant). Au tap → écran Mes Rendez-vous.
  static const int _appointmentIdBase = 500;

  Future<void> scheduleAppointmentReminder({
    required String dateIso,
    required String time,
    required String title,
    String? subtitle,
  }) async {
    DateTime? scheduledAt;
    try {
      final parts = dateIso.split('-');
      if (parts.length == 3) {
        final y = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        final d = int.parse(parts[2]);
        final timeParts = time.split(':');
        final hour = timeParts.isNotEmpty ? int.parse(timeParts[0]) : 9;
        final minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;
        scheduledAt = DateTime(y, m, d, hour, minute);
      }
    } catch (_) {
      return;
    }
    if (scheduledAt == null) return;
    // 10 minutes before
    scheduledAt = scheduledAt.subtract(const Duration(minutes: 10));
    if (scheduledAt.isBefore(DateTime.now())) return;

    final id = _appointmentIdBase +
        (dateIso.hashCode + time.hashCode + title.hashCode).abs() % 50000;
    final body = subtitle != null && subtitle.isNotEmpty
        ? '$subtitle à $time'
        : 'À $time';

    await _notificationsPlugin.zonedSchedule(
      id,
      'Rappel : $title',
      body,
      tz.TZDateTime.from(scheduledAt, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'appointment_reminder_channel',
          'Rappels de rendez-vous',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'appointment',
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
