import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Dashboard.dart';
import '../database_logic/auth_manager.dart';

class ChatPage extends StatefulWidget {
  final String conversationId;
  final types.User currentUser;
  final Map<String, dynamic> matchData;

  const ChatPage({
    Key? key,
    required this.conversationId,
    required this.currentUser,
    required this.matchData,
  }) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

// this class stores all chat messages 
// connection to firebase
// and a timer to end the chat after a certain duration 

class _ChatPageState extends State<ChatPage> {
  late StreamSubscription<DocumentSnapshot> _timerSubscription;
  Timer? _localTimer;
  bool _matchDataUpdated = false;
  List<types.Message> _messages = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _setupTimerListener();
    _loadMessages();
  }

  // In ChatPage.dart, update _initializeChat method to not load previous messages
Future<void> _initializeChat() async {
  // Initialize conversation if not already done
  if (!_matchDataUpdated) {
    await ConversationManager().initializeConversation(
      conversationId: widget.conversationId,
      participants: [
        widget.matchData['currentUser']['id'],
        widget.matchData['matchedUser']['id']
      ],
      matchData: widget.matchData,
    );
    _matchDataUpdated = true;
    
    // Clear any existing messages in the conversation
    try {
      // Don't load previous messages, but ensure the collection exists
      print("Initializing chat without loading previous messages");
    } catch (e) {
      print("Error initializing chat: $e");
    }
  }
}

  // In ChatPage.dart, update the _setupTimerListener method to include more debug logging
void _setupTimerListener() {
  print("Setting up timer listener for conversation: ${widget.conversationId}");
  _timerSubscription = _firestore
      .collection('conversations')
      .doc(widget.conversationId)
      .snapshots()
      .listen((doc) {
    if (!doc.exists) {
      print("Conversation document does not exist");
      return;
    }

    final data = doc.data() as Map<String, dynamic>;
    final endTimeMillis = data['endTime'] as int;
    final status = data['status'] as String;

    final endTime = DateTime.fromMillisecondsSinceEpoch(endTimeMillis);
    final now = DateTime.now();
    final timeLeft = endTime.difference(now).inSeconds;

    print("Conversation status: $status, time left: $timeLeft seconds");

    if (status == 'archived') {
      print("Conversation is archived, ending now");
      _onConversationEnd();
      return;
    }

    if (now.isAfter(endTime)) {
      print("Conversation time has expired, ending now");
      _onConversationEnd();
    } else {
      // Set local timer for UI updates
      _localTimer?.cancel();
      _localTimer = Timer(endTime.difference(now), () {
        print("Local timer triggered, ending conversation");
        _onConversationEnd();
      });
      print("Set local timer to end in ${endTime.difference(now).inMinutes} minutes");
    }
  });
}

  // In ChatPage.dart, update the _loadMessages method to only load new messages
void _loadMessages() {
  // Get the current timestamp when the user joins
  final joinTimestamp = DateTime.now().millisecondsSinceEpoch;
  
  _firestore
      .collection('conversations')
      .doc(widget.conversationId)
      .collection('messages')
      .where('createdAt', isGreaterThanOrEqualTo: joinTimestamp) // Only get messages from now on
      .orderBy('createdAt', descending: true)
      .snapshots()
      .listen((snapshot) {
    List<types.Message> messages = snapshot.docs.map((doc) {
      final data = doc.data();
      return types.TextMessage(
        author: types.User(id: data['authorId'] as String),
        createdAt: data['createdAt'] as int,
        id: doc.id,
        text: data['text'] as String,
      );
    }).toList();

    setState(() {
      _messages = messages;
    });
  });
}

  void _handleSendPressed(types.PartialText message) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final messageData = {
      'authorId': widget.currentUser.id,
      'text': message.text,
      'createdAt': timestamp,
    };

    final conversationRef = _firestore
        .collection('conversations')
        .doc(widget.conversationId);

