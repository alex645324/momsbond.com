import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mvp_code/Database_logic/firebase_options.dart';
import 'package:mvp_code/models/messages_model.dart';
import 'package:mvp_code/viewmodels/messages_viewmodel.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

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
    return null; // ignore Firestore calls in unit tests
  });

  addTearDown(() async {
    coreChannel.setMockMethodCallHandler(null);
    firestoreChannel.setMockMethodCallHandler(null);
  });

  // Initialize Firebase once for this test file
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  group('Starter text generation (FAST)', () {
    final vm = MessagesViewModel();

    test('Shared topic is used when overlap exists', () {
      final current = CurrentUserData(selectedQuestions: ['A', 'B']);
      final matched = MatchedUserData(selectedQuestions: ['B', 'C']);

      final text = vm.computeStarterText(current, matched);

      expect(text, contains('"B"'));
    });

    test('Current user first topic used when no overlap', () {
      final current = CurrentUserData(selectedQuestions: ['D']);
      final matched = MatchedUserData(selectedQuestions: ['E']);

      final text = vm.computeStarterText(current, matched);

      expect(text, contains('"D"'));
    });

    test('Matched user topic used when current user has none', () {
      final current = CurrentUserData(selectedQuestions: []);
      final matched = MatchedUserData(selectedQuestions: ['F']);

      final text = vm.computeStarterText(current, matched);

      expect(text, contains('"F"'));
    });

    test('Default fallback used when both have no topics', () {
      final current = CurrentUserData(selectedQuestions: []);
      final matched = MatchedUserData(selectedQuestions: []);

      final text = vm.computeStarterText(current, matched);

      expect(text, contains('connecting with other moms'));
    });
  });
} 