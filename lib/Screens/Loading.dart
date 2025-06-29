import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'ChatPage.dart';
import '../Database_logic/Matching.dart';
import '../Database_logic/auth_manager.dart';

class Loading extends StatefulWidget {
  const Loading({Key? key}) : super(key: key);

  @override
  _LoadingState createState() => _LoadingState();
}

class _LoadingState extends State<Loading> {
  final AuthManager _authManager = AuthManager();
  StreamSubscription<DocumentSnapshot>? _userSubscription;

  @override
  void initState() {
    super.initState();
    // Attach a real-time listener to the current user's document.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenForMatchUpdates();
      _attemptMatchOnce();
    });
  }

  // Listen for real-time updates on the user's document.
  void _listenForMatchUpdates() {
    final String currentUserId = _authManager.getUserId();
    _userSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .listen((docSnapshot) {
      final data = docSnapshot.data() as Map<String, dynamic>?;
      if (data != null && data.containsKey('matchData')) {
        print("Listener detected matchData update for user $currentUserId.");
        _navigateToChat(data['matchData']);
      }
    });
  }

  // Call the matching service once to trigger a match.
  Future<void> _attemptMatchOnce() async {
    // Retrieve the current user data from Firestore.
    final userData = await _authManager.getUserData();
    if (userData == null) {
      print("No user data found for the current user.");
      return;
    }
    
    // Extract necessary fields.
    final String currentUserId = _authManager.getUserId();
    final List<String> momStages = userData['momStage'] != null
        ? List<String>.from(userData['momStage'])
        : [];
    final String username = userData['username'] ?? "User";

    // Combine question sets.
    List<String> selectedQuestions = [];
    if (userData.containsKey('questionSet1')) {
      selectedQuestions.addAll(List<String>.from(userData['questionSet1']));
    }
    if (userData.containsKey('questionSet2')) {
      selectedQuestions.addAll(List<String>.from(userData['questionSet2']));
    }

    // Mark the user as waiting.
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .update({'isWaiting': true});
    print("User $currentUserId marked as waiting.");

    // Define match cycle (for now, assume first match cycle).
    final int matchCycle = 1;
    print("Attempting to get a match for user $currentUserId with momStages $momStages");

    // Call the matching service once.
    final matchData = await Matching.getMatch(
      currentUserId: currentUserId,
      momStages: momStages,
      selectedQuestions: selectedQuestions,
      matchCycle: matchCycle,
    );

    if (matchData != null) {
      print("Match found (from initial attempt): $matchData");
      // Note: We do not immediately navigate here; we wait for the real-time listener
      // to catch the update. This ensures both users navigate at nearly the same time.
    } else {
      print("No match found yet; waiting for match update via listener.");
    }
  }

void _navigateToChat(dynamic matchData) { 
  final String currentUserId = _authManager.getUserId();
  //Cancel subscription to avoid duplicate navigation 
  _userSubscription?.cancel();

  // Retrieve conversationId from matchData
  final String conversationId = matchData['conversationId'];

  // Build currentUser
  final String username = (matchData['currentUser']?['username']?? "User"). toString();
  final types.User currentUser = types.User(id: currentUserId, firstName: username);

  Navigator.pushReplacement(
    context, 
    MaterialPageRoute(
      builder: (context) => ChatPage(
        conversationId: conversationId,
        currentUser: currentUser, 
        matchData: matchData, 
      ),
    ),
  );
}


  @override 
  void dispose() { 
    _userSubscription?.cancel();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2EDE7),
      body: Center(
        child: Container(
          width: 393,
          height: 852,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                Text(
                  "Finding someone who understands you...",
                  style: TextStyle(
                    fontFamily: "Nunito",
                    fontSize: 20,
                    fontWeight: FontWeight.normal,
                    color: Color(0xFF574F4E),
                  ),
                ),
                SizedBox(height: 20),
                Image(
                  image: AssetImage('assets/images/flower-image.png'),
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


