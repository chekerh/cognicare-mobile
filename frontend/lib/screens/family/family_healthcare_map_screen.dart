import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../models/healthcare_cabinet.dart';
import '../../services/healthcare_cabinets_service.dart';
import '../../utils/constants.dart';

/// Centre approximatif de la Tunisie (carte Glovo-style).
const LatLng _tunisiaCenter = LatLng(34.0, 10.0);
const double _tunisiaZoom = 6.5;

const Color _mapPrimary = Color(0xFFA3D9E2);
const Color _slate800 = Color(0xFF1E293B);
const Color _slate500 = Color(0xFF64748B);

/// Carte des cabinets et centres de santé en Tunisie (hors app) — orthophonistes, pédopsychiatres, centres autisme, etc.
class FamilyHealthcareMapScreen extends StatefulWidget {
  const FamilyHealthcareMapScreen({super.key});

  @override
  State<FamilyHealthcareMapScreen> createState() =>
      _FamilyHealthcareMapScreenState();
}

class _FamilyHealthcareMapScreenState extends State<FamilyHealthcareMapScreen> {
  List<HealthcareCabinet>? _cabinets;
  bool _loading = true;
  String? _error;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await HealthcareCabinetsService().getCabinets();
      if (!mounted) return;
      setState(() {
        _cabinets = list;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cabinets = null;
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final bottomPadding = MediaQuery.paddingOf(context).bottom + 24;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _load,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    final list = _cabinets ?? [];
    final markers = <Marker>[];
    for (final c in list) {
      final point = LatLng(c.latitude, c.longitude);
      markers.add(
        Marker(
          point: point,
          width: 48,
          height: 48,
          child: GestureDetector(
            onTap: () => _showCabinetSheet(context, c, loc),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(color: _mapPrimary, width: 2),
              ),
              child: const Icon(
                Icons.medical_services_rounded,
                color: _mapPrimary,
                size: 26,
              ),
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _tunisiaCenter,
            initialZoom: _tunisiaZoom,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.pinchZoom |
                  InteractiveFlag.drag |
                  InteractiveFlag.doubleTapZoom,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.cognicare.app',
            ),
            MarkerLayer(markers: markers),
          ],
        ),
        if (list.isEmpty)
          Positioned(
            left: 24,
            right: 24,
            bottom: bottomPadding + 80,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Aucun cabinet enregistré pour le moment.',
                  style: TextStyle(fontSize: 14, color: _slate500),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
        else
          Positioned(
            left: 16,
            right: 16,
            bottom: bottomPadding + 16,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: _mapPrimary, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${list.length} cabinet(s) et centre(s) en Tunisie',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _slate800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showCabinetSheet(
    BuildContext context,
    HealthcareCabinet cabinet,
    AppLocalizations loc,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(
            24, 20, 24, 24 + MediaQuery.paddingOf(ctx).bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _mapPrimary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.medical_services_rounded,
                    color: _mapPrimary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cabinet.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: _slate800,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cabinet.specialty,
                        style: const TextStyle(
                          fontSize: 14,
                          color: _mapPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (cabinet.address.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 16, color: _slate500),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                cabinet.address,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: _slate500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (cabinet.city.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 22, top: 2),
                          child: Text(
                            cabinet.city,
                            style: const TextStyle(
                              fontSize: 12,
                              color: _slate500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      context.push(AppConstants.familyCabinetRouteRoute,
                          extra: {'cabinet': cabinet});
                    },
                    icon: const Icon(Icons.directions, size: 18),
                    label: Text(loc.viewItineraryLabel),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _mapPrimary,
                      foregroundColor: _slate800,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                if (cabinet.phone != null && cabinet.phone!.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        final uri = Uri.parse('tel:${cabinet.phone}');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                      icon: const Icon(Icons.phone, size: 18),
                      label: const Text('Appeler'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _slate800,
                        side: const BorderSide(color: _slate500),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
