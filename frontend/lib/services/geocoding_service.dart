import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service de géocodage via Nominatim (OpenStreetMap) - gratuit, sans clé API.
class GeocodingService {
  final http.Client _client = http.Client();
  static const String _nominatimUrl = 'https://nominatim.openstreetmap.org/search';

  /// Convertit une adresse ou un lieu en coordonnées (lat, lng).
  /// Retourne null si non trouvé.
  /// Essaie des variantes (ex: "ariana" -> "Ariana, Tunisie") pour améliorer les résultats.
  Future<GeocodingResult?> geocode(String address) async {
    final trimmed = address.trim();
    if (trimmed.isEmpty) return null;

    final queries = <String>[trimmed];
    if (!trimmed.contains(',')) {
      queries.add('$trimmed, Tunisie');
      queries.add('$trimmed, France');
    }

    for (final q in queries) {
      final result = await _geocodeQuery(q);
      if (result != null) return result;
    }
    return null;
  }

  Future<GeocodingResult?> _geocodeQuery(String query) async {
    try {
      final uri = Uri.parse(_nominatimUrl).replace(
        queryParameters: {
          'q': query,
          'format': 'json',
          'limit': '1',
        },
      );
      final response = await _client.get(
        uri,
        headers: {
          'User-Agent': 'CogniCare/1.0 (donation app)',
        },
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      final list = jsonDecode(response.body) as List<dynamic>?;
      if (list == null || list.isEmpty) return null;
      final first = list.first as Map<String, dynamic>;
      final lat = (first['lat'] as num?)?.toDouble();
      final lng = (first['lon'] as num?)?.toDouble();
      final displayName = first['display_name'] as String?;
      if (lat == null || lng == null) return null;
      return GeocodingResult(
        latitude: lat,
        longitude: lng,
        displayName: displayName ?? query,
      );
    } catch (_) {
      return null;
    }
  }
}

class GeocodingResult {
  final double latitude;
  final double longitude;
  final String displayName;

  GeocodingResult({
    required this.latitude,
    required this.longitude,
    required this.displayName,
  });
}
