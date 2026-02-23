import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../utils/constants.dart';
import '../utils/cache_helper.dart';

/// Fetches healthcare professionals (doctors, psychologists, speech therapists, occupational therapists)
/// so that families can contact them from the Healthcare tab.
class HealthcareService {
  final http.Client _client;
  final FlutterSecureStorage _storage;

  // Simple cache for the directory; healthcare professionals do not change often.
  List<User>? _cachedProfessionals;
  DateTime? _cachedAt;

  HealthcareService({
    http.Client? client,
    FlutterSecureStorage? storage,
  })  : _client = client ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await _storage.read(key: AppConstants.jwtTokenKey);
  }

  Future<List<User>> getHealthcareProfessionals() async {
    // 1) Prefer in-memory cache if still quite fresh.
    if (_cachedProfessionals != null &&
        _cachedAt != null &&
        DateTime.now().difference(_cachedAt!) <
            const Duration(hours: 3)) {
      return _cachedProfessionals!;
    }

    // 2) Try disk cache as a warm start before network.
    final diskRaw = await CacheHelper.load(
      'cache_healthcare_professionals',
      maxAge: const Duration(hours: 12),
    );
    if (diskRaw is List && _cachedProfessionals == null) {
      final fromDisk = diskRaw
          .map((e) => User.fromJson(e as Map<String, dynamic>))
          .toList();
      _cachedProfessionals = fromDisk;
      _cachedAt = DateTime.now();
      // Callers can already render with this list; we still refresh from API.
    }

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
    final parsed = list
        .map((e) => User.fromJson(e as Map<String, dynamic>))
        .toList();

    _cachedProfessionals = parsed;
    _cachedAt = DateTime.now();
    await CacheHelper.save('cache_healthcare_professionals', list);

    return parsed;
  }
}
