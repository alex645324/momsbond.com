import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import '../Screens/ChatPage.dart';

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
  static Future<void> updateUserConversationStatus(String userId, bool isInConversation, String? conversationId) async {
    try {
      print("ConversationHelper: Updating user $userId status to isInConversation=$isInConversation, conversationId=$conversationId");
      
      await _firestore.collection('users').doc(userId).update({
        'isInConversation': isInConversation,
        'activeConversationId': conversationId,
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
      
      // Create the current user object for chat
      final types.User currentUser = types.User(
        id: currentUserId,
        firstName: matchData['userAId'] == currentUserId 
            ? matchData['userAName'] 
            : matchData['userBName'],
      );
      
      // Extract match data to pass to chat
      final Map<String, dynamic> chatMatchData = {
        'conversationId': conversationId,
        'currentUser': {
          'id': currentUserId,
          'username': matchData['userAId'] == currentUserId 
              ? matchData['userAName'] 
              : matchData['userBName'],
          'momStage': matchData['userAId'] == currentUserId 
              ? matchData['momStagesA'] 
              : matchData['momStagesB'],
          'selectedQuestions': matchData['userAId'] == currentUserId 
              ? matchData['selectedQuestionsA'] 
              : matchData['selectedQuestionsB'],
        },
        'matchedUser': {
          'id': otherUserId,
          'username': matchData['userAId'] == currentUserId 
              ? matchData['userBName'] 
              : matchData['userAName'],
          'momStage': matchData['userAId'] == currentUserId 
              ? matchData['momStagesB'] 
              : matchData['momStagesA'],
          'selectedQuestions': matchData['userAId'] == currentUserId 
              ? matchData['selectedQuestionsB'] 
              : matchData['selectedQuestionsA'],
        },
        'matchId': matchData['id'],
      };
      
      print("ConversationHelper: Prepared chat match data: $chatMatchData");
      
      // Update current user status
      await updateUserConversationStatus(currentUserId, true, conversationId);
      
      print("ConversationHelper: Navigating to chat page");
      
      // Navigate to chat
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(
            conversationId: conversationId,
            currentUser: currentUser,
            matchData: chatMatchData,
          ),
        ),
      ).then((_) {
        // When chat is closed, update status
        print("ConversationHelper: Chat closed, updating user status");
        updateUserConversationStatus(currentUserId, false, null);
      });
      
    } catch (e) {
      print("ConversationHelper: Error opening conversation: $e");
    }
  }
}