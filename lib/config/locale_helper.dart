import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/language_viewmodel.dart';
import 'app_config.dart';

class L {
  static bool isEs(BuildContext context) => context.watch<LanguageViewModel>().currentLanguage == 'es';

  // Proxies provide instance getters so callers can use dot syntax safely
  static _HomepageProxy homepage(BuildContext context) => _HomepageProxy(isEs(context));
  static _AuthProxy auth(BuildContext context) => _AuthProxy(isEs(context));
  static _UIProxy ui(BuildContext context) => _UIProxy(isEs(context));
  static _MomStagesProxy momStages(BuildContext context) => _MomStagesProxy(isEs(context));
  static _ChallengesProxy challenges(BuildContext context) => _ChallengesProxy(isEs(context));
  static _ChatProxy chat(BuildContext context) => _ChatProxy(isEs(context));
  static _DashboardProxy dashboard(BuildContext context) => _DashboardProxy(isEs(context));
}

// ==================== Base Proxy Mixin =========================
mixin _BaseProxy {
  bool get es;
  
  String _pick(String en, String esStr) => es ? esStr : en;
  
  String _pickStatic(String Function() en, String Function() es) => this.es ? es() : en();
}

// ==================== Proxy Classes =========================

class _HomepageProxy with _BaseProxy {
  @override
  final bool es;
  const _HomepageProxy(this.es);

  String get mainDescription => _pickStatic(() => HomepageTexts.mainDescription, () => HomepageTextsEs.mainDescription);

  String get cardSubtitle => _pickStatic(() => HomepageTexts.cardSubtitle, () => HomepageTextsEs.cardSubtitle);
}

class _AuthProxy with _BaseProxy {
  @override
  final bool es;
  const _AuthProxy(this.es);

  // Simple string getters
  String get fillAllFields => _pickStatic(() => AuthTexts.fillAllFields, () => AuthTextsEs.fillAllFields);
  String get genericError => _pickStatic(() => AuthTexts.genericError, () => AuthTextsEs.genericError);
  String get signInPrompt => _pickStatic(() => AuthTexts.signInPrompt, () => AuthTextsEs.signInPrompt);
  String get createAccount => _pickStatic(() => AuthTexts.createAccount, () => AuthTextsEs.createAccount);
  String get welcomeBack => _pickStatic(() => AuthTexts.welcomeBack, () => AuthTextsEs.welcomeBack);
  String get signUp => _pickStatic(() => AuthTexts.signUp, () => AuthTextsEs.signUp);
  String get signIn => _pickStatic(() => AuthTexts.signIn, () => AuthTextsEs.signIn);
  String get usernameHint => _pickStatic(() => AuthTexts.usernameHint, () => AuthTextsEs.usernameHint);
  String get passwordHint => _pickStatic(() => AuthTexts.passwordHint, () => AuthTextsEs.passwordHint);
  String get keepSignedIn => _pickStatic(() => AuthTexts.keepSignedIn, () => AuthTextsEs.keepSignedIn);

  // Method wrapper
  String usernameNotFoundError(String message) => _pickStatic(
    () => AuthTexts.usernameNotFoundError(message),
    () => AuthTextsEs.usernameNotFoundError(message)
  );
}

class _UIProxy with _BaseProxy {
  @override
  final bool es;
  const _UIProxy(this.es);

  String get initializingApp => _pickStatic(() => UITexts.initializingApp, () => UITextsEs.initializingApp);
  String get findingConnection => _pickStatic(() => UITexts.findingConnection, () => UITextsEs.findingConnection);
  String get goToDashboard => _pickStatic(() => UITexts.goToDashboard, () => UITextsEs.goToDashboard);
  
  String get chatInvitation => _pickStatic(() => UITexts.chatInvitation, () => UITextsEs.chatInvitation);
  String get wantsToChat => _pickStatic(() => UITexts.wantsToChat, () => UITextsEs.wantsToChat);
  String get startConversationPrompt => _pickStatic(() => UITexts.startConversationPrompt, () => UITextsEs.startConversationPrompt);
  String get decline => _pickStatic(() => UITexts.decline, () => UITextsEs.decline);
  String get accept => _pickStatic(() => UITexts.accept, () => UITextsEs.accept);
}

class _MomStagesProxy with _BaseProxy {
  @override
  final bool es;
  const _MomStagesProxy(this.es);

  // identifiers remain same
  String get trying => MomStageTexts.trying;
  String get pregnant => MomStageTexts.pregnant;
  String get toddler => MomStageTexts.toddler;
  String get teen => MomStageTexts.teen;
  String get adult => MomStageTexts.adult;

  String get tryingLabel => _pickStatic(() => MomStageTexts.tryingLabel, () => MomStageTextsEs.tryingLabel);
  String get pregnantLabel => _pickStatic(() => MomStageTexts.pregnantLabel, () => MomStageTextsEs.pregnantLabel);
  String get toddlerLabel => _pickStatic(() => MomStageTexts.toddlerLabel, () => MomStageTextsEs.toddlerLabel);
  String get teenLabel => _pickStatic(() => MomStageTexts.teenLabel, () => MomStageTextsEs.teenLabel);
  String get adultLabel => _pickStatic(() => MomStageTexts.adultLabel, () => MomStageTextsEs.adultLabel);

