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

    // Show feedback for badges earned
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
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
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

    // Milestone celebration (5, 10, 15, 20... levels completed) using sticker task count
    final completed = stickerProvider.tasksCompletedCount;
    final milestoneSteps = [5, 10, 15, 20, 25, 30];
    if (milestoneSteps.contains(completed)) {
      final loc = AppLocalizations.of(context);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && loc != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      loc.milestoneLevelsCompleted(completed),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF2E7D32),
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
    }
  } catch (e) {
    // Silently fail - don't break existing functionality if backend is unavailable
    debugPrint('Failed to record game session in backend: $e');
  }
}
