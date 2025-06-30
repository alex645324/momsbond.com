import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../models/dashboard_model.dart';
import '../models/messages_model.dart';
import '../views/messages_view.dart';
import '../views/loading_view.dart';
import 'dart:math' as math;

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
            label: 'Dismiss',
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
                final scaleFactor = screenWidth / 393.0;
                
                return Stack(
                  children: [
                    // Header section (fixed at top)
                    _buildHeader(scaleFactor, viewModel),

                    // Scrollable content area with connections
                    _buildConnectionsArea(
                      scaleFactor, 
                      screenHeight, 
                      viewModel,
                    ),

                    // Bottom button (fixed)
                    _buildBottomButton(scaleFactor, viewModel),
                  ],
                );
              },
            );
          },
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
            'welcome back, ${viewModel.username}',
            style: GoogleFonts.poppins(
              fontSize: 16 * scaleFactor,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF777673),
              height: 1.35,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8 * scaleFactor),
          Text(
            'this is your homebase',
            style: GoogleFonts.poppins(
              fontSize: 20 * scaleFactor,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF494949),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8 * scaleFactor),
          Text(
            'where you maintain and create new connections.',
            style: GoogleFonts.poppins(
              fontSize: 11 * scaleFactor,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF777673),
              height: 1.35,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionsArea(
    double scaleFactor, 
    double screenHeight, 
    DashboardViewModel viewModel,
  ) {
    return Positioned.fill(
      top: 200 * scaleFactor,
      bottom: 130 * scaleFactor,
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
          onTap: connection.isActive 
              ? () => viewModel.sendInvitation(connection)
              : null,
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
                                      : 'U',
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
                      connection.statusText,
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
            'No connections yet.',
            style: GoogleFonts.poppins(
              fontSize: 18 * scaleFactor,
              color: const Color(0xFF494949),
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8 * scaleFactor),
          Text(
            'Start by making your first connection!',
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
                  backgroundColor: const Color(0xFF9B7B5F),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16 * scaleFactor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 4,
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
                        'find new connection',
                        style: GoogleFonts.poppins(
                          fontSize: 16 * scaleFactor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
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
        'Chat Invitation',
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
            '${invitation.senderName} wants to chat with you.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF494949),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Would you like to start a conversation?',
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
          onPressed: onDecline,
          child: Text(
            'Decline',
            style: GoogleFonts.poppins(
              color: const Color(0xFF777673),
              fontWeight: FontWeight.w400,
            ),
          ),
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
            'Accept',
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