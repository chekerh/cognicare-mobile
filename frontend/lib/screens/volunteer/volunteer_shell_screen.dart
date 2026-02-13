import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const Color _navPrimary = Color(0xFFA4D9E5);
const Color _navInactive = Color(0xFF94A3B8);

/// Shell secteur bénévole : Accueil | Agenda | Formations | Messages | Profil.
/// Formations est l'écran affiché en premier après connexion.
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
                _navItem(context, 0, Icons.home_outlined, Icons.home_rounded, 'Accueil', currentIndex),
                _navItem(context, 1, Icons.calendar_today_outlined, Icons.calendar_today, 'Agenda', currentIndex),
                _navItem(context, 2, Icons.school_outlined, Icons.school_rounded, 'Formations', currentIndex),
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
    if (path.endsWith('/dashboard')) return 0;
    if (path.endsWith('/agenda')) return 1;
    if (path.endsWith('/formations') || path == '/volunteer' || path == '/volunteer/') return 2;
    if (path.endsWith('/messages')) return 3;
    if (path.endsWith('/profile')) return 4;
    return 2;
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
