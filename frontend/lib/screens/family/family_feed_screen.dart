import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/community_feed_provider.dart';
import '../../models/donation.dart';
import '../../models/marketplace_product.dart';
import '../../models/user.dart' as app_user;
import '../../services/donation_service.dart';
import '../../services/geocoding_service.dart';
import '../../services/healthcare_service.dart';
import '../../services/integrations_service.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import 'family_healthcare_map_screen.dart';

// Couleurs du design HTML Family Community Feed
const Color _feedPrimary = Color(0xFFA3D9E2);
const Color _feedSecondary = Color(0xFF7FBAC4);
const Color _feedBackground = Color(0xFFF8FAFC);

// Couleurs Le Cercle du Don — alignées sur volunteer_community (Stitch)
const Color _donationPrimary = Color(0xFFA3D9E2);
const Color _donationCardBg = Color(0xFFFFFFFF);
const Color _donationTextPrimary = Color(0xFF1E293B);
const Color _donationTextSecondary = Color(0xFF64748B);
const Color _donationTextSlate400 = Color(0xFF94A3B8);
const Color _donationBorderSlate = Color(0xFFF8FAFC);

/// Construit l'URL complète pour une image (backend ou Cloudinary).
/// - Déjà absolue (http/https) → retournée telle quelle.
/// - Commence par / → baseUrl + path.
/// - Sinon (ex. uploads/...) → baseUrl + / + path.
String _fullImageUrl(String path) {
  if (path.isEmpty) return '';
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  final base = AppConstants.baseUrl.endsWith('/')
      ? AppConstants.baseUrl.substring(0, AppConstants.baseUrl.length - 1)
      : AppConstants.baseUrl;
  return path.startsWith('/') ? '$base$path' : '$base/$path';
}

/// Family Community Feed — aligné sur le design HTML fourni.
/// Header blanc (psychology + CogniCare), onglets Community/Marketplace/Experts,
/// carte Family Chat, partage, fil de posts, section From Marketplace.
class FamilyFeedScreen extends StatefulWidget {
  const FamilyFeedScreen({super.key});

  @override
  State<FamilyFeedScreen> createState() => _FamilyFeedScreenState();
}

class _FamilyFeedScreenState extends State<FamilyFeedScreen> {
  int _selectedTab = 0; // 0: Community, 1: Donations, 2: Map
  int _donationsCategoryIndex =
      0; // 0: Tout, 1: Mobilité, 2: Jouets, 3: Vêtements
  late final Future<List<MarketplaceProduct>> _marketplaceProductsFuture;
  final TextEditingController _donationSearchController =
      TextEditingController();
  final FocusNode _donationSearchFocusNode = FocusNode();
  String _donationSearchQuery = '';
  Timer? _donationSearchDebounce;

  List<app_user.User>? _healthcareUsers;
  bool _healthcareLoading = false;
  String? _healthcareError;
  String _healthcareSearchQuery = '';

  List<Donation>? _donations;
  bool _donationsLoading = false;
  String? _donationsError;

  @override
  void initState() {
    super.initState();
    _marketplaceProductsFuture = _loadIntegrationProductsForFeed();
    _loadDonations();
  }

  /// Charge les produits du catalogue intégré (BioHerbs) pour la section marketplace de l'accueil.
  Future<List<MarketplaceProduct>> _loadIntegrationProductsForFeed() async {
    try {
      final websites = await IntegrationsService().getWebsites();
      if (websites.isEmpty) return [];
      final slug = websites.first.slug;
      final catalog = await IntegrationsService().getCatalog(slug, page: 1);
      final list = catalog.products.take(6).map((p) {
        final imageUrl = p.imageUrls.isNotEmpty ? p.imageUrls.first : '';
        return MarketplaceProduct(
          id: p.externalId,
          title: p.name,
          price: p.price,
          imageUrl: imageUrl,
          description: p.availability ? 'En stock' : 'Rupture de stock',
          category: p.category,
          externalUrl: p.productUrl,
        );
      }).toList();
      return list;
    } catch (_) {
      return [];
    }
  }

  void _onDonationSearchChanged(String value) {
    setState(() => _donationSearchQuery = value);
    _donationSearchDebounce?.cancel();
    _donationSearchDebounce = Timer(const Duration(milliseconds: 450), () {
      _loadDonations();
    });
  }

