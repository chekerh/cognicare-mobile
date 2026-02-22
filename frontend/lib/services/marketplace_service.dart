import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/marketplace_product.dart';
import '../models/product_review.dart';
import '../utils/constants.dart';

/// Service pour les produits du marketplace (secteur famille).
class MarketplaceService {
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

  /// Liste les produits (limit par défaut 6 pour la section feed).
  Future<List<MarketplaceProduct>> getProducts(
      {int limit = 6, String? category}) async {
    final query = <String, String>{'limit': limit.toString()};
    if (category != null && category != 'all') query['category'] = category;
    final uri = Uri.parse(
            '${AppConstants.baseUrl}${AppConstants.marketplaceProductsEndpoint}')
        .replace(queryParameters: query);
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to load products: ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final list = body['products'] as List<dynamic>? ?? [];
    return list
        .map((e) => MarketplaceProduct.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Liste uniquement les produits ajoutés par l'utilisateur connecté (JWT requis).
  Future<List<MarketplaceProduct>> getMyProducts(
      {int limit = 50, String? category}) async {
    final query = <String, String>{'limit': limit.toString()};
    if (category != null && category != 'all') query['category'] = category;
    final uri = Uri.parse(
            '${AppConstants.baseUrl}${AppConstants.marketplaceMyProductsEndpoint}')
        .replace(queryParameters: query);
    final response = await _client.get(uri, headers: await _headers());
    if (response.statusCode != 200) {
      throw Exception('Failed to load my products: ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final list = body['products'] as List<dynamic>? ?? [];
    return list
        .map((e) => MarketplaceProduct.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Liste les avis d'un produit.
  Future<List<ProductReview>> getReviews(String productId) async {
    final uri = Uri.parse(
      '${AppConstants.baseUrl}${AppConstants.marketplaceProductReviewsEndpoint(productId)}',
    );
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      return [];
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final list = body['reviews'] as List<dynamic>? ?? [];
    return list
        .map((e) => ProductReview.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Ajoute ou met à jour mon avis sur un produit (JWT requis).
  Future<ProductReview> createReview({
    required String productId,
    required int rating,
    String comment = '',
  }) async {
    final uri = Uri.parse(
      '${AppConstants.baseUrl}${AppConstants.marketplaceProductReviewsEndpoint(productId)}',
    );
    final response = await _client.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({'rating': rating, 'comment': comment}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      String message = 'Échec: ${response.statusCode}';
      try {
        final err = jsonDecode(response.body) as Map<String, dynamic>;
        final m = err['message'];
        if (m != null) message = m.toString();
      } catch (_) {}
      throw Exception(message);
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return ProductReview.fromJson(data);
  }

  /// Récupère un produit par ID.
  Future<MarketplaceProduct> getProductById(String id) async {
    final uri = Uri.parse(
        '${AppConstants.baseUrl}${AppConstants.marketplaceProductByIdEndpoint(id)}');
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      if (response.statusCode == 404) {
        throw Exception('Produit non trouvé');
      }
      throw Exception('Échec du chargement: ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return MarketplaceProduct.fromJson(body);
  }

  /// Upload une image pour un produit. Retourne l'URL.
  Future<String> uploadImage(File imageFile) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
          '${AppConstants.baseUrl}${AppConstants.marketplaceUploadImageEndpoint}'),
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

  /// Crée un produit (vente par l'utilisateur).
  Future<MarketplaceProduct> createProduct({
    required String title,
    required String price,
    required String imageUrl,
    String description = '',
    String? badge,
    String category = 'all',
    int order = 0,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'price': price,
      'imageUrl': imageUrl,
      'description': description,
      'category': category,
      'order': order,
    };
    if (badge != null && badge.isNotEmpty) body['badge'] = badge;
    final response = await _client.post(
      Uri.parse(
          '${AppConstants.baseUrl}${AppConstants.marketplaceProductsEndpoint}'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      String message = 'Échec: ${response.statusCode}';
      try {
        final err = jsonDecode(response.body) as Map<String, dynamic>;
        final m = err['message'];
        if (m != null) message = m.toString();
      } catch (_) {}
      throw Exception(message);
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return MarketplaceProduct.fromJson(data);
  }
}