  String get selectionTitle => _pickStatic(() => MomStageTexts.selectionTitle, () => MomStageTextsEs.selectionTitle);
  String get selectionSubtitle => _pickStatic(() => MomStageTexts.selectionSubtitle, () => MomStageTextsEs.selectionSubtitle);
}

class _ChallengesProxy with _BaseProxy {
  @override
  final bool es;
  const _ChallengesProxy(this.es);

  // Titles
  String get tryingTitle => _pickStatic(() => ChallengeTexts.tryingTitle, () => ChallengeTextsEs.tryingTitle);
  String get generalTitle => _pickStatic(() => ChallengeTexts.generalTitle, () => ChallengeTextsEs.generalTitle);

  String get bodyChanges => _pickStatic(() => ChallengeTexts.bodyChanges, () => ChallengeTextsEs.bodyChanges);
  String get depressionAnxiety => _pickStatic(() => ChallengeTexts.depressionAnxiety, () => ChallengeTextsEs.depressionAnxiety);
  String get loneliness => _pickStatic(() => ChallengeTexts.loneliness, () => ChallengeTextsEs.loneliness);
  String get lostIdentity => _pickStatic(() => ChallengeTexts.lostIdentity, () => ChallengeTextsEs.lostIdentity);
  String get judgingParenting => _pickStatic(() => ChallengeTexts.judgingParenting, () => ChallengeTextsEs.judgingParenting);
  String get fearSick => _pickStatic(() => ChallengeTexts.fearSick, () => ChallengeTextsEs.fearSick);
  String get fertilityStress => _pickStatic(() => ChallengeTexts.fertilityStress, () => ChallengeTextsEs.fertilityStress);
  String get socialPressure => _pickStatic(() => ChallengeTexts.socialPressure, () => ChallengeTextsEs.socialPressure);
  String get financialWorries => _pickStatic(() => ChallengeTexts.financialWorries, () => ChallengeTextsEs.financialWorries);
  String get relationshipChanges => _pickStatic(() => ChallengeTexts.relationshipChanges, () => ChallengeTextsEs.relationshipChanges);
}

class _ChatProxy {
  final bool es;
  const _ChatProxy(this.es);

  String _pick(String en, String esStr) => es ? esStr : en;

  // Input field and starter text
  String get inputHint => _pick(ChatTexts.inputHint, ChatTextsEs.inputHint);
  String get defaultStarterText => _pick(ChatTexts.defaultStarterText, ChatTextsEs.defaultStarterText);

  // Conversation states
  String get conversationEnded => _pick(ChatTexts.conversationEnded, ChatTextsEs.conversationEnded);
  String get feedbackQuestion => _pick(ChatTexts.feedbackQuestion, ChatTextsEs.feedbackQuestion);
  String get savingFeedback => _pick(ChatTexts.savingFeedback, ChatTextsEs.savingFeedback);
  String get feedbackYes => _pick(ChatTexts.feedbackYes, ChatTextsEs.feedbackYes);
  String get feedbackNo => _pick(ChatTexts.feedbackNo, ChatTextsEs.feedbackNo);
  String get thanksForFeedback => _pick(ChatTexts.thanksForFeedback, ChatTextsEs.thanksForFeedback);
  String get enjoyedConnecting => _pick(ChatTexts.enjoyedConnecting, ChatTextsEs.enjoyedConnecting);
  String get continueButton => _pick(ChatTexts.continueButton, ChatTextsEs.continueButton);

  // Errors
  String get chatError => _pick(ChatTexts.chatError, ChatTextsEs.chatError);
  String get errorOccurred => _pick(ChatTexts.errorOccurred, ChatTextsEs.errorOccurred);
  String get retryButton => _pick(ChatTexts.retryButton, ChatTextsEs.retryButton);

  // Dynamic starter text with topic placeholder
  String connectionAlsoStrugglesWith(String topic) => es
      ? 'tu conexión también enfrenta \n"$topic"'
      : 'your connection also struggles with \n"$topic"';
}

class _DashboardProxy {
  final bool es;
  const _DashboardProxy(this.es);

  String get homebaseTitle => es ? DashboardTextsEs.homebaseTitle : DashboardTexts.homebaseTitle;
  
  // Updated to be a function that takes connection count
  String homebaseSubtitle(int connectionCount) => es 
      ? DashboardTextsEs.homebaseSubtitle(connectionCount) 
      : DashboardTexts.homebaseSubtitle(connectionCount);
  
  String get usernamePrefix => es ? DashboardTextsEs.usernamePrefix : DashboardTexts.usernamePrefix;
  String get noConnections => es ? DashboardTextsEs.noConnections : DashboardTexts.noConnections;
  String get firstConnectionPrompt => es ? DashboardTextsEs.firstConnectionPrompt : DashboardTexts.firstConnectionPrompt;
  String get findNewConnection => es ? DashboardTextsEs.findNewConnection : DashboardTexts.findNewConnection;

  String get tapToTalkAgain => es ? 'toca para hablar de nuevo' : 'tap to talk again';
} 