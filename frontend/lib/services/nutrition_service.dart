import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/nutrition_plan.dart';
import '../utils/constants.dart';

class NutritionService {
  final Future<String?> Function() getToken;

  NutritionService({required this.getToken});

  Future<List<NutritionPlan>> getNutritionPlansByChild(String childId) async {
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
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data.map((json) => NutritionPlan.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['message'] ?? 'Failed to get nutrition plans');
    }
  }

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
      return NutritionPlan.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['message'] ?? 'Failed to create nutrition plan');
    }
  }

  Future<NutritionPlan> updateNutritionPlan(String planId, Map<String, dynamic> planData) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.patch(
      Uri.parse('${AppConstants.baseUrl}${AppConstants.nutritionPlanEndpoint(planId)}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(planData),
    );

    if (response.statusCode == 200) {
      return NutritionPlan.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(error['message'] ?? 'Failed to update nutrition plan');
    }
  }
}
