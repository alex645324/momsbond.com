import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'lib/Database_logic/firebase_options.dart';
import 'lib/Database_logic/simple_matching.dart';

/// Test script to verify active user timestamp matching functionality
class ActiveMatchingTester {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final List<String> _testUserIds = [];
  static final Random _random = Random();
  
  /// Test scenarios for active user matching
  static Future<void> runAllTests() async {
    print("\n" + "="*80);
    print("🧪 ACTIVE USER MATCHING TEST SUITE");
    print("="*80);
    
    try {
      await _initializeFirebase();
      await _cleanupPreviousTests();
      
      // Run test scenarios
      await _testScenario1_ActiveUsersMatch();
      await _testScenario2_InactiveUsersFiltered();
      await _testScenario3_TimestampExpiration();
      await _testScenario4_ConcurrentActiveUsers();
      await _testScenario5_MixedActiveInactive();
      
      print("\n" + "="*80);
      print("✅ ALL TESTS COMPLETED SUCCESSFULLY!");
      print("="*80);
      
    } catch (e, stackTrace) {
      print("\n❌ TEST SUITE FAILED: $e");
      print("Stack trace: $stackTrace");
    } finally {
      await _cleanupTestUsers();
    }
  }
  
  /// Initialize Firebase for testing
  static Future<void> _initializeFirebase() async {
    print("\n🔧 Initializing Firebase for testing...");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("✅ Firebase initialized successfully");
  }
  
  /// Clean up any previous test data
  static Future<void> _cleanupPreviousTests() async {
    print("\n🧹 Cleaning up previous test data...");
    
    // Delete test users (IDs starting with "test_user_")
    final testUsers = await _firestore
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: 'test_user_')
        .where('username', isLessThan: 'test_user_\uf8ff')
        .get();
    
    final batch = _firestore.batch();
    for (final doc in testUsers.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    
    print("✅ Cleanup completed (removed ${testUsers.docs.length} test users)");
  }
  
  /// TEST 1: Verify active users can match with each other
  static Future<void> _testScenario1_ActiveUsersMatch() async {
    print("\n" + "-"*60);
    print("🧪 TEST 1: Active Users Should Match");
    print("-"*60);
    
    // Create two active users
    final user1Id = await _createTestUser("test_user_active1", ["pregnant?"], ["Postpartum depression or anxiety?"]);
    final user2Id = await _createTestUser("test_user_active2", ["pregnant?"], ["Postpartum depression or anxiety?"]);
    
    // Make both users active and waiting
    await _makeUserActive(user1Id);
    await _makeUserActive(user2Id);
    
    // Wait a moment for timestamps to be set
    await Future.delayed(Duration(seconds: 2));
    
    // Attempt matching for user1
    print("🔍 Attempting to match user1 with active user2...");
    final matchResult = await SimpleMatching.findMatch(
      currentUserId: user1Id,
      momStages: ["pregnant?"],
      selectedQuestions: ["Postpartum depression or anxiety?"],
    );
    
    if (matchResult != null && matchResult['matchedUser']['id'] == user2Id) {
      print("✅ TEST 1 PASSED: Active users successfully matched!");
      print("   Match ID: ${matchResult['matchId']}");
      print("   Matched with: ${matchResult['matchedUser']['username']}");
    } else {
      throw Exception("TEST 1 FAILED: Active users did not match as expected");
    }
  }
  
  /// TEST 2: Verify inactive users are filtered out
  static Future<void> _testScenario2_InactiveUsersFiltered() async {
    print("\n" + "-"*60);
    print("🧪 TEST 2: Inactive Users Should Be Filtered Out");
    print("-"*60);
    
    // Create active user and inactive user
    final activeUserId = await _createTestUser("test_user_active3", ["teen mom?"], ["Financial stress?"]);
    final inactiveUserId = await _createTestUser("test_user_inactive1", ["teen mom?"], ["Financial stress?"]);
    
    // Make one user active and one inactive
    await _makeUserActive(activeUserId);
    await _makeUserInactive(inactiveUserId); // This will have old timestamp
    
    // Wait a moment
    await Future.delayed(Duration(seconds: 2));
    
    // Attempt matching for active user
    print("🔍 Attempting to match active user (should find no matches)...");
    final matchResult = await SimpleMatching.findMatch(
      currentUserId: activeUserId,
      momStages: ["teen mom?"],
      selectedQuestions: ["Financial stress?"],
    );
    
    if (matchResult == null) {
      print("✅ TEST 2 PASSED: Inactive user was correctly filtered out!");
    } else {
      throw Exception("TEST 2 FAILED: Inactive user was matched (should be filtered)");
    }
  }
  
