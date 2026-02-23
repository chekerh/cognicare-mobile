import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Small helper around [SharedPreferences] to cache JSON-serializable data
/// with a timestamp and optional TTL.
class CacheHelper {
  const CacheHelper._();

  static const String _updatedAtKey = 'updatedAt';
  static const String _dataKey = 'data';

  /// Save any JSON-serializable [value] under [key].
  ///
  /// The value will be wrapped in an envelope that stores the current time
  /// under the [_updatedAtKey] field so we can later enforce TTLs.
  static Future<void> save(String key, Object value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final envelope = <String, Object?>{
        _updatedAtKey: DateTime.now().toIso8601String(),
        _dataKey: value,
      };
      await prefs.setString(key, jsonEncode(envelope));
    } catch (_) {
      // Silently ignore cache write failures.
    }
  }

  /// Load previously cached data for [key].
  ///
  /// If the value was stored via [save], this will:
  /// - check the [_updatedAtKey] timestamp
  /// - enforce [maxAge] if provided
  /// - return only the wrapped [_dataKey] field
  ///
  /// If the stored value is not in envelope form (legacy cache), it will be
  /// returned directly without TTL enforcement.
  static Future<Object?> load(
    String key, {
    Duration? maxAge,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null) return null;

      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic> &&
          decoded.containsKey(_updatedAtKey) &&
          decoded.containsKey(_dataKey)) {
        final ts = DateTime.tryParse(
          decoded[_updatedAtKey]?.toString() ?? '',
        );
        if (maxAge != null && ts != null) {
          final age = DateTime.now().difference(ts);
          if (age > maxAge) return null;
        }
        return decoded[_dataKey];
      }

      // Legacy cache without envelope.
      return decoded;
    } catch (_) {
      return null;
    }
  }

  /// Remove a cached entry.
  static Future<void> clear(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (_) {
      // Ignore failures.
    }
  }
}

