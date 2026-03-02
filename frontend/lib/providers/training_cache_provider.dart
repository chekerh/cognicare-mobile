import 'package:flutter/material.dart';
import '../services/training_service.dart';
import '../utils/cache_helper.dart';

/// Cache keys for training data.
const String _keyCourses = 'training_courses';
const String _keyEnrollments = 'training_enrollments';
const String _keyNextCourse = 'training_next_course';
const String _keyCoursePrefix = 'training_course_';

/// TTL for cached data.
const Duration _ttlCourses = Duration(minutes: 15);
const Duration _ttlEnrollments = Duration(minutes: 5);
const Duration _ttlNextCourse = Duration(minutes: 5);
const Duration _ttlCourseDetail = Duration(minutes: 15);

/// Provider for training data with in-memory + persistent cache.
/// Uses [CacheHelper] (SharedPreferences) and [TrainingService] for API.
/// Notifies listeners when data is loaded or refreshed.
class TrainingCacheProvider with ChangeNotifier {
  final TrainingService _service = TrainingService();

  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _enrollments = [];
  String? _nextCourseId;
  final Map<String, Map<String, dynamic>> _courseById = {};
  bool _loading = false;
  String? _error;

  List<Map<String, dynamic>> get courses => List.unmodifiable(_courses);
  List<Map<String, dynamic>> get enrollments => List.unmodifiable(_enrollments);
  String? get nextCourseId => _nextCourseId;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoaded => _courses.isNotEmpty || _error != null;

  /// Get a single course from memory cache (no disk/API).
  Map<String, dynamic>? getCachedCourse(String courseId) => _courseById[courseId];

  /// Load list + enrollments + next course. Uses cache first, then API.
  /// [forceRefresh] ignores cache and fetches from API.
  Future<void> load({bool forceRefresh = false}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      if (!forceRefresh) {
        final cachedCourses = await CacheHelper.load(_keyCourses, maxAge: _ttlCourses);
        final cachedEnrollments = await CacheHelper.load(_keyEnrollments, maxAge: _ttlEnrollments);
        final cachedNext = await CacheHelper.load(_keyNextCourse, maxAge: _ttlNextCourse);
        if (cachedCourses is List<dynamic> &&
            cachedCourses.isNotEmpty &&
            cachedEnrollments is List<dynamic>) {
          _courses = cachedCourses.whereType<Map<String, dynamic>>().toList();
          _enrollments = cachedEnrollments.whereType<Map<String, dynamic>>().toList();
          final next = cachedNext?.toString();
          _nextCourseId = (next == null || next.isEmpty) ? null : next;
          _loading = false;
          notifyListeners();
          // Refresh in background
          _fetchAndCache();
          return;
        }
      }

      await _fetchAndCache();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      // Try cache on error so user still sees something
      final cachedCourses = await CacheHelper.load(_keyCourses);
      final cachedEnrollments = await CacheHelper.load(_keyEnrollments);
      final cachedNext = await CacheHelper.load(_keyNextCourse);
      if (cachedCourses is List<dynamic> && cachedCourses.isNotEmpty) {
        _courses = cachedCourses.whereType<Map<String, dynamic>>().toList();
        _enrollments = cachedEnrollments is List<dynamic>
            ? cachedEnrollments.whereType<Map<String, dynamic>>().toList()
            : [];
        final next = cachedNext?.toString();
        _nextCourseId = (next == null || next.isEmpty) ? null : next;
      }
      notifyListeners();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchAndCache() async {
    final results = await Future.wait([
      _service.getCourses(),
      _service.myEnrollments(),
      _service.getNextCourseId(),
    ]);
    _courses = (results[0] as List<dynamic>).whereType<Map<String, dynamic>>().toList();
    _enrollments = (results[1] as List<dynamic>).whereType<Map<String, dynamic>>().toList();
    _nextCourseId = results[2] as String?;

    await Future.wait([
      CacheHelper.save(_keyCourses, _courses),
      CacheHelper.save(_keyEnrollments, _enrollments),
      CacheHelper.save(_keyNextCourse, _nextCourseId ?? ''),
    ]);
    _error = null;
    notifyListeners();
  }

  /// Load a single course by id. Uses memory cache, then disk cache, then API.
  Future<Map<String, dynamic>> getCourse(String courseId, {bool forceRefresh = false}) async {
    if (!forceRefresh && _courseById.containsKey(courseId)) {
      return _courseById[courseId]!;
    }
    final cacheKey = '$_keyCoursePrefix$courseId';
    if (!forceRefresh) {
      final cached = await CacheHelper.load(cacheKey, maxAge: _ttlCourseDetail);
      if (cached is Map<String, dynamic>) {
        _courseById[courseId] = cached;
        notifyListeners();
        return cached;
      }
    }
    final course = await _service.getCourse(courseId);
    _courseById[courseId] = course;
    await CacheHelper.save(cacheKey, course);
    notifyListeners();
    return course;
  }

  /// Invalidate enrollments after quiz completion / enrollment so next load refetches.
  Future<void> invalidateEnrollments() async {
    await CacheHelper.clear(_keyEnrollments);
    await CacheHelper.clear(_keyNextCourse);
    _enrollments = [];
    _nextCourseId = null;
    notifyListeners();
  }

  /// Clear all training cache (e.g. on logout).
  Future<void> clearCache() async {
    await CacheHelper.clear(_keyCourses);
    await CacheHelper.clear(_keyEnrollments);
    await CacheHelper.clear(_keyNextCourse);
    for (final id in _courseById.keys) {
      await CacheHelper.clear('$_keyCoursePrefix$id');
    }
    _courses = [];
    _enrollments = [];
    _nextCourseId = null;
    _courseById.clear();
    _error = null;
    notifyListeners();
  }
}
