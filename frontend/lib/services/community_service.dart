import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/community_post.dart';
import '../models/feed_comment.dart';
import '../utils/constants.dart';

/// Service pour les appels API du fil communautaire (posts, commentaires, likes).
class CommunityService {
  final http.Client _client;
  final FlutterSecureStorage _storage;

  CommunityService({
    http.Client? client,
    FlutterSecureStorage? storage,
  })  : _client = client ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage();

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

  /// Récupère tous les posts depuis le backend.
  /// Retourne la liste des posts et un map postId -> likeCount.
  Future<Map<String, dynamic>> getPostsWithLikeCounts() async {
    final response = await _client.get(
      Uri.parse('${AppConstants.baseUrl}${AppConstants.communityPostsEndpoint}'),
      headers: await _headers(),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load posts: ${response.statusCode}');
    }
    final list = jsonDecode(response.body) as List<dynamic>;
    final posts = <CommunityPost>[];
    final likeCounts = <String, int>{};
    for (final e in list) {
      final map = e as Map<String, dynamic>;
      posts.add(_postFromApi(map));
      likeCounts[map['id'] as String] = (map['likeCount'] as num?)?.toInt() ?? 0;
    }
    return {'posts': posts, 'likeCounts': likeCounts};
  }

  /// Crée un post sur le backend.
  Future<CommunityPost> createPost({
    required String authorName,
    required String authorId,
    required String text,
    String? imageUrl,
    List<String> tags = const [],
  }) async {
    final response = await _client.post(
      Uri.parse('${AppConstants.baseUrl}${AppConstants.communityPostsEndpoint}'),
      headers: await _headers(),
      body: jsonEncode({
        'text': text,
        if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
        'tags': tags,
      }),
    );
    if (response.statusCode != 201) {
      final body = response.body;
      try {
        final err = jsonDecode(body) as Map<String, dynamic>;
        throw Exception(err['message'] ?? 'Failed to create post');
      } catch (_) {
        throw Exception('Failed to create post: ${response.statusCode}');
      }
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return _postFromApi(data);
  }

  /// Upload une image pour un post. Retourne l'URL (ex. /uploads/posts/xxx.jpg).
  Future<String> uploadPostImage(File imageFile) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConstants.baseUrl}${AppConstants.communityUploadPostImageEndpoint}'),
    );
    final token = await _getToken();
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 200 && response.statusCode != 201) {
      try {
        final err = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(err['message'] ?? 'Failed to upload image');
      } catch (_) {
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['imageUrl'] as String;
  }

  /// Modifie un post (auteur uniquement).
  Future<void> updatePost(String postId, { required String text, String? imageUrl, List<String>? tags }) async {
    final body = <String, dynamic>{ 'text': text };
    if (imageUrl != null) body['imageUrl'] = imageUrl;
    if (tags != null) body['tags'] = tags;
    final response = await _client.patch(
      Uri.parse('${AppConstants.baseUrl}${AppConstants.communityPostsEndpoint}/$postId'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    if (response.statusCode == 403) throw Exception('Forbidden');
    if (response.statusCode == 404) throw Exception('Post not found');
    if (response.statusCode != 200) throw Exception('Failed to update post');
  }

  /// Supprime un post (auteur uniquement).
  Future<void> deletePost(String postId) async {
    final response = await _client.delete(
      Uri.parse('${AppConstants.baseUrl}${AppConstants.communityPostsEndpoint}/$postId'),
      headers: await _headers(),
    );
    if (response.statusCode == 403) throw Exception('Forbidden');
    if (response.statusCode == 404) throw Exception('Post not found');
    if (response.statusCode != 200) throw Exception('Failed to delete post');
  }

  /// Like / unlike un post. Retourne { liked, likeCount }.
  Future<Map<String, dynamic>> toggleLike(String postId) async {
    final response = await _client.post(
      Uri.parse('${AppConstants.baseUrl}${AppConstants.communityPostsEndpoint}/$postId/like'),
      headers: await _headers(),
    );
    if (response.statusCode != 200) throw Exception('Failed to toggle like');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Liste des commentaires d'un post.
  Future<List<FeedComment>> getComments(String postId) async {
    final response = await _client.get(
      Uri.parse('${AppConstants.baseUrl}${AppConstants.communityPostsEndpoint}/$postId/comments'),
      headers: await _headers(),
    );
    if (response.statusCode != 200) throw Exception('Failed to load comments');
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => FeedComment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Ajoute un commentaire à un post.
  Future<FeedComment> addComment(String postId, String text) async {
    final response = await _client.post(
      Uri.parse('${AppConstants.baseUrl}${AppConstants.communityPostsEndpoint}/$postId/comments'),
      headers: await _headers(),
      body: jsonEncode({'text': text}),
    );
    if (response.statusCode != 201) throw Exception('Failed to add comment');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return FeedComment.fromJson(data);
  }

  /// Statut de like par post pour l'utilisateur courant.
  Future<Map<String, bool>> getLikeStatus(List<String> postIds) async {
    if (postIds.isEmpty) return {};
    final query = postIds.join(',');
    final response = await _client.get(
      Uri.parse('${AppConstants.baseUrl}${AppConstants.communityPostLikeStatusEndpoint}?postIds=$query'),
      headers: await _headers(),
    );
    if (response.statusCode != 200) return {};
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, v as bool));
  }

  static CommunityPost _postFromApi(Map<String, dynamic> e) {
    final id = e['id'] as String;
    final createdAt = DateTime.parse(e['createdAt'] as String);
    final imageUrl = e['imageUrl'] as String?;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    return CommunityPost(
      id: id,
      authorName: e['authorName'] as String,
      authorId: e['authorId'] as String,
      text: e['text'] as String,
      createdAt: createdAt,
      hasImage: hasImage,
      imagePath: imageUrl,
      tags: (e['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }
}
