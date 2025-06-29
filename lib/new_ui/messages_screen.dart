import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const MessagesScreen(),
    );
  }
}

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({Key? key}) : super(key: key);

  @override
  _MessagesScreenState createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _showOverlay = false;
  String? _selectedChoice;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _toggleOverlay() {
    setState(() {
      _showOverlay = !_showOverlay;
      _selectedChoice = null; // Reset choice when showing overlay
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAE7E2),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = constraints.maxHeight;
            final screenWidth = constraints.maxWidth;
            final scaleFactor = screenWidth / 393.0;
            
            return Container(
              width: screenWidth,
              height: screenHeight,
              child: Stack(
                children: [
                  // Arrow button in top right
                  Positioned(
                    right: 32 * scaleFactor,
                    top: 32 * scaleFactor,
                    child: GestureDetector(
                      onTap: _toggleOverlay,
                      child: Container(
                        width: 70 * scaleFactor,
                        height: 66 * scaleFactor,
                        child: Stack(
                          children: [
                            // Background circle
                            Positioned(
                              top: 11 * scaleFactor,
                              child: Container(
                                width: 70 * scaleFactor,
                                height: 44 * scaleFactor,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE6E3E0),
                                  borderRadius: BorderRadius.circular(29 * scaleFactor),
                                ),
                              ),
                            ),
                            // Arrow image
                            Positioned(
                              left: 2 * scaleFactor,
                              top: 0,
                              child: Container(
                                width: 66 * scaleFactor,
                                height: 66 * scaleFactor,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(33 * scaleFactor),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(33 * scaleFactor),
                                  child: Image.asset(
                                    'lib/assets/NavArrow.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // First message bubble
                  Positioned(
                    left: 45 * scaleFactor,
                    top: 203 * scaleFactor,
                    child: Container(
                      width: 197 * scaleFactor,
                      height: 42 * scaleFactor,
                      padding: EdgeInsets.symmetric(horizontal: 16 * scaleFactor, vertical: 8 * scaleFactor),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD9D9D9),
                        borderRadius: BorderRadius.circular(29 * scaleFactor),
                      ),
                      child: Text(
                        'i never really talked about this with anyone.',
                        style: GoogleFonts.poppins(
                          fontSize: 11 * scaleFactor,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF494949),
                        ),
                      ),
                    ),
                  ),
                  
                  // Response bubble
                  Positioned(
                    right: 45 * scaleFactor,
                    top: 256 * scaleFactor,
                    child: Container(
                      width: 156.36 * scaleFactor,
                      height: 28.31 * scaleFactor,
                      padding: EdgeInsets.symmetric(horizontal: 16 * scaleFactor, vertical: 6 * scaleFactor),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDFE0E2),
                        borderRadius: BorderRadius.circular(29 * scaleFactor),
                      ),
                      child: Text(
                        'yes i feel the same way.',
                        style: GoogleFonts.poppins(
                          fontSize: 11 * scaleFactor,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF494949),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  
                  // Input field at bottom
                  Positioned(
                    left: 79 * scaleFactor,
                    bottom: 66 * scaleFactor,
                    child: Container(
                      width: 243 * scaleFactor,
                      height: 44 * scaleFactor,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6E3E0),
                        borderRadius: BorderRadius.circular(29 * scaleFactor),
                      ),
                      child: TextField(
                        controller: _messageController,
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
                            horizontal: 33 * scaleFactor,
                            vertical: 14 * scaleFactor,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),

                  // Overlay
                  if (_showOverlay)
                    Positioned.fill(
                      child: Container(
                        color: const Color(0xFFC8C5C5).withOpacity(0.9),
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
                              SizedBox(height: 8 * scaleFactor),
                              Text(
                                'did you feel connected to this person?',
                                style: GoogleFonts.poppins(
                                  fontSize: 11 * scaleFactor,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF494949),
                                ),
                              ),
                              SizedBox(height: 24 * scaleFactor),
                              // Binary choice button
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
                                          setState(() {
                                            _selectedChoice = 'yes';
                                          });
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: _selectedChoice == 'yes' 
                                                ? const Color(0xFF494949).withOpacity(0.1)
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
                                                fontWeight: _selectedChoice == 'yes' 
                                                    ? FontWeight.w500 
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
                                          setState(() {
                                            _selectedChoice = 'no';
                                          });
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: _selectedChoice == 'no' 
                                                ? const Color(0xFF494949).withOpacity(0.1)
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
                                                fontWeight: _selectedChoice == 'no' 
                                                    ? FontWeight.w500 
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
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
} 