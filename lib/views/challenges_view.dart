import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/challenges_viewmodel.dart';
import '../models/challenges_model.dart';

// Circle configurations for decorative background
const circle1 = CircleConfig(left: -26, top: -27, width: 66, height: 66);
const circle2 = CircleConfig(right: 34, top: 161, width: 38, height: 38);
const circle3 = CircleConfig(right: 15, top: 241, width: 13, height: 13);
const circle4 = CircleConfig(right: 9, top: 363, width: 26, height: 26);
const circle5 = CircleConfig(left: 147, top: 440, width: 12, height: 12);
const circle6 = CircleConfig(left: -26, top: 518, width: 83, height: 85);
const circle7 = CircleConfig(right: 80, top: 50, width: 15, height: 15, opacity: 0.3);
const circle8 = CircleConfig(left: 60, top: 200, width: 20, height: 20, opacity: 0.25);
const circle9 = CircleConfig(right: -10, bottom: 200, width: 45, height: 45, opacity: 0.3);
const circle10 = CircleConfig(left: 30, bottom: 150, width: 18, height: 18, opacity: 0.35);

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
  late ChallengesViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel = Provider.of<ChallengesViewModel>(context, listen: false);
      _viewModel.initialize(widget.isMismatch, startingSet: widget.startingSet);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChallengesViewModel(),
      child: Consumer<ChallengesViewModel>(
        builder: (context, challengesViewModel, child) {
          // Initialize viewModel reference
          _viewModel = challengesViewModel;
          
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
                await challengesViewModel.cleanup();
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
      return Center(
        child: Container(
          width: 400,
          child: buildMainContent(
            context,
            (left) => left,
            (top) => top,
            getResponsiveSize,
          ),
        ),
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
    return [
      for (var circle in [circle1, circle2, circle3, circle4, circle5, circle6, circle7, circle8, circle9, circle10])
        _buildCircle(circle, getSize),
    ];
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
    return Stack(
      children: [
        // Background circles
        ...buildBackgroundCircles(getSize),
        
        SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: getSize(32)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: getSize(80)),
                
                // Progress indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildProgressDot(getSize, isActive: challengesViewModel.isSet1),
                    SizedBox(width: getSize(12)),
                    _buildProgressDot(getSize, isActive: challengesViewModel.isSet2),
                  ],
                ),

                SizedBox(height: getSize(20)),
                
                // Dynamic title based on current set
                Text(
                  challengesViewModel.currentSetTitle,
                  style: TextStyle(
                    fontFamily: "Poppins",
                    fontWeight: FontWeight.w600,
                    fontSize: getSize(16),
                    color: const Color(0xFF777673),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: getSize(10)),

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

                // Dynamic challenge buttons based on current set
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: getSize(20)),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          for (var i = 0; i < challengesViewModel.currentAvailableQuestions.length; i++) ...[
                            Align(
                              alignment: challengesViewModel.currentAvailableQuestions[i].alignment,
                              child: buildChallengeButton(
                                getSize,
                                challengesViewModel.currentAvailableQuestions[i],
                              ),
                            ),
                            if (i < challengesViewModel.currentAvailableQuestions.length - 1)
                              SizedBox(height: getSize(20)),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                // Navigation control
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: getSize(60), right: getSize(20)),
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
    double Function(double) getSize,
    ChallengeQuestion question,
  ) {
    final isSelected = challengesViewModel.isQuestionSelected(question.id);
    
    return GestureDetector(
      onTap: challengesViewModel.isLoading ? null : () => challengesViewModel.toggleQuestion(question.id),
      child: Container(
        width: getSize(question.width),
        height: getSize(question.height),
        decoration: BoxDecoration(
          color: question.backgroundColor,
          borderRadius: BorderRadius.circular(getSize(35)),
          border: isSelected 
              ? Border.all(color: const Color(0xFF494949), width: 2)
              : Border.all(color: Colors.transparent, width: 2),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF494949).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              question.text,
              style: TextStyle(
                fontFamily: "Satoshi",
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                fontSize: getSize(12),
                color: isSelected 
                    ? const Color(0xFF494949)
                    : const Color(0xFF494949).withValues(alpha: 0.8),
                height: 1.35,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildNavigationControl(BuildContext context, double Function(double) getSize) {
    return Container(
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
              onTap: challengesViewModel.isLoading ? null : () => challengesViewModel.goBack(context),
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
                      opacity: challengesViewModel.canGoBack || !challengesViewModel.isSet1 ? 1.0 : 0.54,
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
                color: const Color(0xFF919091).withValues(alpha: 0.38),
                borderRadius: BorderRadius.circular(getSize(20)),
              ),
            ),
          ),

          // Forward arrow background (dynamic)
          if (challengesViewModel.canGoForward && !challengesViewModel.isLoading)
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
              onTap: challengesViewModel.canGoForward && !challengesViewModel.isLoading 
                  ? () => challengesViewModel.goForward(context)
                  : null,
              child: Container(
                width: getSize(66),
                height: getSize(66),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(getSize(33)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(getSize(33)),
                  child: challengesViewModel.isLoading
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        )
                      : Opacity(
                          opacity: challengesViewModel.canGoForward ? 1.0 : 0.54,
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
    );
  }
} 