import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../models/dashboard_model.dart';
import '../models/messages_model.dart';
import '../views/messages_view.dart';
import '../views/loading_view.dart';
import 'dart:math' as math;
import '../config/app_config.dart';
import '../config/locale_helper.dart';

// TODO: FUTURE FEATURE - Create ProfileEditView for returning users
// This new view would allow users to:
// - Update their mother stage selections
// - Modify their challenge question preferences  
// - View and edit other profile settings
// - Save changes and return to dashboard
// The view would reuse StageSelectionView and ChallengesView components in "edit mode"

class DashboardView extends StatefulWidget {
  const DashboardView({Key? key}) : super(key: key);

  @override
  _DashboardViewState createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  ConnectionData? _selectedConnection;
  bool _showConnectionPopup = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize the dashboard after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<DashboardViewModel>(context, listen: false);
      viewModel.initialize();
      
      // Set up callbacks for notifications and invitations
      viewModel.setNotificationCallback(_showNotification);
      viewModel.setInvitationCallback(_showInvitationDialog);
      viewModel.setNavigationCallback(_navigateToMessagesView);
    });
  }

  void _showNotification(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
                          label: UITexts.dismiss,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  void _showInvitationDialog(InvitationData invitation) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => InvitationDialog(
          invitation: invitation,
          onAccept: () {
            Navigator.of(context).pop();
            Provider.of<DashboardViewModel>(context, listen: false)
                .acceptInvitation(invitation);
          },
          onDecline: () {
            Navigator.of(context).pop();
            Provider.of<DashboardViewModel>(context, listen: false)
                .declineInvitation(invitation.id);
          },
        ),
      );
    }
  }

  void _navigateToMessagesView(ConversationInitData initData) {
    if (mounted) {
      print("DashboardView: Navigating to MessagesView with conversation ID: ${initData.conversationId}");
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MessagesView(initData: initData),
        ),
      );
    }
  }

  Offset? _connectionTapPosition; 

  void _showConnectionDetailsPopup(ConnectionData connection, Offset tapPosition) {
    setState(() {
      _selectedConnection = connection; 
      _connectionTapPosition = tapPosition; 
      _showConnectionPopup = true; 
    });
  }

  void _hideConnectionPopup() {
    setState(() {
      _showConnectionPopup = false;
      _selectedConnection = null;
      _connectionTapPosition = null;
    });
  }

  void _handleSmallButtonTap() {
    if (_selectedConnection != null) {
      // Send invitation when small button is tapped
      Provider.of<DashboardViewModel>(context, listen: false)
          .sendInvitation(_selectedConnection!);
      _hideConnectionPopup();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAE7E2),
      body: SafeArea(
        child: Consumer<DashboardViewModel>(
          builder: (context, viewModel, child) {
            // Handle errors
            if (viewModel.hasError) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showNotification(viewModel.errorMessage!);
                viewModel.clearError();
              });
            }

            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final screenHeight = constraints.maxHeight;
                final screenWidth = constraints.maxWidth;

                // Limit content width on large screens and center it
                const double baseWidth = 393.0;
                const double maxContentWidth = 500.0;
                final bool isMobileWidth = screenWidth <= maxContentWidth;
                final double contentWidth = isMobileWidth ? screenWidth : baseWidth;
                final double scaleFactor = contentWidth / baseWidth;
                final double horizontalPadding = isMobileWidth ? 0.0 : (screenWidth - contentWidth) / 2;
                
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: SizedBox(
                    width: contentWidth,
                    height: screenHeight,
                    child: Stack(
                      children: [
                        // Header section (fixed at top)
                        _buildHeader(scaleFactor, viewModel),

                        // User info top-left
                        _buildUserInfoDisplay(scaleFactor, viewModel),

                        // Scrollable content area with connections
                        _buildConnectionsArea(
                          scaleFactor,
                          screenHeight,
                          viewModel,
                        ),

                        // Bottom button (fixed)
                        _buildBottomButton(scaleFactor, viewModel),
                        
                        // Background overlay to dismiss floating UI (must be below floating UI)
                        if (_showConnectionPopup) _buildDismissOverlay(),
                        
                        // Floating connection interaction UI (must be on top)
                        if (_showConnectionPopup) _buildFloatingTalkUI(),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
  Widget _buildDismissOverlay() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: _hideConnectionPopup,
        child: Container(
          color: Colors.transparent, // Transparent overlay to catch taps
        ),
      ),
    );
  }

  Widget _buildFloatingTalkUI() {
    if (!_showConnectionPopup || _selectedConnection == null || _connectionTapPosition == null) {
      return const SizedBox.shrink();
    }

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localOffset = renderBox.globalToLocal(_connectionTapPosition!);

    return Positioned(
      left: localOffset.dx + 20,
      top: localOffset.dy - 80,
      child: GestureDetector(
        onTap: () {}, // Prevent taps from bubbling to dismiss overlay
        child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEAE7E2), // Match dashboard background color
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.20),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [

            const SizedBox(height: 4),
            // Talk again row with button
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'talk again:',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF494949),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _handleSmallButtonTap,
                  child: Container(
                    height: 20,
                    width: 28, // Horizontally elongated
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAE7E2), // Light gray background
                      borderRadius: BorderRadius.circular(10), // Rounded corners
                      border: Border.all(
                        color: const Color(0xFFC4C1BE), // Slightly darker border
                        width: 0.5,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.chevron_right, // Right-pointing arrow
                        size: 16,
                        color: Color(0xFF494949), // Dark gray arrow
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 2),
            // Connection streak text
            Text(
              'connection streak: 1 day',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF777673),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildHeader(double scaleFactor, DashboardViewModel viewModel) {
    return Positioned(
      left: 0,
      right: 0,
      top: 50 * scaleFactor,
      child: Column(
        children: [
          // TODO: FUTURE FEATURE - Add profile settings button here for returning users to update mother stage and questions
          // This would be a small settings icon in the top-right corner that opens a profile edit screen
          
          // Welcome message with username
          Text(
                          L.dashboard(context).homebaseTitle,
            style: GoogleFonts.poppins(
              fontSize: 20 * scaleFactor,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF494949),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8 * scaleFactor),
          _buildConnectionScoreText(scaleFactor, viewModel),
        ],
      ),
    );
  }

  Widget _buildUserInfoDisplay(double scaleFactor, DashboardViewModel viewModel) {
    return Positioned(
      top: 8 * scaleFactor,
      right: 16 * scaleFactor,
      child: PopupMenuButton<String>(
        onSelected: (String value) {
          // Handle dropdown selection if needed in the future
          if (value == 'logout') {
            // Future: handle logout
          }
        },
        itemBuilder: (BuildContext context) => [
          PopupMenuItem<String>(
            enabled: false, // Make it non-clickable, just for display
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person,
                  size: 16 * scaleFactor,
                  color: const Color(0xFF494949),
                ),
                SizedBox(width: 8 * scaleFactor),
                Text(
                  viewModel.username,
                  style: GoogleFonts.poppins(
                    fontSize: 12 * scaleFactor,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF494949),
                  ),
                ),
              ],
            ),
          ),
        ],
        icon: Icon(
          Icons.settings,
          size: 20 * scaleFactor,
          color: const Color(0xFF777673),
        ),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: const Color(0xFFF2EDE7),
        offset: Offset(0, 32 * scaleFactor),
        padding: EdgeInsets.zero,
        splashRadius: 20 * scaleFactor,
      ),
    );
  }

  Widget _buildConnectionsArea(
    double scaleFactor, 
    double screenHeight, 
    DashboardViewModel viewModel,
  ) {
    return Positioned.fill(
      top: 150 * scaleFactor,
      bottom: 100 * scaleFactor,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20 * scaleFactor),
          child: SizedBox(
            height: math.max(600 * scaleFactor, screenHeight - 330 * scaleFactor),
            child: viewModel.hasConnections
                ? _buildConnectionCircles(scaleFactor, viewModel)
                : _buildNoConnectionsMessage(scaleFactor),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionCircles(double scaleFactor, DashboardViewModel viewModel) {
    final connections = viewModel.activeConnections;
    
    // Predefined positions for circles (up to 6 connections)
    final List<CirclePosition> positions = [
      CirclePosition(left: 20, top: 49, size: 85),
      CirclePosition(left: 220, top: 17, size: 68),
      CirclePosition(left: 190, top: 147, size: 100),
      CirclePosition(left: 71, top: 260, size: 96),
      CirclePosition(left: 238, top: 329, size: 104),
      CirclePosition(left: 30, top: 447, size: 72),
    ];

    return Stack(
      children: [
        // Display actual connections
        ...connections.asMap().entries.map((entry) {
          final index = entry.key;
          final connection = entry.value;
          final position = positions[index % positions.length];
          
          return _buildConnectionCircle(
            scaleFactor,
            connection,
            position,
            viewModel,
          );
        }).toList(),
        
        // Add extra space at bottom for scrolling
        Positioned(
          bottom: 0,
          child: SizedBox(height: 100 * scaleFactor),
        ),
      ],
    );
  }

  Widget _buildConnectionCircle(
    double scaleFactor,
    ConnectionData connection,
    CirclePosition position,
    DashboardViewModel viewModel,
  ) {
    return Positioned(
      left: position.left * scaleFactor,
      top: position.top * scaleFactor,
      child: Opacity(
        opacity: connection.visualOpacity,
        child: GestureDetector(
          onTapDown: (details) => _showConnectionDetailsPopup(connection, details.globalPosition),
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    width: position.size * scaleFactor,
                    height: position.size * scaleFactor,
                    decoration: BoxDecoration(
                      color: connection.displayColor,
                      shape: BoxShape.circle,
                      border: connection.isAvailable 
                          ? Border.all(
                              color: const Color(0xFF4CAF50),
                              width: 3,
                            )
                          : connection.isInWarningState
                              ? Border.all(
                                  color: const Color(0xFFFF9800),
                                  width: 2,
                                )
                              : null,
                      boxShadow: [
                        if (connection.isAvailable)
                          BoxShadow(
                            color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        if (!connection.isAvailable && connection.isInWarningState)
                          BoxShadow(
                            color: const Color(0xFFFF9800).withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: Center(
                      child: connection.isAvailable
                          ? const Icon(
                              Icons.chat_bubble_outline,
                              color: Color(0xFF4CAF50),
                              size: 24,
                            )
                          : connection.isInWarningState
                              ? const Icon(
                                  Icons.warning_outlined,
                                  color: Color(0xFFFF9800),
                                  size: 20,
                                )
                              : Text(
                                  connection.otherUserName.isNotEmpty 
                                      ? connection.otherUserName[0].toUpperCase()
                                      : DashboardTexts.defaultAvatarLetter,
                                  style: GoogleFonts.poppins(
                                    fontSize: 18 * scaleFactor,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF494949),
                                  ),
                                ),
                    ),
                  ),
                  
                  if (connection.connectionStrength < 100)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 12 * scaleFactor,
                        height: 12 * scaleFactor,
                        decoration: BoxDecoration(
                          color: _getStrengthColor(connection.connectionStrength),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 6 * scaleFactor),
              Container(
                constraints: BoxConstraints(
                  maxWidth: (position.size + 20) * scaleFactor,
                ),
                child: Column(
                  children: [
                    Text(
                      connection.displayName,
                      style: GoogleFonts.poppins(
                        fontSize: 12 * scaleFactor,
                        color: const Color(0xFF494949),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2 * scaleFactor),
                    Text(
                      _localizedStatusText(context, connection.statusText),
                      style: GoogleFonts.poppins(
                        fontSize: 10 * scaleFactor,
                        color: connection.isInWarningState 
                            ? const Color(0xFFFF9800)
                            : const Color(0xFF777673),
                        fontWeight: FontWeight.w300,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (connection.isInWarningState)
                      Padding(
                        padding: EdgeInsets.only(top: 2 * scaleFactor),
                        child: Text(
                          connection.engagementPrompt,
                          style: GoogleFonts.poppins(
                            fontSize: 8 * scaleFactor,
                            color: const Color(0xFFFF9800),
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStrengthColor(int strength) {
    if (strength >= 80) return const Color(0xFF4CAF50);
    if (strength >= 60) return const Color(0xFF8BC34A);
    if (strength >= 40) return const Color(0xFFFFC107);
    if (strength >= 20) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  Widget _buildNoConnectionsMessage(double scaleFactor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64 * scaleFactor,
            color: const Color(0xFF777673),
          ),
          SizedBox(height: 16 * scaleFactor),
          Text(
                          L.dashboard(context).noConnections,
            style: GoogleFonts.poppins(
              fontSize: 18 * scaleFactor,
              color: const Color(0xFF494949),
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8 * scaleFactor),
          Text(
                          L.dashboard(context).firstConnectionPrompt,
            style: GoogleFonts.poppins(
              fontSize: 14 * scaleFactor,
              color: const Color(0xFF777673),
              fontWeight: FontWeight.w300,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(double scaleFactor, DashboardViewModel viewModel) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 50 * scaleFactor,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20 * scaleFactor),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // TODO: FUTURE FEATURE - Add "Edit Profile" button here for returning users
            // This button would navigate to a profile edit screen where users can update:
            // - Mother stage (pregnant, postpartum, etc.)
            // - Challenge questions/preferences
            // - Other profile settings
            
            // Primary action button for new connections
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: viewModel.isMatching 
                    ? null 
                    : () {
                        print("DEBUG: Find new connection button clicked");
                        print("DEBUG: About to navigate to LoadingView");
                        
                        // Navigate to loading screen to restart connection process
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LoadingView()),
                        );
                        
                        print("DEBUG: Navigation to LoadingView initiated");
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD9D6D3),
                  foregroundColor: const Color(0xFF494949),
                  padding: EdgeInsets.symmetric(vertical: 16 * scaleFactor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(29),
                  ),
                  elevation: 0,
                ),
                child: viewModel.isMatching
                    ? SizedBox(
                        height: 20 * scaleFactor,
                        width: 20 * scaleFactor,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        L.dashboard(context).findNewConnection,
                        style: TextStyle(
                          fontFamily: 'Satoshi',
                          fontSize: 16 * scaleFactor,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF494949),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _localizedStatusText(BuildContext context, String text) {
    if (text == 'tap to talk again') {
      return L.dashboard(context).tapToTalkAgain;
    }
    return text; // other statuses stay the same for now
  }

  Widget _buildConnectionScoreText(double scaleFactor, DashboardViewModel viewModel) {
    final connectionCount = viewModel.activeConnections.length;
    final fullText = L.dashboard(context).homebaseSubtitle(connectionCount);
    
    // Parse the text to find the number and style it differently
    final numberString = connectionCount.toString();
    final parts = fullText.split(numberString);
    
    if (parts.length == 2) {
      // Successfully split the text around the number
      return RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: parts[0],
              style: GoogleFonts.poppins(
                fontSize: 11 * scaleFactor,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF777673),
                height: 1.35,
              ),
            ),
            TextSpan(
              text: numberString,
              style: GoogleFonts.poppins(
                fontSize: 13 * scaleFactor, // Slightly larger size
                fontWeight: FontWeight.w600,
                color: const Color(0xFFF7601A), // Orange color
                height: 1.35,
                shadows: [
                  Shadow(
                    color: const Color(0xFFF7601A).withOpacity(0.6),
                    blurRadius: 8,
                    offset: const Offset(0, 0),
                  ),
                  Shadow(
                    color: const Color(0xFFF7601A).withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
            ),
            TextSpan(
              text: parts[1],
              style: GoogleFonts.poppins(
                fontSize: 11 * scaleFactor,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF777673),
                height: 1.35,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      );
    } else {
      // Fallback to regular text if parsing fails
      return Text(
        fullText,
        style: GoogleFonts.poppins(
          fontSize: 11 * scaleFactor,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF777673),
          height: 1.35,
        ),
        textAlign: TextAlign.center,
      );
    }
  }
}

class CirclePosition {
  final double left;
  final double top;
  final double size;

  const CirclePosition({
    required this.left,
    required this.top,
    required this.size,
  });
}

class InvitationDialog extends StatelessWidget {
  final InvitationData invitation;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const InvitationDialog({
    Key? key,
    required this.invitation,
    required this.onAccept,
    required this.onDecline,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFEAE7E2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        L.ui(context).chatInvitation,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF494949),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${invitation.senderName} ${L.ui(context).wantsToChat}',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF494949),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            L.ui(context).startConversationPrompt,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF777673),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          child: Text(L.ui(context).decline),
          onPressed: onDecline,
        ),
        ElevatedButton(
          onPressed: onAccept,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEFD4E2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            L.ui(context).accept,
            style: GoogleFonts.poppins(
              color: const Color(0xFF494949),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
} 