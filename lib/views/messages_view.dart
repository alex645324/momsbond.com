import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/messages_model.dart';
import '../viewmodels/messages_viewmodel.dart';
import '../Templates/chat_text_field.dart';
import 'dashboard_view.dart';
import 'package:flutter/animation.dart';
import '../config/app_config.dart';
import '../config/locale_helper.dart';

// Holds width / scale data calculated from screen width
class _LayoutSizes {
  final double contentWidth;
  final double scaleFactor;
  final bool isMobileWidth;
  const _LayoutSizes(this.contentWidth, this.scaleFactor, this.isMobileWidth);
}

class MessagesView extends StatefulWidget {
  final ConversationInitData initData;

  const MessagesView({
    Key? key,
    required this.initData,
  }) : super(key: key);

  @override
  _MessagesViewState createState() => _MessagesViewState();
}

class _MessagesViewState extends State<MessagesView> {
  final ScrollController _scrollController = ScrollController();
  late final Widget _chatTextField;
  bool _isNearBottom = true;
  int _previousMessageCount = 0;

  // -------------------------------------------------------------------
  // Small private helpers to remove repetition (public API unchanged)
  // -------------------------------------------------------------------

  static const double _kBaseWidth = 393.0;
  static const double _kMaxContentWidth = 500.0;

  _LayoutSizes _calcSizes(double screenWidth) {
    final isMobileWidth = screenWidth <= _kMaxContentWidth;
    final contentWidth = isMobileWidth ? screenWidth : _kBaseWidth;
    final scaleFactor = contentWidth / _kBaseWidth;
    return _LayoutSizes(contentWidth, scaleFactor, isMobileWidth);
  }

  // Common scaffold wrapper with the app background colour
  Widget _baseScaffold(Widget body) =>
      Scaffold(backgroundColor: const Color(0xFFEAE7E2), body: body);

  // Quick helper for scaled GoogleFonts.poppins
  TextStyle _txt(double size, double scale, FontWeight w, Color c) =>
      GoogleFonts.poppins(fontSize: size * scale, fontWeight: w, color: c);

