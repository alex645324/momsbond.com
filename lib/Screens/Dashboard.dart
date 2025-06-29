import 'dart:async'; // Add this for StreamSubscription
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Database_logic/auth_manager.dart';
import '../Templates/Custom_templates.dart';
import '../Screens/Loading.dart';
import '../Templates/conversation_helper.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types; // Make sure this is imported
import '../Screens/ChatPage.dart'; // Import ChatPage explicitly
import '../main.dart' show navigatorKey;

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  StreamSubscription<QuerySnapshot>? _invitationSubscription;
  StreamSubscription<DocumentSnapshot>? _notificationSubscription;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  // In Dashboard.dart, _DashboardState class
  @override
  void initState() {
    super.initState();
    _listenForInvitations();
    _listenForPendingChats(); 
    _listenForNotifications(); 
    _cleanupOldConnections();
  }

  @override
  void dispose() {
    _invitationSubscription?.cancel();
    _notificationSubscription?.cancel(); // Add this line
    super.dispose();
  }

  Future<String> _getCurrentUserId() async {
    return AuthManager().getUserId();
  }

// Add this method to listen for notifications
void _listenForNotifications() async {
  final currentUserId = await _getCurrentUserId();
  
  _notificationSubscription = FirebaseFirestore.instance
      .collection('users')
      .doc(currentUserId)
      .snapshots()
      .listen((snapshot) {
    if (!snapshot.exists) return;
    
    final userData = snapshot.data() as Map<String, dynamic>;
    if (userData.containsKey('notifications')) {
      List<dynamic> notifications = userData['notifications'];
      
      // Filter unread notifications
      List<dynamic> unreadNotifications = notifications.where((notification) => 
        notification['read'] == false).toList();
      
      // Show notifications if there are any unread ones
      if (unreadNotifications.isNotEmpty) {
        _showNotifications(unreadNotifications);
        
        // Mark notifications as read
        _markNotificationsAsRead(currentUserId, notifications);
      }
    }
  });
}

void _showNotifications(List<dynamic> notifications) {
  // Only show the most recent notification if there are multiple
  // Sort notifications by timestamp (newest first)
  notifications.sort((a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));
  
  final latestNotification = notifications.first;
  
  if (latestNotification['type'] == 'invitation_declined') {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(latestNotification['message']),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Dismiss',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}

// Mark notifications as read
Future<void> _markNotificationsAsRead(String userId, List<dynamic> notifications) async {
  // Update each notification to mark it as read
  List<dynamic> updatedNotifications = notifications.map((notification) {
    notification['read'] = true;
    return notification;
  }).toList();
  
  // Update the user document
  await FirebaseFirestore.instance.collection('users').doc(userId).update({
    'notifications': updatedNotifications
  });
}

  // In Dashboard.dart, _DashboardState class, add this method to listen for pending chats
void _listenForPendingChats() async {
  final currentUserId = await _getCurrentUserId();
  
  FirebaseFirestore.instance
      .collection('users')
      .doc(currentUserId)
      .snapshots()
      .listen((snapshot) {
    if (!snapshot.exists) return;
    
    final userData = snapshot.data() as Map<String, dynamic>;
    final bool hasPendingChat = userData['pendingChat'] ?? false;
    final String? activeConversationId = userData['activeConversationId'];
    
    if (hasPendingChat && activeConversationId != null) {
      print("Detected pending chat for $currentUserId");
      
      // Clear the pending chat flag first to prevent multiple navigations
      FirebaseFirestore.instance.collection('users').doc(currentUserId).update({
        'pendingChat': false,
      });
      
      // Fetch necessary data for the chat
      _navigateToActiveChat(currentUserId, activeConversationId);
    }
  });
}

// Add a helper method to navigate to the active chat
void _navigateToActiveChat(String userId, String conversationId) async {
  try {
    print("Preparing to navigate to active chat: $conversationId");
    
    // Get conversation data
    final conversationDoc = await FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .get();
    
    if (!conversationDoc.exists) {
      print("Conversation document not found");
      return;
    }
    
    final conversationData = conversationDoc.data() as Map<String, dynamic>;
    print("Found conversation data: ${conversationData['matchId']}");
    
    // Get match data using the matchId from the conversation
    final String matchId = conversationData['matchId'];
    
    final matchDoc = await FirebaseFirestore.instance
        .collection('matches')
        .doc(matchId)
        .get();
    
    if (!matchDoc.exists) {
      print("Match document not found for ID: $matchId");
      return;
    }
    
    final matchData = matchDoc.data() as Map<String, dynamic>;
    
    // Determine if current user is user A or user B
    final bool isUserA = matchData['userAId'] == userId;
    final String otherUserId = isUserA ? matchData['userBId'] : matchData['userAId'];
    final String otherUserName = isUserA ? matchData['userBName'] : matchData['userAName'];
    
    // Get current user data
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    
    final userData = userDoc.data() as Map<String, dynamic>?;
    if (userData == null) {
      print("User data is null");
      return;
    }
    
    // Create chat match data
    final chatMatchData = {
      'conversationId': conversationId,
      'currentUser': {
        'id': userId,
        'username': userData['username'] ?? 'User',
        'momStage': userData['momStage'] ?? [],
        'selectedQuestions': _combineQuestionSets(userData),
      },
      'matchedUser': {
        'id': otherUserId,
        'username': otherUserName,
        'momStage': isUserA ? matchData['momStagesB'] : matchData['momStagesA'],
        'selectedQuestions': isUserA ? matchData['selectedQuestionsB'] : matchData['selectedQuestionsA'],
      },
      'matchId': matchId,
    };
    
    // Create user object for chat
    final currentUserObj = types.User(
      id: userId,
      firstName: userData['username'] ?? 'User',
    );
    
    print("Navigating to ChatPage with match data...");
    
    // Use navigatorKey for reliable navigation
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => ChatPage(
          conversationId: conversationId,
          currentUser: currentUserObj,
          matchData: chatMatchData,
        ),
      ),
      (route) => false,
    );
    
    print("Navigation to ChatPage executed");
  } catch (e) {
    print("Error in _navigateToActiveChat: $e");
  }
}




