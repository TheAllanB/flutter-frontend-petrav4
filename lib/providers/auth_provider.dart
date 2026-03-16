import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import '../services/api_client.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? _token;
  User? _user;

  String? get token => _token;
  User? get user => _user;
  bool get isAuthenticated => _token != null;

  Future<void> login(String email, String password) async {
    final data = await _authService.login(email, password);
    _token = data['token'];
    _user = data['user'];
    ApiClient.authToken = _token;
    await _storage.write(key: 'auth_token', value: _token);
    notifyListeners();
  }

  Future<void> register(String name, String email, String password) async {
    final data = await _authService.register(name, email, password);
    _token = data['token'];
    _user = data['user'];
    ApiClient.authToken = _token;
    await _storage.write(key: 'auth_token', value: _token);
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    ApiClient.authToken = null;
    await _storage.delete(key: 'auth_token');
    notifyListeners();
  }

  Future<void> checkAuth() async {
    _token = await _storage.read(key: 'auth_token');
    if (_token != null) {
      try {
        final data = await _authService.getMe();
        _user = data['user'];
      } catch (e) {
        // Token might be invalid or expired
        await _storage.delete(key: 'auth_token');
        _token = null;
        ApiClient.authToken = null;
        _user = null;
      }
      if (_token != null) {
        ApiClient.authToken = _token;
      }
    }
    notifyListeners();
  }
}
