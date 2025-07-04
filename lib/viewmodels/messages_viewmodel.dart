import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/messages_model.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../Database_logic/simple_matching.dart';
import '../config/app_config.dart';
import 'package:meta/meta.dart';

class MessagesViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  MessagesModel _messagesModel = const MessagesModel();
  
  // Timer for conversation management
  Timer? _countdownTimer;
  
  // Real-time message listener
  StreamSubscription<QuerySnapshot>? _messagesSubscription;
  
  // Listener for conversation status changes (e.g., remote user ends conversation early)
  StreamSubscription<DocumentSnapshot>? _conversationStatusSubscription;
  
  bool _isInitialized = false;
  bool _conversationEndTriggered = false;

  MessagesModel get messagesModel => _messagesModel;
  bool get isLoading => _messagesModel.isLoading;
  String? get errorMessage => _messagesModel.errorMessage;
  bool get hasError => _messagesModel.hasError;
  List<ChatMessage> get messages => _messagesModel.messages;
  bool get isConversationActive => _messagesModel.isConversationActive;
  bool get showEndOverlay => _messagesModel.showEndOverlay;
  String get timerDisplay => _messagesModel.timerDisplay;

  void _updateState(MessagesModel newModel) {
    _messagesModel = newModel;
    notifyListeners();
  }

  // ------------------------------------------------------------------
  // Small helpers to reduce repetition (private – public API unchanged)
  // ------------------------------------------------------------------

  // Combines state update and optional debug log
  void _setState(MessagesModel model, [String? log]) {
    _updateState(model);
    if (log != null) debugPrint('MessagesViewModel: $log');
  }

  // Cancel all timers / stream subscriptions used by this view-model
  void _cancelStreamsAndTimers() {
    _countdownTimer?.cancel();
    _messagesSubscription?.cancel();
    _conversationStatusSubscription?.cancel();
  }

  // Clear a user doc's conversation flags
  Future<void> _clearConversationFlags(String userId,
      {bool stampLastActive = false}) {
    final data = {
      'isInConversation': false,
      'activeMatchId': FieldValue.delete(),
    };
    if (stampLastActive) {
      data['lastActiveTimestamp'] = FieldValue.serverTimestamp();
    }
    return _firestore.collection('users').doc(userId).update(data);
  }

  Future<void> initializeConversation(ConversationInitData initData) async {
    // Reset initialization state for new conversations
    if (_isInitialized && _messagesModel.conversationId != initData.conversationId) {
      print("MessagesViewModel: New conversation detected - resetting state");
      _isInitialized = false;
      _conversationEndTriggered = false;
      
      // Clean up previous conversation resources
      _cancelStreamsAndTimers();
    }
    
    if (_isInitialized) {
      print("MessagesViewModel: Already initialized for this conversation, skipping");
      return;
    }
    
    print("MessagesViewModel: Initializing conversation ${initData.conversationId} with real-time messaging");
    
    try {
      // Generate starter text once during initialization
      final starterText = _generateStarterText(initData.currentUser, initData.matchedUser);
      
      _setState(_messagesModel.copyWith(
        isLoading: true,
        conversationId: initData.conversationId,
        currentUser: initData.currentUser,
        matchedUser: initData.matchedUser,
        matchId: initData.matchId,
        starterText: starterText,
        // Reset conversation state for new conversation
        isConversationActive: true,
        showEndOverlay: false,
        remainingSeconds: AppConfig.chatDurationSeconds,
        messages: [], // Clear previous messages
        selectedFeedback: null,
        conversationEndStep: null,
        errorMessage: null,
      ), 'Conversation initialized state set');

      // Create conversation document in Firestore if it doesn't exist
      await _createConversationDocument(initData);
      
      // Set up real-time message listener
      _setupMessageListener();

      // Listen for remote conversation end events (isActive flag)
      _setupConversationStatusListener();

      // Get conversation duration from config
      final conversationDuration = AppConfig.chatDurationSeconds;
      final endTime = DateTime.now().add(Duration(seconds: conversationDuration));
      
      _setState(_messagesModel.copyWith(
        isLoading: false,
        conversationEndTime: endTime,
        remainingSeconds: conversationDuration,
      ), 'Conversation initialized state set');

      // Start admin-managed countdown timer
      _startAdminManagedTimer(initData.matchId);
      _isInitialized = true;
      
      print("MessagesViewModel: Conversation initialized with real-time messaging");
      
    } catch (e) {
      print("MessagesViewModel: Initialization error: $e");
      _setState(_messagesModel.copyWith(
        isLoading: false,
        errorMessage: "Failed to initialize conversation: $e",
      ), 'Conversation initialization error');
    }
  }

  String _generateStarterText(CurrentUserData currentUser, MatchedUserData matchedUser) {
    // Clean and prepare topics
    final currentTopics = currentUser.selectedQuestions
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final matchedTopics = matchedUser.selectedQuestions
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    print("DEBUG: Current user topics: $currentTopics");
    print("DEBUG: Matched user topics: $matchedTopics");

    // Initialize topic as null
    String? topic;

    // First try to find a shared challenge
    if (currentTopics.isNotEmpty && matchedTopics.isNotEmpty) {
      for (var t in currentTopics) {
        if (matchedTopics.contains(t)) {
          topic = t;
          print("DEBUG: Found shared topic: $topic");
          break;
        }
      }
    }

    // If no shared topic found, use current user's first selection
    if (topic == null) {
      // Try current user's topics first
      if (currentTopics.isNotEmpty) {
        topic = currentTopics.first;
        print("DEBUG: Using current user's first topic: $topic");
      }
      // Fallback to matched user's topics if current user has none
      else if (matchedTopics.isNotEmpty) {
        topic = matchedTopics.first;
        print("DEBUG: Using matched user's first topic: $topic");
      }
    }

    // Generate and return the starter text
    final text = 'your connection also struggles with \n"${topic ?? 'connecting with other moms'}"';
    print("DEBUG: Generated starter text: $text");
    return text;
  }

  Future<void> _createConversationDocument(ConversationInitData initData) async {
    try {
      final conversationRef = _firestore.collection('conversations').doc(initData.conversationId);
      final conversationDoc = await conversationRef.get();
      
      if (!conversationDoc.exists) {
        // Create conversation document with participant info
        await conversationRef.set({
          'conversationId': initData.conversationId,
          'matchId': initData.matchId,
          'participants': {
            initData.currentUser.id: {
              'username': initData.currentUser.username,
              'joinedAt': FieldValue.serverTimestamp(),
            },
            initData.matchedUser.id: {
              'username': initData.matchedUser.username,
              'joinedAt': FieldValue.serverTimestamp(),
            },
          },
          'createdAt': FieldValue.serverTimestamp(),
          'isActive': true,
        });
        
        print("MessagesViewModel: Created conversation document: ${initData.conversationId}");
      } else {
        print("MessagesViewModel: Conversation document already exists: ${initData.conversationId}");
      }
    } catch (e) {
      print("MessagesViewModel: Error creating conversation document: $e");
      throw e;
    }
  }

  void _setupMessageListener() {
    if (_messagesModel.conversationId.isEmpty) return;
    
    print("MessagesViewModel: Setting up real-time message listener for: ${_messagesModel.conversationId}");
    
    _messagesSubscription?.cancel();
    _messagesSubscription = _firestore
        .collection('conversations')
        .doc(_messagesModel.conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(50) // Limit to recent messages
        .snapshots()
        .listen(
          (snapshot) {
            try {
              final messages = snapshot.docs
                  .map((doc) =>
                      ChatMessage.fromFirestore(doc, _messagesModel.currentUser.id))
                  .toList();
              
              _setState(_messagesModel.copyWith(messages: messages),
                  'Received ${messages.length} messages via real-time listener');
            } catch (e) {
              print("MessagesViewModel: Error processing messages: $e");
            }
          },
          onError: (error) {
            print("MessagesViewModel: Error in message listener: $error");
            _setState(_messagesModel.copyWith(
              errorMessage: "Failed to sync messages: $error",
            ), 'Error in message listener');
          },
        );
  }

  void _startAdminManagedTimer(String matchId) {
    _countdownTimer?.cancel();
    
    // Start the admin-configured timer
    _countdownTimer = SimpleMatching.startConversationTimer(
      matchId: matchId,
      onTimeUp: () {
        if (!_conversationEndTriggered) {
          print("MessagesViewModel: Admin timer expired - triggering end flow");
          _onConversationEnd();
        }
      },
    );
    
    // Also start a UI update timer for countdown display
    _startUICountdownTimer();
  }

  void _startUICountdownTimer() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_messagesModel.conversationEndTime != null && !_conversationEndTriggered) {
        final now = DateTime.now();
        final timeLeft = _messagesModel.conversationEndTime!.difference(now).inSeconds;
        
        if (timeLeft <= 0) {
          timer.cancel();
        } else {
          _setState(_messagesModel.copyWith(remainingSeconds: timeLeft));
        }
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || !_messagesModel.isConversationActive) return;

    try {
      print("MessagesViewModel: Sending message to conversation: ${_messagesModel.conversationId}");
      
      // Send message to Firestore - it will be received by both users via listener
      await _firestore
          .collection('conversations')
          .doc(_messagesModel.conversationId)
          .collection('messages')
          .add({
        'authorId': _messagesModel.currentUser.id,
        'authorName': _messagesModel.currentUser.username,
        'text': text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'timestamp': DateTime.now().millisecondsSinceEpoch, // Fallback for ordering
      });
      
      print("MessagesViewModel: Message sent successfully: ${text.trim()}");
      
    } catch (e) {
      print("MessagesViewModel: Error sending message: $e");
      _setState(_messagesModel.copyWith(
        errorMessage: "Failed to send message: $e",
      ), 'Error sending message');
    }
  }

  Future<void> _onConversationEnd() async {
    if (_conversationEndTriggered) {
      print("MessagesViewModel: Conversation end already triggered, ignoring");
      return;
    }
    
    _conversationEndTriggered = true;
    print("MessagesViewModel: ========== CONVERSATION ENDED ==========");
    
    try {
      // Cancel timer and message listener
      _cancelStreamsAndTimers();
      
      // Update conversation status in Firestore
      await _firestore
          .collection('conversations')
          .doc(_messagesModel.conversationId)
          .update({
        'isActive': false,
        'endedAt': FieldValue.serverTimestamp(),
      });
      
      // Update user status and clear active match
      await _clearConversationFlags(_messagesModel.currentUser.id);
      await _clearConversationFlags(_messagesModel.matchedUser.id);
      
      print("MessagesViewModel: Cleared activeMatchId for both users");

      // Show end overlay
      _setState(_messagesModel.copyWith(
        isConversationActive: false,
        showEndOverlay: true,
        remainingSeconds: 0,
        conversationEndStep: ConversationEndStep.feedbackPrompt,
      ), 'Conversation ended - showing end overlay');

      print("MessagesViewModel: Conversation ended - real-time sync stopped");

    } catch (e) {
      print("MessagesViewModel: Error ending conversation: $e");
      _setState(_messagesModel.copyWith(
        errorMessage: "Error ending conversation: $e",
      ), 'Error ending conversation');
    }
  }

  void selectFeedback(FeedbackChoice choice) {
    _setState(_messagesModel.copyWith(
      selectedFeedback: choice.value,
      conversationEndStep: ConversationEndStep.feedbackSelected,
    ), 'Selected feedback');
  }

  Future<void> submitFeedback() async {
    if (_messagesModel.selectedFeedback == null) return;

    _setState(_messagesModel.copyWith(
      isSubmittingFeedback: true,
      conversationEndStep: ConversationEndStep.submittingFeedback,
    ), 'Submitting feedback');

    try {
      final keepConnection = _messagesModel.selectedFeedback == 'yes';
      
      // Check if this is a reconnection match and get the original match ID
      String targetMatchId = _messagesModel.matchId;
      
      final matchDoc = await _firestore.collection('matches').doc(_messagesModel.matchId).get();
      if (matchDoc.exists) {
        final matchData = matchDoc.data() as Map<String, dynamic>;
        if (matchData['isReconnection'] == true && matchData.containsKey('originalMatchId')) {
          targetMatchId = matchData['originalMatchId'];
          print("MessagesViewModel: Reconnection detected - saving feedback to original match: $targetMatchId");
        }
      }
      
      // Save feedback to the target match (original for reconnections)
      await _firestore
          .collection('matches')
          .doc(targetMatchId)
          .update({
        'feedback': {
          'timestamp': FieldValue.serverTimestamp(),
          '${_messagesModel.currentUser.id}_preference': keepConnection ? 'keep' : 'remove',
        },
        // Update conversation end timestamp for connection strength calculation
        'lastConversationEnd': FieldValue.serverTimestamp(),
      });

      // If keeping connection, mark match as active AND boost connection strength
      if (keepConnection) {
        await _firestore
            .collection('matches')
            .doc(targetMatchId)
            .update({
          'active': true,
          'lastInteractionDate': FieldValue.serverTimestamp(),
        });
        
        // Boost connection strength for positive feedback (this will handle reconnection matches)
        await _boostConnectionStrength();
      }

      // If this was a reconnection match, clean up the temporary match
      if (targetMatchId != _messagesModel.matchId) {
        print("MessagesViewModel: Cleaning up temporary reconnection match: ${_messagesModel.matchId}");
        await _firestore
            .collection('matches')
            .doc(_messagesModel.matchId)
            .update({
          'completed': true,
          'completedAt': FieldValue.serverTimestamp(),
          'feedbackProcessed': true,
        });
      }

      print('MessagesViewModel: Feedback saved: User ${_messagesModel.currentUser.id} chose to ${keepConnection ? "keep" : "remove"} connection');

      // Show acknowledgment screen
      _setState(_messagesModel.copyWith(
        isSubmittingFeedback: false,
        conversationEndStep: ConversationEndStep.acknowledgment,
      ), 'Feedback saved');
      
    } catch (e) {
      print('MessagesViewModel: Error saving feedback: $e');
      _setState(_messagesModel.copyWith(
        isSubmittingFeedback: false,
        conversationEndStep: ConversationEndStep.acknowledgment,
      ), 'Error saving feedback');
    }
  }

  /// Boost connection strength after successful conversation
  Future<void> _boostConnectionStrength() async {
    try {
      await DashboardViewModel.boostConnectionStrength(
        matchId: _messagesModel.matchId,
        userId: _messagesModel.currentUser.id,
        boostAmount: 15, // Standard boost for completed conversation
      );
      print("MessagesViewModel: Connection strength boosted for positive interaction");
    } catch (e) {
      print("MessagesViewModel: Error boosting connection strength: $e");
    }
  }

  void acknowledgeAndNavigate() {
    print("MessagesViewModel: User acknowledged conversation end - cleaning up and navigating to dashboard");
    
    // Clean up resources and reset state
    resetForNewConversation();
    
    _navigateToDashboard?.call();
  }

  /// Reset ViewModel state for reuse in new conversations
  void resetForNewConversation() {
    print("MessagesViewModel: Resetting ViewModel state for new conversation");
    
    // Cancel timers and subscriptions
    _cancelStreamsAndTimers();
    
    // Reset flags
    _isInitialized = false;
    _conversationEndTriggered = false;
    
    // Reset model to initial state
    _messagesModel = const MessagesModel();
    
    // Notify listeners of the reset state
    notifyListeners();
  }

  // Navigation callback
  VoidCallback? _navigateToDashboard;
  
  void setNavigationCallback(VoidCallback callback) {
    _navigateToDashboard = callback;
  }

  @override
  void dispose() {
    print("MessagesViewModel: Disposing - cleaning up resources");
    
    _cancelStreamsAndTimers();
    
    // Update user status when disposing
    if (_isInitialized && !_conversationEndTriggered) {
      _clearConversationFlags(_messagesModel.currentUser.id);
      print("MessagesViewModel: Dispose cleanup - cleared user status and activeMatchId");
    }
    
    // Reset state for reuse
    _isInitialized = false;
    _conversationEndTriggered = false;
    _messagesModel = const MessagesModel(); // Reset to initial state
    
    super.dispose();
  }

  void clearError() {
    if (_messagesModel.hasError) {
      _setState(_messagesModel.copyWith(errorMessage: null));
    }
  }

  // Expose starter text generation for unit tests
  @visibleForTesting
  String computeStarterText(CurrentUserData current, MatchedUserData matched) {
    return _generateStarterText(current, matched);
  }

  // Listen for changes on the conversation document to detect remote end events
  void _setupConversationStatusListener() {
    if (_messagesModel.conversationId.isEmpty) return;
    _conversationStatusSubscription?.cancel();

    _conversationStatusSubscription = _firestore
        .collection('conversations')
        .doc(_messagesModel.conversationId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final isActive = data['isActive'] as bool? ?? true;

      if (!isActive && !_conversationEndTriggered) {
        print("MessagesViewModel: Detected isActive=false – remote end signal");
        _onConversationEnd();
      }
    }, onError: (error) {
      print("MessagesViewModel: Error in conversation status listener: $error");
    });
  }

  /// Called by UI (exit button) to end conversation early for both users
  void endConversationEarly() {
    print("MessagesViewModel: endConversationEarly invoked by local user");
    _onConversationEnd();
  }
} 