// Separate method to handle the actual navigation
void _navigateToChat(String userId, String conversationId, String matchId, Map<String, dynamic> matchData) async {
  try {
    print("Preparing chat data with match: $matchId");
    
    // Determine if current user is user A or user B
    final bool isUserA = matchData['userAId'] == userId;
    final String otherUserId = isUserA ? matchData['userBId'] : matchData['userAId'];
    final String otherUserName = isUserA ? matchData['userBName'] : matchData['userAName'];
    
    // Get current user data
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    
    final userData = userDoc.data() as Map<String, dynamic>?;
    if (userData == null) {
      print("User data is null");
      return;
    }
    
    // Create chat match data
    final chatMatchData = {
      'conversationId': conversationId,
      'currentUser': {
        'id': userId,
        'username': userData['username'] ?? 'User',
        'momStage': userData['momStage'] ?? [],
        'selectedQuestions': _combineQuestionSets(userData),
      },
      'matchedUser': {
        'id': otherUserId,
        'username': otherUserName,
        'momStage': isUserA ? matchData['momStagesB'] : matchData['momStagesA'],
        'selectedQuestions': isUserA ? matchData['selectedQuestionsB'] : matchData['selectedQuestionsA'],
      },
      'matchId': matchId,
    };
    
    // Create user object for chat
    final currentUserObj = types.User(
      id: userId,
      firstName: userData['username'] ?? 'User',
    );
    
    print("Navigating to ChatPage with match data...");
    
    // Use navigatorKey for reliable navigation
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => ChatPage(
          conversationId: conversationId,
          currentUser: currentUserObj,
          matchData: chatMatchData,
        ),
      ),
      (route) => false,
    );
    
    print("Navigation to ChatPage executed");
  } catch (e) {
    print("Error in _navigateToChat: $e");
  }
}

