import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task_reminder.dart';
import '../utils/constants.dart';

class RemindersService {
  final Future<String?> Function() getToken;

  RemindersService({required this.getToken});

  Future<List<TaskReminder>> getTodayReminders(String childId) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse(
          '${AppConstants.baseUrl}${AppConstants.todayRemindersByChildEndpoint(childId)}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((json) => TaskReminder.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['message'] ?? 'Failed to get today\'s reminders');
    }
  }

  Future<TaskReminder> createReminder(Map<String, dynamic> reminderData) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}${AppConstants.remindersEndpoint}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(reminderData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return TaskReminder.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['message'] ?? 'Failed to create reminder');
    }
  }

  Future<Map<String, dynamic>> completeTask({
    required String reminderId,
    required bool completed,
    required DateTime date,
    String? feedback,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');

    final body = <String, dynamic>{
      'reminderId': reminderId,
      'completed': completed,
      'date': date.toIso8601String(),
    };
    if (feedback != null && feedback.trim().isNotEmpty) {
      body['feedback'] = feedback.trim();
    }

    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}${AppConstants.completeTaskEndpoint}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['message'] ?? 'Failed to complete task');
    }
  }

  Future<Map<String, dynamic>> completeTaskWithProof({
    required String reminderId,
    required bool completed,
    required DateTime date,
    required String proofImagePath,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');

    // Create multipart request for image upload
    final uri = Uri.parse(
        '${AppConstants.baseUrl}${AppConstants.completeTaskEndpoint}');
    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer $token';

    // Add fields
    request.fields['reminderId'] = reminderId;
    request.fields['completed'] = completed.toString();
    request.fields['date'] = date.toIso8601String();

    // Add proof image
    request.files.add(await http.MultipartFile.fromPath(
      'proofImage',
      proofImagePath,
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['message'] ?? 'Failed to complete task with proof');
    }
  }

  /// GET /reminders/child/:childId/stats?days=N - completion stats for charts.
  Future<Map<String, dynamic>> getReminderStats(String childId,
      {int days = 7}) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');
    final uri = Uri.parse(
      '${AppConstants.baseUrl}${AppConstants.reminderStatsEndpoint(childId, days: days)}',
    );
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 200) {
      final err = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(err?['message'] ?? 'Failed to load stats');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> deleteReminder(String reminderId) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.delete(
      Uri.parse(
          '${AppConstants.baseUrl}${AppConstants.reminderEndpoint(reminderId)}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['message'] ?? 'Failed to delete reminder');
    }
  }
}
