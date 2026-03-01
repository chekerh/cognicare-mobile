import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/training_service.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';

const Color _primary = Color(0xFFADD8E6);
const Color _bg = Color(0xFFF8FAFC);

/// Quiz after course: multiple-choice, submit, show score. Pass threshold 70%.
class FamilyTrainingQuizScreen extends StatefulWidget {
  const FamilyTrainingQuizScreen({
    super.key,
    required this.courseId,
    this.title = 'Quiz',
  });

  final String courseId;
  final String title;

  @override
  State<FamilyTrainingQuizScreen> createState() =>
      _FamilyTrainingQuizScreenState();
}

class _FamilyTrainingQuizScreenState extends State<FamilyTrainingQuizScreen> {
  final TrainingService _service = TrainingService();
  List<Map<String, dynamic>> _questions = [];
  final List<int> _selected = [];
  bool _loading = true;
  String? _error;
  bool _submitted = false;
  int? _scorePercent;
  bool? _passed;

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
      final course = await _service.getCourse(widget.courseId);
      final quiz = course['quiz'] as List<dynamic>? ?? [];
      final questions = quiz.map((e) => e as Map<String, dynamic>).toList();
      if (mounted) {
        setState(() {
          _questions = questions;
          _selected.clear();
          for (var i = 0; i < questions.length; i++) {
            _selected.add(-1);
          }
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

  Future<void> _submit() async {
    if (_selected.any((i) => i < 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Répondez à toutes les questions')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await _service.submitQuiz(widget.courseId, _selected);
      if (mounted) {
        setState(() {
          _scorePercent = result['scorePercent'] as int?;
          _passed = result['passed'] as bool?;
          _submitted = true;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text('Quiz — ${widget.title}', style: const TextStyle(color: AppTheme.text, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.text, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading && !_submitted
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : _error != null && !_submitted
              ? Center(child: Text(_error!))
              : _submitted
                  ? _buildResult()
                  : _questions.isEmpty
                      ? const Center(child: Text('Aucune question dans ce quiz.'))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Choisissez une réponse par question.',
                                style: TextStyle(color: AppTheme.text),
                              ),
                              const SizedBox(height: 24),
                              ...List.generate(_questions.length, (i) {
                                final q = _questions[i];
                                final question = q['question'] as String? ?? '';
                                final options = (q['options'] as List<dynamic>?)?.cast<String>() ?? [];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 24),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${i + 1}. $question',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: AppTheme.text,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      ...List.generate(options.length, (j) {
                                        final selected = _selected[i] == j;
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 8),
                                          child: InkWell(
                                            onTap: () {
                                              setState(() => _selected[i] = j);
                                            },
                                            borderRadius: BorderRadius.circular(12),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                              decoration: BoxDecoration(
                                                color: selected ? _primary.withOpacity(0.3) : Colors.white,
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: selected ? _primary : Colors.grey.shade300,
                                                  width: selected ? 2 : 1,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    selected ? Icons.radio_button_checked : Icons.radio_button_off,
                                                    color: selected ? _primary : Colors.grey,
                                                    size: 22,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(child: Text(options[j], style: const TextStyle(color: AppTheme.text))),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                );
                              }),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _primary,
                                    foregroundColor: AppTheme.text,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  child: const Text('Valider le quiz'),
                                ),
                              ),
                              const SizedBox(height: 48),
                            ],
                          ),
                        ),
    );
  }

  Widget _buildResult() {
    final passed = _passed ?? false;
    final score = _scorePercent ?? 0;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              passed ? Icons.check_circle : Icons.cancel,
              size: 80,
              color: passed ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 24),
            Text(
              passed ? 'Quiz réussi' : 'Quiz non réussi',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Score: $score%',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.text.withOpacity(0.8),
              ),
            ),
            if (!passed)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  'Vous pouvez reprendre le cours et réessayer le quiz.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.text),
                ),
              ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go('..'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: AppTheme.text,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Retour aux formations'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
