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

// Circle configurations for decorative background
const circle1 = CircleConfig(left: -15, top: -10, width: 50, height: 50);
const circle2 = CircleConfig(right: 30, top: 145, width: 57, height: 57);
const circle3 = CircleConfig(left: -25, bottom: 140, width: 70, height: 70);
const circle4 = CircleConfig(right: -50, bottom: 10, width: 100, height: 100);
const circle5 = CircleConfig(right: 90, bottom: 390, width: 30, height: 30);
const circle6 = CircleConfig(left: 30, top: 290, width: 25, height: 25);

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
                final isDesktop = constraints.maxWidth > 768;
                final isMobile = constraints.maxWidth <= 768;

                return ResponsiveStageSelection(
                  isDesktop: isDesktop,
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
  final bool isMobile;
  final double screenWidth;
  final double screenHeight;
  final StageViewModel stageViewModel;

  const ResponsiveStageSelection({
    Key? key,
    required this.isDesktop,
    required this.isMobile,
    required this.screenWidth,
    required this.screenHeight,
    required this.stageViewModel,
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
      _buildCircle(circle1, getSize),
      _buildCircle(circle2, getSize),
      _buildCircle(circle3, getSize),
      _buildCircle(circle4, getSize),
      _buildCircle(circle5, getSize),
      _buildCircle(circle6, getSize),
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
        
        // Main content
        SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: getSize(32)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top spacing
                SizedBox(height: getSize(100)),
                
                // Main title
                Text(
                  'what stage are you in?',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    fontSize: getSize(20),
                    color: const Color(0xFF494949),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                // Spacing between title and subtitle
                SizedBox(height: getSize(8)),

                // Subtitle
                Text(
                  'this helps us match you with the best fit :)',
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontWeight: FontWeight.w400,
                    fontSize: getSize(11),
                    color: const Color(0xFF777673),
                    height: 1.35,
                  ),
                  textAlign: TextAlign.center,
                ),

                // Spacing before buttons
                SizedBox(height: getSize(80)),

                // Stage buttons with multi-selection support
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: getSize(20)),
                  child: Column(
                    children: [
                      // Row 1: Pink button (right aligned) - pregnant?
                      Row(
                        children: [
                          const Spacer(),
                          buildStageButton(
                            getSize,
                            'pregnant',
                            'pregnant?',
                            const Color(0xFFEFD4E2),
                            320,
                            65,
                          ),
                        ],
                      ),

                      SizedBox(height: getSize(18)),

                      // Row 2: Yellow button (left aligned) - toddler mom?
                      Row(
                        children: [
                          buildStageButton(
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

                      SizedBox(height: getSize(18)),

                      // Row 3: Green button (right aligned) - teen mom?
                      Row(
                        children: [
                          const Spacer(),
                          buildStageButton(
                            getSize,
                            'teen',
                            'teen mom?',
                            const Color(0xFFD8DAC5),
                            250,
                            65,
                          ),
                        ],
                      ),

                      SizedBox(height: getSize(18)),

                      // Row 4: Blue button (left aligned) - adult mom?
                      Row(
                        children: [
                          buildStageButton(
                            getSize,
                            'adult',
                            'adult mom?',
                            const Color(0xFFBBCAE4).withValues(alpha: 0.30),
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

                // Continue button - right aligned
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: getSize(60), right: getSize(20)),
                    child: GestureDetector(
                      onTap: stageViewModel.hasSelection && !stageViewModel.isLoading 
                          ? () => stageViewModel.submitStages(context)
                          : null,
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
                                  color: stageViewModel.hasSelection && !stageViewModel.isLoading
                                      ? const Color(0xFF494949) 
                                      : const Color(0xFFD9D9D9),
                                  borderRadius: BorderRadius.circular(getSize(29)),
                                ),
                              ),
                            ),
                            // Arrow or loading indicator
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
                                  child: stageViewModel.isLoading
                                      ? const Center(
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
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
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildStageButton(
    double Function(double) getSize,
    String value,
    String text,
    Color backgroundColor,
    double width,
    double height,
  ) {
    // Check if this stage is selected using the database value
    final dbValue = StageModel.getDatabaseValue(value);
    final isSelected = stageViewModel.isStageSelected(dbValue);
    
    return GestureDetector(
      onTap: stageViewModel.isLoading ? null : () => stageViewModel.toggleStage(value),
      child: Container(
        width: getSize(width),
        height: getSize(height),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(getSize(31)),
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
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
              fontSize: getSize(11),
              color: isSelected 
                  ? const Color(0xFF494949)
                  : const Color(0xFF494949).withValues(alpha: 0.8),
              height: 1.35,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
} 