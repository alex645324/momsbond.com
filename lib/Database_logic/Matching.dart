import 'package:cloud_firestore/cloud_firestore.dart';
import '../Database_logic/auth_manager.dart';




class Matching { 
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Retrieves a match for the current user from the 'users' collection.
  ///
  /// [currentUserId]: The ID of the current user.
  /// [momStages]: The current user's motherhood stages (e.g., ["pregnant?"]).
  /// [selectedQuestions]: List of questions the current user picked.
  /// [matchCycle]: 1 for a match with at least one common stage; 2 for a match with no common stage.
  ///
  /// Returns a Future that resolves to a map with keys "currentUser" and "matchedUser",
  /// or null if no match is found.
  static Future<Map<String, dynamic>?> getMatch({
    required String currentUserId, 
    required List<String> momStages,
    required List<String> selectedQuestions, 
    required int matchCycle, 
  }) async {
    try {
      // Updates: First, get the list of users this user has already matched with.
      print("checking for previous matches for userer $currentUserId");
      QuerySnapshot existingMatchesSnapshot = await _firestore
        .collection('matches')
        .where('users', arrayContains: currentUserId)
        .get();

      // Updates: Create a set of user IDs to exclude (users already matched with the current user).
      Set<String> excludedUserIds = {};
      for (var doc in existingMatchesSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['userAId'] == currentUserId) {
        excludedUserIds.add(data['userBId']);
        print("Excluding previous match: ${data['userBId']}");
      } else {
        excludedUserIds.add(data['userAId']);
        print("Excluding previous match: ${data['userAId']}");
      }
    }

    // Updates: always exlude the current user
    excludedUserIds.add(currentUserId);
    print("Total excluded users: $excludedUserIds"); 




      // regluar logic but with some changes- we are filtering out the excluded users 
      Query query;
      if (matchCycle == 1) {
        // For match cycle 1: Query for users whose momStage array contains any element
        // in the current user's momStages list and who are waiting.
        query = _firestore.collection('users')
          .where('isWaiting', isEqualTo: true)
          .where('momStage', arrayContainsAny: momStages);
          // .where(FieldPath.documentId, isNotEqualTo: currentUserId);
      } else {
        // For match cycle 2: Query for waiting users excluding the current user,
        // then filter client-side to pick one with no common stage.
        query = _firestore.collection('users')
          .where('isWaiting', isEqualTo: true);
          // .where(FieldPath.documentId, isNotEqualTo: currentUserId);
      }

      // Limit the result to a few candidates.
      QuerySnapshot snapshot = await query.limit(10).get();
      List<DocumentSnapshot> eligibleDocs = snapshot.docs;
      print("Found ${eligibleDocs.length} waiting users before filtering");

      // Filter out excluded users 
      eligibleDocs = eligibleDocs
        .where((doc) => !excludedUserIds.contains(doc.id))
        .toList();
      print("Found ${eligibleDocs.length} eligible users after filtering out previous matches");


      DocumentSnapshot? matchedDoc;
      if (matchCycle == 2) {
        // Client-side filtering: find the first candidate whose momStage array
        // does not share any element with the current user's momStages.
        for (var doc in eligibleDocs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          List<dynamic>? candidateStages = data['momStage'];
          bool hasCommon = false;
          if (candidateStages != null) {
            for (var stage in momStages) {
              if (candidateStages.contains(stage)) {
                hasCommon = true;
                break;
              }
            }
          }
          if (!hasCommon) {
            matchedDoc = doc;
            break;
          }
        }
      } else {
        if (eligibleDocs.isNotEmpty) {
          matchedDoc = eligibleDocs.first;
        }
      }

      if (matchedDoc != null) {
        final matchedUserData = matchedDoc.data() as Map<String, dynamic>;
        matchedUserData['id'] = matchedDoc.id;

        // Combine matched user's questionSet1 and questionSet2 into a single list:
        List<String> matchedUserQuestions = [];
        if (matchedUserData['questionSet1'] != null) {
          matchedUserQuestions.addAll(List<String>.from(matchedUserData['questionSet1']));
        }
        if (matchedUserData['questionSet2'] != null) {
          matchedUserQuestions.addAll(List<String>.from(matchedUserData['questionSet2']));
        }
        // Now matchedUserQuestions holds all of user B's selected questions.
        // Store it back into matchedUserData['selectedQuestions']:
        matchedUserData['selectedQuestions'] = matchedUserQuestions;

        // Fetch current user's data to get their username
        final currentUserDoc = await _firestore.collection('users').doc(currentUserId).get();
        final currentUserDataFromDb = currentUserDoc.data() as Map<String, dynamic>?; // Handle potential null
        final String currentUserName = currentUserDataFromDb?['username'] ?? 'Unknown';

        // Build out your matchData
        final currentUserData = {
          'id': currentUserId,
          'momStage': momStages,
          'selectedQuestions': selectedQuestions,
        };

        // 1) Create an ID for the conversation (if you plan to do a chat).
        final conversationId = _generateConversationId(currentUserId, matchedUserData['id']);

        // 2) Create a new doc in `matches` to store permanent record
        final matchRef = _firestore.collection('matches').doc();
        final now = DateTime.now();

        // In Matching.dart, look for the matchDocData initialization and ensure it includes:
final matchDocData = {
  'userAId': currentUserId,
  'userBId': matchedUserData['id'],
  'userAName': currentUserName,
  'userBName': matchedUserData['username'] ?? "NoName",
  'momStagesA': momStages,
  'momStagesB': matchedUserData['momStage'] ?? [],
  'selectedQuestionsA': selectedQuestions,
  'selectedQuestionsB': matchedUserQuestions,
  'conversationCount': 0, // This is the important line
  'matchedAt': now,
  'conversationId': conversationId,
  'users': [currentUserId, matchedUserData['id']],
};

        // 4) Write the doc to Firestore
        await matchRef.set(matchDocData);

    // Create perspective-specific match data for User A
    final combinedMatchDataForA = {
      'currentUser': { 
        'id': currentUserId, 
        'momStage': momStages, 
        'selectedQuestions': selectedQuestions, 
        'username': currentUserName, 
      },
      'matchedUser': {
        'id': matchedUserData['id'],
        'momStage': matchedUserData['momStage'], 
        'selectedQuestions': matchedUserQuestions,
        'username': matchedUserData['username'] ?? 'Unknown', 
      }, 
      'conversationId': conversationId, 
      'matchId': matchRef.id, 
    };

    // Create perspective-specific match data for User B
    final combinedMatchDataForB = {
      'currentUser': { 
        'id': matchedUserData['id'],
        'momStage': matchedUserData['momStage'], 
        'selectedQuestions': matchedUserQuestions,
        'username': matchedUserData['username'] ?? 'Unknown', 
      },
      'matchedUser': {
        'id': currentUserId, 
        'momStage': momStages, 
        'selectedQuestions': selectedQuestions, 
        'username': currentUserName, 
      }, 
      'conversationId': conversationId, 
      'matchId': matchRef.id, 
    };

    // Update User A's document
    await _firestore.collection('users').doc(currentUserId).update({
      'matchData': combinedMatchDataForA,
      'isWaiting': false,
      'isInConversation': true
    });

    // Update User B's document
    await _firestore.collection('users').doc(matchedUserData['id']).update({
      'matchData': combinedMatchDataForB,
      'isWaiting': false,
      'isInConversation': true
    });

    return combinedMatchDataForA; // Return User A's perspective since they initiated the match
  } else {
        print('No match found for user $currentUserId in match cycle $matchCycle.');
        return null;
      }
    } catch (e) {
      print("Error in getMatch: $e");
      return null;
    }
  }



  //Cleanup Method: 
  static Future<void> cleanupUserStatus(String userId) async { 
    await _firestore.collection('users').doc(userId).update({
      'isWaiting': false, 
      'isInConversation': false, 
      'matchData': FieldValue.delete()
    });
    print("Cleanup completed- User status reset to available");
  }

  // Status reset for new match: 
  static Future<void> prepareForNewMatch(String userId) async { 
    await _firestore.collection('users').doc(userId).update({
      'isWaiting': true, 
      'isInConversation': false, 
      'matchData': FieldValue.delete()
    });
    print("User status updated to waiting for match");
  }







  static String _generateConversationId(String uid1, String uid2) {
    final sortedIds = [uid1, uid2]..sort();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return 'conversation_${sortedIds[0]}_${sortedIds[1]}_$timestamp';
  }

  static Future<Map<String, dynamic>?> createMatch(String currentUserId, String matchedUserId) async {
    final conversationId = _generateConversationId(currentUserId, matchedUserId);
    
    // Get both users' data
    final currentUserData = await _firestore.collection('users').doc(currentUserId).get();
    final matchedUserData = await _firestore.collection('users').doc(matchedUserId).get();

    if (!currentUserData.exists || !matchedUserData.exists) return null;

    final matchData = {
      'conversationId': conversationId,
      'currentUser': currentUserData.data(),
      'matchedUser': matchedUserData.data(),
      'startTime': FieldValue.serverTimestamp(),
    };

    // Initialize conversation with timer
    await ConversationManager().initializeConversation(
      conversationId: conversationId,
      participants: [currentUserId, matchedUserId],
      matchData: matchData,
    );

    return matchData;
  }
}

