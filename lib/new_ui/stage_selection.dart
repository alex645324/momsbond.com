import 'package:flutter/material.dart';

// ====================
// CIRCLE CLASS
// ====================
class CircleConfig {
  final double? left;    // null if using right position
  final double? right;   // null if using left position
  final double? top;     // null if using bottom position
  final double? bottom;  // null if using top position
  final double width;
  final double height;
  final double opacity;

  const CircleConfig({
    this.left,
    this.right,
    this.top,
    this.bottom,
    required this.width,
    required this.height,
    this.opacity = 0.4,
  });
}

// ====================
// CIRCLE CONFIGURATIONS
// ====================
// Modify these values to adjust each circle individually
const circle1 = CircleConfig(
  left: -15,
  top: -10,
  width: 50,
  height: 50,
);

const circle2 = CircleConfig(
  right: 30,
  top: 145,
  width: 57,
  height: 57,
);

const circle3 = CircleConfig(
  left: -25,
  bottom: 140,
  width: 70,
  height: 70,
);

const circle4 = CircleConfig(
  right: -50,
  bottom: 10,
  width: 100,
  height: 100,
);

// New circles - adjust positions and sizes as needed
const circle5 = CircleConfig(
  right: 90,
  bottom: 390,
  width: 30,
  height: 30,
);

const circle6 = CircleConfig(
  left: 30,
  top: 290,
  width: 25,
  height: 25,
);

// ====================
// MAIN APP ENTRY POINT
// ====================
void main() { 
    runApp(const MyApp()); 
}

// Main app widget - sets up MaterialApp and routes to StageSelectionPage
class MyApp extends StatelessWidget { 
    const MyApp({Key? key}) : super(key: key);

    @override
    Widget build(BuildContext context) { 
        return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: const StageSelectionPage(), // Direct route to stage selection
        );
    }
}

// ====================
// STAGE SELECTION PAGE
// ====================
// Main page widget that handles the "What stage are you in?" screen
// This is a StatefulWidget because it needs to track which stage is selected
class StageSelectionPage extends StatefulWidget {
  const StageSelectionPage({Key? key}) : super(key: key);

  @override
  _StageSelectionPageState createState() => _StageSelectionPageState();
}

// State class that manages the selected stage and builds the UI
class _StageSelectionPageState extends State<StageSelectionPage> {
  // Tracks which motherhood stage the user has selected (null = no selection)
  String? selectedStage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Background color matching Figma design (#EAE7E2)
      backgroundColor: const Color(0xFFEAE7E2),
      body: LayoutBuilder(
        // LayoutBuilder allows us to create responsive design based on screen size
        builder: (context, constraints) {
          // Responsive breakpoints
          final isDesktop = constraints.maxWidth > 768;
          final isMobile = constraints.maxWidth <= 768;

          // Pass all necessary data to the responsive widget
          return ResponsiveStageSelection(
            isDesktop: isDesktop,
            isMobile: isMobile,
            screenWidth: constraints.maxWidth,
            screenHeight: constraints.maxHeight,
            selectedStage: selectedStage, // Current selection state
            onStageSelected: (stage) {
              // Callback function when user selects a stage
              setState(() {
                selectedStage = stage; // Update the selected stage
              });
            },
          );
        },
      ),
    );
  }
}

// ====================
// RESPONSIVE LAYOUT HANDLER
// ====================
// This widget handles the responsive layout logic for both mobile and desktop
class ResponsiveStageSelection extends StatelessWidget {
  // Screen size detection properties
  final bool isDesktop;
  final bool isMobile;
  final double screenWidth;
  final double screenHeight;
  
  // State management properties
  final String? selectedStage; // Currently selected motherhood stage
  final Function(String) onStageSelected; // Callback when user selects a stage

