import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

// Couleurs du design HTML
const Color _primary = Color(0xFF77B5D1);
const Color _brandLight = Color(0xFFA8D9EB);
const Color _bgLight = Color(0xFFF8FAFC);

const _daysFr = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
const _daysFullFr = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
const _monthsFr = ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];

class _Mission {
  final String category;
  final String family;
  final String status;
  final bool isConfirmed;
  final DateTime date;
  final String timeRange;
  final String duration;
  final String address;

  _Mission({
    required this.category,
    required this.family,
    required this.status,
    required this.isConfirmed,
    required this.date,
    required this.timeRange,
    required this.duration,
    required this.address,
  });

  String get dateLabel => '${_daysFullFr[date.weekday - 1]} ${date.day} ${_monthsFr[date.month - 1]}';
  String get time => '$timeRange ($duration)';
}

/// Données d'un bénévole affiché dans la section "Bénévoles" (demander de l'aide).
class _VolunteerProfile {
  final String name;
  final String avatarUrl;
  final bool isOnline;
  final String rating;
  final String reviewsCount;
  final String distance;
  final List<_VolunteerTag> tags;
  final String description;

  _VolunteerProfile({
    required this.name,
    required this.avatarUrl,
    required this.isOnline,
    required this.rating,
    required this.reviewsCount,
    required this.distance,
    required this.tags,
    required this.description,
  });
}

class _VolunteerTag {
  final String label;
  final Color bgColor;
  final Color textColor;

  _VolunteerTag({required this.label, required this.bgColor, required this.textColor});
}

/// Missions bénévole — Rendez-vous (dashboard) / Historique (missions passées).
class VolunteerMissionsScreen extends StatefulWidget {
  const VolunteerMissionsScreen({super.key});

  @override
  State<VolunteerMissionsScreen> createState() => _VolunteerMissionsScreenState();
}

class _VolunteerMissionsScreenState extends State<VolunteerMissionsScreen> {
  bool _isRendezVous = true;
  int _selectedDayIndex = 0;
  String _volunteerSearch = '';
  int _volunteerFilterIndex = 0; // 0=Tous, 1=Orthophonie, 2=Tâches quotidiennes, 3=Atelier créatif

  static List<_VolunteerProfile> _allVolunteers() {
    return [
      _VolunteerProfile(
        name: 'Sarah Miller',
        avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDa9YjhzEnl1xZV-16FgNasNLLSPYGAxoAInz2ABP_EQGTu6dOPK6fxj18Gt-Hm_JiJSsJOzRcgAcBwjvylPN1BfzIQmOWS-M46LbrO8cMWDSMabfeBahZShTGVHPACMChjAKL3oZ4Yazo8PdykzrZW_0uJRXKt3FkoB8VE438vXx99CHpuE3HC2DPFidBkfiNAMsUDnhLB0kA7xMHTqdlnLDXLBA_cNyZCz1JsWzGXPQhYR87Yp52kl3p4GcUi_SDfwFb095juyrM',
        isOnline: true,
        rating: '4.9',
        reviewsCount: '12',
        distance: '2 km',
        tags: [
          _VolunteerTag(label: 'Aide orthophonique', bgColor: const Color(0xFFEFF6FF), textColor: const Color(0xFF2563EB)),
          _VolunteerTag(label: 'Lecture', bgColor: const Color(0xFFFEF3C7), textColor: const Color(0xFFD97706)),
        ],
        description: 'Bénévole patiente et enthousiaste, 3 ans d\'expérience avec les enfants ayant des retards de langage. Disponible le week-end.',
      ),
      _VolunteerProfile(
        name: 'David Chen',
        avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuC9uszXa11CivzMYsbmhCfvx0SASe0AkMaMhe816F5kMf7_q0cUmLvaR3WbAyvMCOEU5Xaj4gTa5SSndyTJh1Lcv2UQf_KwDnTz4qoay7CdXRjQNtlwLX1NAF2XjNEK9lMpdm50PEFU02lVNJDlMEW3QoxQCyvXNRBBieKunWrt1FpK2I5VgY5towJOevNs6El8oqdxbfKsfSoezp7rxVfjUVQy4ZuiopksYJH1DZQpURXMyPhZutJRv6R97VBhwsk24tFNZGkMN9Q',
        isOnline: true,
        rating: '5.0',
        reviewsCount: '28',
        distance: '0,5 km',
        tags: [
          _VolunteerTag(label: 'Kinésithérapie', bgColor: const Color(0xFFF5F3FF), textColor: const Color(0xFF7C3AED)),
          _VolunteerTag(label: 'Activités extérieures', bgColor: const Color(0xFFECFDF5), textColor: const Color(0xFF059669)),
        ],
        description: 'Spécialisé dans l\'activité physique et les sorties. J\'aime organiser des jeux sportifs inclusifs.',
      ),
      _VolunteerProfile(
        name: 'Emma Wilson',
        avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDlV8Lpv4GFaGOxzHKQOVtrEP0kCUl576ef14mnP5FSwPjlR_8o_M0bl3mfSKVJpSM3Y7jiGL-EoHYdpJwZeQDZFbbSpMIl7BWEpLVx8HGIFaCTQIfBFRQp0EKVGjNcu5_j72Oo-mgqR5OULOx1uTHNz7CN4M1WiWd4A0R5UgwDiCzggcMy6tghENrKFZhDAgLbiy2tHsFRCzDFEMDi0vLa3lgZ3bzQUaVX7cFNo_ApWzGg-4FVEW2DOAWzyQuWbOpMMr7dYK2gAIg',
        isOnline: false,
        rating: '4.8',
        reviewsCount: '15',
        distance: '5 km',
        tags: [
          _VolunteerTag(label: 'Tâches quotidiennes', bgColor: const Color(0xFFFFF1F2), textColor: const Color(0xFFE11D48)),
          _VolunteerTag(label: 'Arts créatifs', bgColor: const Color(0xFFECFEFF), textColor: const Color(0xFF0891B2)),
        ],
        description: 'Étudiante en art, propose aide au quotidien et ateliers créatifs pour les enfants.',
      ),
    ];
  }

