import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../services/progress_ai_service.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';

class OrganizationDashboardScreen extends StatefulWidget {
  const OrganizationDashboardScreen({super.key});

  @override
  State<OrganizationDashboardScreen> createState() => _OrganizationDashboardScreenState();
}

class _OrganizationDashboardScreenState extends State<OrganizationDashboardScreen> {
  final _specialistIdController = TextEditingController();
  Map<String, dynamic>? _specialistSummary;
  String? _summaryError;
  bool _summaryLoading = false;

  @override
  void dispose() {
    _specialistIdController.dispose();
    super.dispose();
  }

  Future<void> _loadSpecialistSummary() async {
    final id = _specialistIdController.text.trim();
    if (id.isEmpty) return;
    setState(() {
      _summaryError = null;
      _summaryLoading = true;
    });
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final service = ProgressAiService(getToken: () async => authProvider.accessToken);
    try {
      final data = await service.getOrgSpecialistSummary(id);
      if (mounted) setState(() {
        _specialistSummary = data;
        _summaryLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _summaryError = e.toString().replaceFirst('Exception: ', '');
        _specialistSummary = null;
        _summaryLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(localizations.roleOrganizationLeader),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authProvider.logout();
              context.go(AppConstants.loginRoute);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(context, user?.fullName ?? ''),
              const SizedBox(height: 24),
              Text(
                localizations.staffManagement,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.text,
                    ),
              ),
              const SizedBox(height: 16),
              _buildStatCard(
                context,
                title: localizations.totalStaff,
                value: '0',
                icon: Icons.people,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  context.push(AppConstants.staffManagementRoute);
                },
                icon: const Icon(Icons.add),
                label: Text(localizations.addStaffMember),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Progress AI – Specialist summary',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.text,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'View aggregated progress for a specialist (no child names).',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _specialistIdController,
                      decoration: const InputDecoration(
                        labelText: 'Specialist ID',
                        hintText: 'Enter staff member ID',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _summaryLoading ? null : _loadSpecialistSummary,
                    child: _summaryLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('View summary'),
                  ),
                ],
              ),
              if (_summaryError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _summaryError!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ],
              if (_specialistSummary != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total plans: ${_specialistSummary!['totalPlans'] ?? 0}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Children (anonymized): ${_specialistSummary!['childrenCount'] ?? 0}',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                        ),
                        if (_specialistSummary!['planCountByType'] != null) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: (_specialistSummary!['planCountByType'] as Map<String, dynamic>)
                                .entries
                                .map((e) => Chip(
                                      label: Text('${e.key}: ${e.value}'),
                                      backgroundColor: AppTheme.primary.withOpacity(0.1),
                                    ))
                                .toList(),
                          ),
                        ],
                        if (_specialistSummary!['approvalRatePercent'] != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Taux d\'approbation: ${_specialistSummary!['approvalRatePercent']}%',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                        if (_specialistSummary!['resultsImprovedRatePercent'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Résultats améliorés: ${_specialistSummary!['resultsImprovedRatePercent']}%',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, String name) {
    final loc = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.2),
            radius: 30,
            child: const Icon(Icons.business, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.welcomeBack,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppTheme.text.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: AppTheme.text,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
