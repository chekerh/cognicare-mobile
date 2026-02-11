import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/constants.dart';

const Color _primary = Color(0xFFA2D9E7);
const Color _brand = Color(0xFF2D7DA1);

/// Tableau de bord professionnel : Aperçu IA, Mes Patients, Rapports/Consultations, Prochaine consultation.
class HealthcareDashboardScreen extends StatelessWidget {
  const HealthcareDashboardScreen({super.key});

  static const List<Map<String, String>> _patients = [
    {'id': 'jean-dupont', 'name': 'Jean Dupont', 'initials': 'JD', 'status': 'Progrès constant', 'statusColor': 'green'},
    {'id': 'thomas-bernard', 'name': 'Thomas Bernard', 'initials': 'TB', 'status': 'Fluctuation détectée', 'statusColor': 'orange'},
    {'id': 'marie-lefebvre', 'name': 'Marie Lefebvre', 'initials': 'ML', 'status': 'Objectifs atteints (80%)', 'statusColor': 'green'},
  ];

  @override
  Widget build(BuildContext context) {
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
                    _sectionTitle(context, 'Mes Patients', onSeeAll: () => context.go(AppConstants.healthcarePatientsRoute)),
                    const SizedBox(height: 12),
                    ..._patients.map((p) => _patientCard(context, p)),
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
                'PROFESSIONNEL DE SANTÉ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Bonjour, Dr. Martin',
                style: TextStyle(
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
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: _primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'APERÇU CLINIQUE (IA)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '3 patients montrent une progression stable cette semaine. Attention requise pour Thomas B.',
                  style: TextStyle(
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
                  label: const Text('Voir les détails', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
            child: const Text('Voir tout', style: TextStyle(color: _brand, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }

  Widget _patientCard(BuildContext context, Map<String, String> p) {
    final statusColor = p['statusColor'] == 'green' ? Colors.green : Colors.orange;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => context.push(
            '${AppConstants.healthcareCareBoardRoute}?patientId=${p['id']}&patientName=${Uri.encodeComponent(p['name']!)}',
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
                    color: p['statusColor'] == 'orange'
                        ? Colors.orange.shade100
                        : _primary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    p['initials']!,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: p['statusColor'] == 'orange' ? Colors.orange.shade700 : _brand,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p['name']!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            p['status']!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
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

  Widget _quickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _actionCard(
            context,
            icon: Icons.description_outlined,
            label: 'Rapports Médicaux',
            color: Colors.blue,
            onTap: () => context.go(AppConstants.healthcareReportsRoute),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _actionCard(
            context,
            icon: Icons.event_outlined,
            label: 'Consultations',
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
        const Text(
          'Prochaine consultation',
          style: TextStyle(
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
                    const Text(
                      'AUJOURD\'HUI • 14:30',
                      style: TextStyle(
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
                      child: const Text(
                        'TÉLÉMÉDECINE',
                        style: TextStyle(
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
                        child: const Text('Démarrer l\'appel'),
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
