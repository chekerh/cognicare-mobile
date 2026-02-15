import 'dart:math' show cos, sin, sqrt, asin;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../l10n/app_localizations.dart';
import '../../services/geocoding_service.dart';
import '../../utils/constants.dart';
import '../../widgets/location_map_widget.dart';

const Color _primary = Color(0xFFA3D9E2);
const Color _textDark = Color(0xFF111418);
const Color _textMuted = Color(0xFF64748B);
const Color _bgLight = Color(0xFFF0F7FF);

/// Distance en mètres entre deux points (formule de Haversine).
double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const p = 0.017453292519943295; // pi/180
  final a = 0.5 -
      cos((lat2 - lat1) * p) / 2 +
      cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
  return 12742 * asin(sqrt(a)); // 2 * R = 12742 km
}

/// Page détail d'une annonce de don — design aligné sur le HTML fourni.
class DonationDetailScreen extends StatefulWidget {
  const DonationDetailScreen({super.key, this.title, this.description, this.fullDescription, this.conditionIndex = 0, this.categoryIndex = 0, this.imageUrl = '', this.location = '', this.distanceText, this.donorName, this.donorAvatarUrl, this.donorRating, this.latitude, this.longitude, this.suitableAge});

  final String? title;
  final String? description;
  final String? fullDescription;
  final int conditionIndex;
  final int categoryIndex;
  final String imageUrl;
  final String location;
  final String? distanceText;
  final String? donorName;
  final String? donorAvatarUrl;
  final double? donorRating;
  final double? latitude;
  final double? longitude;
  final String? suitableAge;

  static Map<String, dynamic> _extraFromState(GoRouterState state) {
    final extra = state.extra as Map<String, dynamic>?;
    return extra ?? {};
  }

  factory DonationDetailScreen.fromState(GoRouterState state) {
    final e = _extraFromState(state);
    return DonationDetailScreen(
      title: e['title'] as String?,
      description: e['description'] as String?,
      fullDescription: e['fullDescription'] as String?,
      conditionIndex: e['conditionIndex'] as int? ?? 0,
      categoryIndex: e['categoryIndex'] as int? ?? 0,
      imageUrl: e['imageUrl'] as String? ?? '',
      location: e['location'] as String? ?? '',
      distanceText: e['distanceText'] as String?,
      donorName: e['donorName'] as String?,
      donorAvatarUrl: e['donorAvatarUrl'] as String?,
      donorRating: (e['donorRating'] as num?)?.toDouble(),
      latitude: (e['latitude'] as num?)?.toDouble(),
      longitude: (e['longitude'] as num?)?.toDouble(),
      suitableAge: e['suitableAge'] as String?,
    );
  }

  @override
  State<DonationDetailScreen> createState() => _DonationDetailScreenState();
}

class _DonationDetailScreenState extends State<DonationDetailScreen> {
  double? _mapLat;
  double? _mapLng;
  String? _computedDistanceText;
  bool _loadingMap = false;

  @override
  void initState() {
    super.initState();
    _initMapAndDistance();
  }

  Future<void> _initMapAndDistance() async {
    double? lat = widget.latitude;
    double? lng = widget.longitude;
    if (lat == null || lng == null) {
      if (widget.location.trim().isEmpty) {
        if (mounted) setState(() {});
        return;
      }
      setState(() => _loadingMap = true);
      final result = await GeocodingService().geocode(widget.location);
      if (!mounted) return;
      setState(() => _loadingMap = false);
      if (result != null) {
        lat = result.latitude;
        lng = result.longitude;
      }
    }
    if (!mounted) return;
    setState(() {
      _mapLat = lat;
      _mapLng = lng;
    });
    if (lat != null && lng != null) {
      _computeDistance(lat, lng);
    }
  }

