import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Database_logic/simple_auth_manager.dart';
import '../Database_logic/simple_matching.dart';
import '../models/loading_model.dart';
import '../views/messages_view.dart';
import '../models/messages_model.dart';

class LoadingViewModel extends ChangeNotifier {
  final SimpleAuthManager _authManager = SimpleAuthManager();
  LoadingModel _loadingModel = const LoadingModel();
  StreamSubscription<DocumentSnapshot>? _userSubscription;
  Timer? _activeStatusTimer; // Timer to update active status

  LoadingModel get loadingModel => _loadingModel;
  bool get isLoading => _loadingModel.isLoading;
  bool get isWaiting => _loadingModel.isWaiting;
  String? get errorMessage => _loadingModel.errorMessage;
  bool get hasError => _loadingModel.hasError;
  String get loadingText => _loadingModel.loadingText;
  UserData? get userData => _loadingModel.userData;

  void _updateState(LoadingModel newModel) {
    _loadingModel = newModel;
    notifyListeners();
  }

  Future<void> initialize() async {
    print("DEBUG: LoadingViewModel.initialize() called");
    print("LoadingViewModel: Initializing matching process");
    
    // FIRST: Reset internal state to clear any old match data from memory
    print("DEBUG: Resetting LoadingViewModel internal state");
    _resetInternalState();
    
    try {
      // FIRST: Let's check the user's current state in Firestore
      final currentUserId = _authManager.getUserId();
      print("DEBUG: Current user ID: $currentUserId");
      
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();
      final userData = userDoc.data();
      print("DEBUG: Current user state in Firestore: $userData");
      
      if (userData != null) {
        print("DEBUG: User isInConversation: ${userData['isInConversation']}");
        print("DEBUG: User isWaiting: ${userData['isWaiting']}");
        print("DEBUG: User has matchData: ${userData.containsKey('matchData')}");
        print("DEBUG: User has activeMatchId: ${userData.containsKey('activeMatchId')}");
        print("DEBUG: User has pendingChat: ${userData['pendingChat']}");
        print("DEBUG: User has hasInvitation: ${userData['hasInvitation']}");
        
        if (userData.containsKey('matchData')) {
          print("DEBUG: Existing matchData: ${userData['matchData']}");
        }
      }
      
      // CLEAN SLATE: Clear any old conversation/match data before starting fresh
      print("DEBUG: Clearing old match data to start fresh");
      await FirebaseFirestore.instance.collection('users').doc(currentUserId).update({
        'matchData': FieldValue.delete(),
        'activeMatchId': FieldValue.delete(), 
        'isInConversation': false,
        'isWaiting': false,
        'pendingChat': false,
        'hasInvitation': false,
        'lastActiveTimestamp': FieldValue.delete(), // Clear old timestamp for fresh start
      });
      print("DEBUG: Old match data cleared");
      
      // Start listening for match updates first
      _listenForMatchUpdates();
      
      // Then attempt to find a match
      await _attemptMatchOnce();
      
    } catch (e) {
      print("LoadingViewModel: Initialization error: $e");
      _updateState(_loadingModel.copyWith(
        isLoading: false,
        errorMessage: "Failed to initialize matching: $e",
      ));
    }
  }

  void _listenForMatchUpdates() {
    final String currentUserId = _authManager.getUserId();
    print("DEBUG: Setting up real-time listener for user $currentUserId");
    print("LoadingViewModel: Setting up real-time listener for user $currentUserId");
    
    _userSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .listen((docSnapshot) {
      print("DEBUG: Real-time listener triggered");
      final data = docSnapshot.data() as Map<String, dynamic>?;
      print("DEBUG: Listener received data: $data");
      
      if (data != null && data.containsKey('matchData')) {
        print("DEBUG: Match data detected via listener: ${data['matchData']}");
        print("LoadingViewModel: Match data detected via listener");
        _handleMatchFound(data['matchData']);
      } else {
        print("DEBUG: No match data in listener update");
      }
    }, onError: (error) {
      print("LoadingViewModel: Listener error: $error");
      _updateState(_loadingModel.copyWith(
        errorMessage: "Connection error: $error",
      ));
    });
  }

