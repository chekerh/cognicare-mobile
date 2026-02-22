import 'package:flutter/material.dart';
import '../../services/courses_service.dart';

const Color _primary = Color(0xFFA4D9E5);
const Color _background = Color(0xFFF8FAFC);

class VolunteerCoursesScreen extends StatefulWidget {
  const VolunteerCoursesScreen({super.key});

  @override
  State<VolunteerCoursesScreen> createState() => _VolunteerCoursesScreenState();
}

class _VolunteerCoursesScreenState extends State<VolunteerCoursesScreen> {
  final CoursesService _coursesService = CoursesService();
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _enrollments = [];
  bool _loading = true;
  bool _qualificationOnly = true;
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
      final courses = await _coursesService.getCourses(
          qualificationOnly: _qualificationOnly);
      final enrollments = await _coursesService.myEnrollments();
      if (mounted) {
        setState(() {
          _courses = courses;
          _enrollments = enrollments;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _enroll(String courseId) async {
    try {
      await _coursesService.enroll(courseId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Inscription enregistrée'),
              backgroundColor: Colors.green),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  bool _isEnrolled(String courseId) {
    return _enrollments.any((e) => e['courseId'] == courseId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _primary,
        title: const Text('Formations qualifiantes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
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
                            onPressed: _load, child: const Text('Réessayer')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SwitchListTile(
                          title:
                              const Text('Formations qualifiantes uniquement'),
                          value: _qualificationOnly,
                          onChanged: (v) {
                            setState(() => _qualificationOnly = v);
                            _load();
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Mes inscriptions',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        if (_enrollments.isEmpty)
                          const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('Aucune inscription pour le moment.'),
                            ),
                          )
                        else
                          ..._enrollments.map((e) {
                            final course = e['course'] as Map<String, dynamic>?;
                            final title = course?['title'] ?? 'Cours';
                            final progress = e['progressPercent'] as int? ?? 0;
                            final status = e['status'] as String? ?? 'enrolled';
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _primary.withOpacity(0.3),
                                  child: Icon(
                                    status == 'completed'
                                        ? Icons.check
                                        : Icons.school,
                                    color: _primary,
                                  ),
                                ),
                                title: Text(title),
                                subtitle: Text(
                                    '$progress% • ${status == 'completed' ? 'Terminé' : 'En cours'}'),
                              ),
                            );
                          }),
                        const SizedBox(height: 24),
                        const Text(
                          'Cours disponibles',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        if (_courses.isEmpty)
                          const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'Aucun cours disponible pour le moment. Revenez plus tard.',
                              ),
                            ),
                          )
                        else
                          ..._courses.map((c) {
                            final id = c['id'] as String? ?? '';
                            final title = c['title'] as String? ?? 'Cours';
                            final desc = c['description'] as String? ?? '';
                            final enrolled = _isEnrolled(id);
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            title,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        if (enrolled)
                                          const Chip(
                                            label: Text('Inscrit'),
                                            backgroundColor: Colors.green,
                                          )
                                        else
                                          TextButton(
                                            onPressed: () => _enroll(id),
                                            child: const Text('S\'inscrire'),
                                          ),
                                      ],
                                    ),
                                    if (desc.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        desc,
                                        style: const TextStyle(
                                            fontSize: 14, color: Colors.grey),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
    );
  }
}
