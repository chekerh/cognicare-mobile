import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../utils/constants.dart';

class AdminService {
  final http.Client _client;
  final FlutterSecureStorage _storage;

  AdminService({
    http.Client? client,
    FlutterSecureStorage? storage,
  })  : _client = client ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await _storage.read(key: AppConstants.jwtTokenKey);
  }

  Future<List<User>> getAllUsers({String? role}) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      String url = '${AppConstants.baseUrl}/api/v1/users';
      if (role != null && role.isNotEmpty) {
        url += '?role=$role';
      }

      final response = await _client.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => User.fromJson(json)).toList();
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to fetch users');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<User> getUserById(String userId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await _client.get(
        Uri.parse('${AppConstants.baseUrl}/api/v1/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to fetch user');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<User> updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await _client.patch(
        Uri.parse('${AppConstants.baseUrl}/api/v1/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updates),
      );

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to update user');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await _client.delete(
        Uri.parse('${AppConstants.baseUrl}/api/v1/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to delete user');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// List volunteer applications (admin). Optional [status]: pending, approved, denied.
  Future<List<Map<String, dynamic>>> getVolunteerApplications({String? status}) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');
      var url = '${AppConstants.baseUrl}${AppConstants.volunteerApplicationsAdminEndpoint}';
      if (status != null && status.isNotEmpty) {
        url += '?status=$status';
      }
      final response = await _client.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode != 200) {
        final err = jsonDecode(response.body) as Map<String, dynamic>?;
        throw Exception(err?['message'] ?? 'Failed to fetch applications');
      }
      final list = jsonDecode(response.body) as List<dynamic>?;
      return (list ?? []).map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Get one volunteer application by id (admin).
  Future<Map<String, dynamic>> getVolunteerApplication(String id) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');
      final response = await _client.get(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.volunteerApplicationAdminEndpoint(id)}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode != 200) {
        final err = jsonDecode(response.body) as Map<String, dynamic>?;
        throw Exception(err?['message'] ?? 'Failed to fetch application');
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// List course enrollments (admin). Optional [userId] to filter by volunteer.
  Future<List<Map<String, dynamic>>> getVolunteerCourseEnrollments({String? userId}) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');
      var url = '${AppConstants.baseUrl}${AppConstants.coursesAdminEnrollmentsEndpoint}';
      if (userId != null && userId.isNotEmpty) {
        url += '?userId=$userId';
      }
      final response = await _client.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode != 200) {
        final err = jsonDecode(response.body) as Map<String, dynamic>?;
        throw Exception(err?['message'] ?? 'Failed to fetch enrollments');
      }
      final list = jsonDecode(response.body) as List<dynamic>?;
      return (list ?? []).map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Review volunteer: approve or deny (admin). [deniedReason] required when denying.
  Future<Map<String, dynamic>> reviewVolunteerApplication(
    String applicationId, {
    required String decision,
    String? deniedReason,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');
      final body = <String, dynamic>{'decision': decision};
      if (deniedReason != null && deniedReason.isNotEmpty) {
        body['deniedReason'] = deniedReason;
      }
      final response = await _client.patch(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.volunteerApplicationReviewEndpoint(applicationId)}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
      if (response.statusCode != 200) {
        final err = jsonDecode(response.body) as Map<String, dynamic>?;
        throw Exception(err?['message'] ?? 'Review failed');
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Progress AI: admin aggregate summary (no PII).
  Future<Map<String, dynamic>> getProgressAiAdminSummary() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');
      final response = await _client.get(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.progressAiAdminSummaryEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode != 200) {
        final err = jsonDecode(response.body) as Map<String, dynamic>?;
        throw Exception(err?['message'] ?? 'Failed to fetch progress summary');
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}
