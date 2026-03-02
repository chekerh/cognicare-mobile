import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/reel.dart';
import '../utils/constants.dart';

class ReelsService {
  final http.Client _client = http.Client();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, String>> _authHeaders() async {
    final token = await _storage.read(key: AppConstants.jwtTokenKey);
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// Lance le chargement des reels depuis Invidious (nécessite d'être connecté).
  Future<ReelsRefreshResult> refreshReels() async {
    final uri = Uri.parse(
        '${AppConstants.baseUrl}${AppConstants.reelsRefreshEndpoint}');
    final response = await _client
        .post(uri, headers: await _authHeaders())
        .timeout(const Duration(seconds: 60));
    if (response.statusCode == 401) {
      throw Exception('Connectez-vous pour charger les vidéos.');
    }
    if (response.statusCode != 200 && response.statusCode != 201) {
      final body = response.body;
      try {
        final err = jsonDecode(body) as Map<String, dynamic>;
        throw Exception(err['message'] ?? 'Échec du chargement');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Échec: ${response.statusCode}');
      }
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return ReelsRefreshResult(
      added: (data['added'] as num?)?.toInt() ?? 0,
      skipped: (data['skipped'] as num?)?.toInt() ?? 0,
    );
  }

  /// Liste des reels (vidéos courtes troubles cognitifs / autisme).
  Future<ReelsListResult> getReels({int page = 1, int limit = 20}) async {
    final uri = Uri.parse(
        '${AppConstants.baseUrl}${AppConstants.reelsEndpoint}')
        .replace(queryParameters: {
      'page': page.toString(),
      'limit': limit.toString(),
    });
    // Render peut mettre 30–50 s à se réveiller (cold start) au premier appel.
    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 45), onTimeout: () {
      throw Exception(
        'Délai dépassé. Le serveur (Render) met peut-être du temps à démarrer. Réessayez.',
      );
    });
    if (response.statusCode != 200) {
      throw Exception(
        'Serveur indisponible (${response.statusCode}). Vérifiez que le backend tourne.',
      );
    }
    Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Réponse serveur invalide.');
    }
    final list = (data['reels'] as List<dynamic>?)
        ?.map((e) => Reel.fromJson(e as Map<String, dynamic>))
        .toList() ?? [];
    return ReelsListResult(
      reels: list,
      total: (data['total'] as num?)?.toInt() ?? 0,
      page: (data['page'] as num?)?.toInt() ?? 1,
      totalPages: (data['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}

class ReelsListResult {
  const ReelsListResult({
    required this.reels,
    required this.total,
    required this.page,
    required this.totalPages,
  });
  final List<Reel> reels;
  final int total;
  final int page;
  final int totalPages;
}

class ReelsRefreshResult {
  const ReelsRefreshResult({required this.added, required this.skipped});
  final int added;
  final int skipped;
}
