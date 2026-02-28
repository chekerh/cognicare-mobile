import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../utils/constants.dart';
import '../../services/volunteer_service.dart';

const Color _primary = Color(0xFFa3dae1);
const Color _background = Color(0xFFF8FAFC);
const Color _cardBg = Color(0xFFFFFFFF);
const Color _textPrimary = Color(0xFF1E293B);
const Color _textSecondary = Color(0xFF64748B);

/// Certification test for volunteers: MCQ and short answer, then submit.
/// On pass, backend sets trainingCertified; Agenda and Messages unlock.
class VolunteerCertificationTestScreen extends StatefulWidget {
  const VolunteerCertificationTestScreen({super.key});

  @override
  State<VolunteerCertificationTestScreen> createState() =>
      _VolunteerCertificationTestScreenState();
}

class _VolunteerCertificationTestScreenState
    extends State<VolunteerCertificationTestScreen> {
  final VolunteerService _volunteerService = VolunteerService();
  Map<String, dynamic>? _testData;
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  final Map<int, String> _answers = {};

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
    ));
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _testData = null;
      _answers.clear();
    });
    try {
      final data = await _volunteerService.getCertificationTest();
      if (!mounted) return;
      if (data['alreadyCertified'] == true) {
        _showAlreadyCertifiedAndPop();
        return;
      }
      setState(() => _testData = data);
    } catch (e) {
      if (mounted) {
        setState(
            () => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showAlreadyCertifiedAndPop() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Déjà certifié'),
        content: const Text(
          'Vous avez déjà obtenu la certification. Vous pouvez accéder à l\'Agenda et aux Messages.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _primary),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go(AppConstants.volunteerFormationsRoute);
            },
            child: const Text('Retour aux formations'),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _questions {
    final list = _testData?['questions'] as List<dynamic>?;
    if (list == null) return [];
    return list
        .map((e) => (e as Map<String, dynamic>))
        .toList();
  }

  int? get _passingScore =>
      _testData?['passingScorePercent'] as int?;

  Future<void> _submit() async {
    final answers = _questions
        .map((q) {
          final index = q['index'] as int? ?? 0;
          final value = _answers[index]?.trim() ?? '';
          return {'questionIndex': index, 'value': value};
        })
        .toList();
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final result = await _volunteerService.submitCertificationTest(answers);
      if (!mounted) return;
      final passed = result['passed'] == true;
      final certified = result['certified'] == true;
      final scorePercent = (result['scorePercent'] as num?)?.toInt() ?? 0;
      final totalQuestions = (result['totalQuestions'] as num?)?.toInt() ?? 0;
      final correctCount = (result['correctCount'] as num?)?.toInt() ?? 0;

      if (passed && certified) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700, size: 28),
                const SizedBox(width: 8),
                const Text('Certification obtenue'),
              ],
            ),
            content: Text(
              'Félicitations ! Vous avez réussi le test ($correctCount/$totalQuestions). '
              'L\'Agenda et les Messages sont maintenant accessibles.',
            ),
            actions: [
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _primary),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.go(AppConstants.volunteerFormationsRoute);
                },
                child: const Text('Retour aux formations'),
              ),
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Test non réussi'),
            content: Text(
              'Score : $scorePercent% ($correctCount/$totalQuestions). '
              'Il faut ${_passingScore ?? 80}% pour valider. Vous pouvez réessayer.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Fermer'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _primary),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _load();
                },
                child: const Text('Réessayer'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() =>
            _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text('Test de certification'),
        backgroundColor: _cardBg,
        foregroundColor: _textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(AppConstants.volunteerFormationsRoute),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : _error != null
              ? _buildError()
              : _testData == null
                  ? const SizedBox.shrink()
                  : _buildTest(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _primary),
              onPressed: () {
                context.go(AppConstants.volunteerFormationsRoute);
              },
              child: const Text('Retour aux formations'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTest() {
    final questions = _questions;
    if (questions.isEmpty) {
      return const Center(child: Text('Aucune question disponible.'));
    }
    final passingScore = _passingScore ?? 80;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Text(
            _testData?['title'] as String? ?? 'Test de certification',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Text(
            'Réussite à partir de $passingScore %. ${questions.length} question(s).',
            style: const TextStyle(fontSize: 14, color: _textSecondary),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            itemCount: questions.length,
            itemBuilder: (context, i) {
              final q = questions[i];
              return _QuestionCard(
                question: q,
                value: _answers[q['index'] as int? ?? i],
                onChanged: (v) {
                  setState(() =>
                      _answers[q['index'] as int? ?? i] = v);
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Envoyer les réponses'),
          ),
        ),
      ],
    );
  }
}

class _QuestionCard extends StatefulWidget {
  final Map<String, dynamic> question;
  final String? value;
  final ValueChanged<String> onChanged;

  const _QuestionCard({
    required this.question,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value ?? '');
  }

  @override
  void didUpdateWidget(covariant _QuestionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && widget.value != _controller.text) {
      _controller.text = widget.value ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.question['type'] as String? ?? 'mcq';
    final text = widget.question['text'] as String? ?? '';
    final index = (widget.question['index'] as num?)?.toInt() ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: _cardBg,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${index + 1}. $text',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            if (type == 'mcq') ...[
              ...((widget.question['options'] as List<dynamic>?) ?? []).map((opt) {
                final option = opt as String;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: RadioListTile<String>(
                    value: option,
                    groupValue: widget.value,
                    onChanged: (v) {
                      if (v != null) widget.onChanged(v);
                    },
                    title: Text(
                      option,
                      style: const TextStyle(
                        fontSize: 14,
                        color: _textPrimary,
                      ),
                    ),
                    activeColor: _primary,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                );
              }),
            ] else
              TextField(
                controller: _controller,
                onChanged: widget.onChanged,
                decoration: InputDecoration(
                  hintText: 'Votre réponse',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _primary, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
