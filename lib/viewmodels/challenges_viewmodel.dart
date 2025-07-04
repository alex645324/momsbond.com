import 'package:flutter/material.dart';
import '../Database_logic/simple_auth_manager.dart';
import '../models/challenges_model.dart';
import '../views/loading_view.dart';

class ChallengesViewModel extends ChangeNotifier {
  final SimpleAuthManager _authManager = SimpleAuthManager();
  ChallengesModel _challengesModel = const ChallengesModel();

  ChallengesModel get challengesModel => _challengesModel;
  int get currentSet => _challengesModel.currentSet;
  List<String> get currentQuestions => _challengesModel.currentQuestions;
  bool get isLoading => _challengesModel.isLoading;
  String? get errorMessage => _challengesModel.errorMessage;
  bool get hasError => _challengesModel.hasError;
  bool get canProceed => _challengesModel.canProceed;
  bool get canGoBack => _challengesModel.canGoBack;
  bool get canGoForward => _challengesModel.canGoForward;
  bool get isSet1 => _challengesModel.isSet1;
  bool get isSet2 => _challengesModel.isSet2;
  String get currentSetTitle => _challengesModel.currentSetTitle;
  List<ChallengeQuestion> get currentAvailableQuestions => _challengesModel.currentAvailableQuestions;

  // Initialize with mismatch parameter and optional starting set
  void initialize(bool isMismatch, {int startingSet = 1}) {
    _updateState(_challengesModel.copyWith(
      isMismatch: isMismatch,
      currentSet: startingSet,
    ));
    print("ChallengesViewModel: Initialized with isMismatch=$isMismatch, startingSet=$startingSet");
  }

  void _updateState(ChallengesModel newModel) {
    _challengesModel = newModel;
    notifyListeners();
  }

  bool isQuestionSelected(String questionId) {
    return _challengesModel.isQuestionSelected(questionId);
  }

  // REFACTORED: Simplified toggleQuestion using helper methods
  void toggleQuestion(String questionId) {
    final dbValue = _getDbValueForId(questionId);
    final updatedQuestions = _toggleQuestionInList(_getCurrentQuestionsList(), dbValue);
    _updateCurrentQuestionsList(updatedQuestions);
    
    print("Question toggled: $questionId -> $dbValue");
    print("Current set ${_challengesModel.currentSet} questions: $updatedQuestions");
  }

  // REFACTORED: Helper to get current questions list by set
  List<String> _getCurrentQuestionsList() {
    switch (_challengesModel.currentSet) {
      case 1: return _challengesModel.set1Questions;
      case 2: return _challengesModel.set2Questions;
      case 3: return _challengesModel.set3Questions;
      default: return [];
    }
  }

  // REFACTORED: Generic helper to toggle question in any list
  List<String> _toggleQuestionInList(List<String> questions, String dbValue) {
    final updatedQuestions = List<String>.from(questions);
    if (updatedQuestions.contains(dbValue)) {
      updatedQuestions.remove(dbValue);
    } else {
      updatedQuestions.add(dbValue);
    }
    return updatedQuestions;
  }

  // REFACTORED: Helper to update current questions list based on set
  void _updateCurrentQuestionsList(List<String> updatedQuestions) {
    switch (_challengesModel.currentSet) {
      case 1:
        _updateState(_challengesModel.copyWith(
          set1Questions: updatedQuestions,
          errorMessage: null,
        ));
        break;
      case 2:
        _updateState(_challengesModel.copyWith(
          set2Questions: updatedQuestions,
          errorMessage: null,
        ));
        break;
      case 3:
        _updateState(_challengesModel.copyWith(
          set3Questions: updatedQuestions,
          errorMessage: null,
        ));
        break;
    }
  }

  // REFACTORED: Using ChallengesModel's improved question lookup
  String _getDbValueForId(String questionId) {
    final question = ChallengesModel.getQuestionById(questionId);
    if (question == null) {
      throw ArgumentError('Question ID not found: $questionId');
    }
    return question.dbValue;
  }

