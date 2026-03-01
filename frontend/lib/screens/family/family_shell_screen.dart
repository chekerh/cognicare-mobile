import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import 'chatbot_sheet.dart';

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
      backgroundColor: Colors.white,
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: _navItem(context, 1, Icons.share_outlined, Icons.share,
                    AppLocalizations.of(context)!.navFeed, currentIndex)),
                Expanded(child: _navItem(context, 2, Icons.chat_bubble_outline,
                    Icons.chat_bubble, AppLocalizations.of(context)!.navChats, currentIndex)),
                Expanded(child: _centerPlusButton(context, currentIndex)),
                Expanded(child: _navItem(context, 3, Icons.shopping_bag_outlined,
                    Icons.shopping_bag, AppLocalizations.of(context)!.navMarket, currentIndex)),
                Expanded(child: _navItem(context, 4, Icons.person_outline, Icons.person,
                    AppLocalizations.of(context)!.navProfile, currentIndex)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _indexFromPath(String path) {
    if (path.endsWith('/dashboard') || path == '/family' || path == '/family/') {
      return 0;
    }
    if (path.endsWith('/feed')) return 1;
    if (path.endsWith('/families')) return 2;
    if (path.endsWith('/market')) return 3;
    if (path.endsWith('/profile')) return 4;
    return 0;
  }

  /// Bouton central Accueil : tap = dashboard, appui long = chatbot Cogni.
  /// Aligné avec les autres onglets : même hauteur de zone (icon + label).
  Widget _centerPlusButton(BuildContext context, int currentIndex) {
    return GestureDetector(
      onTap: () => _onTap(0),
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const ChatbotSheet(),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 30,
            child: Center(
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _navPrimary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _navPrimary.withOpacity(0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.home_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context)!.home,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _navPrimary,
            ),
          ),
        ],
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
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
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
