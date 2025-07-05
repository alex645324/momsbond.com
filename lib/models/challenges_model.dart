import 'package:flutter/material.dart';
import '../config/app_config.dart';

class ChallengesModel {
  final int currentSet; // 1, 2, or 3 (3 = trying moms)
  final List<String> set1Questions;
  final List<String> set2Questions;
  final List<String> set3Questions;
  final bool isLoading;
  final String? errorMessage;
  final bool isMismatch;
  final bool set1Completed;
  final bool set2Completed;
  final bool set3Completed;

  const ChallengesModel({
    this.currentSet = 1,
    this.set1Questions = const [],
    this.set2Questions = const [],
    this.set3Questions = const [],
    this.isLoading = false,
    this.errorMessage,
    this.isMismatch = false,
    this.set1Completed = false,
    this.set2Completed = false,
    this.set3Completed = false,
  });

  ChallengesModel copyWith({
    int? currentSet,
    List<String>? set1Questions,
    List<String>? set2Questions,
    List<String>? set3Questions,
    bool? isLoading,
    String? errorMessage,
    bool? isMismatch,
    bool? set1Completed,
    bool? set2Completed,
    bool? set3Completed,
  }) {
    return ChallengesModel(
      currentSet: currentSet ?? this.currentSet,
      set1Questions: set1Questions ?? this.set1Questions,
      set2Questions: set2Questions ?? this.set2Questions,
      set3Questions: set3Questions ?? this.set3Questions,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      isMismatch: isMismatch ?? this.isMismatch,
      set1Completed: set1Completed ?? this.set1Completed,
      set2Completed: set2Completed ?? this.set2Completed,
      set3Completed: set3Completed ?? this.set3Completed,
    );
  }

  // REFACTORED: Centralized question set registry
  static final Map<int, List<ChallengeQuestion>> _questionSets = {
    1: _set1Available,
    2: _set2Available,
    3: _set3Available,
  };

  // REFACTORED: Generic helper to get data by set number
  T _getBySet<T>({
    required T set1Value,
    required T set2Value,
    required T set3Value,
    T? defaultValue,
  }) {
    switch (currentSet) {
      case 1: return set1Value;
      case 2: return set2Value;
      case 3: return set3Value;
      default: return defaultValue ?? set1Value;
    }
  }

  // REFACTORED: Simplified current questions getter
  List<String> get currentQuestions => _getBySet(
    set1Value: set1Questions,
    set2Value: set2Questions,
    set3Value: set3Questions,
    defaultValue: <String>[],
  );

  // REFACTORED: Simplified current available questions getter
  List<ChallengeQuestion> get currentAvailableQuestions => 
    _questionSets[currentSet] ?? _set1Available;

  // REFACTORED: Cached combined questions for efficiency
  static List<ChallengeQuestion>? _allQuestionsCache;
  static List<ChallengeQuestion> get _allQuestions {
    _allQuestionsCache ??= [
      ..._set1Available,
      ..._set2Available,
      ..._set3Available,
    ];
    return _allQuestionsCache!;
  }

  // REFACTORED: More efficient question lookup
  String _getDbValueForId(String questionId) {
    final question = _allQuestions.firstWhere(
      (q) => q.id == questionId,
      orElse: () => throw ArgumentError('Question ID not found: $questionId'),
    );
    return question.dbValue;
  }

  // REFACTORED: Helper to check if question exists
  static bool hasQuestionId(String questionId) {
    return _allQuestions.any((q) => q.id == questionId);
  }

  // REFACTORED: Get question by ID
  static ChallengeQuestion? getQuestionById(String questionId) {
    try {
      return _allQuestions.firstWhere((q) => q.id == questionId);
    } catch (e) {
      return null;
    }
  }

  // REFACTORED: Get all questions for a specific set
  static List<ChallengeQuestion> getQuestionsForSet(int setNumber) {
    return _questionSets[setNumber] ?? [];
  }

  bool get hasCurrentSelection => currentQuestions.isNotEmpty;
  bool get hasError => errorMessage != null;
  bool get canProceed => hasCurrentSelection && !isLoading;
  bool get isSet1 => currentSet == 1;
  bool get isSet2 => currentSet == 2;
  bool get isSet3 => currentSet == 3;

  bool isQuestionSelected(String questionId) {
    final dbValue = _getDbValueForId(questionId);
    return currentQuestions.contains(dbValue);
  }

  String get currentSetTitle => "";
  
