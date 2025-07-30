import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard_model.dart'; // Import for ConnectionData

// Add enum for conversation end steps
enum ConversationEndStep {
  feedbackPrompt,    // Showing "did you feel connected?" question
  feedbackSelected,  // User selected yes/no but hasn't submitted yet
  submittingFeedback, // Saving feedback to database
  acknowledgment,    // Showing "Thanks for your feedback!" message
}

class MessagesModel {
  final bool isLoading;
  final String? errorMessage;
  final String conversationId;
  final CurrentUserData currentUser;
  final MatchedUserData matchedUser;
  final String matchId;
  final List<ChatMessage> messages;
  final bool isConversationActive;
  final DateTime? conversationEndTime;
  final int remainingSeconds;
  final bool showEndOverlay;
  final String? selectedFeedback;
  final bool isSubmittingFeedback;
  final ConversationEndStep? conversationEndStep;
  final String? starterText;

  const MessagesModel({
    this.isLoading = true,
    this.errorMessage,
    this.conversationId = '',
    this.currentUser = const CurrentUserData(),
    this.matchedUser = const MatchedUserData(),
    this.matchId = '',
    this.messages = const [],
    this.isConversationActive = true,
    this.conversationEndTime,
    this.remainingSeconds = 0,
    this.showEndOverlay = false,
    this.selectedFeedback,
    this.isSubmittingFeedback = false,
    this.conversationEndStep,
    this.starterText,
  });

  MessagesModel copyWith({
    bool? isLoading,
    String? errorMessage,
    String? conversationId,
    CurrentUserData? currentUser,
    MatchedUserData? matchedUser,
    String? matchId,
    List<ChatMessage>? messages,
    bool? isConversationActive,
    DateTime? conversationEndTime,
    int? remainingSeconds,
    bool? showEndOverlay,
    String? selectedFeedback,
    bool? isSubmittingFeedback,
    ConversationEndStep? conversationEndStep,
    String? starterText,
  }) {
    return MessagesModel(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      conversationId: conversationId ?? this.conversationId,
      currentUser: currentUser ?? this.currentUser,
      matchedUser: matchedUser ?? this.matchedUser,
      matchId: matchId ?? this.matchId,
      messages: messages ?? this.messages,
      isConversationActive: isConversationActive ?? this.isConversationActive,
      conversationEndTime: conversationEndTime ?? this.conversationEndTime,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      showEndOverlay: showEndOverlay ?? this.showEndOverlay,
      selectedFeedback: selectedFeedback ?? this.selectedFeedback,
      isSubmittingFeedback: isSubmittingFeedback ?? this.isSubmittingFeedback,
      conversationEndStep: conversationEndStep ?? this.conversationEndStep,
      starterText: starterText ?? this.starterText,
    );
  }

  bool get hasError => errorMessage != null;
  bool get hasMessages => messages.isNotEmpty;
  bool get isConversationEnded => !isConversationActive;
  String get timerDisplay => '${remainingSeconds ~/ 60}:${(remainingSeconds % 60).toString().padLeft(2, '0')}';
  bool get isFirstConversation => true; // Simplified since conversationCount was removed
  
  // Helper getters for end flow
  bool get showFeedbackPrompt => conversationEndStep == ConversationEndStep.feedbackPrompt;
  bool get showFeedbackButtons => conversationEndStep == ConversationEndStep.feedbackPrompt || conversationEndStep == ConversationEndStep.feedbackSelected;
  bool get showAcknowledgment => conversationEndStep == ConversationEndStep.acknowledgment;
}

class CurrentUserData {
  final String id;
  final String username;
  final List<String> momStage;
  final List<String> selectedQuestions;

  const CurrentUserData({
    this.id = '',
    this.username = 'User',
    this.momStage = const [],
    this.selectedQuestions = const [],
  });

  CurrentUserData copyWith({
    String? id,
    String? username,
    List<String>? momStage,
    List<String>? selectedQuestions,
  }) {
    return CurrentUserData(
      id: id ?? this.id,
      username: username ?? this.username,
      momStage: momStage ?? this.momStage,
      selectedQuestions: selectedQuestions ?? this.selectedQuestions,
    );
  }

  static CurrentUserData fromMap(Map<String, dynamic> data) {
    print("DEBUG: CurrentUserData.fromMap called with data: $data");
    
    return CurrentUserData(
      id: data['id'] ?? '',
      username: data['username'] ?? 'User',
      momStage: _safeExtractStringList(data, 'momStage'),
      selectedQuestions: _safeExtractStringList(data, 'selectedQuestions'),
    );
  }

  static List<String> _safeExtractStringList(Map<String, dynamic> data, String key) {
    final value = data[key];
    print("DEBUG: CurrentUserData._safeExtractStringList - key: $key, value: $value (type: ${value.runtimeType})");
    
    if (value == null) return [];
    
    if (value is List) {
      try {
        return value.map((item) => item?.toString() ?? '').where((item) => item.isNotEmpty).toList();
      } catch (e) {
        print("DEBUG: Error converting list in CurrentUserData: $e");
        return [];
      }
    }
    
    if (value is String && value.isNotEmpty) {
      return [value];
    }
    
    return [];
  }
}

