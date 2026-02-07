import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Barre comme la 2e photo : teal #A3D9E2, fond blanc, + central et grand
const Color _navPrimary = Color(0xFFA3D9E2);
const Color _navInactive = Color(0xFF94A3B8);

/// Shell secteur famille : Feed | Chats | [+] (écran Accueil) | Market | Profile.
/// Pas d’onglet Accueil : le + affiche le dashboard (contenu Accueil).
class FamilyShellScreen extends StatelessWidget {
  const FamilyShellScreen({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(index);
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _indexFromPath(
      GoRouterState.of(context).uri.path,
    );

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
                _navItem(context, 1, Icons.article_outlined, Icons.article, 'Feed', currentIndex),
                _navItem(context, 2, Icons.chat_bubble_outline, Icons.chat_bubble, 'Chats', currentIndex),
                _centerPlusButton(context, currentIndex),
                _navItem(context, 3, Icons.shopping_bag_outlined, Icons.shopping_bag, 'Market', currentIndex),
                _navItem(context, 4, Icons.person_outline, Icons.person, 'Profile', currentIndex),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _indexFromPath(String path) {
    if (path.endsWith('/dashboard') || path == '/family' || path == '/family/') return 0;
    if (path.endsWith('/feed')) return 1;
    if (path.endsWith('/families')) return 2;
    if (path.endsWith('/market')) return 3;
    if (path.endsWith('/profile')) return 4;
    return 0;
  }

  /// Bouton central Accueil : affiche le dashboard. Icône maison (Accueil).
  Widget _centerPlusButton(BuildContext context, int currentIndex) {
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
