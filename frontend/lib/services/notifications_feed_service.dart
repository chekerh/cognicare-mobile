import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/app_notification.dart';
import '../utils/constants.dart';

/// Service pour le centre de notifications (liste depuis l'API, marquer lu).
class NotificationsFeedService {
  final http.Client _client = http.Client();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> _getToken() async {
    return _storage.read(key: AppConstants.jwtTokenKey);
  }

  Future<Map<String, String>> _headers() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Liste les notifications de l'utilisateur + nombre de non lues.
  Future<NotificationsFeedResult> getNotifications({int limit = 50}) async {
    final uri = Uri.parse(
      '${AppConstants.baseUrl}${AppConstants.notificationsEndpoint}',
    ).replace(queryParameters: {'limit': limit.toString()});
    final response = await _client.get(uri, headers: await _headers());
    if (response.statusCode != 200) {
      throw Exception('Échec chargement notifications: ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final list = body['notifications'] as List<dynamic>? ?? [];
    final unreadCount = (body['unreadCount'] is int)
        ? body['unreadCount'] as int
        : 0;
    final notifications = list
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
    return NotificationsFeedResult(
      notifications: notifications,
      unreadCount: unreadCount,
    );
  }

  /// Marquer une notification comme lue.
  Future<void> markRead(String notificationId) async {
    final uri = Uri.parse(
      '${AppConstants.baseUrl}${AppConstants.notificationMarkReadEndpoint(notificationId)}',
    );
    final response = await _client.patch(uri, headers: await _headers());
    if (response.statusCode != 200) {
      throw Exception('Échec: ${response.statusCode}');
    }
  }

  /// Marquer toutes les notifications comme lues.
  Future<void> markAllRead() async {
    final uri = Uri.parse(
      '${AppConstants.baseUrl}${AppConstants.notificationsReadAllEndpoint}',
    );
    final response = await _client.post(uri, headers: await _headers());
    if (response.statusCode != 200) {
      throw Exception('Échec: ${response.statusCode}');
    }
  }

  /// Créer une notification (ex: confirmation de commande) — enregistrée dans le centre de notifications.
  Future<void> createNotification({
    required String type,
    required String title,
    String description = '',
  }) async {
    final uri = Uri.parse(
      '${AppConstants.baseUrl}${AppConstants.notificationsEndpoint}',
    );
    final response = await _client.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({
        'type': type,
        'title': title,
        'description': description,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Échec enregistrement notification: ${response.statusCode}');
    }
  }
}

class NotificationsFeedResult {
  final List<AppNotification> notifications;
  final int unreadCount;

  NotificationsFeedResult({
    required this.notifications,
    required this.unreadCount,
  });
}