  Future<void> _computeDistance(double donationLat, double donationLng) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(timeLimit: Duration(seconds: 8)),
      ).timeout(const Duration(seconds: 10));
      final km = _haversineKm(pos.latitude, pos.longitude, donationLat, donationLng);
      String text;
      if (km < 1) {
        text = '${(km * 1000).round()} m';
      } else if (km < 10) {
        text = '${km.toStringAsFixed(1)} km';
      } else {
        text = '${km.round()} km';
      }
      if (mounted) setState(() => _computedDistanceText = text);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final conditionLabels = [loc.veryGoodCondition, loc.goodCondition, loc.likeNew];
    final conditionColors = [Colors.green, Colors.amber, Colors.green];
    final categoryLabels = [loc.all, loc.mobility, loc.earlyLearning, loc.clothing];
    final displayDescription = (widget.fullDescription ?? widget.description ?? '').trim().isNotEmpty ? (widget.fullDescription ?? widget.description)! : (widget.description ?? '');
    final donor = widget.donorName ?? 'Donateur';
    final avatarUrl = widget.donorAvatarUrl;
    final distance = _computedDistanceText ?? widget.distanceText;

    return Scaffold(
      backgroundColor: _bgLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildImage(context, widget.imageUrl),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                      child: Transform.translate(
                        offset: const Offset(0, -40),
                        child: _buildCard(
                          context,
                          loc: loc,
                          title: widget.title ?? '',
                          description: displayDescription,
                          conditionLabel: conditionLabels[widget.conditionIndex.clamp(0, 2)],
                          conditionColor: conditionColors[widget.conditionIndex.clamp(0, 2)],
                          categoryLabel: widget.categoryIndex >= 0 && widget.categoryIndex < categoryLabels.length ? categoryLabels[widget.categoryIndex] : loc.clothing,
                          donorName: donor,
                          donorAvatarUrl: avatarUrl,
                          location: widget.location,
                          distanceText: distance,
                          showDistance: distance != null,
                          suitableAge: widget.suitableAge,
                          mapLat: _mapLat,
                          mapLng: _mapLng,
                          loadingMap: _loadingMap,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildBottomButton(context, loc),
          ],
        ),
      ),
    );
  }

  void _shareDonation() {
    final donor = widget.donorName ?? 'Donateur';
    final t = widget.title ?? '';
    final shareText = '$t — $donor\n${widget.location}\n\n— CogniCare Le Cercle du Don';
    Share.share(shareText, subject: t.isNotEmpty ? t : 'Annonce de don');
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Material(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              onTap: () => context.pop(),
              borderRadius: BorderRadius.circular(999),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(Icons.arrow_back_ios_new, color: _primary, size: 20),
              ),
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: _shareDonation,
                icon: const Icon(Icons.share, color: _primary),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.report_outlined, color: _primary),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImage(BuildContext context, String url) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.45,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey.shade300,
              child: const Icon(Icons.image_not_supported, size: 64),
            ),
          ),
          Positioned(
            bottom: 24,
            right: 24,
            child: Material(
              elevation: 8,
              shape: const CircleBorder(),
              color: Colors.white,
              child: InkWell(
                onTap: () {},
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Icon(Icons.favorite, color: Colors.red, size: 28),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required AppLocalizations loc,
    required String title,
    required String description,
    required String conditionLabel,
    required Color conditionColor,
    required String categoryLabel,
    required String donorName,
    required String? donorAvatarUrl,
    required String location,
    String? distanceText,
    bool showDistance = true,
    String? suitableAge,
    double? mapLat,
    double? mapLng,
    bool loadingMap = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.12),
            blurRadius: 40,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: conditionColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  conditionLabel.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: conditionColor.withOpacity(0.9),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  categoryLabel.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _primary,
                  ),
                ),
              ),
              if (suitableAge != null && suitableAge.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.child_care, color: _primary, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        suitableAge,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: _textMuted,
            ),
          ),
          const SizedBox(height: 24),
          Divider(height: 1, color: Colors.grey.shade200),
          const SizedBox(height: 24),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: donorAvatarUrl != null && donorAvatarUrl.isNotEmpty
                    ? NetworkImage(donorAvatarUrl)
                    : null,
                onBackgroundImageError: (_, __) {},
                child: donorAvatarUrl == null || donorAvatarUrl.isEmpty
                    ? Text(
                        donorName.isNotEmpty ? donorName[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _primary),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.donatedBy,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      donorName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: _primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        location,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _textDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (showDistance && distanceText != null && distanceText.isNotEmpty)
                Text(
                  'À $distanceText ${loc.distanceFromYou}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (loadingMap)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 160,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2, color: _primary)),
                      const SizedBox(height: 8),
                      Text('Chargement de la carte...', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ),
            )
          else if (mapLat != null && mapLng != null)
            LocationMapWidget(
              latitude: mapLat,
              longitude: mapLng,
              height: 160,
              borderRadius: BorderRadius.circular(16),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 160,
                color: Colors.grey.shade100,
                child: Center(
                  child: Icon(Icons.map_outlined, size: 48, color: Colors.grey.shade400),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context, AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_bgLight.withOpacity(0), _bgLight],
        ),
      ),
      child: Material(
        elevation: 8,
        shadowColor: _primary.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        color: _primary,
        child: InkWell(
          onTap: () {
            context.push(AppConstants.familyDonationChatRoute, extra: {
              'donorName': widget.donorName ?? 'Donateur',
              'donationTitle': widget.title ?? '',
              'donorAvatarUrl': widget.donorAvatarUrl,
              'donationImageUrl': widget.imageUrl,
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(
                  loc.contactDonor,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
