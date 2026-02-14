import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/child_mode_session_provider.dart';
import '../providers/child_security_code_provider.dart';
import '../providers/gamification_provider.dart';
import '../services/gamification_service.dart';
import '../utils/constants.dart';
import 'parent_code_input_dialog.dart';

/// Enregistre la durée du mode enfant et navigue vers le profil (sortie sans code).
Future<void> _recordChildModeDurationAndExit(BuildContext context) async {
  final sessionProvider = context.read<ChildModeSessionProvider>();
  final durationSeconds = sessionProvider.durationSeconds;
  sessionProvider.clearSession();
  final gp = context.read<GamificationProvider>();
  if (gp.currentChildId != null && durationSeconds > 0) {
    try {
      await gp.recordGameSession(
        gameType: GameType.childMode,
        completed: true,
        timeSpentSeconds: durationSeconds,
      );
    } catch (_) {}
  }
  if (context.mounted) context.go(AppConstants.familyProfileRoute);
}

/// Bouton "Appui long" pour quitter le mode enfant (affiché sur le dashboard et tous les écrans de jeux).
class ChildModeExitButton extends StatelessWidget {
  const ChildModeExitButton({
    super.key,
    this.iconColor,
    this.textColor,
    this.opacity = 0.4,
  });

  final Color? iconColor;
  final Color? textColor;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final codeProvider = Provider.of<ChildSecurityCodeProvider>(context, listen: false);
    final iconC = iconColor ?? Colors.white;
    final textC = textColor ?? Colors.white;

    Future<void> handleExit() async {
      if (codeProvider.hasCode) {
        await ParentCodeInputDialog.show(context);
      } else {
        await _recordChildModeDurationAndExit(context);
      }
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: handleExit,
      onLongPress: handleExit,
      child: Opacity(
        opacity: opacity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: iconC.withOpacity(0.2),
                border: Border.all(color: iconC.withOpacity(0.4), width: 2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.logout_rounded, color: iconC, size: 28),
            ),
            const SizedBox(height: 4),
            Text(
              loc.childDashboardLongPress,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: textC,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
