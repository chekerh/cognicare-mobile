import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../models/marketplace_product.dart';
import '../../services/integrations_service.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';

const Color _marketPrimary = Color(0xFFADD8E6);
const Color _marketBackground = Color(0xFFF8FAFC);
const Color _accentColor =
    Color(0xFF212121); // même gris que "Commande Confirmée"

/// Marketplace — écran de produits spécialisés (secteur famille).
class FamilyMarketScreen extends StatefulWidget {
  const FamilyMarketScreen({super.key});

  @override
  State<FamilyMarketScreen> createState() => _FamilyMarketScreenState();
}

class _FamilyMarketScreenState extends State<FamilyMarketScreen> {
  final ScrollController _contentScrollController = ScrollController();

  /// Uniquement les produits scrapés (catalogue intégré, ex. Books to Scrape).
  List<MarketplaceProduct> _integrationProducts = [];
  String _integrationSectionTitle = '';
  String _integrationWebsiteSlug = '';
  bool _integrationLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadIntegrationCatalog());
  }

  Future<void> _loadIntegrationCatalog({bool refresh = false}) async {
    setState(() {
      _integrationLoading = true;
      if (!refresh) {
        _integrationSectionTitle = '';
        _integrationProducts = [];
      }
    });
    try {
      final websites = await IntegrationsService().getWebsites();
      if (websites.isEmpty || !mounted) return;
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
    } catch (_) {
      if (mounted) {
        setState(() {
          _integrationSectionTitle = '';
          _integrationProducts = [];
          _integrationLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _contentScrollController.dispose();
    super.dispose();
  }

  static Color _badgeToColor(String? badge) {
    if (badge == null || badge.isEmpty) return _marketPrimary;
    final b = badge.toUpperCase();
    if (b.contains('TOP')) return _accentColor;
    if (b.contains('SKILL') || b.contains('BUILDER')) return Colors.green;
    if (b.contains('POPULAR')) return Colors.orange;
    return _marketPrimary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _marketBackground,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _integrationLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: () => _loadIntegrationCatalog(refresh: true),
                      child: SingleChildScrollView(
                        controller: _contentScrollController,
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: _buildIntegrationSection(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final loc = AppLocalizations.of(context)!;
    final padding = MediaQuery.paddingOf(context);
    return Container(
      padding: EdgeInsets.fromLTRB(24, padding.top + 8, 24, 24),
      decoration: BoxDecoration(
        color: _marketPrimary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.marketplaceTitle,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _integrationSectionTitle.isEmpty
                    ? loc.marketplaceSubtitle
                    : _integrationSectionTitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.text,
                ),
              ),
            ],
          ),
          Row(
            children: [
              _headerButton(Icons.shopping_cart_outlined,
                  onTap: () => context.push(AppConstants.familyCartRoute)),
              const SizedBox(width: 12),
              _headerButton(Icons.search),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerButton(IconData icon, {VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.text, size: 22),
        ),
      ),
    );
  }

  void _openProductDetail(MarketplaceProduct product) {
    if (_integrationWebsiteSlug.isNotEmpty && product.externalUrl != null) {
      context.push(AppConstants.familyIntegrationOrderRoute, extra: {
        'websiteSlug': _integrationWebsiteSlug,
        'externalId': product.id,
        'productName': product.title,
        'price': product.price,
      });
      return;
    }
    final badgeColor = _badgeToColor(product.badge);
    context.push(
      AppConstants.familyProductDetailRoute,
      extra: {
        'productId': product.id,
        'title': product.title,
        'price': product.price,
        'imageUrl': product.imageUrl,
        'description': product.description,
        'badge': product.badge,
        'badgeColorValue': badgeColor.value,
        'externalUrl': product.externalUrl,
      },
    );
  }

  Widget _buildIntegrationSection() {
    if (_integrationLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_integrationProducts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Aucun produit pour le moment.\nVérifiez que le backend et le catalogue intégré sont disponibles.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.text.withOpacity(0.7),
            ),
          ),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.72,
      ),
      itemCount: _integrationProducts.length,
      itemBuilder: (context, i) => _newArrivalCard(_integrationProducts[i]),
    );
  }

  Widget _newArrivalCard(MarketplaceProduct product) {
    return InkWell(
      onTap: () => _openProductDetail(product),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  product.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey.shade200,
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image_not_supported),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.text,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              product.price,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: _accentColor,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _openProductDetail(product),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                  backgroundColor: Colors.grey.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.quickBuy,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.text,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