  static List<_Mission> _allMissions(DateTime now) {
    return [
      _Mission(
        category: 'Aide aux devoirs',
        family: 'Famille Martin',
        status: 'Confirmé',
        isConfirmed: true,
        date: now.add(const Duration(days: 2)),
        timeRange: '16:30 - 18:00',
        duration: '1h30',
        address: '12 Rue de la Paix, 75002 Paris',
      ),
      _Mission(
        category: 'Accompagnement extérieur',
        family: 'Famille Lefebvre',
        status: 'En attente',
        isConfirmed: false,
        date: now.add(const Duration(days: 5)),
        timeRange: '14:00 - 16:00',
        duration: '2h00',
        address: '8 Avenue des Champs-Élysées, 75008 Paris',
      ),
      _Mission(
        category: 'Visite de courtoisie',
        family: 'Famille Dubois',
        status: 'Confirmé',
        isConfirmed: true,
        date: now.add(const Duration(days: 7)),
        timeRange: '10:00 - 11:30',
        duration: '1h30',
        address: '25 Boulevard Saint-Germain, 75005 Paris',
      ),
      _Mission(
        category: 'Aide aux devoirs',
        family: 'Famille Bernard',
        status: 'Confirmé',
        isConfirmed: true,
        date: now.subtract(const Duration(days: 7)),
        timeRange: '14:00 - 15:30',
        duration: '1h30',
        address: '5 Rue de Rivoli, 75001 Paris',
      ),
      _Mission(
        category: 'Accompagnement extérieur',
        family: 'Famille Petit',
        status: 'Confirmé',
        isConfirmed: true,
        date: now.subtract(const Duration(days: 14)),
        timeRange: '10:00 - 12:00',
        duration: '2h00',
        address: '42 Rue du Faubourg Saint-Honoré, 75008 Paris',
      ),
      _Mission(
        category: 'Visite de courtoisie',
        family: 'Famille Durand',
        status: 'Confirmé',
        isConfirmed: true,
        date: now.subtract(const Duration(days: 21)),
        timeRange: '15:00 - 16:00',
        duration: '1h00',
        address: '18 Place de la Bastille, 75011 Paris',
      ),
    ];
  }

  List<_Mission> _pastMissions() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _allMissions(now)
        .where((m) => DateTime(m.date.year, m.date.month, m.date.day).isBefore(today))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  DateTime _weekStart(DateTime d) => d.subtract(Duration(days: d.weekday - 1));

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final userName = (user?.fullName ?? '').split(' ').firstOrNull ?? 'Lucas';

