import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/training_service.dart';
import '../../utils/theme.dart';

// Quiz Premium UI : primary #3fb1c1, gradient, radio cards, glow button
const Color _primary = Color(0xFF3fb1c1);
const Color _secondary = Color(0xFFa3dae1);
const Color _bgLight = Color(0xFFf8fdfe);
const Color _slate800 = Color(0xFF1e293b);
const Color _slate700 = Color(0xFF334155);
const Color _slate500 = Color(0xFF64748B);

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

  double get _progress {
    if (_questions.isEmpty) return 0.45;
    final answered = _selected.where((s) => s >= 0).length;
    return answered / _questions.length;
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: _bgLight,
      body: _loading && !_submitted
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : _error != null && !_submitted
              ? Center(child: Text(_error!, style: const TextStyle(color: _slate800)))
              : _submitted
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: _buildResultContent(),
                    )
                  : Stack(
                      children: [
                        CustomScrollView(
                          slivers: [
                            SliverToBoxAdapter(child: _buildPremiumHeader(topPadding)),
                            SliverToBoxAdapter(
                              child: Container(
                                padding: const EdgeInsets.only(top: 24, left: 20, right: 20, bottom: 140),
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Color(0xFFf0f9fa), Color(0xFFa3dae1)],
                                  ),
                                ),
                                child: _questions.isEmpty
                                    ? const Center(
                                        child: Text(
                                          'Aucune question dans ce quiz.',
                                          style: TextStyle(color: _slate700),
                                        ),
                                      )
                                    : Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Center(
                                            child: Text(
                                              'Quiz — Module 1',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w800,
                                                color: _slate800,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Center(
                                            child: Text(
                                              'RÉPONDEZ AUX QUESTIONS POUR VALIDER VOS ACQUIS',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                letterSpacing: 1.2,
                                                color: _slate500,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 32),
                                          ...List.generate(_questions.length, (i) {
                                            final q = _questions[i];
                                            final question = q['question'] as String? ?? '';
                                            final type = q['type'] as String? ?? 'mcq';
                                            final options = (q['options'] as List<dynamic>?)?.cast<String>() ?? [];
                                            final isFillBlank = type == 'fill_blank';
                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 40),
                                              child: _buildQuestionBlock(i, question, isFillBlank, options),
                                            );
                                          }),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                        if (!_loading && _questions.isNotEmpty && !_submitted)
                          Positioned(
                            left: 24,
                            right: 24,
                            bottom: 24 + bottomPadding,
                            child: _buildValidateButton(),
                          ),
                      ],
                    ),
    );
  }

  Widget _buildPremiumHeader(double topPadding) {
    return Container(
      padding: EdgeInsets.only(top: topPadding, left: 20, right: 20, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Material(
                    color: Colors.grey.shade100.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(999),
                    child: InkWell(
                      onTap: () => context.pop(),
                      borderRadius: BorderRadius.circular(999),
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(Icons.chevron_left, color: _slate700, size: 28),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'QUIZ PREMIUM',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: _primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      SizedBox(
                        width: 200,
                        child: Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _slate800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const SizedBox(width: 40, height: 40),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(_primary),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 16,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildValidateButton() {
    return Material(
      borderRadius: BorderRadius.circular(32),
      elevation: 8,
      shadowColor: _primary.withOpacity(0.4),
      color: _secondary,
      child: InkWell(
        onTap: _loading ? null : _submit,
        borderRadius: BorderRadius.circular(32),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          alignment: Alignment.center,
          child: _loading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Valider mes réponses',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.task_alt, color: Colors.white, size: 24),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildQuestionBlock(int i, String question, bool isFillBlank, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: _primary.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                '${i + 1}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                question,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: _slate800,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (isFillBlank)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _primary.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: i < _textControllers.length ? _textControllers[i] : null,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Votre réponse',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(fontSize: 15, color: _slate700),
            ),
          )
        else
          ...List.generate(options.length, (j) {
            final selected = _selected[i] == j;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                elevation: 2,
                shadowColor: _primary.withOpacity(0.15),
                child: InkWell(
                  onTap: () => setState(() => _selected[i] = j),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    decoration: BoxDecoration(
                      color: selected ? _primary.withOpacity(0.05) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected ? _primary : Colors.transparent,
                        width: selected ? 2 : 0,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: _primary.withOpacity(0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selected ? _primary : Colors.transparent,
                            border: Border.all(
                              color: selected ? _primary : Colors.grey.shade300,
                              width: 2,
                            ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: _primary.withOpacity(0.2),
                                      blurRadius: 4,
                                      spreadRadius: 0,
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: selected
                              ? const Icon(Icons.circle, size: 8, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            options[j],
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: _slate700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildResultContent() {
    final passed = _passed ?? false;
    final score = _scorePercent ?? 0;
    return Column(
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
            color: _slate800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Score: $score%',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, color: _slate500),
        ),
        if (!passed)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text(
              'Vous pouvez reprendre le cours et réessayer le quiz.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _slate700),
            ),
          ),
        if (_review.isNotEmpty) ...[
          const SizedBox(height: 28),
          const Text(
            'Corrections',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _slate800,
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
                              color: _slate800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (correctLabel.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Réponse correcte: $correctLabel',
                        style: const TextStyle(fontSize: 13, color: _slate700),
                      ),
                    ],
                    if (userAnswer != null && userAnswer.isNotEmpty && !isCorrect)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Votre réponse: $userAnswer',
                          style: const TextStyle(fontSize: 12, color: _slate500),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
        const SizedBox(height: 32),
        Material(
          borderRadius: BorderRadius.circular(32),
          elevation: 8,
          shadowColor: _primary.withOpacity(0.4),
          color: _secondary,
          child: InkWell(
            onTap: () {
              final path = GoRouterState.of(context).uri.path;
              final trainingListPath = path.replaceFirst(RegExp(r'/quiz$'), '');
              context.go(trainingListPath.isNotEmpty ? trainingListPath : '/family/training');
            },
            borderRadius: BorderRadius.circular(32),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              alignment: Alignment.center,
              child: const Text(
                'Retour aux formations',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 48),
      ],
    );
  }
}
