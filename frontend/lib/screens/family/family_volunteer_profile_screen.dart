import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const Color _primary = Color(0xFFA7DBE6);
const Color _primaryDark = Color(0xFF8FC9D6);
const Color _slate800 = Color(0xFF1E293B);
const Color _slate600 = Color(0xFF475569);
const Color _slate500 = Color(0xFF64748B);

/// Écran profil bénévole — header, À propos, Compétences, Demande d'aide (date/heure), Confirmer réservation.
class FamilyVolunteerProfileScreen extends StatefulWidget {
  const FamilyVolunteerProfileScreen({
    super.key,
    required this.volunteerId,
    required this.volunteerName,
    required this.avatarUrl,
    required this.specialization,
    this.location,
    this.about,
    this.skills,
    this.rating = '4.9',
    this.reviewCount = '124',
  });

  final String volunteerId;
  final String volunteerName;
  final String avatarUrl;
  final String specialization;
  final String? location;
  final String? about;
  final List<String>? skills;
  final String rating;
  final String reviewCount;

  static FamilyVolunteerProfileScreen fromState(GoRouterState state) {
    final extra = state.extra as Map<String, dynamic>?;
    if (extra == null) {
      return const FamilyVolunteerProfileScreen(
        volunteerId: '',
        volunteerName: 'Bénévole',
        avatarUrl: '',
        specialization: '',
      );
    }
    final skills = extra['skills'] as List<dynamic>?;
    return FamilyVolunteerProfileScreen(
      volunteerId: extra['id'] as String? ?? '',
      volunteerName: extra['name'] as String? ?? 'Bénévole',
      avatarUrl: extra['avatarUrl'] as String? ?? '',
      specialization: extra['specialization'] as String? ?? '',
      location: extra['location'] as String?,
      about: extra['about'] as String?,
      skills: skills?.map((e) => e.toString()).toList(),
      rating: extra['rating'] as String? ?? '4.9',
      reviewCount: extra['reviewCount'] as String? ?? '124',
    );
  }

  @override
  State<FamilyVolunteerProfileScreen> createState() => _FamilyVolunteerProfileScreenState();
}

class _FamilyVolunteerProfileScreenState extends State<FamilyVolunteerProfileScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 2));
  int _selectedTimeIndex = 1; // 0 or 1

  static const List<String> _defaultTimeSlots = [
    '09:00 - 11:00',
    '13:30 - 15:30',
  ];

  List<DateTime> _getWeekDays() {
    final start = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
    return List.generate(7, (i) => start.add(Duration(days: i)));
  }

  List<String> get _skills {
    if (widget.skills != null && widget.skills!.isNotEmpty) return widget.skills!;
    return widget.specialization.split('&').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  String get _about {
    return widget.about ??
        'Bénévole expérimenté. J\'aime créer un environnement bienveillant où chaque enfant se sent écouté et soutenu.';
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final weekDays = _getWeekDays();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.fromLTRB(24, topPadding + 8, 24, 32),
              decoration: const BoxDecoration(
                color: _primary,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _headerButton(icon: Icons.arrow_back_ios_new, onTap: () => context.pop()),
                      const Text(
                        'Profil bénévole',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _slate800),
                      ),
                      _headerButton(icon: Icons.more_horiz, onTap: () {}),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: Image.network(
                          widget.avatarUrl,
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 96,
                            height: 96,
                            color: _primaryDark,
                            child: const Icon(Icons.person, color: Colors.white, size: 48),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.check, color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.volunteerName,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _slate800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.specialization,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: _slate800.withOpacity(0.8)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _badge(Icons.star, '${widget.rating} (${widget.reviewCount})'),
                      const SizedBox(width: 8),
                      _badge(Icons.verified_user, 'Vérifié'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 24),
                _sectionCard(
                  icon: Icons.info_outline,
                  title: 'À propos',
                  child: Text(
                    _about,
                    style: const TextStyle(fontSize: 15, color: _slate600, height: 1.5),
                  ),
                ),
                const SizedBox(height: 24),
                _sectionTitle(Icons.psychology, 'Compétences vérifiées'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _skills.map((s) => _skillChip(s)).toList(),
                ),
                const SizedBox(height: 24),
                _sectionCard(
                  icon: Icons.event,
                  title: 'Demander de l\'aide',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _monthYear(_selectedDate),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _slate800),
                          ),
                          Row(
                            children: [
                              IconButton(icon: const Icon(Icons.chevron_left, color: _slate500), onPressed: () => setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 7)))),
                              IconButton(icon: const Icon(Icons.chevron_right, color: _slate500), onPressed: () => setState(() => _selectedDate = _selectedDate.add(const Duration(days: 7)))),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: weekDays.map((d) {
                            final isSelected = d.day == _selectedDate.day && d.month == _selectedDate.month;
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedDate = d),
                                child: Container(
                                  width: 56,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: isSelected ? _primary : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: isSelected ? _primary : Colors.grey.shade300),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(_dayShort(d.weekday), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isSelected ? _slate800 : _slate500)),
                                      Text('${d.day}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isSelected ? _slate800 : _slate600)),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Créneaux disponibles', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _slate500)),
                      const SizedBox(height: 8),
                      Row(
                        children: List.generate(_defaultTimeSlots.length, (i) {
                          final selected = _selectedTimeIndex == i;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(right: i < _defaultTimeSlots.length - 1 ? 8 : 0),
                              child: OutlinedButton(
                                onPressed: () => setState(() => _selectedTimeIndex = i),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: selected ? _primary.withOpacity(0.15) : null,
                                  foregroundColor: selected ? _slate800 : _slate600,
                                  side: BorderSide(color: selected ? _primary : Colors.grey.shade300),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text(_defaultTimeSlots[i], style: const TextStyle(fontSize: 13)),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + bottomPadding),
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Réservation confirmée avec ${widget.volunteerName}'), behavior: SnackBarBehavior.floating),
              );
              context.pop();
            },
            icon: const Icon(Icons.calendar_today, size: 20),
            label: const Text('Confirmer la réservation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: _slate800,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.white.withOpacity(0.3),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(width: 40, height: 40, child: Icon(icon, color: _slate800, size: 22)),
      ),
    );
  }

  Widget _badge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _slate800),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _slate800)),
        ],
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: _primary, size: 22),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _slate800)),
      ],
    );
  }

  Widget _sectionCard({required IconData icon, required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _primary, size: 22),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _slate800)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _skillChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _primary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primary.withOpacity(0.3)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _slate800)),
    );
  }

  String _dayShort(int weekday) {
    const d = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return d[weekday - 1];
  }

  String _monthYear(DateTime d) {
    const m = ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
    return '${m[d.month - 1]} ${d.year}';
  }
}
