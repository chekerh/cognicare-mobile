import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/community_post.dart';
import '../models/feed_comment.dart';

const String _storageFileName = 'cognicare_feed.json';

/// Provider du fil communautaire : posts, likes, commentaires + persistance locale.
class CommunityFeedProvider with ChangeNotifier {
  final List<CommunityPost> _posts = [];
  final Map<String, bool> _postLiked = {};
  final Map<String, int> _postLikeCount = {};
  final Map<String, List<FeedComment>> _postComments = {};
  bool _loaded = false;

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

  /// Charge les posts, likes et commentaires depuis le stockage local.
  Future<void> loadFromStorage() async {
    if (_loaded) return;
    try {
      final file = await _getStorageFile();
      if (!await file.exists()) {
        _loaded = true;
        notifyListeners();
        return;
      }
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;

      final postsList = json['posts'] as List<dynamic>?;
      if (postsList != null) {
        _posts.clear();
        for (final e in postsList) {
          var post = CommunityPost.fromJson(e as Map<String, dynamic>);
          // Si l'image était sur un chemin temporaire ou supprimé, ne pas garder le chemin
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
    } catch (_) {
      // Fichier absent ou corrompu : on garde l’état vide
    }
    _loaded = true;
    notifyListeners();
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

  void toggleLike(String postId) {
    final liked = _postLiked[postId] ?? false;
    final count = _postLikeCount[postId] ?? 0;
    _postLiked[postId] = !liked;
    _postLikeCount[postId] = count + (liked ? -1 : 1);
    notifyListeners();
    _saveToStorage();
  }

  void addComment(String postId, String authorName, String text) {
    _postComments[postId] ??= [];
    _postComments[postId]!.insert(
      0,
      FeedComment(authorName: authorName, text: text.trim(), createdAt: DateTime.now()),
    );
    notifyListeners();
    _saveToStorage();
  }

  /// Supprime un post et ses données associées (likes, commentaires, image locale).
  Future<void> deletePost(String postId) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = _posts[index];

    // Supprimer l'image locale si elle existe
    if (post.imagePath != null && post.imagePath!.isNotEmpty) {
      try {
        final file = File(post.imagePath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }

    _posts.removeAt(index);
    _postLiked.remove(postId);
    _postLikeCount.remove(postId);
    _postComments.remove(postId);

    notifyListeners();
    await _saveToStorage();
  }

  Future<void> addPost({
    required String authorName,
    required String authorId,
    required String text,
    String? imagePath,
    List<String> tags = const [],
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    String? persistentImagePath;
    if (imagePath != null && imagePath.isNotEmpty) {
      try {
        final file = File(imagePath);
        if (await file.exists()) {
          final dir = await getApplicationDocumentsDirectory();
          final postImagesDir = Directory('${dir.path}/post_images');
          if (!await postImagesDir.exists()) await postImagesDir.create(recursive: true);
          final dest = File('${postImagesDir.path}/$id.jpg');
          await file.copy(dest.path);
          if (await dest.exists()) persistentImagePath = dest.path;
        }
      } catch (_) {
        // Ne pas garder le chemin temporaire : il serait supprimé et la photo "disparaît"
        persistentImagePath = null;
      }
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
