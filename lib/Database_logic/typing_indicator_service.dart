import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class TypingIndicatorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Updates typing status for a user in a conversation
  Future<void> updateTypingStatus({
    required String conversationId,
    required String userId,
    required bool isTyping,
  }) async {
    try {
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('typing')
          .doc(userId)
          .set({
        'isTyping': isTyping,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('TypingIndicatorService: Error updating typing status: $e');
    }
  }
  
  /// Stream that listens to typing status of other participants
  Stream<Map<String, bool>> getTypingStatusStream({
    required String conversationId,
    required String excludeUserId,
  }) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('typing')
        .snapshots()
        .map((snapshot) {
      final typingStatus = <String, bool>{};
      
      for (final doc in snapshot.docs) {
        final userId = doc.id;
        if (userId != excludeUserId) {
          final data = doc.data();
          final isTyping = data['isTyping'] as bool? ?? false;
          final lastUpdated = data['lastUpdated'] as Timestamp?;
          
          // Consider typing status stale after 3 seconds
          if (lastUpdated != null) {
            final timeDiff = DateTime.now().difference(lastUpdated.toDate());
            if (timeDiff.inSeconds > 3) {
              typingStatus[userId] = false;
            } else {
              typingStatus[userId] = isTyping;
            }
          } else {
            typingStatus[userId] = isTyping;
          }
        }
      }
      
      return typingStatus;
    });
  }
  
  /// Clears typing status for a user when they leave the conversation
  Future<void> clearTypingStatus({
    required String conversationId,
    required String userId,
  }) async {
    try {
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('typing')
          .doc(userId)
          .delete();
    } catch (e) {
      print('TypingIndicatorService: Error clearing typing status: $e');
    }
  }
}