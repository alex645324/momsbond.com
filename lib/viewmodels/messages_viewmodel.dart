import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/messages_model.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../Database_logic/simple_matching.dart';

class MessagesViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  MessagesModel _messagesModel = const MessagesModel();
  
  // Timer for conversation management
  Timer? _countdownTimer;
  
  // Real-time message listener
  StreamSubscription<QuerySnapshot>? _messagesSubscription;
  
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

  Future<void> initializeConversation(ConversationInitData initData) async {
    // Reset initialization state for new conversations
    if (_isInitialized && _messagesModel.conversationId != initData.conversationId) {
      print("MessagesViewModel: New conversation detected - resetting state");
      _isInitialized = false;
      _conversationEndTriggered = false;
      
      // Clean up previous conversation resources
      _countdownTimer?.cancel();
      _messagesSubscription?.cancel();
    }
    
    if (_isInitialized) {
      print("MessagesViewModel: Already initialized for this conversation, skipping");
      return;
    }
    
    print("MessagesViewModel: Initializing conversation ${initData.conversationId} with real-time messaging");
    
    try {
      _updateState(_messagesModel.copyWith(
        isLoading: true,
        conversationId: initData.conversationId,
        currentUser: initData.currentUser,
        matchedUser: initData.matchedUser,
        matchId: initData.matchId,
        // Reset conversation state for new conversation
        isConversationActive: true,
        showEndOverlay: false,
        remainingSeconds: 30,
        messages: [], // Clear previous messages
        selectedFeedback: null,
        conversationEndStep: null,
        errorMessage: null,
      ));

      // Create conversation document in Firestore if it doesn't exist
      await _createConversationDocument(initData);
      
      // Set up real-time message listener
      _setupMessageListener();

      // Hard-coded conversation duration
      final conversationDuration = 300; // 5 minutes
      final endTime = DateTime.now().add(Duration(seconds: conversationDuration));
      
      _updateState(_messagesModel.copyWith(
        isLoading: false,
        conversationEndTime: endTime,
        remainingSeconds: conversationDuration,
      ));

      // Start admin-managed countdown timer
      _startAdminManagedTimer(initData.matchId);
      _isInitialized = true;
      
      print("MessagesViewModel: Conversation initialized with real-time messaging");
      
    } catch (e) {
      print("MessagesViewModel: Initialization error: $e");
      _updateState(_messagesModel.copyWith(
        isLoading: false,
        errorMessage: "Failed to initialize conversation: $e",
      ));
    }
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
              final messages = snapshot.docs.map((doc) {
                return ChatMessage.fromFirestore(doc, _messagesModel.currentUser.id);
              }).toList();
              
              _updateState(_messagesModel.copyWith(messages: messages));
              print("MessagesViewModel: Received ${messages.length} messages via real-time listener");
            } catch (e) {
              print("MessagesViewModel: Error processing messages: $e");
            }
          },
          onError: (error) {
            print("MessagesViewModel: Error in message listener: $error");
            _updateState(_messagesModel.copyWith(
              errorMessage: "Failed to sync messages: $error",
            ));
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
          _updateState(_messagesModel.copyWith(remainingSeconds: timeLeft));
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
      _updateState(_messagesModel.copyWith(
        errorMessage: "Failed to send message: $e",
      ));
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
      _countdownTimer?.cancel();
      _messagesSubscription?.cancel();
      
      // Update conversation status in Firestore
      await _firestore
          .collection('conversations')
          .doc(_messagesModel.conversationId)
          .update({
        'isActive': false,
        'endedAt': FieldValue.serverTimestamp(),
      });
      
      // Update user status and clear active match
      await _firestore.collection('users').doc(_messagesModel.currentUser.id).update({
        'isInConversation': false,
        'activeMatchId': FieldValue.delete(), // Clear active match ID
        'lastActiveTimestamp': FieldValue.serverTimestamp(), // Mark as recently active
      });
      
      await _firestore.collection('users').doc(_messagesModel.matchedUser.id).update({
        'isInConversation': false,
        'activeMatchId': FieldValue.delete(), // Clear active match ID
        'lastActiveTimestamp': FieldValue.serverTimestamp(), // Mark as recently active
      });
      
      print("MessagesViewModel: Cleared activeMatchId for both users");

      // Show end overlay
      _updateState(_messagesModel.copyWith(
        isConversationActive: false,
        showEndOverlay: true,
        remainingSeconds: 0,
        conversationEndStep: ConversationEndStep.feedbackPrompt,
      ));

      print("MessagesViewModel: Conversation ended - real-time sync stopped");

    } catch (e) {
      print("MessagesViewModel: Error ending conversation: $e");
      _updateState(_messagesModel.copyWith(
        errorMessage: "Error ending conversation: $e",
      ));
    }
  }

  void selectFeedback(FeedbackChoice choice) {
    _updateState(_messagesModel.copyWith(
      selectedFeedback: choice.value,
      conversationEndStep: ConversationEndStep.feedbackSelected,
    ));
  }

  Future<void> submitFeedback() async {
    if (_messagesModel.selectedFeedback == null) return;

    _updateState(_messagesModel.copyWith(
      isSubmittingFeedback: true,
      conversationEndStep: ConversationEndStep.submittingFeedback,
    ));

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
      _updateState(_messagesModel.copyWith(
        isSubmittingFeedback: false,
        conversationEndStep: ConversationEndStep.acknowledgment,
      ));
      
    } catch (e) {
      print('MessagesViewModel: Error saving feedback: $e');
      _updateState(_messagesModel.copyWith(
        isSubmittingFeedback: false,
        conversationEndStep: ConversationEndStep.acknowledgment,
      ));
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
    _countdownTimer?.cancel();
    _messagesSubscription?.cancel();
    
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
    
    _countdownTimer?.cancel();
    _messagesSubscription?.cancel();
    
    // Update user status when disposing
    if (_isInitialized && !_conversationEndTriggered) {
      _firestore.collection('users').doc(_messagesModel.currentUser.id).update({
        'isInConversation': false,
        'activeMatchId': FieldValue.delete(), // Clear active match ID
      });
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
      _updateState(_messagesModel.copyWith(errorMessage: null));
    }
  }
} 