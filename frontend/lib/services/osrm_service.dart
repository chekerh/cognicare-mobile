import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// OSRM (Open Source Routing Machine) — gratuit, pas de clé API.
const String _osrmBase = 'https://router.project-osrm.org';

const Distance _distance = Distance();

/// Résultat d'un itinéraire OSRM (points + distance + durée).
class OSRMRouteResult {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;

  const OSRMRouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });
}

/// Profil OSRM : voiture (driving) ou à pied (foot).
String osrmProfileFromTravelMode(TravelMode mode) {
  switch (mode) {
    case TravelMode.car:
      return 'driving';
    case TravelMode.walking:
      return 'foot';
  }
}

/// Mode de déplacement pour l'itinéraire.
enum TravelMode { car, walking }

/// Retourne le trajet avec distance et durée, ou null si erreur.
/// [travelMode] : voiture ou à pied (change le calcul de l'itinéraire).
Future<OSRMRouteResult?> getRoute({
  required double startLat,
  required double startLng,
  required double endLat,
  required double endLng,
  TravelMode travelMode = TravelMode.car,
}) async {
  final profile = osrmProfileFromTravelMode(travelMode);
  final coords = '${startLng},$startLat;${endLng},$endLat';
  final uri = Uri.parse(
    '$_osrmBase/route/v1/$profile/$coords?overview=full&geometries=geojson',
  );
  try {
    final response = await http.get(uri).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Timeout'),
    );
    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final routes = data['routes'] as List<dynamic>?;
    if (routes == null || routes.isEmpty) return null;
    final route = routes[0] as Map<String, dynamic>;
    final distanceMeters = (route['distance'] is num)
        ? (route['distance'] as num).toDouble()
        : 0.0;
    final durationSeconds = (route['duration'] is num)
        ? (route['duration'] as num).toDouble()
        : 0.0;
    final geometry = route['geometry'] as Map<String, dynamic>?;
    if (geometry == null) return null;
    final coordsList = geometry['coordinates'] as List<dynamic>?;
    if (coordsList == null || coordsList.isEmpty) return null;
    final points = coordsList
        .map((e) {
          final list = e as List<dynamic>;
          if (list.length < 2) return null;
          final lng = (list[0] is num) ? (list[0] as num).toDouble() : null;
          final lat = (list[1] is num) ? (list[1] as num).toDouble() : null;
          if (lat == null || lng == null) return null;
          return LatLng(lat, lng);
        })
        .whereType<LatLng>()
        .toList();
    return OSRMRouteResult(
      points: points,
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
    );
  } catch (_) {
    return null;
  }
}

/// Index du segment le plus proche + distance restante (m) le long du trajet.
({int segmentIndex, double remainingMeters}) remainingFromPosition(
    List<LatLng> route, LatLng userPosition) {
  int best = 0;
  double bestDist = double.maxFinite;
  for (int i = 0; i < route.length; i++) {
    final d = _distance.as(LengthUnit.Meter, userPosition, route[i]);
    if (d < bestDist) {
      bestDist = d;
      best = i;
    }
  }
  double remaining = 0;
  for (int i = best; i < route.length - 1; i++) {
    remaining += _distance.as(LengthUnit.Meter, route[i], route[i + 1]);
  }
  return (segmentIndex: best, remainingMeters: remaining);
}
