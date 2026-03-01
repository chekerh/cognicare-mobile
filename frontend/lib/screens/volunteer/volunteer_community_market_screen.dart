import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/marketplace_product.dart';
import '../../services/integrations_service.dart';
import '../../utils/constants.dart';

// Design aligné sur le HTML Stitch - Community Marketplace Hub
const Color _primary = Color(0xFFa3dae1);
const Color _accentColor = Color(0xFF212121);
const Color _background = Color(0xFFF5F9FA);
const Color _cardBg = Color(0xFFFFFFFF);
const Color _textPrimary = Color(0xFF1E293B);
const Color _textMuted = Color(0xFF64748B);
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

/// Affiche le prix en dinars tunisiens (DT), en remplaçant € par DT.
String _formatPriceDt(String price) {
  final p = price.trim().replaceAll('€', '').trim();
  if (p.isEmpty) return '0 DT';
  return p.toUpperCase().endsWith('DT') ? p : '$p DT';
}

/// Labels des catégories (Tout = pas de filtre).
const List<String> _categoryLabels = [
  'Tout',
  'Sensory',
  'Éducatif',
  'Mobilité',
  'Nouveautés',
];

/// Marketplace bénévole — même logique que family: catalogue intégré (IntegrationsService),
/// grille/liste de produits, ouverture vers formulaire de commande intégré ou détail produit.
/// Si [showHeader] est false, seul le contenu est affiché (pour intégration dans la section Communauté).
class VolunteerCommunityMarketScreen extends StatefulWidget {
  const VolunteerCommunityMarketScreen({super.key, this.showHeader = true});

  final bool showHeader;

  @override
  State<VolunteerCommunityMarketScreen> createState() =>
      _VolunteerCommunityMarketScreenState();
}

