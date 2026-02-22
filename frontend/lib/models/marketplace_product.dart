/// Produit du marketplace (secteur famille).
class MarketplaceProduct {
  final String id;
  final String title;
  final String price;
  final String imageUrl;
  final String description;
  final String? badge;
  final String category;

  const MarketplaceProduct({
    required this.id,
    required this.title,
    required this.price,
    required this.imageUrl,
    this.description = '',
    this.badge,
    this.category = 'all',
  });

  factory MarketplaceProduct.fromJson(Map<String, dynamic> json) {
    // Support both backend format (imageUrl) and DummyJSON API (images[], thumbnail)
    String imageUrl = (json['imageUrl'] ?? '').toString();
    if (imageUrl.isEmpty) {
      final images = json['images'];
      if (images is List && images.isNotEmpty) {
        imageUrl = images[0].toString();
      } else {
        imageUrl = (json['thumbnail'] ?? '').toString();
      }
    }
    return MarketplaceProduct(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      price: (json['price']?.toString() ?? '0'),
      imageUrl: imageUrl,
      description: (json['description'] ?? '').toString(),
      badge: json['badge']?.toString(),
      category: (json['category'] ?? 'all').toString(),
    );
  }
}
