/// Modèle d'un post dans le fil communautaire (secteur famille).
class CommunityPost {
  final String id;
  final String authorName;
  final String authorId;
  final String? authorProfilePic;
  final String text;
  final DateTime createdAt;
  final bool hasImage;

  /// Chemin local de l'image uploadée (après sélection galerie/caméra).
  final String? imagePath;
  final List<String> tags;
  final int likeCount;
  final int commentCount;

  const CommunityPost({
    required this.id,
    required this.authorName,
    required this.authorId,
    this.authorProfilePic,
    required this.text,
    required this.createdAt,
    this.hasImage = false,
    this.imagePath,
    this.tags = const [],
    this.likeCount = 0,
    this.commentCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'authorName': authorName,
        'authorId': authorId,
        if (authorProfilePic != null) 'authorProfilePic': authorProfilePic,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'hasImage': hasImage,
        'imagePath': imagePath,
        'tags': tags,
        'likeCount': likeCount,
        'commentCount': commentCount,
      };

  factory CommunityPost.fromJson(Map<String, dynamic> json) => CommunityPost(
        id: json['id'] as String,
        authorName: json['authorName'] as String,
        authorId: json['authorId'] as String,
        authorProfilePic: json['authorProfilePic'] as String?,
        text: json['text'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        hasImage: json['hasImage'] as bool? ?? false,
        imagePath: json['imagePath'] as String?,
        tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
        likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
        commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
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
