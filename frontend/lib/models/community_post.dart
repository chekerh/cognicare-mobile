/// Modèle d'un post dans le fil communautaire (secteur famille).
class CommunityPost {
  final String id;
  final String authorName;
  final String authorId;
  final String text;
  final DateTime createdAt;
  final bool hasImage;

  /// Chemin local de l'image uploadée (après sélection galerie/caméra).
  final String? imagePath;
  final List<String> tags;

  const CommunityPost({
    required this.id,
    required this.authorName,
    required this.authorId,
    required this.text,
    required this.createdAt,
    this.hasImage = false,
    this.imagePath,
    this.tags = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'authorName': authorName,
        'authorId': authorId,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'hasImage': hasImage,
        'imagePath': imagePath,
        'tags': tags,
      };

  factory CommunityPost.fromJson(Map<String, dynamic> json) => CommunityPost(
        id: json['id'] as String,
        authorName: json['authorName'] as String,
        authorId: json['authorId'] as String,
        text: json['text'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        hasImage: json['hasImage'] as bool? ?? false,
        imagePath: json['imagePath'] as String?,
        tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
      );

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${(diff.inDays / 7).floor()} weeks ago';
  }
}
