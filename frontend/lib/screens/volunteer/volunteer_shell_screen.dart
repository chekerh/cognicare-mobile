import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const Color _navPrimary = Color(0xFFA4D9E5);
const Color _navInactive = Color(0xFF94A3B8);

/// Shell secteur bénévole : Agenda | Mission | Accueil (centre) | Messages | Profil.
/// Même style que la navbar famille : bouton central Accueil mis en avant.
class VolunteerShellScreen extends StatelessWidget {
  const VolunteerShellScreen({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(index);
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _indexFromPath(GoRouterState.of(context).uri.path);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(context, 1, Icons.calendar_today_outlined, Icons.calendar_today, 'Agenda', currentIndex),
                _navItem(context, 2, Icons.assignment_outlined, Icons.assignment, 'Mission', currentIndex),
                _centerHomeButton(context, currentIndex),
                _navItem(context, 3, Icons.chat_bubble_outline, Icons.chat_bubble, 'Messages', currentIndex),
                _navItem(context, 4, Icons.person_outline, Icons.person, 'Profil', currentIndex),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _indexFromPath(String path) {
    if (path.endsWith('/dashboard') || path == '/volunteer' || path == '/volunteer/') return 0;
    if (path.endsWith('/agenda')) return 1;
    if (path.endsWith('/missions') || path.endsWith('/mission-itinerary') || path.endsWith('/task-accepted') || path.endsWith('/notifications')) return 2;
    if (path.endsWith('/messages')) return 3;
    if (path.endsWith('/profile')) return 4;
    return 0;
  }

  /// Bouton central Accueil : cercle bleu avec icône maison.
  Widget _centerHomeButton(BuildContext context, int currentIndex) {
    return InkWell(
      onTap: () => _onTap(0),
      borderRadius: BorderRadius.circular(32),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: _navPrimary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _navPrimary.withOpacity(0.45),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.home_rounded,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }

  Widget _navItem(
    BuildContext context,
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
    int currentIndex,
  ) {
    final isSelected = currentIndex == index;
    return InkWell(
      onTap: () => _onTap(index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 26,
              color: isSelected ? _navPrimary : _navInactive,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? _navPrimary : _navInactive,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
