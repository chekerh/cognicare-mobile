import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

class TrainingService {
  final http.Client _client = http.Client();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await _storage.read(key: AppConstants.jwtTokenKey);
  }

  String get _base =>
      AppConstants.baseUrl.endsWith('/')
          ? AppConstants.baseUrl.substring(0, AppConstants.baseUrl.length - 1)
          : AppConstants.baseUrl;

  /// List approved training courses.
  Future<List<Map<String, dynamic>>> getCourses() async {
    final response = await _client.get(
      Uri.parse('$_base${AppConstants.trainingCoursesEndpoint}'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load training courses');
    }
    final raw = jsonDecode(response.body);
    final list = raw is List<dynamic> ? raw : <dynamic>[];
    return list.whereType<Map<String, dynamic>>().toList();
  }

  /// Get one course by id.
  Future<Map<String, dynamic>> getCourse(String courseId) async {
    final response = await _client.get(
      Uri.parse('$_base${AppConstants.trainingCourseByIdEndpoint(courseId)}'),
    );
    final decoded = jsonDecode(response.body);
    if (response.statusCode != 200) {
      final body = decoded is Map<String, dynamic> ? decoded : null;
      throw Exception(body?['message'] ?? 'Course not found');
    }
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is List<dynamic> && decoded.isNotEmpty) {
      final first = decoded.first;
      if (first is Map<String, dynamic>) return first;
    }
    throw Exception('Invalid course response');
  }

  /// Enroll in a course. Returns updated enrollments.
  Future<List<Map<String, dynamic>>> enroll(String courseId) async {
    final token = await _getToken();
    if (token == null) throw Exception('No authentication token');
    final response = await _client.post(
      Uri.parse('$_base${AppConstants.trainingEnrollEndpoint(courseId)}'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final decoded = jsonDecode(response.body);
    if (response.statusCode != 200 && response.statusCode != 201) {
      final body = decoded is Map<String, dynamic> ? decoded : null;
      throw Exception(body?['message'] ?? 'Enrollment failed');
    }
    final list = decoded is List<dynamic> ? decoded : <dynamic>[];
    return list.whereType<Map<String, dynamic>>().toList();
  }

  /// My training enrollments with progress.
  Future<List<Map<String, dynamic>>> myEnrollments() async {
    final token = await _getToken();
    if (token == null) throw Exception('No authentication token');
    final response = await _client.get(
      Uri.parse('$_base${AppConstants.trainingMyEnrollmentsEndpoint}'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load enrollments');
    }
    final raw = jsonDecode(response.body);
    final list = raw is List<dynamic> ? raw : <dynamic>[];
    return list.whereType<Map<String, dynamic>>().toList();
  }

  /// Mark course content as completed (before taking quiz).
  Future<List<Map<String, dynamic>>> markContentCompleted(String courseId) async {
    final token = await _getToken();
    if (token == null) throw Exception('No authentication token');
    final response = await _client.post(
      Uri.parse('$_base${AppConstants.trainingCompleteContentEndpoint(courseId)}'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final ok = response.statusCode == 200 || response.statusCode == 201;
    dynamic decoded;
    try {
      decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    } catch (_) {
      decoded = null;
    }
    if (!ok) {
      final body = decoded is Map<String, dynamic> ? decoded : null;
      final message = body?['message'] ?? body?['error'] ?? '';
      if (response.statusCode == 401) {
        throw Exception(message.toString().isEmpty ? 'Session expirée. Reconnectez-vous.' : message);
      }
      throw Exception(message.toString().isNotEmpty ? message.toString() : 'Failed to mark complete');
    }
    final list = decoded is List<dynamic> ? decoded : <dynamic>[];
    return list.whereType<Map<String, dynamic>>().toList();
  }

  /// Submit quiz answers. [textAnswers] optional for fill_blank questions (same-length list).
  /// Returns score, passed, enrollments, and review (correct answers per question).
  Future<Map<String, dynamic>> submitQuiz(
    String courseId,
    List<int> answers, {
    List<String>? textAnswers,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('No authentication token');
    final body = <String, dynamic>{'answers': answers};
    if (textAnswers != null) body['textAnswers'] = textAnswers;
    final response = await _client.post(
      Uri.parse('$_base${AppConstants.trainingSubmitQuizEndpoint(courseId)}'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    final respDecoded = jsonDecode(response.body);
    if (response.statusCode != 200 && response.statusCode != 201) {
      final respBody = respDecoded is Map<String, dynamic> ? respDecoded : null;
      throw Exception(respBody?['message'] ?? 'Quiz submission failed');
    }
    if (respDecoded is Map<String, dynamic>) return respDecoded;
    throw Exception('Invalid quiz response');
  }

  /// Get next unlocked course id (for progression).
  Future<String?> getNextCourseId() async {
    final token = await _getToken();
    if (token == null) return null;
    final response = await _client.get(
      Uri.parse('$_base${AppConstants.trainingNextCourseEndpoint}'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) return null;
    final raw = jsonDecode(response.body);
    final data = raw is Map<String, dynamic> ? raw : null;
    final id = data?['courseId'];
    return id is String ? id : null;
  }
}
