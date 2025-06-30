class StageModel {
  final List<String> selectedStages;
  final bool isLoading;
  final String? errorMessage;
  final bool hasSubmitted;

  const StageModel({
    this.selectedStages = const [],
    this.isLoading = false,
    this.errorMessage,
    this.hasSubmitted = false,
  });

  StageModel copyWith({
    List<String>? selectedStages,
    bool? isLoading,
    String? errorMessage,
    bool? hasSubmitted,
  }) {
    return StageModel(
      selectedStages: selectedStages ?? this.selectedStages,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      hasSubmitted: hasSubmitted ?? this.hasSubmitted,
    );
  }

  bool get hasSelection => selectedStages.isNotEmpty;
  bool get hasError => errorMessage != null;
  
  bool isStageSelected(String stage) => selectedStages.contains(stage);
  
  // Available motherhood stages (must match existing values for compatibility)
  static const List<String> availableStages = [
    'pregnant?',
    'toddler mom?',
    'teen mom?',
    'adult mom?',
  ];
  
  // Map display values to database values for compatibility
  static const Map<String, String> stageMapping = {
    'pregnant': 'pregnant?',
    'toddler': 'toddler mom?',
    'teen': 'teen mom?',
    'adult': 'adult mom?',
  };
  
  static String getDisplayValue(String dbValue) {
    return stageMapping.entries
        .firstWhere((entry) => entry.value == dbValue, 
                   orElse: () => MapEntry(dbValue, dbValue))
        .key;
  }
  
  static String getDatabaseValue(String displayValue) {
    return stageMapping[displayValue] ?? displayValue;
  }
} 