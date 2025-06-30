import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../viewmodels/loading_viewmodel.dart';

class LoadingView extends StatefulWidget {
  const LoadingView({Key? key}) : super(key: key);

  @override
  _LoadingViewState createState() => _LoadingViewState();
}

class _LoadingViewState extends State<LoadingView> with SingleTickerProviderStateMixin {
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
    _initializeAnimations();
    
    // Initialize the matching process
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LoadingViewModel>(context, listen: false).initialize();
    });
  }

  void _initializeAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 6000),
      vsync: this,
    );

    // Horizontal movement animation - constant speed left to right
    _horizontalAnimation = Tween<double>(
      begin: -0.15,
      end: 1.15,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.linear,
      ),
    );

    // Create gentle, space-like bounce animation
    _bounceAnimation = TweenSequence<double>([
      // First gentle bounce - up
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.5)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 15.0,
      ),
      // First bounce - floating down
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.5, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 15.0,
      ),
      
      // Second bounce - up
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 13.0,
      ),
      // Second bounce - floating down
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 13.0,
      ),
      
      // Third bounce - up
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 0.7)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 11.0,
      ),
      // Third bounce - floating down
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.7, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 11.0,
      ),
      
      // Final soft bounce - up
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 0.4)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 8.0,
      ),
      // Final gentle settle
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.4, end: 0.0)
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
        tween: Tween<double>(begin: 0.6, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 15.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.6)
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
          _startingOffset = (_random.nextDouble() - 0.5) * 15;
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
      // First bounce: light base → full color → next light base
      TweenSequenceItem(
        tween: ColorTween(begin: currentBase, end: currentFull),
        weight: 20.0,
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: currentFull, end: nextBase),
        weight: 20.0,
      ),
      
      // Second bounce: continue the pattern
      TweenSequenceItem(
        tween: ColorTween(begin: nextBase, end: fullColors[(_currentColorFamilyIndex + 1) % fullColors.length]),
        weight: 15.0,
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: fullColors[(_currentColorFamilyIndex + 1) % fullColors.length], 
                         end: baseColors[(_currentColorFamilyIndex + 2) % baseColors.length]),
        weight: 15.0,
      ),
      
      // Third bounce
      TweenSequenceItem(
        tween: ColorTween(begin: baseColors[(_currentColorFamilyIndex + 2) % baseColors.length], 
                         end: fullColors[(_currentColorFamilyIndex + 2) % fullColors.length]),
        weight: 10.0,
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: fullColors[(_currentColorFamilyIndex + 2) % fullColors.length], 
                         end: baseColors[(_currentColorFamilyIndex + 3) % baseColors.length]),
        weight: 10.0,
      ),
      
      // Final bounce
      TweenSequenceItem(
        tween: ColorTween(begin: baseColors[(_currentColorFamilyIndex + 3) % baseColors.length], 
                         end: fullColors[(_currentColorFamilyIndex + 3) % fullColors.length]),
        weight: 4.0,
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: fullColors[(_currentColorFamilyIndex + 3) % fullColors.length], 
                         end: currentBase),
        weight: 4.0,
      ),
      
      // Rest period
      TweenSequenceItem(
        tween: ColorTween(begin: currentBase, end: currentBase),
        weight: 2.0,
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
        child: Consumer<LoadingViewModel>(
          builder: (context, viewModel, child) {
            // Handle navigation when match is found
            if (viewModel.loadingModel.shouldNavigateToChat) {
              print("DEBUG: LoadingView detected shouldNavigateToChat = true");
              print("DEBUG: About to automatically navigate to chat");
              WidgetsBinding.instance.addPostFrameCallback((_) {
                print("DEBUG: Calling viewModel.navigateToChat()");
                viewModel.navigateToChat(context);
              });
            }

            // Handle error display
            if (viewModel.hasError) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                viewModel.showErrorMessage(context, viewModel.errorMessage!);
                viewModel.clearError();
              });
            }

            return LayoutBuilder(
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
                          viewModel.loadingText,
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

                    // Status indicator (optional - shows when waiting)
                    if (viewModel.isWaiting)
                      Positioned(
                        top: screenHeight * 0.25,
                        left: 0,
                        right: 0,
                        child: Text(
                          "waiting for match...",
                          style: GoogleFonts.poppins(
                            fontSize: 14 * scaleFactor,
                            fontWeight: FontWeight.w300,
                            color: const Color(0xFF494949).withOpacity(0.7),
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
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
                          bottom: screenHeight * 0.35 + _startingOffset + (100 * scaleFactor * _bounceAnimation.value),
                          child: Container(
                            width: currentSize,
                            height: currentSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _colorAnimation.value?.withValues(alpha: 0.75) ?? Colors.transparent,
                              boxShadow: [
                                BoxShadow(
                                  color: (_colorAnimation.value ?? Colors.transparent).withValues(alpha: 0.2),
                                  blurRadius: 12 + (_sizeAnimation.value * 8),
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
            );
          },
        ),
      ),
    );
  }
} 