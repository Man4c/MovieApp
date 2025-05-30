import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_video_app/services/api_service.dart';
import 'package:flutter_video_app/models/user_model.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isInitialized = false;
  String? _token;
  UserModel? _user;
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  bool get isAuthenticated => _isAuthenticated;
  bool get isInitialized => _isInitialized;
  String? get token => _token;
  UserModel? get user => _user;

  AuthProvider() {
    _loadAuthState();
  }

  Future<void> _loadAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      final userJson = prefs.getString(_userKey);

      if (token != null && userJson != null) {
        _token = token;
        _user = UserModel.fromJson(json.decode(userJson));
        _isAuthenticated = true;
        ApiService.setToken(token);
      }
    } catch (e) {
      print('Error loading auth state: $e');
      await _clearAuthState();
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _saveAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_token != null && _user != null) {
        await prefs.setString(_tokenKey, _token!);
        await prefs.setString(_userKey, json.encode(_user!.toJson()));
      }
    } catch (e) {
      print('Error saving auth state: $e');
      await logout();
    }
  }

  Future<void> _clearAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
    } catch (e) {
      print('Error clearing auth state: $e');
    }
  }

  Future<void> login(String email, String password) async {
    try {
      final response = await ApiService.login(email, password);
      await _handleAuthResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> register(String name, String email, String password) async {
    try {
      final response = await ApiService.register(name, email, password);
      await _handleAuthResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _handleAuthResponse(Map<String, dynamic> response) async {
    _token = response['token'];
    _user = UserModel.fromJson(response['user']);
    _isAuthenticated = true;
    ApiService.setToken(_token!);
    await _saveAuthState();
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      // Call logout endpoint if your API has one
      // await ApiService.logout();
    } catch (e) {
      print('Error during logout: $e');
    } finally {
      _token = null;
      _user = null;
      _isAuthenticated = false;
      ApiService.setToken('');
      await _clearAuthState();
      notifyListeners();
    }
  }

  // Verify token validity
  Future<bool> verifyToken() async {
    if (_token == null) return false;

    try {
      // Call your API endpoint to verify token
      // final isValid = await ApiService.verifyToken(_token!);
      // return isValid;
      return true; // Replace with actual token verification
    } catch (e) {
      print('Error verifying token: $e');
      await logout();
      return false;
    }
  }

  Future<void> checkSession() async {
    if (!_isAuthenticated || _token == null) return;

    try {
      final isValid = await verifyToken();
      if (!isValid) {
        // Token is invalid or expired
        await logout();
      }
    } catch (e) {
      print('Error checking session: $e');
      await logout();
    }
  }
}
