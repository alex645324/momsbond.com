import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/stage_viewmodel.dart';
import '../models/stage_model.dart';

// Circle configuration class for decorative elements
class CircleConfig {
  final double? left;
  final double? right;
  final double? top;
  final double? bottom;
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

// Circle configurations for decorative background - Mobile
const mobileCircles = [
  CircleConfig(
    left: 20,
    top: 30,
    width: 50,
    height: 50,
    opacity: 0.3,
  ),
  CircleConfig(
    right: 40,
    top: 120,
    width: 57,
    height: 57,
    opacity: 0.35,
  ),
  CircleConfig(
    left: 35,
    bottom: 160,
    width: 70,
    height: 70,
    opacity: 0.3,
  ),
  CircleConfig(
    right: 25,
    bottom: 80,
    width: 90,
    height: 90,
    opacity: 0.25,
  ),
  CircleConfig(
    right: 60,
    bottom: 320,
    width: 40,
    height: 40,
    opacity: 0.35,
  ),
  CircleConfig(
    left: 45,
    top: 250,
    width: 35,
    height: 35,
    opacity: 0.3,
  ),
];

// Circle configurations for decorative background - Desktop
const desktopCircles = [
  // Top-left large circle - moved further left and up
  CircleConfig(
    left: -60,
    top: -80,
    width: 240,
    height: 240,
    opacity: 0.12,
  ),
  // Top-right medium circle - moved further right
  CircleConfig(
    right: -40,
    top: 120,
    width: 180,
    height: 180,
    opacity: 0.1,
  ),
  // Middle-left small circle - moved further left
  CircleConfig(
    left: -20,
    top: 380,
    width: 100,
    height: 100,
    opacity: 0.15,
  ),
  // Middle-right medium circle - moved further right
  CircleConfig(
    right: -80,
    top: 420,
    width: 160,
    height: 160,
    opacity: 0.08,
  ),
  // Bottom-left medium circle - moved further left and down
  CircleConfig(
    left: -100,
    bottom: 60,
    width: 200,
    height: 200,
    opacity: 0.1,
  ),
  // Bottom-right large circle - moved further right and down
  CircleConfig(
    right: -120,
    bottom: -100,
    width: 280,
    height: 280,
    opacity: 0.12,
  ),
  // Far right accent circle
  CircleConfig(
    right: 60,
    top: 280,
    width: 50,
    height: 50,
    opacity: 0.2,
  ),
  // Far left accent circle
  CircleConfig(
    left: 40,
    bottom: 240,
    width: 40,
    height: 40,
    opacity: 0.18,
  ),
];

class ShakeAnimationButton extends StatefulWidget {
  final VoidCallback? onTap;
  final bool isEnabled;
  final bool isDesktop;
  final Widget child;

  const ShakeAnimationButton({
    Key? key,
    required this.onTap,
    required this.isEnabled,
    required this.isDesktop,
    required this.child,
  }) : super(key: key);

  @override
  State<ShakeAnimationButton> createState() => _ShakeAnimationButtonState();
}

class _ShakeAnimationButtonState extends State<ShakeAnimationButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shakeAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -5.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -5.0, end: 5.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 5.0, end: -3.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -3.0, end: 0.0), weight: 25),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _triggerShake() {
    if (!widget.isEnabled && !_controller.isAnimating) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: widget.isDesktop ? (_) => setState(() => _isHovered = true) : null,
      onExit: widget.isDesktop ? (_) => setState(() => _isHovered = false) : null,
      child: GestureDetector(
        onTap: () {
          if (widget.isEnabled) {
            widget.onTap?.call();
          } else {
            _triggerShake();
          }
        },
        child: AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_shakeAnimation.value, 0),
              child: AnimatedScale(
                scale: _isHovered && widget.isEnabled ? 1.05 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: widget.child,
              ),
            );
          },
        ),
      ),
    );
  }
}

class PulseAnimationButton extends StatefulWidget {
  final Widget child;

  const PulseAnimationButton({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<PulseAnimationButton> createState() => _PulseAnimationButtonState();
}

class _PulseAnimationButtonState extends State<PulseAnimationButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  bool _hasPlayed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.03), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.03, end: 0.98), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.98, end: 1.01), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.01, end: 1.0), weight: 20),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutSine,
    ));

    // Delay the animation start slightly
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && !_hasPlayed) {
        _controller.forward().then((_) {
          _hasPlayed = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: widget.child,
        );
      },
    );
  }
}