    return Scaffold(
      backgroundColor: _bgLight,
      body: Stack(
        children: [
          Positioned.fill(child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_brandLight.withOpacity(0.6), _brandLight.withOpacity(0.3), _bgLight], stops: const [0.0, 0.4, 0.6])))),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Bonjour,', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade600)),
                          Text('Bénévole $userName', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => context.push('/volunteer/notifications'),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))]),
                              child: const Icon(Icons.notifications, color: _primary, size: 22),
                            ),
                            Positioned(top: 0, right: 0, child: Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: _brandLight, width: 2)))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Tabs: Rendez-vous | Historique
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.grey.shade200.withOpacity(0.5), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isRendezVous = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _isRendezVous ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: _isRendezVous ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : null,
                              ),
                              child: Text('Rendez-vous', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: _isRendezVous ? FontWeight.w600 : FontWeight.w500, color: _isRendezVous ? _primary : Colors.grey.shade600)),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isRendezVous = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _isRendezVous ? Colors.transparent : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: _isRendezVous ? null : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
                              ),
                              child: Text('Historique', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: _isRendezVous ? FontWeight.w500 : FontWeight.w600, color: _isRendezVous ? Colors.grey.shade600 : _primary)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: _isRendezVous ? _buildRendezVousContent() : _buildHistoriqueContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRendezVousContent() {
    final now = DateTime.now();
    final weekStart = _weekStart(now);
    final weekDays = List.generate(6, (i) => weekStart.add(Duration(days: i)));
    final selectedDate = weekDays[_selectedDayIndex.clamp(0, weekDays.length - 1)];

    final bottomPadding = 100 + MediaQuery.of(context).padding.bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImpactCard(),
          const SizedBox(height: 24),
          _buildVolunteersSection(),
          const SizedBox(height: 24),
          _buildSemaineSection(weekDays, selectedDate),
        ],
      ),
    );
  }

  Widget _buildImpactCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Votre Impact', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: _primary.withOpacity(0.1), borderRadius: BorderRadius.circular(999)),
                child: const Text('Niveau 4', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _primary)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  border: Border.all(color: _primary.withOpacity(0.3), width: 4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_user, color: _primary, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text('Prochain Badge: "Super Aidant"', style: TextStyle(fontSize: 14, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 8),
                        const Text('85%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(
                        height: 8,
                        child: LinearProgressIndicator(
                          value: 0.85,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation(_primary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _statBox('Heures', '24h')),
              const SizedBox(width: 8),
              Expanded(child: _statBox('Missions', '12')),
              const SizedBox(width: 8),
              Expanded(child: _statBox('Merci', '8')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildVolunteersSection() {
    final volunteers = _allVolunteers().where((v) {
      final matchSearch = _volunteerSearch.isEmpty ||
          v.name.toLowerCase().contains(_volunteerSearch.toLowerCase()) ||
          v.description.toLowerCase().contains(_volunteerSearch.toLowerCase()) ||
          v.tags.any((t) => t.label.toLowerCase().contains(_volunteerSearch.toLowerCase()));
      final filterLabels = ['', 'orthophonie', 'quotidien', 'art'];
      final filter = filterLabels[_volunteerFilterIndex.clamp(0, filterLabels.length - 1)];
      final matchFilter = filter.isEmpty ||
          v.tags.any((t) => t.label.toLowerCase().contains(filter));
      return matchSearch && matchFilter;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Bénévoles', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        const SizedBox(height: 12),
        // Barre de recherche
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextField(
            onChanged: (v) => setState(() => _volunteerSearch = v),
            decoration: InputDecoration(
              hintText: 'Rechercher un bénévole...',
              hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              prefixIcon: Icon(Icons.search, size: 22, color: Colors.grey.shade500),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Filtres (chips)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterChip('Tous', 0),
              const SizedBox(width: 8),
              _filterChip('Orthophonie', 1),
              const SizedBox(width: 8),
              _filterChip('Tâches quotidiennes', 2),
              const SizedBox(width: 8),
              _filterChip('Atelier créatif', 3),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...volunteers.map((v) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _volunteerCard(v),
        )),
      ],
    );
  }

  Widget _filterChip(String label, int index) {
    final isSelected = _volunteerFilterIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _volunteerFilterIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _primary : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: isSelected ? _primary : Colors.grey.shade300),
          boxShadow: isSelected ? [BoxShadow(color: _primary.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 2))] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _volunteerCard(_VolunteerProfile v) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      v.avatarUrl,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 64,
                        height: 64,
                        color: _primary.withOpacity(0.2),
                        child: const Icon(Icons.person, color: _primary, size: 32),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: v.isOnline ? Colors.green : Colors.grey.shade400,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(v.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const Row(
                      children: [
                        Icon(Icons.verified, size: 14, color: _primary),
                        SizedBox(width: 4),
                        Text('Bénévole vérifié', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _primary)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '${v.rating} (${v.reviewsCount} avis) • ${v.distance}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: v.tags.map((t) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: t.bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(t.label.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t.textColor, letterSpacing: 0.5)),
            )).toList(),
          ),
          const SizedBox(height: 12),
          Text(v.description, style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4)),
          const SizedBox(height: 16),
          Material(
            color: _primary,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () => _onRequestHelp(v),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('Demander de l\'aide', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onRequestHelp(_VolunteerProfile v) {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    final userName = (user?.fullName ?? '').split(' ').firstOrNull ?? 'Lucas';
    context.push('/volunteer/task-accepted', extra: {
      'volunteerName': userName,
      'familyName': v.name,
      'missionType': v.tags.isNotEmpty ? v.tags.first.label : 'Aide bénévole',
      'schedule': 'À définir',
      'address': '',
    });
  }

  Widget _buildSemaineSection(List<DateTime> weekDays, DateTime selectedDate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Votre semaine', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: List.generate(weekDays.length, (i) {
                    final d = weekDays[i];
                    final isSelected = i == _selectedDayIndex;
                    final hasEvent = d.weekday == 3 && d.day == 14;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedDayIndex = i),
                        child: Column(
                          children: [
                            Text(_daysFr[d.weekday - 1], style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
                            const SizedBox(height: 4),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: isSelected ? const BoxDecoration(color: _primary, shape: BoxShape.circle) : null,
                              alignment: Alignment.center,
                              child: Text('${d.day}', style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? Colors.white : const Color(0xFF1E293B))),
                            ),
                            if (hasEvent) ...[
                              const SizedBox(height: 2),
                              Container(width: 4, height: 4, decoration: const BoxDecoration(color: _primary, shape: BoxShape.circle)),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
              Container(height: 1, color: Colors.grey.shade100),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _scheduleItem('14:00', 'Visite de courtoisie', 'Mme. Lefebvre', isCancelled: false),
                    const SizedBox(height: 12),
                    _scheduleItem('16:30', 'Transport Médical', 'ANNULÉ', isCancelled: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _scheduleItem(String time, String title, String subtitle, {required bool isCancelled}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 40, child: Text(time, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500))),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCancelled ? Colors.grey.shade50 : _primary.withOpacity(0.08),
              border: Border(left: BorderSide(color: isCancelled ? Colors.grey.shade400 : _primary, width: 4)),
              borderRadius: const BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isCancelled ? Colors.grey.shade500 : const Color(0xFF1E293B), decoration: isCancelled ? TextDecoration.lineThrough : null)),
                Text(subtitle, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isCancelled ? Colors.grey.shade500 : Colors.grey.shade600)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoriqueContent() {
    final missions = _pastMissions();
    final bottomPadding = 100 + MediaQuery.of(context).padding.bottom;
    if (missions.isEmpty) {
      return Center(
        child: Text('Aucune mission dans l\'historique', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding),
      itemCount: missions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, i) => _missionCard(missions[i]),
    );
  }

  void _openItinerary(_Mission m) {
    context.push('/volunteer/mission-itinerary', extra: {'family': m.family, 'address': m.address});
  }

  Widget _missionCard(_Mission m) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.category.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: _primary)),
                  const SizedBox(height: 4),
                  Text(m.family, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: m.isConfirmed ? Colors.green.shade100 : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(m.status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: m.isConfirmed ? Colors.green.shade700 : Colors.orange.shade700)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 18, color: _primary),
              const SizedBox(width: 8),
              Text(m.dateLabel, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.schedule, size: 18, color: _primary),
              const SizedBox(width: 8),
              Text(m.time, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Material(
                  color: _primary,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => _openItinerary(m),
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.directions, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text('Itinéraire', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 56,
                height: 48,
                decoration: BoxDecoration(border: Border.all(color: _primary.withOpacity(0.3)), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.chat_bubble_outline, color: _primary, size: 22),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
