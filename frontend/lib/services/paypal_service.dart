import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

/// Service pour créer une commande PayPal et vérifier son statut.
class PaypalService {
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

  /// Crée une commande PayPal. Retourne orderId et l'URL d'approbation à ouvrir dans le navigateur.
  Future<PaypalOrderResult> createOrder({
    required String amount,
    String currencyCode = 'USD',
  }) async {
    final uri = Uri.parse(
        '${AppConstants.baseUrl}${AppConstants.paypalCreateOrderEndpoint}');
    final response = await _client.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({
        'amount': amount,
        'currencyCode': currencyCode,
      }),
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
    return PaypalOrderResult(
      orderId: data['orderId'] as String,
      approvalUrl: data['approvalUrl'] as String,
    );
  }

  /// Vérifie le statut d'une commande (COMPLETED = paiement reçu).
  Future<PaypalOrderStatus> getOrderStatus(String orderId) async {
    final uri = Uri.parse(
      '${AppConstants.baseUrl}${AppConstants.paypalOrderStatusEndpoint(orderId)}',
    );
    final response = await _client.get(uri, headers: await _headers());
    if (response.statusCode != 200) {
      throw Exception('Échec: ${response.statusCode}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return PaypalOrderStatus(
      orderId: data['orderId'] as String? ?? orderId,
      status: data['status'] as String? ?? 'UNKNOWN',
    );
  }
}

class PaypalOrderResult {
  final String orderId;
  final String approvalUrl;

  PaypalOrderResult({required this.orderId, required this.approvalUrl});
}

class PaypalOrderStatus {
  final String orderId;
  final String status;

  PaypalOrderStatus({required this.orderId, required this.status});
}