class StageSelectionView extends StatelessWidget {
  const StageSelectionView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StageViewModel(),
      child: Consumer<StageViewModel>(
        builder: (context, stageViewModel, child) {
          // Handle error messages
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (stageViewModel.errorMessage != null) {
              stageViewModel.showErrorMessage(context, stageViewModel.errorMessage!);
              stageViewModel.clearError();
            }
          });

          return Scaffold(
            backgroundColor: const Color(0xFFEAE7E2),
            body: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 1024;
                final isTablet = constraints.maxWidth > 768 && constraints.maxWidth <= 1024;
                final isMobile = constraints.maxWidth <= 768;

                return ResponsiveStageSelection(
                  isDesktop: isDesktop,
                  isTablet: isTablet,
                  isMobile: isMobile,
                  screenWidth: constraints.maxWidth,
                  screenHeight: constraints.maxHeight,
                  stageViewModel: stageViewModel,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class ResponsiveStageSelection extends StatelessWidget {
  final bool isDesktop;
  final bool isTablet;
  final bool isMobile;
  final double screenWidth;
  final double screenHeight;
  final StageViewModel stageViewModel;

  const ResponsiveStageSelection({
    Key? key,
    required this.isDesktop,
    required this.isTablet,
    required this.isMobile,
    required this.screenWidth,
    required this.screenHeight,
    required this.stageViewModel,
  }) : super(key: key);

  double get horizontalPadding {
    if (isDesktop) return screenWidth * 0.08; // 8% of screen width
    if (isTablet) return screenWidth * 0.06; // 6% of screen width
    return screenWidth * 0.04; // 4% of screen width
  }

  double get verticalPadding {
    if (isDesktop) return screenHeight * 0.08; // 8% of screen height
    if (isTablet) return screenHeight * 0.06; // 6% of screen height
    return screenHeight * 0.04; // 4% of screen height
  }

  double get titleFontSize {
    if (isDesktop) return 32;
    if (isTablet) return 24;
    return 20;
  }

  double get subtitleFontSize {
    if (isDesktop) return 16;
    if (isTablet) return 14;
    return 11;
  }

  double get buttonHeight {
    if (isDesktop) return screenHeight * 0.09; // ~9% of screen height for desktop
    if (isTablet) return screenHeight * 0.1; // 10% of screen height for tablet
    return 65; // Keep mobile size fixed
  }

  double get buttonSpacing {
    if (isDesktop) return screenHeight * 0.04; // 4% of screen height
    if (isTablet) return screenHeight * 0.03; // 3% of screen height
    return screenHeight * 0.02; // 2% of screen height
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background circles
        ...buildBackgroundCircles(!isMobile),
        
        // Main content
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Main title
              Text(
                'what stage are you in?',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                  fontSize: titleFontSize,
                  color: const Color(0xFF494949),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              // Spacing between title and subtitle
              SizedBox(height: screenHeight * 0.02),

              // Subtitle
              Text(
                'this helps us match you with the best fit :)',
                style: TextStyle(
                  fontFamily: 'Satoshi',
                  fontWeight: FontWeight.w400,
                  fontSize: subtitleFontSize,
                  color: const Color(0xFF777673),
                  height: 1.35,
                ),
                textAlign: TextAlign.center,
              ),

              // Spacing before buttons - adjusted for desktop
              SizedBox(height: isDesktop ? screenHeight * 0.15 : screenHeight * 0.08),

              // Stage buttons
              if (isMobile)
                // Mobile layout - stacked buttons
                buildMobileButtons()
              else
                // Desktop/Tablet layout - 2x2 grid
                buildDesktopButtons(),
            ],
          ),
        ),

        // Continue button
        buildContinueButton(),
      ],
    );
  }

  List<Widget> buildBackgroundCircles(bool isDesktop) {
    final circles = isDesktop ? desktopCircles : mobileCircles;
    return circles.map((config) => _buildCircle(config, isDesktop)).toList();
  }

  Widget _buildCircle(CircleConfig config, bool isDesktop) {
    return Positioned(
      left: config.left,
      right: config.right,
      top: config.top,
      bottom: config.bottom,
      child: Container(
        width: config.width,
        height: config.height,
        decoration: BoxDecoration(
          color: const Color(0xFFD9D9D9).withOpacity(config.opacity),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget buildMobileButtons() {
    return Column(
      children: [
        Row(
          children: [
            const Spacer(),
            Expanded(
              flex: 3,
              child: buildStageButton(
                'pregnant',
                'pregnant?',
                const Color(0xFFEFD4E2),
                null,
              ),
            ),
            const Spacer(),
          ],
        ),
        SizedBox(height: buttonSpacing),
        Row(
          children: [
            const Spacer(),
            Expanded(
              flex: 3,
              child: buildStageButton(
                'toddler',
                'toddler mom?',
                const Color(0xFFEDE4C6),
                null,
              ),
            ),
            const Spacer(),
          ],
        ),
        SizedBox(height: buttonSpacing),
        Row(
          children: [
            const Spacer(),
            Expanded(
              flex: 3,
              child: buildStageButton(
                'teen',
                'teen mom?',
                const Color(0xFFD8DAC5),
                null,
              ),
            ),
            const Spacer(),
          ],
        ),
        SizedBox(height: buttonSpacing),
        Row(
          children: [
            const Spacer(),
            Expanded(
              flex: 3,
              child: buildStageButton(
                'adult',
                'adult mom?',
                const Color(0xFFBBCAE4).withOpacity(0.30),
                null,
              ),
            ),
            const Spacer(),
          ],
        ),
      ],
    );
  }

  Widget buildDesktopButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.15, // Increase horizontal padding to make buttons smaller
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // First row
          Row(
            children: [
              Expanded(
                child: buildStageButton(
                  'pregnant',
                  'pregnant?',
                  const Color(0xFFEFD4E2),
                  null,
                ),
              ),
              SizedBox(width: buttonSpacing),
              Expanded(
                child: buildStageButton(
                  'toddler',
                  'toddler mom?',
                  const Color(0xFFEDE4C6),
                  null,
                ),
              ),
            ],
          ),
          SizedBox(height: buttonSpacing),
          // Second row
          Row(
            children: [
              Expanded(
                child: buildStageButton(
                  'teen',
                  'teen mom?',
                  const Color(0xFFD8DAC5),
                  null,
                ),
              ),
              SizedBox(width: buttonSpacing),
              Expanded(
                child: buildStageButton(
                  'adult',
                  'adult mom?',
                  const Color(0xFFBBCAE4).withOpacity(0.30),
                  null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildStageButton(
    String value,
    String text,
    Color backgroundColor,
    double? width,
  ) {
    final dbValue = StageModel.getDatabaseValue(value);
    final isSelected = stageViewModel.isStageSelected(dbValue);
    
    return ShakeAnimationButton(
      onTap: () => stageViewModel.toggleStage(value),
      isEnabled: !stageViewModel.isLoading,
      isDesktop: !isMobile,
      child: PulseAnimationButton(
        child: Container(
          width: width,
          height: buttonHeight,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(buttonHeight / 2),
            border: isSelected 
                ? Border.all(color: const Color(0xFF494949), width: 2)
                : Border.all(color: Colors.transparent, width: 2),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF494949).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Satoshi',
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                fontSize: isDesktop ? 16 : (isTablet ? 14 : 11),
                color: isSelected 
                    ? const Color(0xFF494949)
                    : const Color(0xFF494949).withOpacity(0.8),
                height: 1.35,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildContinueButton() {
    final buttonSize = isDesktop ? screenWidth * 0.045 : (isTablet ? screenWidth * 0.06 : screenWidth * 0.1);
    final circleHeight = buttonSize * 0.64;
    
    return Builder(
      builder: (context) => Positioned(
        right: horizontalPadding,
        bottom: verticalPadding,
        child: ShakeAnimationButton(
          onTap: () => stageViewModel.submitStages(context),
          isEnabled: stageViewModel.hasSelection && !stageViewModel.isLoading,
          isDesktop: !isMobile,
          child: Container(
            width: buttonSize,
            height: buttonSize,
            child: Stack(
              children: [
                // Background circle
                Positioned(
                  top: buttonSize * 0.16,
                  child: Container(
                    width: buttonSize,
                    height: circleHeight,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9D9D9),
                      borderRadius: BorderRadius.circular(buttonSize / 2),
                    ),
                  ),
                ),
                // Arrow or loading indicator
                Positioned(
                  left: buttonSize * 0.03,
                  top: 0,
                  child: Container(
                    width: buttonSize * 0.96,
                    height: buttonSize,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(buttonSize / 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(buttonSize / 2),
                      child: stageViewModel.isLoading
                          ? Center(
                              child: SizedBox(
                                width: buttonSize * 0.3,
                                height: buttonSize * 0.3,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                            )
                          : Opacity(
                              opacity: stageViewModel.hasSelection ? 1.0 : 0.54,
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
    );
  }
} 