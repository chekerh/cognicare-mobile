import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service de géocodage — accepte toute localisation dans le monde.
/// Utilise Photon (Komoot) puis Nominatim (OSM), gratuits et sans clé API.
class GeocodingService {
  final http.Client _client = http.Client();
  static const String _photonUrl = 'https://photon.komoot.io/api/';
  static const String _nominatimUrl = 'https://nominatim.openstreetmap.org/search';

  /// Convertit une adresse ou un lieu en coordonnées (lat, lng).
  /// Accepte toute localisation dans le monde.
  Future<GeocodingResult?> geocode(String address) async {
    final trimmed = address.trim();
    if (trimmed.isEmpty) return null;

    final result = await _geocodePhoton(trimmed) ?? await _geocodeNominatim(trimmed);
    return result;
  }

  /// Photon (Komoot) — rapide, couverture mondiale.
  Future<GeocodingResult?> _geocodePhoton(String query) async {
    try {
      final uri = Uri.parse(_photonUrl).replace(
        queryParameters: {'q': query, 'limit': '1'},
      );
      final response = await _client.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body) as Map<String, dynamic>?;
      final features = json?['features'] as List<dynamic>?;
      if (features == null || features.isEmpty) return null;
      final first = features.first as Map<String, dynamic>;
      final coords = first['geometry']?['coordinates'] as List<dynamic>?;
      final props = first['properties'] as Map<String, dynamic>?;
      if (coords == null || coords.length < 2) return null;
      final lng = (coords[0] as num).toDouble();
      final lat = (coords[1] as num).toDouble();
      final name = props?['name'] as String?;
      final country = props?['country'] as String?;
      final display = [name, country].where((e) => e != null && e.toString().isNotEmpty).join(', ');
      return GeocodingResult(
        latitude: lat,
        longitude: lng,
        displayName: display.isNotEmpty ? display : query,
      );
    } catch (_) {
      return null;
    }
  }

  /// Nominatim (OpenStreetMap) — fallback.
  Future<GeocodingResult?> _geocodeNominatim(String query) async {
    try {
      final uri = Uri.parse(_nominatimUrl).replace(
        queryParameters: {'q': query, 'format': 'json', 'limit': '1'},
      );
      final response = await _client.get(
        uri,
        headers: {'User-Agent': 'CogniCare/1.0'},
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

  const GeocodingResult({
    required this.latitude,
    required this.longitude,
    required this.displayName,
  });
}
