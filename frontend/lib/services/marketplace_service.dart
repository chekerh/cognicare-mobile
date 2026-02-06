import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/marketplace_product.dart';
import '../utils/constants.dart';

/// Service pour les produits du marketplace (secteur famille).
class MarketplaceService {
  final http.Client _client = http.Client();

  /// Liste les produits (limit par défaut 6 pour la section feed).
  Future<List<MarketplaceProduct>> getProducts({int limit = 6, String? category}) async {
    final query = <String, String>{'limit': limit.toString()};
    if (category != null && category != 'all') query['category'] = category;
    final uri = Uri.parse('${AppConstants.baseUrl}${AppConstants.marketplaceProductsEndpoint}')
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
}
