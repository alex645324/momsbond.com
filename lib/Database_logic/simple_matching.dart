import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

/// Simplified matching system optimized for current needs with future extensibility
class SimpleMatching {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Main matching method - finds a compatible user
  static Future<Map<String, dynamic>?> findMatch({
    required String currentUserId,
    required List<String> momStages,
    List<String>? selectedQuestions, // Optional for future use
  }) async {
    try {
      print("DEBUG: SimpleMatching.findMatch called");
      print("DEBUG: currentUserId: $currentUserId");
      print("DEBUG: momStages: $momStages (type: ${momStages.runtimeType})");
      print("DEBUG: selectedQuestions: $selectedQuestions (type: ${selectedQuestions.runtimeType})");
      
      print("SimpleMatching: Finding match for user $currentUserId with stages: $momStages");
      
      print("DEBUG: About to call _getExcludedUsers");
      // Get previously matched users to exclude
      final excludedUsers = await _getExcludedUsers(currentUserId);
      print("DEBUG: _getExcludedUsers completed");
      
      print("DEBUG: About to call _findCompatibleUser");
      // Try to find a match using the primary criteria (mom stages)
      final matchedUser = await _findCompatibleUser(
        currentUserId: currentUserId,
        momStages: momStages,
        excludedUsers: excludedUsers,
      );
      print("DEBUG: _findCompatibleUser completed, result: $matchedUser");
      
      if (matchedUser == null) {
        print("SimpleMatching: No match found");
        return null;
      }
      
      print("DEBUG: About to extract matched user data");
      print("DEBUG: matchedUser data: $matchedUser");
      
      final matchedUserStages = _safeExtractStringList(matchedUser, 'momStage');
      print("DEBUG: matchedUserStages extracted: $matchedUserStages");
      
      final matchedUserQuestions = _extractQuestions(matchedUser);
      print("DEBUG: matchedUserQuestions extracted: $matchedUserQuestions");
      
      print("DEBUG: About to call _createMatch");
      // Create the match
      final matchData = await _createMatch(
        currentUserId: currentUserId,
        matchedUserId: matchedUser['id'],
        currentUserStages: momStages,
        matchedUserStages: matchedUserStages,
        currentUserQuestions: selectedQuestions ?? [],
        matchedUserQuestions: matchedUserQuestions,
      );
      print("DEBUG: _createMatch completed");
      
      return matchData;
      
    } catch (e, stackTrace) {
      print("DEBUG: Error in SimpleMatching.findMatch: $e");
      print("DEBUG: Stack trace: $stackTrace");
      return null;
    }
  }

  /// Get users that should be excluded from matching
  static Future<Set<String>> _getExcludedUsers(String currentUserId) async {
    final excludedUsers = <String>{currentUserId}; // Always exclude self
    
    final existingMatches = await _firestore
        .collection('matches')
        .where('users', arrayContains: currentUserId)
        .get();
    
    for (final doc in existingMatches.docs) {
      final data = doc.data();
      final userAId = data['userAId'] as String;
      final userBId = data['userBId'] as String;
      
      // Add the other user to excluded list
      excludedUsers.add(userAId == currentUserId ? userBId : userAId);
    }
    
    print("SimpleMatching: Excluding ${excludedUsers.length} users");
    return excludedUsers;
  }

  /// Find a compatible user based on matching criteria
  static Future<Map<String, dynamic>?> _findCompatibleUser({
    required String currentUserId,
    required List<String> momStages,
    required Set<String> excludedUsers,
  }) async {
    
    // Calculate cutoff time for active users (30 seconds ago)
    final activeThreshold = DateTime.now().subtract(const Duration(seconds: 30));
    
    // SIMPLIFIED FOR TESTING: Use simple query and filter in memory
    // This avoids the need for Firebase composite indexes
    final waitingUsers = await _firestore
        .collection('users')
        .where('isWaiting', isEqualTo: true)
        .limit(50)
        .get();
    
    print("SimpleMatching: Found ${waitingUsers.docs.length} waiting users");
    
    // Filter users in memory
    final activeEligibleUsers = <Map<String, dynamic>>[];
    
    for (final doc in waitingUsers.docs) {
      final data = doc.data();
      final userId = doc.id;
      
      // Skip excluded users
      if (excludedUsers.contains(userId)) {
        continue;
      }
      
      // Check if user is recently active
      final lastActiveTimestamp = data['lastActiveTimestamp'] as Timestamp?;
      if (lastActiveTimestamp != null) {
        final lastActive = lastActiveTimestamp.toDate();
        if (lastActive.isBefore(activeThreshold)) {
          print("SimpleMatching: User $userId not active recently");
          continue; // Skip inactive users
        }
      } else {
        print("SimpleMatching: User $userId has no lastActiveTimestamp");
        continue; // Skip users with no timestamp
      }
      
      // Add to eligible users list
      activeEligibleUsers.add({'id': userId, ...data});
      print("SimpleMatching: Added eligible user: $userId");
    }
    
    print("SimpleMatching: Found ${activeEligibleUsers.length} active eligible users");
    
    if (activeEligibleUsers.isEmpty) {
      print("SimpleMatching: No active users found");
      return null;
    }
    
    // Strategy 1: Prefer users with overlapping mom stages
    for (final user in activeEligibleUsers) {
      final userStages = _safeExtractStringList(user, 'momStage');
      if (_hasCommonStages(momStages, userStages)) {
        print("SimpleMatching: Found user with common stages: ${user['id']}");
        return user;
      }
    }
    
    // Strategy 2: If no common stages, return any active user
    print("SimpleMatching: No common stages found, returning first active user");
    return activeEligibleUsers.first;
  }

