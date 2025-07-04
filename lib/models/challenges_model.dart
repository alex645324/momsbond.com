import 'package:flutter/material.dart';

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
      text: "worries about body changes?",
      dbValue: "Worry about weight and body changes?",
      backgroundColor: Color(0xFFEFD4E2),
      width: 280,
      height: 70,
      alignment: Alignment.centerRight,
    ),
    ChallengeQuestion(
      id: "depression_anxiety",
      text: "feeling postpartum depression or anxiety?",
      dbValue: "Postpartum depression or anxiety?",
      backgroundColor: Color(0xFFEDE4C6),
      width: 320,
      height: 80,
      alignment: Alignment.centerLeft,
    ),
    ChallengeQuestion(
      id: "loneliness",
      text: "loneliness because friends don't understand motherhood?",
      dbValue: "Loneliness because friends don't understand motherhood?",
      backgroundColor: Color(0xFFD8DAC5),
      width: 340,
      height: 80,
      alignment: Alignment.centerRight,
    ),
  ];

  static const List<ChallengeQuestion> _set2Available = [
    ChallengeQuestion(
      id: "lost_identity",
      text: "feeling lost outside of motherhood?",
      dbValue: "Feeling lost outside of motherhood?",
      backgroundColor: Color(0xFFEFD4E2),
      width: 280,
      height: 70,
      alignment: Alignment.centerLeft,
    ),
    ChallengeQuestion(
      id: "judging_parenting",
      text: "worried about others judging parenting style?",
      dbValue: "Worried about others judging parenting style?",
      backgroundColor: Color(0xFFEDE4C6),
      width: 320,
      height: 80,
      alignment: Alignment.centerRight,
    ),
    ChallengeQuestion(
      id: "fear_sick",
      text: "fear of getting sick and not supporting family?",
      dbValue: "Fear of getting sick and not supporting family?",
      backgroundColor: Color(0xFFD8DAC5),
      width: 340,
      height: 80,
      alignment: Alignment.centerLeft,
    ),
  ];

  static const List<ChallengeQuestion> _set3Available = [
    ChallengeQuestion(
      id: "fertility_stress",
      text: "stress about fertility and timing?",
      dbValue: "Stress about fertility and timing?",
      backgroundColor: Color(0xFFEED5B9),
      width: 280,
      height: 70,
      alignment: Alignment.centerLeft,
    ),
    ChallengeQuestion(
      id: "social_pressure",
      text: "pressure from family and friends about having kids?",
      dbValue: "Pressure from family and friends about having kids?",
      backgroundColor: Color(0xFFEFD4E2),
      width: 320,
      height: 80,
      alignment: Alignment.centerRight,
    ),
    ChallengeQuestion(
      id: "financial_worries",
      text: "worries about financial readiness for a baby?",
      dbValue: "Worries about financial readiness for a baby?",
      backgroundColor: Color(0xFFEDE4C6),
      width: 300,
      height: 75,
      alignment: Alignment.centerLeft,
    ),
    ChallengeQuestion(
      id: "relationship_changes",
      text: "concerns about how a baby will change your relationship?",
      dbValue: "Concerns about how a baby will change your relationship?",
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