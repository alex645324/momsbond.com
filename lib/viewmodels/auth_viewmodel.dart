import 'package:flutter/material.dart';
import '../Database_logic/simple_auth_manager.dart';
import '../models/auth_model.dart';

class AuthViewModel extends ChangeNotifier {
  final SimpleAuthManager _authManager = SimpleAuthManager();
  AuthModel _authModel = const AuthModel();

  AuthModel get authModel => _authModel;
  bool get isLoading => _authModel.isLoading;
  String? get errorMessage => _authModel.errorMessage;
  bool get isAuthenticated => _authModel.isAuthenticated;
  String? get currentUsername => _authManager.currentUsername;

  void _updateState(AuthModel newModel) {
    _authModel = newModel;
    notifyListeners();
  }

  /// Initialize the authentication system
  Future<void> initialize() async {
    print("\n" + "="*50);
    print("AuthViewModel: Initializing simple auth - ${DateTime.now()}");
    print("="*50);

    _updateState(_authModel.copyWith(isLoading: true, errorMessage: null));

    try {
      await _authManager.initialize();
      
      if (_authManager.isAuthenticated) {
        print("AuthViewModel: User already authenticated: ${_authManager.currentUsername}");
        
        // Check if user has completed onboarding
        final hasCompletedOnboarding = await _authManager.hasCompletedOnboarding();
        
        _updateState(_authModel.copyWith(
          userId: _authManager.currentUserId,
          isLoading: false,
          hasCompletedOnboarding: hasCompletedOnboarding,
        ));
        
        print("AuthViewModel: Updated state - hasCompletedOnboarding: $hasCompletedOnboarding");
      } else {
        print("AuthViewModel: No authenticated user found");
        _updateState(_authModel.copyWith(
          isLoading: false,
        ));
      }
    } catch (e) {
      print("AuthViewModel: Error during initialization: $e");
      _updateState(_authModel.copyWith(
        isLoading: false,
        errorMessage: "Error initializing authentication: $e",
      ));
    }
    
    print("="*50 + "\n");
  }

  /// Check current authentication status
  Future<void> checkAuthStatus() async {
    try {
      if (_authManager.isAuthenticated) {
        final hasCompletedOnboarding = await _authManager.hasCompletedOnboarding();
        
        _updateState(_authModel.copyWith(
          userId: _authManager.currentUserId,
          hasCompletedOnboarding: hasCompletedOnboarding,
        ));
      }
    } catch (e) {
      print("AuthViewModel: Error checking auth status: $e");
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    print("AuthViewModel: Signing out user");
    
    try {
      await _authManager.signOut();
      
      _updateState(_authModel.copyWith(
        userId: null,
        hasCompletedOnboarding: false,
      ));
      
      print("AuthViewModel: User signed out successfully");
    } catch (e) {
      print("AuthViewModel: Error during sign out: $e");
      _updateState(_authModel.copyWith(
        errorMessage: "Error signing out: $e",
      ));
    }
  }

  /// Clear any error messages
  void clearError() {
    if (_authModel.hasError) {
      _updateState(_authModel.copyWith(errorMessage: null));
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

  /// Get current user ID for database operations
  String? getCurrentUserId() {
    return _authManager.currentUserId;
  }

  /// Get remembered username (for login form pre-filling)
  Future<String?> getRememberedUsername() async {
    return await _authManager.getRememberedUsername();
  }
} 