import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/nutrition_plan.dart';
import '../utils/constants.dart';

class NutritionService {
  final Future<String?> Function() getToken;

  NutritionService({required this.getToken});

  Future<NutritionPlan> createNutritionPlan(Map<String, dynamic> planData) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}${AppConstants.nutritionPlansEndpoint}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(planData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return NutritionPlan.fromJson(data);
    } else {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['message'] ?? 'Failed to create nutrition plan');
    }
  }

  Future<NutritionPlan> getNutritionPlanByChildId(String childId) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}${AppConstants.nutritionPlansByChildEndpoint(childId)}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return NutritionPlan.fromJson(data);
    } else if (response.statusCode == 404) {
      throw Exception('No nutrition plan found for this child');
    } else {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['message'] ?? 'Failed to get nutrition plan');
    }
  }

  Future<NutritionPlan> updateNutritionPlan(
    String planId,
    Map<String, dynamic> updates,
  ) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.patch(
      Uri.parse('${AppConstants.baseUrl}${AppConstants.nutritionPlanEndpoint(planId)}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(updates),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return NutritionPlan.fromJson(data);
    } else {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['message'] ?? 'Failed to update nutrition plan');
    }
  }

  Future<void> deleteNutritionPlan(String planId) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.delete(
      Uri.parse('${AppConstants.baseUrl}${AppConstants.nutritionPlanEndpoint(planId)}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['message'] ?? 'Failed to delete nutrition plan');
    }
  }
}
