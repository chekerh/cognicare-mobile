/// Cabinet ou centre de santé en Tunisie (hors app) — pour la carte famille.
class HealthcareCabinet {
  final String id;
  final String name;
  final String specialty;
  final String address;
  final String city;
  final double latitude;
  final double longitude;
  final String? phone;
  final String? website;

  const HealthcareCabinet({
    required this.id,
    required this.name,
    required this.specialty,
    required this.address,
    required this.city,
    required this.latitude,
    required this.longitude,
    this.phone,
    this.website,
  });

  factory HealthcareCabinet.fromJson(Map<String, dynamic> json) {
    return HealthcareCabinet(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      specialty: (json['specialty'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      latitude: _toDouble(json['latitude']) ?? 0,
      longitude: _toDouble(json['longitude']) ?? 0,
      phone: json['phone']?.toString(),
      website: json['website']?.toString(),
    );
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}
