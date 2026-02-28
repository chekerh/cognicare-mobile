import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/children_service.dart';
import '../../services/reminders_service.dart';
import '../../services/progress_ai_service.dart';
import '../../l10n/app_localizations.dart';

const Color _primary = Color(0xFFA3D9E5);
const Color _slate800 = Color(0xFF1E293B);
const Color _slate600 = Color(0xFF475569);
const Color _slate500 = Color(0xFF64748B);

/// Parent view: progress by plan type (PECS, TEACCH, etc.) and task completion over time.
class ChildProgressSummaryScreen extends StatefulWidget {
  const ChildProgressSummaryScreen({
    super.key,
    required this.childId,
    this.childName,
  });

  final String childId;
  final String? childName;

  @override
  State<ChildProgressSummaryScreen> createState() =>
      _ChildProgressSummaryScreenState();
}

class _ChildProgressSummaryScreenState
    extends State<ChildProgressSummaryScreen> {
  List<Map<String, dynamic>> _planProgress = [];
  Map<String, dynamic>? _reminderStats;
  bool _loadingPlans = true;
  bool _loadingStats = true;
  String? _errorPlans;
  String? _errorStats;
  String? _aiSummary;
  bool _loadingSummary = false;
  String? _errorSummary;
  String _summaryPeriod = 'week';
  List<Map<String, dynamic>> _parentFeedback = [];
  bool _loadingFeedback = false;
  String? _errorFeedback;
  bool _showFeedbackModal = false;
  int _selectedRating = 0;
  final TextEditingController _feedbackCommentController = TextEditingController();
  String? _selectedPlanType;
  List<Map<String, dynamic>> _allChildren = [];
  bool _loadingChildren = false;
  String? _selectedChildId;

  @override
  void initState() {
    super.initState();
    _load();
    _loadAiSummary();
    _loadParentFeedback();
  }

  @override
  void dispose() {
    _feedbackCommentController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final childrenService =
        ChildrenService(getToken: () async => authProvider.accessToken);
    final remindersService =
        RemindersService(getToken: () async => authProvider.accessToken);

    setState(() {
      _loadingPlans = true;
      _loadingStats = true;
      _loadingChildren = true;
      _errorPlans = null;
      _errorStats = null;
    });

    try {
      final list = await childrenService.getChildren();
      if (mounted) {
        setState(() {
          _allChildren = list.map((c) => {
            'id': c.id,
            'name': c.fullName,
          }).toList();
          if (_selectedChildId == null && _allChildren.isNotEmpty) {
            _selectedChildId = widget.childId;
          }
          _loadingChildren = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingChildren = false;
        });
      }
    }

    try {
      final plans = await childrenService.getProgressSummary(_selectedChildId ?? widget.childId);
      if (mounted) {
        setState(() {
          _planProgress = plans;
          _loadingPlans = false;
          _errorPlans = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _planProgress = [];
          _loadingPlans = false;
          _errorPlans = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }

    try {
      final stats = await remindersService.getReminderStats(_selectedChildId ?? widget.childId, days: 14);
      if (mounted) {
        setState(() {
          _reminderStats = stats;
          _loadingStats = false;
          _errorStats = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _reminderStats = null;
          _loadingStats = false;
          _errorStats = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  void _switchChild(String childId) {
    setState(() {
      _selectedChildId = childId;
    });
    _load();
    _loadAiSummary();
    _loadParentFeedback();
  }

  Future<void> _loadParentFeedback() async {
    setState(() {
      _loadingFeedback = true;
      _errorFeedback = null;
    });
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final service = ProgressAiService(getToken: () async => authProvider.accessToken);
    try {
      final list = await service.getParentFeedback(widget.childId, limit: 5);
      if (mounted) {
        setState(() {
          _parentFeedback = list;
          _loadingFeedback = false;
          _errorFeedback = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _parentFeedback = [];
          _loadingFeedback = false;
          _errorFeedback = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _submitParentFeedback() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une note')),
      );
      return;
    }
    setState(() {
      _loadingFeedback = true;
      _errorFeedback = null;
    });
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final service = ProgressAiService(getToken: () async => authProvider.accessToken);
    try {
      await service.submitParentFeedback(
        childId: _selectedChildId ?? widget.childId,
        rating: _selectedRating,
        comment: _feedbackCommentController.text.trim().isEmpty
            ? null
            : _feedbackCommentController.text.trim(),
        planType: _selectedPlanType,
      );
      if (mounted) {
        setState(() {
          _showFeedbackModal = false;
          _selectedRating = 0;
          _feedbackCommentController.clear();
          _selectedPlanType = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Merci pour votre retour !'),
            backgroundColor: Colors.green,
          ),
        );
        _loadParentFeedback();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorFeedback = e.toString().replaceFirst('Exception: ', '');
          _loadingFeedback = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadAiSummary() async {
    setState(() {
      _loadingSummary = true;
      _errorSummary = null;
    });
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final service =
        ProgressAiService(getToken: () async => authProvider.accessToken);
    try {
      final data = await service.getParentSummary(_selectedChildId ?? widget.childId, period: _summaryPeriod);
      if (mounted) {
        setState(() {
          _aiSummary = data['summary'] as String?;
          _loadingSummary = false;
          _errorSummary = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiSummary = null;
          _loadingSummary = false;
          _errorSummary = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showFeedbackModal) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showFeedbackDialog();
        setState(() => _showFeedbackModal = false);
      });
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: _allChildren.length > 1
            ? DropdownButton<String>(
                value: _selectedChildId,
                isExpanded: false,
                underline: const SizedBox(),
                style: const TextStyle(
                  color: _slate800,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                items: _allChildren.map((child) {
                  return DropdownMenuItem<String>(
                    value: child['id'] as String,
                    child: Text(
                      child['name'] as String,
                      style: const TextStyle(color: _slate800),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) _switchChild(value);
                },
              )
            : Text(widget.childName != null
                ? 'Progrès – ${widget.childName}'
                : AppLocalizations.of(context)!.progressSummary),
        backgroundColor: _primary,
        foregroundColor: _slate800,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            20 + MediaQuery.paddingOf(context).left,
            20 + MediaQuery.paddingOf(context).top,
            20 + MediaQuery.paddingOf(context).right,
            20 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_planProgress.isNotEmpty) ...[
                const Text(
                  'Progression par plan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _slate800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Les détails des plans sont gérés par le spécialiste.',
                  style: TextStyle(fontSize: 12, color: _slate500),
                ),
                const SizedBox(height: 12),
                ..._planProgress.map((p) {
                  final type = p['type'] as String? ?? '—';
                  final title = p['title'] as String? ?? type;
                  final percent = (p['progressPercent'] is int)
                      ? (p['progressPercent'] as int) / 100.0
                      : (p['progressPercent'] is num)
                          ? (p['progressPercent'] as num).toDouble() / 100.0
                          : 0.0;
                  
                  // Determine status and color
                  Color progressColor;
                  String statusText;
                  String description;
                  if (percent < 0.3) {
                    progressColor = Colors.orange.shade300;
                    statusText = 'À démarrer';
                    description = 'Votre enfant commence ce plan. Le spécialiste ajustera le programme selon les progrès.';
                  } else if (percent < 0.7) {
                    progressColor = Colors.blue.shade300;
                    statusText = 'En cours';
                    description = 'Votre enfant progresse bien, continuez comme ça !';
                  } else {
                    progressColor = Colors.green.shade300;
                    statusText = 'Bien avancé';
                    description = 'Objectifs presque atteints, le spécialiste ajustera bientôt le programme.';
                  }
                  
                  // Plan type labels
                  String planTypeLabel = type;
                  IconData planIcon = Icons.assignment;
                  if (type == 'PECS') {
                    planTypeLabel = 'PECS – Communication visuelle';
                    planIcon = Icons.image;
                  } else if (type == 'TEACCH') {
                    planTypeLabel = 'TEACCH – Structuration';
                    planIcon = Icons.grid_view;
                  } else if (type == 'SkillTracker') {
                    planTypeLabel = 'Suivi de compétences';
                    planIcon = Icons.track_changes;
                  } else if (type == 'Activity') {
                    planTypeLabel = 'Activités';
                    planIcon = Icons.games;
                  }
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(planIcon, color: _primary, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      planTypeLabel,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: _slate800,
                                      ),
                                    ),
                                    if (title != type && title.isNotEmpty)
                                      Text(
                                        title,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _slate600,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: progressColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  statusText,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: progressColor.withOpacity(0.8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: percent,
                              minHeight: 8,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${(percent * 100).round()}% complété',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _slate600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: percent.clamp(0.0, 1.0),
                            backgroundColor: Colors.grey.shade300,
                            valueColor: const AlwaysStoppedAnimation<Color>(_primary),
                            minHeight: 8,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: 12,
                              color: _slate500,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 24),
              ] else if (!_loadingPlans && _errorPlans == null) ...[
                const Text(
                  'Progression par plan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _slate800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Aucun plan pour le moment. Les détails des plans sont gérés par le spécialiste.',
                  style: TextStyle(fontSize: 13, color: _slate500),
                ),
                const SizedBox(height: 24),
              ],
              if (_errorPlans != null) ...[
                Text(
                  _errorPlans!,
                  style: TextStyle(fontSize: 13, color: Colors.red.shade700),
                ),
                const SizedBox(height: 24),
              ],
              Row(
                children: [
                  const Text(
                    'Tâches complétées',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _slate800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(14 derniers jours)',
                    style: TextStyle(
                      fontSize: 14,
                      color: _slate500,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_loadingStats)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ))
              else if (_errorStats != null)
                Text(
                  _errorStats!,
                  style: TextStyle(fontSize: 13, color: Colors.red.shade700),
                )
              else if (_reminderStats != null)
                _buildTaskCompletionSection(_reminderStats!),
              const SizedBox(height: 24),
              const Text(
                'Résumé IA',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _slate800,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'week', label: Text('Semaine')),
                      ButtonSegment(value: 'month', label: Text('Mois')),
                    ],
                    selected: {_summaryPeriod},
                    onSelectionChanged: (Set<String> s) {
                      setState(() {
                        _summaryPeriod = s.first;
                        _loadAiSummary();
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadingSummary ? null : _loadAiSummary,
                    tooltip: 'Actualiser',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_loadingSummary)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_errorSummary != null)
                Text(
                  _errorSummary!,
                  style: TextStyle(fontSize: 13, color: Colors.red.shade700),
                )
              else if (_aiSummary != null && _aiSummary!.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _aiSummary!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: _slate800,
                        height: 1.4,
                      ),
                    ),
                  ),
                )
              else
                TextButton.icon(
                  onPressed: _loadAiSummary,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Générer le résumé'),
                ),
              const SizedBox(height: 24),
              _buildParentFeedbackSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParentFeedbackSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Votre feedback',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _slate800,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => setState(() {
                _showFeedbackModal = true;
                _selectedRating = 0;
                _feedbackCommentController.clear();
                _selectedPlanType = null;
              }),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ajouter un feedback'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: _slate800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Vos retours aident le spécialiste et l\'IA à mieux adapter les recommandations.',
          style: TextStyle(fontSize: 12, color: _slate500),
        ),
        const SizedBox(height: 12),
        if (_loadingFeedback)
          const Center(child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ))
        else if (_errorFeedback != null)
          Text(
            _errorFeedback!,
            style: TextStyle(fontSize: 13, color: Colors.red.shade700),
          )
        else if (_parentFeedback.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Aucun feedback pour le moment. Cliquez sur "Ajouter un feedback" pour partager vos impressions.',
                style: TextStyle(fontSize: 13, color: _slate500),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ..._parentFeedback.map((fb) {
            final rating = fb['rating'] as int? ?? 0;
            final comment = fb['comment'] as String?;
            final planType = fb['planType'] as String?;
            final date = fb['createdAt'] != null
                ? DateTime.tryParse(fb['createdAt'].toString())
                : null;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ...List.generate(5, (i) => Icon(
                          i < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 18,
                        )),
                        const SizedBox(width: 8),
                        if (planType != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _primary.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              planType,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                          ),
                        const Spacer(),
                        if (date != null)
                          Text(
                            '${date.day}/${date.month}/${date.year}',
                            style: TextStyle(fontSize: 11, color: _slate500),
                          ),
                      ],
                    ),
                    if (comment != null && comment.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        comment,
                        style: const TextStyle(fontSize: 13, color: _slate800),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  void _showFeedbackDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Ajouter un feedback',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _slate800,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Note (1-5 étoiles)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _slate800),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final rating = i + 1;
                return IconButton(
                  icon: Icon(
                    _selectedRating >= rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 40,
                  ),
                  onPressed: () => setState(() => _selectedRating = rating),
                );
              }),
            ),
            const SizedBox(height: 16),
            const Text(
              'Commentaire (optionnel)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _slate800),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _feedbackCommentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Partagez vos impressions...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Type de plan (optionnel)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _slate800),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['PECS', 'TEACCH', 'SkillTracker', 'Activity', null].map((type) {
                final isSelected = _selectedPlanType == type;
                return FilterChip(
                  label: Text(type ?? 'Général'),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedPlanType = selected ? type : null);
                  },
                  selectedColor: _primary.withOpacity(0.3),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() {
                      _showFeedbackModal = false;
                      _selectedRating = 0;
                      _feedbackCommentController.clear();
                      _selectedPlanType = null;
                    }),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loadingFeedback ? null : _submitParentFeedback,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: _slate800,
                    ),
                    child: _loadingFeedback
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Envoyer'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCompletionSection(Map<String, dynamic> stats) {
    final dailyStats = stats['dailyStats'] as List<dynamic>? ?? [];
    final totalTasks = stats['totalTasks'] as int? ?? 0;
    final completedTasks = stats['completedTasks'] as int? ?? 0;
    final rate = stats['completionRate'] as int? ?? 0;
    
    // Calculate days with good regularity (>= 70% completion)
    int daysWithGoodRegularity = 0;
    for (final day in dailyStats) {
      final dayTotal = day['total'] as int? ?? 0;
      final dayCompleted = day['completed'] as int? ?? 0;
      if (dayTotal > 0 && (dayCompleted / dayTotal) >= 0.7) {
        daysWithGoodRegularity++;
      }
    }
    
    String regularityText;
    Color regularityColor;
    if (daysWithGoodRegularity >= 10) {
      regularityText = 'Excellente régularité';
      regularityColor = Colors.green;
    } else if (daysWithGoodRegularity >= 7) {
      regularityText = 'Bonne régularité';
      regularityColor = Colors.blue;
    } else if (daysWithGoodRegularity >= 4) {
      regularityText = 'Régularité moyenne';
      regularityColor = Colors.orange;
    } else {
      regularityText = 'Régularité à améliorer';
      regularityColor = Colors.red;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Sur les 14 derniers jours',
                        style: TextStyle(fontSize: 12, color: _slate500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$completedTasks tâches complétées sur $totalTasks',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _slate800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: regularityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      regularityText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: regularityColor.withOpacity(0.8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: rate / 100.0,
                minHeight: 10,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  rate >= 70 ? Colors.green : (rate >= 50 ? Colors.blue : Colors.orange),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Taux de complétion: $rate%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _slate600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Jours avec bonne régularité: $daysWithGoodRegularity sur ${dailyStats.length}',
              style: TextStyle(fontSize: 12, color: _slate500),
            ),
            if (dailyStats.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Détails par jour',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _slate600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: dailyStats.take(14).map((d) {
                  final m = d as Map<String, dynamic>;
                  final total = m['total'] as int? ?? 0;
                  final completed = m['completed'] as int? ?? 0;
                  final dateStr = m['date'] as String? ?? '';
                  final dayLabel = dateStr.length >= 10
                      ? '${dateStr.substring(8, 10)}/${dateStr.substring(5, 7)}'
                      : '';
                  final h = total > 0 ? (completed / total) * 80.0 : 0.0;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: h.clamp(4.0, 80.0),
                            decoration: BoxDecoration(
                              color: total > 0
                                  ? (completed >= total
                                      ? _primary
                                      : _primary.withOpacity(0.4))
                                  : Colors.grey.shade300,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dayLabel,
                            style: TextStyle(
                              fontSize: 9,
                              color: _slate500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