    // Ensure the conversation doc exists and has the participants field
    if (!_matchDataUpdated) {
      await conversationRef.set({
        'participants': [
          widget.matchData['currentUser']['id'],
          widget.matchData['matchedUser']['id']
        ],
        'matchId': widget.matchData['matchId'],
        'momStagesA': widget.matchData['currentUser']['momStage'],
        'momStagesB': widget.matchData['matchedUser']['momStage'],
        'selectedQuestionsA': widget.matchData['currentUser']['selectedQuestions'],
        'selectedQuestionsB': widget.matchData['matchedUser']['selectedQuestions'] ?? [],
        'status': 'active',
      }, SetOptions(merge: true));

      _matchDataUpdated = true;
    }

    // Add the new message to the 'messages' subcollection
    await conversationRef.collection('messages').add(messageData);
  }

// In ChatPage.dart, update the _onConversationEnd method to fix the ID issue
void _onConversationEnd() async {
  print("========== CONVERSATION ENDED ==========");
  
  // Get user IDs directly from matchData instead of widget.currentUser.id
  final String currentUserId = widget.matchData['currentUser']['id'];
  final String currentUserName = widget.matchData['currentUser']['username'] ?? "Unknown";
  
  // The problem is here - the matchedUser id is incorrectly being set
  // Let's fix it by using the widget.matchData properly
  
  // First, log the full match data to see what's available
  print("DEBUG - Full matchData: ${widget.matchData}");
  
  final String matchedUserId = widget.matchData['matchedUser']['id'];
  final String matchedUserName = widget.matchData['matchedUser']['username'] ?? "Unknown";
  final String matchId = widget.matchData['matchId'];
  
  print("DEBUG - CURRENT USER: ID=$currentUserId, Name=$currentUserName");
  print("DEBUG - MATCHED WITH: ID=$matchedUserId, Name=$matchedUserName");
  print("DEBUG - Match ID: $matchId");
  print("DEBUG - Full matchData: ${widget.matchData}");
  
  // First update the conversation status
  await ConversationManager().endConversation(widget.conversationId);
  
  // Update both users' status to not be in conversation
  await FirebaseFirestore.instance.collection('users').doc(currentUserId).update({
    'isInConversation': false,
    'activeConversationId': null,
  });
  
  await FirebaseFirestore.instance.collection('users').doc(matchedUserId).update({
    'isInConversation': false,
    'activeConversationId': null,
  });
  
  // Check if this is the first conversation between these users
  bool isFirstConversation = false;
  try {
    final matchDoc = await FirebaseFirestore.instance
        .collection('matches')
        .doc(matchId)
        .get();
    
    if (matchDoc.exists) {
      final matchData = matchDoc.data() as Map<String, dynamic>;
      final int conversationCount = matchData['conversationCount'] ?? 1;
      isFirstConversation = conversationCount <= 1;
      
      print("DEBUG - Is first conversation: $isFirstConversation (count: $conversationCount)");
      print("DEBUG - Match document data: $matchData");
      
      // Update the conversation count
      await FirebaseFirestore.instance
          .collection('matches')
          .doc(matchId)
          .update({
        'conversationCount': FieldValue.increment(1),
        'lastConversationEnd': FieldValue.serverTimestamp(),
      });
    }
  } catch (e) {
    print("Error checking if first conversation: $e");
    isFirstConversation = true;
  }
  
    // When showing the feedback dialog, make sure we're passing the right IDs
  if (mounted) {
    if (isFirstConversation) {
      print("DEBUG - Showing feedback dialog for $currentUserName about keeping connection with $matchedUserName");
      
      // Show feedback dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return FeedbackDialog(
            matchedUserName: matchedUserName,
            matchedUserId: matchedUserId,  // Make sure this is the correct ID
            currentUserId: currentUserId,
            conversationId: widget.conversationId,
            matchId: matchId,
            onComplete: () {
              print("DEBUG - Feedback completed, navigating to dashboard");
              if (mounted) {
                _navigateToDashboard();
              }
            },
          );
        },
      );
    } else {
      _navigateToDashboard();
    }
  }
}

  void _navigateToDashboard() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Dashboard()),
      );
    }
  }

  @override
