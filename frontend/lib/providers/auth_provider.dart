import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  String? _accessToken;
  String? _refreshToken;
  bool _isLoading = false;

  User? get user => _user;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _accessToken != null && _user != null;

  final AuthService _authService = AuthService();

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _authService.login(email, password);
      _accessToken = response.accessToken;
      _refreshToken = response.refreshToken;
      _user = response.user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> signup({
    required String fullName,
    required String email,
    required String password,
    String? phone,
    required String role,
    required String verificationCode,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _authService.signup(
        fullName: fullName,
        email: email,
        password: password,
        phone: phone,
        role: role,
        verificationCode: verificationCode,
      );
      _accessToken = response.accessToken;
      _refreshToken = response.refreshToken;
      _user = response.user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> loadStoredAuth() async {
    final storedToken = await _authService.getStoredToken();
    final storedUser = await _authService.getStoredUser();

    if (storedToken != null && storedUser != null) {
      _accessToken = storedToken;
      _user = storedUser;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    await _authService.clearStoredData();
    _accessToken = null;
    _refreshToken = null;
    _user = null;
    notifyListeners();
  }

  void updateUser(User user) {
    _user = user;
    notifyListeners();
    _authService.saveUser(user); // persist so stored user stays in sync
  }
}