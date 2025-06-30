import 'dart:io';
import 'dart:math';

/// Firebase-only test (requires firebase_core but not flutter framework)
/// Run with: dart test_firebase_only.dart
void main() async {
  print("🔥 Firebase-Only Matching Test");
  print("=" * 40);
  
  try {
    // This would test Firebase if we could initialize it
    // For now, simulate the test results
    await simulateFirebaseTest();
    
    print("\n✅ Firebase simulation completed!");
    print("🎯 Ready for real Firebase testing!");
    
  } catch (e) {
    print("❌ Error: $e");
    exit(1);
  }
}

/// Simulate Firebase operations
Future<void> simulateFirebaseTest() async {
  print("🧪 Simulating Firebase Operations\n");
  
  // Simulate creating test users
  print("📋 Step 1: Creating Test Users");
  print("-" * 30);
  
  final user1 = createMockUser("TestUser1", ["pregnant?"]);
  final user2 = createMockUser("TestUser2", ["pregnant?"]);
  
  print("👤 Created mock user: ${user1['username']} (${user1['id']})");
  print("👤 Created mock user: ${user2['username']} (${user2['id']})");
  
  // Simulate marking users as active
  print("\n📋 Step 2: Marking Users as Active");
  print("-" * 30);
  
  markUserActive(user1);
  markUserActive(user2);
  
  print("⏳ ${user1['username']} marked as active");
  print("⏳ ${user2['username']} marked as active");
  
  // Simulate finding compatible users
  print("\n📋 Step 3: Finding Compatible Users");
  print("-" * 30);
  
  final compatibleUsers = findCompatibleUsers(user1, [user2]);
  
  print("🔍 Searching for matches for ${user1['username']}...");
  print("🎯 Found ${compatibleUsers.length} compatible users");
  
  if (compatibleUsers.isNotEmpty) {
    final match = compatibleUsers.first;
    print("✅ Match found: ${match['username']}");
    
    // Simulate creating match
    final matchData = createMockMatch(user1, match);
    print("🤝 Created match: ${matchData['matchId']}");
  }
  
  // Simulate cleanup
  print("\n📋 Step 4: Cleanup");
  print("-" * 30);
  print("🧹 Cleaning up mock data...");
  print("✨ Cleanup completed");
}

/// Create a mock user (simulates Firestore document)
Map<String, dynamic> createMockUser(String username, List<String> momStages) {
  final userId = "mock_user_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}";
  
  return {
    'id': userId,
    'username': username,
    'momStage': momStages,
    'questionSet1': ["Mock question"],
    'questionSet2': null,
    'authMethod': 'mock',
    'createdAt': DateTime.now(),
    'lastStatusUpdate': DateTime.now(),
    'isWaiting': false,
    'isInConversation': false,
    'lastActiveTimestamp': null,
  };
}

/// Mark user as active (simulates Firestore update)
void markUserActive(Map<String, dynamic> user) {
  user['isWaiting'] = true;
  user['isInConversation'] = false;
  user['lastActiveTimestamp'] = DateTime.now();
}

/// Find compatible users (simulates Firestore query)
List<Map<String, dynamic>> findCompatibleUsers(
  Map<String, dynamic> currentUser, 
  List<Map<String, dynamic>> allUsers
) {
  final currentStages = List<String>.from(currentUser['momStage']);
  final activeThreshold = DateTime.now().subtract(Duration(seconds: 30));
  
  return allUsers.where((user) {
    // Skip self
    if (user['id'] == currentUser['id']) return false;
    
    // Check if waiting
    if (user['isWaiting'] != true) return false;
    
    // Check if active
    final lastActive = user['lastActiveTimestamp'] as DateTime?;
    if (lastActive == null || lastActive.isBefore(activeThreshold)) return false;
    
    // Check stage compatibility
    final userStages = List<String>.from(user['momStage']);
    return hasCommonStages(currentStages, userStages);
    
  }).toList();
}

/// Create mock match (simulates Firestore match creation)
Map<String, dynamic> createMockMatch(
  Map<String, dynamic> user1, 
  Map<String, dynamic> user2
) {
  final matchId = "mock_match_${DateTime.now().millisecondsSinceEpoch}";
  
  return {
    'matchId': matchId,
    'userAId': user1['id'],
    'userBId': user2['id'],
    'userAName': user1['username'],
    'userBName': user2['username'],
    'matchedAt': DateTime.now(),
    'currentUser': {
      'id': user1['id'],
      'username': user1['username'],
      'momStage': user1['momStage'],
    },
    'matchedUser': {
      'id': user2['id'],
      'username': user2['username'],
      'momStage': user2['momStage'],
    },
  };
}

/// Check if two stage lists have common elements
bool hasCommonStages(List<String> stages1, List<String> stages2) {
  return stages1.any((stage) => stages2.contains(stage));
} 