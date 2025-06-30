import 'package:flutter/material.dart';
import '../Database_logic/simple_auth_manager.dart';
import '../models/challenges_model.dart';
import '../views/loading_view.dart';

class ChallengesViewModel extends ChangeNotifier {
  final SimpleAuthManager _authManager = SimpleAuthManager();
  ChallengesModel _challengesModel = const ChallengesModel();

  // TODO: FUTURE FEATURE - Add editing mode support for returning users
  // This would require:
  // - bool _isEditMode = false; // Track if we're editing existing data vs initial setup
  // - loadExistingChallenges() method to populate current selections when editing
  // - updateExistingChallenges() method that updates rather than creates new data
  // - Different UI flow for editing (show current selections, allow changes, save updates)
  // - Navigation back to dashboard after editing vs continuing onboarding flow

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

  void toggleQuestion(String questionId) {
    // Get the database value for this question
    final dbValue = _getDbValueForId(questionId);
    
    List<String> updatedQuestions;
    
    if (_challengesModel.currentSet == 1) {
      updatedQuestions = List.from(_challengesModel.set1Questions);
      if (updatedQuestions.contains(dbValue)) {
        updatedQuestions.remove(dbValue);
      } else {
        updatedQuestions.add(dbValue);
      }
      
      _updateState(_challengesModel.copyWith(
        set1Questions: updatedQuestions,
        errorMessage: null,
      ));
    } else {
      updatedQuestions = List.from(_challengesModel.set2Questions);
      if (updatedQuestions.contains(dbValue)) {
        updatedQuestions.remove(dbValue);
      } else {
        updatedQuestions.add(dbValue);
      }
      
      _updateState(_challengesModel.copyWith(
        set2Questions: updatedQuestions,
        errorMessage: null,
      ));
    }
    
    print("Question toggled: $questionId -> $dbValue");
    print("Current set ${_challengesModel.currentSet} questions: $updatedQuestions");
  }

  String _getDbValueForId(String questionId) {
    final allQuestions = [
      ...ChallengesModel.set1Available,
      ...ChallengesModel.set2Available
    ];
    return allQuestions.firstWhere((q) => q.id == questionId).dbValue;
  }

  Future<void> goForward(BuildContext context) async {
    if (!_challengesModel.canGoForward) return;

    if (_challengesModel.currentQuestions.isEmpty) {
      _updateState(_challengesModel.copyWith(
        errorMessage: "Please select at least one challenge",
      ));
      return;
    }

    _updateState(_challengesModel.copyWith(isLoading: true, errorMessage: null));

    try {
      // Save current set data
      final dataKey = 'questionSet${_challengesModel.currentSet}';
      bool success = await _authManager.saveUserData(dataKey, _challengesModel.currentQuestions);
      
      if (!success) {
        _updateState(_challengesModel.copyWith(
          isLoading: false,
          errorMessage: "Failed to save your selections. Please try again.",
        ));
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
        // Complete the flow
        _updateState(_challengesModel.copyWith(
          isLoading: false,
          set1Completed: _challengesModel.currentSet == 1,
          set2Completed: _challengesModel.currentSet == 2,
        ));
        
        print("Completing challenges flow, navigating to Loading");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoadingView()),
        );
      }

    } catch (e) {
      print("Error saving question set: $e");
      _updateState(_challengesModel.copyWith(
        isLoading: false,
        errorMessage: "Error: $e",
      ));
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
      await _authManager.clearUserData('questionSet2');
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
    // Clear any incomplete data on dispose
    if (!_challengesModel.set1Completed) {
      await _authManager.clearUserData('questionSet1');
    }
    if (!_challengesModel.set2Completed) {
      await _authManager.clearUserData('questionSet2');
    }
  }
} 