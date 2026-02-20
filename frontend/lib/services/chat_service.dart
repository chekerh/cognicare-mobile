import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime createdAt;
  final String? attachmentUrl;
  final String? attachmentType;
  final int? callDuration;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.attachmentUrl,
    this.attachmentType,
    this.callDuration,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      text: json['text'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      attachmentUrl: json['attachmentUrl'] as String?,
      attachmentType: json['attachmentType'] as String?,
      callDuration: json['callDuration'] as int?,
    );
  }
}

class InboxConversation {
  final String id;
  /// ID de l'autre participant (pour appels, ex. famille pour un bénévole).
  final String? otherUserId;
  final String name;
  final String? subtitle;
  final String lastMessage;
  final String timeAgo;
  final String imageUrl;
  final bool unread;
  final String segment;
  final bool isGroup;
  final List<String> participantIds;

  InboxConversation({
    required this.id,
    this.otherUserId,
    required this.name,
    this.subtitle,
    required this.lastMessage,
    required this.timeAgo,
    required this.imageUrl,
    this.unread = false,
    this.segment = 'persons',
    this.isGroup = false,
    this.participantIds = const [],
  });

  factory InboxConversation.fromJson(Map<String, dynamic> json) {
    final participantIdsRaw = json['participantIds'];
    final participantIds = participantIdsRaw is List
        ? (participantIdsRaw).map((e) => e.toString()).toList()
        : <String>[];
    return InboxConversation(
      id: json['id'] as String? ?? '',
      otherUserId: json['otherUserId'] as String?,
      name: json['name'] as String? ?? '',
      subtitle: json['subtitle'] as String?,
      lastMessage: json['lastMessage'] as String? ?? '',
      timeAgo: json['timeAgo'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      unread: json['unread'] as bool? ?? false,
      segment: json['segment'] as String? ?? 'persons',
      isGroup: json['isGroup'] as bool? ?? false,
      participantIds: participantIds,
    );
  }
}

/// Famille affichée dans l'onglet Families pour démarrer une conversation.
class FamilyUser {
  final String id;
  final String fullName;
  final String? profilePic;

  FamilyUser({required this.id, required this.fullName, this.profilePic});

  factory FamilyUser.fromJson(Map<String, dynamic> json) {
    return FamilyUser(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      profilePic: json['profilePic'] as String?,
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

  /// Liste des autres familles avec qui l'utilisateur peut ouvrir une conversation.
  Future<List<FamilyUser>> getFamiliesToContact() async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');
    final uri = Uri.parse(
      '${AppConstants.baseUrl}${AppConstants.usersFamiliesEndpoint}',
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
        throw Exception(err['message'] ?? 'Failed to load families');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Failed to load families: ${response.statusCode}');
      }
    }
    final list = jsonDecode(response.body) as List<dynamic>? ?? [];
    return list
        .map((e) => FamilyUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

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

  /// Upload attachment (image or voice). Returns the URL to use in sendMessage.
  Future<String> uploadAttachment(File file, String type) async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    }
    final uri = Uri.parse(
      '${AppConstants.baseUrl}${AppConstants.conversationsUploadEndpoint}',
    );
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    request.fields['type'] = type;
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode == 401) {
      throw Exception('Unauthorized');
    }
    if (response.statusCode != 200 && response.statusCode != 201) {
      try {
        final err = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(err['message'] ?? 'Upload failed');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Upload failed: ${response.statusCode}');
      }
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final url = json['url'] as String?;
    if (url == null || url.isEmpty) throw Exception('No URL returned');
    return url;
  }

