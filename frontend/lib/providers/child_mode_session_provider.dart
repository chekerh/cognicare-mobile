import 'package:flutter/foundation.dart';

/// Enregistre le début de la session "mode enfant" pour calculer la durée
/// à la sortie et l'envoyer au backend (temps de jeu).
class ChildModeSessionProvider with ChangeNotifier {
  DateTime? _startedAt;

  /// Démarre la session (appelé à l'entrée sur le dashboard mode enfant).
  void startSession() {
    if (_startedAt == null) {
      _startedAt = DateTime.now();
      notifyListeners();
    }
  }

  /// Durée en secondes depuis le début de la session.
  int get durationSeconds {
    if (_startedAt == null) return 0;
    return DateTime.now().difference(_startedAt!).inSeconds;
  }

  bool get hasSession => _startedAt != null;

  /// Réinitialise après enregistrement de la session côté backend.
  void clearSession() {
    _startedAt = null;
    notifyListeners();
  }
}
