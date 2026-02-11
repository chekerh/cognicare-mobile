import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/community_feed_provider.dart';
import '../../models/marketplace_product.dart';
import '../../services/marketplace_service.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';

// Couleurs du design HTML Family Community Feed
const Color _feedPrimary = Color(0xFFA3D9E2);
const Color _feedSecondary = Color(0xFF7FBAC4);
const Color _feedBackground = Color(0xFFF8FAFC);

// Couleurs Le Cercle du Don
const Color _donationPrimary = Color(0xFFA3D9E2);

/// Construit l'URL complète pour une image du backend (ex. /uploads/posts/xxx.jpg).
String _fullImageUrl(String path) {
  final base = AppConstants.baseUrl.endsWith('/')
      ? AppConstants.baseUrl.substring(0, AppConstants.baseUrl.length - 1)
      : AppConstants.baseUrl;
  return path.startsWith('/') ? '$base$path' : path;
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
  int _selectedTab = 0; // 0: Community, 1: Donations, 2: Experts
  int _donationsToggleIndex = 0; // 0: Je donne, 1: Je recherche
  int _donationsCategoryIndex = 0; // 0: Tout, 1: Mobilité, 2: Éveil, 3: Vêtements
  late final Future<List<MarketplaceProduct>> _marketplaceProductsFuture;
  final TextEditingController _donationSearchController = TextEditingController();
  final FocusNode _donationSearchFocusNode = FocusNode();
  String _donationSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _marketplaceProductsFuture = MarketplaceService().getProducts(limit: 6);
  }

  @override
  void dispose() {
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
              _buildHeaderWidget(),
              _buildTabs(),
              Expanded(
                child: _selectedTab == 0
                    ? _buildCommunityScrollContent(context, feedProvider, bottomPadding)
                    : _selectedTab == 1
                        ? _buildDonationsContent(bottomPadding)
                        : _buildExpertsContent(bottomPadding),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Header fixe (CogniCare + search + notifications) — même design que le HTML.
  Widget _buildHeaderWidget() {
    final padding = MediaQuery.paddingOf(context);
    final horizontal = (padding.horizontal + 16).clamp(16.0, 24.0);
    return Container(
      color: _feedPrimary,
      padding: EdgeInsets.fromLTRB(horizontal, padding.top + 12, horizontal, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.psychology, color: _feedPrimary, size: 22),
              ),
              const SizedBox(width: 8),
              const Text(
                'CogniCare',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _headerButton(Icons.notifications_outlined, onPressed: () => context.push(AppConstants.familyNotificationsRoute)),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.fromBorderSide(
                          BorderSide(color: _feedPrimary, width: 1),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerButton(IconData icon, {VoidCallback? onPressed}) {
    return IconButton(
      onPressed: onPressed ?? () {},
      icon: Icon(icon, color: Colors.white, size: 22),
      splashRadius: 22,
    );
  }

  Widget _buildTabs() {
    final loc = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: _feedPrimary,
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
      ),
      child: Row(
        children: [
          _tab(loc.community, 0),
          _tab(loc.donations, 1),
          _tab(loc.experts, 2),
        ],
      ),
    );
  }

  Widget _tab(String label, int index) {
    final selected = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white70,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              if (selected)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  height: 3,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
            ],
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
        SliverToBoxAdapter(child: _buildFamilyChatCard()),
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

  /// Contenu onglet Donations — Le Cercle du Don.
  Widget _buildDonationsContent(double bottomPadding) {
    final loc = AppLocalizations.of(context)!;
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Le Cercle du Don header (in-content)
              Row(
                children: [
                  const Icon(Icons.favorite, color: _donationPrimary, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    loc.leCercleDuDon,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111418),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Toggle Je donne / Je recherche
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _donationPrimary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _donationToggleSegment(loc.jeDonne, 0),
                    ),
                    Expanded(
                      child: _donationToggleSegment(loc.jeRecherche, 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Category chips
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _donationCategoryChip(loc.all, Icons.grid_view, 0),
                    const SizedBox(width: 8),
                    _donationCategoryChip(loc.mobility, Icons.accessibility_new, 1),
                    const SizedBox(width: 8),
                    _donationCategoryChip(loc.earlyLearning, Icons.toys, 2),
                    const SizedBox(width: 8),
                    _donationCategoryChip(loc.clothing, Icons.checkroom, 3),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildDonationSearchBar(),
              const SizedBox(height: 20),
              ..._buildDonationCards(loc),
              SizedBox(height: bottomPadding),
            ],
          ),
        ),
        // FAB "Proposer un don" — bouton rond à droite
        Positioned(
          right: 24,
          bottom: 100,
          child: Tooltip(
            message: loc.proposeDonation,
            child: Material(
              elevation: 8,
              shadowColor: _donationPrimary.withOpacity(0.3),
              shape: const CircleBorder(),
              color: _donationPrimary,
              child: InkWell(
                onTap: () => context.push(AppConstants.familyProposeDonationRoute),
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

  Widget _donationToggleSegment(String label, int index) {
    final selected = _donationsToggleIndex == index;
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      elevation: selected ? 2 : 0,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: () => setState(() => _donationsToggleIndex = index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected ? _donationPrimary : const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _donationCategoryChip(String label, IconData icon, int index) {
    final selected = _donationsCategoryIndex == index;
    return Material(
      color: selected ? _donationPrimary : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: () => setState(() => _donationsCategoryIndex = index),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? _donationPrimary : _donationPrimary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: selected ? Colors.white : _donationPrimary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: selected ? Colors.white : const Color(0xFF111418),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDonationSearchBar() {
    final loc = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _donationPrimary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _donationSearchController,
        focusNode: _donationSearchFocusNode,
        decoration: InputDecoration(
          hintText: loc.searchDonationsHint,
          hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: _donationPrimary.withOpacity(0.8), size: 22),
          suffixIcon: _donationSearchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, size: 20, color: Colors.grey.shade600),
                  onPressed: () {
                    _donationSearchController.clear();
                    setState(() => _donationSearchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: (value) => setState(() => _donationSearchQuery = value),
      ),
    );
  }

  /// Catégories dons : 0 Tout, 1 Mobilité, 2 Éveil, 3 Vêtements
  static const int _catAll = 0;
  /// Toggle : 0 = Je donne (offres), 1 = Je recherche (demandes)
  static const int _toggleGive = 0;

  List<Widget> _buildDonationCards(AppLocalizations loc) {
    const cardData = [
      (
        title: 'Vêtements sensoriels',
        description: 'Textiles adaptés sans coutures irritantes pour le confort sensoriel au quotidien.',
        fullDescription: 'Ensemble de 5 hauts en coton biologique, conçus spécifiquement pour les enfants avec hypersensibilité tactile. Sans étiquettes intérieures et avec des coutures plates inversées pour éviter toute irritation. Très utiles pour les enfants TSA ou avec des troubles de l\'intégration sensorielle.',
        condition: 0,
        location: 'Paris 15e, Javel',
        category: 3,
        isGive: true,
        imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBNwpJkxXJO4qPvJguyMJI8Jj88n_cMeQpmeJ63D72nrT2h90NZ859t1A8minaQ01kX1yk4QnB9teSjXGeEYzkpbKipI7RfPGJobNOAsBjk4fpKddk-MM9kz4yOhH3tRdsuJudTtF4QstUtzLwYJ_awa2QheQHTygqORQNQ4yMqHZ96GRkTLApID38iQL9fPZD5MsHqEE-mHsdzqe9iOiehayCPKYyG7HQ4lcIMHYlWestP5gwoWly2gRYLJd7XbXsEcIQUFCPoG6I',
        distanceText: '2.4 km',
      ),
      (
        title: 'Lit médicalisé',
        description: 'Lit avec réglages électriques et barrières de sécurité. Disponible immédiatement.',
        fullDescription: null,
        condition: 1,
        location: 'Lyon • 5km',
        category: 1,
        isGive: true,
        imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCb8SXYxcrQ4CgCujtTt7fyG-k61uPITDNwrJTWzYKq-U4ZY0bIdijFvRAiH_MPJTUX9gWaVwYoAVal5YaYgIbxmjyyZiPCh4GWFQquL3xQWz9ywGw2ywUWn1Fss4VAh3Rgtle-gVREM-fphtNAN8MEbcrgx60VPNtITY2D7_VjDGfo1gypD70ogxVDENtD3la2XEm7AsjpcfXvNwvQvUYgNeZ7PC-kDgKsPdufaXu5RAW06WxKn6TqGCatPdGlypP0chAws6irEm0',
        distanceText: null,
      ),
      (
        title: 'Kit d\'éveil Montessori',
        description: 'Ensemble de jeux en bois pour le développement de la motricité fine.',
        fullDescription: null,
        condition: 2,
        location: 'Bordeaux • 12km',
        category: 2,
        isGive: true,
        imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCxkZXpSV2sgwfy7eL_wAO1VsHV3zZ3O38eifySxi_30mTe2bbtkA_R3-okaq759yz1-H9z8NffBRyQeRPi52wJ7oDhkMdkBeg58wlnBcXv_cVyjCZ3VeTr16QDFESkDDeuEZTARH_dKSUn5tI39xeZgP_uwRuSgLl1YIaqVuubechX6zjuSmiyce8q7dDGcCHDUtpuZkwDhnysqYydnUck6NKWjiepuPqt3vVRuB6lNrfPHLoHr8n4vCyg1IbHEB8Vye4Pu3JN8TU',
        distanceText: null,
      ),
      (
        title: 'Déambulateur',
        description: 'Déambulateur réglable avec freins et panier. Idéal pour la mobilité au quotidien.',
        fullDescription: null,
        condition: 0,
        location: 'Marseille • 8km',
        category: 1,
        isGive: false,
        imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBNwpJkxXJO4qPvJguyMJI8Jj88n_cMeQpmeJ63D72nrT2h90NZ859t1A8minaQ01kX1yk4QnB9teSjXGeEYzkpbKipI7RfPGJobNOAsBjk4fpKddk-MM9kz4yOhH3tRdsuJudTtF4QstUtzLwYJ_awa2QheQHTygqORQNQ4yMqHZ96GRkTLApID38iQL9fPZD5MsHqEE-mHsdzqe9iOiehayCPKYyG7HQ4lcIMHYlWestP5gwoWly2gRYLJd7XbXsEcIQUFCPoG6I',
        distanceText: null,
      ),
      (
        title: 'Puzzle sensoriel',
        description: 'Puzzle en bois à encastrer pour l\'éveil et la motricité fine.',
        fullDescription: null,
        condition: 2,
        location: 'Toulouse • 15km',
        category: 2,
        isGive: false,
        imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCxkZXpSV2sgwfy7eL_wAO1VsHV3zZ3O38eifySxi_30mTe2bbtkA_R3-okaq759yz1-H9z8NffBRyQeRPi52wJ7oDhkMdkBeg58wlnBcXv_cVyjCZ3VeTr16QDFESkDDeuEZTARH_dKSUn5tI39xeZgP_uwRuSgLl1YIaqVuubechX6zjuSmiyce8q7dDGcCHDUtpuZkwDhnysqYydnUck6NKWjiepuPqt3vVRuB6lNrfPHLoHr8n4vCyg1IbHEB8Vye4Pu3JN8TU',
        distanceText: null,
      ),
      (
        title: 'Combinaison adaptée',
        description: 'Combinaison à pressions pour faciliter l\'habillage. Taille 2 ans.',
        fullDescription: null,
        condition: 1,
        location: 'Nantes • 10km',
        category: 3,
        isGive: false,
        imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBNwpJkxXJO4qPvJguyMJI8Jj88n_cMeQpmeJ63D72nrT2h90NZ859t1A8minaQ01kX1yk4QnB9teSjXGeEYzkpbKipI7RfPGJobNOAsBjk4fpKddk-MM9kz4yOhH3tRdsuJudTtF4QstUtzLwYJ_awa2QheQHTygqORQNQ4yMqHZ96GRkTLApID38iQL9fPZD5MsHqEE-mHsdzqe9iOiehayCPKYyG7HQ4lcIMHYlWestP5gwoWly2gRYLJd7XbXsEcIQUFCPoG6I',
        distanceText: null,
      ),
    ];
    final isGiveMode = _donationsToggleIndex == _toggleGive;
    var filtered = cardData.where((d) => d.isGive == isGiveMode).toList();
    final selectedCategory = _donationsCategoryIndex;
    if (selectedCategory != _catAll) {
      filtered = filtered.where((d) => d.category == selectedCategory).toList();
    }
    final search = _donationSearchQuery.trim().toLowerCase();
    if (search.isNotEmpty) {
      filtered = filtered.where((d) {
        return d.title.toLowerCase().contains(search) ||
            d.description.toLowerCase().contains(search) ||
            (d.fullDescription?.toLowerCase().contains(search) ?? false) ||
            d.location.toLowerCase().contains(search);
      }).toList();
    }
    return filtered.map((d) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _donationCard(
          title: d.title,
          description: d.description,
          fullDescription: d.fullDescription,
          conditionIndex: d.condition,
          categoryIndex: d.category,
          location: d.location,
          distanceText: d.distanceText,
          imageUrl: d.imageUrl,
          isOffer: d.isGive,
          loc: loc,
          onDetailsTap: () {
            context.push(AppConstants.familyDonationDetailRoute, extra: {
              'title': d.title,
              'description': d.description,
              'fullDescription': d.fullDescription,
              'conditionIndex': d.condition,
              'categoryIndex': d.category,
              'imageUrl': d.imageUrl,
              'location': d.location,
              'distanceText': d.distanceText,
            });
          },
        ),
      );
    }).toList();
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
    VoidCallback? onDetailsTap,
  }) {
    final conditionLabels = [
      loc.veryGoodCondition,
      loc.goodCondition,
      loc.likeNew,
    ];
    final conditionColors = [
      Colors.green,
      Colors.amber,
      Colors.green,
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _donationPrimary.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: SizedBox(
              height: 192,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade300,
                      child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey.shade600),
                    ),
                  ),
                  // Condition badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: conditionColors[conditionIndex],
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        conditionLabels[conditionIndex].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // Favorite
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Material(
                      color: Colors.white.withOpacity(0.9),
                      shape: const CircleBorder(),
                      elevation: 1,
                      child: InkWell(
                        onTap: () {},
                        customBorder: const CircleBorder(),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(Icons.favorite, color: _donationPrimary, size: 20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111418),
                        ),
                      ),
                    ),
                    Text(
                      isOffer ? loc.donation : loc.recherche,
                      style: const TextStyle(
                        color: _donationPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          location,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: onDetailsTap,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            loc.details,
                            style: const TextStyle(
                              color: _donationPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right, color: _donationPrimary, size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Contenu onglet Experts — design HTML (search, filtres, cartes experts).
  Widget _buildExpertsContent(double bottomPadding) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildExpertsSearchBar(),
          const SizedBox(height: 16),
          _buildExpertsFilterChips(),
          const SizedBox(height: 16),
          ..._buildExpertCards(),
          SizedBox(height: bottomPadding),
        ],
      ),
    );
  }

  Widget _buildExpertsSearchBar() {
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
        decoration: InputDecoration(
          hintText: 'Search specialists...',
          hintStyle: TextStyle(
            color: AppTheme.text.withOpacity(0.5),
            fontSize: 14,
          ),
          prefixIcon: Icon(Icons.search, color: AppTheme.text.withOpacity(0.4), size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  int _expertsFilterIndex = 0;
  static const List<String> _expertsFilterLabels = [
    'All Experts',
    'Speech Therapists',
    'Pedopsychiatrists',
    'Occupational Therapists',
  ];

  Widget _buildExpertsFilterChips() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _expertsFilterLabels.length,
        itemBuilder: (context, index) {
          final selected = _expertsFilterIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: selected
                  ? Colors.white
                  : Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                onTap: () => setState(() => _expertsFilterIndex = index),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: selected ? Colors.white : Colors.white.withOpacity(0.2),
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
                    _expertsFilterLabels[index],
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

  static const List<Map<String, String>> _expertsData = [
    {
      'name': 'Dr. Sarah Williams',
      'specialization': 'Pedopsychiatrist',
      'location': 'Downtown Medical Center',
      'imageUrl': 'https://lh3.googleusercontent.com/aida-public/AB6AXuAyc6PUxSagO2rMYKXsNcJDu6NXpeHs13KLV13ahZr1uQPb2mPvFr_HmwHJE5faOUJFgHpgO9d3RE2H7ospP4boMlCyquBP3RtDmfvVFewUAG_EV1PNvuwqWHSeZmyH_xFHkeqWmjEoBmjCkf52CLAI9LJd1xncqycz-kc-dQ0dq2P-3fWe0gI7sn--O83AJ8LonfL8sggUNVVB-Yb64YSlpZrskgEXrO3LxG2AnImH9uOkDEg2A7WCyaqL70LV_QGzD6s0lWQ88-s',
    },
    {
      'name': 'Dr. Marcus Chen',
      'specialization': 'Speech Therapist',
      'location': 'East Side Therapy Hub',
      'imageUrl': 'https://lh3.googleusercontent.com/aida-public/AB6AXuBxrvw_y9g6_4zvk26bEdXvU4m_fnybfNySQQv-GrIMe6MAr4woU_wfoCMKurthkGAcTl9Y8frUrc67ujVTSZxFGje0LTnixHKsAmVDPgJwop6Lf0MLIPGmR1Pdv1xBjI21HbalyhGIExACf8ud364M6k5ejyLRncSCmckfjt9uX-Zcr9KhuFX2hq-6VXSRL9ifjrIvQ4TS_Vdn6Ny9Y0d9n5O_J6Hc-JJ5iQJLmbmuexMXI7WN2AAbxp_iFY4XpxzNQEx52uBiOL4',
    },
    {
      'name': 'Elena Rodriguez',
      'specialization': 'Occupational Therapist',
      'location': 'North Wellness Clinic',
      'imageUrl': 'https://lh3.googleusercontent.com/aida-public/AB6AXuAYCjMCXkZrBAaDQzFN45VLLIi6JfdNuaqJonMmdKQzEoOS-5PP8ZpKHlO6MWTv0RXVpjX_-otwRGE7C5Geejw_-89rhbENRNPZ3u_R969qpYkPbL89_OihdurHYm4cSkn8ddk2Zmsub7WNj8XCGvnCyCvl4b9tC7rV96o24Oyj6B-0I0tVzya8yGutePqBRLSuPTklFAgO0VpG-05aXR7Wyq4mscmAy5aXS_aoIni0uwPtmkzOv7P-QoqJujhYwihsq9PXQJz5pzE',
    },
  ];

  List<Widget> _buildExpertCards() {
    return _expertsData.map((e) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _ExpertCard(
          name: e['name']!,
          specialization: e['specialization']!,
          location: e['location']!,
          imageUrl: e['imageUrl']!,
          primaryColor: _feedSecondary,
          onBookConsultation: () {
            context.push(AppConstants.familyExpertBookingRoute, extra: {
              'name': e['name'],
              'specialization': e['specialization'],
              'location': e['location'],
              'imageUrl': e['imageUrl'],
            });
          },
          onMessage: () {},
        ),
      );
    }).toList();
  }

  Widget _buildFamilyChatCard() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => context.go(AppConstants.familyFamiliesRoute),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.text.withOpacity(0.08)),
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
            SizedBox(
              width: 104,
              height: 40,
              child: Stack(
                children: [
                  Positioned(left: 0, child: _avatarCircle('D', 20)),
                  Positioned(left: 32, child: _avatarCircle('M', 20)),
                  Positioned(
                    left: 64,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _feedPrimary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Center(
                        child: Text(
                          '+2',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.familyChat,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppTheme.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Mom: "Check out this toy!"',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.text.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Material(
              color: _feedPrimary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                onTap: () => context.go(AppConstants.familyFamiliesRoute),
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Text(
                    AppLocalizations.of(context)!.open,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _feedSecondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
            ],
          ),
        ),
      ),
    ),
  );
  }

  Widget _avatarCircle(String letter, double radius) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: _feedPrimary.withOpacity(0.4),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Text(
          letter,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: AppTheme.text,
          ),
        ),
      ),
    );
  }

  Widget _buildShareCard() {
    final user = Provider.of<AuthProvider>(context).user;
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
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _feedPrimary.withOpacity(0.3),
                  child: Text(
                    (user?.fullName ?? 'U').substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.text,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                const Icon(Icons.add_photo_alternate, color: _feedPrimary, size: 26),
              ],
            ),
          ),
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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return feedProvider.posts.map((post) {
      final tagStyles = post.tags.asMap().entries.map((e) {
        final c = _tagColors[e.key % _tagColors.length];
        return (c.$1, e.value);
      }).toList();
      final comments = feedProvider.getComments(post.id);
      final lastComment = comments.isNotEmpty
          ? '${comments.first.authorName}: ${comments.first.text}'
          : null;
      final currentUserId = authProvider.user?.id;
      final canDelete = currentUserId != null && currentUserId == post.authorId;
      return _buildPost(
        postId: post.id,
        name: post.authorName,
        time: post.timeAgo,
        text: post.text,
        tagStyles: tagStyles,
        likes: feedProvider.getLikeCount(post.id),
        comments: comments.length,
        liked: feedProvider.isLiked(post.id),
        hasImage: post.hasImage,
        imagePath: post.imagePath,
        lastComment: lastComment,
        onAuthorTap: () {
          context.push(AppConstants.familyCommunityMemberProfileRoute, extra: {
            'memberId': post.authorId,
            'memberName': post.authorName,
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
          final shareText = '${post.authorName}: ${post.text}\n\n— CogniCare Community';
          Share.share(shareText, subject: 'Publication CogniCare');
        },
        canDelete: canDelete,
        onEditTap: canDelete
            ? () => _showEditPostDialog(context, post.id, post.text, feedProvider)
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
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
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
                          content: Text(e is Exception ? e.toString().replaceFirst('Exception: ', '') : loc.errorLoadingProfile),
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
                        (authProvider.user?.fullName ?? 'U').substring(0, 1).toUpperCase(),
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
                            borderSide: BorderSide(color: AppTheme.text.withOpacity(0.2)),
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
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: _feedPrimary.withOpacity(0.4),
                          child: Text(
                            name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: AppTheme.text,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
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
              if (canDelete && (onEditTap != null || onDeleteTap != null))
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
                  },
                  itemBuilder: (context) => [
                    if (onEditTap != null)
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit_outlined, color: AppTheme.primary, size: 20),
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
                  ],
                )
              else
                Icon(Icons.more_horiz, color: AppTheme.text.withOpacity(0.3), size: 22),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                    ? (imagePath.startsWith('http') || imagePath.startsWith('/uploads/')
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
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
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
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          liked ? Icons.favorite : Icons.favorite_border,
                          size: 22,
                          color: liked ? Colors.red : AppTheme.text.withOpacity(0.5),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$likes',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: liked ? Colors.red : AppTheme.text.withOpacity(0.5),
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
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Icon(Icons.share_outlined, size: 22, color: AppTheme.text.withOpacity(0.5)),
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
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
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
                    children: List.generate(3, (_) => _marketplaceCardPlaceholder()),
                  );
                }
                List<MarketplaceProduct> products = snapshot.data ?? [];
                if (snapshot.hasError || products.isEmpty) {
                  products = _fallbackMarketplaceProducts();
                }
                if (products.isEmpty) {
                  return ListView(
                    scrollDirection: Axis.horizontal,
                    children: [_marketplaceCardPlaceholder()],
                  );
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

  /// URLs d'images de repli (Unsplash) quand l'API n'en fournit pas.
  static const List<String> _fallbackImageUrls = [
    'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?w=400', // weighted blanket
    'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400', // headphones
    'https://images.unsplash.com/photo-1560869713-72d2c8364444?w=400',   // timer
  ];

  /// Produits affichés quand l'API est indisponible ou renvoie une liste vide.
  List<MarketplaceProduct> _fallbackMarketplaceProducts() {
    final loc = AppLocalizations.of(context)!;
    return [
      MarketplaceProduct(
        id: 'fallback_1',
        title: loc.weightedBlanket,
        price: '\$45.00',
        imageUrl: _fallbackImageUrls[0],
        description: '',
      ),
      MarketplaceProduct(
        id: 'fallback_2',
        title: loc.noiseCancelling,
        price: '\$129.00',
        imageUrl: _fallbackImageUrls[1],
        description: '',
      ),
      MarketplaceProduct(
        id: 'fallback_3',
        title: loc.visualTimer,
        price: '\$18.50',
        imageUrl: _fallbackImageUrls[2],
        description: '',
      ),
    ];
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
              child: Icon(Icons.shopping_bag_outlined, size: 32, color: _feedPrimary),
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
            'badgeColorValue': null,
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
                          child: Icon(Icons.shopping_bag_outlined, size: 32, color: _feedPrimary),
                        );
                      },
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.shopping_bag_outlined, size: 32, color: _feedPrimary),
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.shopping_bag_outlined, size: 32, color: _feedPrimary),
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

/// Carte expert — photo, nom, badge Verified, spécialisation, lieu, Book Consultation / Message.
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
  final String imageUrl;
  final Color primaryColor;
  final VoidCallback onBookConsultation;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    const Color slate900 = Color(0xFF0F172A);
    const Color slate400 = Color(0xFF94A3B8);
    const Color blue50 = Color(0xFFEFF6FF);
    const Color blue600 = Color(0xFF2563EB);

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
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      width: 80,
                      height: 80,
                      color: const Color(0xFFA3D9E2).withOpacity(0.2),
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => Container(
                    width: 80,
                    height: 80,
                    color: const Color(0xFFA3D9E2).withOpacity(0.2),
                    child: const Icon(Icons.person, size: 36, color: Color(0xFF7FBAC4)),
                  ),
                ),
              ),
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: blue50,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified, size: 14, color: blue600),
                              SizedBox(width: 4),
                              Text(
                                'VERIFIED',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: blue600,
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
                        const Icon(Icons.location_on, size: 14, color: slate400),
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
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Center(
                        child: Text(
                          'Book Consultation',
                          style: TextStyle(
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
                      child: const Text(
                        'Message',
                        style: TextStyle(
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
