/// Configuration values for the application
class AppConfig {
  /// Duration of chat conversations in seconds
  static const int chatDurationSeconds = 600; // 10 minutes

  // Private constructor to prevent instantiation
  AppConfig._();
}

// Private mixin to handle text selection
mixin _TextSelector {
  static String _pick(String en, String es, bool isEs) => isEs ? es : en;
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

  // Language
  static const language = LanguageTexts();
  
  // Private constructor to prevent instantiation
  AppTexts._();
}

/// Mom stage related text
class MomStageTexts with _TextSelector {
  const MomStageTexts();
  
  // Stage identifiers
  static const String trying = 'trying';
  static const String pregnant = 'pregnant';
  static const String toddler = 'toddler';
  static const String teen = 'teen';
  static const String adult = 'adult';
  
  // Stage display text
  static const String tryingLabel = 'Newborn stage (0–3 months)';
  static const String pregnantLabel = 'Infant stage (3–12 months)';
  static const String toddlerLabel = 'Toddler stage (1–3 years)';
  static const String teenLabel = 'Preschool & Early School-age (3–6 years)';
  static const String adultLabel = 'Older Kids (6+ years)';
  
  // Stage selection screen text
  static const String selectionTitle = 'what stage are you in?';
  static const String selectionSubtitle = 'this helps us match you with the best fit :)';
}

/// Challenge questions text
class ChallengeTexts with _TextSelector {
  const ChallengeTexts();
  
  // Screen titles
  static const String tryingTitle = 'what challenges are you\nfacing while trying?';
  static const String generalTitle = 'what kinds of challenges\nhave you encountered?';
  
  // Set 1 Questions (New mothers)
  static const String bodyChanges = 'Since giving birth, do you feel people care more about the baby than about you?';
  static const String bodyChangesDb = 'Since giving birth, do you feel people care more about the baby than about you?';
  
  static const String depressionAnxiety = 'Do you feel like you can\'t be fully honest about how you\'re doing without being judged?';
  static const String depressionAnxietyDb = 'Do you feel like you can\'t be fully honest about how you\'re doing without being judged?';
  
  static const String loneliness = 'Have you lost friends or connections since becoming a mom?';
  static const String lonelinessDb = 'Have you lost friends or connections since becoming a mom?';
  
  // Set 2 Questions (Additional motherhood challenges)
  static const String lostIdentity = 'Since giving birth, do you feel people care more about the baby than about you?';
  static const String lostIdentityDb = 'Since giving birth, do you feel people care more about the baby than about you?';
  
  static const String judgingParenting = 'Do you feel like you can\'t be fully honest about how you\'re doing without being judged?';
  static const String judgingParentingDb = 'Do you feel like you can\'t be fully honest about how you\'re doing without being judged?';
  
  static const String fearSick = 'Have you lost friends or connections since becoming a mom?';
  static const String fearSickDb = 'Have you lost friends or connections since becoming a mom?';
  
  // Set 3 Questions (Trying to conceive challenges)
  static const String fertilityStress = 'Since giving birth, do you feel people care more about the baby than about you?';
  static const String fertilityStressDb = 'Since giving birth, do you feel people care more about the baby than about you?';
  
  static const String socialPressure = 'Do you feel like you can\'t be fully honest about how you\'re doing without being judged?';
  static const String socialPressureDb = 'Do you feel like you can\'t be fully honest about how you\'re doing without being judged?';
  
  static const String financialWorries = 'Have you lost friends or connections since becoming a mom?';
  static const String financialWorriesDb = 'Have you lost friends or connections since becoming a mom?';
  
  static const String relationshipChanges = 'Do you feel like you can\'t be fully honest about how you\'re doing without being judged?';
  static const String relationshipChangesDb = 'Do you feel like you can\'t be fully honest about how you\'re doing without being judged?';
}

/// Authentication related text
class AuthTexts with _TextSelector {
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
class DashboardTexts with _TextSelector {
  const DashboardTexts();
  
  // Main text
  static const String homebaseTitle = 'Homebase';
  
  // Updated to be a function that takes connection count
  static String homebaseSubtitle(int connectionCount) {
    if (connectionCount == 0) {
      return 'No connections yet';
    } else if (connectionCount == 1) {
      return 'Connection score: 1 strong connection';
    } else {
      return 'Connection score: $connectionCount strong connections';
    }
  }
  
  // Connection text
  static const String noConnections = 'No connections yet.';
  static const String firstConnectionPrompt = 'Start by making your first connection!';
  static const String findNewConnection = 'find new connection :)';
  
  // User info (placeholders)
  static const String usernamePrefix = 'username: ';
  static const String defaultAvatarLetter = 'U';
}

/// Chat and messages related text
class ChatTexts with _TextSelector {
  const ChatTexts();
  
