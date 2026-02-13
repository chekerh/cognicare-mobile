import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      text: json['text'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class InboxConversation {
  final String id;
  final String name;
  final String? subtitle;
  final String lastMessage;
  final String timeAgo;
  final String imageUrl;
  final bool unread;
  final String segment;

  InboxConversation({
    required this.id,
    required this.name,
    this.subtitle,
    required this.lastMessage,
    required this.timeAgo,
    required this.imageUrl,
    this.unread = false,
    this.segment = 'persons',
  });

  factory InboxConversation.fromJson(Map<String, dynamic> json) {
    return InboxConversation(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      subtitle: json['subtitle'] as String?,
      lastMessage: json['lastMessage'] as String? ?? '',
      timeAgo: json['timeAgo'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      unread: json['unread'] as bool? ?? false,
      segment: json['segment'] as String? ?? 'persons',
    );
  }
}

class ChatService {
  final http.Client _client;
  final Future<String?> Function() getToken;

  ChatService({
    http.Client? client,
    required this.getToken,
  }) : _client = client ?? http.Client();

  Future<List<InboxConversation>> getInbox() async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');
    final uri = Uri.parse(
      '${AppConstants.baseUrl}${AppConstants.conversationsInboxEndpoint}',
    );
    final response = await _client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 200) {
      try {
        final err = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(err['message'] ?? 'Failed to load inbox');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Failed to load inbox: ${response.statusCode}');
      }
    }
    final list = jsonDecode(response.body) as List<dynamic>? ?? [];
    return list
        .map((e) => InboxConversation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get or create conversation with [otherUserId]. Returns conversation (with id and threadId).
  Future<InboxConversation> getOrCreateConversation(String otherUserId) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');
    final uri = Uri.parse(
      '${AppConstants.baseUrl}${AppConstants.conversationsByParticipantEndpoint}/$otherUserId',
    );
    final response = await _client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 200) {
      try {
        final err = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(err['message'] ?? 'Failed to get conversation');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Failed to get conversation: ${response.statusCode}');
      }
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return InboxConversation.fromJson(json);
  }

  Future<List<ChatMessage>> getMessages(String conversationId) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');
    final uri = Uri.parse(
      '${AppConstants.baseUrl}${AppConstants.conversationsMessagesEndpoint(conversationId)}',
    );
    final response = await _client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 200) {
      try {
        final err = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(err['message'] ?? 'Failed to load messages');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Failed to load messages: ${response.statusCode}');
      }
    }
    final list = jsonDecode(response.body) as List<dynamic>? ?? [];
    return list
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ChatMessage> sendMessage(String conversationId, String text) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');
    final uri = Uri.parse(
      '${AppConstants.baseUrl}${AppConstants.conversationsMessagesEndpoint(conversationId)}',
    );
    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'text': text}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      try {
        final err = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(err['message'] ?? 'Failed to send message');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return ChatMessage.fromJson(json);
  }

  Future<void> deleteConversation(String conversationId) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');
    final uri = Uri.parse(
      '${AppConstants.baseUrl}/api/v1/conversations/$conversationId',
    );
    final response = await _client.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      try {
        final err = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(err['message'] ?? 'Failed to delete conversation');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Failed to delete conversation: ${response.statusCode}');
      }
    }
  }
}
