import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/children_service.dart';
import '../../services/progress_ai_service.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/constants.dart';

const Color _primary = Color(0xFFA2D9E7);
const Color _brand = Color(0xFF2D7DA1);

/// Tableau de bord professionnel : Aperçu IA, Mes Patients (API), Rapports/Consultations, Prochaine consultation.
class HealthcareDashboardScreen extends StatefulWidget {
  const HealthcareDashboardScreen({super.key});

  @override
  State<HealthcareDashboardScreen> createState() => _HealthcareDashboardScreenState();
}

class _HealthcareDashboardScreenState extends State<HealthcareDashboardScreen> {
  List<ChildModel> _patients = [];
  bool _patientsLoading = true;
  List<String> _activitySuggestions = [];
  bool _suggestionsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPatients();
    _loadActivitySuggestions();
  }

  Future<void> _loadPatients() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final service = ChildrenService(getToken: () async => authProvider.accessToken);
    try {
      final list = await service.getOrganizationChildren();
      if (mounted) setState(() { _patients = list; _patientsLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _patients = []; _patientsLoading = false; });
    }
  }

  Future<void> _loadActivitySuggestions() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final service = ProgressAiService(getToken: () async => authProvider.accessToken);
    try {
      final list = await service.getActivitySuggestions();
      if (mounted) setState(() { _activitySuggestions = list; _suggestionsLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _activitySuggestions = []; _suggestionsLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewPatients = _patients.take(3).toList();
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(context),
                    const SizedBox(height: 24),
                    _clinicalOverviewCard(context),
                    const SizedBox(height: 24),
                    _activitySuggestionsCard(context),
                    const SizedBox(height: 24),
                    _sectionTitle(context, AppLocalizations.of(context)!.myPatientsLabel, onSeeAll: () => context.go(AppConstants.healthcarePatientsRoute)),
                    const SizedBox(height: 12),
                    if (_patientsLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (previewPatients.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Aucun patient assigné. Consultez la liste pour plus de détails.',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                        ),
                      )
                    else
                      ...previewPatients.map((c) => _patientCardFromChild(context, c)),
                    const SizedBox(height: 24),
                    _quickActions(context),
                    const SizedBox(height: 24),
                    _nextConsultation(context),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _patientCardFromChild(BuildContext context, ChildModel child) {
    final initials = child.fullName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => context.push(
            '${AppConstants.healthcareCareBoardRoute}?patientId=${child.id}&patientName=${Uri.encodeComponent(child.fullName)}',
          ),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: _brand),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        child.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        child.diagnosis ?? 'Suivi',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.healthcareProfessionalLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)!.helloDr('Martin'),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined, color: _brand),
            style: IconButton.styleFrom(
              backgroundColor: _primary.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _clinicalOverviewCard(BuildContext context) {
    return Material(
      color: _brand,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _brand.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: _primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.clinicalOverviewIALabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.clinicalSummaryIALabel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () => context.push(
                    AppConstants.healthcareComparativeRoute,
                    extra: {'highlightPatientId': 'thomas-bernard'},
                  ),
                  icon: const Icon(Icons.arrow_forward, size: 16, color: Colors.white),
                  label: Text(AppLocalizations.of(context)!.seeDetailsLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ],
            ),
            Positioned(
              right: -24,
              bottom: -24,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _primary.withOpacity(0.2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activitySuggestionsCard(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: _brand, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Suggestions d\'activités',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => context.go(AppConstants.healthcarePatientsRoute),
                  child: const Text('Voir patients', style: TextStyle(color: _brand, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_suggestionsLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
              )
            else if (_activitySuggestions.isEmpty)
              Text(
                'Aucune suggestion pour le moment.',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              )
            else
              ..._activitySuggestions.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ', style: TextStyle(fontSize: 14, color: _brand, fontWeight: FontWeight.bold)),
                      Expanded(child: Text(s, style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.35))),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title, {VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: Text(AppLocalizations.of(context)!.seeAllLabel, style: const TextStyle(color: _brand, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }

  Widget _quickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _actionCard(
            context,
            icon: Icons.description_outlined,
            label: AppLocalizations.of(context)!.medicalReportsLabel,
            color: Colors.blue,
            onTap: () => context.go(AppConstants.healthcareReportsRoute),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _actionCard(
            context,
            icon: Icons.event_outlined,
            label: AppLocalizations.of(context)!.consultationsLabel,
            color: Colors.purple,
            onTap: () => context.push(AppConstants.healthcarePlannerRoute),
          ),
        ),
      ],
    );
  }

  Widget _actionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nextConsultation(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.nextConsultationLabel,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: const Border(left: BorderSide(color: _brand, width: 4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.todayAtTime('14:30'),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _brand,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.telemedicineLabel,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _brand,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sophie Marchand',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => context.push(
                          '${AppConstants.healthcareConsultationRoute}?consultationId=sophie-marchand-14h30&patientName=${Uri.encodeComponent('Sophie Marchand')}',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _brand,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(AppLocalizations.of(context)!.startCallLabel),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(44, 44),
                        padding: EdgeInsets.zero,
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: const Icon(Icons.more_horiz, size: 20),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