class _VolunteerCommunityMarketScreenState
    extends State<VolunteerCommunityMarketScreen> {
  /// Produits du catalogue intégré (ex. Books to Scrape), comme dans family.
  List<MarketplaceProduct> _integrationProducts = [];
  String _integrationSectionTitle = '';
  String _integrationWebsiteSlug = '';
  bool _integrationLoading = false;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  int _selectedCategoryIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadIntegrationCatalog());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Même logique que FamilyMarketScreen: charger le catalogue intégré.
  Future<void> _loadIntegrationCatalog({bool refresh = false}) async {
    setState(() {
      _integrationLoading = true;
      _error = null;
      if (!refresh) {
        _integrationSectionTitle = '';
        _integrationProducts = [];
      }
    });
    try {
      final websites = await IntegrationsService().getWebsites();
      if (websites.isEmpty || !mounted) {
        if (mounted) setState(() => _integrationLoading = false);
        return;
      }
      final slug = websites.first.slug;
      final catalog = await IntegrationsService().getCatalog(slug, page: 1, refresh: refresh);
      if (!mounted) return;
      final website = websites.first;
      final list = catalog.products.map((p) {
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
      setState(() {
        _integrationSectionTitle = website.name;
        _integrationWebsiteSlug = slug;
        _integrationProducts = list;
        _integrationLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _integrationSectionTitle = '';
          _integrationProducts = [];
          _integrationLoading = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  List<MarketplaceProduct> get _filteredProducts {
    if (_integrationProducts.isEmpty) return [];
    var list = List<MarketplaceProduct>.from(_integrationProducts);
    if (_selectedCategoryIndex > 0) {
      final label = _categoryLabels[_selectedCategoryIndex];
      final labelLower = label.toLowerCase();
      list = list.where((p) {
        final cat = p.category.toLowerCase();
        final badge = (p.badge ?? '').toLowerCase();
        if (labelLower == 'sensory') {
          return cat.contains('sensor') || badge.contains('premium') || badge.contains('sensory');
        }
        if (labelLower == 'nouveautés') {
          return cat.contains('new') || badge.contains('new') || badge.contains('nouveau');
        }
        return cat.contains(labelLower) || badge.contains(labelLower);
      }).toList();
    }
    final q = _searchController.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((p) =>
              p.title.toLowerCase().contains(q) ||
              p.description.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  static Color _badgeToColor(String? badge) {
    if (badge == null || badge.isEmpty) return _primary;
    final b = badge.toUpperCase();
    if (b.contains('TOP')) return _accentColor;
    if (b.contains('SKILL') || b.contains('BUILDER')) return Colors.green;
    if (b.contains('POPULAR')) return Colors.orange;
    return _primary;
  }

  /// Même logique que family: si produit intégré → formulaire de commande; sinon détail produit.
  void _openProduct(MarketplaceProduct product) {
    if (_integrationWebsiteSlug.isNotEmpty && product.externalUrl != null && product.externalUrl!.isNotEmpty) {
      context.push(AppConstants.volunteerIntegrationOrderRoute, extra: {
        'websiteSlug': _integrationWebsiteSlug,
        'externalId': product.id,
        'productName': product.title,
        'price': product.price,
        'imageUrl': product.imageUrl,
      });
      return;
    }
    final badgeColor = _badgeToColor(product.badge);
    context.push(AppConstants.volunteerProductDetailRoute, extra: {
      'productId': product.id,
      'title': product.title,
      'price': product.price,
      'imageUrl': product.imageUrl,
      'description': product.description,
      'badge': product.badge,
      'badgeColorValue': badgeColor.value,
      'externalUrl': product.externalUrl,
    });
  }

  Widget _buildBodyContent() {
    if (_integrationLoading) {
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
                onPressed: () => _loadIntegrationCatalog(),
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
    if (_integrationProducts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Aucun produit pour le moment.\nVérifiez que le backend et le catalogue intégré sont disponibles.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: _textMuted),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _loadIntegrationCatalog(refresh: true),
      color: _primary,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildSearchAndFilters()),
          SliverToBoxAdapter(child: _buildCategoryChips()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            sliver: _filteredProducts.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 48),
                      child: Center(
                        child: Text(
                          'Aucun produit ne correspond.',
                          style: TextStyle(
                              fontSize: 15, color: _textMuted),
                        ),
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildListDelegate(
                      _filteredProducts
                          .asMap()
                          .entries
                          .map((e) => _productCard(e.value, e.key))
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
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () =>
                    context.push(AppConstants.volunteerCommunityDonationsRoute),
                borderRadius: BorderRadius.circular(999),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'Donations',
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
                'Marketplace',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
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
                  hintText: 'Rechercher un outil sensoriel...',
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
                onTap: () => setState(() => _selectedCategoryIndex = i),
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
                      color: selected ? Colors.white : _textMuted,
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

  Widget _productCard(MarketplaceProduct product, int index) {
    final imageUrl = product.imageUrl.isNotEmpty
        ? (product.imageUrl.startsWith('http')
            ? product.imageUrl
            : _fullImageUrl(product.imageUrl))
        : '';
    final badgeLabel = product.badge ?? 'Premium';
    final showDelivery = index.isEven;

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
            onTap: () => _openProduct(product),
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
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _borderSlate),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Text(
                            _formatPriceDt(product.price),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: _primary,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _primary.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.verified_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                badgeLabel.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.8,
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              product.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _textPrimary,
                                height: 1.2,
                              ),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 18,
                                color: Colors.amber.shade400,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '4.5',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.description.isNotEmpty
                            ? product.description
                            : 'Produit adapté à la communauté CogniCare.',
                        style: TextStyle(
                          fontSize: 14,
                          color: _textMuted,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.only(top: 16),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: _borderSlate),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    showDelivery
                                        ? Icons.local_shipping_outlined
                                        : Icons.verified_user_outlined,
                                    size: 20,
                                    color: _primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      showDelivery
                                          ? 'LIVRAISON OFFERTE'
                                          : 'GARANTIE 2 ANS',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: _textSlate400,
                                        letterSpacing: 0.8,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Material(
                                color: _primary,
                                borderRadius: BorderRadius.circular(16),
                                child: InkWell(
                                  onTap: () => _openProduct(product),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10),
                                    child: Center(
                                      child: Text(
                                        'Ajouter au panier',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
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

  Widget _imagePlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: _primary.withOpacity(0.12),
      child: Center(
        child: Icon(
          Icons.shopping_bag_outlined,
          size: 48,
          color: _primary.withOpacity(0.5),
        ),
      ),
    );
  }
}
