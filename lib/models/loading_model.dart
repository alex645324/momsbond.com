import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class LoadingModel {
  final bool isLoading;
  final bool isWaiting;
  final String? errorMessage;
  final UserData? userData;
  final dynamic matchData;
  final bool hasMatch;
  final String loadingText;

  const LoadingModel({
    this.isLoading = true,
    this.isWaiting = false,
    this.errorMessage,
    this.userData,
    this.matchData,
    this.hasMatch = false,
    this.loadingText = "finding someone\nwho understands you",
  });

  LoadingModel copyWith({
    bool? isLoading,
    bool? isWaiting,
    String? errorMessage,
    UserData? userData,
    dynamic matchData,
    bool? hasMatch,
    String? loadingText,
  }) {
    return LoadingModel(
      isLoading: isLoading ?? this.isLoading,
      isWaiting: isWaiting ?? this.isWaiting,
      errorMessage: errorMessage ?? this.errorMessage,
      userData: userData ?? this.userData,
      matchData: matchData ?? this.matchData,
      hasMatch: hasMatch ?? this.hasMatch,
      loadingText: loadingText ?? this.loadingText,
    );
  }

  bool get hasError => errorMessage != null;
  bool get shouldNavigateToChat => hasMatch && matchData != null && matchData['matchId'] != null;
  
  // Extract conversation data for navigation  
  String? get conversationId => matchData?['matchId']; // Use matchId as conversationId
  types.User? get currentUser {
    if (userData == null || matchData == null) return null;
    
    final String userId = userData!.userId;
    final String username = matchData['currentUser']?['username'] ?? userData!.username ?? "User";
    return types.User(id: userId, firstName: username);
  }
}

class UserData {
  final String userId;
  final String? username;
  final List<String> momStages;
  final List<String> selectedQuestions;

  const UserData({
    required this.userId,
    this.username,
    this.momStages = const [],
    this.selectedQuestions = const [],
  });

  UserData copyWith({
    String? userId,
    String? username,
    List<String>? momStages,
    List<String>? selectedQuestions,
  }) {
    return UserData(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      momStages: momStages ?? this.momStages,
      selectedQuestions: selectedQuestions ?? this.selectedQuestions,
    );
  }

  static UserData fromFirebaseData(String userId, Map<String, dynamic> data) {
    print("DEBUG: UserData.fromFirebaseData called with data: $data");
    
    // REFACTORED: Process all question sets using reusable function
    List<String> selectedQuestions = [];
    _processQuestionSets(data, selectedQuestions);
    
    // REFACTORED: Process momStage using reusable function
    final momStages = _processMomStages(data);

    final result = UserData(
      userId: userId,
      username: data['username'] ?? "User",
      momStages: momStages,
      selectedQuestions: selectedQuestions,
    );
    
    print("DEBUG: UserData created: $result");
    return result;
  }

  // REFACTORED: Reusable function to process all question sets
  static void _processQuestionSets(Map<String, dynamic> data, List<String> selectedQuestions) {
    const questionSetKeys = ['questionSet1', 'questionSet2', 'questionSet3'];
    
    for (final key in questionSetKeys) {
      _processQuestionSet(data, key, selectedQuestions);
    }
  }

  // REFACTORED: Generic function to process a single question set
  static void _processQuestionSet(Map<String, dynamic> data, String key, List<String> selectedQuestions) {
    _debugLog("Processing $key...");
    
    if (!data.containsKey(key)) {
      _debugLog("$key not found in data");
      return;
    }
    
    final questionSet = data[key];
    _debugLog("$key value: $questionSet (type: ${questionSet.runtimeType})");
    
    final questions = _safeConvertToStringList(questionSet, key);
    if (questions.isNotEmpty) {
      selectedQuestions.addAll(questions);
      _debugLog("$key processed successfully, total count: ${selectedQuestions.length}");
    }
  }

  // REFACTORED: Reusable function to process momStage
  static List<String> _processMomStages(Map<String, dynamic> data) {
    _debugLog("Processing momStage...");
    
    final momStageRaw = data['momStage'];
    _debugLog("momStage value: $momStageRaw (type: ${momStageRaw.runtimeType})");
    
    final momStages = _safeConvertToStringList(momStageRaw, 'momStage');
    if (momStages.isNotEmpty) {
      _debugLog("momStage processed successfully: $momStages");
    }
    
    return momStages;
  }

  // REFACTORED: Generic safe conversion to List<String> with error handling
  static List<String> _safeConvertToStringList(dynamic value, String fieldName) {
    try {
      if (value == null) return [];
      
      if (value is List) {
        return value.map((item) => item?.toString() ?? '').where((item) => item.isNotEmpty).toList();
      }
      
      if (value is String && value.isNotEmpty) {
        return [value];
      }
      
      return [];
    } catch (e) {
      _debugLog("Error processing $fieldName: $e");
      return [];
    }
  }

  // REFACTORED: Centralized debug logging
  static void _debugLog(String message) {
    print("DEBUG: $message");
  }

  bool get isValidForMatching => momStages.isNotEmpty || selectedQuestions.isNotEmpty;
} 