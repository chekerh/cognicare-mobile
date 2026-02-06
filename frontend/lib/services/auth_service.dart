import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/auth_response.dart';
import '../models/user.dart';
import '../utils/constants.dart';

class AuthService {
  final http.Client _client;
  final FlutterSecureStorage _storage;

  AuthService({
    http.Client? client,
    FlutterSecureStorage? storage,
  })  : _client = client ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage();

  Future<AuthResponse> signup({
    required String fullName,
    required String email,
    required String password,
    String? phone,
    required String role,
    required String verificationCode,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.signupEndpoint}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': fullName,
          'email': email,
          'password': password,
          'phone': phone,
          'role': role,
          'verificationCode': verificationCode,
        }),
      );

      if (response.statusCode == 201) {
        final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
        await _storeAuthData(authResponse);
        return authResponse;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Signup failed');
      }
    } catch (e) {
      throw Exception('Network error during signup: $e');
    }
  }

  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _client.post(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.loginEndpoint}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
        await _storeAuthData(authResponse);
        return authResponse;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Network error during login: $e');
    }
  }

  Future<User> getProfile() async {
    try {
      final token = await getStoredToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await _client.get(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.profileEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      }
      if (response.statusCode == 401) {
        throw Exception('Unauthorized');
      }
      try {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to get profile');
      } catch (_) {
        throw Exception('Failed to get profile');
      }
    } catch (e) {
      if (e is Exception && e.toString().contains('Unauthorized')) rethrow;
      throw Exception('Network error during profile fetch: $e');
    }
  }

  Future<void> _storeAuthData(AuthResponse authResponse) async {
    await _storage.write(
      key: AppConstants.jwtTokenKey,
      value: authResponse.accessToken,
    );
    await _storage.write(
      key: AppConstants.userDataKey,
      value: jsonEncode(authResponse.user.toJson()),
    );
  }

  /// Update own profile (fullName, phone, profilePic URL).
  Future<User> updateProfile({
    String? fullName,
    String? phone,
    String? profilePic,
  }) async {
    final token = await getStoredToken();
    if (token == null) throw Exception('No authentication token found');
    final body = <String, dynamic>{};
    if (fullName != null) body['fullName'] = fullName;
    if (phone != null) body['phone'] = phone;
    if (profilePic != null) body['profilePic'] = profilePic;
    final response = await _client.patch(
      Uri.parse('${AppConstants.baseUrl}${AppConstants.updateProfileEndpoint}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) {
      try {
        final err = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(err['message'] ?? 'Failed to update profile');
      } catch (_) {
        throw Exception('Failed to update profile: ${response.statusCode}');
      }
    }
    return User.fromJson(jsonDecode(response.body));
  }

  /// Upload profile picture (multipart). Returns updated user with profilePic URL.
  Future<User> uploadProfilePicture(File imageFile) async {
    final token = await getStoredToken();
    if (token == null) throw Exception('No authentication token found');
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConstants.baseUrl}${AppConstants.uploadProfilePictureEndpoint}'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 200 && response.statusCode != 201) {
      try {
        final err = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(err['message'] ?? 'Failed to upload picture');
      } catch (_) {
        throw Exception('Failed to upload picture: ${response.statusCode}');
      }
    }
    return User.fromJson(jsonDecode(response.body));
  }

  Future<String?> getStoredToken() async {
    return await _storage.read(key: AppConstants.jwtTokenKey);
  }

  Future<User?> getStoredUser() async {
    final userData = await _storage.read(key: AppConstants.userDataKey);
    if (userData != null) {
      return User.fromJson(jsonDecode(userData));
    }
    return null;
  }

  Future<void> clearStoredData() async {
    await _storage.delete(key: AppConstants.jwtTokenKey);
    await _storage.delete(key: AppConstants.userDataKey);
  }

  void dispose() {
    _client.close();
  }
}