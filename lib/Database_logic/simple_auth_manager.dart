import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SimpleAuthManager {
  static final SimpleAuthManager _instance = SimpleAuthManager._internal();
  factory SimpleAuthManager() => _instance;
  SimpleAuthManager._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _usersKey = 'simple_auth_users';
  static const String _currentUserKey = 'simple_auth_current_user';
  static const String _rememberMeKey = 'simple_auth_remember_me';

  // Current user data
  String? _currentUserId;
  String? _currentUsername;
  bool _isAuthenticated = false;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  String? get currentUserId => _currentUserId;
  String? get currentUsername => _currentUsername;

  /// Initialize authentication system and check for existing session
  Future<void> initialize() async {
    try {
      // Check if user was remembered
      final prefs = await SharedPreferences.getInstance();
      final rememberMeData = prefs.getString(_rememberMeKey);
      if (rememberMeData != null) {
        final data = jsonDecode(rememberMeData);
        final userId = data['userId'];
        final username = data['username'];
        
        if (userId != null && username != null) {
          _currentUserId = userId;
          _currentUsername = username;
          _isAuthenticated = true;
          print("SimpleAuth: Restored session for user: $username ($userId)");
        }
      }
      
      print("SimpleAuth: Initialization complete. Authenticated: $_isAuthenticated");
    } catch (e) {
      print("SimpleAuth: Error during initialization: $e");
    }
  }

  /// Sign up a new user with username and password
  Future<SignUpResult> signUp({
    required String username,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      if (username.trim().isEmpty || password.trim().isEmpty) {
        return SignUpResult(success: false, message: "Username and password cannot be empty");
      }

      if (username.length < 2) {
        return SignUpResult(success: false, message: "Username must be at least 2 characters");
      }

      if (password.length < 3) {
        return SignUpResult(success: false, message: "Password must be at least 3 characters");
      }

      // Get existing users
      final users = await _getStoredUsers();
      
      // Check if username already exists
      if (users.containsKey(username.toLowerCase())) {
        return SignUpResult(success: false, message: "Username already exists");
      }

      // Create user ID and hash password
      final userId = _generateUserId();
      final hashedPassword = _hashPassword(password);

      // Store user
      users[username.toLowerCase()] = {
        'userId': userId,
        'username': username, // Store original case
        'hashedPassword': hashedPassword,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'isWaiting': false,
        'isInConversation': false,
        'momStage': null,
        'questionSet1': null,
        'questionSet2': null,
      };

      await _saveUsers(users);

      // Create Firestore user document
      await _createFirestoreUser(userId, username);

      // Sign in the user
      _currentUserId = userId;
      _currentUsername = username;
      _isAuthenticated = true;

      // Handle Remember Me
      if (rememberMe) {
        await _saveRememberMe(userId, username);
      }

      print("SimpleAuth: User signed up successfully: $username ($userId)");
      return SignUpResult(success: true, message: "Account created successfully!");

    } catch (e) {
      print("SimpleAuth: Error during sign up: $e");
      return SignUpResult(success: false, message: "Error creating account: $e");
    }
  }

  /// Sign in existing user with username and password
  Future<SignInResult> signIn({
    required String username,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      if (username.trim().isEmpty || password.trim().isEmpty) {
        return SignInResult(success: false, message: "Username and password cannot be empty");
      }

      // Get existing users
      final users = await _getStoredUsers();
      final userKey = username.toLowerCase();
      
      if (!users.containsKey(userKey)) {
        return SignInResult(success: false, message: "Username not found");
      }

      final userData = users[userKey];
      final storedHashedPassword = userData['hashedPassword'];
      final hashedInputPassword = _hashPassword(password);

      if (storedHashedPassword != hashedInputPassword) {
        return SignInResult(success: false, message: "Incorrect password");
      }

      // Sign in successful
      _currentUserId = userData['userId'];
      _currentUsername = userData['username']; // Use original case
      _isAuthenticated = true;

      // Handle Remember Me
      if (rememberMe) {
        await _saveRememberMe(_currentUserId!, _currentUsername!);
      } else {
        await _clearRememberMe();
      }

      print("SimpleAuth: User signed in successfully: $_currentUsername ($_currentUserId)");
      return SignInResult(success: true, message: "Welcome back!");

    } catch (e) {
      print("SimpleAuth: Error during sign in: $e");
      return SignInResult(success: false, message: "Error signing in: $e");
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    _currentUserId = null;
    _currentUsername = null;
    _isAuthenticated = false;
    await _clearRememberMe();
    print("SimpleAuth: User signed out");
  }

  /// Get remembered username if available
  Future<String?> getRememberedUsername() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMeData = prefs.getString(_rememberMeKey);
      if (rememberMeData != null) {
        final data = jsonDecode(rememberMeData);
        return data['username'];
      }
    } catch (e) {
      print("SimpleAuth: Error getting remembered username: $e");
    }
    return null;
  }

  /// Check if user has completed onboarding
  Future<bool> hasCompletedOnboarding() async {
    if (!_isAuthenticated || _currentUserId == null) {
      return false;
    }

    try {
      final userDoc = await _firestore.collection('users').doc(_currentUserId).get();
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        bool hasMomStage = userData.containsKey('momStage');
        bool hasQuestionSet1 = userData.containsKey('questionSet1');
        bool hasQuestionSet2 = userData.containsKey('questionSet2');
        
        return hasMomStage && (hasQuestionSet1 || hasQuestionSet2);
      }
      
      return false;
    } catch (e) {
      print("SimpleAuth: Error checking onboarding: $e");
      return false;
    }
  }

  // Private helper methods

  Future<Map<String, dynamic>> _getStoredUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_usersKey);
      if (usersJson != null) {
        return Map<String, dynamic>.from(jsonDecode(usersJson));
      }
    } catch (e) {
      print("SimpleAuth: Error reading stored users: $e");
    }
    return {};
  }

  Future<void> _saveUsers(Map<String, dynamic> users) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_usersKey, jsonEncode(users));
    } catch (e) {
      print("SimpleAuth: Error saving users: $e");
    }
  }

  String _generateUserId() {
    return 'user_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (9999 - 1000) * (DateTime.now().microsecond / 1000000)).round()}';
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password + 'simple_auth_salt_2024');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _saveRememberMe(String userId, String username) async {
    try {
      final data = {
        'userId': userId,
        'username': username,
      };
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_rememberMeKey, jsonEncode(data));
    } catch (e) {
      print("SimpleAuth: Error saving remember me: $e");
    }
  }

  Future<void> _clearRememberMe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_rememberMeKey);
    } catch (e) {
      print("SimpleAuth: Error clearing remember me: $e");
    }
  }

  Future<void> _createFirestoreUser(String userId, String username) async {
    await _firestore.collection('users').doc(userId).set({
      'username': username,
      'isInConversation': false,
      'lastStatusUpdate': FieldValue.serverTimestamp(),
      'authMethod': 'simple',
      'createdAt': FieldValue.serverTimestamp(),
      'isWaiting': false,
      'momStage': null,
      'questionSet1': null,
      'questionSet2': null,
    }, SetOptions(merge: true));
  }

  // Additional methods needed by other viewmodels

  /// Get current user ID for database operations
  String getUserId() {
    return _currentUserId ?? "no_user";
  }

  /// Save user data to Firestore
  Future<bool> saveUserData(String field, dynamic value) async {
    try {
      if (!_isAuthenticated || _currentUserId == null) {
        print("SimpleAuth: Cannot save data - user not authenticated");
        return false;
      }

      await _firestore.collection('users').doc(_currentUserId).set({
        field: value,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      print("SimpleAuth: User data saved: $field = $value for user $_currentUserId");
      return true;
    } catch (e) {
      print("SimpleAuth: Error saving user data: $e");
      return false;
    }
  }

  /// Clear specific user data field from Firestore
  Future<bool> clearUserData(String field) async {
    try {
      if (!_isAuthenticated || _currentUserId == null) {
        print("SimpleAuth: Cannot clear data - user not authenticated");
        return false;
      }

      await _firestore.collection('users').doc(_currentUserId).update({
        field: FieldValue.delete(),
      });
      
      print("SimpleAuth: Cleared user data: $field for user $_currentUserId");
      return true;
    } catch (e) {
      print("SimpleAuth: Error clearing user data: $e");
      return false;
    }
  }

  /// Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      if (!_isAuthenticated || _currentUserId == null) {
        print("SimpleAuth: Cannot get data - user not authenticated");
        return null;
      }

      DocumentSnapshot doc = await _firestore.collection('users').doc(_currentUserId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        print("SimpleAuth: Retrieved user data for $_currentUserId");
        return data;
      } else {
        print("SimpleAuth: No user data found for $_currentUserId");
        return null;
      }
    } catch (e) {
      print("SimpleAuth: Error getting user data: $e");
      return null;
    }
  }

  /// Save user profile data to Firestore
  Future<bool> saveUserProfile(Map<String, dynamic> data) async {
    try {
      if (!_isAuthenticated || _currentUserId == null) {
        print("SimpleAuth: Cannot save profile - user not authenticated");
        return false;
      }

      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('users').doc(_currentUserId).set(
        data,
        SetOptions(merge: true),
      );
      
      print("SimpleAuth: User profile saved for $_currentUserId");
      return true;
    } catch (e) {
      print("SimpleAuth: Error saving user profile: $e");
      return false;
    }
  }

  /// Show error message to user
  void showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

class SignUpResult {
  final bool success;
  final String message;

  const SignUpResult({required this.success, required this.message});
}

class SignInResult {
  final bool success;
  final String message;

  const SignInResult({required this.success, required this.message});
} 