  const ResponsiveStageSelection({
    Key? key,
    required this.isDesktop,
    required this.isMobile,
    required this.screenWidth,
    required this.screenHeight,
    required this.selectedStage,
    required this.onStageSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Scale factor for responsive sizing (smaller on desktop to prevent oversizing)
    final scaleFactor = isDesktop ? 0.8 : 1.0;

    // Helper function to scale sizes based on device type
    double getResponsiveSize(double mobileSize) => mobileSize * scaleFactor;

    // DESKTOP LAYOUT: Center content with fixed width
    if (isDesktop) {
      return Center(
        child: Container(
          width: 400, // Fixed width container for desktop
          child: buildMainContent(
            (left) => left,   // No left positioning needed
            (top) => top,     // No top positioning needed
            getResponsiveSize, // Apply scaling
          ),
        ),
      );
    } 
    // MOBILE LAYOUT: Full screen content
    else {
      return buildMainContent(
        (left) => left,     // No positioning adjustments
        (top) => top,       // No positioning adjustments
        getResponsiveSize,  // Apply scaling (1.0 for mobile)
      );
    }
  }

  // ====================
  // DECORATIVE CIRCLES
  // ====================
  List<Widget> buildBackgroundCircles(double Function(double) getSize) {
    return [
      // Top-left circle - Large, aligned with 'what stage' text
      Positioned(
        left: circle1.left != null ? getSize(circle1.left!) : null,
        right: circle1.right != null ? getSize(circle1.right!) : null,
        top: circle1.top != null ? getSize(circle1.top!) : null,
        bottom: circle1.bottom != null ? getSize(circle1.bottom!) : null,
        child: Container(
          width: getSize(circle1.width),
          height: getSize(circle1.height),
          decoration: BoxDecoration(
            color: const Color(0xFFD9D9D9).withOpacity(circle1.opacity),
            shape: BoxShape.circle,
          ),
        ),
      ),
      // Top-right circle - Medium, above and right of pregnant button
      Positioned(
        left: circle2.left != null ? getSize(circle2.left!) : null,
        right: circle2.right != null ? getSize(circle2.right!) : null,
        top: circle2.top != null ? getSize(circle2.top!) : null,
        bottom: circle2.bottom != null ? getSize(circle2.bottom!) : null,
        child: Container(
          width: getSize(circle2.width),
          height: getSize(circle2.height),
          decoration: BoxDecoration(
            color: const Color(0xFFD9D9D9).withOpacity(circle2.opacity),
            shape: BoxShape.circle,
          ),
        ),
      ),
      // Bottom-left circle - Large, aligned with toddler button
      Positioned(
        left: circle3.left != null ? getSize(circle3.left!) : null,
        right: circle3.right != null ? getSize(circle3.right!) : null,
        top: circle3.top != null ? getSize(circle3.top!) : null,
        bottom: circle3.bottom != null ? getSize(circle3.bottom!) : null,
        child: Container(
          width: getSize(circle3.width),
          height: getSize(circle3.height),
          decoration: BoxDecoration(
            color: const Color(0xFFD9D9D9).withOpacity(circle3.opacity),
            shape: BoxShape.circle,
          ),
        ),
      ),
      // Bottom-right circle - Medium, aligned with teen button
      Positioned(
        left: circle4.left != null ? getSize(circle4.left!) : null,
        right: circle4.right != null ? getSize(circle4.right!) : null,
        top: circle4.top != null ? getSize(circle4.top!) : null,
        bottom: circle4.bottom != null ? getSize(circle4.bottom!) : null,
        child: Container(
          width: getSize(circle4.width),
          height: getSize(circle4.height),
          decoration: BoxDecoration(
            color: const Color(0xFFD9D9D9).withOpacity(circle4.opacity),
            shape: BoxShape.circle,
          ),
        ),
      ),
      // New circle 5
      Positioned(
        left: circle5.left != null ? getSize(circle5.left!) : null,
        right: circle5.right != null ? getSize(circle5.right!) : null,
        top: circle5.top != null ? getSize(circle5.top!) : null,
        bottom: circle5.bottom != null ? getSize(circle5.bottom!) : null,
        child: Container(
          width: getSize(circle5.width),
          height: getSize(circle5.height),
          decoration: BoxDecoration(
            color: const Color(0xFFD9D9D9).withOpacity(circle5.opacity),
            shape: BoxShape.circle,
          ),
        ),
      ),
      // New circle 6
      Positioned(
        left: circle6.left != null ? getSize(circle6.left!) : null,
        right: circle6.right != null ? getSize(circle6.right!) : null,
        top: circle6.top != null ? getSize(circle6.top!) : null,
        bottom: circle6.bottom != null ? getSize(circle6.bottom!) : null,
        child: Container(
          width: getSize(circle6.width),
          height: getSize(circle6.height),
          decoration: BoxDecoration(
            color: const Color(0xFFD9D9D9).withOpacity(circle6.opacity),
            shape: BoxShape.circle,
          ),
        ),
      ),
    ];
  }

  // ====================
  // MAIN CONTENT BUILDER
  // ====================
  // Builds the main screen content with title, subtitle, buttons, and navigation
  Widget buildMainContent(
    double Function(double) getLeft,  // Left positioning function (unused but kept for consistency)
    double Function(double) getTop,   // Top positioning function (unused but kept for consistency)
    double Function(double) getSize,  // Size scaling function for responsive design
  ) {
    return Stack(
      children: [
        // Add the background circles
        ...buildBackgroundCircles(getSize),
        
        // Main content
        SafeArea(
          child: Padding(
            // Horizontal padding scaled for responsive design
            padding: EdgeInsets.symmetric(horizontal: getSize(32)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center, // Center all content horizontally
              children: [
                // TOP SPACING
                SizedBox(height: getSize(100)), // Space from top of safe area
                
                // MAIN TITLE
                Text(
                  'what stage are you in?',
                  style: TextStyle(
                    fontFamily: 'Poppins',      // Primary font
                    fontWeight: FontWeight.w500, // Medium weight
                    fontSize: getSize(20),       // Responsive font size
                    color: const Color(0xFF494949), // Dark gray color from Figma
                    height: 1.5,                 // Line height
                  ),
                  textAlign: TextAlign.center,
                ),

                // SPACING BETWEEN TITLE AND SUBTITLE
                SizedBox(height: getSize(8)),

                // SUBTITLE
                Text(
                  'this helps us match you with the best fit :)',
                  style: TextStyle(
                    fontFamily: 'Satoshi',         // Secondary font
                    fontWeight: FontWeight.w400,   // Regular weight
                    fontSize: getSize(11),         // Smaller responsive font size
                    color: const Color(0xFF777673), // Light gray color from Figma
                    height: 1.35,                  // Line height
                  ),
                  textAlign: TextAlign.center,
                ),

                // SPACING BEFORE BUTTONS
                SizedBox(height: getSize(80)),

                // Option buttons - positioned more like Figma layout
                // Option buttons - two column layout with equal padding
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: getSize(20)), // Equal left/right padding
                  child: Column(
                    children: [
                      // Row 1: Pink button (right aligned)
                      Row(
                        children: [
                          const Spacer(),
                          buildStageButtonMinimal(
                            getSize,
                            'pregnant',
                            'pregnant?',
                            const Color(0xFFEFD4E2),
                            320, // Make it wider to match the image
                            65,
                          ),
                        ],
                      ),

                      SizedBox(height: getSize(18)), // Increased spacing by 3px

                      // Row 2: Yellow button (left aligned)  
                      Row(
                        children: [
                          buildStageButtonMinimal(
                            getSize,
                            'toddler',
                            'toddler mom?',
                            const Color(0xFFEDE4C6),
                            250,
                            65,
                          ),
                          const Spacer(),
                        ],
                      ),

                      SizedBox(height: getSize(18)), // Increased spacing by 3px

                      // Row 3: Green button (right aligned)
                      Row(
                        children: [
                          const Spacer(),
                          buildStageButtonMinimal(
                            getSize,
                            'teen',
                            'teen mom?',
                            const Color(0xFFD8DAC5),
                            250,
                            65,
                          ),
                        ],
                      ),

                      SizedBox(height: getSize(18)), // Increased spacing by 3px

                      // Row 4: Blue button (left aligned)
                      Row(
                        children: [
                          buildStageButtonMinimal(
                            getSize,
                            'adult',
                            'adult mom?',
                            const Color(0xFFBBCAE4).withOpacity(0.30),
                            320,
                            65,
                          ),
                          const Spacer(),
                        ],
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Continue button - right aligned and flush with padding
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: getSize(60), right: getSize(20)), // Match the button group padding
                    child: GestureDetector(
                      onTap: selectedStage != null ? () {
                        // Handle continue action
                        print('Selected stage: $selectedStage');
                        // Navigator.push or other navigation logic
                      } : null,
                      child: Container(
                        width: getSize(70),
                        height: getSize(66),
                        child: Stack(
                          children: [
                            // Background circle
                            Positioned(
                              top: getSize(11),
                              child: Container(
                                width: getSize(70),
                                height: getSize(44),
                                decoration: BoxDecoration(
                                  color: selectedStage != null 
                                      ? const Color(0xFF494949) 
                                      : const Color(0xFFD9D9D9),
                                  borderRadius: BorderRadius.circular(getSize(29)),
                                ),
                              ),
                            ),
                            // Arrow image
                            Positioned(
                              left: getSize(2),
                              top: 0,
                              child: Container(
                                width: getSize(66),
                                height: getSize(66),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(getSize(33)),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(getSize(33)),
                                  child: Opacity(
                                    opacity: selectedStage != null ? 1.0 : 0.54,
                                    child: Image.asset(
                                      'lib/assets/NavArrow.png',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildStageButtonMinimal(
    double Function(double) getSize,
    String value,
    String text,
    Color backgroundColor,
    double width,
    double height,
  ) {
    final isSelected = selectedStage == value;
    
    return GestureDetector(
      onTap: () => onStageSelected(value),
      child: Container(
        width: getSize(width),
        height: getSize(height),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(getSize(31)),
          border: isSelected 
              ? Border.all(color: const Color(0xFF494949), width: 2)
              : null,
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontWeight: FontWeight.w400,
              fontSize: getSize(11),
              color: const Color(0xFF494949),
              height: 1.35,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
} 
