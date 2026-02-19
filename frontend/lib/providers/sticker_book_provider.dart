import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sticker.dart';

const String _keyTotalTasksCompleted = 'sticker_book_total_tasks_completed';
const String _keyCompletedLevels = 'sticker_book_completed_levels';
const String _keyStickersEarnedToday = 'sticker_book_earned_today';
const String _keyLastEarnedDate = 'sticker_book_last_date';

/// Logique des jeux et récompenses :
///
/// 1. **Tâches** : Chaque niveau réussi dans un jeu = 1 tâche (clé unique : matching, shape_1, star_1, etc.).
/// 2. **Stickers** : Les 12 premières tâches débloquent les 12 stickers (ordre fixe). Au-delà, on ne débloque plus de nouveaux stickers mais les tâches sont quand même comptées.
/// 3. **Prochaine récompense** : Objectif = 16 tâches pour le "Super Hero Pack". La barre de progression affiche tâches complétées / 16 (ex. 9/16).
/// 4. **Aujourd’hui** : "Stickers gagnés aujourd’hui" = nombre de tâches complétées aujourd’hui (réinitialisé chaque jour).
///
/// Jeux et clés utilisées :
/// - Match Pairs : 1 partie gagnée → "matching"
/// - Shape Sorting : 1 niveau (jeu en 1 level) → "shape_1"
/// - Star Tracer : 1 niveau (étoile 5 segments) → "star_1"
class StickerBookProvider with ChangeNotifier {
  StickerBookProvider() {
    _load();
  }

  int _totalTasksCompleted = 0;
  int _stickersEarnedToday = 0;
  String? _lastEarnedDate;

  /// Nombre total de parties gagnées (tous jeux, chaque victoire compte).
  int get tasksCompletedCount => _totalTasksCompleted;

  /// Nombre de stickers débloqués : TOUS DÉBLOQUÉS pour l'utilisateur
  int get unlockedCount => kTotalStickers;

  int get stickersEarnedToday => _stickersEarnedToday;
  int get totalStickers => kTotalStickers;

  /// Tous les stickers sont déverrouillés par défaut
  bool isUnlocked(int index) => true;
  bool isUnlockedById(String stickerId) => true;

  /// Progression vers la prochaine récompense (Super Hero Pack) : jusqu’à 16 tâches.
  int get nextRewardTarget => kNextRewardTarget;
  int get progressTowardNextReward => _totalTasksCompleted.clamp(0, nextRewardTarget);
  int get tasksRemainingForNextReward => (nextRewardTarget - progressTowardNextReward).clamp(0, nextRewardTarget);

  /// True si la récompense "Super Hero Pack" est atteinte (16 tâches).
  bool get hasReachedNextReward => _totalTasksCompleted >= nextRewardTarget;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTotal = prefs.getInt(_keyTotalTasksCompleted);
      final oldList = prefs.getStringList(_keyCompletedLevels);
      _totalTasksCompleted = savedTotal ?? (oldList?.length ?? 0);
      _stickersEarnedToday = prefs.getInt(_keyStickersEarnedToday) ?? 0;
      _lastEarnedDate = prefs.getString(_keyLastEarnedDate);
      _resetTodayIfNewDay();
      notifyListeners();
    } catch (_) {}
  }

  void _resetTodayIfNewDay() {
    final today = _todayString();
    if (_lastEarnedDate != today) {
      _stickersEarnedToday = 0;
      _lastEarnedDate = today;
    }
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  /// Appelé à chaque fois que l’enfant gagne une partie (n’importe quel jeu).
  /// Chaque victoire ajoute 1 à la progression (9 → 10 → … → 16). [levelKey] sert uniquement au suivi (ex. "matching", "shape_1", "star_1").
  Future<bool> recordLevelCompleted(String levelKey) async {
    _totalTasksCompleted++;
    _resetTodayIfNewDay();
    _stickersEarnedToday++;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyTotalTasksCompleted, _totalTasksCompleted);
      await prefs.setInt(_keyStickersEarnedToday, _stickersEarnedToday);
      await prefs.setString(_keyLastEarnedDate, _lastEarnedDate ?? _todayString());
    } catch (_) {}

    notifyListeners();
    return true;
  }

  static String levelKeyForMatching() => 'matching';
  static String levelKeyForShapeSortingLevel(int level) => 'shape_$level';
  static String levelKeyForStarTracerLevel(int level) => 'star_$level';
}
