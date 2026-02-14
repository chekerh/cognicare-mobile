import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

class EngagementActivity {
  final String id;
  final String type; // 'game' | 'task'
  final String title;
  final String subtitle;
  final String time;
  final String? badgeLabel;
  final String? badgeColor;

  EngagementActivity({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.time,
    this.badgeLabel,
    this.badgeColor,
  });

  factory EngagementActivity.fromJson(Map<String, dynamic> json) {
    final badge = json['badge'] as Map<String, dynamic>?;
    return EngagementActivity(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'task',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      time: json['time'] as String? ?? '',
      badgeLabel: badge?['label'] as String?,
      badgeColor: badge?['color'] as String?,
    );
  }
}

class EngagementBadge {
  final String id;
  final String name;
  final String? description;
  final String? iconUrl;
  final String earnedAt;

  EngagementBadge({
    required this.id,
    required this.name,
    this.description,
    this.iconUrl,
    required this.earnedAt,
  });

  factory EngagementBadge.fromJson(Map<String, dynamic> json) {
    return EngagementBadge(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      iconUrl: json['iconUrl'] as String?,
      earnedAt: json['earnedAt'] as String? ?? '',
    );
  }
}

class EngagementDashboard {
  final String childId;
  final String childName;
  final int playTimeTodayMinutes;
  final int playTimeGoalMinutes;
  final String focusMessage;
  final List<EngagementActivity> recentActivities;
  final List<EngagementBadge> badges;

  EngagementDashboard({
    required this.childId,
    required this.childName,
    required this.playTimeTodayMinutes,
    required this.playTimeGoalMinutes,
    required this.focusMessage,
    required this.recentActivities,
    required this.badges,
  });

  factory EngagementDashboard.fromJson(Map<String, dynamic> json) {
    final activities = json['recentActivities'] as List<dynamic>? ?? [];
    final badgesList = json['badges'] as List<dynamic>? ?? [];
    return EngagementDashboard(
      childId: json['childId'] as String? ?? '',
      childName: json['childName'] as String? ?? '',
      playTimeTodayMinutes: (json['playTimeTodayMinutes'] as num?)?.toInt() ?? 0,
      playTimeGoalMinutes: (json['playTimeGoalMinutes'] as num?)?.toInt() ?? 60,
      focusMessage: json['focusMessage'] as String? ?? '',
      recentActivities: activities.map((e) => EngagementActivity.fromJson(e as Map<String, dynamic>)).toList(),
      badges: badgesList.map((e) => EngagementBadge.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class EngagementService {
  final http.Client _client = http.Client();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> _getToken() async {
    return _storage.read(key: AppConstants.jwtTokenKey);
  }

  /// Récupère le tableau d'engagement (temps de jeu, activités récentes, badges).
  /// [childId] optionnel : si null, le backend utilise le premier enfant de la famille.
  Future<EngagementDashboard> getDashboard({String? childId}) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) throw Exception('Non authentifié');
    final url = AppConstants.baseUrl + AppConstants.engagementDashboardUrl(childId);
    final response = await _client.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 200) {
      try {
        final err = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(err['message'] ?? 'Erreur chargement tableau d\'engagement');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Erreur: ${response.statusCode}');
      }
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return EngagementDashboard.fromJson(data);
  }
}
