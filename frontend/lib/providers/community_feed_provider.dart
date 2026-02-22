import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/community_post.dart';
import '../models/feed_comment.dart';
import '../services/community_service.dart';

const String _storageFileName = 'cognicare_feed.json';

/// Vrai seulement pour les IDs de posts venant du backend (MongoDB ObjectId 24 hex).
bool _isBackendPostId(String id) =>
    id.length == 24 &&
    RegExp(r'^[a-f0-9]{24}$', caseSensitive: false).hasMatch(id);

/// Provider du fil communautaire : posts, commentaires, likes.
/// Utilise le backend en priorité (données persistées), repli sur stockage local si pas de token ou erreur.
class CommunityFeedProvider with ChangeNotifier {
  final List<CommunityPost> _posts = [];
  final Map<String, bool> _postLiked = {};
  final Map<String, int> _postLikeCount = {};
  final Map<String, List<FeedComment>> _postComments = {};
  bool _loaded = false;
  bool _useBackend = false;
  final CommunityService _api = CommunityService();

  List<CommunityPost> get posts => List.unmodifiable(_posts);
  bool get isLoaded => _loaded;

  bool isLiked(String postId) => _postLiked[postId] ?? false;
  int getLikeCount(String postId) => _postLikeCount[postId] ?? 0;
  List<FeedComment> getComments(String postId) =>
      List.unmodifiable(_postComments[postId] ?? []);

