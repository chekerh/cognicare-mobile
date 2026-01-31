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

  void dispose() {
    _client.close();
  }
}
