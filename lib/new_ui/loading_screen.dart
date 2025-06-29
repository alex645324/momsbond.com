import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

void main() { 
    runApp(const MyApp()); 
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const LoadingScreen(),
    );
  }
}

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _horizontalAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _sizeAnimation;
  late Animation<Color?> _colorAnimation;
  final _random = math.Random();
  double _startingOffset = 0.0;
  int _currentColorFamilyIndex = 0;

  // Base colors for ripple effect
  static const List<Color> baseColors = [
    Color(0xFFECDFE2), // Light pink base
    Color(0xFFEAE1C3), // Light cream base  
    Color(0xFFD5D7C2), // Light sage base
    Color(0xFFDCDDDF), // Light grey base
  ];
  
  // Full intensity colors
  static const List<Color> fullColors = [
    Color(0xFFEFD4E2), // Full pink
    Color(0xFFEDE4C6), // Full cream
    Color(0xFFD8DAC5), // Full sage
    Color(0xFFDFE0E2), // Full grey
  ];

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 6000), // Much slower, more gentle
      vsync: this,
    );

    // Horizontal movement animation - constant speed left to right
    _horizontalAnimation = Tween<double>(
      begin: -0.15, // Start further off-screen left
      end: 1.15,    // End further off-screen right
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.linear, // Constant horizontal speed
      ),
    );

    // Create gentle, space-like bounce animation with higher graceful bounces
    _bounceAnimation = TweenSequence<double>([
      // First gentle bounce - up (higher)
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.5) // Increased from 1.2
            .chain(CurveTween(curve: Curves.easeOutQuad)), // Gentler curve
        weight: 15.0,
      ),
      // First bounce - floating down
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.5, end: 0.0) // Increased from 1.2
            .chain(CurveTween(curve: Curves.easeInQuad)), // Gentle gravity
        weight: 15.0,
      ),
      
      // Second bounce (medium-high) - up
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0) // Increased from 0.8
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 13.0,
      ),
      // Second bounce - floating down
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0) // Increased from 0.8
            .chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 13.0,
      ),
      
      // Third bounce (medium) - up
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 0.7) // Increased from 0.5
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 11.0,
      ),
      // Third bounce - floating down
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.7, end: 0.0) // Increased from 0.5
            .chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 11.0,
      ),
      
      // Final soft bounce - up
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 0.4) // Increased from 0.25
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 8.0,
      ),
      // Final gentle settle
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.4, end: 0.0) // Increased from 0.25
            .chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 8.0,
      ),
      
      // Peaceful rest period
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 0.0),
        weight: 6.0,
      ),
    ]).animate(_controller);

    // Create size animation that pulses with the bounce
    _sizeAnimation = TweenSequence<double>([
      // First bounce - expand going up, contract coming down
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.6, end: 1.0) // Small to large going up
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 15.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.6) // Large to small coming down
            .chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 15.0,
      ),
      
      // Second bounce - expand and contract
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.6, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 13.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.6)
            .chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 13.0,
      ),
      
      // Third bounce - expand and contract
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.6, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 11.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.6)
            .chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 11.0,
      ),
      
      // Final bounce - expand and contract
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.6, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 8.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.6)
            .chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 8.0,
      ),
      
      // Rest period - small size
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.6, end: 0.6),
        weight: 6.0,
      ),
    ]).animate(_controller);

    // Create ripple color animation that cycles through color families
    _colorAnimation = TweenSequence<Color?>(
      _createColorSequence()
    ).animate(_controller);

    // Add listener for cycling through color families
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          // Very gentle variation to maintain peaceful feeling
          _startingOffset = (_random.nextDouble() - 0.5) * 15; // Smaller, gentler variation
          // Cycle to next color family
          _currentColorFamilyIndex = (_currentColorFamilyIndex + 1) % baseColors.length;
        });
        _controller.reset();
        _controller.forward();
      }
    });

    _controller.forward();
  }

  List<TweenSequenceItem<Color?>> _createColorSequence() {
    final currentBase = baseColors[_currentColorFamilyIndex];
    final currentFull = fullColors[_currentColorFamilyIndex];
    final nextBase = baseColors[(_currentColorFamilyIndex + 1) % baseColors.length];
    
    return [
      // First bounce: light base → full color → next light base (slower transition)
      TweenSequenceItem(
        tween: ColorTween(begin: currentBase, end: currentFull), // Going up
        weight: 20.0, // Increased from 15.0
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: currentFull, end: nextBase), // Coming down
        weight: 20.0, // Increased from 15.0
      ),
      
      // Second bounce: continue the pattern (slower transition)
      TweenSequenceItem(
        tween: ColorTween(begin: nextBase, end: fullColors[(_currentColorFamilyIndex + 1) % fullColors.length]),
        weight: 15.0, // Increased from 13.0
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: fullColors[(_currentColorFamilyIndex + 1) % fullColors.length], 
                         end: baseColors[(_currentColorFamilyIndex + 2) % baseColors.length]),
        weight: 15.0, // Increased from 13.0
      ),
      
      // Third bounce (slower transition)
      TweenSequenceItem(
        tween: ColorTween(begin: baseColors[(_currentColorFamilyIndex + 2) % baseColors.length], 
                         end: fullColors[(_currentColorFamilyIndex + 2) % fullColors.length]),
        weight: 10.0, // Slightly reduced for balance
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: fullColors[(_currentColorFamilyIndex + 2) % fullColors.length], 
                         end: baseColors[(_currentColorFamilyIndex + 3) % baseColors.length]),
        weight: 10.0, // Slightly reduced for balance
      ),
      
      // Final bounce (gentle transition)
      TweenSequenceItem(
        tween: ColorTween(begin: baseColors[(_currentColorFamilyIndex + 3) % baseColors.length], 
                         end: fullColors[(_currentColorFamilyIndex + 3) % fullColors.length]),
        weight: 4.0, // Reduced for quicker final transitions
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: fullColors[(_currentColorFamilyIndex + 3) % fullColors.length], 
                         end: currentBase),
        weight: 4.0, // Reduced for quicker final transitions
      ),
      
      // Rest period (shorter to compensate for longer transitions)
      TweenSequenceItem(
        tween: ColorTween(begin: currentBase, end: currentBase),
        weight: 2.0, // Reduced from 6.0
      ),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
            
            return Stack(
              fit: StackFit.expand,
              children: [
                // Centered text
                Positioned(
                  top: screenHeight * 0.15,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20 * scaleFactor),
                    child: Text(
                      'finding someone \nwho understands you.',
                      style: GoogleFonts.poppins(
                        fontSize: 20 * scaleFactor,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF494949),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                // Bouncing circle with ripple effect
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final baseSize = 40 * scaleFactor;
                    final currentSize = baseSize * _sizeAnimation.value;
                    
                    return Positioned(
                      left: _horizontalAnimation.value * screenWidth,
                      bottom: screenHeight * 0.35 + _startingOffset + (100 * scaleFactor * _bounceAnimation.value), // Higher bounce distance to match new heights
                      child: Container(
                        width: currentSize,
                        height: currentSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _colorAnimation.value?.withOpacity(0.75) ?? Colors.transparent, // More transparency for gentleness
                          boxShadow: [
                            BoxShadow(
                              color: (_colorAnimation.value ?? Colors.transparent).withOpacity(0.2), // Softer shadow
                              blurRadius: 12 + (_sizeAnimation.value * 8), // Shadow grows with size
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}