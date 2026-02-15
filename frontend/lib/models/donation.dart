/// Modèle pour une annonce de don (Le Cercle du Don).
class Donation {
  final String id;
  final String donorId;
  final String donorName;
  final String title;
  final String description;
  final String? fullDescription;
  final int category;
  final int condition;
  final String location;
  final bool isOffer;
  final List<String> imageUrls;
  final String imageUrl;
  final String createdAt;

  Donation({
    required this.id,
    required this.donorId,
    required this.donorName,
    required this.title,
    required this.description,
    this.fullDescription,
    required this.category,
    required this.condition,
    required this.location,
    required this.isOffer,
    this.imageUrls = const [],
    this.imageUrl = '',
    this.createdAt = '',
  });

  factory Donation.fromJson(Map<String, dynamic> json) {
    final urls = json['imageUrls'] as List<dynamic>?;
    final list = urls?.map((e) => e.toString()).toList() ?? [];
    final first = list.isNotEmpty ? list.first : '';
    return Donation(
      id: json['id']?.toString() ?? '',
      donorId: json['donorId']?.toString() ?? '',
      donorName: json['donorName']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      fullDescription: json['fullDescription']?.toString(),
      category: (json['category'] as num?)?.toInt() ?? 0,
      condition: (json['condition'] as num?)?.toInt() ?? 1,
      location: json['location']?.toString() ?? '',
      isOffer: json['isOffer'] == true,
      imageUrls: list,
      imageUrl: json['imageUrl']?.toString() ?? first,
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}
