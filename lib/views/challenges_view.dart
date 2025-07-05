import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/challenges_viewmodel.dart';
import '../models/challenges_model.dart';
import '../config/app_config.dart';
import '../config/locale_helper.dart';

// Circle configurations for decorative background - Mobile
const mobileCircles = [
  CircleConfig(left: 20, top: 30, width: 50, height: 50, opacity: 0.3),
  CircleConfig(right: 40, top: 120, width: 57, height: 57, opacity: 0.35),
  CircleConfig(left: 35, bottom: 160, width: 70, height: 70, opacity: 0.3),
  CircleConfig(right: 25, bottom: 80, width: 90, height: 90, opacity: 0.25),
  CircleConfig(right: 60, bottom: 320, width: 40, height: 40, opacity: 0.35),
  CircleConfig(left: 45, top: 250, width: 35, height: 35, opacity: 0.3),
];

// Circle configurations for decorative background - Desktop
const desktopCircles = [
  CircleConfig(left: -60, top: -80, width: 240, height: 240, opacity: 0.12),
  CircleConfig(right: -40, top: 120, width: 180, height: 180, opacity: 0.1),
  CircleConfig(left: -20, top: 380, width: 100, height: 100, opacity: 0.15),
  CircleConfig(right: -80, top: 420, width: 160, height: 160, opacity: 0.08),
  CircleConfig(left: -100, bottom: 60, width: 200, height: 200, opacity: 0.1),
  CircleConfig(right: -120, bottom: -100, width: 280, height: 280, opacity: 0.12),
  CircleConfig(right: 60, top: 280, width: 50, height: 50, opacity: 0.2),
  CircleConfig(left: 40, bottom: 240, width: 40, height: 40, opacity: 0.18),
];

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

class ChallengesView extends StatefulWidget {
  final bool isMismatch;
  final int startingSet;

  const ChallengesView({
    Key? key,
    required this.isMismatch,
    this.startingSet = 1,
  }) : super(key: key);

  @override
  State<ChallengesView> createState() => _ChallengesViewState();
}

class _ChallengesViewState extends State<ChallengesView> {
  late final ChallengesViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    // Create a single instance and pass initial parameters once.
    _viewModel = ChallengesViewModel();
    _viewModel.initialize(widget.isMismatch, startingSet: widget.startingSet);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<ChallengesViewModel>(
        builder: (context, challengesViewModel, child) {
          // Handle error messages
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (challengesViewModel.errorMessage != null) {
              challengesViewModel.showErrorMessage(context, challengesViewModel.errorMessage!);
              challengesViewModel.clearError();
            }
          });

