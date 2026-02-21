import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'package:cognicare_frontend/services/auth_service.dart';

class VolunteerAvailability {
  final String id;
  final String volunteerId;
  final String volunteerName;
  final String volunteerProfilePic;
  final List<String> dates;
  final String startTime;
  final String endTime;
  final String recurrence;
  final bool recurrenceOn;

  VolunteerAvailability({
    required this.id,
    required this.volunteerId,
    required this.volunteerName,
    required this.volunteerProfilePic,
    required this.dates,
    required this.startTime,
    required this.endTime,
    required this.recurrence,
    required this.recurrenceOn,
  });

  factory VolunteerAvailability.fromJson(Map<String, dynamic> json) {
    final datesList = json['dates'];
    return VolunteerAvailability(
      id: json['id'] ?? json['_id']?.toString() ?? '',
      volunteerId: json['volunteerId']?.toString() ?? '',
      volunteerName: json['volunteerName'] as String? ?? 'Bénévole',
      volunteerProfilePic: json['volunteerProfilePic'] as String? ?? '',
      dates: datesList is List ? (datesList).map((e) => e.toString()).toList() : [],
      startTime: json['startTime'] as String? ?? '14:00',
      endTime: json['endTime'] as String? ?? '18:00',
      recurrence: json['recurrence'] as String? ?? 'weekly',
      recurrenceOn: json['recurrenceOn'] as bool? ?? true,
    );
  }
}

class AvailabilityService {
  final AuthService _authService;
  final http.Client _client;

  AvailabilityService({
    http.Client? client,
    AuthService? authService,
  })  : _client = client ?? http.Client(),
        _authService = authService ?? AuthService();

  /// List availabilities for family home (no auth required for GET for-families).
  Future<List<VolunteerAvailability>> listForFamilies() async {
    final uri = Uri.parse(
      '${AppConstants.baseUrl}${AppConstants.availabilitiesForFamiliesEndpoint}',
    );
    final response = await _client.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode != 200) {
      try {
        final err = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(err['message'] ?? 'Failed to load availabilities');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Failed to load: ${response.statusCode}');
      }
    }
    final list = jsonDecode(response.body) as List<dynamic>? ?? [];
    return list
        .map((e) => VolunteerAvailability.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Publish availability (volunteer only). Requires token.
  Future<void> create({
    required List<String> dates,
    String startTime = '14:00',
    String endTime = '18:00',
    String recurrence = 'weekly',
    bool recurrenceOn = true,
  }) async {
    final token = await _authService.getStoredToken();
    if (token == null) throw Exception('Not authenticated');
    final uri = Uri.parse(
      '${AppConstants.baseUrl}${AppConstants.availabilitiesEndpoint}',
    );
    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'dates': dates,
        'startTime': startTime,
        'endTime': endTime,
        'recurrence': recurrence,
        'recurrenceOn': recurrenceOn,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      try {
        final err = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(err['message'] ?? 'Failed to publish availability');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Failed to publish: ${response.statusCode}');
      }
    }
  }
}
