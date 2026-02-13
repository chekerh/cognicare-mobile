import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../utils/constants.dart';

/// Fetches healthcare professionals (doctors, psychologists, speech therapists, occupational therapists)
/// so that families can contact them from the Healthcare tab.
class HealthcareService {
  final http.Client _client;
  final FlutterSecureStorage _storage;

  HealthcareService({
    http.Client? client,
    FlutterSecureStorage? storage,
  })  : _client = client ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await _storage.read(key: AppConstants.jwtTokenKey);
  }

  Future<List<User>> getHealthcareProfessionals() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Non authentifié');
    }
    final base = AppConstants.baseUrl.endsWith('/')
        ? AppConstants.baseUrl.substring(0, AppConstants.baseUrl.length - 1)
        : AppConstants.baseUrl;
    final url = '$base/api/v1/users/healthcare';
    final response = await _client.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 200) {
      final body = response.body;
      Map<String, dynamic>? err;
      try {
        err = jsonDecode(body) as Map<String, dynamic>?;
      } catch (_) {}
      throw Exception(err?['message'] ?? 'Erreur: ${response.statusCode}');
    }
    final List<dynamic> list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => User.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
