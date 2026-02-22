import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/children_service.dart';
import '../../utils/constants.dart';

const Color _primary = Color(0xFFA2D9E7);
const Color _brand = Color(0xFF2D7DA1);

/// Liste des patients suivis (Espace Santé) : chargée depuis l’API organisation,
/// recherche, cartes patients avec lien vers Care Board et Recommandations IA.
class HealthcarePatientsScreen extends StatefulWidget {
  const HealthcarePatientsScreen({super.key});

  @override
  State<HealthcarePatientsScreen> createState() => _HealthcarePatientsScreenState();
}

class _HealthcarePatientsScreenState extends State<HealthcarePatientsScreen> {
  List<Map<String, dynamic>> _childrenWithPlans = [];
  bool _loading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _planTypeFilter = 'all'; // 'all' | 'PECS' | 'TEACCH' | 'SkillTracker' | 'Activity'
  String _progressFilter = 'all'; // 'all' | 'need_attention' | 'on_track'

  @override
  void initState() {
    super.initState();
    _loadPatients();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final service = ChildrenService(getToken: () async => authProvider.accessToken);
    try {
      final list = await service.getOrganizationChildrenWithPlans();
      if (mounted) {
        setState(() {
          _childrenWithPlans = list;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _childrenWithPlans = [];
          _loading = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredChildren {
    var list = _childrenWithPlans;
    if (_searchQuery.isNotEmpty) {
      list = list
          .where((c) =>
              (c['childName'] as String? ?? '')
                  .toLowerCase()
                  .contains(_searchQuery))
          .toList();
    }
    if (_planTypeFilter != 'all') {
      list = list
          .where((c) {
            final types = c['planTypes'] as List<dynamic>? ?? [];
            return types.contains(_planTypeFilter);
          })
          .toList();
    }
    if (_progressFilter == 'need_attention') {
      list = list.where((c) => c['needAttention'] == true).toList();
    } else if (_progressFilter == 'on_track') {
      list = list.where((c) => c['needAttention'] != true).toList();
    }
    return list;
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: _primary.withOpacity(0.3),
      checkmarkColor: _brand,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: true);
    final userName = authProvider.user?.fullName ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadPatients,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Espace Santé',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userName.isNotEmpty ? 'Bonjour, $userName' : 'Bonjour',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Rechercher un patient...',
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Patients suivis',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          if (!_loading && _error == null)
                            Text(
                              '${_filteredChildren.length} ACTIFS',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade500,
                              ),
                            ),
                        ],
                      ),
                      if (!_loading && _error == null && _childrenWithPlans.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            const Text('Type de plan:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            _filterChip('Tous', _planTypeFilter == 'all', () => setState(() => _planTypeFilter = 'all')),
                            _filterChip('PECS', _planTypeFilter == 'PECS', () => setState(() => _planTypeFilter = 'PECS')),
                            _filterChip('TEACCH', _planTypeFilter == 'TEACCH', () => setState(() => _planTypeFilter = 'TEACCH')),
                            _filterChip('Skill Tracker', _planTypeFilter == 'SkillTracker', () => setState(() => _planTypeFilter = 'SkillTracker')),
                            _filterChip('Activité', _planTypeFilter == 'Activity', () => setState(() => _planTypeFilter = 'Activity')),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            const Text('Progrès:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            _filterChip('Tous', _progressFilter == 'all', () => setState(() => _progressFilter = 'all')),
                            _filterChip('Besoin d\'attention', _progressFilter == 'need_attention', () => setState(() => _progressFilter = 'need_attention')),
                            _filterChip('En bonne voie', _progressFilter == 'on_track', () => setState(() => _progressFilter = 'on_track')),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              if (_loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _loadPatients,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_filteredChildren.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          _childrenWithPlans.isEmpty
                              ? 'Aucun patient assigné à votre organisation.'
                              : 'Aucun patient ne correspond aux filtres ou à la recherche.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final child = _filteredChildren[index];
                      final childId = child['childId'] as String? ?? '';
                      final name = child['childName'] as String? ?? '';
                      final condition = child['diagnosis'] as String? ?? '—';
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        child: _PatientCard(
                          patientId: childId,
                          name: name,
                          condition: condition,
                          status: 'SUIVI',
                          statusColor: Colors.green,
                          hasAiAnalysis: false,
                          aiSummary: null,
                        ),
                      );
                    },
                    childCount: _filteredChildren.length,
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _clinicalNotesSection(context),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _clinicalNotesSection(BuildContext context) {
    return Material(
      color: const Color(0xFF1E293B),
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.event_note, color: _primary, size: 22),
                SizedBox(width: 8),
                Text(
                  'Notes cliniques',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Consultez le tableau de suivi (Care Board) et les recommandations IA pour chaque patient.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade400,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  const _PatientCard({
    required this.patientId,
    required this.name,
    required this.condition,
    required this.status,
    required this.statusColor,
    required this.hasAiAnalysis,
    this.aiSummary,
  });

  final String patientId;
  final String name;
  final String condition;
  final String status;
  final Color statusColor;
  final bool hasAiAnalysis;
  final String? aiSummary;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _brand,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        condition,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            if (hasAiAnalysis && aiSummary != null && aiSummary!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _primary.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome, size: 14, color: _brand),
                        SizedBox(width: 6),
                        Text(
                          'ANALYSE IA',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _brand,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      aiSummary!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.push(
                      '${AppConstants.healthcareCareBoardRoute}?patientId=$patientId&patientName=${Uri.encodeComponent(name)}',
                    ),
                    icon: const Icon(Icons.description_outlined, size: 18),
                    label: const Text('Détails'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: const Color(0xFF1E293B),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(
                      AppConstants.healthcareProgressAiRecommendationsRoute(patientId),
                      extra: {'childName': name},
                    ),
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: const Text('Recommandations IA'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: _primary),
                      foregroundColor: _brand,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