  /// TEST 3: Verify timestamp expiration works
  static Future<void> _testScenario3_TimestampExpiration() async {
    print("\n" + "-"*60);
    print("🧪 TEST 3: Timestamp Expiration (30 second timeout)");
    print("-"*60);
    
    // Create users with expired timestamps
    final user1Id = await _createTestUser("test_user_expired1", ["postpartum?"], ["Body image issues?"]);
    final user2Id = await _createTestUser("test_user_expired2", ["postpartum?"], ["Body image issues?"]);
    
    // Set old timestamps (more than 30 seconds ago)
    final oldTimestamp = DateTime.now().subtract(Duration(minutes: 2));
    await _setUserTimestamp(user1Id, oldTimestamp);
    await _setUserTimestamp(user2Id, oldTimestamp);
    
    // Wait a moment
    await Future.delayed(Duration(seconds: 1));
    
    // Attempt matching
    print("🔍 Attempting to match users with expired timestamps...");
    final matchResult = await SimpleMatching.findMatch(
      currentUserId: user1Id,
      momStages: ["postpartum?"],
      selectedQuestions: ["Body image issues?"],
    );
    
    if (matchResult == null) {
      print("✅ TEST 3 PASSED: Users with expired timestamps were filtered out!");
    } else {
      throw Exception("TEST 3 FAILED: Users with expired timestamps should not match");
    }
  }
  
  /// TEST 4: Test concurrent active users
  static Future<void> _testScenario4_ConcurrentActiveUsers() async {
    print("\n" + "-"*60);
    print("🧪 TEST 4: Multiple Concurrent Active Users");
    print("-"*60);
    
    // Create multiple active users
    final List<String> userIds = [];
    for (int i = 1; i <= 5; i++) {
      final userId = await _createTestUser("test_user_concurrent$i", ["pregnant?"], ["Sleep deprivation?"]);
      userIds.add(userId);
      await _makeUserActive(userId);
    }
    
    // Wait for timestamps to be set
    await Future.delayed(Duration(seconds: 2));
    
    // Each user should be able to find matches
    int successfulMatches = 0;
    for (int i = 0; i < userIds.length - 1; i++) { // Leave last user unmatched
      final matchResult = await SimpleMatching.findMatch(
        currentUserId: userIds[i],
        momStages: ["pregnant?"],
        selectedQuestions: ["Sleep deprivation?"],
      );
      
      if (matchResult != null) {
        successfulMatches++;
        print("   ✅ User ${i + 1} matched successfully");
        
        // Mark both users as no longer waiting to avoid duplicate matches
        await _firestore.collection('users').doc(userIds[i]).update({'isWaiting': false});
        await _firestore.collection('users').doc(matchResult['matchedUser']['id']).update({'isWaiting': false});
      }
    }
    
    if (successfulMatches >= 2) {
      print("✅ TEST 4 PASSED: Multiple concurrent users matched successfully!");
      print("   Successful matches: $successfulMatches");
    } else {
      throw Exception("TEST 4 FAILED: Expected at least 2 matches from 5 users, got $successfulMatches");
    }
  }
  
