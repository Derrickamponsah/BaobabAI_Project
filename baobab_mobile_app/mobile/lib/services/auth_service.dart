import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';

/// Handles sign-up, login, token persistence and the current session.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  String? _token;
  Map<String, dynamic>? _user;

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isLoggedIn => _token != null;

  Map<String, String> get authHeaders => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    final u = prefs.getString('user');
    if (u != null) _user = jsonDecode(u);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (_token != null) prefs.setString('token', _token!);
    if (_user != null) prefs.setString('user', jsonEncode(_user));
  }

  Future<String?> signup(String name, String email, String password) async {
    final r = await http.post(
      Uri.parse('${AppConfig.apiPrefix}/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'full_name': name, 'email': email, 'password': password}),
    );
    final body = jsonDecode(r.body);
    if (r.statusCode == 201) {
      _token = body['token'];
      _user = body['user'];
      await _persist();
      return null;
    }
    return body['error'] ?? 'Sign-up failed';
  }

  Future<String?> login(String email, String password) async {
    final r = await http.post(
      Uri.parse('${AppConfig.apiPrefix}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final body = jsonDecode(r.body);
    if (r.statusCode == 200) {
      _token = body['token'];
      _user = body['user'];
      await _persist();
      return null;
    }
    return body['error'] ?? 'Login failed';
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }
}
