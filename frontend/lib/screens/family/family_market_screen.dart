import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../models/marketplace_product.dart';
import '../../services/marketplace_service.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';

const Color _marketPrimary = Color(0xFFADD8E6);
const Color _marketBackground = Color(0xFFF8FAFC);
const Color _accentColor = Color(0xFF212121); // même gris que "Commande Confirmée"

/// Marketplace — écran de produits spécialisés (secteur famille).
class FamilyMarketScreen extends StatefulWidget {
  const FamilyMarketScreen({super.key});

  @override
  State<FamilyMarketScreen> createState() => _FamilyMarketScreenState();
}

class _FamilyMarketScreenState extends State<FamilyMarketScreen> {
  String? _selectedCategoryKey;
  List<MarketplaceProduct> _products = [];
  bool _loading = true;
  final ScrollController _contentScrollController = ScrollController();
  final GlobalKey _newArrivalsSectionKey = GlobalKey();

  List<String> _getCategories(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return [loc.allItems, loc.sensory, loc.motorSkills, loc.cognitive];
  }

  /// Map display category label to API category value.
  String _categoryToApi(String displayCategory) {
    final loc = AppLocalizations.of(context)!;
    if (displayCategory == loc.allItems) return 'all';
    if (displayCategory == loc.sensory) return 'sensory';
    if (displayCategory == loc.motorSkills) return 'motor';
    if (displayCategory == loc.cognitive) return 'cognitive';
    return 'all';
  }

  Future<void> _loadProducts() async {
    final category = _selectedCategoryKey != null ? _categoryToApi(_selectedCategoryKey!) : 'all';
    setState(() => _loading = true);
    try {
      // Uniquement les produits ajoutés par l'utilisateur connecté
      final list = await MarketplaceService().getMyProducts(limit: 50, category: category);
      if (mounted) setState(() { _products = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _products = []; _loading = false; });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loc = AppLocalizations.of(context)!;
      _selectedCategoryKey ??= loc.allItems;
      _loadProducts();
    });
  }

  @override
  void dispose() {
    _contentScrollController.dispose();
    super.dispose();
  }

  Future<void> _showAllProducts() async {
    final loc = AppLocalizations.of(context)!;
    final allItems = loc.allItems;
    if (_selectedCategoryKey != allItems) {
      setState(() => _selectedCategoryKey = allItems);
      await _loadProducts();
    }
    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 40));
    _scrollToSection(_newArrivalsSectionKey);
  }

  void _scrollToSection(GlobalKey key) {
    final sectionContext = key.currentContext;
    if (sectionContext == null || !_contentScrollController.hasClients) return;
    final box = sectionContext.findRenderObject() as RenderBox?;
    if (box == null) return;
    final listBox = context.findRenderObject() as RenderBox?;
    if (listBox == null) return;
    final sectionTop = box.localToGlobal(Offset.zero, ancestor: listBox).dy;
    final target = (_contentScrollController.offset + sectionTop - 12).clamp(
      0.0,
      _contentScrollController.position.maxScrollExtent,
    ).toDouble();
    _contentScrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
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
    final loc = AppLocalizations.of(context)!;
    _selectedCategoryKey ??= loc.allItems;
    return Scaffold(
      backgroundColor: _marketBackground,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      controller: _contentScrollController,
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildRecommendedSection(),
                          const SizedBox(height: 40),
                          _buildNewArrivalsSection(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final added = await context.push<bool>(AppConstants.familyAddProductRoute);
          if (added == true && mounted) _loadProducts();
        },
        backgroundColor: _accentColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    final loc = AppLocalizations.of(context)!;
    final padding = MediaQuery.paddingOf(context);
    final categories = _getCategories(context);
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
      child: Column(
        children: [
          Row(
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
                    loc.marketplaceSubtitle,
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
                  _headerButton(Icons.shopping_cart_outlined, onTap: () => context.push(AppConstants.familyCartRoute)),
                  const SizedBox(width: 12),
                  _headerButton(Icons.search),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                final isSelected = cat == _selectedCategoryKey;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: InkWell(
                    onTap: () {
                      setState(() => _selectedCategoryKey = cat);
                      _loadProducts();
                    },
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _accentColor
                            : Colors.white.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : AppTheme.text,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
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

  Widget _buildRecommendedSection() {
    final loc = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: _accentColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  '${loc.recommendedFor} Leo',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.text,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: _showAllProducts,
              child: Text(
                loc.seeAll,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _accentColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 320,
          child: _products.isEmpty
              ? const Center(child: Text('Aucun produit pour cette catégorie.'))
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _products.length,
                  itemBuilder: (context, i) {
                    final product = _products[i];
                    return Padding(
                      padding: EdgeInsets.only(right: i < _products.length - 1 ? 16 : 0),
                      child: _recommendedCard(product),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _openProductDetail(MarketplaceProduct product) {
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
      },
    );
  }

  Widget _recommendedCard(MarketplaceProduct product) {
    final badgeColor = _badgeToColor(product.badge);
    final badge = product.badge ?? '';
    return InkWell(
      onTap: () => _openProductDetail(product),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(16),
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
              child: Stack(
                children: [
                  ClipRRect(
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
                  if (badge.isNotEmpty)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              product.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              product.description,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.text.withOpacity(0.6),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  product.price,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.text,
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _openProductDetail(product),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.buyNow,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewArrivalsSection() {
    final loc = AppLocalizations.of(context)!;
    return Column(
      key: _newArrivalsSectionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              loc.newArrivals,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.text,
              ),
            ),
            IconButton(
              icon: Icon(Icons.filter_list, color: AppTheme.text.withOpacity(0.5)),
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: 16),
        _products.isEmpty
            ? const SizedBox.shrink()
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                itemCount: _products.length,
                itemBuilder: (context, i) => _newArrivalCard(_products[i]),
              ),
      ],
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
