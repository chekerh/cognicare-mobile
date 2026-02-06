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
    return MarketplaceProduct(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      price: (json['price'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      badge: json['badge']?.toString(),
      category: (json['category'] ?? 'all').toString(),
    );
  }
}
