import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

enum GameType {
  matching,
  shapeSorting,
  starTracer,
  basketSort,
  /// Temps passé en mode enfant (session ouverte).
  childMode,
}

class GameSessionResult {
  final int pointsEarned;
  final int totalPoints;
  final List<BadgeEarned> badgesEarned;
  final int currentStreak;

  GameSessionResult({
    required this.pointsEarned,
    required this.totalPoints,
    required this.badgesEarned,
    required this.currentStreak,
  });

  factory GameSessionResult.fromJson(Map<String, dynamic> json) {
    return GameSessionResult(
      pointsEarned: json['pointsEarned'] as int? ?? 0,
      totalPoints: json['totalPoints'] as int? ?? 0,
      badgesEarned: (json['badgesEarned'] as List<dynamic>?)
              ?.map((e) => BadgeEarned.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      currentStreak: json['currentStreak'] as int? ?? 0,
    );
  }
}

class BadgeEarned {
  final String badgeId;
  final String name;
  final String? description;
  final String? iconUrl;
  final DateTime earnedAt;

  BadgeEarned({
    required this.badgeId,
    required this.name,
    this.description,
    this.iconUrl,
    required this.earnedAt,
  });

  factory BadgeEarned.fromJson(Map<String, dynamic> json) {
    return BadgeEarned(
      badgeId: json['badgeId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      iconUrl: json['iconUrl'] as String?,
      earnedAt: DateTime.parse(json['earnedAt'] as String),
    );
  }
}

class ChildStats {
  final int totalPoints;
  final Map<String, int> pointsByGame;
  final int gamesCompleted;
  final List<String> gamesPlayed;
  final int currentStreak;
  final List<BadgeEarned> badges;
  final List<GameSession> recentSessions;

  ChildStats({
    required this.totalPoints,
    required this.pointsByGame,
    required this.gamesCompleted,
    required this.gamesPlayed,
    required this.currentStreak,
    required this.badges,
    required this.recentSessions,
  });

  factory ChildStats.fromJson(Map<String, dynamic> json) {
    return ChildStats(
      totalPoints: json['totalPoints'] as int? ?? 0,
      pointsByGame: (json['pointsByGame'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as int? ?? 0)) ??
          {},
      gamesCompleted: json['gamesCompleted'] as int? ?? 0,
      gamesPlayed: (json['gamesPlayed'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      currentStreak: json['currentStreak'] as int? ?? 0,
      badges: (json['badges'] as List<dynamic>?)
              ?.map((e) => BadgeEarned.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      recentSessions: (json['recentSessions'] as List<dynamic>?)
              ?.map((e) => GameSession.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class GameSession {
  final String gameType;
  final int? level;
  final bool completed;
  final int score;
  final int timeSpentSeconds;
  final DateTime createdAt;

  GameSession({
    required this.gameType,
    this.level,
    required this.completed,
    required this.score,
    required this.timeSpentSeconds,
    required this.createdAt,
  });

  factory GameSession.fromJson(Map<String, dynamic> json) {
    return GameSession(
      gameType: json['gameType'] as String? ?? '',
      level: json['level'] as int?,
      completed: json['completed'] as bool? ?? false,
      score: json['score'] as int? ?? 0,
      timeSpentSeconds: json['timeSpentSeconds'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class GamificationService {
  final http.Client _client;
  final Future<String?> Function() getToken;

  GamificationService({
    http.Client? client,
    required this.getToken,
  }) : _client = client ?? http.Client();

  String _gameTypeToString(GameType type) {
    switch (type) {
      case GameType.matching:
        return 'matching';
      case GameType.shapeSorting:
        return 'shape_sorting';
      case GameType.starTracer:
        return 'star_tracer';
      case GameType.basketSort:
        return 'basket_sort';
      case GameType.childMode:
        return 'child_mode';
    }
  }

  /// Record a game session and get points/badges earned.
  Future<GameSessionResult> recordGameSession({
    required String childId,
    required GameType gameType,
    int? level,
    required bool completed,
    int? score,
    int? timeSpentSeconds,
    Map<String, int>? metrics,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse(
      '${AppConstants.baseUrl}/api/v1/gamification/children/$childId/game-session',
    );

    final body = {
      'gameType': _gameTypeToString(gameType),
      'completed': completed,
    };
    if (level != null) body['level'] = level;
    if (score != null) body['score'] = score;
    if (timeSpentSeconds != null) body['timeSpentSeconds'] = timeSpentSeconds;
    if (metrics != null) body['metrics'] = metrics;

    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      try {
        final err = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(err['message'] ?? 'Failed to record game session');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Failed to record: ${response.statusCode}');
      }
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return GameSessionResult.fromJson(json);
  }

  /// Get child's gamification stats.
  Future<ChildStats> getChildStats(String childId) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse(
      '${AppConstants.baseUrl}/api/v1/gamification/children/$childId/stats',
    );

    final response = await _client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      try {
        final err = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(err['message'] ?? 'Failed to load stats');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Failed to load: ${response.statusCode}');
      }
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return ChildStats.fromJson(json);
  }
}
