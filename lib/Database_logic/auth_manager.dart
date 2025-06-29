import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class ConversationManager {
  static final ConversationManager _instance = ConversationManager._internal();
  factory ConversationManager() => _instance;
  ConversationManager._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initializeConversation({
    required String conversationId,
    required List<String> participants,
    required Map<String, dynamic> matchData,
  }) async {
    final endTime = DateTime.now().add(const Duration(seconds: 30)); // Changed to 30 minutes

    await _firestore.collection('conversations').doc(conversationId).set({
      'participants': participants,
      'status': 'active',
      'startTime': FieldValue.serverTimestamp(),
      'endTime': endTime.millisecondsSinceEpoch,
      'matchData': matchData,
      'matchId': matchData['matchId'], // Explicitly store matchId at the top level
    }, SetOptions(merge: true));
    
    print("ConversationManager: Initialized conversation $conversationId with matchId: ${matchData['matchId']}");
  }

  Future<void> endConversation(String conversationId) async {
    await _firestore.collection('conversations').doc(conversationId).update({
      'status': 'archived',
    });
    print("ConversationManager: Ended conversation $conversationId");
  }
}

class InvitationManager {
  static final InvitationManager _instance = InvitationManager._internal();
  factory InvitationManager() => _instance;
  InvitationManager._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
// In auth_manager.dart, update the sendInvitation method in InvitationManager class
Future<void> sendInvitation({
  required String senderId,
  required String senderName,
  required String receiverId,
  required String receiverName,
  required String matchId,
  required String conversationId,
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
    
    // Create the invitation document
    await _firestore.collection('invitations').add({
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'matchId': matchId,
      'conversationId': conversationId,
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
  
// In the acceptInvitation method in auth_manager.dart (InvitationManager class)
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
      'activeConversationId': conversationId,
      'pendingChat': true, // This flag should trigger navigation for the sender, but it's not being detected
    });
    
    print("InvitationManager: Updated sender (${invitationData['senderId']}) status with pendingChat=true");
      
      await _firestore.collection('users').doc(invitationData['receiverId']).update({
        'isInConversation': true,
        'activeConversationId': conversationId,
        'hasInvitation': false,
        'pendingChat': true, // Add this field to trigger navigation for receiver
      });
      
      // Initialize or re-initialize the conversation
      final endTime = DateTime.now().add(const Duration(seconds: 30)); // 30-minute chat
      
      // Get the match data from the matches collection
      final matchDoc = await _firestore.collection('matches').doc(matchId).get();
      Map<String, dynamic> matchData = {};
      
      if (matchDoc.exists) {
        matchData = matchDoc.data() as Map<String, dynamic>;
        print("InvitationManager: Found match data: $matchData");
      } else {
        // If match document doesn't exist, build minimal match data
        print("InvitationManager: Match document not found, creating minimal match data");
        matchData = {
          'userAId': invitationData['senderId'],
          'userBId': invitationData['receiverId'],
          'userAName': invitationData['senderName'],
          'userBName': invitationData['receiverName'],
        };
      }
      
      // Set conversation data with explicit matchId
      await _firestore.collection('conversations').doc(conversationId).set({
        'participants': [invitationData['senderId'], invitationData['receiverId']],
        'status': 'active',
        'startTime': FieldValue.serverTimestamp(),
        'endTime': endTime.millisecondsSinceEpoch,
        'matchId': matchId, // Explicit matchId field
        'invitationAccepted': true,
        'senderInfo': {
          'id': invitationData['senderId'],
          'name': invitationData['senderName'],
        },
        'receiverInfo': {
          'id': invitationData['receiverId'],
          'name': invitationData['receiverName'],
        },
      }, SetOptions(merge: true));
      
      print("InvitationManager: Conversation initialized with matchId: $matchId");
      
      // Delete the invitation document
      await _firestore.collection('invitations').doc(invitationId).delete();
      print("InvitationManager: Invitation deleted from cloud");
      
      // Return conversation details
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

class AuthManager {
  // Singleton pattern
  static final AuthManager _instance = AuthManager._internal();
  factory AuthManager() => _instance;
  AuthManager._internal();

  // Firebase and Google Sign-In instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Use the Web client ID from Firebase Console
final GoogleSignIn _googleSignIn = GoogleSignIn(
  clientId: "974452187234-9s0lgdqe8uamd23smf325e2a2ffpg1h6.apps.googleusercontent.com",
);

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get user ID
  String getUserId() {
    User? user = _auth.currentUser;
    return user?.uid ?? "no_user";
  }

// Initialize authentication
Future<void> initialize() async {
  try {
    // Set persistence for web
    if (kIsWeb) {
      await _auth.setPersistence(Persistence.LOCAL);
      print("Set Firebase Auth persistence to LOCAL for web");
    }
    
    await _auth.authStateChanges().first;
    print("Auth manager initialized");
    
    // Check current user after initialization
    final currentUser = _auth.currentUser;
    print("Auth initialize - Current user: ${currentUser?.uid ?? 'null'}");
    if (currentUser != null) {
      print("Auth initialize - User email: ${currentUser.email}");
      print("Auth initialize - User display name: ${currentUser.displayName}");
    }
  } catch (e) {
    print("Error initializing auth manager: $e");
  }
}

  // // Sign in with Google
  // Future<String?> signInWithGoogle() async {
  //   try {
  //     final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
  //     if (googleUser == null) return null; // User canceled

  //     final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
  //     final credential = GoogleAuthProvider.credential(
  //       accessToken: googleAuth.accessToken,
  //       idToken: googleAuth.idToken,
  //     );

  //     final userCredential = await _auth.signInWithCredential(credential);
  //     final userId = userCredential.user?.uid;
      
  //     if (userId != null) {
  //       // Initialize user document with Google info
  //       await _firestore.collection('users').doc(userId).set({
  //         'username': userCredential.user?.displayName ?? 'User',
  //         'email': userCredential.user?.email,
  //         'isInConversation': false,
  //         'activeConversationId': null,
  //         'lastStatusUpdate': FieldValue.serverTimestamp(),
  //       }, SetOptions(merge: true));
        
  //       print("User signed in with Google: $userId");
  //     }

  //     return userId;
  //   } catch (e) {
  //     print("Error signing in with Google: $e");
  //     return null;
  //   }
  // }

  // Replace the signInWithGoogle method with this:

// Sign in with Google using Firebase popup
Future<String?> signInWithGoogle() async {
  try {
    print("Starting Firebase popup Google Sign-In...");
    
    GoogleAuthProvider googleProvider = GoogleAuthProvider();
    
    final userCredential = await _auth.signInWithPopup(googleProvider);
    final userId = userCredential.user?.uid;
    final userEmail = userCredential.user?.email;
    
    if (userId != null && userEmail != null) {
      print("Firebase sign-in successful: $userId");
      print("User: ${userCredential.user?.displayName} ($userEmail)");
      print("=== USER EMAIL: $userEmail ===");
      
      // Check if email already exists in database
      print("Checking if email exists in database...");
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: userEmail)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        print("=== EMAIL EXISTS IN DATABASE ===");
        print("Found ${querySnapshot.docs.length} users with email: $userEmail");
        
        // Log details of existing users
        for (var doc in querySnapshot.docs) {
          final data = doc.data();
          print("Existing user ID: ${doc.id}");
          print("Existing user data: $data");
        }
      } else {
        print("=== EMAIL NOT FOUND IN DATABASE - NEW USER ===");
      }
      
      // Initialize/update user document with Google info
      await _firestore.collection('users').doc(userId).set({
        'username': userCredential.user?.displayName ?? 'User',
        'email': userEmail,
        'isInConversation': false,
        'activeConversationId': null,
        'lastStatusUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      print("User document created/updated for ID: $userId");
    }

    return userId;
  } catch (e) {
    print("Firebase popup Google Sign-In error: $e");
    return null;
  }
}

// Check if user is already signed in
Future<bool> isUserSignedIn() async {
  // Force a refresh of the auth state
  await _auth.authStateChanges().first;
  
  final user = _auth.currentUser;
  print("=== AUTH STATE CHECK ===");
  print("Current user: ${user?.uid ?? 'null'}");
  if (user != null) {
    print("User email: ${user.email}");
    print("=== CURRENT USER EMAIL: ${user.email} ==="); // Added this line
    print("User display name: ${user.displayName}");
    print("User is anonymous: ${user.isAnonymous}");
  }
  print("========================");
  
  return user != null;
}

  // // Sign out
  // Future<void> signOut() async {
  //   await _googleSignIn.signOut();
  //   await _auth.signOut();
  // }

  // Also update the signOut method:
Future<void> signOut() async {
  await _auth.signOut();
}

  // Rest of your existing methods remain the same...
  Future<bool> clearUserData(String field) async {
    try {
      String userId = getUserId();
      await _firestore.collection('users').doc(userId).update({
        field: FieldValue.delete(),
      });
      print("Cleared user data: $field");
      return true;
    } catch (e) {
      print("Error clearing user data: $e");
      return false;
    }
  }

  Future<bool> saveUserData(String field, dynamic value) async {
    try {
      String userId = getUserId();
      await _firestore.collection('users').doc(userId).set({
        field: value,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print("User data saved: $field = $value");
      return true;
    } catch (e) {
      print("Error saving user data: $e");
      return false;
    }
  }

  Future<bool> saveUserProfile(Map<String, dynamic> data) async {
    try {
      String userId = getUserId();
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('users').doc(userId).set(
        data,
        SetOptions(merge: true),
      );
      print("User profile saved");
      return true;
    } catch (e) {
      print("Error saving user profile: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>?> getUserData() async {
    try {
      String userId = getUserId();
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      } else {
        print("No user data found");
        return null;
      }
    } catch (e) {
      print("Error getting user data: $e");
      return null;
    }
  }

  void showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}