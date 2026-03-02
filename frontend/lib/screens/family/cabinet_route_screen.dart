import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/healthcare_cabinet.dart';
import '../../services/osrm_service.dart';

const Color _mapPrimary = Color(0xFFA3D9E2);
const Color _slate800 = Color(0xFF1E293B);
const Color _slate500 = Color(0xFF64748B);

/// Écran itinéraire entièrement dans l'app : carte + position + trajet (OSRM), temps/distance restants mis à jour en temps réel.
class CabinetRouteScreen extends StatefulWidget {
  const CabinetRouteScreen({
    super.key,
    required this.cabinet,
  });

  final HealthcareCabinet cabinet;

  @override
  State<CabinetRouteScreen> createState() => _CabinetRouteScreenState();
}

class _CabinetRouteScreenState extends State<CabinetRouteScreen> {
  Position? _userPosition;
  List<LatLng>? _routePoints;
  double _totalDistanceMeters = 0;
  double _totalDurationSeconds = 0;
  double _remainingMeters = 0;
  double _remainingMinutes = 0;
  bool _loading = true;
  String? _error;
  TravelMode _travelMode = TravelMode.car;
  bool _navigationActive = false;
  bool _isApproximateRoute = false; // true si trajet ligne directe (OSRM a échoué)
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionSubscription;

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  void _startPositionStream() {
    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      if (!mounted || _routePoints == null || _routePoints!.isEmpty) return;
      final user = LatLng(position.latitude, position.longitude);
      final result = remainingFromPosition(_routePoints!, user);
      final remainingM = result.remainingMeters;
      double remainingSec = 0;
      if (_totalDistanceMeters > 0 && _totalDurationSeconds > 0) {
        remainingSec = (remainingM / _totalDistanceMeters) * _totalDurationSeconds;
      }
      if (mounted) {
        setState(() {
          _userPosition = position;
          _remainingMeters = remainingM;
          _remainingMinutes = remainingSec / 60;
        });
        if (_navigationActive) {
          _mapController.move(user, _mapController.camera.zoom);
        }
      }
    });
  }

  bool get _cabinetHasValidCoords =>
      widget.cabinet.latitude != 0 || widget.cabinet.longitude != 0;

  Future<void> _openInGoogleMaps() async {
    final dest = _cabinetHasValidCoords
        ? '${widget.cabinet.latitude},${widget.cabinet.longitude}'
        : Uri.encodeComponent(
            '${widget.cabinet.address}, ${widget.cabinet.city}'.trim());
    final origin = _userPosition != null
        ? '&origin=${_userPosition!.latitude},${_userPosition!.longitude}'
        : '';
    final url = _cabinetHasValidCoords
        ? 'https://www.google.com/maps/dir/?api=1${origin}&destination=$dest'
        : 'https://www.google.com/maps/search/?api=1&query=$dest';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _loadRoute() async {
    setState(() {
      _loading = true;
      _error = null;
      _userPosition = null;
      _routePoints = null;
      _totalDistanceMeters = 0;
      _totalDurationSeconds = 0;
      _remainingMeters = 0;
      _remainingMinutes = 0;
    });

    try {
      _isApproximateRoute = false;
      if (!_cabinetHasValidCoords) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error =
              'Coordonnées du cabinet non renseignées. Utilisez « Ouvrir dans Google Maps » pour obtenir un itinéraire.';
        });
        return;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = 'Activez la localisation pour voir l\'itinéraire.';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = 'Autorisez l\'accès à la position pour afficher l\'itinéraire.';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      if (!mounted) return;
      setState(() => _userPosition = position);

      final result = await getRoute(
        startLat: position.latitude,
        startLng: position.longitude,
        endLat: widget.cabinet.latitude,
        endLng: widget.cabinet.longitude,
        travelMode: _travelMode,
      );

      if (!mounted) return;

      OSRMRouteResult routeResult;
      if (result == null || result.points.isEmpty) {
        routeResult = getStraightLineRoute(
          startLat: position.latitude,
          startLng: position.longitude,
          endLat: widget.cabinet.latitude,
          endLng: widget.cabinet.longitude,
          travelMode: _travelMode,
        );
      } else {
        routeResult = result;
      }

      final remaining = remainingFromPosition(
          routeResult.points, LatLng(position.latitude, position.longitude));
      setState(() {
        _routePoints = routeResult.points;
        _totalDistanceMeters = routeResult.distanceMeters;
        _totalDurationSeconds = routeResult.durationSeconds;
        _remainingMeters = remaining.remainingMeters;
        _remainingMinutes = routeResult.distanceMeters > 0
            ? (remaining.remainingMeters / routeResult.distanceMeters) *
                (routeResult.durationSeconds / 60)
            : 0;
        _loading = false;
        _isApproximateRoute = (result == null || result.points.isEmpty);
      });

      _startPositionStream();

      final destPoint = LatLng(widget.cabinet.latitude, widget.cabinet.longitude);
      final distanceKm = routeResult.distanceMeters / 1000;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (distanceKm > 300) {
          // Trajet très long (ex. utilisateur à l'étranger) : centrer sur la Tunisie / l'emplacement exact du cabinet
          _mapController.move(destPoint, 12);
        } else {
          final allPoints = routeResult.points +
              [
                LatLng(position.latitude, position.longitude),
                destPoint,
              ];
          final bounds = LatLngBounds.fromPoints(allPoints);
          _mapController.fitCamera(CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(48),
          ));
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  static String _formatRemainingTime(double minutes) {
    if (minutes < 1) return '< 1 min';
    if (minutes < 60) return '${minutes.round()} min';
    final h = (minutes / 60).floor();
    final m = (minutes % 60).round();
    if (m == 0) return '${h}h';
    return '${h}h ${m}min';
  }

  static String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  static String _formatArrival(double remainingMinutes) {
    final now = DateTime.now();
    final arrival = now.add(Duration(minutes: remainingMinutes.round()));
    final h = arrival.hour;
    final m = arrival.minute;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  /// Points de la polyline à afficher : du point le plus proche de l'utilisateur jusqu'à la destination (trajet restant).
  List<LatLng> _remainingPolylinePoints() {
    final route = _routePoints!;
    if (_userPosition == null) return route;
    final user = LatLng(_userPosition!.latitude, _userPosition!.longitude);
    final result = remainingFromPosition(route, user);
    if (result.segmentIndex >= route.length) return route;
    return route.sublist(result.segmentIndex);
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final dest = LatLng(widget.cabinet.latitude, widget.cabinet.longitude);
    final start = _userPosition != null
        ? LatLng(_userPosition!.latitude, _userPosition!.longitude)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Itinéraire — ${widget.cabinet.name}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: _mapPrimary,
        foregroundColor: _slate800,
        actions: [
          if (!_loading && _error == null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadRoute,
              tooltip: 'Recalculer',
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 15),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _loadRoute,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _mapPrimary,
                          ),
                          child: const Text('Réessayer'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _openInGoogleMaps,
                          icon: const Icon(Icons.map, size: 20),
                          label: const Text('Ouvrir dans Google Maps'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _slate800,
                            side: const BorderSide(color: _mapPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: start ?? dest,
                        initialZoom: 14,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.pinchZoom |
                              InteractiveFlag.drag |
                              InteractiveFlag.doubleTapZoom,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.cognicare.app',
                        ),
                        if (_routePoints != null && _routePoints!.isNotEmpty) ...[
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: _remainingPolylinePoints(),
                                strokeWidth: 5,
                                color: _mapPrimary,
                              ),
                            ],
                          ),
                        ],
                        MarkerLayer(
                          markers: [
                            if (start != null)
                              Marker(
                                point: start,
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.person_pin_circle,
                                  color: Colors.blue,
                                  size: 40,
                                ),
                              ),
                            Marker(
                              point: dest,
                              width: 44,
                              height: 44,
                              child: const Icon(
                                Icons.medical_services_rounded,
                                color: _mapPrimary,
                                size: 44,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16 + MediaQuery.paddingOf(context).bottom,
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_isApproximateRoute)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              'Itinéraire approximatif (ligne directe)',
                              style: TextStyle(
                                fontSize: 12,
                                color: _slate500,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        if (_totalDistanceMeters > 0 && _totalDurationSeconds > 0) ...[
                                Row(
                                  children: [
                                    const Icon(Icons.schedule, size: 18, color: _slate500),
                                    const SizedBox(width: 6),
                                    Text(
                                      _formatRemainingTime(_remainingMinutes),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: _slate800,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      _formatDistance(_remainingMeters),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: _slate500,
                                      ),
                                    ),
                                  ],
                                ),
                                if (_remainingMinutes > 0) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Arrivée à ${_formatArrival(_remainingMinutes)}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: _slate500,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                              ],
                              // Sélecteur de mode : Voiture / À pied (comme Maps)
                              Row(
                                children: [
                                  _TravelModeChip(
                                    icon: Icons.directions_car,
                                    label: 'Voiture',
                                    duration: _travelMode == TravelMode.car && _totalDurationSeconds > 0
                                        ? _formatRemainingTime(_totalDurationSeconds / 60)
                                        : '—',
                                    selected: _travelMode == TravelMode.car,
                                    onTap: () {
                                      if (_travelMode == TravelMode.car) return;
                                      setState(() => _travelMode = TravelMode.car);
                                      _loadRoute();
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  _TravelModeChip(
                                    icon: Icons.directions_walk,
                                    label: 'À pied',
                                    duration: _travelMode == TravelMode.walking && _totalDurationSeconds > 0
                                        ? _formatRemainingTime(_totalDurationSeconds / 60)
                                        : '—',
                                    selected: _travelMode == TravelMode.walking,
                                    onTap: () {
                                      if (_travelMode == TravelMode.walking) return;
                                      setState(() => _travelMode = TravelMode.walking);
                                      _loadRoute();
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                widget.cabinet.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: _slate800,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (widget.cabinet.address.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  widget.cabinet.address,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: _slate500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              if (widget.cabinet.city.isNotEmpty)
                                Text(
                                  widget.cabinet.city,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: _slate500,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              const SizedBox(height: 16),
                              // Bouton Démarrer / Arrêter (comme Maps)
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: () {
                                    setState(() => _navigationActive = !_navigationActive);
                                    if (_navigationActive && _userPosition != null) {
                                      _mapController.move(
                                        LatLng(_userPosition!.latitude, _userPosition!.longitude),
                                        _mapController.camera.zoom,
                                      );
                                    }
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _navigationActive
                                        ? _slate500
                                        : const Color(0xFF22C55E),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  icon: Icon(
                                    _navigationActive ? Icons.stop_rounded : Icons.play_arrow_rounded,
                                    size: 22,
                                  ),
                                  label: Text(
                                    _navigationActive ? 'Arrêter la navigation' : 'Démarrer',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

/// Chip pour le mode de déplacement (Voiture / À pied).
class _TravelModeChip extends StatelessWidget {
  const _TravelModeChip({
    required this.icon,
    required this.label,
    required this.duration,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String duration;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _mapPrimary.withOpacity(0.4) : Colors.grey.shade200,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? _slate800 : _slate500,
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? _slate800 : _slate500,
                    ),
                  ),
                  Text(
                    duration,
                    style: TextStyle(
                      fontSize: 11,
                      color: selected ? _slate800 : _slate500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
