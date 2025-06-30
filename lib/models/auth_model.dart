class AuthModel {
  final String? userId;
  final String? userEmail;
  final String? userName;
  final bool isLoading;
  final String? errorMessage;
  final bool hasCompletedOnboarding;

  const AuthModel({
    this.userId,
    this.userEmail,
    this.userName,
    this.isLoading = false,
    this.errorMessage,
    this.hasCompletedOnboarding = false,
  });

  AuthModel copyWith({
    String? userId,
    String? userEmail,
    String? userName,
    bool? isLoading,
    String? errorMessage,
    bool? hasCompletedOnboarding,
  }) {
    return AuthModel(
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
    );
  }

  bool get isAuthenticated => userId != null;
  bool get hasError => errorMessage != null;
} 