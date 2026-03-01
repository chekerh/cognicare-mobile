import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/training_service.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';

const Color _primary = Color(0xFFADD8E6);
const Color _bg = Color(0xFFF8FAFC);

/// Course content: sections then "Start Quiz". User must complete content before quiz.
class FamilyTrainingCourseScreen extends StatefulWidget {
  const FamilyTrainingCourseScreen({
    super.key,
    required this.courseId,
    this.title = 'Cours',
  });

  final String courseId;
  final String title;

  @override
  State<FamilyTrainingCourseScreen> createState() =>
      _FamilyTrainingCourseScreenState();
}

class _FamilyTrainingCourseScreenState extends State<FamilyTrainingCourseScreen> {
  final TrainingService _service = TrainingService();
  Map<String, dynamic>? _course;
  bool _loading = true;
  String? _error;
  bool _markingComplete = false;

  String get _courseId => widget.courseId;
  String get _title => widget.title;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final id = _courseId;
    if (id.isEmpty) {
      setState(() => _error = 'Cours inconnu');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final course = await _service.getCourse(id);
      if (mounted) {
        setState(() {
          _course = course;
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

  Future<void> _onStartQuiz() async {
    final id = _courseId;
    if (id.isEmpty) return;
    setState(() => _markingComplete = true);
    try {
      await _service.markContentCompleted(id);
      if (!mounted) return;
      if (!mounted) return;
      context.push(AppConstants.familyTrainingQuizRoute, extra: {'courseId': id, 'title': _title});
    } catch (_) {}
    if (mounted) setState(() => _markingComplete = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(_title, style: const TextStyle(color: AppTheme.text, fontSize: 18)),
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
              ? Center(child: Text(_error!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_course?['description'] != null &&
                          (_course!['description'] as String).isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Text(
                            _course!['description'] as String,
                            style: TextStyle(
                              fontSize: 15,
                              color: AppTheme.text.withOpacity(0.9),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ..._buildSections(),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _markingComplete ? null : _onStartQuiz,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: AppTheme.text,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _markingComplete
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Commencer le quiz'),
                        ),
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
    );
  }

  List<Widget> _buildSections() {
    final sections = _course?['contentSections'] as List<dynamic>? ?? [];
    final list = <Widget>[];
    for (var i = 0; i < sections.length; i++) {
      final s = sections[i] is Map<String, dynamic> ? sections[i] as Map<String, dynamic> : <String, dynamic>{};
      final type = s['type'] as String? ?? 'text';
      final title = s['title'] as String?;
      final content = s['content'] as String?;
      final listItems = s['listItems'] as List<dynamic>?;
      final definitions = s['definitions'] as Map<String, dynamic>?;
      final videoUrl = s['videoUrl'] as String?;
      if (title != null && title.isNotEmpty) {
        list.add(Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.text,
            ),
          ),
        ));
      }
      if (content != null && content.isNotEmpty) {
        list.add(Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            content,
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.text.withOpacity(0.9),
              height: 1.5,
            ),
          ),
        ));
      }
      if (listItems != null && listItems.isNotEmpty) {
        list.add(Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: listItems.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: _primary, fontWeight: FontWeight.bold)),
                  Expanded(child: Text(e.toString(), style: TextStyle(fontSize: 15, color: AppTheme.text.withOpacity(0.9)))),
                ],
              ),
            )).toList(),
          ),
        ));
      }
      if (definitions != null && definitions.isNotEmpty) {
        for (final entry in definitions.entries) {
          list.add(Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 15, color: AppTheme.text.withOpacity(0.9)),
                children: [
                  TextSpan(text: '${entry.key}: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: entry.value.toString()),
                ],
              ),
            ),
          ));
        }
      }
      if (videoUrl != null && videoUrl.isNotEmpty) {
        list.add(Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {},
            child: Row(
              children: [
                Icon(Icons.video_library, color: _primary),
                const SizedBox(width: 8),
                Expanded(child: Text(videoUrl, style: const TextStyle(color: _primary, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
        ));
      }
    }
    if (list.isEmpty) {
      list.add(const Padding(
        padding: EdgeInsets.only(top: 16),
        child: Text('Contenu à venir.', style: TextStyle(color: AppTheme.text)),
      ));
    }
    return list;
  }
}