Future<void> _cleanupOldConnections() async {
  try {
    final currentUserId = await _getCurrentUserId();
    final cutoffDate = DateTime.now().subtract(const Duration(days: 2));
    
    // Query matches that include the current user
    QuerySnapshot matchesSnapshot = await FirebaseFirestore.instance
        .collection('matches')
        .where('users', arrayContains: currentUserId)
        .get();
    
    // Check each match for inactivity
    for (var doc in matchesSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      
      // Check if there was a conversation end time
      if (data.containsKey('lastConversationEnd')) {
        Timestamp lastConversationEnd = data['lastConversationEnd'];
        if (lastConversationEnd.toDate().isBefore(cutoffDate)) {
          // This match is inactive for more than 2 days
          await FirebaseFirestore.instance
              .collection('matches')
              .doc(doc.id)
              .update({'active': false});
        }
      }
      // If no conversation happened, check match creation date
      else if (data.containsKey('matchedAt')) {
        Timestamp matchedAt = data['matchedAt'];
        if (matchedAt.toDate().isBefore(cutoffDate)) {
          // This match is more than 2 days old with no conversation
          await FirebaseFirestore.instance
              .collection('matches')
              .doc(doc.id)
              .update({'active': false});
        }
      }
    }
    
    print("Cleaned up old connections");
  } catch (e) {
    print("Error cleaning up old connections: $e");
  }
}
  // Listen for incoming chat invitations
  void _listenForInvitations() async {
    final currentUserId = await _getCurrentUserId();
    
    _invitationSubscription = FirebaseFirestore.instance
        .collection('invitations')
        .where('receiverId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final invitationDoc = snapshot.docs.first;
        final invitationData = invitationDoc.data() as Map<String, dynamic>;
        
        // Show invitation popup
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => ChatInvitationPopup(
            senderName: invitationData['senderName'],
            onAccept: () async {
              print("User accepting invitation");
              // Store important data
              final String invitationDocId = invitationDoc.id;
              final String receiverId = invitationData['receiverId'];
              
              // Close dialog first
              Navigator.of(context).pop();
              
              try {
                print("Processing invitation acceptance");
                
                // Accept invitation - no dialog, just process it
                final conversationDetails = await InvitationManager().acceptInvitation(invitationDocId);
                print("Invitation accepted: $conversationDetails");
                
                if (conversationDetails != null) {
                  // Get current user data without any UI interactions
                  final userDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(receiverId)
                    .get();
                    
                  final userData = userDoc.data() as Map<String, dynamic>?;
                  
                  if (userData == null) {
                    print("User data is null");
                    return;
                  }
                  
                  // Get match data
                  final matchDoc = await FirebaseFirestore.instance
                    .collection('matches')
                    .doc(conversationDetails['matchId'])
                    .get();
                    
                  final matchData = matchDoc.data() as Map<String, dynamic>?;
                  
                  if (matchData == null) {
                    print("Match data is null");
                    return;
                  }
                  
                  // Create chat data
                  final chatMatchData = {
                    'conversationId': conversationDetails['conversationId'],
                    'currentUser': {
                      'id': receiverId,
                      'username': userData['username'] ?? 'User',
                      'momStage': userData['momStage'] ?? [],
                      'selectedQuestions': _combineQuestionSets(userData),
                    },
                    'matchedUser': {
                      'id': conversationDetails['senderId'],
                      'username': conversationDetails['senderName'],
                      'momStage': receiverId == matchData['userAId'] 
                        ? matchData['momStagesB'] 
                        : matchData['momStagesA'],
                      'selectedQuestions': receiverId == matchData['userAId']
                        ? matchData['selectedQuestionsB']
                        : matchData['selectedQuestionsA'],
                    },
                    'matchId': conversationDetails['matchId'],
                  };
                  
                  // Build current user object
                  final currentUserObj = types.User(
                    id: receiverId,
                    firstName: userData['username'] ?? 'User',
                  );
                  
                  print("Navigating to ChatPage using global navigator key...");
                  
                  // Use the global navigator key to navigate without context
                  navigatorKey.currentState?.pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                        conversationId: conversationDetails['conversationId'],
                        currentUser: currentUserObj,
                        matchData: chatMatchData,
                      ),
                    ),
                    (route) => false, // Remove all routes
                  );
                  
                  print("Navigation initiated with global key");
                } else {
                  print("Conversation details is null");
                }
              } catch (e) {
                print("Error handling invitation acceptance: $e");
              }
            },
            onDecline: () {
              final BuildContext contextRef = context;
              Navigator.of(context).pop(); // Close dialog
              
              // Decline invitation
              InvitationManager().declineInvitation(invitationDoc.id).then((_) {
                if (contextRef.mounted) {
                  ScaffoldMessenger.of(contextRef).showSnackBar(
                    const SnackBar(content: Text("Invitation declined")),
                  );
                }
              }).catchError((e) {
                if (contextRef.mounted) {
                  ScaffoldMessenger.of(contextRef).showSnackBar(
                    SnackBar(content: Text("Error declining invitation: $e")),
                  );
                }
              });
            },
          ),
        );
      }
    });
  }

  // Helper method to combine questionSet1 and questionSet2
