import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/donation.dart';
import '../../services/donation_service.dart';
import '../../utils/constants.dart';

// Design aligné sur le HTML Stitch - Donations Community Hub
const Color _primary = Color(0xFFa3dae1);
const Color _background = Color(0xFFF5F9FA);
const Color _cardBg = Color(0xFFFFFFFF);
const Color _textPrimary = Color(0xFF1E293B);
const Color _textSecondary = Color(0xFF64748B);
const Color _textSlate400 = Color(0xFF94A3B8);
const Color _borderSlate = Color(0xFFF8FAFC);

String _fullImageUrl(String path) {
  if (path.isEmpty) return '';
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  final base = AppConstants.baseUrl.endsWith('/')
      ? AppConstants.baseUrl.substring(0, AppConstants.baseUrl.length - 1)
      : AppConstants.baseUrl;
  return path.startsWith('/') ? '$base$path' : '$base/$path';
}

/// Labels des catégories (Tout = pas de filtre).
const List<String> _categoryLabels = [
  'Tout',
  'Vêtements',
  'Mobilier',
  'Éveil',
  'Médical',
];

/// List of donations for volunteers — design Stitch: header wave, search, filters, single-column cards.
/// Si [showHeader] est false, seul le contenu est affiché (pour intégration dans la section Communauté).
class VolunteerDonationsListScreen extends StatefulWidget {
  const VolunteerDonationsListScreen({super.key, this.showHeader = true});

  final bool showHeader;

  @override
  State<VolunteerDonationsListScreen> createState() =>
      _VolunteerDonationsListScreenState();
}

class _VolunteerDonationsListScreenState
    extends State<VolunteerDonationsListScreen> {
  final DonationService _donationService = DonationService();
  List<Donation>? _donations;
  bool _loading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  int _selectedCategoryIndex = 0; // 0 = Tout

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _donationService.getDonations();
      if (mounted) {
        setState(() => _donations = list
          ..sort((a, b) => (b.createdAt).compareTo(a.createdAt)));
      }
    } catch (e) {
      if (mounted) {
        setState(
            () => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Donation> get _filteredDonations {
    if (_donations == null) return [];
    var list = _donations!;
    if (_selectedCategoryIndex > 0) {
      list = list
          .where((d) => d.category == _selectedCategoryIndex - 1)
          .toList();
    }
    final q = _searchController.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((d) =>
              d.title.toLowerCase().contains(q) ||
              d.description.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  static const _conditionMap = {0: 2, 1: 0, 2: 1};

  void _openDetail(Donation d) {
    final conditionDisplayIndex = _conditionMap[d.condition] ?? d.condition;
    final imageUrl = _fullImageUrl(d.imageUrl);
    context.push(AppConstants.volunteerDonationDetailRoute, extra: {
      'title': d.title,
      'description': d.description,
      'fullDescription': d.fullDescription ?? d.description,
      'conditionIndex': conditionDisplayIndex,
      'categoryIndex': d.category,
      'imageUrl': imageUrl,
      'location': d.location,
      'distanceText': null,
      'donorName': d.donorName,
      'donorAvatarUrl': d.donorProfilePic != null
          ? _fullImageUrl(d.donorProfilePic!)
          : null,
      'donorId': d.donorId,
      'donationId': d.id,
      'latitude': d.latitude,
      'longitude': d.longitude,
      'suitableAge': d.suitableAge,
    });
  }

  Widget _buildBodyContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _primary));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _load,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }
    if (_donations == null || _donations!.isEmpty) {
      return Center(
        child: Text(
          'Aucun don pour le moment.',
          style: TextStyle(fontSize: 15, color: _textSecondary),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: _primary,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildSearchAndFilters()),
          SliverToBoxAdapter(child: _buildCategoryChips()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            sliver: _filteredDonations.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 48),
                      child: Center(
                        child: Text(
                          'Aucun don ne correspond.',
                          style: TextStyle(
                              fontSize: 15, color: _textSecondary),
                        ),
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildListDelegate(
                      _filteredDonations
                          .map((d) => _donationCard(d))
                          .toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showHeader = widget.showHeader;
    final content = _buildBodyContent();
    return Scaffold(
      backgroundColor: _background,
      body: showHeader
          ? Column(
              children: [
                _buildHeaderWave(context),
                Expanded(child: content),
              ],
            )
          : SizedBox.expand(child: content),
    );
  }

  Widget _buildHeaderWave(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 24,
        right: 24,
        bottom: 24,
      ),
      decoration: BoxDecoration(
        color: _primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.elliptical(400, 40),
          bottomRight: Radius.elliptical(400, 40),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.psychology_rounded,
                      color: _primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'CogniCare',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade400,
                        border: Border.all(color: _primary, width: 1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSegmentTabs(context),
        ],
      ),
    );
  }

  Widget _buildSegmentTabs(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () =>
                    context.go(AppConstants.volunteerCommunityFeedRoute),
                borderRadius: BorderRadius.circular(999),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'Community',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Text(
                'Donations',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
            ),
          ),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () =>
                    context.push(AppConstants.volunteerCommunityMarketRoute),
                borderRadius: BorderRadius.circular(999),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      'Marketplace',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.search, size: 22, color: _textSlate400),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Rechercher un don...',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _textSlate400,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            Material(
              color: _primary,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () {
                  // TODO: ouvrir filtre avancé si besoin
                },
                borderRadius: BorderRadius.circular(16),
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(
                    Icons.tune_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: List.generate(_categoryLabels.length, (i) {
          final selected = i == _selectedCategoryIndex;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: selected ? _primary : _cardBg,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                onTap: () =>
                    setState(() => _selectedCategoryIndex = i),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: selected
                        ? null
                        : Border.all(color: _borderSlate),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                  ),
                  child: Text(
                    _categoryLabels[i],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: selected ? Colors.white : _textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _donationCard(Donation d) {
    final imageUrl = _fullImageUrl(d.imageUrl);
    final donorInitials = _donorInitials(d.donorName);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: _cardBg),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openDetail(d),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 256,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (imageUrl.isNotEmpty)
                        Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imagePlaceholder(),
                        )
                      else
                        _imagePlaceholder(),
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_on,
                                  size: 16, color: _primary),
                              const SizedBox(width: 6),
                              Text(
                                _shortLocation(d.location),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _textPrimary,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        d.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: _textSecondary,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.only(top: 16),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: _borderSlate),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: _primary.withOpacity(0.2)),
                              ),
                              child: Center(
                                child: Text(
                                  donorInitials,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'DONATEUR',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: _textSlate400,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  Text(
                                    d.donorName,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Material(
                              color: _primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(999),
                              child: InkWell(
                                onTap: () => _openDetail(d),
                                borderRadius: BorderRadius.circular(999),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  child: Text(
                                    'Contacter',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _primary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _donorInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].length >= 2
          ? parts[0].substring(0, 2).toUpperCase()
          : parts[0].toUpperCase();
    }
    return ((parts[0].isNotEmpty ? parts[0][0] : '') +
            (parts[1].isNotEmpty ? parts[1][0] : ''))
        .toUpperCase();
  }

  String _shortLocation(String location) {
    if (location.length <= 20) return location;
    final parts = location.split(',').map((e) => e.trim()).toList();
    if (parts.isEmpty) return location;
    if (parts.length >= 2) return '${parts[0]}, ${parts[1]}';
    return parts[0];
  }

  Widget _imagePlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: _primary.withOpacity(0.12),
      child: Center(
        child: Icon(
          Icons.favorite_border,
          size: 48,
          color: _primary.withOpacity(0.5),
        ),
      ),
    );
  }
}
