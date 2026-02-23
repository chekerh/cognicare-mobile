import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/donation.dart';
import '../utils/constants.dart';
import '../utils/cache_helper.dart';

/// Service pour les dons (Le Cercle du Don) — création et liste.
class DonationService {
  final http.Client _client = http.Client();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // In-memory cache keyed by simple filter signature.
  final Map<String, _DonationCacheEntry> _memoryCache = {};

  static const String _donationsCacheKeyPrefix = 'cache_donations_';

  String _keyForFilters({bool? isOffer, int? category, String? search}) {
    final normalizedSearch = search?.trim() ?? '';
    return '${isOffer ?? 'any'}_${category ?? 0}_$normalizedSearch';
  }

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
      Uri.parse(
          '${AppConstants.baseUrl}${AppConstants.donationsUploadImageEndpoint}'),
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
    String? suitableAge,
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
    if (suitableAge != null && suitableAge.isNotEmpty) {
      body['suitableAge'] = suitableAge;
    }
    final response = await _client.post(
      Uri.parse('${AppConstants.baseUrl}${AppConstants.donationsEndpoint}'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      String message = 'Échec: ${response.statusCode}';
      try {
        final err = jsonDecode(response.body) as Map<String, dynamic>;
        final m = err['message'];
        if (m != null) {
          if (m is List) {
            message = (m as List).map((e) => e.toString()).join(', ');
          } else {
            message = m.toString();
          }
        }
      } catch (_) {}
      throw Exception(message);
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
    final key = _keyForFilters(
      isOffer: isOffer,
      category: category,
      search: search,
    );

    // 1) Try very fresh in-memory cache first (fast navigations).
    final mem = _memoryCache[key];
    if (mem != null && mem.isFresh(const Duration(seconds: 90))) {
      return mem.items;
    }

    // 2) Try disk cache as a warm start before hitting network.
    final diskRaw = await CacheHelper.load(
      '$_donationsCacheKeyPrefix$key',
      maxAge: const Duration(minutes: 10),
    );
    if (diskRaw is List && mem == null) {
      final fromDisk = diskRaw
          .map((e) => Donation.fromJson(e as Map<String, dynamic>))
          .toList();
      _memoryCache[key] = _DonationCacheEntry(DateTime.now(), fromDisk);
      // We still continue to network below to refresh, but UI can already
      // display disk data.
    }

    final params = <String, String>{};
    if (isOffer != null) params['isOffer'] = isOffer.toString();
    if (category != null && category > 0) {
      params['category'] = category.toString();
    }
    if (search != null && search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }

    final uri =
        Uri.parse('${AppConstants.baseUrl}${AppConstants.donationsEndpoint}')
            .replace(queryParameters: params.isEmpty ? null : params);
    final response = await _client.get(uri, headers: await _headers());
    if (response.statusCode != 200) {
      throw Exception('Échec du chargement: ${response.statusCode}');
    }
    final list = jsonDecode(response.body) as List<dynamic>? ?? [];
    final parsed = list
        .map((e) => Donation.fromJson(e as Map<String, dynamic>))
        .toList();

    // 3) Update caches.
    _memoryCache[key] = _DonationCacheEntry(DateTime.now(), parsed);
    // Store raw JSON list so we don't have to re-encode models.
    await CacheHelper.save('$_donationsCacheKeyPrefix$key', list);

    return parsed;
  }
}

class _DonationCacheEntry {
  _DonationCacheEntry(this.updatedAt, this.items);

  final DateTime updatedAt;
  final List<Donation> items;

  bool isFresh(Duration ttl) =>
      DateTime.now().difference(updatedAt) < ttl;
}

