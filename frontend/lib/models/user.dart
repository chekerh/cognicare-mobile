class User {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String role;
  final String? profilePic;
  final DateTime createdAt;
  /// Cabinet en Tunisie — pour la carte des professionnels de santé.
  final String? officeAddress;
  final String? officeCity;
  final double? officeLat;
  final double? officeLng;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    required this.role,
    this.profilePic,
    required this.createdAt,
    this.officeAddress,
    this.officeCity,
    this.officeLat,
    this.officeLng,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['_id'],
      fullName: json['fullName'],
      email: json['email'],
      phone: json['phone'],
      role: json['role'],
      profilePic: json['profilePic'],
      createdAt: DateTime.parse(json['createdAt']),
      officeAddress: json['officeAddress']?.toString(),
      officeCity: json['officeCity']?.toString(),
      officeLat: _parseDouble(json['officeLat']),
      officeLng: _parseDouble(json['officeLng']),
    );
  }

  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  bool get hasOfficeLocation =>
      officeLat != null && officeLng != null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'role': role,
      'profilePic': profilePic,
      'createdAt': createdAt.toIso8601String(),
      'officeAddress': officeAddress,
      'officeCity': officeCity,
      'officeLat': officeLat,
      'officeLng': officeLng,
    };
  }

  User copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? role,
    String? profilePic,
    DateTime? createdAt,
    String? officeAddress,
    String? officeCity,
    double? officeLat,
    double? officeLng,
  }) {
    return User(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      profilePic: profilePic ?? this.profilePic,
      createdAt: createdAt ?? this.createdAt,
      officeAddress: officeAddress ?? this.officeAddress,
      officeCity: officeCity ?? this.officeCity,
      officeLat: officeLat ?? this.officeLat,
      officeLng: officeLng ?? this.officeLng,
    );
  }
}
