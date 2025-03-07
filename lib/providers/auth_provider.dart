import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<void> signInWithGoogle() async {
    _setLoading(true);
    try {
      await _authService.signInWithGoogle();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signInWithApple() async {
    _setLoading(true);
    try {
      await _authService.signInWithApple();
    } finally {
      _setLoading(false);
    }
  }

  void signInOffline() {
    _authService.signInOffline();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
