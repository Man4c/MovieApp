import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_video_app/services/api_service.dart';
import 'package:flutter_video_app/models/user_model.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isInitialized = false;
  String? _token;
  UserModel? _user;
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    clientId:
        '42959912450-2vtkro05bddrc4b1u6m3bd2kk292jsrn.apps.googleusercontent.com',
  );

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
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _handleAuthResponse(data);
      } else {
        throw Exception('Failed to login: ${response.body}');
      }
    } catch (e) {
      print("Error in login provider: $e");
      rethrow;
    }
  }

  Future<void> register(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'name': name, 'email': email, 'password': password}),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        await _handleAuthResponse(data);
      } else {
        throw Exception('Failed to register: ${response.body}');
      }
    } catch (e) {
      print("Error in register provider: $e");
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

  Future<void> updateUsername(String newUsername) async {
    if (_user == null || _token == null) {
      throw Exception('User not authenticated');
    }

    try {
      final updatedUser = await ApiService.updateUsername(newUsername);
      _user = updatedUser; // Update the local user model
      await _saveAuthState(); // Resave auth state with updated user
      notifyListeners();
    } catch (e) {
      print('Error updating username: $e');
      rethrow;
    }
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    if (_token == null) throw Exception('User not authenticated');

    try {
      await ApiService.changePassword(currentPassword, newPassword);
      // No user model change, but you might want to notify listeners if UI needs to react
      // notifyListeners();
    } catch (e) {
      print('Error changing password: $e');
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      print('Starting Google Sign In...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('User cancelled the sign-in');
        return;
      }

      print('Got Google User: ${googleUser.email}');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      print('Got idToken: ${idToken != null}');

      if (idToken == null) {
        throw Exception('Failed to get Google ID token.');
      }

      // Call ApiService to send this token to your backend
      final responseData = await ApiService.signInWithGoogleToken(idToken);

      // Assuming responseData is a map like {'token': '...', 'user': { ... }}
      // Use existing _handleAuthResponse to process it
      await _handleAuthResponse(responseData);
    } catch (e) {
      print('Error during Google sign-in: $e');
      // Ensure logout if partial auth occurs or error happens
      await logout(); // Or a more specific cleanup
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      // Existing backend logout call
      if (_token != null) {
        await http.post(
          Uri.parse('${ApiService.baseUrl}/auth/logout'),
          headers: {'Authorization': 'Bearer $_token'},
        );
      }

      // Sign out from Google
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
    } catch (e) {
      print('Error during backend logout API call or Google sign out: $e');
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

  Future<void> refreshUserData() async {
    if (_token == null) {
      print('Cannot refresh user data: No token available.');
      // Optionally throw an error or handle as appropriate
      return;
    }
    try {
      print('Refreshing user data...');
      // Assuming ApiService.getCurrentUser() fetches the full user profile
      // including any new subscription details.
      final UserModel updatedUser = await ApiService.getCurrentUser();
      _user = updatedUser;
      await _saveAuthState(); // Save the updated user details
      notifyListeners();
      print('User data refreshed.');
    } catch (e) {
      print('Error refreshing user data: $e');
      // Handle error appropriately, e.g., if it's an auth error, maybe logout
      // if (e is YouAuthException && e.statusCode == 401) await logout();
    }
  }
}
