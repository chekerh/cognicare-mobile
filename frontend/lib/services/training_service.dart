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
    final list = jsonDecode(response.body) as List<dynamic>?;
    return (list ?? []).map((e) => e as Map<String, dynamic>).toList();
  }

  /// Get one course by id.
  Future<Map<String, dynamic>> getCourse(String courseId) async {
    final response = await _client.get(
      Uri.parse('$_base${AppConstants.trainingCourseByIdEndpoint(courseId)}'),
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(body?['message'] ?? 'Course not found');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Enroll in a course. Returns updated enrollments.
  Future<List<Map<String, dynamic>>> enroll(String courseId) async {
    final token = await _getToken();
    if (token == null) throw Exception('No authentication token');
    final response = await _client.post(
      Uri.parse('$_base${AppConstants.trainingEnrollEndpoint(courseId)}'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(body?['message'] ?? 'Enrollment failed');
    }
    final list = jsonDecode(response.body) as List<dynamic>?;
    return (list ?? []).map((e) => e as Map<String, dynamic>).toList();
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
    final list = jsonDecode(response.body) as List<dynamic>?;
    return (list ?? []).map((e) => e as Map<String, dynamic>).toList();
  }

  /// Mark course content as completed (before taking quiz).
  Future<List<Map<String, dynamic>>> markContentCompleted(String courseId) async {
    final token = await _getToken();
    if (token == null) throw Exception('No authentication token');
    final response = await _client.post(
      Uri.parse('$_base${AppConstants.trainingCompleteContentEndpoint(courseId)}'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(body?['message'] ?? 'Failed to mark complete');
    }
    final list = jsonDecode(response.body) as List<dynamic>?;
    return (list ?? []).map((e) => e as Map<String, dynamic>).toList();
  }

  /// Submit quiz answers. Returns score, passed, and updated enrollments.
  Future<Map<String, dynamic>> submitQuiz(String courseId, List<int> answers) async {
    final token = await _getToken();
    if (token == null) throw Exception('No authentication token');
    final response = await _client.post(
      Uri.parse('$_base${AppConstants.trainingSubmitQuizEndpoint(courseId)}'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'answers': answers}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(body?['message'] ?? 'Quiz submission failed');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
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
    final data = jsonDecode(response.body) as Map<String, dynamic>?;
    final id = data?['courseId'];
    return id is String ? id : null;
  }
}
