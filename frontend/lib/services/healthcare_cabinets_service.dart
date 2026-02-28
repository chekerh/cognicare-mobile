import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/healthcare_cabinet.dart';
import '../utils/constants.dart';

/// Cabinets et centres de santé en Tunisie (hors app) — pour la carte famille.
class HealthcareCabinetsService {
  final http.Client _client = http.Client();

  Future<List<HealthcareCabinet>> getCabinets() async {
    final base = AppConstants.baseUrl.endsWith('/')
        ? AppConstants.baseUrl.substring(0, AppConstants.baseUrl.length - 1)
        : AppConstants.baseUrl;
    final url = '$base${AppConstants.healthcareCabinetsEndpoint}';
    final response = await _client.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Erreur: ${response.statusCode}');
    }
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => HealthcareCabinet.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
