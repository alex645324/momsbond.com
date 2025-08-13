import 'package:cloud_firestore/cloud_firestore.dart';

class InvitationManager {
  static final InvitationManager _instance = InvitationManager._internal();
  factory InvitationManager() => _instance;
  InvitationManager._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Future<void> sendInvitation({
    required String senderId,
    required String senderName,
    required String receiverId,
    required String receiverName,
    required String matchId,
    String? existingConversationId, // Optional: reuse existing conversation ID for past connections
  }) async {
    try {
      print("InvitationManager: Sending invitation from $senderName to $receiverName with matchId: $matchId");
      
      // Check if there's any negative feedback for this match
      final matchDoc = await _firestore.collection('matches').doc(matchId).get();
      if (matchDoc.exists) {
        final matchData = matchDoc.data() as Map<String, dynamic>;
        
        // Check if either user chose to remove the connection
        if (matchData.containsKey('feedback')) {
          final feedback = matchData['feedback'] as Map<String, dynamic>;
          
          if (feedback.containsKey('${senderId}_preference') && 
              feedback['${senderId}_preference'] == 'remove') {
            print("InvitationManager: Sender chose to remove this connection previously");
            return; // Don't send invitation
          }
          
          if (feedback.containsKey('${receiverId}_preference') && 
              feedback['${receiverId}_preference'] == 'remove') {
            print("InvitationManager: Receiver chose to remove this connection previously");
            return; // Don't send invitation
          }
        }
      }
      
      // Use existing conversation ID for past connections, or generate new one for fresh connections
      final conversationId = existingConversationId ?? _generateConversationId(senderId, receiverId);
      
      // Create the invitation document
      await _firestore.collection('invitations').add({
        'senderId': senderId,
        'senderName': senderName,
        'receiverId': receiverId,
        'receiverName': receiverName,
        'matchId': matchId,
        'conversationId': conversationId, // For identification only, not stored as conversation
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Update receiver's invitation status
      await _firestore.collection('users').doc(receiverId).update({
        'hasInvitation': true,
      });
      
      print("InvitationManager: Invitation sent from $senderName to $receiverName");
    } catch (e) {
      print("Error sending invitation: $e");
    }
  }

  // Helper method to generate conversation ID locally
  String _generateConversationId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return 'conversation_${sortedIds[0]}_${sortedIds[1]}_$timestamp';
  }
  
  Future<Map<String, dynamic>?> acceptInvitation(String invitationId) async {
    try {
      print("InvitationManager: Processing invitation acceptance for $invitationId");
      
      // Get the invitation details
      final invitationDoc = await _firestore.collection('invitations').doc(invitationId).get();
      if (!invitationDoc.exists) {
        print("InvitationManager: Invitation document not found");
        return null;
      }
      
      final invitationData = invitationDoc.data() as Map<String, dynamic>;
      final String conversationId = invitationData['conversationId'];
      final String matchId = invitationData['matchId'];
      
      print("InvitationManager: Accepting invitation for conversation: $conversationId, match: $matchId");
      
      // Update both users' status to be in a conversation
      await _firestore.collection('users').doc(invitationData['senderId']).update({
        'isInConversation': true,
        'pendingChat': true, // This flag should trigger navigation for the sender
        'activeMatchId': matchId, // Set the active match ID for navigation
      });
      
      print("InvitationManager: Updated sender (${invitationData['senderId']}) status with pendingChat=true and activeMatchId=$matchId");
        
      await _firestore.collection('users').doc(invitationData['receiverId']).update({
        'isInConversation': true,
        'hasInvitation': false,
        'pendingChat': true, // Add this field to trigger navigation for receiver
        'activeMatchId': matchId, // Set the active match ID for navigation
      });
      
      print("InvitationManager: Updated receiver (${invitationData['receiverId']}) status with pendingChat=true and activeMatchId=$matchId");
      
      // Note: Conversation data is no longer stored in database - only exists in memory during chat
      print("InvitationManager: Conversation will be handled in-memory only");
      
      // Delete the invitation document
      await _firestore.collection('invitations').doc(invitationId).delete();
      print("InvitationManager: Invitation deleted from cloud");
      
      // Return conversation details for in-memory initialization
      return {
        'conversationId': conversationId,
        'matchId': matchId,
        'senderId': invitationData['senderId'],
        'senderName': invitationData['senderName'],
        'receiverId': invitationData['receiverId'],
        'receiverName': invitationData['receiverName'],
      };
    } catch (e) {
      print("Error accepting invitation: $e");
      return null;
    }
  }
    
  Future<void> declineInvitation(String invitationId) async {
    try {
      // Get the invitation details
      final invitationDoc = await _firestore.collection('invitations').doc(invitationId).get();
      if (!invitationDoc.exists) return;
      
      final invitationData = invitationDoc.data() as Map<String, dynamic>;
      final String senderId = invitationData['senderId'];
      final String receiverName = invitationData['receiverName'];
      
      // Clear invitation status for receiver
      await _firestore.collection('users').doc(invitationData['receiverId']).update({
        'hasInvitation': false,
      });
      
      // First get current notifications if they exist
      DocumentSnapshot senderDoc = await _firestore.collection('users').doc(senderId).get();
      Map<String, dynamic>? senderData = senderDoc.data() as Map<String, dynamic>?;
      
      List<Map<String, dynamic>> notifications = [];
      if (senderData != null && senderData.containsKey('notifications')) {
        notifications = List<Map<String, dynamic>>.from(senderData['notifications']);
      }
      
      // Add new notification
      notifications.add({
        'type': 'invitation_declined',
        'message': '$receiverName declined your chat invitation',
        'timestamp': DateTime.now().millisecondsSinceEpoch, // Use regular timestamp instead
        'read': false
      });
      
      // Update user document with new notifications array
      await _firestore.collection('users').doc(senderId).update({
        'notifications': notifications
      });
      
      // Delete the invitation document
      await _firestore.collection('invitations').doc(invitationId).delete();
      print("Invitation declined and deleted from cloud. Sender notified.");
    } catch (e) {
      print("Error declining invitation: $e");
    }
  }
} 