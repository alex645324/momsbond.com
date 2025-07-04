import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/messages_model.dart';
import '../viewmodels/messages_viewmodel.dart';
import 'dashboard_view.dart';

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
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
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
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      Provider.of<MessagesViewModel>(context, listen: false).sendMessage(text);
      _messageController.clear();
      _scrollToBottom();
    }
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
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return _buildLoadingState();
        }

        if (viewModel.hasError) {
          return _buildErrorState(viewModel);
        }

        return _buildChatInterface(viewModel);
      },
    );
  }

  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: const Color(0xFFEAE7E2),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorState(MessagesViewModel viewModel) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAE7E2),
      body: Center(
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
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF494949),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                viewModel.errorMessage ?? 'An error occurred',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF494949),
                ),
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

  Widget _buildChatInterface(MessagesViewModel viewModel) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAE7E2),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = constraints.maxHeight;
            final screenWidth = constraints.maxWidth;
            // Treat screens wider than 500 px as "large" and keep the design at its phone baseline width.
            const double baseWidth = 393.0;
            const double maxContentWidth = 500.0; // optional cap for tablets/desktops
            final bool isMobileWidth = screenWidth <= maxContentWidth;
            final double contentWidth = isMobileWidth ? screenWidth : baseWidth;
            final double scaleFactor = contentWidth / baseWidth; // Never larger than 1 on big screens
            final horizontalPadding = isMobileWidth ? 0.0 : (screenWidth - contentWidth) / 2;
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Container(
                width: contentWidth,
                height: screenHeight,
                child: Stack(
                  children: [
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
                                style: GoogleFonts.poppins(
                                  fontSize: 14 * scaleFactor,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF494949),
                                ),
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
                        child: _buildMessageInput(scaleFactor),
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
          style: GoogleFonts.poppins(
            fontSize: 16 * scaleFactor,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF878787),
          ),
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
                style: GoogleFonts.poppins(
                  fontSize: 11 * scaleFactor,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF494949),
                ),
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

  Widget _buildMessageInput(double scaleFactor) {
    return Container(
      constraints: BoxConstraints(
        minHeight: 44 * scaleFactor,
        maxHeight: 120 * scaleFactor,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE6E3E0),
        borderRadius: BorderRadius.circular(29 * scaleFactor),
        border: Border.all(
          color: const Color(0xFFD9D9D9),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              onSubmitted: (_) => _sendMessage(),
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              maxLines: null, // allow unlimited lines
              minLines: 1,
              style: GoogleFonts.poppins(
                fontSize: 11 * scaleFactor,
                color: const Color(0xFF494949),
              ),
              decoration: InputDecoration(
                hintText: 'say how you feel...',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 11 * scaleFactor,
                  color: const Color(0xFF878787),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20 * scaleFactor,
                  vertical: 14 * scaleFactor,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 32 * scaleFactor,
              height: 32 * scaleFactor,
              margin: EdgeInsets.only(right: 4 * scaleFactor, bottom: 4 * scaleFactor),
              decoration: BoxDecoration(
                color: const Color(0xFF494949),
                borderRadius: BorderRadius.circular(16 * scaleFactor),
              ),
              child: Icon(
                Icons.send,
                color: Colors.white,
                size: 14 * scaleFactor,
              ),
            ),
          ),
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
                style: GoogleFonts.poppins(
                  fontSize: 20 * scaleFactor,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF494949),
                ),
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
          style: GoogleFonts.poppins(
            fontSize: 11 * scaleFactor,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF494949),
          ),
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
                style: GoogleFonts.poppins(
                  fontSize: 10 * scaleFactor,
                  color: const Color(0xFF494949),
                ),
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
                          style: GoogleFonts.poppins(
                            fontSize: 11 * scaleFactor,
                            color: const Color(0xFF494949),
                            fontWeight: viewModel.messagesModel.selectedFeedback == 'yes' 
                                ? FontWeight.w600 
                                : FontWeight.w400,
                          ),
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
                          style: GoogleFonts.poppins(
                            fontSize: 11 * scaleFactor,
                            color: const Color(0xFF494949),
                            fontWeight: viewModel.messagesModel.selectedFeedback == 'no' 
                                ? FontWeight.w600 
                                : FontWeight.w400,
                          ),
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
          style: GoogleFonts.poppins(
            fontSize: 14 * scaleFactor,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF494949),
          ),
        ),
        SizedBox(height: 8 * scaleFactor),
        Text(
          'We hope you enjoyed connecting with another mom',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 11 * scaleFactor,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF494949),
          ),
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
                style: GoogleFonts.poppins(
                  fontSize: 12 * scaleFactor,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
} 