  Future<ChatMessage> sendMessage(
    String conversationId,
    String text, {
    String? attachmentUrl,
    String? attachmentType,
    int? callDuration,
  }) async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    }
    final uri = Uri.parse(
      '${AppConstants.baseUrl}${AppConstants.conversationsMessagesEndpoint(conversationId)}',
    );
    final body = <String, dynamic>{'text': text};
    if (attachmentUrl != null) body['attachmentUrl'] = attachmentUrl;
    if (attachmentType != null) body['attachmentType'] = attachmentType;
    if (callDuration != null) body['callDuration'] = callDuration;
    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode == 401) throw Exception('Unauthorized');
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

  /// Create a group conversation (e.g. family group). Returns the new conversation.
  Future<Map<String, dynamic>> createGroup(
    String name,
    List<String> participantIds,
  ) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');
    final uri = Uri.parse(
      '${AppConstants.baseUrl}/api/v1/conversations/groups',
    );
    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'name': name, 'participantIds': participantIds}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      try {
        final err = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(err['message'] ?? 'Failed to create group');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Failed to create group: ${response.statusCode}');
      }
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return Map<String, dynamic>.from(json);
  }

  /// Add a member to a group conversation.
  Future<void> addMemberToGroup(
    String conversationId,
    String userId,
  ) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');
    final uri = Uri.parse(
      '${AppConstants.baseUrl}/api/v1/conversations/$conversationId/members',
    );
    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'userId': userId}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      try {
        final err = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(err['message'] ?? 'Failed to add member');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Failed to add member: ${response.statusCode}');
      }
    }
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

  /// Get conversation settings (autoSavePhotos, muted) from API.
  Future<Map<String, dynamic>> getConversationSettings(String conversationId) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');
    final uri = Uri.parse(
      '${AppConstants.baseUrl}${AppConstants.conversationsSettingsEndpoint(conversationId)}',
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
        throw Exception(err['message'] ?? 'Failed to load settings');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Failed to load settings: ${response.statusCode}');
      }
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Update conversation settings (autoSavePhotos, muted).
  Future<Map<String, dynamic>> updateConversationSettings(
    String conversationId, {
    bool? autoSavePhotos,
    bool? muted,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');
    final uri = Uri.parse(
      '${AppConstants.baseUrl}${AppConstants.conversationsSettingsEndpoint(conversationId)}',
    );
    final body = <String, dynamic>{};
    if (autoSavePhotos != null) body['autoSavePhotos'] = autoSavePhotos;
    if (muted != null) body['muted'] = muted;
    final response = await _client.patch(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) {
      try {
        final err = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(err['message'] ?? 'Failed to update settings');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Failed to update settings: ${response.statusCode}');
      }
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Get media (images, voice) shared in the conversation.
  Future<List<Map<String, dynamic>>> getConversationMedia(String conversationId) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');
    final uri = Uri.parse(
      '${AppConstants.baseUrl}${AppConstants.conversationsMediaEndpoint(conversationId)}',
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
        throw Exception(err['message'] ?? 'Failed to load media');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Failed to load media: ${response.statusCode}');
      }
    }
    final list = jsonDecode(response.body) as List<dynamic>? ?? [];
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  /// Search messages in conversation.
  Future<List<Map<String, dynamic>>> searchConversationMessages(
    String conversationId,
    String query,
  ) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');
    final uri = Uri.parse(
      '${AppConstants.baseUrl}${AppConstants.conversationsSearchEndpoint(conversationId, query)}',
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
        throw Exception(err['message'] ?? 'Failed to search');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Failed to search: ${response.statusCode}');
      }
    }
    final list = jsonDecode(response.body) as List<dynamic>? ?? [];
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  /// Block a user (store in MongoDB).
  Future<void> blockUser(String targetUserId) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');
    final uri = Uri.parse(
      '${AppConstants.baseUrl}${AppConstants.usersMeBlockEndpoint}',
    );
    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'userId': targetUserId}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      try {
        final err = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(err['message'] ?? 'Failed to block user');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Failed to block user: ${response.statusCode}');
      }
    }
  }

  /// Get list of blocked user IDs.
  Future<List<String>> getBlockedUserIds() async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');
    final uri = Uri.parse(
      '${AppConstants.baseUrl}${AppConstants.usersMeBlockedEndpoint}',
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
        throw Exception(err['message'] ?? 'Failed to load blocked list');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Failed to load blocked list: ${response.statusCode}');
      }
    }
    final list = jsonDecode(response.body) as List<dynamic>? ?? [];
    return list.map((e) => e.toString()).toList();
  }
}
