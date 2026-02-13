// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/sticker_book_provider.dart';
import '../providers/gamification_provider.dart';
import '../services/gamification_service.dart';

/// Helper to record game completion both locally (StickerBookProvider) and in backend (GamificationProvider).
/// This ensures backward compatibility with existing sticker system while adding backend tracking.
Future<void> recordGameCompletion({
  required BuildContext context,
  required String levelKey, // e.g. "matching", "shape_1", "star_1"
  required GameType gameType,
  int? level,
  int? timeSpentSeconds,
  Map<String, int>? metrics,
}) async {
  // Record locally (existing behavior)
  final stickerProvider = Provider.of<StickerBookProvider>(context, listen: false);
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  await stickerProvider.recordLevelCompleted(levelKey);

  // Record in backend (new gamification system)
  try {
    final gamificationProvider = Provider.of<GamificationProvider>(context, listen: false);
    final result = await gamificationProvider.recordGameSession(
      gameType: gameType,
      level: level,
      completed: true,
      timeSpentSeconds: timeSpentSeconds,
      metrics: metrics,
    );

    // Badge feedback: light toast without green frame (milestone phrase is on Bravo screen)
    if (result != null && result.badgesEarned.isNotEmpty) {
      for (final badge in result.badgesEarned) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.emoji_events, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Badge débloqué: ${badge.name}!',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF1A4B7A),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        });
      }
    }

    // Show points earned feedback
    if (result != null && result.pointsEarned > 0) {
      final total = result.totalPoints;
      final loc = AppLocalizations.of(context);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      loc != null
                          ? '+${result.pointsEarned} ${loc.totalPointsLabel}! Total: $total'
                          : '+${result.pointsEarned} points! Total: $total',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
    }

    // Alerte verte : jalon (5, 10, 15, 20, 25, 30) — trophée + "You've completed X levels!"
    // On utilise scaffoldMessenger capturé pour que l'alerte s'affiche même après navigation (ex. passage au jeu suivant).
    final completed = stickerProvider.tasksCompletedCount;
    final milestoneSteps = [5, 10, 15, 20, 25, 30];
    if (milestoneSteps.contains(completed)) {
      final loc = AppLocalizations.of(context);
      final message = loc?.milestoneLevelsCompleted(completed) ?? 'You\'ve completed $completed levels!';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF2E7D32),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          ),
        );
      });
    }
  } catch (e) {
    // Silently fail - don't break existing functionality if backend is unavailable
    debugPrint('Failed to record game session in backend: $e');
  }
}
