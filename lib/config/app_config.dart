/// Configuration values for the application
class AppConfig {
  /// Duration of chat conversations in seconds
  static const int chatDurationSeconds = 30; // 5 minutes

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
class ChallengeTexts with _TextSelector {
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
class ChatTexts with _TextSelector {
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
  static const String mainDescription = 'Welcome to MomsBond\nConnect with moms who understand your journey';
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
  static const String tryingLabel = '¿Buscando quedar embarazada?';
  static const String pregnantLabel = '¿embarazada?';
  static const String toddlerLabel = '¿mamá de niño pequeño?';
  static const String teenLabel = '¿mamá de adolescente?';
  static const String adultLabel = '¿mamá de hijo adulto?';

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
  static const String bodyChanges = '¿preocupada por los cambios en tu cuerpo?';
  static const String bodyChangesDb = '¿Preocupación por el peso y los cambios corporales?';

  static const String depressionAnxiety = '¿sientes depresión o ansiedad posparto?';
  static const String depressionAnxietyDb = '¿Depresión o ansiedad posparto?';

  static const String loneliness = '¿Te sientes sola porque tus amigas no entienden la maternidad?';
  static const String lonelinessDb = '¿Soledad porque tus amigas no entienden la maternidad?';

  // Set 2 Questions
  static const String lostIdentity = '¿te sientes perdida más allá de la maternidad?';
  static const String lostIdentityDb = '¿Sentirte perdida más allá de la maternidad?';

  static const String judgingParenting = '¿preocupada porque otros juzgan tu estilo de crianza?';
  static const String judgingParentingDb = '¿Preocupada porque otros juzgan tu estilo de crianza?';

  static const String fearSick = '¿miedo a enfermarte y no poder apoyar a tu familia?';
  static const String fearSickDb = '¿Miedo a enfermarte y no poder apoyar a tu familia?';

  // Set 3 Questions (Trying to conceive challenges)
  static const String fertilityStress = '¿Estrés por la fertilidad y el momento adecuado?';
  static const String fertilityStressDb = '¿Estrés por la fertilidad y el momento adecuado?';

  static const String socialPressure = '¿Presión de familiares y amigos para tener hijos?';
  static const String socialPressureDb = '¿Presión de familiares y amigos para tener hijos?';

  static const String financialWorries = '¿preocupaciones financieras para tener un bebé?';
  static const String financialWorriesDb = '¿Preocupaciones financieras para tener un bebé?';

  static const String relationshipChanges = '¿temor de cómo un bebé cambiará tu relación?';
  static const String relationshipChangesDb = '¿Temor de cómo un bebé cambiará tu relación?';
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
  static const String homebaseSubtitle = 'donde mantienes y creas nuevas conexiones.';

  static const String noConnections = 'Aún no hay conexiones.';
  static const String firstConnectionPrompt = '¡Empieza creando tu primera conexión!';
  static const String findNewConnection = 'buscar nueva conexión :)';

  static const String usernamePrefix = 'usuario: ';
  static const String instaHandle = 'insta: realconnection.com_';

  static const String defaultAvatarLetter = 'U';
}

/// Chat and messages related text (Spanish)
class ChatTextsEs with _TextSelector {
  const ChatTextsEs();

  static const String inputHint = 'di cómo te sientes...';
  static const String defaultStarterText = 'Comienza tu conversación...';

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

  static const String mainDescription = 'Estamos aquí para ayudarte a conectar con otras madres en tu etapa.';
  static const String getStarted = 'Comenzar';
} 