List<String> _combineQuestionSets(Map<String, dynamic> userData) {
  List<String> combinedQuestions = [];
  
  if (userData.containsKey('questionSet1')) {
    combinedQuestions.addAll(List<String>.from(userData['questionSet1']));
  }
  
  if (userData.containsKey('questionSet2')) {
    combinedQuestions.addAll(List<String>.from(userData['questionSet2']));
  }
  
  return combinedQuestions;
}

  // This is the main method that we call when a users presses the button to make a new connection
  Future<void> _startNewConnection(BuildContext context) async {
    print("Make Another Connection button clicked");

    try {
      // Get current user's ID
      final String currentUserId = await _getCurrentUserId();
      print("Current user ID: $currentUserId");

      // Clear current matchData and set isWaiting to true
      await FirebaseFirestore.instance.collection('users').doc(currentUserId).update({
        'matchData': FieldValue.delete(), // Safe to delete as matches are stored in "matches" collection
        'isWaiting': true,
      });
      print("Current matchData cleared and isWaiting set to true");

      // ✅ Move Navigator.push INSIDE the try block
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const Loading()),
      );
    } catch (e) {
      print("Error starting new connection: $e");

      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

@override
Widget build(BuildContext context) {
  return FutureBuilder<String>(
    future: _getCurrentUserId(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return Scaffold(
          backgroundColor: const Color(0xFFF2EDE7),
          body: const Center(child: CircularProgressIndicator()),
        );
      }
      final String currentUserId = snapshot.data!;
      
      return Scaffold(
        backgroundColor: const Color(0xFFF2EDE7),
        body: SafeArea(
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(currentUserId)
                .snapshots(),
            builder: (context, userDataSnapshot) {
              // Get username from user data
              String username = "User";
              if (userDataSnapshot.hasData && userDataSnapshot.data != null) {
                final userData = userDataSnapshot.data!.data() as Map<String, dynamic>?;
                if (userData != null && userData.containsKey('username')) {
                  username = userData['username'];
                }
              }
              
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('matches')
                    .where('users', arrayContains: currentUserId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return Stack(
                      children: [
                        // User account header
                        UserAccountHeader(username: username),
                        
                        Center(
                          child: Text(
                            "No connections yet.",
                            style: TextStyle(
                              fontFamily: "Nuosu SIL",
                              fontSize: 18,
                            ),
                          ),
                        ),
                        
                        // Use the CustomDirectionTextBox without returning a Positioned
                        Positioned(
                          bottom: 40,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: CustomDirectionTextBox(
                              text: "Make Another Connection",
                              onTap: () => _startNewConnection(context),
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  final allUserIds = docs
                      .map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return [data['userAId'], data['userBId']];
                      })
                      .expand((ids) => ids)
                      .toSet()
                      .toList();

                  print("Dashboard: Need to check availability for: $allUserIds");

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .where(FieldPath.documentId, whereIn: allUserIds.isEmpty ? ['dummy'] : allUserIds)
                        .snapshots(),
                    builder: (context, usersSnapshot) {
                      // Create a map of user IDs to their availability status
                      Map<String, bool> userAvailability = {};

                      if (usersSnapshot.hasData) {
                        for (var userDoc in usersSnapshot.data!.docs) {
                          final userData = userDoc.data() as Map<String, dynamic>;
                          bool isInConversation = userData['isInConversation'] ?? false;
                          userAvailability[userDoc.id] = !isInConversation;
                          print("Dashboard: User ${userDoc.id} availability: ${!isInConversation}");
                        }
                      }

                      List<Widget> connectionCards = [];
                      DateTime now = DateTime.now();
                      // Loop over each match document
                      for (var doc in docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        final userAId = data['userAId'];
                        final userBId = data['userBId'];
                        final userAName = data['userAName'];
                        final userBName = data['userBName'];

                        // Calculate inactivity days
            int inactiveDays = 0;
            if (data.containsKey('lastConversationEnd')) {
              Timestamp lastConversationEnd = data['lastConversationEnd'];
              DateTime lastChatDate = lastConversationEnd.toDate();
              inactiveDays = now.difference(lastChatDate).inDays;
              
              // If more than 2 days inactive, skip this connection
              if (inactiveDays >= 2) {
                continue; // Skip this connection, it's too old
              }
            }
            
            // If there's never been a conversation (no lastConversationEnd),
            // check when the match was created
            else if (data.containsKey('matchedAt')) {
              Timestamp matchedAt = data['matchedAt'];
              DateTime matchDate = matchedAt.toDate();
              inactiveDays = now.difference(matchDate).inDays;
              
              // If match is more than 2 days old with no conversation, skip
              if (inactiveDays >= 2) {
                continue; // Skip this connection, it's too old
              }
            }

                        final bool isUserA = (userAId == currentUserId);
                        final String connectionName = isUserA ? userBName : userAName;
                        final String otherUserId = isUserA ? userBId : userAId;

                        // Get availability status
                        final bool isAvailable = userAvailability[otherUserId] ?? false;
                        print("Dashboard: Connection $connectionName (ID: $otherUserId) availability: $isAvailable");

                        // Create match data for the conversation
                        Map<String, dynamic> matchData = {
                          'id': doc.id,
                          'userAId': userAId,
                          'userBId': userBId,
                          'userAName': userAName,
                          'userBName': userBName,
                          'conversationId': data['conversationId'],
                          'momStagesA': data['momStagesA'],
                          'momStagesB': data['momStagesB'],
                          'selectedQuestionsA': data['selectedQuestionsA'],
                          'selectedQuestionsB': data['selectedQuestionsB'],
                        };

                        connectionCards.add(
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: GestureDetector(
                              onTap: () {
                                print("Dashboard: Card tapped for connection $connectionName");
                                if (isAvailable) {
                                  print("Dashboard: Sending invitation to $connectionName");
                                  
                                  // Show sending invitation indicator
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Sending chat invitation to $connectionName...")),
                                  );
                                  
                                  // Send invitation
                                  InvitationManager().sendInvitation(
                                    senderId: currentUserId,
                                    senderName: userAId == currentUserId ? userAName : userBName,
                                    receiverId: otherUserId,
                                    receiverName: connectionName,
                                    matchId: doc.id,
                                    conversationId: data['conversationId'],
                                  );
                                } else {
                                  print("Dashboard: Connection $connectionName is not available");
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("$connectionName is currently not available for chat.")),
                                  );
                                }
                              },
                              child: CustomConnectionCard(
                                connectionName: connectionName,
                                isAvailable: isAvailable,
                                inactiveDays: inactiveDays, // Pass inactivity days
                              ),
                            ),
                          ),
                        );
                      }

                      // Your existing layout code
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          // Add the UserAccountHeader widget
                          UserAccountHeader(username: username),
                          
                          // Heading near the top
                          Positioned(
                            top: 150,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Text(
                                "Your Connections",
                                style: const TextStyle(
                                  fontFamily: "Nuosu SIL",
                                  fontSize: 20,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF574F4E),
                                ),
                              ),
                            ),
                          ),
                          // Horizontally scrollable list of connection cards
                          Positioned(
                            top: 300,
                            left: 0,
                            right: 0,
                            child: SizedBox(
                              height: 200,
                              child: Center(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: connectionCards,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Bottom-aligned button to initiate a new connection
                          Positioned(
                            bottom: 40,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: GestureDetector(
                                onTap: () => _startNewConnection(context),
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minWidth: 0,
                                    maxWidth: 300,
                                    minHeight: 40,
                                    maxHeight: 40,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF2EDE7),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFFD7BFB8),
                                      width: 1,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color.fromRGBO(0, 0, 0, 0.25),
                                        offset: Offset(2, 2),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: const Center(
                                    child: Text(
                                      "Make Another Connection",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: "Nuosu SIL",
                                        fontSize: 14,
                                        color: Color(0xFF574F4E),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      );
    },
  );
}
}