import 'package:flutter/material.dart';
import '../Database_logic/simple_auth_manager.dart';
import '../Templates/navigation_helper.dart';
import '../models/stage_model.dart';

class StageViewModel extends ChangeNotifier {
  final SimpleAuthManager _authManager = SimpleAuthManager();
  StageModel _stageModel = const StageModel();

  // TODO: FUTURE FEATURE - Add editing mode support for returning users
  // This would require:
  // - bool _isEditMode = false; // Track if we're editing existing data vs initial setup
  // - loadExistingStages() method to populate current selections when editing
  // - updateExistingStages() method that updates rather than creates new data
  // - Different navigation flow for editing (return to dashboard vs continue onboarding)

  StageModel get stageModel => _stageModel;
  List<String> get selectedStages => _stageModel.selectedStages;
  bool get isLoading => _stageModel.isLoading;
  String? get errorMessage => _stageModel.errorMessage;
  bool get hasSelection => _stageModel.hasSelection;
  bool get hasError => _stageModel.hasError;

  void _updateState(StageModel newModel) {
    _stageModel = newModel;
    notifyListeners();
  }

  bool isStageSelected(String stage) {
    return _stageModel.isStageSelected(stage);
  }

  void toggleStage(String displayStage) {
    // Convert display value to database value for consistency
    final dbStage = StageModel.getDatabaseValue(displayStage);
    
    List<String> updatedStages = List.from(_stageModel.selectedStages);
    
    if (updatedStages.contains(dbStage)) {
      updatedStages.remove(dbStage);
    } else {
      updatedStages.add(dbStage);
    }
    
    _updateState(_stageModel.copyWith(
      selectedStages: updatedStages,
      errorMessage: null, // Clear any previous errors
    ));
    
    print("Stage toggled: $displayStage -> $dbStage");
    print("Current selection: $updatedStages");
  }

  Future<void> submitStages(BuildContext context) async {
    if (_stageModel.selectedStages.isEmpty) {
      _updateState(_stageModel.copyWith(
        errorMessage: "Please select at least one stage",
      ));
      return;
    }

    _updateState(_stageModel.copyWith(isLoading: true, errorMessage: null));

    try {
      print("Submitting stages: ${_stageModel.selectedStages}");
      
      bool success = await _authManager.saveUserData('momStage', _stageModel.selectedStages);
      
      if (!success) {
        _updateState(_stageModel.copyWith(
          isLoading: false,
          errorMessage: "Failed to save your selection. Please try again.",
        ));
        return;
      }

      print("Stages saved successfully: ${_stageModel.selectedStages}");
      
      _updateState(_stageModel.copyWith(
        isLoading: false,
        hasSubmitted: true,
      ));

      // Navigate based on selected stages using existing logic
      NavigationHelper.navigateBasedOnStages(context, _stageModel.selectedStages);

    } catch (e) {
      print("Error saving mom stages: $e");
      _updateState(_stageModel.copyWith(
        isLoading: false,
        errorMessage: "Error: $e",
      ));
    }
  }

  void clearError() {
    if (_stageModel.hasError) {
      _updateState(_stageModel.copyWith(errorMessage: null));
    }
  }

  void showErrorMessage(BuildContext context, String message) {
    _authManager.showErrorMessage(context, message);
  }
} 