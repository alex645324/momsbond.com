import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../Database_logic/simple_auth_manager.dart';
import '../Database_logic/invitation_manager.dart';
import '../Database_logic/simple_matching.dart';
import '../models/dashboard_model.dart';
import '../models/messages_model.dart';

class DashboardViewModel extends ChangeNotifier {
  final SimpleAuthManager _authManager = SimpleAuthManager();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DashboardModel _dashboardModel = const DashboardModel();
  
  // Stream subscription
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSubscription;
  Timer? _refreshTimer;  // Add timer for periodic updates

  DashboardModel get dashboardModel => _dashboardModel;
  bool get isLoading => _dashboardModel.isLoading;
  String? get errorMessage => _dashboardModel.errorMessage;
  bool get hasError => _dashboardModel.hasError;
  String get username => _dashboardModel.username;
  List<ConnectionData> get connections => _dashboardModel.connections;
  List<ConnectionData> get activeConnections => connections.where((c) => c.isActive).toList();
  bool get hasConnections => _dashboardModel.hasConnections;
  List<MatchData> get availableMatches => _dashboardModel.availableMatches;
  bool get isMatching => _dashboardModel.isMatching;
  String get matchingStatus => _dashboardModel.matchingStatus;

  void _updateState(DashboardModel newModel) {
    _dashboardModel = newModel;
    notifyListeners();
  }

  Future<void> initialize() async {
    print("DashboardViewModel: Initializing...");
    
    try {
      _updateState(_dashboardModel.copyWith(isLoading: true));
      
      // CLEANUP: Ensure user is marked as NOT in conversation when on dashboard
      await _ensureUserNotInConversation();
      
      // Load both available matches AND existing connections
      await Future.wait([
        _loadMatches(),
        _loadConnections(), // NEW: Load past connections
        _cleanupOldReconnectionMatches(), // Clean up temporary matches
      ]);
      
      // Set up real-time listener for user status
      _setupUserStatusListener();
      
      // Set up periodic refresh timer (every 30 seconds)
      _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        _refreshConnections();
      });
      