void dispose() {
  _timerSubscription.cancel();
  _localTimer?.cancel();
  
  // Update user status when leaving the chat
  FirebaseFirestore.instance.collection('users').doc(widget.matchData['currentUser']['id']).update({
    'isInConversation': false,
    'activeConversationId': null,
  });
  
  super.dispose();
} 

  // In ChatPage.dart, update the build method to include a debug button
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      title: Text(''), // Empty title instead of "Chat with [username]"
      actions: [
        IconButton(
          icon: const Icon(Icons.timer_off),
          tooltip: 'End conversation (debug)',
          onPressed: () {
            print("Debug: Manually ending conversation");
            _onConversationEnd();
          },
        ),
      ],
    ),
    body: Chat(
      messages: _messages,
      onSendPressed: _handleSendPressed,
      user: widget.currentUser,
      theme: DefaultChatTheme(
        backgroundColor: const Color(0xFFF2EDE7),
        sentMessageBodyTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
        receivedMessageBodyTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 16,
        ),
        primaryColor: Colors.blue,
        secondaryColor: Colors.grey,
        messageBorderRadius: 16,
      ),
    ),
  );
}
}


// In ChatPage.dart, update the FeedbackDialog class by removing the const keyword
class FeedbackDialog extends StatefulWidget {
  final String matchedUserName;
  final String matchedUserId;
  final String currentUserId;
  final String conversationId;
  final String matchId;
  final VoidCallback onComplete;

  // Remove const here
  FeedbackDialog({
    Key? key,
    required this.matchedUserName,
    required this.matchedUserId,
    required this.currentUserId,
    required this.conversationId,
    required this.matchId,
    required this.onComplete,
  }) : super(key: key) {
    // Add debug print when dialog is constructed
    print("DEBUG - FeedbackDialog created:");
    print("DEBUG - Current User ID: $currentUserId");
    print("DEBUG - Matched User ID: $matchedUserId");
    print("DEBUG - Matched User Name: $matchedUserName");
    print("DEBUG - Match ID: $matchId");
  }

  @override
  _FeedbackDialogState createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  bool _isSubmitting = false;

  Future<void> _saveConnectionPreference(bool keepConnection) async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      // Update the match document with the user's preference
      await FirebaseFirestore.instance
          .collection('matches')
          .doc(widget.matchId)
          .update({
        'feedback': {
          'timestamp': FieldValue.serverTimestamp(),
          '${widget.currentUserId}_preference': keepConnection ? 'keep' : 'remove',
        },
      });

      print('Feedback saved: User ${widget.currentUserId} chose to ${keepConnection ? "keep" : "remove"} connection with ${widget.matchedUserId}');

      // If they chose to keep the connection, make sure the match isn't deleted
      if (keepConnection) {
        await FirebaseFirestore.instance
            .collection('matches')
            .doc(widget.matchId)
            .update({
          'active': true,
          'lastInteractionDate': FieldValue.serverTimestamp(),
        });
        
        print('Match marked as active for future connections');
      }
      
      // Complete the feedback process
      widget.onComplete();
    } catch (e) {
      print('Error saving feedback: $e');
      // Even if there's an error, proceed to dashboard
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: contentBox(context),
    );
  }

  Widget contentBox(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: const Color(0xFFF2EDE7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFD7BFB8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(0, 10),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'Conversation Ended',
            style: const TextStyle(
              fontFamily: "Nuosu SIL",
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Color(0xFF574F4E),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            'Do you wish to keep a connection with ${widget.matchedUserName}?',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: "Nuosu SIL",
              fontSize: 16,
              color: Color(0xFF574F4E),
            ),
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              _isSubmitting
                  ? const CircularProgressIndicator()
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        // No button
                        GestureDetector(
                          onTap: () => _saveConnectionPreference(false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFD7BFB8),
                                width: 1,
                              ),
                            ),
                            child: const Text(
                              'No',
                              style: TextStyle(
                                fontFamily: "Nuosu SIL",
                                fontSize: 16,
                                color: Color(0xFF574F4E),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Yes button
                        GestureDetector(
                          onTap: () => _saveConnectionPreference(true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2EDE7),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFD7BFB8),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  offset: const Offset(0, 2),
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: const Text(
                              'Yes',
                              style: TextStyle(
                                fontFamily: "Nuosu SIL",
                                fontSize: 16,
                                color: Color(0xFF574F4E),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ],
      ),
    );
  }
}






