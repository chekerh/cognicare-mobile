import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/progress_ai_service.dart';
import '../../utils/constants.dart';

const Color _primary = Color(0xFFA2D9E7);
const Color _brand = Color(0xFF2D7DA1);

/// Computes progress 0.0..1.0 and optional milestone label from a specialized plan.
({double progress, String? milestone}) planProgress(Map<String, dynamic> plan) {
  final type = plan['type'] as String?;
  final content = plan['content'] as Map<String, dynamic>? ?? {};
  if (type == 'PECS') {
    final items = content['items'] as List<dynamic>? ?? [];
    int pass = 0, total = 0;
    for (final it in items) {
      final trials = (it is Map ? (it as Map)['trials'] : null) as List<dynamic>?;
      if (trials != null) {
        for (final t in trials) {
          if (t == true) pass++;
          if (t == true || t == false) total++;
        }
      }
    }
    if (total == 0) return (progress: 0.0, milestone: null);
    final p = pass / total;
    return (progress: p, milestone: '${pass}/${total} essais');
  }
  if (type == 'TEACCH') {
    final goals = content['goals'] as List<dynamic>? ?? [];
    double sumCur = 0, sumTarget = 0;
    for (final g in goals) {
      if (g is! Map) continue;
      final cur = (g['current'] is num) ? (g['current'] as num).toDouble() : 0.0;
      final tgt = (g['target'] is num) ? (g['target'] as num).toDouble() : 0.0;
      sumCur += cur;
      sumTarget += tgt;
    }
    if (sumTarget <= 0) return (progress: 0.0, milestone: null);
    final p = (sumCur / sumTarget).clamp(0.0, 1.0);
    return (progress: p, milestone: 'Objectifs ${(p * 100).round()}%');
  }
  if (type == 'SkillTracker') {
    final cur = (content['currentPercent'] is num)
        ? (content['currentPercent'] as num).toDouble()
        : 0.0;
    final tgt = (content['targetPercent'] is num)
        ? (content['targetPercent'] as num).toDouble()
        : 100.0;
    if (tgt <= 0) return (progress: 0.0, milestone: null);
    final p = (cur / tgt).clamp(0.0, 1.0);
    return (progress: p, milestone: '${cur.round()}% / ${tgt.round()}%');
  }
  if (type == 'Activity') {
    final status = content['status'] as String?;
    final p = status == 'completed' ? 1.0 : (status == 'in_progress' ? 0.5 : 0.0);
    return (progress: p, milestone: status ?? '—');
  }
  return (progress: 0.0, milestone: null);
}

/// AI-generated recommendations for a child (PECS, TEACCH, Skill Tracker, Activity).
/// Specialist can Approve, Modify, or Dismiss each recommendation.
class ProgressAiRecommendationsScreen extends StatefulWidget {
  const ProgressAiRecommendationsScreen({
    super.key,
    required this.childId,
    this.childName,
  });

  final String childId;
  final String? childName;

  @override
  State<ProgressAiRecommendationsScreen> createState() =>
      _ProgressAiRecommendationsScreenState();
}