          return PopScope(
            canPop: true,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) {
                await _viewModel.cleanup();
              }
            },
            child: Scaffold(
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
                    challengesViewModel: challengesViewModel,
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class ResponsiveChallengesLayout extends StatelessWidget {
  final bool isDesktop;
  final bool isMobile;
  final double screenWidth;
  final double screenHeight;
  final ChallengesViewModel challengesViewModel;

  const ResponsiveChallengesLayout({
    Key? key,
    required this.isDesktop,
    required this.isMobile,
    required this.screenWidth,
    required this.screenHeight,
    required this.challengesViewModel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scaleFactor = isDesktop ? 0.8 : 1.0;
    double getResponsiveSize(double mobileSize) => mobileSize * scaleFactor;

    if (isDesktop) {
      return Stack(
        children: [
          buildMainContent(
            context,
            (left) => left,
            (top) => top,
            getResponsiveSize,
          ),
        ],
      );
    } else {
      return buildMainContent(
        context,
        (left) => left,
        (top) => top,
        getResponsiveSize,
      );
    }
  }

  List<Widget> buildBackgroundCircles(double Function(double) getSize) {
    final circles = isDesktop ? desktopCircles : mobileCircles;
    return circles.map((config) => _buildCircle(config, getSize)).toList();
  }

  Widget _buildCircle(CircleConfig config, double Function(double) getSize) {
    return Positioned(
      left: config.left != null ? getSize(config.left!) : null,
      right: config.right != null ? getSize(config.right!) : null,
      top: config.top != null ? getSize(config.top!) : null,
      bottom: config.bottom != null ? getSize(config.bottom!) : null,
      child: Container(
        width: getSize(config.width),
        height: getSize(config.height),
        decoration: BoxDecoration(
          color: const Color(0xFFD9D9D9).withValues(alpha: config.opacity),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget buildMainContent(
    BuildContext context,
    double Function(double) getLeft,
    double Function(double) getTop,
    double Function(double) getSize,
  ) {
    final horizontalPadding = isDesktop ? screenWidth * 0.08 : screenWidth * 0.04;
    final verticalPadding = isDesktop ? screenHeight * 0.08 : screenHeight * 0.04;
    final titleFontSize = isDesktop ? 32.0 : 20.0;
    final subtitleFontSize = isDesktop ? 16.0 : 11.0;
    final buttonHeight = isDesktop ? screenHeight * 0.12 : 65.0;

    return Stack(
      children: [
        // Background circles
        ...buildBackgroundCircles(getSize),
        
        SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Progress indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (challengesViewModel.currentSet == 3) ...[
                      _buildProgressDot(getSize, isActive: challengesViewModel.currentSet == 3),
                    ] else ...[
                      _buildProgressDot(getSize, isActive: challengesViewModel.isSet1),
                      SizedBox(width: getSize(12)),
                      _buildProgressDot(getSize, isActive: challengesViewModel.isSet2),
                    ],
                  ],
                ),

                SizedBox(height: getSize(20)),
                
                // Dynamic title based on current set
                Text(
                  challengesViewModel.currentSetTitle,
                  style: TextStyle(
                    fontFamily: "Poppins",
                    fontWeight: FontWeight.w500,
                    fontSize: subtitleFontSize,
                    color: const Color(0xFF777673),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: getSize(10)),

                // Main title
                Text(
                  challengesViewModel.currentSet == 3 
                      ? L.challenges(context).tryingTitle
                      : L.challenges(context).generalTitle,
                  style: const TextStyle(
                    fontFamily: "Poppins",
                    fontWeight: FontWeight.w500,
                    fontSize: 28,
                    color: Color(0xFF494949),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: isDesktop ? screenHeight * 0.1 : screenHeight * 0.06),

                // Dynamic challenge buttons based on current set
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? screenWidth * 0.15 : getSize(20)
                    ),
                    child: SingleChildScrollView(
                      child: isMobile 
                          ? buildMobileLayout(context, getSize, buttonHeight)
                          : buildDesktopLayout(context, getSize, buttonHeight),
                    ),
                  ),
                ),

                // Navigation control
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: verticalPadding * 0.5,
                      right: isDesktop ? 0 : getSize(20)
                    ),
                    child: buildNavigationControl(context, getSize),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildMobileLayout(BuildContext context, double Function(double) getSize, double buttonHeight) {
    return Column(
      children: [
        for (var i = 0; i < challengesViewModel.currentAvailableQuestions.length; i++) ...[
          Row(
            children: [
              const Spacer(),
              Expanded(
                flex: 3,
                child: Container(
                  height: buttonHeight,
                  child: buildChallengeButton(
                    context,
                    getSize,
                    challengesViewModel.currentAvailableQuestions[i],
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
          if (i < challengesViewModel.currentAvailableQuestions.length - 1)
            SizedBox(height: getSize(20)),
        ],
        SizedBox(height: getSize(40)),
      ],
    );
  }

  Widget buildDesktopLayout(BuildContext context, double Function(double) getSize, double buttonHeight) {
    final questions = challengesViewModel.currentAvailableQuestions;
    final hasThreeOptions = questions.length == 3;
    final hasFourOptions = questions.length == 4;
    final rows = hasThreeOptions ? 2 : (questions.length / 2).ceil();

    return Column(
      children: [
        // First row (always two items)
        Row(
          children: [
            Expanded(
              child: Container(
                height: buttonHeight,
                child: buildChallengeButton(
                  context,
                  getSize,
                  questions[0],
                ),
              ),
            ),
            SizedBox(width: getSize(20)),
            Expanded(
              child: Container(
                height: buttonHeight,
                child: buildChallengeButton(
                  context,
                  getSize,
                  questions[1],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: getSize(20)),
        
        // Second row
        if (hasThreeOptions)
          // Single centered item for 3 questions
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.15),
            child: Container(
              height: buttonHeight,
              child: buildChallengeButton(
                context,
                getSize,
                questions[2],
              ),
            ),
          )
        else if (hasFourOptions)
          // Two items for 4 questions
          Row(
            children: [
              Expanded(
                child: Container(
                  height: buttonHeight,
                  child: buildChallengeButton(
                    context,
                    getSize,
                    questions[2],
                  ),
                ),
              ),
              SizedBox(width: getSize(20)),
              Expanded(
                child: Container(
                  height: buttonHeight,
                  child: buildChallengeButton(
                    context,
                    getSize,
                    questions[3],
                  ),
                ),
              ),
            ],
          )
        else
          // Handle other cases (like more than 4 questions)
          for (var row = 1; row < rows; row++) ...[
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: buttonHeight,
                    child: buildChallengeButton(
                      context,
                      getSize,
                      questions[row * 2],
                    ),
                  ),
                ),
                SizedBox(width: getSize(20)),
                Expanded(
                  child: row * 2 + 1 < questions.length
                      ? Container(
                          height: buttonHeight,
                          child: buildChallengeButton(
                            context,
                            getSize,
                            questions[row * 2 + 1],
                          ),
                        )
                      : Container(), // Empty container for alignment
                ),
              ],
            ),
            if (row < rows - 1) SizedBox(height: getSize(20)),
          ],
        
        SizedBox(height: getSize(40)),
      ],
    );
  }

  Widget _buildProgressDot(double Function(double) getSize, {required bool isActive}) {
    return Container(
      width: getSize(10),
      height: getSize(10),
      decoration: BoxDecoration(
        color: isActive 
            ? const Color(0xFF494949) 
            : const Color(0xFFD9D9D9),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget buildChallengeButton(
    BuildContext context,
    double Function(double) getSize,
    ChallengeQuestion question,
  ) {
    final isSelected = challengesViewModel.isQuestionSelected(question.id);
    bool _isHovered = false;
    final buttonTextSize = isDesktop ? 16.0 : 11.0;
    final verticalPadding = isDesktop ? getSize(16) : getSize(8);
    final horizontalPadding = isDesktop ? getSize(24) : getSize(16);
    
    return StatefulBuilder(
      builder: (context, setState) => MouseRegion(
        onEnter: isDesktop ? (_) => setState(() => _isHovered = true) : null,
        onExit: isDesktop ? (_) => setState(() => _isHovered = false) : null,
        child: GestureDetector(
          onTap: challengesViewModel.isLoading ? null : () => challengesViewModel.toggleQuestion(question.id),
          child: PulseAnimationButton(
            child: AnimatedScale(
              scale: _isHovered && !challengesViewModel.isLoading ? 1.02 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: question.backgroundColor,
                  borderRadius: BorderRadius.circular(isDesktop ? getSize(45) : getSize(35)),
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
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: verticalPadding,
                    ),
                    child: Text(
                      _localizedQuestionText(context, question.id),
                      style: TextStyle(
                        fontFamily: "Satoshi",
                        fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                        fontSize: buttonTextSize,
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
            ),
          ),
        ),
      ),
    );
  }

  Widget buildNavigationControl(BuildContext context, double Function(double) getSize) {
    final buttonSize = isDesktop ? screenWidth * 0.045 : screenWidth * 0.1;
    final circleHeight = buttonSize * 0.64;
    
    return MouseRegion(
      cursor: (!challengesViewModel.isLoading && challengesViewModel.canGoForward) 
          ? SystemMouseCursors.click 
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: (!challengesViewModel.isLoading && challengesViewModel.canGoForward)
            ? () => challengesViewModel.goForward(context)
            : null,
        child: PulseAnimationButton(
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
                      child: challengesViewModel.isLoading
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
                              opacity: challengesViewModel.canGoForward ? 1.0 : 0.54,
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

  // Returns the localized text for a given question ID based on current language
  String _localizedQuestionText(BuildContext context, String questionId) {
    final lc = L.challenges(context);
    switch (questionId) {
      case 'body_changes':
        return lc.bodyChanges;
      case 'depression_anxiety':
        return lc.depressionAnxiety;
      case 'loneliness':
        return lc.loneliness;
      case 'lost_identity':
        return lc.lostIdentity;
      case 'judging_parenting':
        return lc.judgingParenting;
      case 'fear_sick':
        return lc.fearSick;
      case 'fertility_stress':
        return lc.fertilityStress;
      case 'social_pressure':
        return lc.socialPressure;
      case 'financial_worries':
        return lc.financialWorries;
      case 'relationship_changes':
        return lc.relationshipChanges;
      default:
        return questionId;
    }
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