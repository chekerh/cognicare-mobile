/// Un commentaire sur un post du fil.
class FeedComment {
  final String authorName;
  final String text;
  final DateTime createdAt;

  const FeedComment({
    required this.authorName,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'authorName': authorName,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
      };

  factory FeedComment.fromJson(Map<String, dynamic> json) => FeedComment(
        authorName: json['authorName'] as String,
        text: json['text'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
