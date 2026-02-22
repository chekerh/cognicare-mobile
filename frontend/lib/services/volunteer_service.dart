import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

class VolunteerService {
  final http.Client _client;
  final FlutterSecureStorage _storage;

  VolunteerService({
    http.Client? client,
    FlutterSecureStorage? storage,
  })  : _client = client ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await _storage.read(key: AppConstants.jwtTokenKey);
  }

  /// Get or create my volunteer application (status, documents).
  Future<Map<String, dynamic>> getMyApplication() async {
    final token = await _getToken();
    if (token == null) throw Exception('No authentication token');
    final response = await _client.get(
      Uri.parse(
          '${AppConstants.baseUrl}${AppConstants.volunteerApplicationEndpoint}'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(body?['message'] ?? 'Failed to load application');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Upload a document (id, certificate, other). Max 5MB. Images or PDF.
  Future<Map<String, dynamic>> uploadDocument({
    required File file,
    required String type,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('No authentication token');
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
          '${AppConstants.baseUrl}${AppConstants.volunteerDocumentsEndpoint}'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['type'] = type;
    final mimeType = _mimeForFile(file.path);
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: MediaType.parse(mimeType),
      ),
    );
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 200 && response.statusCode != 201) {
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>?;
        throw Exception(body?['message'] ?? 'Upload failed');
      } catch (_) {
        throw Exception('Upload failed: ${response.statusCode}');
      }
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  String _mimeForFile(String path) {
    final ext = path.split('.').last.toLowerCase();
    if (ext == 'pdf') return 'application/pdf';
    if (ext == 'png') return 'image/png';
    if (ext == 'webp') return 'image/webp';
    return 'image/jpeg';
  }

  /// Remove document by index.
  Future<Map<String, dynamic>> removeDocument(int index) async {
    final token = await _getToken();
    if (token == null) throw Exception('No authentication token');
    final response = await _client.delete(
      Uri.parse(
          '${AppConstants.baseUrl}${AppConstants.volunteerDocumentDeleteEndpoint(index)}'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(body?['message'] ?? 'Failed to remove document');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