  // Navigation state
  bool get canGoBack => currentSet == 2;  // Can go back from set 2 to set 1
  bool get canGoForward {
    if (currentSet == 1) {
      return hasCurrentSelection; // Can go forward if has selection
    } else {
      return hasCurrentSelection; // Can complete if has selection
    }
  }
  
  bool get shouldProceedToSet2 => currentSet == 1 && isMismatch;
  bool get shouldComplete => (currentSet == 1 && !isMismatch) || currentSet == 2;

  // REFACTORED: Moved question definitions to private static methods for better organization
  static const List<ChallengeQuestion> _set1Available = [
    ChallengeQuestion(
      id: "body_changes",
      text: ChallengeTexts.bodyChanges,
      dbValue: ChallengeTexts.bodyChangesDb,
      backgroundColor: Color(0xFFEFD4E2),
      width: 280,
      height: 70,
      alignment: Alignment.centerRight,
    ),
    ChallengeQuestion(
      id: "depression_anxiety",
      text: ChallengeTexts.depressionAnxiety,
      dbValue: ChallengeTexts.depressionAnxietyDb,
      backgroundColor: Color(0xFFEDE4C6),
      width: 320,
      height: 80,
      alignment: Alignment.centerLeft,
    ),
    ChallengeQuestion(
      id: "loneliness",
      text: ChallengeTexts.loneliness,
      dbValue: ChallengeTexts.lonelinessDb,
      backgroundColor: Color(0xFFD8DAC5),
      width: 340,
      height: 80,
      alignment: Alignment.centerRight,
    ),
  ];

  static const List<ChallengeQuestion> _set2Available = [
    ChallengeQuestion(
      id: "lost_identity",
      text: ChallengeTexts.lostIdentity,
      dbValue: ChallengeTexts.lostIdentityDb,
      backgroundColor: Color(0xFFEFD4E2),
      width: 280,
      height: 70,
      alignment: Alignment.centerLeft,
    ),
    ChallengeQuestion(
      id: "judging_parenting",
      text: ChallengeTexts.judgingParenting,
      dbValue: ChallengeTexts.judgingParentingDb,
      backgroundColor: Color(0xFFEDE4C6),
      width: 320,
      height: 80,
      alignment: Alignment.centerRight,
    ),
    ChallengeQuestion(
      id: "fear_sick",
      text: ChallengeTexts.fearSick,
      dbValue: ChallengeTexts.fearSickDb,
      backgroundColor: Color(0xFFD8DAC5),
      width: 340,
      height: 80,
      alignment: Alignment.centerLeft,
    ),
  ];

  static const List<ChallengeQuestion> _set3Available = [
    ChallengeQuestion(
      id: "fertility_stress",
      text: ChallengeTexts.fertilityStress,
      dbValue: ChallengeTexts.fertilityStressDb,
      backgroundColor: Color(0xFFEED5B9),
      width: 280,
      height: 70,
      alignment: Alignment.centerLeft,
    ),
    ChallengeQuestion(
      id: "social_pressure",
      text: ChallengeTexts.socialPressure,
      dbValue: ChallengeTexts.socialPressureDb,
      backgroundColor: Color(0xFFEFD4E2),
      width: 320,
      height: 80,
      alignment: Alignment.centerRight,
    ),
    ChallengeQuestion(
      id: "relationship_changes",
      text: ChallengeTexts.relationshipChanges,
      dbValue: ChallengeTexts.relationshipChangesDb,
      backgroundColor: Color(0xFFD8DAC5),
      width: 340,
      height: 80,
      alignment: Alignment.centerRight,
    ),
  ];

  // REFACTORED: Maintain backward compatibility with public static getters
  static List<ChallengeQuestion> get set1Available => _set1Available;
  static List<ChallengeQuestion> get set2Available => _set2Available;
  static List<ChallengeQuestion> get set3Available => _set3Available;
}

class ChallengeQuestion {
  final String id;
  final String text;
  final String dbValue;
  final Color backgroundColor;
  final double width;
  final double height;
  final Alignment alignment;

  const ChallengeQuestion({
    required this.id,
    required this.text,
    required this.dbValue,
    required this.backgroundColor,
    required this.width,
    required this.height,
    required this.alignment,
  });
}

// Circle configuration for decorative elements
class CircleConfig {
  final double? left;
  final double? right;
  final double? top;
  final double? bottom;
  final double width;
  final double height;
  final double opacity;

  const CircleConfig({
    this.left,
    this.right,
    this.top,
    this.bottom,
    required this.width,
    required this.height,
    this.opacity = 0.4,
  });
} 