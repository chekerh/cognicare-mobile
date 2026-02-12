import 'package:flutter/foundation.dart';
import '../services/gamification_service.dart';
import '../services/auth_service.dart';
import '../services/children_service.dart';
import '../providers/auth_provider.dart';

class GamificationProvider with ChangeNotifier {
  final GamificationService _gamificationService;
  final ChildrenService _childrenService;
  final AuthProvider _authProvider;

  String? _currentChildId;
  ChildStats? _stats;
  bool _isLoading = false;
  String? _error;

  GamificationProvider({
    required GamificationService gamificationService,
    required ChildrenService childrenService,
    required AuthProvider authProvider,
  })  : _gamificationService = gamificationService,
        _childrenService = childrenService,
        _authProvider = authProvider;

  String? get currentChildId => _currentChildId;
  ChildStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get totalPoints => _stats?.totalPoints ?? 0;
  int get gamesCompleted => _stats?.gamesCompleted ?? 0;
  int get currentStreak => _stats?.currentStreak ?? 0;
  List<BadgeEarned> get badges => _stats?.badges ?? [];

  /// Initialize with the first child of the family (or set manually).
  Future<void> initialize() async {
    try {
      final children = await _childrenService.getChildren();
      if (children.isNotEmpty) {
        _currentChildId = children.first.id;
        await loadStats();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Set the current child ID manually.
  void setCurrentChildId(String childId) {
    _currentChildId = childId;
    notifyListeners();
  }

  /// Load stats for the current child.
  Future<void> loadStats() async {
    if (_currentChildId == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _stats = await _gamificationService.getChildStats(_currentChildId!);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Record a game session and update stats.
  Future<GameSessionResult?> recordGameSession({
    required GameType gameType,
    int? level,
    required bool completed,
    int? score,
    int? timeSpentSeconds,
    Map<String, int>? metrics,
  }) async {
    if (_currentChildId == null) {
      await initialize();
      if (_currentChildId == null) {
        _error = 'No child selected';
        notifyListeners();
        return null;
      }
    }

    try {
      final result = await _gamificationService.recordGameSession(
        childId: _currentChildId!,
        gameType: gameType,
        level: level,
        completed: completed,
        score: score,
        timeSpentSeconds: timeSpentSeconds,
        metrics: metrics,
      );

      // Reload stats to get updated data
      await loadStats();

      return result;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }
}
