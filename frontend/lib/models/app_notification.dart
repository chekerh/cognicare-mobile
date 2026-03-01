/// Élément du centre de notifications (liste depuis l'API).
class AppNotification {
  final String id;
  final String type;
  final String title;
  final String description;
  final bool read;
  final DateTime? createdAt;
  final Map<String, dynamic>? data;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    this.description = '',
    this.read = false,
    this.createdAt,
    this.data,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return AppNotification(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      type: (json['type'] ?? 'system').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      read: json['read'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      data: data is Map<String, dynamic> ? data : null,
    );
  }

  String? get followRequestId =>
      data != null ? data!['requestId'] as String? : null;
}
