import 'dart:io';
import 'dart:convert';

/// Ultra-simple test to verify matching logic
/// Run with: dart simple_test.dart
void main() async {
  print("🧪 Ultra-Simple Matching Logic Test");
  print("=" * 40);
  
  try {
    await testMatchingLogic();
    print("\n✅ All tests passed!");
    print("🎉 Matching logic is working correctly!");
  } catch (e) {
    print("❌ Test failed: $e");
    exit(1);
  }
}

/// Test the core matching logic without Firebase
Future<void> testMatchingLogic() async {
  print("📋 Testing Core Matching Logic\n");
  
  // Test 1: Basic stage matching
  print("Test 1: Stage Matching");
  print("-" * 20);
  
  final user1Stages = ["pregnant?"];
  final user2Stages = ["pregnant?"];
  final user3Stages = ["new_mom"];
  
  final match1 = hasCommonStages(user1Stages, user2Stages);
  final match2 = hasCommonStages(user1Stages, user3Stages);
  
  print("👤 User1 stages: $user1Stages");
  print("👤 User2 stages: $user2Stages");
  print("👤 User3 stages: $user3Stages");
  print("🤝 User1 & User2 match: $match1 ${match1 ? '✅' : '❌'}");
  print("🤝 User1 & User3 match: $match2 ${match2 ? '❌' : '✅'}");
  
  if (!match1) throw Exception("Expected User1 & User2 to match");
  if (match2) throw Exception("Expected User1 & User3 NOT to match");
  
  // Test 2: Active user filtering
  print("\nTest 2: Active User Filtering");
  print("-" * 20);
  
  final now = DateTime.now();
  final activeTime = now.subtract(Duration(seconds: 10)); // Recent
  final inactiveTime = now.subtract(Duration(minutes: 5)); // Old
  
  final isActive = isUserActive(activeTime, now);
  final isInactive = isUserActive(inactiveTime, now);
  
  print("⏰ Current time: ${formatTime(now)}");
  print("⏰ Active user time: ${formatTime(activeTime)}");
  print("⏰ Inactive user time: ${formatTime(inactiveTime)}");
  print("🟢 Active user status: $isActive ${isActive ? '✅' : '❌'}");
  print("🔴 Inactive user status: $isInactive ${isInactive ? '❌' : '✅'}");
  
  if (!isActive) throw Exception("Expected recent user to be active");
  if (isInactive) throw Exception("Expected old user to be inactive");
  
  // Test 3: Question extraction
  print("\nTest 3: Question Processing");
  print("-" * 20);
  
  final userData = {
    'questionSet1': ['Question 1', 'Question 2'],
    'questionSet2': ['Question 3'],
    'momStage': ['pregnant?'],
  };
  
  final questions = extractQuestions(userData);
  final stages = extractStages(userData);
  
  print("📊 User data: ${formatUserData(userData)}");
  print("❓ Extracted questions: $questions");
  print("🏃 Extracted stages: $stages");
  
  if (questions.length != 3) throw Exception("Expected 3 questions, got ${questions.length}");
  if (stages.length != 1) throw Exception("Expected 1 stage, got ${stages.length}");
  
  print("\n🎯 All core logic tests passed!");
}

/// Check if two stage lists have common elements
bool hasCommonStages(List<String> stages1, List<String> stages2) {
  return stages1.any((stage) => stages2.contains(stage));
}

/// Check if user is active (within last 30 seconds)
bool isUserActive(DateTime lastActive, DateTime now) {
  final threshold = now.subtract(Duration(seconds: 30));
  return lastActive.isAfter(threshold);
}

/// Extract questions from user data
List<String> extractQuestions(Map<String, dynamic> userData) {
  final questions = <String>[];
  
  final q1 = userData['questionSet1'];
  if (q1 is List) {
    questions.addAll(q1.map((q) => q.toString()));
  }
  
  final q2 = userData['questionSet2'];
  if (q2 is List) {
    questions.addAll(q2.map((q) => q.toString()));
  }
  
  return questions;
}

/// Extract stages from user data
List<String> extractStages(Map<String, dynamic> userData) {
  final stages = userData['momStage'];
  if (stages is List) {
    return stages.map((s) => s.toString()).toList();
  }
  return [];
}

/// Format time for display
String formatTime(DateTime time) {
  return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}";
}

/// Format user data for display
String formatUserData(Map<String, dynamic> data) {
  return json.encode(data);
} 