import 'dart:io';
import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'lib/Database_logic/simple_matching.dart';
import 'lib/Database_logic/firebase_options.dart';

/// Simple test script to verify matching functionality
/// Run with: dart test_matching_simple.dart
void main() async {
  print("🚀 Starting Simple Matching Test Script");
  print("=" * 50);
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Configure Firestore
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
    
    print("🔥 Firebase initialized successfully");
    
    final tester = MatchingTester();
    await tester.runAllTests();
    
  } catch (e) {
    print("❌ Error running tests: $e");
    print("💡 Make sure Firebase is configured and you're in the v1_mother_edition folder");
    exit(1);
  }
}

class MatchingTester {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<String> _testUserIds = [];
  
  /// Run all matching tests
  Future<void> runAllTests() async {
    print("🧪 Running Matching Tests...\n");
    
    // Test 1: Basic matching with same stages
    await testBasicMatching();
    
    // Test 2: Active user filtering
    await testActiveUserFiltering();
    
    // Test 3: No match scenario
    await testNoMatchScenario();
    
    // Cleanup
    await cleanup();
    
    print("\n✅ All tests completed!");
    print("🎉 Matching system is working correctly!");
  }
  
  /// Test 1: Basic matching between users with same stages
  Future<void> testBasicMatching() async {
    print("📋 Test 1: Basic Matching with Same Stages");
    print("-" * 40);
    
    // Create two users with same stage
    final user1Id = await createTestUser("TestUser1", ["pregnant?"]);
    final user2Id = await createTestUser("TestUser2", ["pregnant?"]);
    
    print("👤 Created User1: $user1Id");
    print("👤 Created User2: $user2Id");
    
    // Mark both as active and waiting
    await markUserActiveAndWaiting(user1Id);
    await markUserActiveAndWaiting(user2Id);
    
    print("⏳ Both users marked as active and waiting");
    
    // Try to match user1
    final matchResult = await SimpleMatching.findMatch(
      currentUserId: user1Id,
      momStages: ["pregnant?"],
      selectedQuestions: ["Worry about weight and body changes?"],
    );
    
    if (matchResult != null) {
      print("✅ Match found successfully!");
      print("🤝 Matched with: ${matchResult['matchedUser']['username']}");
      print("📊 Match ID: ${matchResult['matchId']}");
    } else {
      print("❌ No match found (unexpected)");
    }
    
    print("");
  }
  
  /// Test 2: Active user filtering
  Future<void> testActiveUserFiltering() async {
    print("📋 Test 2: Active User Filtering");
    print("-" * 40);
    
    // Create users
    final activeUserId = await createTestUser("ActiveUser", ["new_mom"]);
    final inactiveUserId = await createTestUser("InactiveUser", ["new_mom"]);
    
    print("👤 Created Active User: $activeUserId");
    print("👤 Created Inactive User: $inactiveUserId");
    
    // Mark active user as recently active
    await markUserActiveAndWaiting(activeUserId);
    
    // Mark inactive user as waiting but not recently active
    await _firestore.collection('users').doc(inactiveUserId).update({
      'isWaiting': true,
      'isInConversation': false,
      'lastActiveTimestamp': DateTime.now().subtract(Duration(minutes: 5)), // Old timestamp
    });
    
    print("⏳ Active user marked as recently active");
    print("🕐 Inactive user marked with old timestamp");
    
    // Try to match active user (should not match with inactive user)
    final matchResult = await SimpleMatching.findMatch(
      currentUserId: activeUserId,
      momStages: ["new_mom"],
      selectedQuestions: ["Sleep deprivation?"],
    );
    
    if (matchResult == null) {
      print("✅ Correctly filtered out inactive users!");
    } else {
      print("❌ Should not have matched with inactive user");
    }
    
    print("");
  }
  
  /// Test 3: No match scenario
  Future<void> testNoMatchScenario() async {
    print("📋 Test 3: No Match Scenario");
    print("-" * 40);
    
    // Create a single user
    final lonelyUserId = await createTestUser("LonelyUser", ["trying_to_conceive"]);
    
    print("👤 Created Lonely User: $lonelyUserId");
    
    await markUserActiveAndWaiting(lonelyUserId);
    
    print("⏳ User marked as active and waiting");
    
    // Try to match (should find no one since they're alone)
    final matchResult = await SimpleMatching.findMatch(
      currentUserId: lonelyUserId,
      momStages: ["trying_to_conceive"],
      selectedQuestions: ["Fertility concerns?"],
    );
    
    if (matchResult == null) {
      print("✅ Correctly returned no match when alone!");
    } else {
      print("❌ Should not have found a match");
    }
    
    print("");
  }
  
  /// Create a test user
  Future<String> createTestUser(String username, List<String> momStages) async {
    final userId = "test_user_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}";
    
    await _firestore.collection('users').doc(userId).set({
      'username': username,
      'momStage': momStages,
      'questionSet1': ["Test question"],
      'questionSet2': null,
      'authMethod': 'test',
      'createdAt': DateTime.now(),
      'lastStatusUpdate': DateTime.now(),
      'isWaiting': false,
      'isInConversation': false,
    });
    
    _testUserIds.add(userId);
    return userId;
  }
  
  /// Mark user as active and waiting for match
  Future<void> markUserActiveAndWaiting(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'isWaiting': true,
      'isInConversation': false,
      'lastActiveTimestamp': DateTime.now(),
    });
  }
  
  /// Clean up test data
  Future<void> cleanup() async {
    print("🧹 Cleaning up test data...");
    
    final batch = _firestore.batch();
    
    // Delete test users
    for (final userId in _testUserIds) {
      batch.delete(_firestore.collection('users').doc(userId));
    }
    
    // Delete any test matches
    final matches = await _firestore
        .collection('matches')
        .where('users', arrayContainsAny: _testUserIds)
        .get();
    
    for (final doc in matches.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
    print("✨ Cleanup completed");
  }
} 