  Future<File> _getStorageFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_storageFileName');
  }

  /// Charge le fil : essaie le backend d'abord, sinon stockage local.
  Future<void> loadFromStorage() async {
    if (_loaded) return;
    _useBackend = false;
    try {
      final result = await _api.getPostsWithLikeCounts();
      final posts = result['posts'] as List<CommunityPost>;
      final likeCounts = result['likeCounts'] as Map<String, int>;
      _posts.clear();
      _posts.addAll(posts);
      _postLikeCount.clear();
      for (final entry in likeCounts.entries) {
        _postLikeCount[entry.key] = entry.value;
      }
      final postIds = _posts.map((p) => p.id).toList();
      final status = await _api.getLikeStatus(postIds);
      _postLiked.clear();
      for (final p in _posts) {
        _postLiked[p.id] = status[p.id] ?? false;
      }
      _postComments.clear();
      _useBackend = true;
    } catch (_) {
      // Pas de token ou erreur API : charger depuis le stockage local
    }
    if (!_useBackend) await _loadLocal();
    _loaded = true;
    notifyListeners();
  }

  Future<void> _loadLocal() async {
    try {
      final file = await _getStorageFile();
      if (!await file.exists()) return;
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final postsList = json['posts'] as List<dynamic>?;
      if (postsList != null) {
        _posts.clear();
        for (final e in postsList) {
          var post = CommunityPost.fromJson(e as Map<String, dynamic>);
          if (post.hasImage && post.imagePath != null) {
            final f = File(post.imagePath!);
            if (!f.existsSync()) {
              post = CommunityPost(
                id: post.id,
                authorName: post.authorName,
                authorId: post.authorId,
                text: post.text,
                createdAt: post.createdAt,
                hasImage: false,
                imagePath: null,
                tags: post.tags,
              );
            }
          }
          _posts.add(post);
        }
      }
      final likedMap = json['liked'] as Map<String, dynamic>?;
      if (likedMap != null) {
        _postLiked.clear();
        for (final e in likedMap.entries) {
          _postLiked[e.key] = e.value as bool;
        }
      }
      final countMap = json['likeCount'] as Map<String, dynamic>?;
      if (countMap != null) {
        _postLikeCount.clear();
        for (final e in countMap.entries) {
          _postLikeCount[e.key] = (e.value as num).toInt();
        }
      }
      final commentsMap = json['comments'] as Map<String, dynamic>?;
      if (commentsMap != null) {
        _postComments.clear();
        for (final e in commentsMap.entries) {
          final list = (e.value as List<dynamic>)
              .map((c) => FeedComment.fromJson(c as Map<String, dynamic>))
              .toList();
          _postComments[e.key] = list;
        }
      }
    } catch (_) {}
  }

  Future<void> _saveToStorage() async {
    try {
      final file = await _getStorageFile();
      final map = <String, dynamic>{
        'posts': _posts.map((p) => p.toJson()).toList(),
        'liked': _postLiked,
        'likeCount': _postLikeCount,
        'comments': _postComments.map(
          (k, v) => MapEntry(k, v.map((c) => c.toJson()).toList()),
        ),
      };
      await file.writeAsString(jsonEncode(map));
    } catch (_) {}
  }

  /// Charge les commentaires d'un post depuis l'API (si backend) et met en cache.
  Future<void> loadCommentsForPost(String postId) async {
    if (_useBackend && _isBackendPostId(postId)) {
      try {
        final list = await _api.getComments(postId);
        _postComments[postId] = list;
        notifyListeners();
      } catch (_) {}
    }
  }

  void toggleLike(String postId) async {
    if (_useBackend && _isBackendPostId(postId)) {
      try {
        final result = await _api.toggleLike(postId);
        _postLiked[postId] = result['liked'] as bool;
        _postLikeCount[postId] = (result['likeCount'] as num).toInt();
        notifyListeners();
        return;
      } catch (_) {}
    }
    final liked = _postLiked[postId] ?? false;
    final count = _postLikeCount[postId] ?? 0;
    _postLiked[postId] = !liked;
    _postLikeCount[postId] = count + (liked ? -1 : 1);
    notifyListeners();
    _saveToStorage();
  }

  void addComment(String postId, String authorName, String text) async {
    if (_useBackend && _isBackendPostId(postId)) {
      try {
        final comment = await _api.addComment(postId, text.trim());
        _postComments[postId] ??= [];
        _postComments[postId]!.insert(0, comment);
        notifyListeners();
        return;
      } catch (_) {}
    }
    _postComments[postId] ??= [];
    _postComments[postId]!.insert(
      0,
      FeedComment(
          authorName: authorName, text: text.trim(), createdAt: DateTime.now()),
    );
    notifyListeners();
    _saveToStorage();
  }

  Future<void> updatePost(String postId, String newText) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;
    final post = _posts[index];
    final updated = CommunityPost(
      id: post.id,
      authorName: post.authorName,
      authorId: post.authorId,
      text: newText,
      createdAt: post.createdAt,
      hasImage: post.hasImage,
      imagePath: post.imagePath,
      tags: post.tags,
    );
    if (_useBackend && _isBackendPostId(postId)) {
      try {
        await _api.updatePost(postId, text: newText);
        _posts[index] = updated;
        notifyListeners();
        return;
      } catch (_) {
        rethrow;
      }
    }
    _posts[index] = updated;
    await _saveToStorage();
    notifyListeners();
  }

  Future<void> deletePost(String postId) async {
    if (_useBackend && _isBackendPostId(postId)) {
      try {
        await _api.deletePost(postId);
        _removePostLocal(postId);
        notifyListeners();
        return;
      } catch (_) {
        rethrow;
      }
    }
    _removePostLocal(postId);
    await _saveToStorage();
    notifyListeners();
  }

  void _removePostLocal(String postId) {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;
    final post = _posts[index];
    if (post.imagePath != null && post.imagePath!.isNotEmpty) {
      try {
        final file = File(post.imagePath!);
        if (file.existsSync()) file.deleteSync();
      } catch (_) {}
    }
    _posts.removeAt(index);
    _postLiked.remove(postId);
    _postLikeCount.remove(postId);
    _postComments.remove(postId);
  }

  Future<void> addPost({
    required String authorName,
    required String authorId,
    required String text,
    String? imagePath,
    List<String> tags = const [],
  }) async {
    if (_useBackend) {
      try {
        String? imageUrl;
        if (imagePath != null && imagePath.isNotEmpty) {
          final file = File(imagePath);
          if (await file.exists()) {
            imageUrl = await _api.uploadPostImage(file);
          } else {
            throw Exception(
                'Image file not found. Try selecting the image again.');
          }
        }
        final post = await _api.createPost(
          authorName: authorName,
          authorId: authorId,
          text: text.trim(),
          imageUrl: imageUrl,
          tags: tags,
        );
        _posts.insert(0, post);
        _postLikeCount[post.id] = 0;
        _postLiked[post.id] = false;
        notifyListeners();
        return;
      } catch (_) {
        rethrow;
      }
    }
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    String? persistentImagePath;
    if (imagePath != null && imagePath.isNotEmpty) {
      try {
        final file = File(imagePath);
        if (await file.exists()) {
          final dir = await getApplicationDocumentsDirectory();
          final postImagesDir = Directory('${dir.path}/post_images');
          if (!await postImagesDir.exists()) {
            await postImagesDir.create(recursive: true);
          }
          final dest = File('${postImagesDir.path}/$id.jpg');
          await file.copy(dest.path);
          if (await dest.exists()) persistentImagePath = dest.path;
        }
      } catch (_) {}
    }
    final post = CommunityPost(
      id: id,
      authorName: authorName,
      authorId: authorId,
      text: text.trim(),
      createdAt: DateTime.now(),
      hasImage: persistentImagePath != null && persistentImagePath.isNotEmpty,
      imagePath: persistentImagePath,
      tags: tags,
    );
    _posts.insert(0, post);
    _postLikeCount[id] = 0;
    notifyListeners();
    await _saveToStorage();
  }
}
