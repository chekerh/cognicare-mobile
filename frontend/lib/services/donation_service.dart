import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/donation.dart';
import '../utils/constants.dart';

/// Service pour les dons (Le Cercle du Don) — création et liste.
class DonationService {
  final http.Client _client = http.Client();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> _getToken() async {
    return _storage.read(key: AppConstants.jwtTokenKey);
  }

  Future<Map<String, String>> _headers() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Upload une image pour un don. Retourne l'URL.
  Future<String> uploadImage(File imageFile) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConstants.baseUrl}${AppConstants.donationsUploadImageEndpoint}'),
    );
    final token = await _getToken();
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath(
      'file',
      imageFile.path,
      contentType: MediaType('image', 'jpeg'),
    ));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 200 && response.statusCode != 201) {
      try {
        final err = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(err['message'] ?? 'Échec de l\'upload de l\'image');
      } catch (_) {
        throw Exception('Échec de l\'upload: ${response.statusCode}');
      }
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['imageUrl'] as String;
  }

  /// Crée un don.
  Future<Donation> createDonation({
    required String title,
    required String description,
    required int category,
    required int condition,
    required String location,
    required List<String> imageUrls,
    bool isOffer = true,
    double? latitude,
    double? longitude,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'description': description,
      'category': category,
      'condition': condition,
      'location': location,
      'imageUrls': imageUrls,
      'isOffer': isOffer,
    };
    if (latitude != null && longitude != null) {
      body['latitude'] = latitude;
      body['longitude'] = longitude;
    }
    final response = await _client.post(
      Uri.parse('${AppConstants.baseUrl}${AppConstants.donationsEndpoint}'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      try {
        final err = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(err['message'] ?? 'Échec de la création du don');
      } catch (_) {
        throw Exception('Échec: ${response.statusCode}');
      }
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return Donation.fromJson(data);
  }

  /// Liste les dons avec filtres.
  Future<List<Donation>> getDonations({
    bool? isOffer,
    int? category,
    String? search,
  }) async {
    final params = <String, String>{};
    if (isOffer != null) params['isOffer'] = isOffer.toString();
    if (category != null && category > 0) params['category'] = category.toString();
    if (search != null && search.trim().isNotEmpty) params['search'] = search.trim();

    final uri = Uri.parse('${AppConstants.baseUrl}${AppConstants.donationsEndpoint}')
        .replace(queryParameters: params.isEmpty ? null : params);
    final response = await _client.get(uri, headers: await _headers());
    if (response.statusCode != 200) {
      throw Exception('Échec du chargement: ${response.statusCode}');
    }
    final list = jsonDecode(response.body) as List<dynamic>? ?? [];
    return list
        .map((e) => Donation.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
