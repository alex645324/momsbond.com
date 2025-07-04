import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/messages_model.dart';
import '../viewmodels/messages_viewmodel.dart';
import '../Templates/chat_text_field.dart';
import 'dashboard_view.dart';

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
    
    // Create ChatTextField once and reuse it
    _chatTextField = LayoutBuilder(
      builder: (context, constraints) {
        final sizes = _calcSizes(constraints.maxWidth);
        return ChatTextField(
          onSendMessage: _onSendMessage,
          scaleFactor: sizes.scaleFactor,
        );
      },
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<MessagesViewModel>(context, listen: false);
      viewModel.setNavigationCallback(_navigateToDashboard);
      viewModel.initializeConversation(widget.initData);
    });
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
    _scrollController.dispose();
    super.dispose();
  }

  void _onSendMessage(String text) {
    Provider.of<MessagesViewModel>(context, listen: false).sendMessage(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MessagesViewModel>(
      child: _chatTextField,
      builder: (context, viewModel, chatTextField) {
        if (viewModel.isLoading) {
          return _buildLoadingState();
        }

        if (viewModel.hasError) {
          return _buildErrorState(viewModel);
        }

        return _buildChatInterface(viewModel, chatTextField ?? _chatTextField);
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
              'Chat Error',
              style: _txt(20, 1, FontWeight.w600, const Color(0xFF494949)),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                viewModel.errorMessage ?? 'An error occurred',
                textAlign: TextAlign.center,
                style: _txt(14, 1, FontWeight.normal, const Color(0xFF494949)),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => viewModel.clearError(),
              child: const Text('Retry'),
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
            final double contentWidth = sizes.contentWidth;
            final double scaleFactor = sizes.scaleFactor;
            final double horizontalPadding =
                sizes.isMobileWidth ? 0.0 : (screenWidth - contentWidth) / 2;
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Container(
                width: contentWidth,
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
                          tooltip: 'Go to dashboard',
                          onPressed: () {
                            final viewModel = Provider.of<MessagesViewModel>(context, listen: false);
                            viewModel.endConversationEarly();
                          },
                        ),
                      ),
                    ),
                    // Chat messages area
                    Positioned(
                      left: 20,
                      right: 20,
                      top: 120 * scaleFactor,
                      bottom: 140 * scaleFactor + bottomInset,
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

                    // Input field at bottom
                    if (viewModel.isConversationActive)
                      Positioned(
                        left: 20 * scaleFactor,
                        right: 20 * scaleFactor,
                        bottom: 20 * scaleFactor + bottomInset,
                        child: chatTextField,
                      ),

                    // End overlay
                    if (viewModel.showEndOverlay)
                      _buildEndOverlay(viewModel, scaleFactor),
                  ],
                ),
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
          viewModel.messagesModel.starterText ?? 'Start your conversation...',
          textAlign: TextAlign.center,
          style: _txt(16, scaleFactor, FontWeight.w400, const Color(0xFF878787)),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true, // Show newest messages at bottom
      itemCount: viewModel.messages.length,
      itemBuilder: (context, index) {
        final message = viewModel.messages[index];
        return _buildMessageBubble(message, scaleFactor);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message, double scaleFactor) {
    final isCurrentUser = message.isCurrentUser;
    
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4 * scaleFactor),
      child: Row(
        mainAxisAlignment: isCurrentUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        children: [
          if (!isCurrentUser) SizedBox(width: 45 * scaleFactor),
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 16 * scaleFactor,
                vertical: 12 * scaleFactor,
              ),
              decoration: BoxDecoration(
                color: isCurrentUser 
                    ? const Color(0xFFDFE0E2)
                    : const Color(0xFFD9D9D9),
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
                style: _txt(11, scaleFactor, FontWeight.w400, const Color(0xFF494949)),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
            ),
          ),
          if (isCurrentUser) SizedBox(width: 45 * scaleFactor),
        ],
      ),
    );
  }

  Widget _buildEndOverlay(MessagesViewModel viewModel, double scaleFactor) {
    return Positioned.fill(
      child: Container(
        color: const Color(0xFFC8C5C5).withValues(alpha: 0.9),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Conversations Ended',
                style: _txt(20, scaleFactor, FontWeight.w600, const Color(0xFF494949)),
              ),
              SizedBox(height: 16 * scaleFactor),
              
              // Show different content based on conversation end step
              if (viewModel.messagesModel.showAcknowledgment)
                _buildAcknowledmentContent(viewModel, scaleFactor)
              else if (viewModel.messagesModel.showFeedbackPrompt || viewModel.messagesModel.showFeedbackButtons)
                _buildFeedbackContent(viewModel, scaleFactor),
            ],
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
          'did you feel connected to this person?',
          style: _txt(11, scaleFactor, FontWeight.w400, const Color(0xFF494949)),
        ),
        SizedBox(height: 24 * scaleFactor),
        
        // Binary choice button or loading indicator
        if (viewModel.messagesModel.isSubmittingFeedback)
          Column(
            children: [
              const CircularProgressIndicator(),
              SizedBox(height: 8 * scaleFactor),
              Text(
                'Saving your feedback...',
                style: _txt(10, scaleFactor, FontWeight.normal, const Color(0xFF494949)),
              ),
            ],
          )
        else
          Container(
            width: 200 * scaleFactor,
            height: 44 * scaleFactor,
            decoration: BoxDecoration(
              color: const Color(0xFFD9D9D9),
              borderRadius: BorderRadius.circular(22 * scaleFactor),
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
                          topLeft: Radius.circular(22 * scaleFactor),
                          bottomLeft: Radius.circular(22 * scaleFactor),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'yes',
                          style: _txt(11, scaleFactor, FontWeight.w600, const Color(0xFF494949)),
                        ),
                      ),
                    ),
                  ),
                ),
                // Vertical divider
                Container(
                  width: 1,
                  height: 24 * scaleFactor,
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
                          topRight: Radius.circular(22 * scaleFactor),
                          bottomRight: Radius.circular(22 * scaleFactor),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'no',
                          style: _txt(11, scaleFactor, FontWeight.w600, const Color(0xFF494949)),
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
          'Thanks for your feedback!',
          style: _txt(14, scaleFactor, FontWeight.w500, const Color(0xFF494949)),
        ),
        SizedBox(height: 8 * scaleFactor),
        Text(
          'We hope you enjoyed connecting with another mom',
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
                'Continue',
                style: _txt(12, scaleFactor, FontWeight.w500, Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
} 