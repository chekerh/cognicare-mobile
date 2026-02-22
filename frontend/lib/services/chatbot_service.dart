import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class ChatbotMessage {
  final String role; // 'user' or 'model'
  final String content;

  ChatbotMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

class ChatbotService {
  final http.Client _client;
  final Future<String?> Function() getToken;

  ChatbotService({
    http.Client? client,
    required this.getToken,
  }) : _client = client ?? http.Client();

  /// POST /api/v1/chatbot/chat
  Future<String> sendMessage(
    String message,
    List<ChatbotMessage> history,
  ) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await _client.post(
      Uri.parse('${AppConstants.baseUrl}/api/v1/chatbot/chat'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'message': message,
        'history': history.map((h) => h.toJson()).toList(),
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      try {
        final err = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(err['message'] ?? 'Erreur chatbot');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Erreur: ${response.statusCode}');
      }
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['reply'] as String? ?? '';
  }
}
