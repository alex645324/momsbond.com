/// Configuration values for the application
class AppConfig {
  /// Duration of chat conversations in seconds
  static const int chatDurationSeconds = 30; // 5 minutes

  // Private constructor to prevent instantiation
  AppConfig._();
}

/// Centralized text strings for the application
class AppTexts {
  // Mom Stages
  static const momStages = MomStageTexts();
  
  // Challenge Questions
  static const challenges = ChallengeTexts();
  
  // Authentication
  static const auth = AuthTexts();
  
  // Dashboard
  static const dashboard = DashboardTexts();
  
  // Chat & Messages
  static const chat = ChatTexts();
  
  // Common UI
  static const ui = UITexts();
  
  // Homepage
  static const homepage = HomepageTexts();

  // Private constructor to prevent instantiation
  AppTexts._();
}

/// Mom stage related text
class MomStageTexts {
  const MomStageTexts();
  
  // Stage identifiers
  static const String trying = 'trying';
  static const String pregnant = 'pregnant';
  static const String toddler = 'toddler';
  static const String teen = 'teen';
  static const String adult = 'adult';
  
  // Stage display text
  static const String tryingLabel = 'trying moms?';
  static const String pregnantLabel = 'pregnant?';
  static const String toddlerLabel = 'toddler mom?';
  static const String teenLabel = 'teen mom?';
  static const String adultLabel = 'adult mom?';
  
  // Stage selection screen text
  static const String selectionTitle = 'what stage are you in?';
  static const String selectionSubtitle = 'this helps us match you with the best fit :)';
}

/// Challenge questions text
class ChallengeTexts {
  const ChallengeTexts();
  
  // Screen titles
  static const String tryingTitle = 'what challenges are you\nfacing while trying?';
  static const String generalTitle = 'what kinds of challenges\nhave you encountered?';
  
  // Set 1 Questions (General motherhood challenges)
  static const String bodyChanges = 'worries about body changes?';
  static const String bodyChangesDb = 'Worry about weight and body changes?';
  
  static const String depressionAnxiety = 'feeling postpartum depression or anxiety?';
  static const String depressionAnxietyDb = 'Postpartum depression or anxiety?';
  
  static const String loneliness = 'loneliness because friends don\'t understand motherhood?';
  static const String lonelinessDb = 'Loneliness because friends don\'t understand motherhood?';
  
  // Set 2 Questions (Additional motherhood challenges)
  static const String lostIdentity = 'feeling lost outside of motherhood?';
  static const String lostIdentityDb = 'Feeling lost outside of motherhood?';
  
  static const String judgingParenting = 'worried about others judging parenting style?';
  static const String judgingParentingDb = 'Worried about others judging parenting style?';
  
  static const String fearSick = 'fear of getting sick and not supporting family?';
  static const String fearSickDb = 'Fear of getting sick and not supporting family?';
  
  // Set 3 Questions (Trying to conceive challenges)
  static const String fertilityStress = 'stress about fertility and timing?';
  static const String fertilityStressDb = 'Stress about fertility and timing?';
  
  static const String socialPressure = 'pressure from family and friends about having kids?';
  static const String socialPressureDb = 'Pressure from family and friends about having kids?';
  
  static const String financialWorries = 'worries about financial readiness for a baby?';
  static const String financialWorriesDb = 'Worries about financial readiness for a baby?';
  
  static const String relationshipChanges = 'concerns about how a baby will change your relationship?';
  static const String relationshipChangesDb = 'Concerns about how a baby will change your relationship?';
}

/// Authentication related text
class AuthTexts {
  const AuthTexts();
  
  // Screen titles
  static const String createAccount = 'Create Account';
  static const String welcomeBack = 'Welcome Back';
  
  // Button labels
  static const String signUp = 'Sign Up';
  static const String signIn = 'Sign In';
  
  // Form fields
  static const String usernameHint = 'Username';
  static const String passwordHint = 'Password';
  static const String keepSignedIn = 'Keep me signed in';
  
  // Error messages
  static const String fillAllFields = 'Please fill in all fields';
  static const String genericError = 'An error occurred. Please try again.';
  static const String signInPrompt = 'Enter your username and password to sign in';
  
  // Username not found error with tip
  static String usernameNotFoundError(String message) => 
    '$message\n\nTip: Check your spelling or create a new account if you haven\'t already.';
}

/// Dashboard related text
class DashboardTexts {
  const DashboardTexts();
  
  // Main text
  static const String homebaseTitle = 'this is your homebase';
  static const String homebaseSubtitle = 'where you maintain and create new connections.';
  
  // Connection text
  static const String noConnections = 'No connections yet.';
  static const String firstConnectionPrompt = 'Start by making your first connection!';
  static const String findNewConnection = 'find new connection :)';
  
  // User info (placeholders)
  static const String usernamePrefix = 'username: ';
  static const String instaHandle = 'insta: realconnection.com_';
  
  // Default avatar letter
  static const String defaultAvatarLetter = 'U';
}

/// Chat and messages related text
class ChatTexts {
  const ChatTexts();
  
  // Input field
  static const String inputHint = 'say how you feel...';
  static const String defaultStarterText = 'Start your conversation...';
  
  // Conversation ending
  static const String conversationEnded = 'Conversations Ended';
  static const String feedbackQuestion = 'did you feel connected to this person?';
  static const String savingFeedback = 'Saving your feedback...';
  static const String feedbackYes = 'yes';
  static const String feedbackNo = 'no';
  
  // Thank you section
  static const String thanksForFeedback = 'Thanks for your feedback!';
  static const String enjoyedConnecting = 'We hope you enjoyed connecting with another mom';
  static const String continueButton = 'Continue';
  
  // Error states
  static const String chatError = 'Chat Error';
  static const String errorOccurred = 'An error occurred';
  static const String retryButton = 'Retry';
}

/// Common UI text
class UITexts {
  const UITexts();
  
  // Navigation
  static const String goToDashboard = 'Go to dashboard';
  
  // Invitations
  static const String chatInvitation = 'Chat Invitation';
  static const String wantsToChat = 'wants to chat with you.';
  static const String startConversationPrompt = 'Would you like to start a conversation?';
  static const String decline = 'Decline';
  static const String accept = 'Accept';
  static const String dismiss = 'Dismiss';
  
  // Loading
  static const String initializingApp = 'Initializing app...';
}

/// Homepage related text
class HomepageTexts {
  const HomepageTexts();
  
  static const String mainDescription = 'We\'re here to help you connect with \nother mothers at your stage.';
  static const String getStarted = 'Get Started';
} 