  // Input field
  static const String inputHint = 'say how you feel...';
  static const String inputStarterText = 'Since becoming a mom, I feel like I\'ve disappeared from my own story. Everyone asks about the baby, but no one asks about me. I\'ve been ';
  static const String defaultStarterText = 'Start your conversation...';
  
  // Chat starter
  static const String chatStarter = 'Since becoming a mom, I feel like I\'ve disappeared from my own story. Everyone asks about the baby, but no one asks about me. I\'ve been…';
  
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
class UITexts with _TextSelector {
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
  // Loading messages
  static const String findingConnection = 'finding someone\nwho understands you';
}

/// Homepage related text
class HomepageTexts with _TextSelector {
  const HomepageTexts();
  
  // Main description
  static const String mainDescription = "We built a space that connects you with moms who've been in your place.";
  // Tagline inside description card
  static const String cardSubtitle = "We connect you with moms who feel exactly what you’re feeling.";
}

/// Language selection text
class LanguageTexts with _TextSelector {
  const LanguageTexts();
  
  String get english => 'English';
  String get spanish => 'Español';
}

// ============================================================
// Spanish translations (ES)
// ============================================================

/// Aggregator for Spanish texts (structure mirrors AppTexts)
class AppTextsEs {
  static const momStages = MomStageTextsEs();
  static const challenges = ChallengeTextsEs();
  static const auth = AuthTextsEs();
  static const dashboard = DashboardTextsEs();
  static const chat = ChatTextsEs();
  static const ui = UITextsEs();
  static const homepage = HomepageTextsEs();

  const AppTextsEs._();
}

/// Mom stage related text (Spanish)
class MomStageTextsEs with _TextSelector {
  const MomStageTextsEs();

  // Stage identifiers (keep english codes for backend consistency)
  static const String trying = MomStageTexts.trying;
  static const String pregnant = MomStageTexts.pregnant;
  static const String toddler = MomStageTexts.toddler;
  static const String teen = MomStageTexts.teen;
  static const String adult = MomStageTexts.adult;

  // Stage display text (Spanish)
  static const String tryingLabel = 'Etapa de recién nacido (0–3 meses)';
  static const String pregnantLabel = 'Etapa de bebé (3–12 meses)';
  static const String toddlerLabel = 'Etapa de niño pequeño (1–3 años)';
  static const String teenLabel = 'Preescolar y edad escolar temprana (3–6 años)';
  static const String adultLabel = 'Niños mayores (6+ años)';

  // Stage selection screen text
  static const String selectionTitle = '¿en qué etapa estás?';
  static const String selectionSubtitle = 'Esto nos ayuda a encontrarte la mejor opción :)';
}

/// Challenge questions text (Spanish)
class ChallengeTextsEs with _TextSelector {
  const ChallengeTextsEs();

  // Screen titles
  static const String tryingTitle = '¿qué desafíos enfrentas\nmientras intentas concebir?';
  static const String generalTitle = '¿qué tipos de desafíos\nhas enfrentado?';

  // Set 1 Questions (General motherhood challenges)
  static const String bodyChanges = 'Desde que diste a luz, ¿sientes que la gente se preocupa más por el bebé que por ti?';
  static const String bodyChangesDb = 'Desde que diste a luz, ¿sientes que la gente se preocupa más por el bebé que por ti?';

  static const String depressionAnxiety = '¿Sientes que no puedes ser completamente honesta sobre cómo te sientes sin ser juzgada?';
  static const String depressionAnxietyDb = '¿Sientes que no puedes ser completamente honesta sobre cómo te sientes sin ser juzgada?';

  static const String loneliness = '¿Has perdido amistades o conexiones desde que te convertiste en madre?';
  static const String lonelinessDb = '¿Has perdido amistades o conexiones desde que te convertiste en madre?';

  // Set 2 Questions
  static const String lostIdentity = 'Desde que diste a luz, ¿sientes que la gente se preocupa más por el bebé que por ti?';
  static const String lostIdentityDb = 'Desde que diste a luz, ¿sientes que la gente se preocupa más por el bebé que por ti?';

  static const String judgingParenting = '¿Sientes que no puedes ser completamente honesta sobre cómo te sientes sin ser juzgada?';
  static const String judgingParentingDb = '¿Sientes que no puedes ser completamente honesta sobre cómo te sientes sin ser juzgada?';

  static const String fearSick = '¿Has perdido amistades o conexiones desde que te convertiste en madre?';
  static const String fearSickDb = '¿Has perdido amistades o conexiones desde que te convertiste en madre?';

  // Set 3 Questions (Trying to conceive challenges)
  static const String fertilityStress = 'Desde que diste a luz, ¿sientes que la gente se preocupa más por el bebé que por ti?';
  static const String fertilityStressDb = 'Desde que diste a luz, ¿sientes que la gente se preocupa más por el bebé que por ti?';

