import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/children_service.dart';
import '../../services/reminders_service.dart';
import '../../services/progress_ai_service.dart';

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
  State<ChildProgressSummaryScreen> createState() => _ChildProgressSummaryScreenState();
}

class _ChildProgressSummaryScreenState extends State<ChildProgressSummaryScreen> {
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

  @override
  void initState() {
    super.initState();
    _load();
    _loadAiSummary();
  }

  Future<void> _load() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final childrenService = ChildrenService(getToken: () async => authProvider.accessToken);
    final remindersService = RemindersService(getToken: () async => authProvider.accessToken);

    setState(() {
      _loadingPlans = true;
      _loadingStats = true;
      _errorPlans = null;
      _errorStats = null;
    });

    try {
      final plans = await childrenService.getProgressSummary(widget.childId);
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
      final stats = await remindersService.getReminderStats(widget.childId, days: 14);
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

  Future<void> _loadAiSummary() async {
    setState(() {
      _loadingSummary = true;
      _errorSummary = null;
    });
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final service = ProgressAiService(getToken: () async => authProvider.accessToken);
    try {
      final data = await service.getParentSummary(widget.childId, period: _summaryPeriod);
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.childName != null
            ? 'Progrès – ${widget.childName}'
            : 'Résumé de progrès'),
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
          padding: const EdgeInsets.all(20),
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
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: _slate800,
                                  ),
                                  overflow: TextOverflow.ellipsis,
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
                            '${(percent * 100).round()} %',
                            style: TextStyle(fontSize: 12, color: _slate500),
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
              const Text(
                'Tâches complétées (14 derniers jours)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _slate800,
                ),
              ),
              const SizedBox(height: 12),
              if (_loadingStats)
                const Center(child: Padding(
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCompletionSection(Map<String, dynamic> stats) {
    final dailyStats = stats['dailyStats'] as List<dynamic>? ?? [];
    final totalTasks = stats['totalTasks'] as int? ?? 0;
    final completedTasks = stats['completedTasks'] as int? ?? 0;
    final rate = stats['completionRate'] as int? ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$completedTasks / $totalTasks tâches',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _slate800,
                  ),
                ),
                Text(
                  '$rate %',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: totalTasks > 0 ? (completedTasks / totalTasks).clamp(0.0, 1.0) : 0.0,
              backgroundColor: Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation<Color>(_primary),
              minHeight: 10,
            ),
            if (dailyStats.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Par jour',
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
                      ? dateStr.substring(8, 10) + '/' + dateStr.substring(5, 7)
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
                                  ? (completed >= total ? _primary : _primary.withOpacity(0.4))
                                  : Colors.grey.shade300,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
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