  /// Create match record and update user statuses
  static Future<Map<String, dynamic>> _createMatch({
    required String currentUserId,
    required String matchedUserId,
    required List<String> currentUserStages,
    required List<String> matchedUserStages,
    required List<String> currentUserQuestions,
    required List<String> matchedUserQuestions,
  }) async {
    
    // Get usernames
    final currentUserDoc = await _firestore.collection('users').doc(currentUserId).get();
    final matchedUserDoc = await _firestore.collection('users').doc(matchedUserId).get();
    
    final currentUserName = currentUserDoc.data()?['username'] ?? 'Unknown';
    final matchedUserName = matchedUserDoc.data()?['username'] ?? 'Unknown';
    
    // Create match record with hard-coded conversation duration
    final matchRef = _firestore.collection('matches').doc();
    final conversationDuration = 300; // 5 minutes
    final expiresAt = DateTime.now().add(Duration(seconds: conversationDuration));
    
    final matchData = {
      'userAId': currentUserId,
      'userBId': matchedUserId,
      'userAName': currentUserName,
      'userBName': matchedUserName,
      'momStagesA': currentUserStages,
      'momStagesB': matchedUserStages,
      'selectedQuestionsA': currentUserQuestions,
      'selectedQuestionsB': matchedUserQuestions,
      'matchedAt': FieldValue.serverTimestamp(),
      'conversationExpiresAt': Timestamp.fromDate(expiresAt),
      'conversationDurationSeconds': conversationDuration,
      'users': [currentUserId, matchedUserId],
      'status': 'active',
    };
    
    await matchRef.set(matchData);
    
    // Update user statuses to 'in_conversation' (replacing AdminService.updateUserStatus)
    await _firestore.collection('users').doc(currentUserId).update({
      'status': 'in_conversation',
      'lastActive': FieldValue.serverTimestamp(),
    });
    await _firestore.collection('users').doc(matchedUserId).update({
      'status': 'in_conversation',
      'lastActive': FieldValue.serverTimestamp(),
    });
    
    // Prepare user-specific match data
    final currentUserMatchData = {
      'currentUser': {
        'id': currentUserId,
        'username': currentUserName,
        'momStage': currentUserStages,
        'selectedQuestions': currentUserQuestions,
      },
      'matchedUser': {
        'id': matchedUserId,
        'username': matchedUserName,
        'momStage': matchedUserStages,
        'selectedQuestions': matchedUserQuestions,
      },
      'matchId': matchRef.id,
      'conversationDurationSeconds': conversationDuration,
      'expiresAt': expiresAt,
    };
    
    final matchedUserMatchData = {
      'currentUser': {
        'id': matchedUserId,
        'username': matchedUserName,
        'momStage': matchedUserStages,
        'selectedQuestions': matchedUserQuestions,
      },
      'matchedUser': {
        'id': currentUserId,
        'username': currentUserName,
        'momStage': currentUserStages,
        'selectedQuestions': currentUserQuestions,
      },
      'matchId': matchRef.id,
      'conversationDurationSeconds': conversationDuration,
      'expiresAt': expiresAt,
    };
    
    // Update both users' status with new match data
    final batch = _firestore.batch();
    
    batch.update(_firestore.collection('users').doc(currentUserId), {
      'matchData': currentUserMatchData,
      'isWaiting': false,
      'isInConversation': true,
      'status': 'in_conversation',
    });
    
    batch.update(_firestore.collection('users').doc(matchedUserId), {
      'matchData': matchedUserMatchData,
      'isWaiting': false,
      'isInConversation': true,
      'status': 'in_conversation',
    });
    
    await batch.commit();
    
    print("SimpleMatching: Created match ${matchRef.id} between $currentUserName and $matchedUserName");
    print("SimpleMatching: Conversation duration set to $conversationDuration seconds (expires at $expiresAt)");
    
    return currentUserMatchData;
  }

