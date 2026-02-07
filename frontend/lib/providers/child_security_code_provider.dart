import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _keyParentCode = 'child_mode_parent_code';

/// Stores and verifies the 4-digit parent code used to exit child mode.
/// Code is stored per user (family) - one code for the whole family.
class ChildSecurityCodeProvider with ChangeNotifier {
  ChildSecurityCodeProvider() {
    _load();
  }

  String? _savedCode;

  /// True if a security code has been set.
  bool get hasCode => _savedCode != null && _savedCode!.length == 4;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _savedCode = prefs.getString(_keyParentCode);
      notifyListeners();
    } catch (_) {}
  }

  /// Set the 4-digit parent code. Returns true on success.
  Future<bool> setCode(String code) async {
    if (code.length != 4 || !RegExp(r'^\d{4}$').hasMatch(code)) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyParentCode, code);
      _savedCode = code;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Verify the entered code. Returns true if it matches.
  bool verifyCode(String code) {
    return _savedCode != null && _savedCode == code;
  }

  /// Clear the saved code (e.g. for testing).
  Future<void> clearCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyParentCode);
      _savedCode = null;
      notifyListeners();
    } catch (_) {}
  }
}
