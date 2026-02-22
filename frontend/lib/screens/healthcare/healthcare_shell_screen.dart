import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/constants.dart';

const Color _navPrimary = Color(0xFFA2D9E7);
const Color _navBrand = Color(0xFF2D7DA1);
const Color _navInactive = Color(0xFF94A3B8);

/// Shell secteur healthcare : une seule navbar (Tableau, Patients, Rapports, Messages, Profil).
class HealthcareShellScreen extends StatelessWidget {
  const HealthcareShellScreen({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(index);
  }

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final currentIndex = _indexFromPath(path);

    return Scaffold(
      backgroundColor: Colors.white,
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
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
                _navItem(context, 0, Icons.group_rounded, AppLocalizations.of(context)!.patientsLabel, currentIndex),
                _navItem(context, 1, Icons.insights_rounded, AppLocalizations.of(context)!.reportsLabel, currentIndex),
                _tableauNavItem(context, currentIndex),
                _navItem(context, 3, Icons.chat_bubble_outline_rounded, AppLocalizations.of(context)!.messageLabel, currentIndex),
                _navItem(context, 4, Icons.person_outline_rounded, AppLocalizations.of(context)!.profileTitle, currentIndex),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _indexFromPath(String path) {
    if (path.startsWith(AppConstants.healthcareRoute)) {
      if (path.endsWith('patients')) return 0;
      if (path.endsWith('reports')) return 1;
      if (path.endsWith('dashboard') || path == AppConstants.healthcareRoute || path == '${AppConstants.healthcareRoute}/') return 2;
      if (path.endsWith('messages')) return 3;
      if (path.endsWith('profile')) return 4;
    }
    return 2;
  }

  /// Tableau : logo dans un cercle bleu avec bordure blanche (style FAB).
  Widget _tableauNavItem(BuildContext context, int currentIndex) {
    const int tableauIndex = 2;
    final isSelected = currentIndex == tableauIndex;
    return InkWell(
      onTap: () => _onTap(tableauIndex),
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _navPrimary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: _navPrimary.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.grid_view_rounded,
                size: 26,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context)!.tableauLabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? _navBrand : _navInactive,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, int index, IconData icon, String label, int currentIndex) {
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
              icon,
              size: 26,
              color: isSelected ? _navBrand : _navInactive,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? _navBrand : _navInactive,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
