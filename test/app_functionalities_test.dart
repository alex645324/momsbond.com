import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mvp_code/Database_logic/firebase_options.dart';
import 'package:mvp_code/Database_logic/simple_auth_manager.dart';
import 'package:mvp_code/viewmodels/dashboard_viewmodel.dart';
import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MotherApp core flow', () {
    late SimpleAuthManager authManager;

    setUpAll(() async {
      // Mock Firebase Core & Firestore channels
      const MethodChannel coreChannel = MethodChannel('plugins.flutter.io/firebase_core');
      coreChannel.setMockMethodCallHandler((MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'initializeCore':
            return [
              {
                'name': '[DEFAULT]',
                'options': {
                  'apiKey': 'fake',
                  'appId': 'fake',
                  'messagingSenderId': 'fake',
                  'projectId': 'fake'
                },
                'pluginConstants': {},
              }
            ];
          case 'initializeApp':
            return {
              'name': methodCall.arguments['appName'] ?? '[DEFAULT]',
              'options': methodCall.arguments['options'],
              'pluginConstants': {},
            };
        }
        return null;
      });

      const MethodChannel firestoreChannel = MethodChannel('plugins.flutter.io/firebase_firestore');
      firestoreChannel.setMockMethodCallHandler((methodCall) async {
        return null;
      });

      addTearDown(() async {
        coreChannel.setMockMethodCallHandler(null);
        firestoreChannel.setMockMethodCallHandler(null);
      });

      // Initialize Firebase for integration-style tests
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      authManager = SimpleAuthManager();
      await authManager.initialize();
    });

    test('sign-up, onboarding flag, sign-in, dashboard init', () async {
      final username = 'testuser_${DateTime.now().millisecondsSinceEpoch}';
      const password = 'test123';

      // Sign-up
      final signUpResult = await authManager.signUp(
        username: username,
        password: password,
      );
      expect(signUpResult.success, isTrue, reason: 'Sign-up should succeed');
      expect(authManager.isAuthenticated, isTrue);

      // Simulate mother-stage completion by saving data directly
      await authManager.saveUserData('momStage', ['pregnancy']);

      // Verify onboarding considered complete
      final completed = await authManager.hasCompletedOnboarding();
      expect(completed, isTrue, reason: 'Onboarding should be complete');

      // Sign-out and sign-in again
      await authManager.signOut();
      final signInRes = await authManager.signIn(
        username: username,
        password: password,
      );
      expect(signInRes.success, isTrue, reason: 'Sign-in should succeed');

      // Initialize dashboard viewmodel (smoke test)
      final dashVM = DashboardViewModel();
      await dashVM.initialize();
      expect(dashVM.isLoading, isFalse);
    });
  });
} 