  Future<void> goForward(BuildContext context) async {
    if (!_challengesModel.canGoForward) return;

    if (_challengesModel.currentQuestions.isEmpty) {
      _updateStateWithError("Please select at least one challenge");
      return;
    }

    _updateState(_challengesModel.copyWith(isLoading: true, errorMessage: null));

    try {
      // REFACTORED: Using helper method for data key generation
      final dataKey = _generateDataKey(_challengesModel.currentSet);
      bool success = await _authManager.saveUserData(dataKey, _challengesModel.currentQuestions);
      
      if (!success) {
        _updateStateWithError("Failed to save your selections. Please try again.");
        return;
      }

      print("$dataKey saved: ${_challengesModel.currentQuestions}");

      if (_challengesModel.shouldProceedToSet2) {
        // Go to question set 2
        _updateState(_challengesModel.copyWith(
          currentSet: 2,
          isLoading: false,
          set1Completed: true,
        ));
        print("Navigating to Question Set 2");
      } else {
        // REFACTORED: Using helper method for completion state
        final completionState = _generateCompletionState(_challengesModel.currentSet);
        _updateState(_challengesModel.copyWith(
          isLoading: false,
          set1Completed: completionState.set1Completed,
          set2Completed: completionState.set2Completed,
          set3Completed: completionState.set3Completed,
        ));
        
        print("Completing challenges flow, navigating to Loading");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoadingView()),
        );
      }

    } catch (e) {
      print("Error saving question set: $e");
      _updateStateWithError("Error: $e");
    }
  }

  Future<void> goBack(BuildContext context) async {
    if (!_challengesModel.canGoBack) {
      // If can't go back within sets, pop the screen
      Navigator.pop(context);
      return;
    }

    // Clear current set data and go back to set 1
    if (_challengesModel.currentSet == 2) {
      await _authManager.clearUserData(_generateDataKey(2));
      _updateState(_challengesModel.copyWith(
        currentSet: 1,
        set2Questions: [],
        set2Completed: false,
        errorMessage: null,
      ));
      print("Navigated back to Question Set 1");
    }
  }

  void clearError() {
    if (_challengesModel.hasError) {
      _updateState(_challengesModel.copyWith(errorMessage: null));
    }
  }

  void showErrorMessage(BuildContext context, String message) {
    _authManager.showErrorMessage(context, message);
  }

  Future<void> cleanup() async {
    // REFACTORED: Using helper method and loop for cleanup
    final incompleteSets = _getIncompleteSets();
    for (final setNumber in incompleteSets) {
      await _authManager.clearUserData(_generateDataKey(setNumber));
    }
  }

  // REFACTORED: Helper methods for common operations
  void _updateStateWithError(String errorMessage) {
    _updateState(_challengesModel.copyWith(
      isLoading: false,
      errorMessage: errorMessage,
    ));
  }

  String _generateDataKey(int setNumber) {
    return 'questionSet$setNumber';
  }

  _CompletionState _generateCompletionState(int currentSet) {
    return _CompletionState(
      set1Completed: currentSet == 1,
      set2Completed: currentSet == 2,
      set3Completed: currentSet == 3,
    );
  }

  List<int> _getIncompleteSets() {
    final incompleteSets = <int>[];
    if (!_challengesModel.set1Completed) incompleteSets.add(1);
    if (!_challengesModel.set2Completed) incompleteSets.add(2);
    if (!_challengesModel.set3Completed) incompleteSets.add(3);
    return incompleteSets;
  }
}

// REFACTORED: Private helper class for completion state
class _CompletionState {
  final bool set1Completed;
  final bool set2Completed;
  final bool set3Completed;

  const _CompletionState({
    required this.set1Completed,
    required this.set2Completed,
    required this.set3Completed,
  });
} 