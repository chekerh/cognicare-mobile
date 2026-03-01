import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/training_service.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';

const Color _primary = Color(0xFFADD8E6);
const Color _bg = Color(0xFFF8FAFC);

/// Autism training for caregivers (and volunteers) — list of courses with progression.
class FamilyTrainingListScreen extends StatefulWidget {
  const FamilyTrainingListScreen({super.key, this.fromVolunteer = false});

  final bool fromVolunteer;

  @override
  State<FamilyTrainingListScreen> createState() =>
      _FamilyTrainingListScreenState();
}

class _FamilyTrainingListScreenState extends State<FamilyTrainingListScreen> {
  final TrainingService _service = TrainingService();
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _enrollments = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _service.getCourses(),
        _service.myEnrollments(),
      ]);
      if (mounted) {
        setState(() {
          _courses = results[0] as List<Map<String, dynamic>>;
          _enrollments = results[1] as List<Map<String, dynamic>>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  bool _isEnrolled(String courseId) {
    return _enrollments.any((e) => e['courseId'] == courseId);
  }

  bool _isCompleted(String courseId) {
    for (final e in _enrollments) {
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

  Future<void> _openCourse(String courseId, String title, bool alreadyEnrolled) async {
    if (!alreadyEnrolled) {
      try {
        await _service.enroll(courseId);
        if (mounted) _load();
      } catch (_) {}
    }
    if (!mounted) return;
    context.push('course', extra: {'courseId': courseId, 'title': title});
  }

  @override
  Widget build(BuildContext context) {
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
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _load,
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
                  onRefresh: _load,
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
                      ...(_courses
                        ..sort((a, b) =>
                            (_courseOrder(a) ?? 0).compareTo(_courseOrder(b) ?? 0)))
                          .map((course) {
                        final id = course['id'] as String? ?? '';
                        final title = course['title'] as String? ?? 'Cours';
                        final desc = course['description'] as String? ?? '';
                        final completed = _isCompleted(id);
                        final enrolled = _isEnrolled(id);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: InkWell(
                            onTap: () => _openCourse(id, title, enrolled),
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
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.text,
                                          ),
                                        ),
                                      ),
                                      if (completed)
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
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () => _openCourse(id, title, enrolled),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _primary,
                                        foregroundColor: AppTheme.text,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Text(
                                        completed
                                            ? 'Revoir le cours'
                                            : enrolled
                                                ? 'Continuer'
                                                : 'Commencer',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      if (_courses.isEmpty)
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
  }
}