  Future<void> _loadDonations() async {
    setState(() {
      _donationsLoading = true;
      _donationsError = null;
    });
    try {
      const isOffer = true; // Afficher les dons (offres)
      final category =
          _donationsCategoryIndex > 0 ? _donationsCategoryIndex : null;
      final search = _donationSearchQuery.trim().isNotEmpty
          ? _donationSearchQuery.trim()
          : null;
      final list = await DonationService().getDonations(
        isOffer: isOffer,
        category: category,
        search: search,
      );
      if (!mounted) return;
      setState(() {
        _donations = list;
        _donationsLoading = false;
        _donationsError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _donations = null;
        _donationsLoading = false;
        _donationsError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _loadHealthcareUsers() async {
    setState(() {
      _healthcareLoading = true;
      _healthcareError = null;
    });
    try {
      final list = await HealthcareService().getHealthcareProfessionals();
      if (!mounted) return;
      setState(() {
        _healthcareUsers = list;
        _healthcareLoading = false;
        _healthcareError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _healthcareUsers = null;
        _healthcareLoading = false;
        _healthcareError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  void dispose() {
    _donationSearchDebounce?.cancel();
    _donationSearchController.dispose();
    _donationSearchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Barre de statut en bleu (icônes claires) — header tout en bleu
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
    final bottomPadding = MediaQuery.paddingOf(context).bottom + 88;
    return Scaffold(
      backgroundColor: _feedBackground,
      body: Consumer<CommunityFeedProvider>(
        builder: (context, feedProvider, _) {
          if (!feedProvider.isLoaded) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              feedProvider.loadFromStorage();
            });
          }
          return Column(
            children: [
              _buildHeaderWave(),
              Expanded(
                child: _selectedTab == 0
                    ? _buildCommunityScrollContent(
                        context, feedProvider, bottomPadding)
                    : _selectedTab == 1
                        ? _buildDonationsContent(bottomPadding)
                        : FamilyHealthcareMapScreen(),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Header type première screenshot : carte bleue arrondie, logo, CogniCare, cloche (badge orange), onglets en pill.
  Widget _buildHeaderWave() {
    final loc = AppLocalizations.of(context)!;
    final padding = MediaQuery.paddingOf(context);
    return Container(
      padding: EdgeInsets.only(
        top: padding.top + 12,
        left: 24,
        right: 24,
        bottom: 24,
      ),
      decoration: BoxDecoration(
        color: _feedPrimary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.elliptical(400, 28),
          bottomRight: Radius.elliptical(400, 28),
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
                      color: Colors.white,
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
                      color: _feedPrimary,
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
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () =>
                          context.push(AppConstants.familyNotificationsRoute),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
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
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade400,
                        border: Border.all(color: _feedPrimary, width: 2),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildHeaderSegmentTabs(loc),
        ],
      ),
    );
  }

  Widget _buildHeaderSegmentTabs(AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          _headerTab(loc.community, 0),
          _headerTab(loc.donations, 1),
          _headerTab(loc.mapTab, 2),
        ],
      ),
    );
  }

  Widget _headerTab(String label, int index) {
    final selected = _selectedTab == index;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedTab = index),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                color: selected ? _donationTextPrimary : Colors.white70,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Contenu scrollable de l’onglet Community (header + tab bar restent fixes).
  Widget _buildCommunityScrollContent(
    BuildContext context,
    CommunityFeedProvider feedProvider,
    double bottomPadding,
  ) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildShareCard()),
        if (feedProvider.posts.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.article_outlined,
                      size: 56,
                      color: _feedPrimary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.noPostsYet,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.text.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.tapToShare,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.text.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildListDelegate(
              _buildFeedPostsFromProvider(context, feedProvider),
            ),
          ),
        SliverToBoxAdapter(child: _buildFromMarketplaceSection()),
        SliverToBoxAdapter(child: SizedBox(height: bottomPadding)),
      ],
    );
  }

  /// Contenu onglet Donations — Le Cercle du Don (design aligné volunteer_community).
  Widget _buildDonationsContent(double bottomPadding) {
    final loc = AppLocalizations.of(context)!;
    final padding = MediaQuery.paddingOf(context);
    const horizontalPadding = 24.0;
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _loadDonations,
          color: _donationPrimary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              horizontalPadding + padding.left,
              16,
              horizontalPadding + padding.right,
              bottomPadding + 72,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                _buildDonationSearchBar(),
                const SizedBox(height: 16),
                _buildDonationCategoryChips(loc),
                const SizedBox(height: 24),
                ..._buildDonationCards(loc),
                SizedBox(height: bottomPadding),
              ],
            ),
          ),
        ),
        // FAB "Proposer un don" — aligné volunteer (padding 24)
        Positioned(
          right: 24 + padding.right,
          bottom: padding.bottom + 100,
          child: Tooltip(
            message: loc.proposeDonation,
            child: Material(
              elevation: 8,
              shadowColor: _donationPrimary.withOpacity(0.3),
              shape: const CircleBorder(),
              color: _donationPrimary,
              child: InkWell(
                onTap: () async {
                  await context.push(AppConstants.familyProposeDonationRoute);
                  if (!mounted) return;
                  _loadDonations();
                },
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  width: 56,
                  height: 56,
                  child: Icon(Icons.add, color: Colors.white, size: 28),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Chips de catégories — style volunteer (pill, ombre, bordure).
  Widget _buildDonationCategoryChips(AppLocalizations loc) {
    final labels = [loc.all, loc.mobility, loc.earlyLearning, loc.clothing];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = _donationsCategoryIndex == i;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: selected ? _donationPrimary : _donationCardBg,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                onTap: () {
                  setState(() => _donationsCategoryIndex = i);
                  _loadDonations();
                },
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: selected
                        ? null
                        : Border.all(color: _donationBorderSlate),
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
                    labels[i],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: selected
                          ? Colors.white
                          : _donationTextSecondary,
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

  /// Barre de recherche — style volunteer (container arrondi, icône filtre).
  Widget _buildDonationSearchBar() {
    final loc = AppLocalizations.of(context)!;
    return Container(
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
          Icon(Icons.search, size: 22, color: _donationTextSlate400),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _donationSearchController,
              focusNode: _donationSearchFocusNode,
              onChanged: _onDonationSearchChanged,
              onSubmitted: (_) => _loadDonations(),
              decoration: InputDecoration(
                hintText: loc.searchDonationsHint,
                hintStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _donationTextSlate400,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                suffixIcon: _donationSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          size: 20,
                          color: _donationTextSlate400,
                        ),
                        onPressed: () {
                          _donationSearchController.clear();
                          setState(() => _donationSearchQuery = '');
                          _loadDonations();
                        },
                      )
                    : null,
              ),
            ),
          ),
          Material(
            color: _donationPrimary,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () {},
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
    );
  }

  /// Catégories dons : 0 Tout, 1 Mobilité, 2 Jouets, 3 Vêtements
  static const int _catAll = 0;

  List<Widget> _buildDonationCards(AppLocalizations loc) {
    if (_donationsLoading) {
      return [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (_donationsError != null) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                _donationsError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red.shade700, fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _loadDonations,
                icon: const Icon(Icons.refresh),
                label: Text(AppLocalizations.of(context)!.retry),
              ),
            ],
          ),
        ),
      ];
    }
    final list = _donations ?? [];
    if (list.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.inventory_2_outlined,
                    size: 56, color: _donationPrimary.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(
                  loc.noDonationsYet,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      ];
    }
    const conditionMap = {0: 2, 1: 0, 2: 1};
    final isFrench = loc.localeName.startsWith('fr');
    final currentUserId =
        Provider.of<AuthProvider>(context, listen: false).user?.id ?? '';
    final isMyDonation = (String id) =>
        currentUserId.isNotEmpty && id.trim() == currentUserId.trim();
    return list.map((d) {
      final conditionDisplayIndex = conditionMap[d.condition] ?? d.condition;
      final imageUrl = _fullImageUrl(d.imageUrl);
      final displayLocation = isFrench ? locationToFrench(d.location) : d.location;
      final myDonation = isMyDonation(d.donorId);
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: _donationCard(
          title: d.title,
          description: d.description,
          fullDescription: d.fullDescription ?? d.description,
          conditionIndex: conditionDisplayIndex,
          categoryIndex: d.category,
          location: displayLocation,
          distanceText: null,
          imageUrl: imageUrl,
          isOffer: d.isOffer,
          loc: loc,
          donorName: d.donorName,
          isMyDonation: myDonation,
          donationId: d.id,
          onDeleteTap: myDonation
              ? () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(loc.deleteLabel),
                      content: Text(
                        AppLocalizations.of(context)!.deleteDonationConfirm,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: Text(loc.cancel),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: Text(loc.deleteLabel),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && mounted) {
                    try {
                      await DonationService().deleteDonation(d.id);
                      if (mounted) {
                        _loadDonations();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                AppLocalizations.of(context)!
                                    .donationDeletedSuccess),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e is Exception
                                ? e.toString().replaceFirst('Exception: ', '')
                                : 'Erreur'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                }
              : null,
          onDetailsTap: () {
            context.push(AppConstants.familyDonationDetailRoute, extra: {
              'title': d.title,
              'description': d.description,
              'fullDescription': d.fullDescription ?? d.description,
              'conditionIndex': conditionDisplayIndex,
              'categoryIndex': d.category,
              'imageUrl': imageUrl,
              'location': displayLocation,
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
          },
        ),
      );
    }).toList();
  }

  static String _donationShortLocation(String location) {
    if (location.length <= 20) return location;
    final parts = location.split(',').map((e) => e.trim()).toList();
    if (parts.isEmpty) return location;
    if (parts.length >= 2) return '${parts[0]}, ${parts[1]}';
    return parts[0];
  }

  static String _donationDonorInitials(String name) {
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

  Widget _donationCard({
    required String title,
    required String description,
    String? fullDescription,
    required int conditionIndex,
    required int categoryIndex,
    required String location,
    String? distanceText,
    required String imageUrl,
    required bool isOffer,
    required AppLocalizations loc,
    String? donorName,
    VoidCallback? onDetailsTap,
    bool isMyDonation = false,
    String? donationId,
    VoidCallback? onDeleteTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _donationCardBg,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: _donationCardBg),
        boxShadow: [
          BoxShadow(
            color: _donationPrimary.withOpacity(0.2),
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
            onTap: onDetailsTap,
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
                          errorBuilder: (_, __, ___) => _donationImagePlaceholder(),
                        )
                      else
                        _donationImagePlaceholder(),
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
                                  size: 16, color: _donationPrimary),
                              const SizedBox(width: 6),
                              Text(
                                _donationShortLocation(location),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _donationTextPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                          top: 16,
                          right: 16,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (onDeleteTap != null) ...[
                                Material(
                                  color: Colors.white.withOpacity(0.9),
                                  shape: const CircleBorder(),
                                  elevation: 1,
                                  child: InkWell(
                                    onTap: onDeleteTap,
                                    customBorder: const CircleBorder(),
                                    child: const Padding(
                                      padding: EdgeInsets.all(8),
                                      child: Icon(Icons.delete_outline,
                                          color: Colors.red, size: 20),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Material(
                                color: Colors.white.withOpacity(0.9),
                                shape: const CircleBorder(),
                                elevation: 1,
                                child: InkWell(
                                  onTap: () {},
                                  customBorder: const CircleBorder(),
                                  child: const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Icon(Icons.favorite,
                                        color: _donationPrimary, size: 20),
                                  ),
                                ),
                              ),
                            ],
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
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _donationTextPrimary,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: _donationTextSecondary,
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
                            top: BorderSide(color: _donationBorderSlate),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _donationPrimary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: _donationPrimary.withOpacity(0.2)),
                              ),
                              child: Center(
                                child: Text(
                                  _donationDonorInitials(donorName ?? ''),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _donationPrimary,
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
                                      color: _donationTextSlate400,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  Text(
                                    donorName ?? '—',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _donationTextPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Material(
                              color: _donationPrimary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(999),
                              child: InkWell(
                                onTap: onDetailsTap,
                                borderRadius: BorderRadius.circular(999),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  child: Text(
                                    loc.details,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _donationPrimary,
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

  Widget _donationImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: _donationPrimary.withOpacity(0.12),
      child: Center(
        child: Icon(
          Icons.favorite_border,
          size: 48,
          color: _donationPrimary.withOpacity(0.5),
        ),
      ),
    );
  }

  /// Contenu onglet Healthcare — vrais professionnels (API), recherche, filtres, Message → chat.
  Widget _buildHealthcareContent(double bottomPadding) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHealthcareSearchBar(),
          const SizedBox(height: 16),
          _buildHealthcareFilterChips(),
          const SizedBox(height: 16),
          if (_healthcareLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_healthcareError != null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _healthcareError!,
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 14, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _loadHealthcareUsers,
                      child: Text(AppLocalizations.of(context)!.retry),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._buildHealthcareCards(),
          SizedBox(height: bottomPadding),
        ],
      ),
    );
  }

  Widget _buildHealthcareSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) =>
            setState(() => _healthcareSearchQuery = value.trim()),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.searchProfessionalHint,
          hintStyle: TextStyle(
            color: AppTheme.text.withOpacity(0.5),
            fontSize: 14,
          ),
          prefixIcon: Icon(Icons.search,
              color: AppTheme.text.withOpacity(0.4), size: 22),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  int _healthcareFilterIndex = 0;

  Widget _buildHealthcareFilterChips() {
    final loc = AppLocalizations.of(context)!;
    final labels = [
      loc.filterAll,
      loc.filterSpeechTherapists,
      loc.filterChildPsychiatrists,
      loc.filterOccupationalTherapists,
    ];
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        itemBuilder: (context, index) {
          final selected = _healthcareFilterIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: selected ? Colors.white : Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                onTap: () => setState(() => _healthcareFilterIndex = index),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: selected
                          ? Colors.white
                          : Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    labels[index],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? _feedSecondary : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static String _roleToSpecializationLabel(AppLocalizations loc, String role) {
    switch (role) {
      case 'doctor':
        return loc.doctor;
      case 'psychologist':
        return loc.psychologist;
      case 'speech_therapist':
        return loc.speechTherapist;
      case 'occupational_therapist':
        return loc.occupationalTherapist;
      default:
        return role;
    }
  }

  List<Widget> _buildHealthcareCards() {
    final list = _healthcareUsers ?? [];
    List<app_user.User> filtered = list;
    if (_healthcareFilterIndex == 1) {
      filtered = list.where((u) => u.role == 'speech_therapist').toList();
    } else if (_healthcareFilterIndex == 2) {
      filtered = list
          .where((u) => u.role == 'psychologist' || u.role == 'doctor')
          .toList();
    } else if (_healthcareFilterIndex == 3) {
      filtered = list.where((u) => u.role == 'occupational_therapist').toList();
    }
    final loc = AppLocalizations.of(context)!;
    if (_healthcareSearchQuery.isNotEmpty) {
      final q = _healthcareSearchQuery.toLowerCase();
      filtered = filtered
          .where((u) =>
              u.fullName.toLowerCase().contains(q) ||
              _roleToSpecializationLabel(loc, u.role).toLowerCase().contains(q))
          .toList();
    }
    if (filtered.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              loc.noProfessionalsYet,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ];
    }
    return filtered.map((user) {
      final imageUrl = (user.profilePic != null && user.profilePic!.isNotEmpty)
          ? _fullImageUrl(user.profilePic!)
          : '';
      final userId = user.id;
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _ExpertCard(
          name: user.fullName,
          specialization: _roleToSpecializationLabel(loc, user.role),
          location: 'CogniCare',
          imageUrl: imageUrl,
          primaryColor: _feedSecondary,
          onBookConsultation: () {
            context.push(AppConstants.familyExpertBookingRoute, extra: {
              'expertId': userId,
              'name': user.fullName,
              'specialization': _roleToSpecializationLabel(loc, user.role),
              'location': 'CogniCare',
              'imageUrl': imageUrl,
            });
          },
          onMessage: () {
            context.push(
              Uri(
                path: AppConstants.familyPrivateChatRoute,
                queryParameters: {
                  'id': userId,
                  'name': user.fullName,
                  if (imageUrl.isNotEmpty) 'imageUrl': imageUrl,
                },
              ).toString(),
            );
          },
        ),
      );
    }).toList();
  }

  Widget _buildShareCard() {
    final user = Provider.of<AuthProvider>(context).user;
    final profilePicUrl = user != null && user.profilePic != null && user.profilePic!.isNotEmpty
        ? _fullImageUrl(user.profilePic!)
        : null;
    final initial = (user?.fullName ?? 'U').substring(0, 1).toUpperCase();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push(AppConstants.familyCreatePostRoute),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildShareCardAvatar(profilePicUrl: profilePicUrl, initial: initial),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: _feedBackground,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.shareExperiencePlaceholder,
                      style: TextStyle(
                        color: AppTheme.text.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.add_photo_alternate,
                    color: _feedPrimary, size: 26),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShareCardAvatar({String? profilePicUrl, required String initial}) {
    const radius = 20.0;
    if (profilePicUrl != null && profilePicUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          profilePicUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => CircleAvatar(
            radius: radius,
            backgroundColor: _feedPrimary.withOpacity(0.3),
            child: Text(
              initial,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.text,
                fontSize: 18,
              ),
            ),
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: _feedPrimary.withOpacity(0.3),
      child: Text(
        initial,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppTheme.text,
          fontSize: 18,
        ),
      ),
    );
  }

  static const List<(Color, String)> _tagColors = [
    (Color(0xFF3B82F6), 'blue'),
    (Color(0xFF9333EA), 'purple'),
    (Color(0xFF0D9488), 'teal'),
    (Color(0xFFEA580C), 'orange'),
  ];

  List<Widget> _buildFeedPostsFromProvider(
    BuildContext context,
    CommunityFeedProvider feedProvider,
  ) {
    // listen: true pour que le menu Modifier/Supprimer s'affiche une fois l'utilisateur chargé
    final authProvider = Provider.of<AuthProvider>(context, listen: true);
    return feedProvider.posts.map((post) {
      final tagStyles = post.tags.asMap().entries.map((e) {
        final c = _tagColors[e.key % _tagColors.length];
        return (c.$1, e.value);
      }).toList();
      final comments = feedProvider.getComments(post.id);
      final commentCount = feedProvider.getCommentCount(post.id);
      final lastComment = comments.isNotEmpty
          ? '${comments.first.authorName}: ${comments.first.text}'
          : null;
      final currentUserId = authProvider.user?.id.toString().trim() ?? '';
      final postAuthorId = post.authorId.toString().trim();
      final sameName =
          (authProvider.user?.fullName ?? '').trim().toLowerCase() ==
              post.authorName.trim().toLowerCase();
      // canDelete: même id, ou même nom si les ids ne matchent pas (ex. posts créés sur téléphone)
      final canDelete = currentUserId.isNotEmpty &&
          (currentUserId == postAuthorId ||
              (sameName && postAuthorId.isNotEmpty));
      return _buildPost(
        postId: post.id,
        name: post.authorName,
        authorProfilePicUrl: post.authorProfilePic != null && post.authorProfilePic!.isNotEmpty
            ? _fullImageUrl(post.authorProfilePic!)
            : null,
        time: post.timeAgo,
        text: post.text,
        tagStyles: tagStyles,
        likes: feedProvider.getLikeCount(post.id),
        comments: commentCount,
        liked: feedProvider.isLiked(post.id),
        hasImage: post.hasImage,
        imagePath: post.imagePath,
        lastComment: lastComment,
        onAuthorTap: () {
          final imageUrl = post.authorProfilePic != null &&
                  post.authorProfilePic!.isNotEmpty
              ? _fullImageUrl(post.authorProfilePic!)
              : null;
          context.push(AppConstants.familyCommunityMemberProfileRoute, extra: {
            'memberId': post.authorId,
            'memberName': post.authorName,
            'memberImageUrl': imageUrl,
          });
        },
        onLikeTap: () => feedProvider.toggleLike(post.id),
        onCommentTap: () async {
          await feedProvider.loadCommentsForPost(post.id);
          if (context.mounted) {
            _showCommentsSheet(context, post.id, feedProvider, authProvider);
          }
        },
        onShareTap: () {
          final base = AppConstants.baseUrl.endsWith('/')
              ? AppConstants.baseUrl.substring(
                  0, AppConstants.baseUrl.length - 1)
              : AppConstants.baseUrl;
          final profileLink =
              '$base${AppConstants.familyCommunityMemberProfileRoute}?memberId=${Uri.encodeComponent(post.authorId)}&memberName=${Uri.encodeComponent(post.authorName)}';
          final shareText =
              '${post.authorName}: ${post.text}\n\n'
              'Voir le profil de ${post.authorName} sur CogniCare : $profileLink\n\n'
              '— CogniCare Communauté';
          Share.share(shareText, subject: 'Publication CogniCare');
        },
        canDelete: canDelete,
        onEditTap: canDelete
            ? () =>
                _showEditPostDialog(context, post.id, post.text, feedProvider)
            : null,
        onDeleteTap: canDelete
            ? () async {
                final loc = AppLocalizations.of(context)!;
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(loc.deletePost),
                    content: Text(loc.deletePostConfirm),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: Text(loc.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style:
                            TextButton.styleFrom(foregroundColor: Colors.red),
                        child: Text(loc.delete),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  try {
                    await feedProvider.deletePost(post.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(loc.postDeleted),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e is Exception
                              ? e.toString().replaceFirst('Exception: ', '')
                              : loc.errorLoadingProfile),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              }
            : null,
      );
    }).toList();
  }

  void _showEditPostDialog(
    BuildContext context,
    String postId,
    String initialText,
    CommunityFeedProvider feedProvider,
  ) {
    final loc = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: initialText);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.editPostTitle),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: loc.shareExperiencePlaceholder,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(loc.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final newText = controller.text.trim();
              if (newText.isEmpty) return;
              Navigator.of(ctx).pop();
              try {
                await feedProvider.updatePost(postId, newText);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(loc.postUpdated),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(loc.errorLoadingProfile),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(loc.save),
          ),
        ],
      ),
    );
  }

  void _showCommentsSheet(
    BuildContext context,
    String postId,
    CommunityFeedProvider feedProvider,
    AuthProvider authProvider,
  ) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom +
              MediaQuery.paddingOf(sheetContext).bottom,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.comments,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.text,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(sheetContext).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: feedProvider.getComments(postId).length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, i) {
                    final c = feedProvider.getComments(postId)[i];
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: _feedPrimary.withOpacity(0.4),
                        child: Text(
                          c.authorName.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.text,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      title: Text(
                        c.authorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppTheme.text,
                        ),
                      ),
                      subtitle: Text(
                        c.text,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.text.withOpacity(0.85),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: _feedPrimary.withOpacity(0.3),
                      child: Text(
                        (authProvider.user?.fullName ?? 'U')
                            .substring(0, 1)
                            .toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.text,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.writeComment,
                          hintStyle: TextStyle(
                            color: AppTheme.text.withOpacity(0.5),
                            fontSize: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                                color: AppTheme.text.withOpacity(0.2)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        onSubmitted: (text) {
                          if (text.trim().isEmpty) return;
                          feedProvider.addComment(
                            postId,
                            authProvider.user?.fullName ?? 'Anonymous',
                            text,
                          );
                          controller.clear();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send, color: _feedPrimary),
                      onPressed: () {
                        final text = controller.text.trim();
                        if (text.isEmpty) return;
                        feedProvider.addComment(
                          postId,
                          authProvider.user?.fullName ?? 'Anonymous',
                          text,
                        );
                        controller.clear();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPost({
    required String postId,
    required String name,
    String? authorProfilePicUrl,
    required String time,
    required String text,
    required List<(Color, String)> tagStyles,
    required int likes,
    required int comments,
    required bool liked,
    required VoidCallback onLikeTap,
    required VoidCallback onCommentTap,
    VoidCallback? onShareTap,
    VoidCallback? onAuthorTap,
    bool canDelete = false,
    VoidCallback? onEditTap,
    VoidCallback? onDeleteTap,
    bool hasImage = false,
    String? imagePath,
    String? lastComment,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppTheme.text.withOpacity(0.06)),
          bottom: BorderSide(color: AppTheme.text.withOpacity(0.06)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onAuthorTap,
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      children: [
                        _buildPostAuthorAvatar(
                          authorProfilePicUrl: authorProfilePicUrl,
                          name: name,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.text,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                time,
                                style: TextStyle(
                                  color: AppTheme.text.withOpacity(0.5),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_horiz,
                    color: AppTheme.text.withOpacity(0.5),
                    size: 22,
                  ),
                  onSelected: (value) {
                    if (value == 'edit' && onEditTap != null) {
                      onEditTap();
                    } else if (value == 'delete' && onDeleteTap != null) {
                      onDeleteTap();
                    }
                    // 'info' = fermer le menu (pas d'action)
                  },
                  itemBuilder: (context) => [
                    if (onEditTap != null)
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit_outlined,
                                color: AppTheme.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(AppLocalizations.of(context)!.editPost),
                          ],
                        ),
                      ),
                    if (onDeleteTap != null)
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(AppLocalizations.of(context)!.deletePost),
                          ],
                        ),
                      ),
                    if (onEditTap == null && onDeleteTap == null)
                      const PopupMenuItem<String>(
                        value: 'info',
                        child: Text(
                            'Vous ne pouvez modifier que vos propres publications'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    color: AppTheme.text,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: tagStyles.map((e) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: e.$1.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        e.$2,
                        style: TextStyle(
                          color: e.$1,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          if (hasImage)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imagePath != null
                    ? (imagePath.startsWith('http') ||
                            imagePath.startsWith('/uploads/')
                        ? Image.network(
                            imagePath.startsWith('http')
                                ? imagePath
                                : _fullImageUrl(imagePath),
                            width: double.infinity,
                            height: 256,
                            fit: BoxFit.cover,
                            cacheWidth: 800,
                            cacheHeight: 512,
                            loadingBuilder: (_, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 256,
                                color: _feedPrimary.withOpacity(0.15),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    color: _feedSecondary,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) => Container(
                              height: 256,
                              color: _feedPrimary.withOpacity(0.2),
                              child: Icon(
                                Icons.broken_image_outlined,
                                size: 72,
                                color: _feedPrimary.withOpacity(0.6),
                              ),
                            ),
                          )
                        : Image.file(
                            File(imagePath),
                            width: double.infinity,
                            height: 256,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 256,
                              color: _feedPrimary.withOpacity(0.2),
                              child: Icon(
                                Icons.broken_image_outlined,
                                size: 72,
                                color: _feedPrimary.withOpacity(0.6),
                              ),
                            ),
                          ))
                    : Container(
                        height: 256,
                        decoration: BoxDecoration(
                          color: _feedPrimary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.child_care,
                            size: 72,
                            color: _feedPrimary.withOpacity(0.6),
                          ),
                        ),
                      ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                InkWell(
                  onTap: onLikeTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          liked ? Icons.favorite : Icons.favorite_border,
                          size: 22,
                          color: liked
                              ? Colors.red
                              : AppTheme.text.withOpacity(0.5),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$likes',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: liked
                                ? Colors.red
                                : AppTheme.text.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                InkWell(
                  onTap: onCommentTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 22,
                          color: AppTheme.text.withOpacity(0.5),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$comments',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.text.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: onShareTap ?? () {},
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Icon(Icons.share_outlined,
                        size: 22, color: AppTheme.text.withOpacity(0.5)),
                  ),
                ),
              ],
            ),
          ),
          if (lastComment != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _feedBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: _feedSecondary.withOpacity(0.3),
                      child: const Text(
                        'S',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.text,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        lastComment,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.text.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPostAuthorAvatar({String? authorProfilePicUrl, required String name}) {
    const radius = 20.0;
    final initial = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
    if (authorProfilePicUrl != null && authorProfilePicUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          authorProfilePicUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => CircleAvatar(
            radius: radius,
            backgroundColor: _feedPrimary.withOpacity(0.4),
            child: Text(
              initial,
              style: const TextStyle(
                color: AppTheme.text,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: _feedPrimary.withOpacity(0.4),
      child: Text(
        initial,
        style: const TextStyle(
          color: AppTheme.text,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildFromMarketplaceSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppTheme.text.withOpacity(0.06)),
          bottom: BorderSide(color: AppTheme.text.withOpacity(0.06)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.fromMarketplace,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.text.withOpacity(0.6),
                  letterSpacing: 1.5,
                ),
              ),
              InkWell(
                onTap: () => context.go(AppConstants.familyMarketRoute),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  child: Text(
                    AppLocalizations.of(context)!.viewAll,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _feedPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 128,
            child: FutureBuilder<List<MarketplaceProduct>>(
              future: _marketplaceProductsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView(
                    scrollDirection: Axis.horizontal,
                    children:
                        List.generate(3, (_) => _marketplaceCardPlaceholder()),
                  );
                }
                final products = snapshot.data ?? [];
                if (snapshot.hasError || products.isEmpty) {
                  return _marketplaceEmptyState(context);
                }
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return _marketplaceProductCard(products[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// État vide : plus de mock, uniquement les données de l'API.
  Widget _marketplaceEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_bag_outlined,
                size: 40, color: AppTheme.text.withOpacity(0.3)),
            const SizedBox(height: 8),
            Text(
              'Aucun produit pour le moment',
              style: TextStyle(
                  fontSize: 13, color: AppTheme.text.withOpacity(0.6)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go(AppConstants.familyMarketRoute),
              child: Text(
                AppLocalizations.of(context)!.viewAll,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _marketplaceCardPlaceholder() {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 82,
            decoration: BoxDecoration(
              color: _feedPrimary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(Icons.shopping_bag_outlined,
                  size: 32, color: _feedPrimary),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '...',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.text,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          const Text(
            '\$0.00',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _feedSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  static Color _marketplaceBadgeColor(String? badge) {
    if (badge == null || badge.isEmpty) return const Color(0xFFADD8E6);
    final b = badge.toUpperCase();
    if (b.contains('TOP')) return const Color(0xFF212121);
    if (b.contains('SKILL') || b.contains('BUILDER')) return Colors.green;
    if (b.contains('POPULAR')) return Colors.orange;
    return const Color(0xFFADD8E6);
  }

  Widget _marketplaceProductCard(MarketplaceProduct product) {
    return InkWell(
      onTap: () {
        context.push(
          AppConstants.familyProductDetailRoute,
          extra: {
            'productId': product.id,
            'title': product.title,
            'price': product.price,
            'imageUrl': product.imageUrl,
            'description': product.description,
            'badge': product.badge,
            'badgeColorValue': _marketplaceBadgeColor(product.badge).value,
            'externalUrl': product.externalUrl,
          },
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 82,
              decoration: BoxDecoration(
                color: _feedPrimary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: product.imageUrl.isNotEmpty
                  ? Image.network(
                      product.imageUrl,
                      width: double.infinity,
                      height: 82,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: Icon(Icons.shopping_bag_outlined,
                              size: 32, color: _feedPrimary),
                        );
                      },
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.shopping_bag_outlined,
                            size: 32, color: _feedPrimary),
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.shopping_bag_outlined,
                          size: 32, color: _feedPrimary),
                    ),
            ),
            const SizedBox(height: 6),
            Text(
              product.title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.text,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              product.price,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: _feedSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte expert — photo de profil si présente, sinon initiale ; nom, badge Verified, spécialisation, lieu, Book Consultation / Message.
class _ExpertCard extends StatelessWidget {
  const _ExpertCard({
    required this.name,
    required this.specialization,
    required this.location,
    required this.imageUrl,
    required this.primaryColor,
    required this.onBookConsultation,
    required this.onMessage,
  });

  final String name;
  final String specialization;
  final String location;

  /// URL de la photo de profil (vide = afficher l'initiale du nom).
  final String imageUrl;
  final Color primaryColor;
  final VoidCallback onBookConsultation;
  final VoidCallback onMessage;

  Widget _buildProfileImage() {
    const size = 80.0;
    final initial = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
    final avatarPlaceholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFA3D9E2).withOpacity(0.25),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF7FBAC4),
          ),
        ),
      ),
    );
    if (imageUrl.isEmpty) return avatarPlaceholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            width: size,
            height: size,
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => avatarPlaceholder,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    const Color slate900 = Color(0xFF0F172A);
    const Color slate400 = Color(0xFF94A3B8);
    const Color verifiedAccent = Color(0xFF212121);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileImage(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: slate900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: verifiedAccent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified,
                                  size: 14, color: verifiedAccent),
                              const SizedBox(width: 4),
                              Text(
                                loc.verifiedLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: verifiedAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      specialization,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 14, color: slate400),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: const TextStyle(
                              fontSize: 12,
                              color: slate400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Material(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: onBookConsultation,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Center(
                        child: Text(
                          loc.bookConsultation,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Material(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: onMessage,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        loc.messageLabel,
                        style: const TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
