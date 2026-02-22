import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

class CoursesService {
  final http.Client _client;
  final FlutterSecureStorage _storage;

  CoursesService({
    http.Client? client,
    FlutterSecureStorage? storage,
  })  : _client = client ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await _storage.read(key: AppConstants.jwtTokenKey);
  }

  /// List courses. [qualificationOnly] true for qualification courses only.
  Future<List<Map<String, dynamic>>> getCourses(
      {bool qualificationOnly = false}) async {
    var url = '${AppConstants.baseUrl}${AppConstants.coursesEndpoint}';
    if (qualificationOnly) url += '?qualification=true';
    final response = await _client.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Failed to load courses');
    }
    final list = jsonDecode(response.body) as List<dynamic>?;
    return (list ?? []).map((e) => e as Map<String, dynamic>).toList();
  }

  /// Enroll in a course. Returns updated my enrollments.
  Future<List<Map<String, dynamic>>> enroll(String courseId) async {
    final token = await _getToken();
    if (token == null) throw Exception('No authentication token');
    final response = await _client.post(
      Uri.parse(
          '${AppConstants.baseUrl}${AppConstants.courseEnrollEndpoint(courseId)}'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(body?['message'] ?? 'Enrollment failed');
    }
    final list = jsonDecode(response.body) as List<dynamic>?;
    return (list ?? []).map((e) => e as Map<String, dynamic>).toList();
  }

  /// My enrollments with course details.
  Future<List<Map<String, dynamic>>> myEnrollments() async {
    final token = await _getToken();
    if (token == null) throw Exception('No authentication token');
    final response = await _client.get(
      Uri.parse(
          '${AppConstants.baseUrl}${AppConstants.coursesMyEnrollmentsEndpoint}'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load enrollments');
    }
    final list = jsonDecode(response.body) as List<dynamic>?;
    return (list ?? []).map((e) => e as Map<String, dynamic>).toList();
  }

  /// Update progress for an enrollment (0-100).
  Future<List<Map<String, dynamic>>> updateProgress(
      String enrollmentId, int progressPercent) async {
    final token = await _getToken();
    if (token == null) throw Exception('No authentication token');
    final response = await _client.patch(
      Uri.parse(
          '${AppConstants.baseUrl}${AppConstants.courseEnrollmentProgressEndpoint(enrollmentId)}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'progressPercent': progressPercent}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update progress');
    }
    final list = jsonDecode(response.body) as List<dynamic>?;
    return (list ?? []).map((e) => e as Map<String, dynamic>).toList();
  }
}