  @override
  void initState() {
    super.initState();
    
    // Add scroll listener to track user scroll behavior
    _scrollController.addListener(_onScroll);
    
    // Create ChatTextField once and reuse it
    _chatTextField = LayoutBuilder(
      builder: (context, constraints) {
        final sizes = _calcSizes(constraints.maxWidth);
        final viewModel = Provider.of<MessagesViewModel>(context, listen: false);
        return ChatTextField(
          onSendMessage: _onSendMessage,
          scaleFactor: sizes.scaleFactor,
          hasMessages: viewModel.messages.isNotEmpty,
          onUserStartedTyping: viewModel.onUserStartedTyping,
          onUserStoppedTyping: viewModel.onUserStoppedTyping,
        );
      },
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<MessagesViewModel>(context, listen: false);
      viewModel.setNavigationCallback(_navigateToDashboard);
      viewModel.initializeConversation(widget.initData);
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    
    // Consider "near bottom" if within 100 pixels of bottom
    final wasNearBottom = _isNearBottom;
    _isNearBottom = (maxScroll - currentScroll) < 100;
    
    // Track if user is actively scrolling (not auto-scroll)
    if (wasNearBottom != _isNearBottom) {
      setState(() {});
    }
  }

  void _navigateToDashboard() {
    if (mounted) {
      // Reset the MessagesViewModel state before navigating
      final viewModel = Provider.of<MessagesViewModel>(context, listen: false);
      viewModel.resetForNewConversation();
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardView()),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onSendMessage(String text) {
    Provider.of<MessagesViewModel>(context, listen: false).sendMessage(text);
    // Always scroll to bottom when user sends a message
    _isNearBottom = true; // Force scroll for sent messages
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    
    // Only auto-scroll if user is near bottom (like iMessage)
    if (_isNearBottom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MessagesViewModel>(
      child: _chatTextField,
      builder: (context, viewModel, chatTextField) {
        // Check for new messages and auto-scroll if user is near bottom
        if (viewModel.messages.length > _previousMessageCount && _isNearBottom) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
        
        // Initial scroll to bottom when conversation first loads
        if (_previousMessageCount == 0 && viewModel.messages.isNotEmpty) {
          _isNearBottom = true; // Ensure we scroll for initial load
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
        
        _previousMessageCount = viewModel.messages.length;

        if (viewModel.isLoading) {
          return _buildLoadingState();
        }

        if (viewModel.hasError) {
          return _buildErrorState(viewModel);
        }

        // Build ChatTextField with current message state
        final currentChatTextField = LayoutBuilder(
          builder: (context, constraints) {
            final sizes = _calcSizes(constraints.maxWidth);
            return ChatTextField(
              onSendMessage: _onSendMessage,
              scaleFactor: sizes.scaleFactor,
              hasMessages: viewModel.messages.isNotEmpty,
              onUserStartedTyping: viewModel.onUserStartedTyping,
              onUserStoppedTyping: viewModel.onUserStoppedTyping,
            );
          },
        );
        
        return _buildChatInterface(viewModel, currentChatTextField);
      },
    );
  }

  Widget _buildLoadingState() =>
      _baseScaffold(const Center(child: CircularProgressIndicator()));

  Widget _buildErrorState(MessagesViewModel viewModel) {
    return _baseScaffold(
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              L.chat(context).chatError,
              style: _txt(20, 1, FontWeight.w600, const Color(0xFF494949)),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                viewModel.errorMessage ?? L.chat(context).errorOccurred,
                textAlign: TextAlign.center,
                style: _txt(14, 1, FontWeight.normal, const Color(0xFF494949)),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => viewModel.clearError(),
              child: Text(L.chat(context).retryButton),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatInterface(MessagesViewModel viewModel, Widget chatTextField) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAE7E2),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = constraints.maxHeight;
            final screenWidth = constraints.maxWidth;

            // Sizing helper reused
            final sizes = _calcSizes(screenWidth);
            final bool isDesktop = screenWidth > 1024;
            final bool isTablet = screenWidth > 768 && screenWidth <= 1024;
            final double scaleFactor = sizes.scaleFactor;
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            
            return Container(
              width: screenWidth, // Use full screen width
              height: screenHeight,
              child: Stack(
                children: [
                  // Exit (X) button – identical design to LoadingView
                  Positioned(
                    top: 10 * scaleFactor,
                    right: 10 * scaleFactor,
                    child: Opacity(
                      opacity: 0.6,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: isDesktop
                            ? 28
                            : (isTablet ? 24 : 20 * scaleFactor),
                        icon: const Icon(Icons.close),
                        color: const Color(0xFF494949),
                        tooltip: L.ui(context).goToDashboard,
                        onPressed: () {
                          final viewModel = Provider.of<MessagesViewModel>(context, listen: false);
                          viewModel.endConversationEarly();
                        },
                      ),
                    ),
                  ),
                  // Chat messages area
                  Positioned(
                    left: 16,
                    right: 16,
                    top: 80 * scaleFactor,
                    bottom: 80 * scaleFactor + bottomInset,
                    child: _buildMessagesArea(viewModel, scaleFactor),
                  ),

                  // Timer display (top center)
                  if (viewModel.isConversationActive)
                    Positioned(
                      top: 40 * scaleFactor,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: AnimatedOpacity(
                          opacity: viewModel.messagesModel.remainingSeconds <= 10 ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16 * scaleFactor,
                              vertical: 8 * scaleFactor,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6E3E0),
                              borderRadius: BorderRadius.circular(20 * scaleFactor),
                            ),
                            child: Text(
                              viewModel.timerDisplay,
                              style: _txt(14, scaleFactor, FontWeight.w500,
                                  const Color(0xFF494949)),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Typing indicator just above input field
                  if (viewModel.isConversationActive && viewModel.isOtherUserTyping)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 80 * scaleFactor + bottomInset,
                      child: _buildTypingIndicator(scaleFactor),
                    ),

                  // Input field at bottom
                  if (viewModel.isConversationActive)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 20 * scaleFactor + bottomInset,
                      child: chatTextField,
                    ),



                  // End overlay
                  if (viewModel.showEndOverlay)
                    _buildEndOverlay(viewModel, scaleFactor),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMessagesArea(MessagesViewModel viewModel, double scaleFactor) {
    if (viewModel.messages.isEmpty) {
      return Center(
        child: Text(
          _localizedStarterText(context, viewModel.messagesModel.starterText),
          textAlign: TextAlign.center,
          style: _txt(16, scaleFactor, FontWeight.w400, const Color(0xFF878787)),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      // Natural order - no reverse, messages flow chronologically from top to bottom
      itemCount: viewModel.messages.length,
      padding: EdgeInsets.only(
        top: 8 * scaleFactor,
        bottom: 8 * scaleFactor,
      ),
      itemBuilder: (context, index) {
        // Natural indexing - messages are already in chronological order
        final message = viewModel.messages[index];
        return _buildMessageBubble(message, scaleFactor);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message, double scaleFactor) {
    final isCurrentUser = message.isCurrentUser;
    const currentUserColor = Color(0xFFD9D9D9); // Light gray for current user
    const partnerColor = Color(0xFFB0B0B0);     // Darker gray for partner
    
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4 * scaleFactor),
      child: Row(
        mainAxisAlignment: isCurrentUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        children: [
          if (!isCurrentUser) SizedBox(width: 0),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: 20 * scaleFactor,
                vertical: 16 * scaleFactor,
              ),
              decoration: BoxDecoration(
                color: isCurrentUser ? currentUserColor : partnerColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16 * scaleFactor),
                  topRight: Radius.circular(16 * scaleFactor),
                  bottomLeft: Radius.circular(isCurrentUser ? 16 * scaleFactor : 4 * scaleFactor),
                  bottomRight: Radius.circular(isCurrentUser ? 4 * scaleFactor : 16 * scaleFactor),
                ),
                border: Border.all(
                  color: const Color(0xFFEAE7E2), // Match screen background
                  width: 1,
                ),
              ),
              child: Text(
                message.text,
                style: _txt(14, scaleFactor, FontWeight.w400, const Color(0xFF494949)),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
            ),
          ),
          if (isCurrentUser) SizedBox(width: 0),
        ],
      ),
    );
  }



  // -------------------------------------------------------------

  Widget _buildEndOverlay(MessagesViewModel viewModel, double scaleFactor) {
    return Positioned.fill(
      child: _FadeInWrapper(
        child: Container(
          color: const Color(0xFFC8C5C5).withOpacity(0.9),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  L.chat(context).conversationEnded,
                  textAlign: TextAlign.center,
                  style: _txt(26, scaleFactor, FontWeight.w600, const Color(0xFF494949)),
                ),
                SizedBox(height: 24 * scaleFactor),
                
                // Show different content based on conversation end step
                if (viewModel.messagesModel.showAcknowledgment)
                  _buildAcknowledmentContent(viewModel, scaleFactor)
                else if (viewModel.messagesModel.showFeedbackPrompt || viewModel.messagesModel.showFeedbackButtons)
                  _buildFeedbackContent(viewModel, scaleFactor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackContent(MessagesViewModel viewModel, double scaleFactor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          L.chat(context).feedbackQuestion,
          style: _txt(14, scaleFactor, FontWeight.w400, const Color(0xFF494949)),
        ),
        SizedBox(height: 32 * scaleFactor),
        
        // Binary choice button or loading indicator
        if (viewModel.messagesModel.isSubmittingFeedback)
          Column(
            children: [
              const CircularProgressIndicator(),
              SizedBox(height: 12 * scaleFactor),
              Text(
                L.chat(context).savingFeedback,
                style: _txt(12, scaleFactor, FontWeight.normal, const Color(0xFF494949)),
              ),
            ],
          )
        else
          Container(
            width: 240 * scaleFactor,
            height: 56 * scaleFactor,
            decoration: BoxDecoration(
              color: const Color(0xFFD9D9D9),
              borderRadius: BorderRadius.circular(28 * scaleFactor),
            ),
            child: Row(
              children: [
                // Yes option
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      viewModel.selectFeedback(FeedbackChoice.yes);
                      // Small delay for visual feedback then submit
                      Future.delayed(const Duration(milliseconds: 300), () {
                        viewModel.submitFeedback();
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: viewModel.messagesModel.selectedFeedback == 'yes' 
                            ? const Color(0xFF494949).withValues(alpha: 0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(28 * scaleFactor),
                          bottomLeft: Radius.circular(28 * scaleFactor),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          L.chat(context).feedbackYes,
                          style: _txt(14, scaleFactor, FontWeight.w600, const Color(0xFF494949)),
                        ),
                      ),
                    ),
                  ),
                ),
                // Vertical divider
                Container(
                  width: 1,
                  height: 32 * scaleFactor,
                  color: const Color(0xFF494949),
                ),
                // No option
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      viewModel.selectFeedback(FeedbackChoice.no);
                      // Small delay for visual feedback then submit
                      Future.delayed(const Duration(milliseconds: 300), () {
                        viewModel.submitFeedback();
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: viewModel.messagesModel.selectedFeedback == 'no' 
                            ? const Color(0xFF494949).withValues(alpha: 0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(28 * scaleFactor),
                          bottomRight: Radius.circular(28 * scaleFactor),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          L.chat(context).feedbackNo,
                          style: _txt(14, scaleFactor, FontWeight.w600, const Color(0xFF494949)),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAcknowledmentContent(MessagesViewModel viewModel, double scaleFactor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.check_circle_outline,
          size: 40 * scaleFactor,
          color: const Color(0xFF494949),
        ),
        SizedBox(height: 16 * scaleFactor),
        Text(
          L.chat(context).thanksForFeedback,
          style: _txt(14, scaleFactor, FontWeight.w500, const Color(0xFF494949)),
        ),
        SizedBox(height: 8 * scaleFactor),
        Text(
          L.chat(context).enjoyedConnecting,
          textAlign: TextAlign.center,
          style: _txt(11, scaleFactor, FontWeight.w400, const Color(0xFF494949)),
        ),
        SizedBox(height: 24 * scaleFactor),
        
        // Continue button - user must click to proceed
        GestureDetector(
          onTap: () {
            viewModel.acknowledgeAndNavigate();
          },
          child: Container(
            width: 140 * scaleFactor,
            height: 40 * scaleFactor,
            decoration: BoxDecoration(
              color: const Color(0xFF494949),
              borderRadius: BorderRadius.circular(20 * scaleFactor),
            ),
            child: Center(
              child: Text(
                L.chat(context).continueButton,
                style: _txt(12, scaleFactor, FontWeight.w500, Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypingIndicator(double scaleFactor) {
    return Container(
      margin: EdgeInsets.only(bottom: 8 * scaleFactor),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 16 * scaleFactor,
              vertical: 12 * scaleFactor,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFB0B0B0), // Partner message color
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16 * scaleFactor),
                topRight: Radius.circular(16 * scaleFactor),
                bottomLeft: Radius.circular(4 * scaleFactor),
                bottomRight: Radius.circular(16 * scaleFactor),
              ),
              border: Border.all(
                color: const Color(0xFFEAE7E2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(scaleFactor, 0),
                SizedBox(width: 4 * scaleFactor),
                _buildTypingDot(scaleFactor, 200),
                SizedBox(width: 4 * scaleFactor),
                _buildTypingDot(scaleFactor, 400),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(double scaleFactor, int delay) {
    return _TypingDot(scaleFactor: scaleFactor, delay: delay);
  }

  String _localizedStarterText(BuildContext context, String? original) {
    if (original != null && original.startsWith('your connection also struggles with')) {
      // Extract topic
      final idx = original.indexOf('\n"');
      if (idx != -1) {
        final topic = original.substring(idx + 2).replaceAll('"', '');
        final localizedTopic = _translateTopic(context, topic);
        return L.chat(context).connectionAlsoStrugglesWith(localizedTopic);
      }
    }
    if (original != null && original.isNotEmpty) return original;
    return L.chat(context).defaultStarterText;
  }

  String _translateTopic(BuildContext context, String topic) {
    final lc = L.challenges(context);
    // Map database values to localized display strings
    switch (topic) {
      case ChallengeTexts.bodyChangesDb:
      case ChallengeTexts.bodyChanges:
        return lc.bodyChanges;
      case ChallengeTexts.depressionAnxietyDb:
      case ChallengeTexts.depressionAnxiety:
        return lc.depressionAnxiety;
      case ChallengeTexts.lonelinessDb:
      case ChallengeTexts.loneliness:
        return lc.loneliness;
      case ChallengeTexts.lostIdentityDb:
      case ChallengeTexts.lostIdentity:
        return lc.lostIdentity;
      case ChallengeTexts.judgingParentingDb:
      case ChallengeTexts.judgingParenting:
        return lc.judgingParenting;
      case ChallengeTexts.fearSickDb:
      case ChallengeTexts.fearSick:
        return lc.fearSick;
      case ChallengeTexts.fertilityStressDb:
      case ChallengeTexts.fertilityStress:
        return lc.fertilityStress;
      case ChallengeTexts.socialPressureDb:
      case ChallengeTexts.socialPressure:
        return lc.socialPressure;
      case ChallengeTexts.financialWorriesDb:
      case ChallengeTexts.financialWorries:
        return lc.financialWorries;
      case ChallengeTexts.relationshipChangesDb:
      case ChallengeTexts.relationshipChanges:
        return lc.relationshipChanges;
      default:
        return topic; // fallback if unknown
    }
  }
}

// Small helper widget to fade-in its child once when inserted
class _FadeInWrapper extends StatefulWidget {
  final Widget child;
  final Duration duration;
  const _FadeInWrapper({Key? key, required this.child, this.duration = const Duration(milliseconds: 400)}) : super(key: key);

  @override
  _FadeInWrapperState createState() => _FadeInWrapperState();
}

class _FadeInWrapperState extends State<_FadeInWrapper> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _controller, child: widget.child);
  }
}

// Animated typing dot widget
class _TypingDot extends StatefulWidget {
  final double scaleFactor;
  final int delay;

  const _TypingDot({required this.scaleFactor, required this.delay});

  @override
  _TypingDotState createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Start animation with delay
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 6 * widget.scaleFactor,
          height: 6 * widget.scaleFactor,
          decoration: BoxDecoration(
            color: const Color(0xFF494949).withValues(alpha: _animation.value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

 