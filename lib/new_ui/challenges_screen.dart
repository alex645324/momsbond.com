import 'package:flutter/material.dart';

// ====================
// MAIN APP ENTRY POINT
// ====================
void main() { 
    runApp(const MyApp()); 
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const ChallengesScreen(),
    );
  }
}

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
// BUTTON CLASS
// ====================
class ChallengeButtonConfig {
  final String id;
  final String text;
  final Color backgroundColor;
  final double width;
  final double height;
  final double fontSize;
  final double borderRadius;
  final EdgeInsets padding;
  final Alignment alignment;
  final double verticalSpacing;

  const ChallengeButtonConfig({
    required this.id,
    required this.text,
    required this.backgroundColor,
    required this.width,
    required this.height,
    this.fontSize = 14,
    this.borderRadius = 31,
    this.padding = const EdgeInsets.symmetric(horizontal: 10),
    required this.alignment,
    this.verticalSpacing = 20,
  });
}

// ====================
// CIRCLE CONFIGURATIONS
// ====================
// Modify these values to adjust each circle individually
const circle1 = CircleConfig(
  left: -26,
  top: -27,
  width: 66,
  height: 66,
);

const circle2 = CircleConfig(
  right: 34,
  top: 161,
  width: 38,
  height: 38,
);

const circle3 = CircleConfig(
  right: 15,
  top: 241,
  width: 13,
  height: 13,
);

const circle4 = CircleConfig(
  right: 9,
  top: 363,
  width: 26,
  height: 26,
);

const circle5 = CircleConfig(
  left: 147,
  top: 440,
  width: 12,
  height: 12,
);

const circle6 = CircleConfig(
  left: -26,
  top: 518,
  width: 83,
  height: 85,
);

// New subtle circles
const circle7 = CircleConfig(
  right: 80,
  top: 50,
  width: 15,
  height: 15,
  opacity: 0.3,
);

const circle8 = CircleConfig(
  left: 60,
  top: 200,
  width: 20,
  height: 20,
  opacity: 0.25,
);

const circle9 = CircleConfig(
  right: -10,
  bottom: 200,
  width: 45,
  height: 45,
  opacity: 0.3,
);

const circle10 = CircleConfig(
  left: 30,
  bottom: 150,
  width: 18,
  height: 18,
  opacity: 0.35,
);

// ====================
// BUTTON CONFIGURATIONS
// ====================
const bodyChangesButton = ChallengeButtonConfig(
  id: "body_changes",
  text: "worries about body changes?",
  backgroundColor: Color(0xFFEFD4E2),
  width: 250,
  height: 70,
  fontSize: 12,
  borderRadius: 35,
  alignment: Alignment.centerRight,
  verticalSpacing: 20,
);

const depressionButton = ChallengeButtonConfig(
  id: "depression_anxiety",
  text: "feeling postpartum depression or anxiety?",
  backgroundColor: Color(0xFFEDE4C6),
  width: 290,
  height: 80,
  fontSize: 12,
  borderRadius: 35,
  alignment: Alignment.centerLeft,
  verticalSpacing: 20,
);

const lonelinessButton = ChallengeButtonConfig(
  id: "loneliness",
  text: "Loneliness because friends don't understand motherhood?",
  backgroundColor: Color(0xFFD8DAC5),
  width: 300,
  height: 80,
  fontSize: 12,
  borderRadius: 35,
  alignment: Alignment.centerRight,
  verticalSpacing: 20,
);