class _ProgressAiRecommendationsScreenState
    extends State<ProgressAiRecommendationsScreen>
    with WidgetsBindingObserver {
  ProgressAiRecommendationResult? _result;
  String? _error;
  bool _loading = true;
  List<Map<String, dynamic>> _plans = [];
  bool _loadingPlans = false;
  Timer? _pollTimer;
  final Set<int> _feedbackSent = {};
  int? _pendingResultsImprovedIndex; // after approve/modify, show "results improved?" then send
  String? _pendingResultsImprovedAction;
  String? _pendingResultsImprovedEditedText;
  String? _pendingResultsImprovedOriginalText;
  String? _pendingResultsImprovedPlanType;
  String? _pendingRecommendationId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _loadPlans();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        _load();
        _loadPlans();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _load();
      _loadPlans();
    }
  }

  Future<void> _loadPlans() async {
    if (!mounted) return;
    setState(() => _loadingPlans = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final service = ProgressAiService(
      getToken: () async => authProvider.accessToken,
    );
    try {
      final list = await service.getPlansByChild(widget.childId);
      if (mounted) setState(() { _plans = list; _loadingPlans = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingPlans = false);
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final service = ProgressAiService(
      getToken: () async => authProvider.accessToken,
    );
    try {
      final result = await service.getRecommendations(widget.childId);
      if (mounted) {
        setState(() {
          _result = result;
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

  Future<void> _submitFeedback({
    required String recommendationId,
    required String action,
    String? editedText,
    String? originalRecommendationText,
    int? itemIndex,
    String? planType,
    bool? resultsImproved,
    bool? parentFeedbackHelpful,
  }) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final service = ProgressAiService(
      getToken: () async => authProvider.accessToken,
    );
    try {
      await service.submitFeedback(
        recommendationId: recommendationId,
        childId: widget.childId,
        action: action,
        editedText: editedText,
        originalRecommendationText: originalRecommendationText,
        planType: planType,
        resultsImproved: resultsImproved,
        parentFeedbackHelpful: parentFeedbackHelpful,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              action == 'approved'
                  ? 'Recommandation approuvée'
                  : action == 'modified'
                      ? 'Modification enregistrée'
                      : 'Recommandation ignorée',
            ),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          if (itemIndex != null) _feedbackSent.add(itemIndex);
          _pendingResultsImprovedIndex = null;
          _pendingResultsImprovedAction = null;
          _pendingResultsImprovedEditedText = null;
          _pendingResultsImprovedOriginalText = null;
          _pendingResultsImprovedPlanType = null;
          _pendingRecommendationId = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _askResultsImprovedThenSubmit({
    required String recommendationId,
    required String action,
    String? editedText,
    String? originalRecommendationText,
    required int itemIndex,
    String? planType,
  }) {
    setState(() {
      _pendingRecommendationId = recommendationId;
      _pendingResultsImprovedAction = action;
      _pendingResultsImprovedEditedText = editedText;
      _pendingResultsImprovedOriginalText = originalRecommendationText;
      _pendingResultsImprovedPlanType = planType;
      _pendingResultsImprovedIndex = itemIndex;
    });
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Résultats améliorés ?'),
        content: const Text(
          'Après application de cette recommandation, les résultats se sont-ils améliorés ?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _submitFeedback(
                recommendationId: recommendationId,
                action: action,
                editedText: editedText,
                originalRecommendationText: originalRecommendationText,
                itemIndex: itemIndex,
                planType: planType,
                resultsImproved: false,
              );
            },
            child: const Text('Non'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _showParentFeedbackHelpfulDialog(
                recommendationId: recommendationId,
                action: action,
                editedText: editedText,
                originalRecommendationText: originalRecommendationText,
                itemIndex: itemIndex,
                planType: planType,
              );
            },
            child: const Text('Oui'),
          ),
        ],
      ),
    );
  }

  void _showParentFeedbackHelpfulDialog({
    required String recommendationId,
    required String action,
    String? editedText,
    String? originalRecommendationText,
    required int itemIndex,
    String? planType,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Retour du parent'),
        content: const Text(
          'Le retour du parent a-t-il été utile pour cette recommandation ?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _submitFeedback(
                recommendationId: recommendationId,
                action: action,
                editedText: editedText,
                originalRecommendationText: originalRecommendationText,
                itemIndex: itemIndex,
                planType: planType,
                resultsImproved: true,
                parentFeedbackHelpful: null,
              );
            },
            child: const Text('Passer'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _submitFeedback(
                recommendationId: recommendationId,
                action: action,
                editedText: editedText,
                originalRecommendationText: originalRecommendationText,
                itemIndex: itemIndex,
                planType: planType,
                resultsImproved: true,
                parentFeedbackHelpful: false,
              );
            },
            child: const Text('Non'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _submitFeedback(
                recommendationId: recommendationId,
                action: action,
                editedText: editedText,
                originalRecommendationText: originalRecommendationText,
                itemIndex: itemIndex,
                planType: planType,
                resultsImproved: true,
                parentFeedbackHelpful: true,
              );
            },
            child: const Text('Oui'),
          ),
        ],
      ),
    );
  }

  void _openRequestParentFeedbackDialog() {
    final messageController = TextEditingController();
    String? selectedPlanType;
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setDialogState) => AlertDialog(
            title: const Text('Demander un retour au parent'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Message optionnel à transmettre au parent :',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: messageController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Ex: Pouvez-vous nous dire si...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Domaine concerné (optionnel) :', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: ['PECS', 'TEACCH', 'SkillTracker', 'Activity']
                        .map((t) => ChoiceChip(
                              label: Text(t),
                              selected: selectedPlanType == t,
                              onSelected: (v) => setDialogState(() => selectedPlanType = v ? t : null),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  final service = ProgressAiService(getToken: () async => authProvider.accessToken);
                  try {
                    await service.requestParentFeedback(
                      childId: widget.childId,
                      message: messageController.text.trim().isEmpty ? null : messageController.text.trim(),
                      planType: selectedPlanType,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Demande de retour envoyée au parent'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString().replaceFirst('Exception: ', '')),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Envoyer'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openPreferencesDialog() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final service = ProgressAiService(getToken: () async => authProvider.accessToken);
    Map<String, dynamic>? prefs;
    try {
      prefs = await service.getPreferences();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de charger les préférences'), backgroundColor: Colors.red),
        );
      }
      return;
    }
    if (!mounted) return;
    final focusTypes = List<String>.from(prefs?['focusPlanTypes'] as List<dynamic>? ?? []);
    final planTypes = ['PECS', 'TEACCH', 'SkillTracker', 'Activity'];
    String summaryLength = prefs?['summaryLength'] as String? ?? 'short';
    String frequency = prefs?['frequency'] as String? ?? 'every_session';
    final weights = Map<String, double>.from(
      (prefs?['planTypeWeights'] as Map<String, dynamic>? ?? {}).map(
        (k, v) => MapEntry(k, (v is num) ? v.toDouble() : 1.0),
      ),
    );
    for (final t in planTypes) {
      weights.putIfAbsent(t, () => 1.0);
    }

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setDialogState) => AlertDialog(
            title: const Text('Préférences IA'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Types de plans à privilégier', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: planTypes.map((t) {
                      final selected = focusTypes.contains(t);
                      return FilterChip(
                        label: Text(t),
                        selected: selected,
                        onSelected: (v) => setDialogState(() {
                          if (v) focusTypes.add(t); else focusTypes.remove(t);
                        }),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Longueur du résumé', style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    value: summaryLength,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'short', child: Text('Court')),
                      DropdownMenuItem(value: 'detailed', child: Text('Détaillé')),
                    ],
                    onChanged: (v) => setDialogState(() => summaryLength = v ?? 'short'),
                  ),
                  const SizedBox(height: 8),
                  const Text('Fréquence', style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    value: frequency,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'every_session', child: Text('Chaque session')),
                      DropdownMenuItem(value: 'weekly', child: Text('Hebdomadaire')),
                    ],
                    onChanged: (v) => setDialogState(() => frequency = v ?? 'every_session'),
                  ),
                  const SizedBox(height: 16),
                  const Text('Pondération par type (0.5 – 2)', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...planTypes.map((t) {
                    final w = weights[t] ?? 1.0;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          SizedBox(width: 100, child: Text(t, style: const TextStyle(fontSize: 12))),
                          Expanded(
                            child: Slider(
                              value: w,
                              min: 0.5,
                              max: 2.0,
                              divisions: 15,
                              label: w.toStringAsFixed(1),
                              onChanged: (v) => setDialogState(() => weights[t] = v),
                            ),
                          ),
                          SizedBox(width: 36, child: Text(w.toStringAsFixed(1), style: const TextStyle(fontSize: 12))),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  try {
                    await service.updatePreferences(
                      focusPlanTypes: focusTypes,
                      summaryLength: summaryLength,
                      frequency: frequency,
                      planTypeWeights: weights,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Préférences enregistrées'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _load();
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString().replaceFirst('Exception: ', '')),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Enregistrer'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showModifyDialog(ProgressAiRecommendationItem item, int index) {
    final controller = TextEditingController(text: item.text);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier la recommandation'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Saisissez votre version de la recommandation',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _askResultsImprovedThenSubmit(
                recommendationId: _result!.recommendationId,
                action: 'modified',
                editedText: controller.text.trim(),
                originalRecommendationText: item.text,
                itemIndex: index,
                planType: item.planType,
              );
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.childName != null
            ? 'Recommandations IA – ${widget.childName}'
            : 'Recommandations IA'),
        backgroundColor: _primary,
        foregroundColor: _brand,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go(AppConstants.healthcarePatientsRoute),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openPreferencesDialog,
            tooltip: 'Préférences IA',
          ),
          IconButton(
            icon: const Icon(Icons.feedback_outlined),
            onPressed: _openRequestParentFeedbackDialog,
            tooltip: 'Demander un retour au parent',
          ),
        ],
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
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _load,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                )
              : _result == null
                  ? const Center(child: Text('Aucune donnée'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Résumé',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _result!.summary,
                                      style: TextStyle(
                                        color: Colors.grey.shade800,
                                        height: 1.4,
                                      ),
                                    ),
                                    if (_result!.milestones != null &&
                                        _result!.milestones!.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        _result!.milestones!,
                                        style: TextStyle(
                                          fontStyle: FontStyle.italic,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                    if (_result!.predictions != null &&
                                        _result!.predictions!.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        _result!.predictions!,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            if (_plans.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              const Text(
                                'Progression par plan',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ..._plans.map((plan) {
                                final type = plan['type'] as String? ?? '—';
                                final title = plan['title'] as String? ?? type;
                                final p = planProgress(plan);
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: _primary.withOpacity(0.3),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                type,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                title,
                                                style: TextStyle(
                                                  color: Colors.grey.shade800,
                                                  fontSize: 14,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        LinearProgressIndicator(
                                          value: p.progress,
                                          backgroundColor: Colors.grey.shade300,
                                          valueColor: const AlwaysStoppedAnimation<Color>(_brand),
                                          minHeight: 8,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        if (p.milestone != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            p.milestone!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              }),
                              const SizedBox(height: 20),
                            ],
                            const SizedBox(height: 20),
                            const Text(
                              'Recommandations par domaine',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...List.generate(
                              _result!.recommendations.length,
                              (index) {
                                final item = _result!.recommendations[index];
                                final feedbackSent = _feedbackSent.contains(index);
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: _primary.withOpacity(0.3),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                item.planType,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          item.text,
                                          style: TextStyle(
                                            color: Colors.grey.shade800,
                                            height: 1.4,
                                          ),
                                        ),
                                        if (!feedbackSent) ...[
                                          const SizedBox(height: 12),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              TextButton(
                                                onPressed: () =>
                                                    _submitFeedback(
                                                      recommendationId: _result!
                                                          .recommendationId,
                                                      action: 'dismissed',
                                                      originalRecommendationText:
                                                          item.text,
                                                      itemIndex: index,
                                                      planType: item.planType,
                                                    ),
                                                child: const Text('Ignorer'),
                                              ),
                                              const SizedBox(width: 8),
                                              TextButton(
                                                onPressed: () =>
                                                    _showModifyDialog(
                                                        item, index),
                                                child: const Text('Modifier'),
                                              ),
                                              const SizedBox(width: 8),
                                              FilledButton(
                                                onPressed: () =>
                                                    _askResultsImprovedThenSubmit(
                                                      recommendationId: _result!
                                                          .recommendationId,
                                                      action: 'approved',
                                                      originalRecommendationText:
                                                          item.text,
                                                      itemIndex: index,
                                                      planType: item.planType,
                                                    ),
                                                child: const Text('Approuver'),
                                              ),
                                            ],
                                          ),
                                        ] else
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                top: 8),
                                            child: Text(
                                              'Feedback enregistré',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
    );
  }
}
