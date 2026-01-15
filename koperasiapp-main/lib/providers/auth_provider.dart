import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  String? _role;

  bool get isLoggedIn => _token != null;
  String? get token => _token;
  String? get role => _role;

  Future<void> login(String token, String role) async {
    _token = token;
    _role = role;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('role', role);

    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _role = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('token')) {
      return;
    }
    _token = prefs.getString('token');
    _role = prefs.getString('role');
    notifyListeners();
  }
}