// ====================
// CHALLENGES SCREEN
// ====================
class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({Key? key}) : super(key: key);

  @override
  _ChallengesScreenState createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  // Track selected challenges
  Set<String> selectedChallenges = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAE7E2),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 768;
          final isMobile = constraints.maxWidth <= 768;

          return ResponsiveChallengesLayout(
            isDesktop: isDesktop,
            isMobile: isMobile,
            screenWidth: constraints.maxWidth,
            screenHeight: constraints.maxHeight,
            selectedChallenges: selectedChallenges,
            onChallengeSelected: (challenge) {
              setState(() {
                if (selectedChallenges.contains(challenge)) {
                  selectedChallenges.remove(challenge);
                } else {
                  selectedChallenges.add(challenge);
                }
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
class ResponsiveChallengesLayout extends StatelessWidget {
  final bool isDesktop;
  final bool isMobile;
  final double screenWidth;
  final double screenHeight;
  final Set<String> selectedChallenges;
  final Function(String) onChallengeSelected;

  const ResponsiveChallengesLayout({
    Key? key,
    required this.isDesktop,
    required this.isMobile,
    required this.screenWidth,
    required this.screenHeight,
    required this.selectedChallenges,
    required this.onChallengeSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scaleFactor = isDesktop ? 0.8 : 1.0;
    double getResponsiveSize(double mobileSize) => mobileSize * scaleFactor;

    if (isDesktop) {
      return Center(
        child: Container(
          width: 400,
          child: buildMainContent(
            (left) => left,
            (top) => top,
            getResponsiveSize,
          ),
        ),
      );
    } else {
      return buildMainContent(
        (left) => left,
        (top) => top,
        getResponsiveSize,
      );
    }
  }

  List<Widget> buildBackgroundCircles(double Function(double) getSize) {
    return [
      for (var circle in [
        circle1,
        circle2,
        circle3,
        circle4,
        circle5,
        circle6,
        circle7,
        circle8,
        circle9,
        circle10,
      ])
        Positioned(
          left: circle.left != null ? getSize(circle.left!) : null,
          right: circle.right != null ? getSize(circle.right!) : null,
          top: circle.top != null ? getSize(circle.top!) : null,
          bottom: circle.bottom != null ? getSize(circle.bottom!) : null,
          child: Container(
            width: getSize(circle.width),
            height: getSize(circle.height),
            decoration: BoxDecoration(
              color: const Color(0xFFD9D9D9).withOpacity(circle.opacity),
              shape: BoxShape.circle,
            ),
          ),
        ),
    ];
  }

  Widget buildMainContent(
    double Function(double) getLeft,
    double Function(double) getTop,
    double Function(double) getSize,
  ) {
    return Builder(
      builder: (BuildContext context) => Stack(
        children: [
          ...buildBackgroundCircles(getSize),
          
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: getSize(32)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: getSize(100)),
                  
                  // Main title
                  Text(
                    "what kinds of challenges\nhave you encountered?",
                    style: TextStyle(
                      fontFamily: "Poppins",
                      fontWeight: FontWeight.w600,
                      fontSize: getSize(20),
                      color: const Color(0xFF494949),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: getSize(50)),

                  // Challenge buttons
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: getSize(20)),
                    child: Column(
                      children: [
                        for (var buttonConfig in [
                          bodyChangesButton,
                          depressionButton,
                          lonelinessButton,
                        ]) ...[
                          Align(
                            alignment: buttonConfig.alignment,
                            child: buildChallengeButton(
                              getSize,
                              buttonConfig,
                            ),
                          ),
                          if (buttonConfig != lonelinessButton)
                            SizedBox(height: getSize(buttonConfig.verticalSpacing)),
                        ],
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Navigation control
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: getSize(60), right: getSize(20)),
                      child: Container(
                        width: getSize(144),
                        height: getSize(66),
                        child: Stack(
                          children: [
                            // Background pill
                            Positioned(
                              top: getSize(11),
                              child: Container(
                                width: getSize(144),
                                height: getSize(44),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD9D9D9),
                                  borderRadius: BorderRadius.circular(getSize(29)),
                                ),
                              ),
                            ),
                            
                            // Back arrow (left side)
                            Positioned(
                              left: getSize(6),
                              top: 0,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pop();
                                },
                                child: Container(
                                  width: getSize(66),
                                  height: getSize(66),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(getSize(33)),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(getSize(33)),
                                    child: Transform.scale(
                                      scaleX: -1,
                                      child: Opacity(
                                        opacity: 0.54,
                                        child: Image.asset(
                                          "lib/assets/NavArrow.png",
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Center divider
                            Positioned(
                              left: getSize(71),
                              top: getSize(18),
                              child: Container(
                                width: getSize(3),
                                height: getSize(30),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF919091).withOpacity(0.38),
                                  borderRadius: BorderRadius.circular(getSize(20)),
                                ),
                              ),
                            ),

                            // Forward arrow (right side) with dynamic background
                            if (selectedChallenges.isNotEmpty)
                              Positioned(
                                left: getSize(73),
                                top: getSize(11),
                                child: Container(
                                  width: getSize(70),
                                  height: getSize(44),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF494949),
                                    borderRadius: BorderRadius.circular(getSize(29)),
                                  ),
                                ),
                              ),

                            // Forward arrow (right side)
                            Positioned(
                              left: getSize(73),
                              top: 0,
                              child: GestureDetector(
                                onTap: selectedChallenges.isNotEmpty ? () {
                                  print("Selected challenges: $selectedChallenges");
                                  // Navigator.push or other navigation logic
                                } : null,
                                child: Container(
                                  width: getSize(66),
                                  height: getSize(66),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(getSize(33)),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(getSize(33)),
                                    child: Opacity(
                                      opacity: selectedChallenges.isNotEmpty ? 1.0 : 0.54,
                                      child: Image.asset(
                                        "lib/assets/NavArrow.png",
                                        fit: BoxFit.cover,
                                      ),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildChallengeButton(
    double Function(double) getSize,
    ChallengeButtonConfig config,
  ) {
    final isSelected = selectedChallenges.contains(config.id);
    
    return GestureDetector(
      onTap: () => onChallengeSelected(config.id),
      child: Container(
        width: getSize(config.width),
        height: getSize(config.height),
        decoration: BoxDecoration(
          color: config.backgroundColor,
          borderRadius: BorderRadius.circular(getSize(config.borderRadius)),
          border: isSelected 
              ? Border.all(color: const Color(0xFF494949), width: 2)
              : null,
        ),
        child: Center(
          child: Padding(
            padding: config.padding,
            child: Text(
              config.text,
              style: TextStyle(
                fontFamily: "Satoshi",
                fontWeight: FontWeight.w400,
                fontSize: getSize(config.fontSize),
                color: const Color(0xFF494949),
                height: 1.35,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
} 