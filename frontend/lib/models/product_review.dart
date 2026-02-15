/// Avis (review) sur un produit du marketplace.
class ProductReview {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final String? userProfileImageUrl;
  final int rating;
  final String comment;
  final DateTime? createdAt;

  const ProductReview({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    this.userProfileImageUrl,
    required this.rating,
    this.comment = '',
    this.createdAt,
  });

  factory ProductReview.fromJson(Map<String, dynamic> json) {
    final pic = json['userProfileImageUrl']?.toString();
    return ProductReview(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      productId: (json['productId'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      userName: (json['userName'] ?? 'User').toString(),
      userProfileImageUrl: (pic != null && pic.isNotEmpty) ? pic : null,
      rating: (json['rating'] is int) ? json['rating'] as int : int.tryParse(json['rating']?.toString() ?? '0') ?? 0,
      comment: (json['comment'] ?? '').toString(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }
}