      _updateState(_dashboardModel.copyWith(isLoading: false));
      print("DashboardViewModel: Initialization complete");
    } catch (e) {
      print("DashboardViewModel: Error during initialization: $e");
      _updateState(_dashboardModel.copyWith(
        isLoading: false,
        errorMessage: "Error loading dashboard: $e",
      ));
    }
  }

  /// Cleanup method to ensure user status is correct when on dashboard
  Future<void> _ensureUserNotInConversation() async {
    try {
      final userId = _authManager.getUserId();
      if (userId == null) return;

      print("DashboardViewModel: Cleaning up user conversation status");
      
      // Set user as NOT in conversation since they're on dashboard
      await _firestore.collection('users').doc(userId).update({
        'isInConversation': false,
        'isWaiting': false, // Also reset waiting status
        'lastStatusUpdate': FieldValue.serverTimestamp(),
        'lastActiveTimestamp': FieldValue.serverTimestamp(), // Update active timestamp
        // Remove any temporary match data
        'matchData': FieldValue.delete(),
        'activeMatchId': FieldValue.delete(),
      });
      
      print("DashboardViewModel: User status cleaned up - isInConversation set to false");
      
    } catch (e) {
      print("DashboardViewModel: Error cleaning up user status: $e");
      // Don't throw - allow dashboard to continue loading
    }
  }

  Future<void> _loadMatches() async {
    try {
      print("DashboardViewModel: Loading matches...");
      
      final userId = _authManager.getUserId();
      if (userId == null) {
        throw Exception("User not authenticated");
      }

      // Get user's stage and preferences
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw Exception("User data not found");
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      
      // Update the dashboard username once (if not already set or changed)
      final fetchedUsername = userData['username'] ?? 'User';
      if (fetchedUsername != _dashboardModel.username) {
        _updateState(_dashboardModel.copyWith(username: fetchedUsername));
      }
      
      // Handle momStage as List<String> since that's how it's stored in Firestore
      List<String> userStages = [];
      try {
        final momStageData = userData['momStage'];
        if (momStageData is List) {
          userStages = List<String>.from(momStageData);
        } else if (momStageData is String) {
          userStages = [momStageData];
        }
      } catch (e) {
        print("DashboardViewModel: Error processing user's momStage: $e");
      }
      
      if (userStages.isEmpty) {
        throw Exception("User stage not set");
      }

      // Query for potential matches using array-contains-any for matching stages
      final matchQuery = await _firestore
          .collection('users')
          .where('momStage', arrayContainsAny: userStages)
          .where('isInConversation', isEqualTo: false)
          .limit(10)
          .get();

      final matches = matchQuery.docs
          .where((doc) => doc.id != userId) // Exclude self
          .map((doc) {
            final data = doc.data();
            
            // Safely convert momStage List<String> to display String
            String momStageDisplay = '';
            try {
              final momStageData = data['momStage'];
              if (momStageData is List) {
                final momStageList = List<String>.from(momStageData);
                momStageDisplay = momStageList.isNotEmpty ? momStageList.join(', ') : 'Not specified';
              } else if (momStageData is String) {
                momStageDisplay = momStageData;
              } else {
                momStageDisplay = 'Not specified';
              }
            } catch (e) {
              print("DashboardViewModel: Error processing momStage for user ${doc.id}: $e");
              momStageDisplay = 'Not specified';
            }
            
            return MatchData(
              userId: doc.id,
              username: data['username'] ?? 'Unknown',
              momStage: momStageDisplay,
              lastActive: (data['lastStatusUpdate'] as Timestamp?)?.toDate() ?? DateTime.now(),
              isOnline: data['isInConversation'] == false,
            );
          })
          .toList();

      _updateState(_dashboardModel.copyWith(availableMatches: matches));
      print("DashboardViewModel: Loaded ${matches.length} matches");
    } catch (e) {
      print("DashboardViewModel: Error loading matches: $e");
      rethrow;
    }
  }

  void _setupUserStatusListener() {
    final userId = _authManager.getUserId();
    if (userId == null) return;

    _userSubscription = _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final isInConversation = data['isInConversation'] as bool? ?? false;
        final pendingChat = data['pendingChat'] as bool? ?? false;
        final hasInvitation = data['hasInvitation'] as bool? ?? false;

        // Check for incoming invitations
        if (hasInvitation) {
          print("DashboardViewModel: User has incoming invitation - fetching invitation details");
          _handleIncomingInvitation(userId);
        }

        // Check for pending chat (after invitation acceptance)
        if (pendingChat) {
          print("DashboardViewModel: User has pending chat - navigation handled by invitation system");
          _handlePendingChat(userId);
        }
      }
    });
  }

  /// Handle incoming invitation by fetching and showing invitation dialog
  Future<void> _handleIncomingInvitation(String userId) async {
    try {
      // Fetch pending invitations for this user
      final invitationsQuery = await _firestore
          .collection('invitations')
          .where('receiverId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (invitationsQuery.docs.isNotEmpty) {
        final invitationDoc = invitationsQuery.docs.first;
        final invitationData = invitationDoc.data();
        
        // Create InvitationData object
        final invitation = InvitationData.fromFirebaseData(invitationDoc.id, invitationData);
        
        // Trigger invitation dialog through callback
        print("DashboardViewModel: Showing invitation dialog for invitation from ${invitation.senderName}");
        _invitationCallback?.call(invitation);
      }
    } catch (e) {
      print("DashboardViewModel: Error handling incoming invitation: $e");
    }
  }

  /// Handle pending chat by navigating to conversation
  Future<void> _handlePendingChat(String userId) async {
    try {
      print("DashboardViewModel: Processing pending chat for user $userId");
      
      // Clear the pending chat flag (keep activeMatchId for navigation)
      await _firestore.collection('users').doc(userId).update({
        'pendingChat': false,
      });
      
      // Get the active match to navigate to conversation
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final activeMatchId = userData['activeMatchId'] as String?;
        
        print("DashboardViewModel: Found activeMatchId: $activeMatchId for user $userId");
        
        if (activeMatchId != null) {
          // Get match data for conversation initialization
          final matchDoc = await _firestore.collection('matches').doc(activeMatchId).get();
          if (matchDoc.exists) {
            final matchData = matchDoc.data() as Map<String, dynamic>;
            
            // Add the match document ID to the match data
            matchData['_matchDocId'] = activeMatchId;
            
            // Create conversation init data
            final initData = _createConversationInitData(matchData, userId);
            
            // Navigate to conversation
            print("DashboardViewModel: Navigating to conversation for match $activeMatchId");
            print("DashboardViewModel: ConversationInitData: ${initData.conversationId}");
            _navigationCallback?.call(initData);
          } else {
            print("DashboardViewModel: Match document not found for activeMatchId: $activeMatchId");
          }
        } else {
          print("DashboardViewModel: No activeMatchId found for user $userId");
        }
      } else {
        print("DashboardViewModel: User document not found for userId: $userId");
      }
    } catch (e) {
      print("DashboardViewModel: Error handling pending chat: $e");
    }
  }

  /// Create ConversationInitData from match data
  ConversationInitData _createConversationInitData(Map<String, dynamic> matchData, String currentUserId) {
    // Determine if current user is userA or userB
    final isUserA = matchData['userAId'] == currentUserId;
    
    final currentUserData = isUserA ? {
      'id': matchData['userAId'],
      'username': matchData['userAName'],
      'momStage': matchData['momStagesA'] ?? [],
      'selectedQuestions': matchData['selectedQuestionsA'] ?? [],
    } : {
      'id': matchData['userBId'],
      'username': matchData['userBName'],
      'momStage': matchData['momStagesB'] ?? [],
      'selectedQuestions': matchData['selectedQuestionsB'] ?? [],
    };
    
    final matchedUserData = isUserA ? {
      'id': matchData['userBId'],
      'username': matchData['userBName'],
      'momStage': matchData['momStagesB'] ?? [],
      'selectedQuestions': matchData['selectedQuestionsB'] ?? [],
    } : {
      'id': matchData['userAId'],
      'username': matchData['userAName'],
      'momStage': matchData['momStagesA'] ?? [],
      'selectedQuestions': matchData['selectedQuestionsA'] ?? [],
    };
    
    // Use stored conversation ID from match document, or generate one if not present
    final conversationId = matchData['conversationId'] ?? _generateConversationId(currentUserId, 
        isUserA ? matchData['userBId'] : matchData['userAId']);
    
    // Get the actual match document ID (we need to pass this from _handlePendingChat)
    final matchId = matchData['_matchDocId'] ?? 'unknown_match_id';
    
    // Check if this is a past connection (reconnection)
    final bool isPastConnection = matchData['sessionType'] == 'reconnection';
    
    return ConversationInitData(
      conversationId: conversationId,
      currentUser: CurrentUserData.fromMap(currentUserData),
      matchedUser: MatchedUserData.fromMap(matchedUserData),
      matchId: matchId,
      isPastConnection: isPastConnection,
    );
  }

  /// Generate conversation ID
  String _generateConversationId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return 'conversation_${sortedIds[0]}_${sortedIds[1]}_$timestamp';
  }



  void Function(ConversationInitData)? _navigationCallback;
  
  void setNavigationCallback(void Function(ConversationInitData) callback) {
    _navigationCallback = callback;
  }

  Future<void> requestMatch(String targetUserId, BuildContext context) async {
    try {
      print("DashboardViewModel: Starting automatic matching for current user");
      
      _updateState(_dashboardModel.copyWith(
        isMatching: true,
        matchingStatus: "Finding match...",
      ));

      final userId = _authManager.getUserId();
      if (userId == null) {
        throw Exception("User not authenticated");
      }

      // Get current user data for matching
      final userData = await _authManager.getUserData();
      if (userData == null) {
        throw Exception("User data not found");
      }

      final momStages = List<String>.from(userData['momStage'] ?? []);
      final selectedQuestions = <String>[];
      
      // Extract questions if available
      if (userData['questionSet1'] != null) {
        selectedQuestions.addAll(List<String>.from(userData['questionSet1']));
      }
      if (userData['questionSet2'] != null) {
        selectedQuestions.addAll(List<String>.from(userData['questionSet2']));
      }

      // First mark user as waiting for the matching system
      await SimpleMatching.resetUserForMatching(userId);

      // Use automatic matching (finds any compatible user, not specific targetUserId)
      final matchData = await SimpleMatching.findMatch(
        currentUserId: userId,
        momStages: momStages,
        selectedQuestions: selectedQuestions,
      );

      if (matchData != null) {
        _updateState(_dashboardModel.copyWith(
          isMatching: false,
          matchingStatus: "",
        ));
        
        // Navigate to chat immediately
        final initData = ConversationInitData.fromChatPageData(
          matchData, 
          matchData['matchId']
        );
        _navigationCallback?.call(initData);
        
      } else {
        _updateState(_dashboardModel.copyWith(
          isMatching: false,
          matchingStatus: "",
          errorMessage: "No suitable match found at this time",
        ));
      }
    } catch (e) {
      print("DashboardViewModel: Error creating match: $e");
      _updateState(_dashboardModel.copyWith(
        isMatching: false,
        matchingStatus: "",
        errorMessage: "Error finding match: $e",
      ));
    }
  }

  // Note: acceptMatch method removed - SimpleMatching creates instant matches without manual acceptance

  void cancelMatching() {
    _updateState(_dashboardModel.copyWith(
      isMatching: false,
      matchingStatus: "",
    ));
  }

  Future<void> refreshMatches() async {
    try {
      await _loadMatches();
    } catch (e) {
      _updateState(_dashboardModel.copyWith(
        errorMessage: "Error refreshing matches: $e",
      ));
    }
  }

  void clearError() {
    if (_dashboardModel.errorMessage != null) {
      _updateState(_dashboardModel.copyWith(errorMessage: null));
    }
  }

  /// Public method to ensure user is marked as not in conversation
  /// Can be called anytime to clean up user status
  Future<void> ensureUserAvailableForMatching() async {
    await _ensureUserNotInConversation();
  }

  // TODO: FUTURE FEATURE - Add profile editing methods for returning users
  // These methods would allow users to update their profile after initial onboarding:
  // 
  // Future<bool> updateMotherStage(List<String> newStages) async {
  //   // Update user's mother stage in Firestore
  //   // Recalculate matches based on new stage
  //   // Update local state and UI
  // }
  //
  // Future<bool> updateChallengeQuestions(Map<String, List<String>> newQuestions) async {
  //   // Update user's challenge question preferences
  //   // Refresh potential matches
  //   // Update matching algorithm inputs
  // }
  //
  // Future<void> navigateToProfileEdit() async {
  //   // Navigate to profile editing screen
  //   // This would reuse StageSelectionView and ChallengesView in "edit mode"
  // }

  // STUB METHODS - Adding missing methods as simple stubs to satisfy interface
  
  /// Set notification callback (stub)
  void setNotificationCallback(Function(String message) callback) {
    // Simple stub - just store the callback
    _notificationCallback = callback;
  }
  Function(String message)? _notificationCallback;

  /// Set invitation callback (stub)
  void setInvitationCallback(Function(InvitationData invitation) callback) {
    // Simple stub - just store the callback
    _invitationCallback = callback;
  }
  Function(InvitationData invitation)? _invitationCallback;

  /// Accept invitation (proper implementation)
  Future<void> acceptInvitation(InvitationData invitation) async {
    try {
      print("DashboardViewModel: Accepting invitation from ${invitation.senderName}");
      
      // Use InvitationManager to accept the invitation
      final conversationData = await InvitationManager().acceptInvitation(invitation.id);
      
      if (conversationData != null) {
        print("DashboardViewModel: Invitation accepted successfully");
        _notificationCallback?.call("Joined conversation with ${invitation.senderName}");
        
        // The InvitationManager sets pendingChat=true for both users
        // The _handlePendingChat method will handle navigation
      } else {
        print("DashboardViewModel: Failed to accept invitation");
        _notificationCallback?.call("Error joining conversation");
      }
    } catch (e) {
      print("DashboardViewModel: Error accepting invitation: $e");
      _notificationCallback?.call("Error accepting invitation");
    }
  }

  /// Decline invitation (proper implementation)
  Future<void> declineInvitation(String invitationId) async {
    try {
      print("DashboardViewModel: Declining invitation: $invitationId");
      
      // Use InvitationManager to decline the invitation
      await InvitationManager().declineInvitation(invitationId);
      
      print("DashboardViewModel: Invitation declined successfully");
      _notificationCallback?.call("Invitation declined");
    } catch (e) {
      print("DashboardViewModel: Error declining invitation: $e");
      _notificationCallback?.call("Error declining invitation");
    }
  }

  /// Send invitation (updated implementation with availability check)
  Future<void> sendInvitation(ConnectionData connection) async {
    try {
      print("DashboardViewModel: Checking availability and sending invitation to ${connection.displayName}");
      
      final userId = _authManager.getUserId();
      if (userId == null) {
        throw Exception("User not authenticated");
      }

      // STEP 1: Check if target user is available (not in conversation)
      print("DashboardViewModel: Checking if ${connection.displayName} is available...");
      final targetUserDoc = await _firestore.collection('users').doc(connection.otherUserId).get();
      
      if (!targetUserDoc.exists) {
        _notificationCallback?.call("User ${connection.displayName} not found");
        return;
      }

      final targetUserData = targetUserDoc.data() as Map<String, dynamic>;
      final isTargetInConversation = targetUserData['isInConversation'] as bool? ?? false;
      final targetHasInvitation = targetUserData['hasInvitation'] as bool? ?? false;

      // Check if target user is busy
      if (isTargetInConversation) {
        print("DashboardViewModel: ${connection.displayName} is currently in a conversation");
        _notificationCallback?.call("${connection.displayName} is currently in a conversation. Try again later.");
        return;
      }

      // Check if target user already has a pending invitation
      if (targetHasInvitation) {
        print("DashboardViewModel: ${connection.displayName} already has a pending invitation");
        _notificationCallback?.call("${connection.displayName} already has a pending invitation. Please wait.");
        return;
      }

      // STEP 2: Check if sender (current user) is available
      final currentUserDoc = await _firestore.collection('users').doc(userId).get();
      if (currentUserDoc.exists) {
        final currentUserData = currentUserDoc.data() as Map<String, dynamic>;
        final isCurrentUserInConversation = currentUserData['isInConversation'] as bool? ?? false;
        
        if (isCurrentUserInConversation) {
          print("DashboardViewModel: Current user is already in a conversation");
          _notificationCallback?.call("You are currently in a conversation. End it first before starting a new one.");
          return;
        }
      }

      // STEP 3: Both users are available - CREATE NEW MATCH for fresh conversation
      print("DashboardViewModel: Both users available - creating new match for fresh conversation with ${connection.displayName}");

      // Get current user data for sender name and match creation
      final userData = await _authManager.getUserData();
      final senderName = userData?['username'] ?? 'User';

      // Create a new temporary match document for this conversation session
      final newMatchDoc = await _createReconnectionMatch(
        originalMatchId: connection.id,
        currentUserId: userId,
        otherUserId: connection.otherUserId,
        currentUserName: senderName,
        otherUserName: connection.displayName,
        originalMatchData: connection.matchData,
      );

      if (newMatchDoc == null) {
        _notificationCallback?.call("Error creating new conversation session");
        return;
      }

      // Send invitation with the NEW match ID, preserving existing conversation ID for past connections
      await InvitationManager().sendInvitation(
        senderId: userId,
        senderName: senderName,
        receiverId: connection.otherUserId,
        receiverName: connection.displayName,
        matchId: newMatchDoc, // Use NEW match ID instead of old one
        existingConversationId: connection.conversationId.isNotEmpty ? connection.conversationId : null, // Reuse existing conversation ID for past connections
      );
      
      _notificationCallback?.call("Invitation sent to ${connection.displayName}! Waiting for response...");
      print("DashboardViewModel: Invitation sent successfully to ${connection.displayName} with new match ID: $newMatchDoc");
      
    } catch (e) {
      print("DashboardViewModel: Error sending invitation: $e");
      _notificationCallback?.call("Error sending invitation: ${e.toString()}");
    }
  }

  /// Create a new match document for reconnection while maintaining link to original
  Future<String?> _createReconnectionMatch({
    required String originalMatchId,
    required String currentUserId,
    required String otherUserId,
    required String currentUserName,
    required String otherUserName,
    required Map<String, dynamic> originalMatchData,
  }) async {
    try {
      print("DashboardViewModel: Creating new match for reconnection (original: $originalMatchId)");
      
      // Get original match data for user details
      final originalMatchDoc = await _firestore.collection('matches').doc(originalMatchId).get();
      if (!originalMatchDoc.exists) {
        print("DashboardViewModel: Original match document not found");
        return null;
      }

      final originalData = originalMatchDoc.data() as Map<String, dynamic>;
      
      // Determine user A/B roles (current user can be either A or B)
      final bool isCurrentUserA = originalData['userAId'] == currentUserId;
      
      // Reuse the existing conversation ID from the original connection to maintain conversation history
      // For old matches without stored conversationId, use the original match ID as the conversation ID
      final sharedConversationId = originalData['conversationId'] ?? originalMatchId;
      
      // Create new match document with fresh state
      final newMatchRef = _firestore.collection('matches').doc();
      await newMatchRef.set({
        // User data (preserve original roles)
        'userAId': isCurrentUserA ? currentUserId : otherUserId,
        'userAName': isCurrentUserA ? currentUserName : otherUserName,
        'userBId': isCurrentUserA ? otherUserId : currentUserId,
        'userBName': isCurrentUserA ? otherUserName : currentUserName,
        
        // Preserve original user preferences
        'momStagesA': originalData['momStagesA'] ?? [],
        'momStagesB': originalData['momStagesB'] ?? [],
        'selectedQuestionsA': originalData['selectedQuestionsA'] ?? [],
        'selectedQuestionsB': originalData['selectedQuestionsB'] ?? [],
        
        // Fresh match state
        'users': [currentUserId, otherUserId],
        'matchedAt': FieldValue.serverTimestamp(),
        'active': true,
        'isReconnection': true, // Flag to indicate this is a reconnection
        'originalMatchId': originalMatchId, // Link to original match for strength tracking
        
        // Fresh conversation state (no lastConversationEnd)
        'connectionStrength': originalData['connectionStrength'] ?? 100,
        'totalConversations': (originalData['totalConversations'] ?? 0) + 1,
        
        // Store shared conversation ID so both users use the same one
        'conversationId': sharedConversationId,
        
        // Metadata
        'createdAt': FieldValue.serverTimestamp(),
        'sessionType': 'reconnection',
      });

      print("DashboardViewModel: Created new match document: ${newMatchRef.id} (reconnection from $originalMatchId)");
      return newMatchRef.id;

    } catch (e) {
      print("DashboardViewModel: Error creating reconnection match: $e");
      return null;
    }
  }

  /// Start new connection (stub)
  Future<void> startNewConnection(BuildContext context) async {
    try {
      // Simple stub implementation
      print("DashboardViewModel: Starting new connection");
      _notificationCallback?.call("Starting new connection...");
    } catch (e) {
      print("DashboardViewModel: Error starting new connection: $e");
      _notificationCallback?.call("Error starting new connection");
    }
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    _refreshTimer?.cancel();  // Cancel timer on dispose
    super.dispose();
  }

  /// Load existing connections from matches collection
  Future<void> _loadConnections() async {
    try {
      print("DashboardViewModel: Loading connections...");
      
      final userId = _authManager.getUserId();
      if (userId == null) {
        throw Exception("User not authenticated");
      }

      // Query matches collection for user's past connections
      // Split into two queries to avoid Firestore index issues
      
      // First: Get matches with conversation history (finished conversations)
      QuerySnapshot<Map<String, dynamic>> finishedMatches;
      try {
        finishedMatches = await _firestore
            .collection('matches')
            .where('users', arrayContains: userId)
            .where('lastConversationEnd', isGreaterThan: DateTime(2020)) // Only matches with conversation history
            .limit(10) // Limit for performance
            .get();
      } catch (e) {
        print("DashboardViewModel: Failed to query finished matches (may need Firestore index): $e");
        // Fallback: Get all user matches and filter client-side
        finishedMatches = await _firestore
            .collection('matches')
            .where('users', arrayContains: userId)
            .limit(20)
            .get();
      }

      final connections = <ConnectionData>[];
      int colorIndex = 0;
      
      for (final doc in finishedMatches.docs) {
        final data = doc.data();
        
        // Skip matches without conversation history (these are active/new matches)
        if (!data.containsKey('lastConversationEnd')) {
          print("DashboardViewModel: Skipping match ${doc.id} - no conversation history");
          continue;
        }
        
        // Skip matches marked as deleted
        if (data['connectionDeleted'] == true) {
          print("DashboardViewModel: Skipping deleted connection ${doc.id}");
          continue;
        }
        
        // Skip temporary reconnection matches (only show original connections)
        if (data['isReconnection'] == true) {
          print("DashboardViewModel: Skipping temporary reconnection match ${doc.id}");
          continue;
        }
        
        try {
          final connection = ConnectionData.fromFirebaseData(
            doc.id,
            data,
            userId,
            colorIndex,
          );
          
          // Only include connections that aren't completely faded (strength > 0)
          if (connection.connectionStrength > 0) {
            connections.add(connection);
            colorIndex++;
            print("DashboardViewModel: Added connection: ${connection.displayName} (strength: ${connection.connectionStrength})");
          } else {
            // Auto-delete connections that have reached 0 strength
            print("DashboardViewModel: Auto-deleting connection ${connection.displayName} (strength: 0)");
            await _autoDeleteConnection(doc.id);
          }
        } catch (e) {
          print("DashboardViewModel: Error processing connection ${doc.id}: $e");
        }
      }

      // Sort connections by strength (strongest first) and last interaction
      connections.sort((a, b) {
        // First by strength (descending)
        final strengthComparison = b.connectionStrength.compareTo(a.connectionStrength);
        if (strengthComparison != 0) return strengthComparison;
        
        // Then by last interaction (most recent first)
        return b.lastInteraction.compareTo(a.lastInteraction);
      });

      // Update connections and also update user profile summary for fast access
      await _updateUserConnectionSummary(connections);
      
      _updateState(_dashboardModel.copyWith(connections: connections));
      print("DashboardViewModel: Loaded ${connections.length} connections successfully");
      
      // Log connection summary for debugging
      for (final conn in connections.take(3)) { // Show first 3
        print("DashboardViewModel: Connection: ${conn.displayName} - Strength: ${conn.connectionStrength} - Days: ${conn.inactiveDays}");
      }
      
    } catch (e) {
      print("DashboardViewModel: Error loading connections: $e");
      
      // Don't rethrow - allow dashboard to load even if connections fail
      _updateState(_dashboardModel.copyWith(
        connections: [], // Empty connections list
        errorMessage: "Could not load connections: $e",
      ));
    }
  }

  /// Update user's connection summary for fast dashboard loading
  Future<void> _updateUserConnectionSummary(List<ConnectionData> connections) async {
    try {
      final userId = _authManager.getUserId();
      if (userId == null) return;

      // Create lightweight connection summary
      final connectionSummary = <String, Map<String, dynamic>>{};
      for (final connection in connections) {
        connectionSummary[connection.otherUserId] = {
          'strength': connection.connectionStrength,
          'lastInteraction': connection.lastInteraction.millisecondsSinceEpoch,
          'totalConversations': connection.totalConversations,
          'name': connection.otherUserName,
        };
      }

      // Update user document with summary (for quick access)
      await _firestore.collection('users').doc(userId).update({
        'connectionSummary': connectionSummary,
      });
      
    } catch (e) {
      print("DashboardViewModel: Error updating connection summary: $e");
    }
  }

  /// Auto-delete connections that have reached 0 strength
  Future<void> _autoDeleteConnection(String matchId) async {
    try {
      // Mark connection as deleted rather than actually deleting
      await _firestore.collection('matches').doc(matchId).update({
        'connectionDeleted': true,
        'deletedAt': DateTime.now(),
      });
      print("DashboardViewModel: Connection $matchId marked as deleted");
    } catch (e) {
      print("DashboardViewModel: Error deleting connection: $e");
    }
  }

  /// Boost connection strength when users interact
  static Future<void> boostConnectionStrength({
    required String matchId,
    required String userId,
    int boostAmount = 15,
  }) async {
    try {
      final matchDoc = await FirebaseFirestore.instance
          .collection('matches')
          .doc(matchId)
          .get();
      
      if (!matchDoc.exists) return;
      
      final data = matchDoc.data() as Map<String, dynamic>;
      
      // Check if this is a reconnection match - if so, update the original match instead
      String targetMatchId = matchId;
      if (data['isReconnection'] == true && data.containsKey('originalMatchId')) {
        targetMatchId = data['originalMatchId'];
        print("DashboardViewModel: Reconnection detected - updating original match: $targetMatchId");
      }
      
      // Get the target match document (either current or original)
      final targetMatchDoc = await FirebaseFirestore.instance
          .collection('matches')
          .doc(targetMatchId)
          .get();
          
      if (!targetMatchDoc.exists) {
        print("DashboardViewModel: Target match document not found: $targetMatchId");
        return;
      }
      
      final targetData = targetMatchDoc.data() as Map<String, dynamic>;
      final currentStrength = targetData['connectionStrength'] ?? 100;
      final totalConversations = (targetData['totalConversations'] ?? 1) + 1;
      
      // Boost strength and update conversation count
      final newStrength = (currentStrength + boostAmount).clamp(0, 100);
      
      await FirebaseFirestore.instance
          .collection('matches')
          .doc(targetMatchId)
          .update({
        'connectionStrength': newStrength,
        'totalConversations': totalConversations,
        'lastConversationEnd': DateTime.now(),
        'lastBoostAt': DateTime.now(),
      });
      
      print("DashboardViewModel: Boosted connection strength to $newStrength (+$boostAmount) on match $targetMatchId");
      
      // If this was a reconnection match, also clean up the temporary match
      if (targetMatchId != matchId) {
        print("DashboardViewModel: Cleaning up temporary reconnection match: $matchId");
        await FirebaseFirestore.instance
            .collection('matches')
            .doc(matchId)
            .update({
          'completed': true,
          'completedAt': DateTime.now(),
        });
      }
      
    } catch (e) {
      print("DashboardViewModel: Error boosting connection strength: $e");
    }
  }

  /// Clean up old temporary reconnection matches
  Future<void> _cleanupOldReconnectionMatches() async {
    try {
      print("DashboardViewModel: Cleaning up old temporary reconnection matches...");
      
      final userId = _authManager.getUserId();
      if (userId == null) {
        throw Exception("User not authenticated");
      }

             // Query matches collection for old temporary reconnection matches
       QuerySnapshot<Map<String, dynamic>> oldReconnectionMatches;
       try {
         // Get completed reconnection matches older than 1 hour
         final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
         oldReconnectionMatches = await _firestore
             .collection('matches')
             .where('users', arrayContains: userId)
             .where('isReconnection', isEqualTo: true)
             .where('completed', isEqualTo: true)
             .where('completedAt', isLessThan: oneHourAgo)
             .limit(10) // Limit for performance
             .get();
       } catch (e) {
         print("DashboardViewModel: Failed to query old reconnection matches (may need Firestore index): $e");
         // Fallback: Get all reconnection matches and filter client-side
         oldReconnectionMatches = await _firestore
             .collection('matches')
             .where('users', arrayContains: userId)
             .where('isReconnection', isEqualTo: true)
             .limit(20)
             .get();
       }

             final batch = _firestore.batch();
       final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
       
       for (final doc in oldReconnectionMatches.docs) {
         final data = doc.data();
         
         // Client-side filter if the query fallback was used
         if (!data.containsKey('completed') || data['completed'] != true) {
           continue;
         }
         
         // Check if it's old enough (for client-side filtering)
         if (data.containsKey('completedAt')) {
           final completedAt = (data['completedAt'] as Timestamp).toDate();
           if (completedAt.isAfter(oneHourAgo)) {
             continue; // Skip recent matches
           }
         }
         
         // Mark connection as deleted rather than actually deleting
         batch.update(_firestore.collection('matches').doc(doc.id), {
           'connectionDeleted': true,
           'deletedAt': DateTime.now(),
         });
       }

      await batch.commit();
      
      print("DashboardViewModel: Cleaned up ${oldReconnectionMatches.docs.length} old temporary reconnection matches");
    } catch (e) {
      print("DashboardViewModel: Error cleaning up old temporary reconnection matches: $e");
    }
  }

  Future<void> _refreshConnections() async {
    try {
      // Update user's active status
      final userId = _authManager.getUserId();
      if (userId == null) return;

      await _firestore.collection('users').doc(userId).update({
        'lastActiveTimestamp': FieldValue.serverTimestamp(),
      });

      // Reload connections to get updated strengths
      await _loadConnections();
      print("DashboardViewModel: Refreshed connections");
    } catch (e) {
      print("DashboardViewModel: Error refreshing connections: $e");
    }
  }
} 