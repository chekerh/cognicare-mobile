import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

/// Site e-commerce intégré (scraping).
class IntegrationWebsite {
  final String slug;
  final String name;
  final String baseUrl;

  const IntegrationWebsite({
    required this.slug,
    required this.name,
    required this.baseUrl,
  });

  factory IntegrationWebsite.fromJson(Map<String, dynamic> json) {
    return IntegrationWebsite(
      slug: (json['slug'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      baseUrl: (json['baseUrl'] ?? '').toString(),
    );
  }
}

/// Produit du catalogue intégré (ex. Books to Scrape).
class IntegrationProduct {
  final String externalId;
  final String name;
  final String price;
  final bool availability;
  final String category;
  final String productUrl;
  final List<String> imageUrls;

  const IntegrationProduct({
    required this.externalId,
    required this.name,
    required this.price,
    required this.availability,
    required this.category,
    required this.productUrl,
    this.imageUrls = const [],
  });

  factory IntegrationProduct.fromJson(Map<String, dynamic> json) {
    final images = json['imageUrls'];
    return IntegrationProduct(
      externalId: (json['externalId'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      price: (json['price'] ?? '').toString(),
      availability: json['availability'] == true,
      category: (json['category'] ?? '').toString(),
      productUrl: (json['productUrl'] ?? '').toString(),
      imageUrls: images is List
          ? (images as List<dynamic>).map((e) => e.toString()).toList()
          : [],
    );
  }
}

/// Réponse catalogue (catégories + produits).
class IntegrationCatalogResponse {
  final List<Map<String, String>> categories;
  final List<IntegrationProduct> products;

  const IntegrationCatalogResponse({
    required this.categories,
    required this.products,
  });

  factory IntegrationCatalogResponse.fromJson(Map<String, dynamic> json) {
    final catList = json['categories'] as List<dynamic>? ?? [];
    final prodList = json['products'] as List<dynamic>? ?? [];
    return IntegrationCatalogResponse(
      categories: catList
          .map((e) => Map<String, String>.from(e as Map<dynamic, dynamic>))
          .toList(),
      products: prodList
          .map((e) => IntegrationProduct.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Service pour les catalogues e-commerce intégrés (scraping).
class IntegrationsService {
  final http.Client _client = http.Client();

  String get _base =>
      AppConstants.baseUrl.endsWith('/')
          ? AppConstants.baseUrl.substring(0, AppConstants.baseUrl.length - 1)
          : AppConstants.baseUrl;

  Future<List<IntegrationWebsite>> getWebsites() async {
    final response = await _client.get(
      Uri.parse('$_base${AppConstants.integrationsWebsitesEndpoint}'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load websites: ${response.statusCode}');
    }
    final list = jsonDecode(response.body) as List<dynamic>? ?? [];
    return list
        .map((e) => IntegrationWebsite.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<IntegrationCatalogResponse> getCatalog(
    String websiteSlug, {
    String? categorySlug,
    int page = 1,
    bool refresh = false,
  }) async {
    final uri = Uri.parse(
        '$_base${AppConstants.integrationsCatalogEndpoint(websiteSlug)}');
    final query = <String, String>{};
    if (categorySlug != null && categorySlug.isNotEmpty) {
      query['category'] = categorySlug;
    }
    if (page > 1) query['page'] = page.toString();
    if (refresh) query['refresh'] = '1';
    final url = query.isEmpty ? uri : uri.replace(queryParameters: query);
    final response = await _client.get(url);
    if (response.statusCode != 200) {
      throw Exception('Failed to load catalog: ${response.statusCode}');
    }
    return IntegrationCatalogResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
