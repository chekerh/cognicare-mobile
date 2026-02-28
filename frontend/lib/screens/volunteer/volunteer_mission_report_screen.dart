import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const Color _primary = Color(0xFFa3dae1);
const Color _bgLight = Color(0xFFF0F9FF);
const Color _slate700 = Color(0xFF334155);

/// Rapport de Mission — résumé, humeur enfant, activités, notes parents, envoyer.
class VolunteerMissionReportScreen extends StatefulWidget {
  const VolunteerMissionReportScreen({super.key});

  @override
  State<VolunteerMissionReportScreen> createState() =>
      _VolunteerMissionReportScreenState();
}

class _VolunteerMissionReportScreenState
    extends State<VolunteerMissionReportScreen> {
  final _summaryController = TextEditingController();
  final _notesController = TextEditingController();
  int _moodIndex = 1; // 0 Joyeux, 1 Calme, 2 Anxieux
  final Set<int> _activities = {0}; // 0 Jeux, 1 Lecture, 2 Promenade

  @override
  void dispose() {
    _summaryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 24, 16),
              child: Row(
                children: [
                  _circleButton(Icons.chevron_left, () => context.pop()),
                  const SizedBox(width: 16),
                  const Text('Rapport de Mission',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B))),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _section(
                      icon: Icons.description,
                      title: 'Résumé de la mission',
                      child: TextField(
                        controller: _summaryController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText:
                              "Décrivez le déroulement de la mission et vos observations...",
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _section(
                      icon: Icons.mood,
                      title: "Humeur de l'enfant",
                      child: Row(
                        children: [
                          _moodButton(0, '😊', 'Joyeux'),
                          const SizedBox(width: 12),
                          _moodButton(1, '😌', 'Calme'),
                          const SizedBox(width: 12),
                          _moodButton(2, '😰', 'Anxieux'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _section(
                      icon: Icons.extension,
                      title: 'Activités réalisées',
                      child: Column(
                        children: [
                          _activityRow(
                              0, Icons.sports_esports, 'Jeux & Divertissement'),
                          const SizedBox(height: 12),
                          _activityRow(1, Icons.menu_book, 'Lecture'),
                          const SizedBox(height: 12),
                          _activityRow(2, Icons.directions_walk, 'Promenade'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _section(
                      icon: Icons.lock,
                      title: 'Notes pour les parents',
                      child: TextField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText:
                              "Message privé destiné uniquement aux parents...",
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Rapport envoyé'),
                                behavior: SnackBarBehavior.floating));
                        context.pop();
                      },
                      icon: const Icon(Icons.send, size: 22),
                      label: const Text('Envoyer le rapport',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                        elevation: 4,
                        shadowColor: _primary.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(999),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.06),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: const SizedBox(
            width: 40,
            height: 40,
            child: Icon(Icons.chevron_left, color: _slate700)),
      ),
    );
  }

  Widget _section(
      {required IconData icon, required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _primary, size: 22),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _slate700)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _moodButton(int index, String emoji, String label) {
    final selected = _moodIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _moodIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: selected ? _primary.withOpacity(0.1) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: selected ? _primary : Colors.transparent, width: 2),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 8),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? _primary : Colors.grey.shade700)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _activityRow(int index, IconData icon, String label) {
    final selected = _activities.contains(index);
    return GestureDetector(
      onTap: () => setState(() {
        if (selected) {
          _activities.remove(index);
        } else {
          _activities.add(index);
        }
      }),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected ? _primary : Colors.grey, size: 24),
            const SizedBox(width: 12),
            Icon(icon, color: Colors.grey.shade600, size: 22),
            const SizedBox(width: 12),
            Text(label,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _slate700)),
          ],
        ),
      ),
    );
  }
}
