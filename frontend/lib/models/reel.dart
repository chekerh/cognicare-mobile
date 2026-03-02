/// Reel (vidéo courte) liée aux troubles cognitifs / autisme.
class Reel {
  const Reel({
    required this.id,
    required this.sourceId,
    required this.source,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.publishedAt,
    this.relevanceScore,
    this.language,
  });

  final String id;
  final String sourceId;
  final String source;
  final String title;
  final String description;
  final String videoUrl;
  final String thumbnailUrl;
  final DateTime publishedAt;
  final double? relevanceScore;
  final String? language;

  factory Reel.fromJson(Map<String, dynamic> json) {
    final id = json['_id']?.toString() ?? json['id']?.toString() ?? '';
    final pub = json['publishedAt'];
    return Reel(
      id: id,
      sourceId: json['sourceId'] as String? ?? '',
      source: json['source'] as String? ?? 'youtube',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      videoUrl: json['videoUrl'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String? ?? '',
      publishedAt: pub is String
          ? DateTime.tryParse(pub) ?? DateTime.now()
          : (pub is DateTime ? pub : DateTime.now()),
      relevanceScore: (json['relevanceScore'] as num?)?.toDouble(),
      language: json['language'] as String?,
    );
  }
}
