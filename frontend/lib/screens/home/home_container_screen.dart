import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/theme.dart';
import 'home_dashboard_screen.dart';
import '../profile/healthcare_profile_screen.dart';

/// Écran Patients pour les professionnels de santé.
class HomePatientsScreen extends StatelessWidget {
  const HomePatientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 0,
        title: Text(
          loc.parents,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.group_outlined,
                size: 56, color: AppTheme.text.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              loc.noPatientsYet,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.text.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              loc.patientsListWillAppear,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.text.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Écran Messages pour les professionnels de santé.
class HomeMessagesScreen extends StatelessWidget {
  const HomeMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 0,
        title: Text(
          loc.messages,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 56, color: AppTheme.text.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              loc.noMessagesYet,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.text.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              loc.conversationsWillAppear,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.text.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Palette alignée sur la nav famille
const Color _navPrimary = Color(0xFFA3D9E2);
const Color _navInactive = Color(0xFF94A3B8);

class HomeContainerScreen extends StatefulWidget {
  const HomeContainerScreen({super.key});

  @override
  State<HomeContainerScreen> createState() => _HomeContainerScreenState();
}

class _HomeContainerScreenState extends State<HomeContainerScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeDashboardScreen(), // Tableau
    const HomePatientsScreen(), // Patients
    const HomeMessagesScreen(), // Messages
    const HealthcareProfileScreen(), // Profil professionnel de santé
  ];

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.white,
      body: _screens[_currentIndex],
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(
                  context: context,
                  index: 0,
                  icon: Icons.grid_view_outlined,
                  activeIcon: Icons.grid_view,
                  label: loc.tableau,
                ),
                _navItem(
                  context: context,
                  index: 1,
                  icon: Icons.groups_outlined,
                  activeIcon: Icons.groups,
                  label: loc.parents,
                ),
                _centerHomeButton(),
                _navItem(
                  context: context,
                  index: 2,
                  icon: Icons.chat_bubble_outline,
                  activeIcon: Icons.chat_bubble,
                  label: loc.messages,
                ),
                _navItem(
                  context: context,
                  index: 3,
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: loc.profil,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Bouton rond central qui ramène au tableau (index 0), comme pour la famille.
  Widget _centerHomeButton() {
    return InkWell(
      onTap: () => setState(() => _currentIndex = 0),
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

  Widget _navItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
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
                fontSize: 11,
                letterSpacing: 0.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? _navPrimary : _navInactive,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
