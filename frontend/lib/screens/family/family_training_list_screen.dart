import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/training_cache_provider.dart';
import '../../services/training_service.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';

const Color _primary = Color(0xFFADD8E6);
const Color _bg = Color(0xFFF8FAFC);

/// Autism training for caregivers (and volunteers) — list of courses with progression.
/// Uses [TrainingCacheProvider] for cached data and state management.
class FamilyTrainingListScreen extends StatefulWidget {
  const FamilyTrainingListScreen({super.key, this.fromVolunteer = false});

  final bool fromVolunteer;

  @override
  State<FamilyTrainingListScreen> createState() =>
      _FamilyTrainingListScreenState();
}

class _FamilyTrainingListScreenState extends State<FamilyTrainingListScreen> {
  final TrainingService _service = TrainingService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TrainingCacheProvider>(context, listen: false).load();
    });
  }

  bool _isEnrolled(List<Map<String, dynamic>> enrollments, String courseId) {
    return enrollments.any((e) => e['courseId'] == courseId);
  }

  bool _isCompleted(List<Map<String, dynamic>> enrollments, String courseId) {
    for (final e in enrollments) {
      if (e['courseId'] == courseId) {
        final progress = (e['progressPercent'] as num?)?.toInt() ?? 0;
        final passed = e['quizPassed'] == true;
        if (progress >= 100 && passed) return true;
      }
    }
    return false;
  }

  int? _courseOrder(Map<String, dynamic> c) =>
      c['order'] is int ? c['order'] as int : null;

  bool _isUnlocked(
    List<Map<String, dynamic>> courses,
    List<Map<String, dynamic>> enrollments,
    String? nextCourseId,
    String courseId,
  ) {
    if (_isCompleted(enrollments, courseId)) return true;
    if (nextCourseId == courseId) return true;
    final course = courses.firstWhere(
      (c) => c['id'] == courseId,
      orElse: () => <String, dynamic>{},
    );
    if (course.isEmpty) return false;
    final currentOrder = _courseOrder(course);
    if (currentOrder == null) return false;
    for (final c in courses) {
      final order = _courseOrder(c);
      if (order != null && order < currentOrder) {
        final prevId = c['id'] as String? ?? '';
        if (!_isCompleted(enrollments, prevId)) return false;
      }
    }
    return true;
  }

  Future<void> _openCourse(
    TrainingCacheProvider provider,
    String courseId,
    String title,
    bool alreadyEnrolled,
    List<Map<String, dynamic>> courses,
    List<Map<String, dynamic>> enrollments,
    String? nextCourseId,
  ) async {
    if (!_isUnlocked(courses, enrollments, nextCourseId, courseId)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Complétez le cours précédent et son quiz pour débloquer ce cours.'),
          ),
        );
      }
      return;
    }
    if (!alreadyEnrolled) {
      try {
        await _service.enroll(courseId);
        if (mounted) await provider.load(forceRefresh: true);
      } catch (_) {}
    }
    if (!mounted) return;
    context.push('course', extra: {'courseId': courseId, 'title': title});
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TrainingCacheProvider>(
      builder: (context, provider, _) {
        final courses = provider.courses;
        final enrollments = provider.enrollments;
        final nextCourseId = provider.nextCourseId;
        final loading = provider.loading;
        final error = provider.error;

        return Scaffold(
          backgroundColor: _bg,
          appBar: AppBar(
            title: const Text('Formation Autisme', style: TextStyle(color: AppTheme.text)),
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.text, size: 20),
              onPressed: () => context.pop(),
            ),
          ),
          body: loading && !provider.isLoaded
              ? const Center(child: CircularProgressIndicator(color: _primary))
              : error != null && courses.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(error, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => provider.load(forceRefresh: true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primary,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => provider.load(forceRefresh: true),
                      color: _primary,
                      child: ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          const Text(
                            'Cours reconnus pour les aidants. Complétez le contenu puis le quiz pour valider.',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.text,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ...(List<Map<String, dynamic>>.from(courses)
                            ..sort((a, b) =>
                                (_courseOrder(a) ?? 0).compareTo(_courseOrder(b) ?? 0)))
                              .map((course) {
                            final id = course['id'] as String? ?? '';
                            final title = course['title'] as String? ?? 'Cours';
                            final desc = course['description'] as String? ?? '';
                            final completed = _isCompleted(enrollments, id);
                            final enrolled = _isEnrolled(enrollments, id);
                            final unlocked = _isUnlocked(courses, enrollments, nextCourseId, id);
                            return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                            child: InkWell(
                            onTap: () => _openCourse(
                                provider, id, title, enrolled,
                                courses, enrollments, nextCourseId),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          title,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: unlocked
                                                ? AppTheme.text
                                                : AppTheme.text.withOpacity(0.6),
                                          ),
                                        ),
                                      ),
                                      if (!unlocked)
                                        const Icon(
                                          Icons.lock_outline,
                                          color: Colors.grey,
                                          size: 28,
                                        )
                                      else if (completed)
                                        const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                          size: 28,
                                        )
                                      else if (enrolled)
                                        const Icon(
                                          Icons.play_circle_outline,
                                          color: _primary,
                                          size: 28,
                                        ),
                                    ],
                                  ),
                                  if (desc.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      desc,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.text.withOpacity(0.8),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  if (!unlocked)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        'Complétez le cours précédent et son quiz.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.orange.shade700,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: unlocked
                                          ? () => _openCourse(
                                              provider, id, title, enrolled,
                                              courses, enrollments, nextCourseId)
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _primary,
                                        foregroundColor: AppTheme.text,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        disabledBackgroundColor: Colors.grey.shade300,
                                        disabledForegroundColor: Colors.grey.shade600,
                                      ),
                                      child: Text(
                                        completed
                                            ? 'Revoir le cours'
                                            : unlocked
                                                ? (enrolled ? 'Continuer' : 'Commencer')
                                                : 'Verrouillé',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      if (courses.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 48),
                          child: Center(
                            child: Text(
                              'Aucun cours disponible pour le moment.',
                              style: TextStyle(color: AppTheme.text),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