  /// Helper: Check if two stage lists have common elements
  static bool _hasCommonStages(List<String> stages1, List<String> stages2) {
    return stages1.any((stage) => stages2.contains(stage));
  }

  /// Helper: Extract questions from user data
  static List<String> _extractQuestions(Map<String, dynamic> userData) {
    final questions = <String>[];
    
    questions.addAll(_safeExtractStringList(userData, 'questionSet1'));
    questions.addAll(_safeExtractStringList(userData, 'questionSet2'));
    
    return questions;
  }

  /// Helper: Safely extract a list of strings from user data
  static List<String> _safeExtractStringList(Map<String, dynamic> data, String key) {
    print("DEBUG: _safeExtractStringList called with key: $key");
    
    final value = data[key];
    print("DEBUG: Value for key '$key': $value (type: ${value.runtimeType})");
    
    if (value == null) {
      print("DEBUG: Value is null, returning empty list");
      return [];
    }
    
    // Check if it's already a List
    if (value is List) {
      print("DEBUG: Value is a List with ${value.length} items");
      try {
        final result = value.map((item) => item?.toString() ?? '').where((item) => item.isNotEmpty).toList();
        print("DEBUG: Successfully converted list, result: $result");
        return result;
      } catch (e) {
        print("DEBUG: Error converting list: $e");
        return [];
      }
    }
    
    // If it's a single string, wrap it in a list
    if (value is String && value.isNotEmpty) {
      print("DEBUG: Value is a string, wrapping in list: [$value]");
      return [value];
    }
    
    // For any other type, return empty list
    print("DEBUG: Value is unknown type, returning empty list");
    return [];
  }

  /// Reset user status for new matching
  static Future<void> resetUserForMatching(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'status': 'waiting',
      'lastActive': FieldValue.serverTimestamp(),
      'isWaiting': true,
      'isInConversation': false,
      'matchData': FieldValue.delete(),
    });
  }

  /// Clean up user status
  static Future<void> cleanupUserStatus(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'status': 'offline',
      'lastActive': FieldValue.serverTimestamp(),
      'isWaiting': false,
      'isInConversation': false,
      'matchData': FieldValue.delete(),
    });
  }

  /// Start conversation timer with hard-coded duration
  static Timer? startConversationTimer({
    required String matchId,
    required VoidCallback onTimeUp,
  }) {
    final duration = Duration(seconds: 300); // 5 minutes
    
    print('SimpleMatching: Starting conversation timer for ${duration.inSeconds} seconds');
    
    return Timer(duration, () {
      print('SimpleMatching: Conversation time up for match $matchId');
      onTimeUp();
    });
  }

  /// Get user connections with strength tracking (hard-coded decay logic)
  static Future<List<Map<String, dynamic>>> getUserConnections(String userId) async {
    try {
      final connections = await _firestore
          .collection('matches')
          .where('userA', isEqualTo: userId)
          .get();
      
      final connections2 = await _firestore
          .collection('matches')
          .where('userB', isEqualTo: userId)
          .get();
      
      final allConnections = [...connections.docs, ...connections2.docs];
      
      return allConnections.map((doc) {
        final data = doc.data();
        final lastContact = (data['lastContact'] as Timestamp?)?.toDate() ?? 
                           (data['createdAt'] as Timestamp?)?.toDate() ?? 
                           DateTime.now();
        
        // Decay system removed – simply use stored strength
        final int currentStrength = data['connectionStrength'] ?? 100;
        
        // Determine if connection needs warning based on custom rule (optional)
        final bool needsWarning = false;
        
        return {
          'id': doc.id,
          'userA': data['userA'],
          'userB': data['userB'],
          'userAName': data['userAName'] ?? 'Unknown',
          'userBName': data['userBName'] ?? 'Unknown',
          'lastContact': lastContact,
          'strength': currentStrength,
          'needsWarning': needsWarning,
          'status': 'active',
          ...data,
        };
      }).toList();
    } catch (e) {
      print('SimpleMatching: Error getting user connections: $e');
      return [];
    }
  }

  /// Update connection contact time (when users interact)
  static Future<void> updateConnectionContact(String connectionId) async {
    try {
      final strength = 100; // Reset to full strength on contact
      
      await _firestore.collection('matches').doc(connectionId).update({
        'lastContact': FieldValue.serverTimestamp(),
        'strength': strength,
        'status': 'active',
      });
      
      print('SimpleMatching: Updated connection $connectionId contact time');
    } catch (e) {
      print('SimpleMatching: Error updating connection contact: $e');
    }
  }

  // TODO: Future enhancement - add question-based matching scoring
  // static double _calculateQuestionCompatibility(List<String> questions1, List<String> questions2) {
  //   // Implement question-based scoring logic
  // }
} 