  static const String socialPressure = '¿Sientes que no puedes ser completamente honesta sobre cómo te sientes sin ser juzgada?';
  static const String socialPressureDb = '¿Sientes que no puedes ser completamente honesta sobre cómo te sientes sin ser juzgada?';

  static const String financialWorries = '¿Has perdido amistades o conexiones desde que te convertiste en madre?';
  static const String financialWorriesDb = '¿Has perdido amistades o conexiones desde que te convertiste en madre?';

  static const String relationshipChanges = '¿Sientes que no puedes ser completamente honesta sobre cómo te sientes sin ser juzgada?';
  static const String relationshipChangesDb = '¿Sientes que no puedes ser completamente honesta sobre cómo te sientes sin ser juzgada?';
}

/// Authentication related text (Spanish)
class AuthTextsEs with _TextSelector {
  const AuthTextsEs();

  static const String createAccount = 'Crear Cuenta';
  static const String welcomeBack = 'Bienvenida';

  static const String signUp = 'Registrarse';
  static const String signIn = 'Iniciar Sesión';

  static const String usernameHint = 'Usuario';
  static const String passwordHint = 'Contraseña';
  static const String keepSignedIn = 'Mantener sesión iniciada';

  static const String fillAllFields = 'Por favor completa todos los campos';
  static const String genericError = 'Ocurrió un error. Intenta de nuevo.';
  static const String signInPrompt = 'Ingresa tu usuario y contraseña para iniciar sesión';

  static String usernameNotFoundError(String message) =>
      '$message\n\nConsejo: revisa tu ortografía o crea una cuenta si aún no lo has hecho.';
}

/// Dashboard related text (Spanish)
class DashboardTextsEs with _TextSelector {
  const DashboardTextsEs();

  static const String homebaseTitle = 'este es tu espacio';
  
  // Updated to be a function that takes connection count
  static String homebaseSubtitle(int connectionCount) {
    if (connectionCount == 0) {
      return 'Aún no hay conexiones';
    } else if (connectionCount == 1) {
      return 'Puntuación de conexión: 1 conexión fuerte';
    } else {
      return 'Puntuación de conexión: $connectionCount conexiones fuertes';
    }
  }

  static const String noConnections = 'Aún no hay conexiones.';
  static const String firstConnectionPrompt = '¡Empieza creando tu primera conexión!';
  static const String findNewConnection = 'buscar nueva conexión :)';

  static const String usernamePrefix = 'usuario: ';
  static const String defaultAvatarLetter = 'U';
}

/// Chat and messages related text (Spanish)
class ChatTextsEs with _TextSelector {
  const ChatTextsEs();

  static const String inputHint = 'di cómo te sientes...';
  static const String inputStarterText = 'Desde que me convertí en madre, siento que he desaparecido de mi propia historia. Todos preguntan por el bebé, pero nadie pregunta por mí. He estado ';
  static const String defaultStarterText = 'Comienza tu conversación...';

  // Chat starter (Spanish)
  static const String chatStarter = 'Desde que me convertí en madre, siento que he desaparecido de mi propia historia. Todos preguntan por el bebé, pero nadie pregunta por mí. He estado…';

  static const String conversationEnded = 'Conversación Terminada';
  static const String feedbackQuestion = '¿Te sentiste conectada con esta persona?';
  static const String savingFeedback = 'Guardando tu opinión...';
  static const String feedbackYes = 'sí';
  static const String feedbackNo = 'no';

  static const String thanksForFeedback = '¡Gracias por tu opinión!';
  static const String enjoyedConnecting = 'Esperamos que hayas disfrutado conectando con otra mamá';
  static const String continueButton = 'Continuar';

  static const String chatError = 'Error de Chat';
  static const String errorOccurred = 'Ocurrió un error';
  static const String retryButton = 'Reintentar';
}

/// Common UI text (Spanish)
class UITextsEs with _TextSelector {
  const UITextsEs();

  static const String goToDashboard = 'Ir a tu espacio';

  static const String chatInvitation = 'Invitación de Chat';
  static const String wantsToChat = 'quiere chatear contigo.';
  static const String startConversationPrompt = '¿Te gustaría iniciar una conversación?';
  static const String decline = 'Rechazar';
  static const String accept = 'Aceptar';
  static const String dismiss = 'Cerrar';

  static const String initializingApp = 'Inicializando la app...';
  static const String findingConnection = 'buscando a alguien\nque te entienda';
}

/// Homepage related text (Spanish)
class HomepageTextsEs with _TextSelector {
  const HomepageTextsEs();

  static const String mainDescription = "Creamos un espacio que te conecta con mamás que han estado en tu lugar.";
  static const String cardSubtitle = 'Te conectamos con mamás que sienten exactamente lo que tú sientes.';
} 