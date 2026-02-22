import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class ProgressAiRecommendationItem {
  final String planType;
  final String text;

  ProgressAiRecommendationItem({required this.planType, required this.text});

  factory ProgressAiRecommendationItem.fromJson(Map<String, dynamic> json) {
    return ProgressAiRecommendationItem(
      planType: json['planType'] as String? ?? '',
      text: json['text'] as String? ?? '',
    );
  }
}

class ProgressAiRecommendationResult {
  final String recommendationId;
  final String summary;
  final List<ProgressAiRecommendationItem> recommendations;
  final String? milestones;
  final String? predictions;

  ProgressAiRecommendationResult({
    required this.recommendationId,
    required this.summary,
    required this.recommendations,
    this.milestones,
    this.predictions,
  });

  factory ProgressAiRecommendationResult.fromJson(Map<String, dynamic> json) {
    final recs = json['recommendations'] as List<dynamic>? ?? [];
    return ProgressAiRecommendationResult(
      recommendationId: json['recommendationId'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      recommendations: recs
          .map((e) => ProgressAiRecommendationItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      milestones: json['milestones'] as String?,
      predictions: json['predictions'] as String?,
    );
  }
}

class ProgressAiService {
  final http.Client _client;
  final Future<String?> Function() getToken;

  ProgressAiService({
    http.Client? client,
    required this.getToken,
  }) : _client = client ?? http.Client();

  /// GET progress-ai/child/:childId/recommendations
  Future<ProgressAiRecommendationResult> getRecommendations(
    String childId, {
    String? planType,
    String? summaryLength,
    String? focusPlanTypes,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');
    final uri = Uri.parse(
      AppConstants.baseUrl +
          AppConstants.progressAiChildRecommendationsEndpoint(
            childId,
            planType: planType,
            summaryLength: summaryLength,
            focusPlanTypes: focusPlanTypes,
          ),
    );
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
        throw Exception(err['message'] ?? 'Failed to load recommendations');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Failed to load: ${response.statusCode}');
      }
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return ProgressAiRecommendationResult.fromJson(json);
  }

  /// GET progress-ai/activity-suggestions
  Future<List<String>> getActivitySuggestions() async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');
    final uri = Uri.parse(
      AppConstants.baseUrl + AppConstants.progressAiActivitySuggestionsEndpoint,
    );
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
        throw Exception(err['message'] ?? 'Failed to load activity suggestions');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Failed to load: ${response.statusCode}');
      }
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final list = json['suggestions'] as List<dynamic>? ?? [];
    return list.map((e) => e.toString()).toList();
  }

  /// POST progress-ai/recommendations/:id/feedback
  Future<void> submitFeedback({
    required String recommendationId,
    required String childId,
    required String action,
    String? planId,
    String? editedText,
    String? originalRecommendationText,
    String? planType,
    bool? resultsImproved,
    bool? parentFeedbackHelpful,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');
    final uri = Uri.parse(
      AppConstants.baseUrl +
          AppConstants.progressAiFeedbackEndpoint(recommendationId),
    );
    final body = <String, dynamic>{
      'childId': childId,
      'action': action,
    };
    if (planId != null && planId.isNotEmpty) body['planId'] = planId;
    if (editedText != null && editedText.isNotEmpty) body['editedText'] = editedText;
    if (originalRecommendationText != null && originalRecommendationText.isNotEmpty) {
      body['originalRecommendationText'] = originalRecommendationText;
    }
    if (planType != null && planType.isNotEmpty) {
      body['planType'] = planType;
    }
    if (resultsImproved != null) {
      body['resultsImproved'] = resultsImproved;
    }
    if (parentFeedbackHelpful != null) {
      body['parentFeedbackHelpful'] = parentFeedbackHelpful;
    }
    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      try {
        final err = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(err['message'] ?? 'Failed to submit feedback');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Failed to submit: ${response.statusCode}');
      }
    }
  }

  /// GET progress-ai/org/specialist/:specialistId/summary (org leader only).
  Future<Map<String, dynamic>> getOrgSpecialistSummary(String specialistId) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');
    final uri = Uri.parse(
      AppConstants.baseUrl +
          AppConstants.progressAiOrgSpecialistSummaryEndpoint(specialistId),
    );
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
        throw Exception(err['message'] ?? 'Failed to load specialist summary');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Failed to load: ${response.statusCode}');
      }
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// GET progress-ai/preferences (specialist).
  Future<Map<String, dynamic>?> getPreferences() async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');
    final response = await _client.get(
      Uri.parse('${AppConstants.baseUrl}${AppConstants.progressAiPreferencesEndpoint}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 404 || response.statusCode == 200) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body) as Map<String, dynamic>?;
    }
    return null;
  }

  /// PATCH progress-ai/preferences (specialist).
  Future<Map<String, dynamic>?> updatePreferences({
    List<String>? focusPlanTypes,
    String? summaryLength,
    String? frequency,
    Map<String, double>? planTypeWeights,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');
    final body = <String, dynamic>{};
    if (focusPlanTypes != null) body['focusPlanTypes'] = focusPlanTypes;
    if (summaryLength != null) body['summaryLength'] = summaryLength;
    if (frequency != null) body['frequency'] = frequency;
    if (planTypeWeights != null && planTypeWeights.isNotEmpty) {
      body['planTypeWeights'] = planTypeWeights.map((k, v) => MapEntry(k, v));
    }
    final response = await _client.patch(
      Uri.parse('${AppConstants.baseUrl}${AppConstants.progressAiPreferencesEndpoint}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) {
      final err = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(err?['message'] ?? 'Failed to update preferences');
    }
    return jsonDecode(response.body) as Map<String, dynamic>?;
  }

  /// GET specialized-plans/child/:childId (for progress bars).
  Future<List<Map<String, dynamic>>> getPlansByChild(String childId) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');
    final uri = Uri.parse(
      AppConstants.baseUrl +
          AppConstants.specializedPlansByChildEndpoint(childId),
    );
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
        throw Exception(err['message'] ?? 'Failed to load plans');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Failed to load: ${response.statusCode}');
      }
    }
    final list = jsonDecode(response.body) as List<dynamic>? ?? [];
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  /// POST progress-ai/child/:childId/request-parent-feedback
  Future<void> requestParentFeedback({
    required String childId,
    String? recommendationId,
    String? message,
    String? planType,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');
    final uri = Uri.parse(
      AppConstants.baseUrl +
          AppConstants.progressAiRequestParentFeedbackEndpoint(childId),
    );
    final body = <String, dynamic>{};
    if (recommendationId != null && recommendationId.isNotEmpty) {
      body['recommendationId'] = recommendationId;
    }
    if (message != null && message.isNotEmpty) body['message'] = message;
    if (planType != null && planType.isNotEmpty) body['planType'] = planType;
    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      try {
        final err = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(err['message'] ?? 'Failed to request parent feedback');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Failed to request: ${response.statusCode}');
      }
    }
  }

  /// GET progress-ai/child/:childId/parent-summary?period=week|month (family role).
  Future<Map<String, dynamic>> getParentSummary(
    String childId, {
    String period = 'week',
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('Not authenticated');
    final uri = Uri.parse(
      AppConstants.baseUrl +
          AppConstants.progressAiParentSummaryEndpoint(childId, period: period),
    );
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
        throw Exception(err['message'] ?? 'Failed to load summary');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Failed to load: ${response.statusCode}');
      }
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