  Future<void> _attemptMatchOnce() async {
    try {
      print("DEBUG: _attemptMatchOnce started");
      
      // Retrieve user data from Firebase
      final firebaseUserData = await _authManager.getUserData();
      print("DEBUG: Retrieved Firebase data: $firebaseUserData");
      
      if (firebaseUserData == null) {
        print("DEBUG: No Firebase user data found");
        _updateState(_loadingModel.copyWith(
          isLoading: false,
          errorMessage: "No user data found. Please complete your profile.",
        ));
        return;
      }

      final String currentUserId = _authManager.getUserId();
      print("DEBUG: Current user ID: $currentUserId");
      
      // Debug the specific fields we're trying to extract
      print("DEBUG: Raw momStage from Firebase: ${firebaseUserData['momStage']} (type: ${firebaseUserData['momStage'].runtimeType})");
      print("DEBUG: Raw questionSet1 from Firebase: ${firebaseUserData['questionSet1']} (type: ${firebaseUserData['questionSet1']?.runtimeType})");
      print("DEBUG: Raw questionSet2 from Firebase: ${firebaseUserData['questionSet2']} (type: ${firebaseUserData['questionSet2']?.runtimeType})");

      print("DEBUG: About to call UserData.fromFirebaseData");
      final userData = UserData.fromFirebaseData(currentUserId, firebaseUserData);
      print("DEBUG: UserData created successfully");
      print("DEBUG: userData.momStages: ${userData.momStages}");
      print("DEBUG: userData.selectedQuestions: ${userData.selectedQuestions}");

      if (!userData.isValidForMatching) {
        print("DEBUG: User data not valid for matching");
        _updateState(_loadingModel.copyWith(
          isLoading: false,
          errorMessage: "Please complete your profile to find matches.",
        ));
        return;
      }

      _updateState(_loadingModel.copyWith(
        userData: userData,
        isWaiting: true,
      ));

      // Mark user as waiting in Firebase
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .update({
        'isWaiting': true,
        'lastActiveTimestamp': FieldValue.serverTimestamp(), // Initialize active timestamp
      });

      // Start timer to update active status every 10 seconds
      _startActiveStatusTimer(currentUserId);

      print("LoadingViewModel: User $currentUserId marked as waiting");
      print("LoadingViewModel: Attempting match with momStages: ${userData.momStages}");
      print("LoadingViewModel: Selected questions: ${userData.selectedQuestions}");

      print("DEBUG: About to call SimpleMatching.findMatch");
      // Attempt to find a match using the simplified matching service
      final matchData = await SimpleMatching.findMatch(
        currentUserId: currentUserId,
        momStages: userData.momStages,
        selectedQuestions: userData.selectedQuestions,
      );
      print("DEBUG: SimpleMatching.findMatch completed");

      if (matchData != null) {
        print("LoadingViewModel: Match found immediately: $matchData");
        // Note: Don't navigate immediately - wait for listener to detect the update
        // This ensures both users navigate simultaneously
      } else {
        print("LoadingViewModel: No immediate match found, waiting for real-time updates");
      }

    } catch (e, stackTrace) {
      print("DEBUG: Error in _attemptMatchOnce: $e");
      print("DEBUG: Stack trace: $stackTrace");
      _updateState(_loadingModel.copyWith(
        isLoading: false,
        isWaiting: false,
        errorMessage: "Matching failed: $e",
      ));
    }
  }

  void _handleMatchFound(dynamic matchData) {
    print("DEBUG: _handleMatchFound called with matchData: $matchData");
    print("LoadingViewModel: Processing match data: $matchData");
    
    // Add more detailed debugging
    if (matchData is Map<String, dynamic>) {
      print("DEBUG: Match data keys: ${matchData.keys.toList()}");
      print("DEBUG: Match ID: ${matchData['matchId']}");
      print("DEBUG: Current user: ${matchData['currentUser']}");
      print("DEBUG: Matched user: ${matchData['matchedUser']}");
    }
    
    _updateState(_loadingModel.copyWith(
      matchData: matchData,
      hasMatch: true,
      isLoading: false,
      isWaiting: false,
    ));
    
    print("DEBUG: State updated - hasMatch: true, shouldNavigateToChat: ${_loadingModel.shouldNavigateToChat}");
  }

  Future<void> navigateToChat(BuildContext context) async {
    print("DEBUG: navigateToChat called");
    print("DEBUG: shouldNavigateToChat: ${_loadingModel.shouldNavigateToChat}");
    print("DEBUG: hasMatch: ${_loadingModel.hasMatch}");
    print("DEBUG: matchData: ${_loadingModel.matchData}");
    
    if (!_loadingModel.shouldNavigateToChat) {
      print("LoadingViewModel: Cannot navigate - missing match data");
      return;
    }

    final conversationId = _loadingModel.conversationId;
    final currentUser = _loadingModel.currentUser;
    
    print("DEBUG: conversationId (matchId): $conversationId");
    print("DEBUG: currentUser: $currentUser");

    if (conversationId == null || currentUser == null) {
      print("DEBUG: Navigation validation failed - conversationId: $conversationId, currentUser: $currentUser");
      _updateState(_loadingModel.copyWith(
        errorMessage: "Invalid match data for navigation",
      ));
      return;
    }

    print("LoadingViewModel: Navigating to chat with conversation: $conversationId");

    // Cancel subscription to avoid duplicate navigation
    await cleanup();

    print("DEBUG: About to create ConversationInitData");
    final initData = ConversationInitData.fromChatPageData(_loadingModel.matchData, conversationId);
    print("DEBUG: ConversationInitData created: $initData");

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MessagesView(initData: initData),
      ),
    );
  }

  Future<void> cleanup() async {
    print("LoadingViewModel: Cleaning up resources");
    _userSubscription?.cancel();
    _userSubscription = null;
    
    // Cancel active status timer
    _activeStatusTimer?.cancel();
    _activeStatusTimer = null;
    print("LoadingViewModel: Cancelled active status timer");
  }

  @override
  void dispose() {
    cleanup();
    super.dispose();
  }

  void clearError() {
    if (_loadingModel.hasError) {
      _updateState(_loadingModel.copyWith(errorMessage: null));
    }
  }

  void showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _resetInternalState() {
    // Cancel any existing timer
    _activeStatusTimer?.cancel();
    _activeStatusTimer = null;
    
    // Reset the internal model to clear any old match data from memory
    _updateState(const LoadingModel(
      isLoading: true,
      isWaiting: false,
      hasMatch: false,
      matchData: null,
      userData: null,
      errorMessage: null,
      loadingText: 'finding you the perfect connection...',
    ));
    print("DEBUG: LoadingViewModel state reset - shouldNavigateToChat: ${_loadingModel.shouldNavigateToChat}");
  }

  void _startActiveStatusTimer(String userId) {
    // Cancel any existing timer
    _activeStatusTimer?.cancel();
    
    // Start new timer to update active status every 10 seconds
    _activeStatusTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({'lastActiveTimestamp': FieldValue.serverTimestamp()});
        print("LoadingViewModel: Updated active timestamp for user $userId");
      } catch (e) {
        print("LoadingViewModel: Error updating active timestamp: $e");
        // Cancel timer on error to prevent spam
        timer.cancel();
      }
    });
    
    print("LoadingViewModel: Started active status timer for user $userId");
  }
} 