import 'package:flutter/material.dart';

class ChallengesModel {
  final int currentSet; // 1 or 2
  final List<String> set1Questions;
  final List<String> set2Questions;
  final bool isLoading;
  final String? errorMessage;
  final bool isMismatch;
  final bool set1Completed;
  final bool set2Completed;

  const ChallengesModel({
    this.currentSet = 1,
    this.set1Questions = const [],
    this.set2Questions = const [],
    this.isLoading = false,
    this.errorMessage,
    this.isMismatch = false,
    this.set1Completed = false,
    this.set2Completed = false,
  });

  ChallengesModel copyWith({
    int? currentSet,
    List<String>? set1Questions,
    List<String>? set2Questions,
    bool? isLoading,
    String? errorMessage,
    bool? isMismatch,
    bool? set1Completed,
    bool? set2Completed,
  }) {
    return ChallengesModel(
      currentSet: currentSet ?? this.currentSet,
      set1Questions: set1Questions ?? this.set1Questions,
      set2Questions: set2Questions ?? this.set2Questions,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      isMismatch: isMismatch ?? this.isMismatch,
      set1Completed: set1Completed ?? this.set1Completed,
      set2Completed: set2Completed ?? this.set2Completed,
    );
  }

  // Current set properties
  List<String> get currentQuestions => currentSet == 1 ? set1Questions : set2Questions;
  bool get hasCurrentSelection => currentQuestions.isNotEmpty;
  bool get hasError => errorMessage != null;
  bool get canProceed => hasCurrentSelection && !isLoading;
  bool get isSet1 => currentSet == 1;
  bool get isSet2 => currentSet == 2;
  
  // Available questions for each set (must match existing values)
  static const List<ChallengeQuestion> set1Available = [
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

  static const List<ChallengeQuestion> set2Available = [
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

  List<ChallengeQuestion> get currentAvailableQuestions => 
      currentSet == 1 ? set1Available : set2Available;

  bool isQuestionSelected(String questionId) {
    final dbValue = _getDbValueForId(questionId);
    return currentQuestions.contains(dbValue);
  }

  String _getDbValueForId(String questionId) {
    final allQuestions = [...set1Available, ...set2Available];
    return allQuestions.firstWhere((q) => q.id == questionId).dbValue;
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