class WelcomeModel {
  final bool isVisible;
  final String primaryText;
  final String secondaryText;

  const WelcomeModel({
    this.isVisible = true,
    this.primaryText = "a gentle space.",
    this.secondaryText = "just for you",
  });

  WelcomeModel copyWith({
    bool? isVisible,
    String? primaryText,
    String? secondaryText,
  }) {
    return WelcomeModel(
      isVisible: isVisible ?? this.isVisible,
      primaryText: primaryText ?? this.primaryText,
      secondaryText: secondaryText ?? this.secondaryText,
    );
  }
} 