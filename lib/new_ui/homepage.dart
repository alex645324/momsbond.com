import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const Homepage(),
    );
  }
}

class Homepage extends StatelessWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAE7E2),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 768;
          final isMobile = constraints.maxWidth <= 768;

          return ResponsiveHomepage(
            isDesktop: isDesktop,
            isMobile: isMobile,
            screenWidth: constraints.maxWidth,
            screenHeight: constraints.maxHeight,
          );
        },
      ),
    );
  }
}

class ResponsiveHomepage extends StatelessWidget {
  final bool isDesktop;
  final bool isMobile;
  final double screenWidth;
  final double screenHeight;

  const ResponsiveHomepage({
    Key? key,
    required this.isDesktop,
    required this.isMobile,
    required this.screenWidth,
    required this.screenHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // your existing scaleFactor, getResponsiveLeft/Top/Size functions
    final scaleFactor = isDesktop ? screenWidth / 375 : 1.0;
    final maxScale = isDesktop ? 2.5 : 1.0;
    final finalScale = scaleFactor > maxScale ? maxScale : scaleFactor;

    double getResponsiveLeft(double mobileLeft) {
      if (isDesktop) {
        final designWidth = 375 * finalScale;
        final centerOffset = (screenWidth - designWidth) / 2;
        return centerOffset + (mobileLeft * finalScale);
      }
      return mobileLeft;
    }

    double getResponsiveTop(double mobileTop) {
      if (isDesktop) {
        final topPadding = screenHeight * 0.1;
        return topPadding + (mobileTop * finalScale);
      }
      return mobileTop;
    }

    double getResponsiveSize(double mobileSize) => mobileSize * finalScale;

    return Stack(
      children: [
        // 1) ALL your other background shapes
        ...buildBackgroundElements(getResponsiveLeft, getResponsiveTop, getResponsiveSize),

        // 2) BIG grey circle, inserted here so it sits OVER the colored shapes but UNDER your images
        Positioned(
          left: -200,
          bottom: 150,
          child: Container(
            width: 350,
            height: 350,
            decoration: const BoxDecoration(
              color: Color(0xFFE3DED5),
              shape: BoxShape.circle,
            ),
          ),
        ),

        // 3) (Optional) desktop‐only layout widget
        if (isDesktop)
          buildDesktopLayout(getResponsiveLeft, getResponsiveTop, getResponsiveSize)
        else
          buildMobileLayout(),

        // 4) YOUR IMAGE LAYER
        ...buildImages(getResponsiveLeft, getResponsiveTop, getResponsiveSize),

        // 5) YOUR TEXT LAYER
        ...buildTextContent(getResponsiveLeft, getResponsiveTop, getResponsiveSize),
      ],
    );
  }

  List<Widget> buildBackgroundElements(
    double Function(double) getLeft,
    double Function(double) getTop,
    double Function(double) getSize,
  ) {
    return [
      // Small ellipse (right) - Keep responsive for now
      Positioned(
        left: 261,
        top: 306,
        child: Container(
          width: 114,
          height: 114,
          decoration: BoxDecoration(
            color: const Color(0xFFE3DED5),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 4,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
      ),
      // Small ellipse (right, overlay) - Keep responsive for now
      Positioned(
        left: 400,
        top: 600,
        child: Container(
          width: 300,
          height: 600,
          decoration: const BoxDecoration(
            color: Color(0xFFE3DED5),
            shape: BoxShape.circle,
          ),
        ),
      ),
      // Decorative rectangles - Positioned more naturally around the mother
      // yellow circle
      Positioned(
        left: 90, // More to the right, behind mother's shoulder area
        bottom: 170, // Higher up
        child: Container(
          width: 100, // Slightly smaller
          height: 65,
          decoration: BoxDecoration(
            color: const Color(0xFFEDE4C6),
            borderRadius: BorderRadius.circular(31),
          ),
        ),
      ),
      // blue circle
      Positioned(
        left: 10, // Close to the mother image
        bottom: 10, // Lower but not at bottom
        child: Opacity(
          opacity: 0.24,
          child: Container(
            width: 130, // Adjusted size
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFBBCAE4),
              borderRadius: BorderRadius.circular(31),
            ),
          ),
        ),
      ),

      // green circle
      Positioned(
        left: 100, // To the right side
        bottom: 70, // Mid-height
        child: Container(
          width: 100, // Smaller size
          height: 65,
          decoration: BoxDecoration(
            color: const Color(0xFFD8DAC5),
            borderRadius: BorderRadius.circular(31),
          ),
        ),
      ),

      // pink circle
      Positioned(
        left: 10, // Between other elements
        bottom: 110, // Lower position
        child: Container(
          width: 90, // Medium size
          height: 65,
          decoration: BoxDecoration(
            color: const Color(0xFFEFD4E2),
            borderRadius: BorderRadius.circular(31),
          ),
        ),
      ),
    ];
  }

  List<Widget> buildImages(
    double Function(double) getLeft,
    double Function(double) getTop,
    double Function(double) getSize,
  ) {
    return [
      // Main image (mother.png) - Bottom flush with screen
      Positioned(
        left: -38, // Fixed position from left
        bottom: 0, // Bottom flush with screen
        child: Opacity(
          opacity: 0.9,
          child: Image.asset(
            'lib/assets/mother.png',
            width: 303, // Fixed size, doesn't scale
            height: 303,
            fit: BoxFit.cover,
          ),
        ),
      ),
      // Heart image (heartarrow.png) - Keep responsive for now
      if (isMobile)
        Positioned(
          left: getLeft(-5), 
          top: getTop(205), 
          child: Opacity(
            opacity: 0.9,
            child: Image.asset(
              'lib/assets/heartarrow.png',
              width: getSize(365),
              height: getSize(243),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ];
    }

  List<Widget> buildTextContent(
    double Function(double) getLeft,
    double Function(double) getTop,
    double Function(double) getSize,
  ) {
    return [
      // Subtitle text
      Positioned(
        left: 247,
        top: 149,
        child: SizedBox(
          width: 220,
          height: 15,
          child: Text(
            'a safe space to share, support and grow. ',
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontWeight: FontWeight.w400,
              fontSize: 11,
              color: const Color(0xFF777673),
              height: 1.35,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ),
      // Title text
      Positioned(
        left: 250,
        top: 164,
        child: SizedBox(
          width: 220,
          height: 30,
          child: Text(
            'Mamas Connect Here',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
              fontSize: 22,
              color: const Color(0xFF494949),
              height: 1.5,
            ),
            textAlign: TextAlign.left,
          ),
        ),
      ),
    ];
  }

  Widget buildDesktopLayout(
    double Function(double) getLeft,
    double Function(double) getTop,
    double Function(double) getSize,
  ) {
    // Optional: Add desktop-specific elements like navigation or additional content
    return Container();
  }

  Widget buildMobileLayout() {
    // Mobile-specific layout adjustments if needed
    return Container();
  }
}

// Alternative approach using a more flexible responsive design
class AlternativeResponsiveHomepage extends StatelessWidget {
  const AlternativeResponsiveHomepage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAE7E2),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 768;

          if (isDesktop) {
            // Desktop layout with centered content and side panels
            return Row(
              children: [
                // Left spacer
                Expanded(flex: 1, child: Container()),

                // Main content
                SizedBox(
                  width: 500, // Fixed width for the main design
                  child: buildMainContent(context, constraints),
                ),

                // Right spacer with optional additional content
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome to\nMamas Connect',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF494949),
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Join our community of mothers supporting each other through every stage of motherhood.',
                          style: TextStyle(
                            fontSize: 16,
                            color: const Color(0xFF777673),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEDE4C6),
                            foregroundColor: const Color(0xFF494949),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text('Get Started'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          } else {
            // Mobile layout (original design)
            return buildMainContent(context, constraints);
          }
        },
      ),
    );
  }

  Widget buildMainContent(BuildContext context, BoxConstraints constraints) {
    // This contains your original mobile design
    // You can use the original Stack layout here
    return Stack(
      children: [
        // Your original stack children go here...
        // (I'll keep this simplified for brevity, but you'd include all your original positioned widgets)
      ],
    );
  }
}