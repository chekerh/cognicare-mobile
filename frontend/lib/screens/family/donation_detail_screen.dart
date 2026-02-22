import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../services/geocoding_service.dart';
import '../../utils/constants.dart';
import '../../widgets/location_map_widget.dart';

const Color _primary = Color(0xFFA3D9E2);
const Color _textDark = Color(0xFF111418);
const Color _textMuted = Color(0xFF64748B);
const Color _bgLight = Color(0xFFF0F7FF);

/// Page détail d'une annonce de don — design aligné sur le HTML fourni.
class DonationDetailScreen extends StatefulWidget {
  const DonationDetailScreen({super.key, this.title, this.description, this.fullDescription, this.conditionIndex = 0, this.categoryIndex = 0, this.imageUrl = '', this.location = '', this.distanceText, this.donorId, this.donorName, this.donorAvatarUrl, this.donorRating, this.latitude, this.longitude, this.suitableAge});

  final String? title;
  final String? description;
  final String? fullDescription;
  final int conditionIndex;
  final int categoryIndex;
  final String imageUrl;
  final String location;
  final String? distanceText;
  final String? donorId;
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
      donorId: e['donorId'] as String?,
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
  bool _loadingMap = false;

  @override
  void initState() {
    super.initState();
    _initMapCoords();
  }

  Future<void> _initMapCoords() async {
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
  }

  Future<void> _openInGoogleMaps() async {
    if (_mapLat != null && _mapLng != null) {
      final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$_mapLat,$_mapLng',
      );
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } else if (widget.location.trim().isNotEmpty) {
      final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(widget.location)}',
      );
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final conditionLabels = [loc.veryGoodCondition, loc.donationGoodCondition, loc.donationLikeNew];
    final conditionColors = [Colors.green, Colors.amber, Colors.green];
    final categoryLabels = [loc.donationAll, loc.donationMobility, loc.donationEarlyLearning, loc.donationClothing];
    final displayDescription = (widget.fullDescription ?? widget.description ?? '').trim().isNotEmpty ? (widget.fullDescription ?? widget.description)! : (widget.description ?? '');
    final donor = widget.donorName ?? loc.donationDefaultDonor;
    final avatarUrl = widget.donorAvatarUrl;

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
                          categoryLabel: widget.categoryIndex >= 0 && widget.categoryIndex < categoryLabels.length ? categoryLabels[widget.categoryIndex] : loc.donationClothing,
                          donorName: donor,
                          donorAvatarUrl: avatarUrl,
                          location: widget.location,
                          suitableAge: widget.suitableAge,
                          mapLat: _mapLat,
                          mapLng: _mapLng,
                          loadingMap: _loadingMap,
                          onMapTap: _openInGoogleMaps,
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

  void _shareDonation(AppLocalizations loc) {
    final donor = widget.donorName ?? loc.donationDefaultDonor;
    final t = widget.title ?? '';
    final shareText = '$t — $donor\n${widget.location}\n\n${loc.donationShareFooter}';
    Share.share(shareText, subject: t.isNotEmpty ? t : loc.donationShareFallbackTitle);
  }

  Widget _buildHeader(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
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
                onPressed: () => _shareDonation(AppLocalizations.of(context)!),
                icon: const Icon(Icons.share, color: _primary),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.report_outlined, color: _primary),
                tooltip: loc.reportLabel,
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
    String? suitableAge,
    double? mapLat,
    double? mapLng,
    bool loadingMap = false,
    VoidCallback? onMapTap,
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
                      Text(loc.loadingMapLabel, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ),
            )
          else if (mapLat != null && mapLng != null)
            _buildTappableMap(
              child: LocationMapWidget(
                latitude: mapLat,
                longitude: mapLng,
                height: 160,
                borderRadius: BorderRadius.circular(16),
              ),
              onTap: onMapTap,
            )
          else
            _buildTappableMap(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 160,
                  color: Colors.grey.shade100,
                  child: Center(
                    child: Icon(Icons.map_outlined, size: 48, color: Colors.grey.shade400),
                  ),
                ),
              ),
              onTap: onMapTap,
            ),
        ],
      ),
    );
  }

  Widget _buildTappableMap({required Widget child, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          child,
          if (onTap != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.directions, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    AppLocalizations.of(context)!.viewItineraryGoogleMaps,
                    style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                ],
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
            if (widget.donorId != null && widget.donorId!.isNotEmpty) {
              context.push(
                Uri(
                  path: AppConstants.familyPrivateChatRoute,
                  queryParameters: {
                    'personId': widget.donorId!,
                    'personName': widget.donorName ?? loc.donationDefaultDonor,
                    if (widget.donorAvatarUrl != null) 'personImageUrl': widget.donorAvatarUrl!,
                  },
                ).toString(),
              );
            } else {
              context.push(AppConstants.familyDonationChatRoute, extra: {
                'donorName': widget.donorName ?? loc.donationDefaultDonor,
                'donationTitle': widget.title ?? '',
                'donorAvatarUrl': widget.donorAvatarUrl,
                'donationImageUrl': widget.imageUrl,
              });
            }
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
