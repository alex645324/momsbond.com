import 'package:flutter/material.dart';
import '../Templates/conversation_helper.dart';
import '../Database_logic/simple_auth_manager.dart';
import '../views/homepage_view.dart';

// this is the same text alignment for headers and titles 

class CustomAlignedText extends StatelessWidget {
  final String text;
  final Alignment alignment;
  final EdgeInsetsGeometry padding;
  final TextStyle style;
  final TextAlign textAlign;

  const CustomAlignedText({
    Key? key,
    required this.text,
    this.alignment = Alignment.topCenter,
    this.padding = EdgeInsets.zero,
    required this.style,
    this.textAlign = TextAlign.center,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: padding,
        child: Text(
          text,
          textAlign: textAlign,
          style: style,
        ),
      ),
    );
  }
}

class ChatInvitationPopup extends StatelessWidget {
  final String senderName;
  final Function() onAccept;
  final Function() onDecline;

  const ChatInvitationPopup({
    Key? key,
    required this.senderName,
    required this.onAccept,
    required this.onDecline,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFF2EDE7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFD7BFB8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Flower icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF2EDE7),
                  border: Border.all(
                    color: const Color(0xFFD7BFB8),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.spa_rounded,
                    size: 35,
                    color: Colors.pink[200],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Invitation text
              Text(
                "Chat Invitation",
                style: const TextStyle(
                  fontFamily: "Nuosu SIL",
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF574F4E),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "$senderName would like to chat with you.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: "Nuosu SIL",
                  fontSize: 16,
                  color: Color(0xFF574F4E),
                ),
              ),
              const SizedBox(height: 24),
              
              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Decline button
                  GestureDetector(
                    onTap: onDecline,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2EDE7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFD7BFB8),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 4,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        "Decline",
                        style: const TextStyle(
                          fontFamily: "Nuosu SIL",
                          fontSize: 14,
                          color: Color(0xFF574F4E),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Accept button
                  GestureDetector(
                    onTap: onAccept,
                    child: Container(
                      width: 120,
                      height: 50,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.pink[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.pink[200]!,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 4,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        "Accept",
                        style: TextStyle(
                          fontFamily: "Nuosu SIL",
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.pink[400],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// This is the boxs that have the options for what types of feelings moms are having, 
// this is what i use in question sets 1 and 2 
class CustomTextBox extends StatelessWidget {
  final String text;
  final double width;
  final double height;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry padding;
  final Alignment alignment;

  const CustomTextBox({
    Key? key,
    required this.text,
    this.width = 226,
    this.height = 43,
    this.textStyle,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.alignment = Alignment.center,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFF2EDE7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFD7BFB8),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.25),
              offset: Offset(4, 4),
              blurRadius: 4,
            ),
          ],
        ),
        padding: padding,
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: textStyle ??
                const TextStyle(
                  fontFamily: "Nuosu SIL",
                  fontSize: 14,
                  color: Color(0xFF574F4E),
                ),
          ),
        ),
      ),
    );
  }
}






// this is the box you should use for most if not all of the boxes in your code 

/// This is just a simple box with text inside it ( this is the back button and next button)       
// this is what i use in question sets 1 and 2 
class CustomDirectionTextBox extends StatelessWidget {
  final String text;
  final double bottom;
  final double? right;
  final double? left;
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final TextStyle? textStyle;
  final bool centerHorizontally;
  final VoidCallback? onTap; // Add this parameter

  const CustomDirectionTextBox({
    Key? key,
    required this.text,
    this.bottom = 40,
    this.right = 20,
    this.left,
    this.maxWidth = 300,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.textStyle,
    this.centerHorizontally = false,
    this.onTap, // Initialize it
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Create the actual button content
    final boxContent = Container(
      constraints: BoxConstraints(
        minWidth: 0,
        maxWidth: maxWidth,
        minHeight: 40,
        maxHeight: 40,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF2EDE7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFD7BFB8),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.25),
            offset: Offset(2, 2),
            blurRadius: 4,
          ),
        ],
      ),
      padding: padding,
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: textStyle ??
              const TextStyle(
                fontFamily: "Nuosu SIL",
                fontSize: 14,
                color: Color(0xFF574F4E),
              ),
        ),
      ),
    );

    // Wrap with GestureDetector if onTap is provided
    final Widget buttonWidget = onTap != null
        ? GestureDetector(onTap: onTap, child: boxContent)
        : boxContent;

    // Return the widget
    return buttonWidget;
  }
}








