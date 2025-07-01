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
    
    // Combine question sets like the original implementation
    List<String> selectedQuestions = [];
    
    print("DEBUG: Processing questionSet1...");
    if (data.containsKey('questionSet1')) {
      final questionSet1 = data['questionSet1'];
      print("DEBUG: questionSet1 value: $questionSet1 (type: ${questionSet1.runtimeType})");
      
      try {
        if (questionSet1 != null) {
          selectedQuestions.addAll(List<String>.from(questionSet1));
          print("DEBUG: questionSet1 processed successfully, count: ${selectedQuestions.length}");
        }
      } catch (e) {
        print("DEBUG: Error processing questionSet1: $e");
      }
    }
    
    print("DEBUG: Processing questionSet2...");
    if (data.containsKey('questionSet2')) {
      final questionSet2 = data['questionSet2'];
      print("DEBUG: questionSet2 value: $questionSet2 (type: ${questionSet2.runtimeType})");
      
      try {
        if (questionSet2 != null) {
          selectedQuestions.addAll(List<String>.from(questionSet2));
          print("DEBUG: questionSet2 processed successfully, total count: ${selectedQuestions.length}");
        }
      } catch (e) {
        print("DEBUG: Error processing questionSet2: $e");
      }
    }

    print("DEBUG: Processing momStage...");
    final momStageRaw = data['momStage'];
    print("DEBUG: momStage value: $momStageRaw (type: ${momStageRaw.runtimeType})");
    
    List<String> momStages = [];
    try {
      if (momStageRaw != null) {
        momStages = List<String>.from(momStageRaw);
        print("DEBUG: momStage processed successfully: $momStages");
      }
    } catch (e) {
      print("DEBUG: Error processing momStage: $e");
    }

    final result = UserData(
      userId: userId,
      username: data['username'] ?? "User",
      momStages: momStages,
      selectedQuestions: selectedQuestions,
    );
    
    print("DEBUG: UserData created: $result");
    return result;
  }

  bool get isValidForMatching => momStages.isNotEmpty || selectedQuestions.isNotEmpty;
} 