import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/training_service.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';

const Color _primary = Color(0xFFADD8E6);
const Color _bg = Color(0xFFF8FAFC);

/// Quiz after course: multiple-choice / true-false, submit, show score and correct answers. Pass threshold 80%.
class FamilyTrainingQuizScreen extends StatefulWidget {
  const FamilyTrainingQuizScreen({
    super.key,
    required this.courseId,
    this.title = 'Quiz',
    this.initialQuiz,
  });

  final String courseId;
  final String title;
  /// When provided, questions are taken from here and no API getCourse call is made.
  final List<dynamic>? initialQuiz;

  @override
  State<FamilyTrainingQuizScreen> createState() =>
      _FamilyTrainingQuizScreenState();
}

class _FamilyTrainingQuizScreenState extends State<FamilyTrainingQuizScreen> {
  final TrainingService _service = TrainingService();
  List<Map<String, dynamic>> _questions = [];
  final List<int> _selected = [];
  final List<TextEditingController> _textControllers = [];
  bool _loading = true;
  String? _error;
  bool _submitted = false;
  int? _scorePercent;
  bool? _passed;
  List<Map<String, dynamic>> _review = [];

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
      List<Map<String, dynamic>> questions = [];
      final rawQuiz = widget.initialQuiz;
      if (rawQuiz is List<dynamic> && rawQuiz.isNotEmpty) {
        for (final e in rawQuiz) {
          if (e is Map<String, dynamic>) questions.add(e);
        }
      } else {
        final course = await _service.getCourse(widget.courseId);
        final quiz = course['quiz'] is List<dynamic> ? course['quiz'] as List<dynamic> : <dynamic>[];
        for (final e in quiz) {
          if (e is Map<String, dynamic>) questions.add(e);
        }
      }
      if (mounted) {
        for (final c in _textControllers) {
          c.dispose();
        }
        _textControllers.clear();
        setState(() {
          _questions = questions;
          _selected.clear();
          for (var i = 0; i < questions.length; i++) {
            _selected.add(-1);
            _textControllers.add(TextEditingController());
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

  bool _isFillBlank(int i) {
    if (i >= _questions.length) return false;
    final type = _questions[i]['type'] as String?;
    return type == 'fill_blank';
  }

  Future<void> _submit() async {
    for (var i = 0; i < _questions.length; i++) {
      if (_isFillBlank(i)) {
        if (i < _textControllers.length &&
            _textControllers[i].text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Répondez à toutes les questions')),
          );
          return;
        }
      } else if (_selected[i] < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Répondez à toutes les questions')),
        );
        return;
      }
    }
    setState(() => _loading = true);
    try {
      final textAnswers = _questions.asMap().keys.map((i) {
        if (_isFillBlank(i) && i < _textControllers.length) {
          return _textControllers[i].text;
        }
        return '';
      }).toList();
      final result = await _service.submitQuiz(
        widget.courseId,
        _selected,
        textAnswers: textAnswers,
      );
      if (mounted) {
        final rawReview = result['review'];
        final review = rawReview is List<dynamic>
            ? rawReview
                .map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{})
                .toList()
            : <Map<String, dynamic>>[];
        setState(() {
          _scorePercent = result['scorePercent'] as int?;
          _passed = result['passed'] as bool?;
          _review = review;
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
                                final type = q['type'] as String? ?? 'mcq';
                                final options = (q['options'] as List<dynamic>?)?.cast<String>() ?? [];
                                final isFillBlank = type == 'fill_blank';
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
                                      if (isFillBlank)
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 8),
                                          child: TextField(
                                            controller: i < _textControllers.length
                                                ? _textControllers[i]
                                                : null,
                                            onChanged: (_) => setState(() {}),
                                            decoration: InputDecoration(
                                              hintText: 'Votre réponse',
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              filled: true,
                                              fillColor: Colors.white,
                                            ),
                                            style: const TextStyle(color: AppTheme.text),
                                          ),
                                        )
                                      else
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Icon(
            passed ? Icons.check_circle : Icons.cancel,
            size: 80,
            color: passed ? Colors.green : Colors.orange,
          ),
          const SizedBox(height: 24),
          Text(
            passed ? 'Quiz réussi' : 'Quiz non réussi',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Score: $score%',
            textAlign: TextAlign.center,
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
          if (_review.isNotEmpty) ...[
            const SizedBox(height: 28),
            const Text(
              'Corrections',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.text,
              ),
            ),
            const SizedBox(height: 12),
            ..._review.asMap().entries.map((entry) {
              final i = entry.key;
              final r = entry.value;
              final isCorrect = r['isCorrect'] == true;
              final questionText = i < _questions.length
                  ? (_questions[i]['question'] as String? ?? '')
                  : 'Question ${i + 1}';
              final correctOptionText = r['correctOptionText'] as String?;
              final correctAnswer = r['correctAnswer'] as String?;
              final userAnswer = r['userAnswer'] as String?;
              final correctLabel = correctOptionText ?? correctAnswer ?? '';
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? Colors.green.withOpacity(0.08)
                        : Colors.orange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCorrect ? Colors.green : Colors.orange,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isCorrect ? Icons.check_circle : Icons.cancel,
                            size: 20,
                            color: isCorrect ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              questionText,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppTheme.text,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (correctLabel.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Réponse correcte: $correctLabel',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.text.withOpacity(0.9),
                          ),
                        ),
                      ],
                      if (userAnswer != null && userAnswer.isNotEmpty && !isCorrect)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Votre réponse: $userAnswer',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.text.withOpacity(0.7),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final path = GoRouterState.of(context).uri.path;
                final trainingListPath = path.replaceFirst(RegExp(r'/quiz$'), '');
                context.go(trainingListPath.isNotEmpty ? trainingListPath : '/family/training');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: AppTheme.text,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Retour aux formations'),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}
