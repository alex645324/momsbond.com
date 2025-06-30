import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../views/messages_view.dart';
import '../models/messages_model.dart';

class ConversationHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Checks if a user is available for conversation
  static Future<bool> isUserAvailable(String userId) async {
    try {
      print("ConversationHelper: Checking availability for user $userId");
      final doc = await _firestore.collection('users').doc(userId).get();
      final userData = doc.data();
      
      if (userData == null) {
        print("ConversationHelper: No user data found for $userId");
        return false;
      }
      
      bool isInConversation = userData['isInConversation'] ?? false;
      print("ConversationHelper: User $userId isInConversation: $isInConversation");
      
      return !isInConversation;
    } catch (e) {
      print("ConversationHelper: Error checking user availability: $e");
      return false;
    }
  }

  /// Updates the user's conversation status
  static Future<void> updateUserConversationStatus(String userId, bool isInConversation) async {
    try {
      print("ConversationHelper: Updating user $userId status to isInConversation=$isInConversation");
      
      await _firestore.collection('users').doc(userId).update({
        'isInConversation': isInConversation,
        'lastStatusUpdate': FieldValue.serverTimestamp(),
      });
      
      print("ConversationHelper: Successfully updated status for user $userId");
    } catch (e) {
      print("ConversationHelper: Error updating user status: $e");
    }
  }

  /// Opens a conversation with another user
  static Future<void> openConversation(
    BuildContext context, 
    String currentUserId,
    String conversationId, 
    Map<String, dynamic> matchData
  ) async {
    try {
      print("ConversationHelper: Attempting to open conversation $conversationId for user $currentUserId");
      print("ConversationHelper: Match data: $matchData");
      
      // Determine the other user's ID
      final String otherUserId = matchData['userAId'] == currentUserId 
          ? matchData['userBId'] 
          : matchData['userAId'];
      
      print("ConversationHelper: Other user ID: $otherUserId");
      
      // Check if the other user is available
      bool isAvailable = await isUserAvailable(otherUserId);
      print("ConversationHelper: Other user available: $isAvailable");
      
      if (!isAvailable) {
        // Return without opening conversation
        print("ConversationHelper: Cannot open conversation - other user is not available");
        return;
      }
      
      // Create init data for chat
      final initData = ConversationInitData(
        conversationId: conversationId,
        currentUser: CurrentUserData(
          id: currentUserId,
          username: matchData['userAId'] == currentUserId 
              ? matchData['userAName'] 
              : matchData['userBName'],
          momStage: List<String>.from(matchData['userAId'] == currentUserId 
              ? matchData['momStagesA'] 
              : matchData['momStagesB']),
          selectedQuestions: List<String>.from(matchData['userAId'] == currentUserId 
              ? matchData['selectedQuestionsA'] 
              : matchData['selectedQuestionsB']),
        ),
        matchedUser: MatchedUserData(
          id: otherUserId,
          username: matchData['userAId'] == currentUserId 
              ? matchData['userBName'] 
              : matchData['userAName'],
          momStage: List<String>.from(matchData['userAId'] == currentUserId 
              ? matchData['momStagesB'] 
              : matchData['momStagesA']),
          selectedQuestions: List<String>.from(matchData['userAId'] == currentUserId 
              ? matchData['selectedQuestionsB'] 
              : matchData['selectedQuestionsA']),
        ),
        matchId: matchData['id'],
      );
      
      print("ConversationHelper: Prepared chat init data: $initData");
      
      // Update current user status
      await updateUserConversationStatus(currentUserId, true);
      
      print("ConversationHelper: Navigating to chat page");
      
      // Navigate to chat
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MessagesView(initData: initData),
        ),
      ).then((_) {
        // When chat is closed, update status
        print("ConversationHelper: Chat closed, updating user status");
        updateUserConversationStatus(currentUserId, false);
      });
      
    } catch (e) {
      print("ConversationHelper: Error opening conversation: $e");
    }
  }
}