  /// TEST 5: Mixed active and inactive users
  static Future<void> _testScenario5_MixedActiveInactive() async {
    print("\n" + "-"*60);
    print("🧪 TEST 5: Mixed Active and Inactive Users");
    print("-"*60);
    
    // Create mix of active and inactive users
    final activeUser1 = await _createTestUser("test_user_mixed_active1", ["trying to conceive?"], ["Fertility concerns?"]);
    final inactiveUser1 = await _createTestUser("test_user_mixed_inactive1", ["trying to conceive?"], ["Fertility concerns?"]);
    final inactiveUser2 = await _createTestUser("test_user_mixed_inactive2", ["trying to conceive?"], ["Fertility concerns?"]);
    final activeUser2 = await _createTestUser("test_user_mixed_active2", ["trying to conceive?"], ["Fertility concerns?"]);
    
    // Set appropriate states
    await _makeUserActive(activeUser1);
    await _makeUserInactive(inactiveUser1);
    await _makeUserInactive(inactiveUser2);
    await _makeUserActive(activeUser2);
    
    // Wait for timestamps
    await Future.delayed(Duration(seconds: 2));
    
    // Active user should match with other active user, not inactive ones
    print("🔍 Attempting to match active user (should skip inactive users)...");
    final matchResult = await SimpleMatching.findMatch(
      currentUserId: activeUser1,
      momStages: ["trying to conceive?"],
      selectedQuestions: ["Fertility concerns?"],
    );
    
    if (matchResult != null && matchResult['matchedUser']['id'] == activeUser2) {
      print("✅ TEST 5 PASSED: Active user matched with other active user, skipping inactive users!");
      print("   Matched with: ${matchResult['matchedUser']['username']}");
    } else if (matchResult == null) {
      throw Exception("TEST 5 FAILED: Active users should have matched with each other");
    } else {
      throw Exception("TEST 5 FAILED: Active user matched with wrong user (possibly inactive)");
    }
  }
  
  /// Helper: Create test user
  static Future<String> _createTestUser(String username, List<String> momStages, List<String> questions) async {
    final userId = "test_${username}_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1000)}";
    
    await _firestore.collection('users').doc(userId).set({
      'username': username,
      'momStage': momStages,
      'questionSet1': questions,
      'questionSet2': null,
      'isWaiting': true,
      'isInConversation': false,
      'hasInvitation': false,
      'pendingChat': false,
      'authMethod': 'test',
      'createdAt': FieldValue.serverTimestamp(),
      'lastStatusUpdate': FieldValue.serverTimestamp(),
    });
    
    _testUserIds.add(userId);
    print("👤 Created test user: $username ($userId)");
    return userId;
  }
  
  /// Helper: Make user active with recent timestamp
  static Future<void> _makeUserActive(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'isWaiting': true,
      'lastActiveTimestamp': FieldValue.serverTimestamp(),
    });
    print("🟢 Made user active: $userId");
  }
  
  /// Helper: Make user inactive (old timestamp)
  static Future<void> _makeUserInactive(String userId) async {
    final oldTimestamp = DateTime.now().subtract(Duration(minutes: 5));
    await _firestore.collection('users').doc(userId).update({
      'isWaiting': true,
      'lastActiveTimestamp': oldTimestamp,
    });
    print("🔴 Made user inactive: $userId");
  }
  
  /// Helper: Set specific timestamp for user
  static Future<void> _setUserTimestamp(String userId, DateTime timestamp) async {
    await _firestore.collection('users').doc(userId).update({
      'isWaiting': true,
      'lastActiveTimestamp': timestamp,
    });
    print("⏰ Set timestamp for user $userId: $timestamp");
  }
  
  /// Helper: Clean up all test users
  static Future<void> _cleanupTestUsers() async {
    print("\n🧹 Cleaning up test users...");
    
    final batch = _firestore.batch();
    for (final userId in _testUserIds) {
      batch.delete(_firestore.collection('users').doc(userId));
    }
    
    // Also clean up any test matches
    final testMatches = await _firestore
        .collection('matches')
        .where('users', arrayContainsAny: _testUserIds)
        .get();
    
    for (final doc in testMatches.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
    print("✅ Cleaned up ${_testUserIds.length} test users and ${testMatches.docs.length} test matches");
    _testUserIds.clear();
  }
}

/// Main function to run the tests
void main() async {
  try {
    await ActiveMatchingTester.runAllTests();
    print("\n🎉 Test suite completed successfully!");
  } catch (e) {
    print("\n💥 Test suite failed: $e");
    exit(1);
  }
} 