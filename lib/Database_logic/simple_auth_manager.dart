import 'dart:convert';
import 'dart:async';
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
  static const Duration _firestoreTimeout = Duration(seconds: 10);

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

      // COMPREHENSIVE USERNAME UNIQUENESS CHECK
      // Check both local storage AND Firebase to prevent duplicates across devices
      
      // STEP 1: Check local storage first (fast check)
      final users = await _getStoredUsers();
      if (users.containsKey(username.toLowerCase())) {
        return SignUpResult(success: false, message: "Username already exists");
      }
      
      // STEP 2: Check Firebase for username uniqueness across all devices
      try {
        print("SimpleAuth: Checking username uniqueness in Firebase...");
        
        // Check for exact username match
        final usernameQuery = await _firestore
            .collection('users')
            .where('username', isEqualTo: username)
            .limit(1)
            .get();
        
        if (usernameQuery.docs.isNotEmpty) {
          print("SimpleAuth: Username '$username' already exists in Firebase");
          return SignUpResult(success: false, message: "Username already exists");
        }
        
        print("SimpleAuth: Username '$username' is unique - proceeding with account creation");
      } catch (e) {
        print("SimpleAuth: Error checking Firebase for username uniqueness: $e");
        // For safety, if Firebase check fails, don't allow account creation
        return SignUpResult(success: false, message: "Unable to verify username uniqueness. Please try again.");
      }

      // Create user ID and hash password
      final userId = _generateUserId();
      final hashedPassword = _hashPassword(password);

      // Store user locally
      // Try to include saved language preference if available
      String? savedLanguage;
      try {
        final prefs = await SharedPreferences.getInstance();
        savedLanguage = prefs.getString('pref_language');
      } catch (_) {}

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
        'language': savedLanguage,
      };

      await _saveUsers(users);

      // Create user document in Firestore with password backup
      await _createFirestoreUser(userId, username, hashedPassword);
      print("SimpleAuth: User document created in Firestore with credential backup");

      // Sign in the user
      _currentUserId = userId;
      _currentUsername = username;
      _isAuthenticated = true;

      // Handle Remember Me
      if (rememberMe) {
        await _saveRememberMe(userId, username);
      }

      print("SimpleAuth: User signed up successfully (local only): $username ($userId)");
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

      // STEP 1: Check local storage first
      final users = await _getStoredUsers();
      final userKey = username.toLowerCase();
      
      Map<String, dynamic>? userData;
      String? storedHashedPassword;
      String? userId;
      String? originalUsername;
      
      if (users.containsKey(userKey)) {
        // Found in local storage
        userData = users[userKey];
        if (userData != null) {
          storedHashedPassword = userData['hashedPassword'] as String?;
          userId = userData['userId'] as String?;
          originalUsername = userData['username'] as String?;
          print("SimpleAuth: Found user credentials in LOCAL STORAGE");
        }
      } else {
        // STEP 2: Fallback to Firestore if not found locally
        print("SimpleAuth: User not found locally, checking FIRESTORE BACKUP...");
        try {
          final querySnapshot = await _firestore
              .collection('users')
              .where('username', isEqualTo: username)
              .limit(1)
              .get()
              .timeout(const Duration(seconds: 10));
          
          if (querySnapshot.docs.isNotEmpty) {
            final doc = querySnapshot.docs.first;
            final firestoreData = doc.data();
            
            if (firestoreData.containsKey('hashedPassword')) {
              // Found credentials in Firestore
              storedHashedPassword = firestoreData['hashedPassword'];
              userId = doc.id;
              originalUsername = firestoreData['username'];
              
              // Restore to local storage for future use
              users[userKey] = {
                'userId': userId,
                'username': originalUsername,
                'hashedPassword': storedHashedPassword,
                'createdAt': firestoreData['createdAt']?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
                'isWaiting': firestoreData['isWaiting'] ?? false,
                'isInConversation': firestoreData['isInConversation'] ?? false,
                'momStage': firestoreData['momStage'],
                'questionSet1': firestoreData['questionSet1'],
                'questionSet2': firestoreData['questionSet2'],
              };
              await _saveUsers(users);
              print("SimpleAuth: Restored user credentials from FIRESTORE BACKUP to local storage");
            }
          }
        } catch (e) {
          print("SimpleAuth: Error checking Firestore backup: $e");
        }
        
        if (storedHashedPassword == null) {
          return SignInResult(success: false, message: "Username not found. Did you create an account with this username?");
        }
      }

      // Verify password
      final hashedInputPassword = _hashPassword(password);
      if (storedHashedPassword != hashedInputPassword) {
        return SignInResult(success: false, message: "Incorrect password");
      }

      // Sign in successful
      _currentUserId = userId;
      _currentUsername = originalUsername; // Use original case
      _isAuthenticated = true;

      // Ensure Firestore document exists with password backup (for users who signed up before this fix)
      try {
        final userDoc = await _firestore.collection('users').doc(_currentUserId).get();
        if (!userDoc.exists) {
          print("SimpleAuth: Creating missing Firestore document for existing user");
          await _createFirestoreUser(_currentUserId!, _currentUsername!, storedHashedPassword);
        } else {
          // Check if existing document needs password backup
          final userData = userDoc.data() as Map<String, dynamic>?;
          if (userData != null && !userData.containsKey('hashedPassword')) {
            print("SimpleAuth: Adding password backup to existing Firestore document");
            await _firestore.collection('users').doc(_currentUserId).update({
              'hashedPassword': storedHashedPassword,
            });
          }
        }
      } catch (e) {
        print("SimpleAuth: Error checking/creating Firestore document: $e");
      }

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

  /// Check if user has completed onboarding (local storage first, Firebase fallback)
  Future<bool> hasCompletedOnboarding() async {
    if (!_isAuthenticated || _currentUserId == null) {
      return false;
    }

    try {
      // STEP 1: Check local storage first
      try {
        final users = await _getStoredUsers();
        final userKey = _currentUsername?.toLowerCase();
        
        if (userKey != null && users.containsKey(userKey)) {
          final localUserData = users[userKey];
          if (_hasOnboardingData(localUserData)) {
            print("SimpleAuth: Checked onboarding status from LOCAL STORAGE");
            return true;
          }
        }
      } catch (e) {
        print("SimpleAuth: Error checking local storage for onboarding, falling back to Firebase: $e");
      }

      // STEP 2: Fallback to Firebase
      print("SimpleAuth: Checking onboarding status from FIREBASE FALLBACK");
      final userDoc = await _firestore.collection('users').doc(_currentUserId).get();
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        if (_hasOnboardingData(userData)) {
          print("SimpleAuth: Checked onboarding status from FIREBASE FALLBACK");
          return true;
        }
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
      final prefs = await _prefs();
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
      final prefs = await _prefs();
      await prefs.setString(_usersKey, jsonEncode(users));
    } catch (e) {
      print("SimpleAuth: Error saving users: $e");
    }
  }

  String _generateUserId() {
    return 'user_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (9999 - 1000) * (DateTime.now().microsecond / 1000000)).round()}';
  }

  String _hashPassword(String password) {
    // Temporarily storing plain password for testing
    return password;
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

  Future<void> _createFirestoreUser(String userId, String username, [String? hashedPassword]) async {
    try {
      final savedLanguage = await _getLanguagePreference();

      final userData = {
        'username': username,
        'isInConversation': false,
        'lastStatusUpdate': FieldValue.serverTimestamp(),
        'authMethod': 'simple',
        'createdAt': FieldValue.serverTimestamp(),
        'isWaiting': false,
        'momStage': null,
        'questionSet1': null,
        'questionSet2': null,
        'language': savedLanguage,
      };
      
      if (hashedPassword != null) {
        userData['hashedPassword'] = hashedPassword;
      }
      
      await _safeFirestoreOperation(
        operation: () => _firestore.collection('users').doc(userId).set(userData, SetOptions(merge: true)),
        operationName: 'Create Firestore user',
      );
      print("SimpleAuth: User document created successfully in Firestore");
    } catch (e) {
      print("SimpleAuth: Error creating user in Firestore: $e");
    }
  }

  // Additional methods needed by other viewmodels

  /// Get current user ID for database operations
  String getUserId() {
    return _currentUserId ?? "no_user";
  }

  /// Save user data (local storage first, Firebase backup)
  Future<bool> saveUserData(String field, dynamic value) async {
    try {
      if (!_isAuthenticated || _currentUserId == null) {
        print("SimpleAuth: Cannot save data - user not authenticated");
        return false;
      }

      // STEP 1: Save to local storage first (primary)
      try {
        final users = await _getStoredUsers();
        final userKey = _currentUsername?.toLowerCase();
        
        if (userKey != null && users.containsKey(userKey)) {
          users[userKey][field] = value;
          users[userKey]['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
          await _saveUsers(users);
          print("SimpleAuth: Successfully saved $field to LOCAL STORAGE");
        }
      } catch (e) {
        print("SimpleAuth: Error saving to local storage: $e");
      }

      // STEP 2: Save to Firebase as backup (secondary)
      await _safeFirestoreOperation(
        operation: () => _firestore.collection('users').doc(_currentUserId).set({
          field: value,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)),
        operationName: 'Save user data to Firebase',
      );
      
      print("SimpleAuth: Successfully saved $field to FIREBASE BACKUP");
      return true;
    } catch (e) {
      print("SimpleAuth: Error in saveUserData: $e");
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

  /// Get user data (local storage first, Firebase fallback)
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      if (!_isAuthenticated || _currentUserId == null) {
        print("SimpleAuth: Cannot get data - user not authenticated");
        return null;
      }

      // STEP 1: Try to get data from local storage first
      try {
        final users = await _getStoredUsers();
        final userKey = _currentUsername?.toLowerCase();
        
        if (userKey != null && users.containsKey(userKey)) {
          final localUserData = users[userKey];
          
          if (_hasOnboardingData(localUserData)) {
            print("SimpleAuth: Retrieved user data from LOCAL STORAGE for $_currentUserId");
            
            return {
              'username': localUserData['username'],
              'momStage': localUserData['momStage'],
              'questionSet1': localUserData['questionSet1'],
              'questionSet2': localUserData['questionSet2'],
              'questionSet3': localUserData['questionSet3'],
              'authMethod': 'simple',
              'isInConversation': false,
              'isWaiting': false,
            };
          }
        }
      } catch (e) {
        print("SimpleAuth: Error reading local storage, falling back to Firebase: $e");
      }

      // STEP 2: Fallback to Firebase
      print("SimpleAuth: Local storage incomplete, checking Firebase as fallback...");
      
      final doc = await _safeFirestoreOperation(
        operation: () => _firestore.collection('users').doc(_currentUserId).get(),
        operationName: 'Get user data from Firebase',
        throwError: true,
      );
      
      if (doc?.exists ?? false) {
        final data = doc!.data() as Map<String, dynamic>;
        print("SimpleAuth: Retrieved user data from FIREBASE FALLBACK for $_currentUserId");
        return data;
      }
      
      print("SimpleAuth: No user data found in local storage OR Firebase for $_currentUserId");
      return null;
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

  // === Small shared helpers ==================================================

  // SharedPreferences shortcut with single instantiation site
  Future<SharedPreferences> _prefs() async => await SharedPreferences.getInstance();

  // Consistent onboarding-data completeness check used in multiple callers
  bool _hasOnboardingData(Map<String, dynamic> data) {
    return data['momStage'] != null &&
        (data['questionSet1'] != null ||
         data['questionSet2'] != null ||
         data['questionSet3'] != null);
  }

  // === Private Firebase Helpers ===
  Future<T?> _safeFirestoreOperation<T>({
    required Future<T> Function() operation,
    String operationName = 'Firestore operation',
    bool throwError = false,
  }) async {
    try {
      return await operation().timeout(
        _firestoreTimeout,
        onTimeout: () {
          print("SimpleAuth: $operationName timed out");
          throw TimeoutException('$operationName timed out', _firestoreTimeout);
        },
      );
    } catch (e) {
      print("SimpleAuth: Error in $operationName: $e");
      if (throwError) rethrow;
      return null;
    }
  }

  Future<String?> _getLanguagePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('pref_language');
    } catch (_) {
      return null;
    }
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