import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../services/volunteer_service.dart';
import '../../utils/constants.dart';

const Color _navPrimary = Color(0xFFa3dae1);
const Color _navInactive = Color(0xFF94A3B8);

/// Shell secteur bénévole : Service Hub | Formations | Messages | Profil.
/// Service Hub (dashboard) est l'écran affiché en premier après connexion.
class VolunteerShellScreen extends StatefulWidget {
  const VolunteerShellScreen({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  State<VolunteerShellScreen> createState() => _VolunteerShellScreenState();
}

class _VolunteerShellScreenState extends State<VolunteerShellScreen> {
  Map<String, dynamic>? _application;

  void _onTap(int index) {
    if (index == 0) {
      context.go(AppConstants.volunteerCommunityRoute);
      return;
    }
    const int messagesIndex = 3;
    final trainingCertified = _application?['trainingCertified'] == true;
    if (index == messagesIndex && !trainingCertified) {
      final loc = AppLocalizations.of(context)!;
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(loc.volunteerTrainingLockedTitle),
          content: Text(loc.volunteerTrainingLockedMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(loc.volunteerProfileAlertLaterButton),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                widget.navigationShell.goBranch(2); // Formations (index 2)
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _navPrimary,
                foregroundColor: Colors.white,
              ),
              child: Text(loc.volunteerTrainingLockedGoToFormations),
            ),
          ],
        ),
      );
      return;
    }
    widget.navigationShell.goBranch(index);
  }

  Future<void> _checkVolunteerProfileComplete() async {
    try {
      final app = await VolunteerService().getMyApplication();
      if (mounted) setState(() => _application = app);
      final profileComplete = app['profileComplete'] == true;
      if (profileComplete) return;
      if (!mounted) return;
      final ctx = context;
      final loc = AppLocalizations.of(ctx)!;
      showDialog<void>(
        context: ctx,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: Text(loc.volunteerProfileAlertTitle),
          content: Text(loc.volunteerProfileAlertMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(loc.volunteerProfileAlertLaterButton),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (!mounted) return;
                context.push(AppConstants.volunteerApplicationRoute);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _navPrimary,
                foregroundColor: Colors.white,
              ),
              child: Text(loc.volunteerProfileAlertCompleteButton),
            ),
          ],
        ),
      );
    } catch (_) {
      // Ignore: user may not be volunteer or network error
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVolunteerProfileComplete());
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final role = user?.role;
    final currentIndex =
        _indexFromPath(GoRouterState.of(context).uri.path, role);

    return Scaffold(
      backgroundColor: Colors.white,
      body: widget.navigationShell,
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
                _navItem(context, 0, Icons.groups_outlined, Icons.groups,
                    'Communauté', currentIndex),
                _navItem(context, 1, Icons.home_outlined, Icons.home_rounded,
                    'Service Hub', currentIndex),
                _navItem(context, 2, Icons.school_outlined,
                    Icons.school_rounded, 'Formations', currentIndex),
                _navItem(context, 3, Icons.chat_bubble_outline,
                    Icons.chat_bubble, 'Messages', currentIndex),
                _navItem(context, 4, Icons.person_outline, Icons.person,
                    'Profil', currentIndex),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _indexFromPath(String path, String? role) {
    if (path.contains('/community')) return 0;
    if (path.endsWith('/dashboard')) return 1;
    if (path.endsWith('/formations') ||
        path == '/volunteer' ||
        path == '/volunteer/') {
      return 2;
    }
    if (path.endsWith('/messages')) return 3;
    if (path.endsWith('/profile')) return 4;

    // Default branch for /volunteer or unknown
    if (AppConstants.isSpecialistRole(role)) {
      return 1; // Service Hub (dashboard) for specialists
    }
    return 1; // Service Hub (dashboard) for regular volunteers
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
