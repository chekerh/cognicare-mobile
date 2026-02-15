import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:http_parser/http_parser.dart';
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

  /// Lightweight ping to warm up the backend (useful on cold starts).
  Future<void> pingBackend() async {
    try {
      await _client
          .get(Uri.parse('${AppConstants.baseUrl}/health'))
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Ignore errors – this is best-effort only.
    }
  }

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
      final response = await _client
          .post(
            Uri.parse('${AppConstants.baseUrl}${AppConstants.loginEndpoint}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));

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

      final response = await _client
          .get(
            Uri.parse('${AppConstants.baseUrl}${AppConstants.profileEndpoint}'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

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
  Future<User> uploadProfilePicture(File imageFile, {String? mimeType}) async {
    final token = await getStoredToken();
    if (token == null) throw Exception('No authentication token found');
    if (!await imageFile.exists()) {
      throw Exception('Image file does not exist');
    }
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConstants.baseUrl}${AppConstants.uploadProfilePictureEndpoint}'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    final contentType = mimeType ?? 'image/jpeg';
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: MediaType.parse(contentType),
      ),
    );
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

  /// Update own presence (lastSeenAt). Call periodically so user appears "online".
  Future<void> updatePresence() async {
    final token = await getStoredToken();
    if (token == null) return;
    try {
      await _client.post(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.authPresenceEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 5));
    } catch (_) {
      // Best-effort; ignore errors.
    }
  }

  /// Family members (MongoDB + Cloudinary). Returns list of {id, name, imageUrl}.
  Future<List<Map<String, String>>> getFamilyMembers() async {
    final token = await getStoredToken();
    if (token == null) return [];
    try {
      final response = await _client.get(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.familyMembersEndpoint}'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return [];
      final list = jsonDecode(response.body) as List<dynamic>?;
      if (list == null) return [];
      return list.map((e) {
        final m = e as Map<String, dynamic>;
        final imageUrl = m['imageUrl']?.toString().trim() ?? m['image_url']?.toString().trim() ?? '';
        return <String, String>{
          'id': m['id']?.toString() ?? '',
          'name': m['name']?.toString() ?? '',
          'imageUrl': imageUrl,
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Add family member with photo (upload to Cloudinary via backend). Returns {id, name, imageUrl}.
  Future<Map<String, String>> addFamilyMember(File imageFile, String name) async {
    final token = await getStoredToken();
    if (token == null) throw Exception('No authentication token found');
    if (!await imageFile.exists()) throw Exception('Image file does not exist');
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConstants.baseUrl}${AppConstants.familyMembersEndpoint}'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['name'] = name;
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: MediaType.parse('image/jpeg'),
      ),
    );
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 200 && response.statusCode != 201) {
      try {
        final err = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(err['message'] ?? 'Failed to add member');
      } catch (_) {
        throw Exception('Failed to add member: ${response.statusCode}');
      }
    }
    final m = jsonDecode(response.body) as Map<String, dynamic>;
    return {
      'id': m['id']?.toString() ?? '',
      'name': m['name']?.toString() ?? name,
      'imageUrl': m['imageUrl']?.toString() ?? '',
    };
  }

  /// Delete family member.
  Future<void> deleteFamilyMember(String memberId) async {
    final token = await getStoredToken();
    if (token == null) throw Exception('No authentication token found');
    final response = await _client.delete(
      Uri.parse('${AppConstants.baseUrl}${AppConstants.familyMemberEndpoint(memberId)}'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      try {
        final err = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(err['message'] ?? 'Failed to delete member');
      } catch (_) {
        throw Exception('Failed to delete: ${response.statusCode}');
      }
    }
  }

  /// Get another user's online status. Returns true only if they logged in recently (e.g. last 5 min).
  Future<bool> getPresence(String userId) async {
    final token = await getStoredToken();
    if (token == null) return false;
    final response = await _client.get(
      Uri.parse('${AppConstants.baseUrl}${AppConstants.userPresenceEndpoint(userId)}'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 5));
    if (response.statusCode != 200) return false;
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['online'] == true;
    } catch (_) {
      return false;
    }
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

  /// Persist updated user (e.g. after profile picture upload) so the app sees the new data.
  Future<void> saveUser(User user) async {
    await _storage.write(
      key: AppConstants.userDataKey,
      value: jsonEncode(user.toJson()),
    );
  }

  Future<void> clearStoredData() async {
    await _storage.delete(key: AppConstants.jwtTokenKey);
    await _storage.delete(key: AppConstants.userDataKey);
    // Remove shared local profile pic so next user doesn't see previous user's photo
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/profile_pic.jpg');
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  /// Change user password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final token = await getStoredToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await _client.patch(
        Uri.parse('${AppConstants.baseUrl}/api/v1/auth/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to change password');
      }
    } catch (e) {
      throw Exception('Error changing password: $e');
    }
  }

  /// Change user email (sends verification email)
  Future<void> changeEmail(String newEmail) async {
    try {
      final token = await getStoredToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await _client.patch(
        Uri.parse('${AppConstants.baseUrl}/api/v1/auth/change-email'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'newEmail': newEmail,
        }),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to change email');
      }
    } catch (e) {
      throw Exception('Error changing email: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}