class MatchedUserData {
  final String id;
  final String username;
  final List<String> momStage;
  final List<String> selectedQuestions;

  const MatchedUserData({
    this.id = '',
    this.username = 'User',
    this.momStage = const [],
    this.selectedQuestions = const [],
  });

  MatchedUserData copyWith({
    String? id,
    String? username,
    List<String>? momStage,
    List<String>? selectedQuestions,
  }) {
    return MatchedUserData(
      id: id ?? this.id,
      username: username ?? this.username,
      momStage: momStage ?? this.momStage,
      selectedQuestions: selectedQuestions ?? this.selectedQuestions,
    );
  }

  static MatchedUserData fromMap(Map<String, dynamic> data) {
    print("DEBUG: MatchedUserData.fromMap called with data: $data");
    
    return MatchedUserData(
      id: data['id'] ?? '',
      username: data['username'] ?? 'User',
      momStage: _safeExtractStringList(data, 'momStage'),
      selectedQuestions: _safeExtractStringList(data, 'selectedQuestions'),
    );
  }

  static List<String> _safeExtractStringList(Map<String, dynamic> data, String key) {
    final value = data[key];
    print("DEBUG: MatchedUserData._safeExtractStringList - key: $key, value: $value (type: ${value.runtimeType})");
    
    if (value == null) return [];
    
    if (value is List) {
      try {
        return value.map((item) => item?.toString() ?? '').where((item) => item.isNotEmpty).toList();
      } catch (e) {
        print("DEBUG: Error converting list in MatchedUserData: $e");
        return [];
      }
    }
    
    if (value is String && value.isNotEmpty) {
      return [value];
    }
    
    return [];
  }

  // Note: isFirstConversation and conversationCount removed to simplify database
}

class ChatMessage {
  final String id;
  final String authorId;
  final String text;
  final DateTime createdAt;
  final bool isCurrentUser;

  const ChatMessage({
    required this.id,
    required this.authorId,
    required this.text,
    required this.createdAt,
    this.isCurrentUser = false,
  });

  ChatMessage copyWith({
    String? id,
    String? authorId,
    String? text,
    DateTime? createdAt,
    bool? isCurrentUser,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
    );
  }

  static ChatMessage fromFirestore(DocumentSnapshot doc, String currentUserId) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Handle Firestore Timestamp or fallback to timestamp field
    DateTime createdAt;
    try {
      if (data['createdAt'] is Timestamp) {
        createdAt = (data['createdAt'] as Timestamp).toDate();
      } else if (data['timestamp'] != null) {
        createdAt = DateTime.fromMillisecondsSinceEpoch(data['timestamp']);
      } else {
        createdAt = DateTime.now();
      }
    } catch (e) {
      print("MessagesModel: Error parsing timestamp: $e");
      createdAt = DateTime.now();
    }
    
    return ChatMessage(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      text: data['text'] ?? '',
      createdAt: createdAt,
      isCurrentUser: data['authorId'] == currentUserId,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'authorId': authorId,
      'text': text,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}

class ConversationInitData {
  final String conversationId;
  final CurrentUserData currentUser;
  final MatchedUserData matchedUser;
  final String matchId;

  const ConversationInitData({
    required this.conversationId,
    required this.currentUser,
    required this.matchedUser,
    required this.matchId,
  });

  static ConversationInitData fromChatPageData(Map<String, dynamic> matchData, String conversationId) {
    return ConversationInitData(
      conversationId: conversationId,
      currentUser: CurrentUserData.fromMap(matchData['currentUser'] ?? {}),
      matchedUser: MatchedUserData.fromMap(matchData['matchedUser'] ?? {}),
      matchId: matchData['matchId'] ?? '',
    );
  }

  /// Create ConversationInitData from existing ConnectionData (for reconnections)
  static ConversationInitData fromConnectionData(ConnectionData connection) {
    // Extract user data from matchData
    final matchData = connection.matchData;
    
    return ConversationInitData(
      conversationId: connection.conversationId,
      currentUser: CurrentUserData.fromMap(matchData['currentUser'] ?? {}),
      matchedUser: MatchedUserData(
        id: connection.otherUserId,
        username: connection.otherUserName,
        momStage: [], // Will be populated from matchData if available
        selectedQuestions: [], // Will be populated from matchData if available
      ),
      matchId: connection.id,
    );
  }
}

enum FeedbackChoice { yes, no }

extension FeedbackChoiceExtension on FeedbackChoice {
  String get value {
    switch (this) {
      case FeedbackChoice.yes:
        return 'yes';
      case FeedbackChoice.no:
        return 'no';
    }
  }

  bool get keepConnection {
    switch (this) {
      case FeedbackChoice.yes:
        return true;
      case FeedbackChoice.no:
        return false;
    }
  }
} 