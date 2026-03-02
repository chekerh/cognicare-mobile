import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/reel.dart';
import '../utils/constants.dart';

class ReelsService {
  final http.Client _client = http.Client();

  /// Liste des reels (vidéos courtes troubles cognitifs / autisme).
  Future<ReelsListResult> getReels({int page = 1, int limit = 20}) async {
    final uri = Uri.parse(
        '${AppConstants.baseUrl}${AppConstants.reelsEndpoint}')
        .replace(queryParameters: {
      'page': page.toString(),
      'limit': limit.toString(),
    });
    final response = await _client.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('Failed to load reels: ${response.statusCode}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
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