// this is the custom typing bar 
class CustomTypingBar extends StatelessWidget {
  final double bottom;
  final double top;
  final double left;
  final double right;
  final double width;
  final double height;
  final String hintText;

  const CustomTypingBar({
    Key? key,
    this.top = 10,
    this.bottom = 20, // Changed default to 20 for better bottom spacing
    this.left = 20,
    this.right = 20,
    this.width = 329,
    this.height = 40,
    this.hintText = "Type a message...",
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          bottom: bottom,
          left: left,
          right: right,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: const Color(0xFFF2EDE7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFD7BFB8),
                width: 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.25),
                  offset: Offset(0, 4),
                  blurRadius: 4,
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
            child: Center(
              child: TextField(
                textAlign: TextAlign.left,
                textAlignVertical: TextAlignVertical.center,
                style: const TextStyle(
                  fontFamily: "Nuosu SIL",
                  fontSize: 14,
                  color: Color(0xFF574F4E),
                ),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: const TextStyle(
                    fontFamily: "Nuosu SIL",
                    fontSize: 14,
                    color: Color(0xFF574F4E),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  isDense: false,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class UserAccountHeader extends StatelessWidget {
  final String username;
  
  const UserAccountHeader({
    Key? key,
    required this.username,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 20,
      right: 20,
      child: Row(
        children: [
          // Logout button
          GestureDetector(
            onTap: () async {
              print("\n" + "="*50);
              print("LOGOUT BUTTON PRESSED - ${DateTime.now()}");
              print("Current user: $username");
              print("="*50);
              
              await SimpleAuthManager().signOut();
              
              print("User signed out, navigating to HomepageView");
              print("="*50 + "\n");
              
              // Navigate back to sign in
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomepageView()),
                (route) => false,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!, width: 1),
              ),
              child: Text(
                "Logout",
                style: TextStyle(
                  fontFamily: "Nuosu SIL",
                  fontSize: 12,
                  color: Colors.red[600],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            username,
            style: const TextStyle(
              fontFamily: "Nuosu SIL",
              fontSize: 14,
              color: Color(0xFF574F4E),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF2EDE7),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFD7BFB8),
                width: 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.25),
                  offset: Offset(2, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.person,
                size: 20,
                color: Color(0xFF574F4E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// this is custom box for the dashboard for the user to see there conncetions 

class CustomConnectionCard extends StatefulWidget {
  /// The name of the connection to display inside the card.
  final String connectionName;

  // Whether the connection is available for chat. 
  final bool isAvailable;
  
  // New parameter for connection age/activity
  final int inactiveDays;

  const CustomConnectionCard({
    Key? key,
    required this.connectionName,
    this.isAvailable = false,
    this.inactiveDays = 0,
  }) : super(key: key);

  @override
  State<CustomConnectionCard> createState() => _CustomConnectionCardState();
}

class _CustomConnectionCardState extends State<CustomConnectionCard> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print("CustomConnectionCard: Building card for ${widget.connectionName}, available: ${widget.isAvailable}, inactive days: ${widget.inactiveDays}");
    
    // No decay visualisation – always full opacity
    final double opacity = 1.0;

    return Opacity(
      opacity: opacity,
      child: _buildCard(),
    );
  }
  
  Widget _buildCard() {
    return Stack(
        children: [
          Container(
            width: 97,
            height: 152,
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF2EDE7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFD7BFB8),
                width: 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.25),
                  offset: Offset(4, 4),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Center(
              child: Text(
                widget.connectionName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: "Nuosu SIL",
                  fontSize: 18,
                  color: Color(0xFF574F4E),
                ),
              ),
            ),
          ),
          
          // Availability indicator
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: widget.isAvailable ? Colors.green : Colors.red,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}