import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_video_app/services/api_service.dart';
import 'package:flutter_video_app/models/user_model.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isInitialized = false;
  String? _token;
  UserModel? _user;
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  bool get isAuthenticated => _isAuthenticated;
  bool get isInitialized => _isInitialized;
  String? get token => _token;
  UserModel? get user => _user;
  bool get hasActiveSubscription {
    if (_user?.subscription == null) return false;
    final status = _user?.subscription?.status?.toLowerCase();
    return status == 'incomplete' || status == 'trialing';
  }

  AuthProvider() {
    _loadAuthState();
    // Listen to Firebase Auth state changes
    _auth.authStateChanges().listen((User? firebaseUser) {
      if (firebaseUser == null) {
        _isAuthenticated = false;
        _token = null;
        _user = null;
        notifyListeners();
      }
    });
  }

  Future<void> _loadAuthState() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        _token = await currentUser.getIdToken();
        _user = UserModel(
          id: currentUser.uid,
          name: currentUser.displayName ?? 'User',
          email: currentUser.email ?? '',
          role: 'user',
          favorites: [],
          watchHistory: [],
        );
        _isAuthenticated = true;
        ApiService.setToken(_token!);
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

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      final User? user = userCredential.user;

      if (user != null) {
        _token = await user.getIdToken();
        _user = UserModel(
          id: user.uid,
          name: user.displayName ?? 'User',
          email: user.email ?? '',
          role: 'user',
          favorites: [],
          watchHistory: [],
          googleId: user.uid,
        );
        _isAuthenticated = true;
        ApiService.setToken(_token!);
        notifyListeners();
      }
    } catch (e) {
      print('Error during Google sign in: $e');
      rethrow;
    }
  }

  Future<void> login(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      final User? user = userCredential.user;
      if (user != null) {
        _token = await user.getIdToken();
        _user = UserModel(
          id: user.uid,
          name: user.displayName ?? 'User',
          email: user.email ?? '',
          role: 'user',
          favorites: [],
          watchHistory: [],
        );
        _isAuthenticated = true;
        ApiService.setToken(_token!);
        notifyListeners();
      }
    } catch (e) {
      print('Error during login: $e');
      rethrow;
    }
  }

  Future<void> register(String name, String email, String password) async {
    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      final User? user = userCredential.user;
      if (user != null) {
        await user.updateDisplayName(name);
        _token = await user.getIdToken();
        _user = UserModel(
          id: user.uid,
          name: name,
          email: user.email ?? '',
          role: 'user',
          favorites: [],
          watchHistory: [],
        );
        _isAuthenticated = true;
        ApiService.setToken(_token!);
        notifyListeners();
      }
    } catch (e) {
      print('Error during registration: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      _token = null;
      _user = null;
      _isAuthenticated = false;
      ApiService.setToken('');
      await _clearAuthState();
      notifyListeners();
    } catch (e) {
      print('Error during logout: $e');
      rethrow;
    }
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

  Future<void> checkSession() async {
    if (!_isAuthenticated || _token == null) return;
    try {
      final isValid = await verifyToken();
      if (!isValid) {
        await logout();
      }
    } catch (e) {
      print('Error checking session: $e');
      await logout();
    }
  }

  Future<void> refreshUserData() async {
    if (!_isAuthenticated || _token == null) return;

    try {
      final updatedUser = await ApiService.getCurrentUser();
      _user = updatedUser;
      await _saveAuthState();
      notifyListeners();
      print(
        'User data refreshed. Subscription status: ${_user?.subscription?.status}',
      );
    } catch (e) {
      print('Error refreshing user data: $e');
      rethrow;
    }
  }

  Future<bool> verifyToken() async {
    if (_token == null) return false;

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Get a fresh token to verify it's still valid
      _token = await currentUser.getIdToken(true);
      return true;
    } catch (e) {
      print('Error verifying token: $e');
      await logout();
      return false;
    }
  }
}
