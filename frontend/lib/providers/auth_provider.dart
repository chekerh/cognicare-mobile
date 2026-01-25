import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = false;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null && _user != null;

  final AuthService _authService = AuthService();

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _authService.login(email, password);
      _token = response.token;
      _user = response.user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signup({
    required String fullName,
    required String email,
    required String password,
    String? phone,
    required String role,
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
      );
      _token = response.token;
      _user = response.user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loadStoredAuth() async {
    final storedToken = await _authService.getStoredToken();
    final storedUser = await _authService.getStoredUser();

    if (storedToken != null && storedUser != null) {
      _token = storedToken;
      _user = storedUser;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    await _authService.clearStoredData();
    _token = null;
    _user = null;
    notifyListeners();
  }
}