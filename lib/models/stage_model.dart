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
    'trying moms?',
    'pregnant?',
    'new mom?',
    'teen mom?',
    'adult mom?',
  ];
  
  // Map display values to database values for compatibility
  static const Map<String, String> stageMapping = {
    'trying': 'trying moms?',
    'pregnant': 'pregnant?',
    'toddler': 'new mom?',
    'teen': 'teen mom?',
    'adult': 'adult mom?',
  };
  
  // REFACTORED: Using helper method to reduce repetitive fallback logic
  static String getDisplayValue(String dbValue) {
    return _findKeyByValue(dbValue, dbValue);
  }
  
  // REFACTORED: Using helper method for consistent fallback pattern
  static String getDatabaseValue(String displayValue) {
    return _safeMapLookup(displayValue, displayValue);
  }
  
  // REFACTORED: Private helper for reverse map lookup with fallback
  static String _findKeyByValue(String value, String fallback) {
    return stageMapping.entries
        .firstWhere((entry) => entry.value == value, 
                   orElse: () => MapEntry(fallback, fallback))
        .key;
  }
  
  // REFACTORED: Private helper for safe map lookup with fallback
  static String _safeMapLookup(String key, String fallback) {
    return stageMapping[key] ?? fallback;
  }
  
  // REFACTORED: Added validation helpers (private - don't change public API)
  static bool _isValidDisplayValue(String displayValue) {
    return stageMapping.containsKey(displayValue);
  }
  
  static bool _isValidDatabaseValue(String dbValue) {
    return stageMapping.containsValue(dbValue);
  }
  
  // REFACTORED: Added utility methods for common operations (private)
  static List<String> _getAllDisplayValues() {
    return stageMapping.keys.toList();
  }
  
  static List<String> _getAllDatabaseValues() {
    return stageMapping.values.toList();
  }
} 