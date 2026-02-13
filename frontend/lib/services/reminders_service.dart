import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task_reminder.dart';
import '../utils/constants.dart';

class RemindersService {
  final Future<String?> Function() getToken;

  RemindersService({required this.getToken});

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
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return TaskReminder.fromJson(data);
    } else {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['message'] ?? 'Failed to create reminder');
    }
  }

  Future<List<TaskReminder>> getRemindersByChildId(String childId) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}${AppConstants.remindersByChildEndpoint(childId)}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data.map((json) => TaskReminder.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['message'] ?? 'Failed to get reminders');
    }
  }

  Future<List<TaskReminder>> getTodayReminders(String childId) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}${AppConstants.todayRemindersByChildEndpoint(childId)}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data.map((json) => TaskReminder.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['message'] ?? 'Failed to get today\'s reminders');
    }
  }

  Future<TaskReminder> updateReminder(
    String reminderId,
    Map<String, dynamic> updates,
  ) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.patch(
      Uri.parse('${AppConstants.baseUrl}${AppConstants.reminderEndpoint(reminderId)}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(updates),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return TaskReminder.fromJson(data);
    } else {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['message'] ?? 'Failed to update reminder');
    }
  }

  Future<Map<String, dynamic>> completeTask({
    required String reminderId,
    required bool completed,
    required DateTime date,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}${AppConstants.completeTaskEndpoint}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'reminderId': reminderId,
        'completed': completed,
        'date': date.toIso8601String(),
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['message'] ?? 'Failed to complete task');
    }
  }

  Future<void> deleteReminder(String reminderId) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.delete(
      Uri.parse('${AppConstants.baseUrl}${AppConstants.reminderEndpoint(reminderId)}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['message'] ?? 'Failed to delete reminder');
    }
  }

  Future<Map<String, dynamic>> getCompletionStats(String childId, {int days = 7}) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}${AppConstants.reminderStatsEndpoint(childId, days: days)}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['message'] ?? 'Failed to get completion stats');
    }
  }
}
