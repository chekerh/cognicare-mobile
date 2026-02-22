import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/product_review.dart';
import '../../providers/cart_provider.dart';
import '../../services/marketplace_service.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';

const Color _marketPrimary = Color(0xFFADD8E6);

/// Écran de détails d'un produit du marketplace.
class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final String title;
  final String price;
  final String imageUrl;
  final String description;
  final String? badge;
  final Color? badgeColor;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    required this.title,
    required this.price,
    required this.imageUrl,
    required this.description,
    this.badge,
    this.badgeColor,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final int _currentImageIndex = 0;
  bool _isFavorite = false;
  List<ProductReview> _reviews = [];
  bool _reviewsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _reviewsLoading = true);
    try {
      final list = await MarketplaceService().getReviews(widget.productId);
      if (mounted) setState(() { _reviews = list; _reviewsLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _reviews = []; _reviewsLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final padding = MediaQuery.paddingOf(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildHeader(context, loc, padding.top),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageCarousel(),
                  const SizedBox(height: 16),
                  _buildProductCard(),
                  const SizedBox(height: 24),
                  _buildReviewsSection(),
                  SizedBox(height: padding.bottom + 100),
                ],
              ),
            ),
          ),
          _buildBottomBar(padding.bottom),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations loc, double topPadding) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(8, topPadding + 8, 8, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.text, size: 20),
            onPressed: () => context.pop(),
          ),
          Expanded(
            child: Text(
              loc.productDetails,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.text,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: AppTheme.text),
            onPressed: () => context.push(AppConstants.familyCartRoute),
          ),
        ],
      ),
    );
  }

  static const String _placeholderImageUrl =
      'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?w=800';

  Widget _buildImageCarousel() {
    final imageUrl = widget.imageUrl.trim().isEmpty ? _placeholderImageUrl : widget.imageUrl;
    return Stack(
      children: [
        SizedBox(
          height: 300,
          width: double.infinity,
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.grey.shade200,
                child: const Center(child: CircularProgressIndicator()),
              );
            },
            errorBuilder: (context, error, stackTrace) => Container(
              height: 300,
              color: Colors.grey.shade200,
              child: const Center(
                child: Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == _currentImageIndex
                      ? Colors.white
                      : Colors.white.withOpacity(0.4),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard() {
    final loc = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
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
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.text,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _marketPrimary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  loc.stockAvailable,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.price,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: _marketPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.title == 'Couverture Lestée'
                ? loc.weightedBlanketDesc
                : widget.description,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: AppTheme.text.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            loc.keyBenefits,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.text,
            ),
          ),
          const SizedBox(height: 12),
          _buildBenefit(Icons.psychology_rounded, loc.anxietyReduction),
          const SizedBox(height: 8),
          _buildBenefit(Icons.bedtime_rounded, loc.improvesSleepQuality),
        ],
      ),
    );
  }

  Widget _buildBenefit(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _marketPrimary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: _marketPrimary, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            color: AppTheme.text,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsSection() {
    final loc = AppLocalizations.of(context)!;
    final avgRating = _reviews.isEmpty
        ? 0.0
        : _reviews.map((r) => r.rating).reduce((a, b) => a + b) / _reviews.length;
    final ratingStr = _reviews.isEmpty
        ? '0 (0 avis)'
        : '${avgRating.toStringAsFixed(1)} (${_reviews.length} avis)';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                loc.communityReviews,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.text,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text(
                ratingStr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _showAddReviewDialog(),
            icon: const Icon(Icons.edit, size: 18),
            label: Text(loc.writeReview),
            style: OutlinedButton.styleFrom(
              foregroundColor: _marketPrimary,
              side: BorderSide(color: _marketPrimary),
            ),
          ),
          const SizedBox(height: 16),
          if (_reviewsLoading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (_reviews.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                loc.noReviewsYet,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.text.withOpacity(0.7),
                ),
              ),
            )
          else
            ..._reviews.map(
              (r) {
                final profileImageUrl = r.userProfileImageUrl != null && r.userProfileImageUrl!.isNotEmpty
                    ? (r.userProfileImageUrl!.startsWith('http')
                        ? r.userProfileImageUrl!
                        : '${AppConstants.baseUrl}${r.userProfileImageUrl}')
                    : null;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildReview(
                    name: r.userName,
                    rating: r.rating,
                    text: r.comment.isEmpty ? loc.reviewWithoutComment : r.comment,
                    profileImageUrl: profileImageUrl,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _showAddReviewDialog() async {
    int rating = 5;
    final commentController = TextEditingController();
    final loc = AppLocalizations.of(context)!;

    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(loc.writeReview),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.ratingLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        final star = i + 1;
                        return IconButton(
                          icon: Icon(
                            Icons.star,
                            size: 32,
                            color: star <= rating ? Colors.amber : Colors.grey,
                          ),
                          onPressed: () => setDialogState(() => rating = star),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    Text(loc.commentOptional, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: commentController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: loc.shareYourExperience,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(loc.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text(loc.publishLabel),
                ),
              ],
            );
          },
        );
      },
    );

    if (submitted != true || !mounted) return;

    try {
      await MarketplaceService().createReview(
        productId: widget.productId,
        rating: rating,
        comment: commentController.text.trim(),
      );
      commentController.dispose();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.reviewPublished),
          backgroundColor: Colors.green,
        ),
      );
      _loadReviews();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildReview({
    required String name,
    required int rating,
    required String text,
    String? profileImageUrl,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _marketPrimary.withOpacity(0.3),
                backgroundImage: (profileImageUrl != null && profileImageUrl.isNotEmpty)
                    ? NetworkImage(profileImageUrl)
                    : null,
                onBackgroundImageError: (profileImageUrl != null && profileImageUrl.isNotEmpty)
                    ? (_, __) {}
                    : null,
                child: (profileImageUrl == null || profileImageUrl.isEmpty)
                    ? Text(
                        name.isNotEmpty ? name[0] : '?',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.text,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.text,
                      ),
                    ),
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          Icons.star,
                          size: 16,
                          color: index < rating ? Colors.amber : Colors.grey.shade300,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppTheme.text.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(double bottomPadding) {
    final loc = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _marketPrimary, width: 2),
              ),
              child: IconButton(
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _marketPrimary,
                ),
                onPressed: () {
                  setState(() => _isFavorite = !_isFavorite);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Provider.of<CartProvider>(context, listen: false).addItem(
                    productId: widget.productId,
                    title: widget.title,
                    price: widget.price,
                    imageUrl: widget.imageUrl.trim().isEmpty
                        ? 'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?w=800'
                        : widget.imageUrl,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(loc.productAddedToCart),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _marketPrimary,
                  foregroundColor: AppTheme.text,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.shopping_cart),
                    const SizedBox(width: 8),
                    Text(
                      loc.addToCart,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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
}
