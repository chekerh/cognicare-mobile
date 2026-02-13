import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';

const Color _primary = Color(0xFF89CFF0);

/// Tableau de bord bénévole — Points Impact, Missions, Compétences, Demandes Ouvertes, Planning.
class VolunteerDashboardScreen extends StatelessWidget {
  const VolunteerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final userName = (user?.fullName ?? '').split(' ').firstOrNull ?? 'Julien';
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: true,
        bottom: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header fixe comme AppBar (ne défile pas)
            _buildHeader(context, userName),
            // Contenu scrollable en dessous
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildStatsCards()),
                  SliverToBoxAdapter(child: _buildSkillsSection(context)),
                  SliverToBoxAdapter(child: _buildRequestsSection(context)),
                  SliverToBoxAdapter(child: _buildPlanningSection(context)),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String userName) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bonjour, $userName 👋',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  const Text('Bénévole', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => context.go(AppConstants.volunteerMissionsRoute),
                    child: const Text('Missions', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                  GestureDetector(
                    onTap: () => context.go(AppConstants.volunteerProfileRoute),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _primary.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: _primary, width: 2),
                          ),
                          child: const Icon(Icons.person_outline, color: _primary, size: 28),
                        ),
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          Expanded(
            child: _statCard(
              icon: Icons.star,
              iconColor: _primary,
              label: 'Points Impact',
              value: '1,250',
              bgColor: _primary.withOpacity(0.1),
              borderColor: _primary.withOpacity(0.2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _statCard(
              icon: Icons.volunteer_activism,
              iconColor: Colors.green.shade600,
              label: 'Missions',
              value: '24',
              bgColor: Colors.green.shade50,
              borderColor: Colors.green.shade100,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _buildSkillsSection(BuildContext context) {
    final skills = [
      (Icons.psychology, Colors.amber.shade500, Colors.amber.shade100, 'TDAH'),
      (Icons.palette, Colors.blue.shade500, Colors.blue.shade100, 'Art Thérapie'),
      (Icons.menu_book, Colors.purple.shade500, Colors.purple.shade100, 'Lecture'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Mes Compétences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              GestureDetector(
                onTap: () {},
                child: const Text('Voir tout', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _primary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: skills.length,
              itemBuilder: (context, i) {
                final s = skills[i];
                return Container(
                  width: 128,
                  margin: EdgeInsets.only(right: i < skills.length - 1 ? 12 : 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(color: s.$3, shape: BoxShape.circle),
                        child: Icon(s.$1, color: s.$2, size: 26),
                      ),
                      const SizedBox(height: 8),
                      Text(s.$4, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Demandes Ouvertes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('URGENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _requestCard(
            familyName: 'Famille Martin',
            location: '2.4 km • Lyon 03',
            description: 'Besoin d\'aide pour une séance de lecture adaptée avec Lucas (8 ans, Spectre Autistique).',
            timeSlot: '16:30 - 18:00',
            badge: 'Aujourd\'hui',
            badgeColor: _primary,
            badgeBgColor: _primary.withOpacity(0.1),
          ),
          const SizedBox(height: 16),
          _requestCard(
            familyName: 'Famille Dubois',
            location: '5.1 km • Villeurbanne',
            description: 'Accompagnement pour une sortie au parc Georges Bazin. Sophie a besoin d\'un binôme rassurant.',
            timeSlot: '14:00 - 16:00',
            badge: 'Demain',
            badgeColor: Colors.grey.shade600,
            badgeBgColor: Colors.grey.shade100,
          ),
        ],
      ),
    );
  }

  Widget _requestCard({
    required String familyName,
    required String location,
    required String description,
    required String timeSlot,
    required String badge,
    required Color badgeColor,
    required Color badgeBgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                child: Icon(Icons.home_outlined, color: Colors.grey.shade600, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(familyName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(location, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: badgeBgColor, borderRadius: BorderRadius.circular(8)),
                child: Text(badge, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: badgeColor)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(description, style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade100))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(timeSlot, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
                Material(
                  color: _primary,
                  borderRadius: BorderRadius.circular(12),
                  elevation: 2,
                  shadowColor: _primary.withOpacity(0.3),
                  child: InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Text('Accepter', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanningSection(BuildContext context) {
    const weekdays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    const dates = ['12', '13', '14', '15', '16', '17', '18'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Mon Planning', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              GestureDetector(
                onTap: () => context.go(AppConstants.volunteerAgendaRoute),
                child: const Text('Détails', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _primary)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(7, (i) => Text(weekdays[i], style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500))),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(7, (i) {
                    final isToday = i == 2;
                    return Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: isToday
                          ? const BoxDecoration(color: _primary, shape: BoxShape.circle)
                          : null,
                      child: Text(
                        dates[i],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                          color: isToday ? Colors.white : (i == 3 ? const Color(0xFF1E293B) : Colors.grey.shade500),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(width: 4, height: 32, decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Prochaine intervention', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                            Text('Mercredi 14, 16:30 avec Lucas', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
