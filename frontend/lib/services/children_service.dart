import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class ChildModel {
  final String id;
  final String fullName;
  final String dateOfBirth;
  final String gender;
  final String? diagnosis;
  final String? medicalHistory;
  final String? allergies;
  final String? medications;
  final String? notes;
  final String? parentId;

  ChildModel({
    required this.id,
    required this.fullName,
    required this.dateOfBirth,
    required this.gender,
    this.diagnosis,
    this.medicalHistory,
    this.allergies,
    this.medications,
    this.notes,
    this.parentId,
  });

  factory ChildModel.fromJson(Map<String, dynamic> json) {
    return ChildModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      fullName: json['fullName'] as String? ?? '',
      dateOfBirth: json['dateOfBirth']?.toString() ?? '',
      gender: json['gender'] as String? ?? 'other',
      diagnosis: json['diagnosis'] as String?,
      medicalHistory: json['medicalHistory'] as String?,
      allergies: json['allergies'] as String?,
      medications: json['medications'] as String?,
      notes: json['notes'] as String?,
      parentId: json['parentId']?.toString(),
    );
  }
}

/// DTO for adding a child (matches backend AddChildDto).
class AddChildDto {
  final String fullName;
  final String dateOfBirth;
  final String gender;
  final String? diagnosis;
  final String? medicalHistory;
  final String? allergies;
  final String? medications;
  final String? notes;

  AddChildDto({
    required this.fullName,
    required this.dateOfBirth,
    required this.gender,
    this.diagnosis,
    this.medicalHistory,
    this.allergies,
    this.medications,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{
      'fullName': fullName,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
    };
    if (diagnosis != null && diagnosis!.isNotEmpty) m['diagnosis'] = diagnosis;
    if (medicalHistory != null && medicalHistory!.isNotEmpty) m['medicalHistory'] = medicalHistory;
    if (allergies != null && allergies!.isNotEmpty) m['allergies'] = allergies;
    if (medications != null && medications!.isNotEmpty) m['medications'] = medications;
    if (notes != null && notes!.isNotEmpty) m['notes'] = notes;
    return m;
  }
}

class ChildrenService {
  final http.Client _client;
  final Future<String?> Function() getToken;

  ChildrenService({
    http.Client? client,
    required this.getToken,
  }) : _client = client ?? http.Client();

  /// GET /children or GET /children?familyId=xxx
  Future<List<ChildModel>> getChildren({String? familyId}) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');
    final query = familyId != null && familyId.isNotEmpty ? '?familyId=$familyId' : '';
    final uri = Uri.parse('${AppConstants.baseUrl}${AppConstants.childrenEndpoint}$query');
    
    print('🔍 ChildrenService - Requesting: $uri');
    print('🔍 ChildrenService - Token présent: ${token != null ? "Oui (${token.substring(0, 20)}...)" : "Non"}');
    
    final response = await _client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    print('🔍 ChildrenService - Status: ${response.statusCode}');
    print('🔍 ChildrenService - Body: ${response.body}');
    
    if (response.statusCode != 200) {
      try {
        final err = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(err['message'] ?? 'Failed to load children');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Failed to load: ${response.statusCode}');
      }
    }
    final list = jsonDecode(response.body) as List<dynamic>? ?? [];
    print('🔍 ChildrenService - Nombre d\'enfants reçus: ${list.length}');
    
    return list.map((e) => ChildModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /organization/my-organization/children - for specialists
  Future<List<ChildModel>> getOrganizationChildren() async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');
    final uri = Uri.parse('${AppConstants.baseUrl}${AppConstants.organizationChildrenEndpoint}');
    
    print('🔍 ChildrenService - Requesting Org Children: $uri');
    
    final response = await _client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode != 200) {
      try {
        final err = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(err['message'] ?? 'Failed to load organization children');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Failed to load: ${response.statusCode}');
      }
    }
    final list = jsonDecode(response.body) as List<dynamic>? ?? [];
    return list.map((e) => ChildModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// POST /children - add a child (family only).
  Future<ChildModel> addChild(AddChildDto dto) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');
    final uri = Uri.parse('${AppConstants.baseUrl}${AppConstants.childrenEndpoint}');
    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(dto.toJson()),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      try {
        final err = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(err['message'] ?? 'Failed to add child');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Failed to add: ${response.statusCode}');
      }
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return ChildModel.fromJson(json);
  }
}
