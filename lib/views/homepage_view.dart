import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'login_view.dart';
import '../config/app_config.dart';
import '../viewmodels/language_viewmodel.dart';
import '../config/locale_helper.dart';

// Configuration for positioned images in the photo mosaic
class ImageConfig {
  final String assetPath;
  final double left;
  final double top;
  final double width;
  final double height;

  const ImageConfig({
    required this.assetPath,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });
}

// Values taken from the Figma art-board (frame 11:2)
const List<ImageConfig> mosaicImages = [
  ImageConfig(
    assetPath: 'lib/assets/image6.png',
    left: 220,
    top: 179,
    width: 140.17,
    height: 177,
  ),
  ImageConfig(
    assetPath: 'lib/assets/image8.png',
    left: 233,
    top: 10,
    width: 150,
    height: 158,
  ),
  ImageConfig(
    assetPath: 'lib/assets/image7.png',
    left: 8,
    top: 10,
    width: 217.87,
    height: 172,
  ),
  ImageConfig(
    assetPath: 'lib/assets/image5.png',
    left: 200,
    top: 551,
    width: 183.17,
    height: 283,
  ),
  ImageConfig(
    assetPath: 'lib/assets/image4.png',
    left: 8,
    top: 564,
    width: 163,
    height: 233,
  ),
  ImageConfig(
    assetPath: 'lib/assets/image3.png',
    left: 23,
    top: 186,
    width: 183.86,
    height: 231,
  ),
  ImageConfig(
    assetPath: 'lib/assets/image2.png',
    left: 8,
    top: 426,
    width: 198.62,
    height: 129,
  ),
  ImageConfig(
    assetPath: 'lib/assets/image1.png',
    left: 220,
    top: 363,
    width: 158.14,
    height: 184,
  ),
];

class HomepageView extends StatefulWidget {
  const HomepageView({super.key});

  @override
  State<HomepageView> createState() => _HomepageViewState();
}

class _HomepageViewState extends State<HomepageView> {
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    // Initialize auth system when homepage loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthViewModel>().initialize();
    });
  }

  void _navigateToLogin() {
    // Prevent multiple rapid taps or navigation during auth initialization
    if (_isNavigating) return;
    
    // Check if auth is still initializing
    final authViewModel = context.read<AuthViewModel>();
    if (authViewModel.isLoading) {
      print("Homepage: Auth still initializing, waiting...");
      return;
    }
    
    setState(() {
      _isNavigating = true;
    });

    print("Homepage: Navigating to Login view");
    
    // Add small delay to ensure Navigator is ready
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginView()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          // Updated to match project's consistent background color
          backgroundColor: const Color(0xFFEAE7E2),
          body: SafeArea(
            child: Stack(
              children: [
                // Calculate offsets to center the Figma-sized collage (393×878) in the
                // current screen. Negative offsets collapse to zero to avoid spilling.
                ...(() {
                  const designWidth = 393.0;
                  const designHeight = 878.0;
                  final size = MediaQuery.of(context).size;
                  final dx = ((size.width - designWidth) / 2).clamp(0.0, double.infinity);
                  final dy = ((size.height - designHeight) / 2).clamp(0.0, double.infinity);

                  // Build mosaic images
                  final imageWidgets = mosaicImages.map((img) => Positioned(
                        left: img.left + dx,
                        top: img.top + dy,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            img.assetPath,
                            width: img.width,
                            height: img.height,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ));

                  // Build description card with internal content
                  final cardWidget = Positioned(
                    left: 71 + dx,
                    top: 519 + dy,
                    child: Container(
                      width: 260,
                      height: 250,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2EDE7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.black,
                          width: 1,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(0, 0, 0, 0.25),
                            offset: Offset(0, 4),
                            blurRadius: 23.9,
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Main description text positioned exactly as in Figma
                          Positioned(
                            left: 23,
                            top: 25, //32
                            child: SizedBox(
                              width: 214.83,
                              height: 85.03,
                              child: Text(
                                L.homepage(context).mainDescription,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ),
                          // Language buttons positioned exactly as in Figma
                          Positioned(
                            left: 50,
                            top: 103,
                            child: SizedBox(
                              width: 158.64,
                              height: 102.93,
                              child: Column(
                                children: [
                                  _buildLanguageButton(context, viewModel, 'en', AppTexts.language.english),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );

                  // Build Group 39 asset positioned as in Figma
                  final group39Widget = Positioned(
                    left: 67.28 + dx,
                    top: 177.91 + dy,
                    child: Image.asset(
                      'lib/assets/Group 39.png',
                      width: 272.55,
                      height: 364.11,
                      fit: BoxFit.cover,
                    ),
                  );

                  // Build overlay with 33% opacity
                  final overlayWidget = Positioned.fill(
                    child: Container(
                      color: const Color(0xFFEAE7E2).withOpacity(0.60),
                    ),
                  );

                  return [
                    ...imageWidgets,
                    overlayWidget,
                    cardWidget,
                    group39Widget,
                    // Note: language buttons now inside the card.
                  ];
                })(),

                // Error message display
                if (viewModel.errorMessage != null)
                  Positioned(
                    bottom: 120,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE6E6),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFFF9999),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Color(0xFFCC0000),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              viewModel.errorMessage!,
                              style: const TextStyle(
                                fontFamily: "Nuosu SIL",
                                fontSize: 12,
                                color: Color(0xFFCC0000),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: viewModel.clearError,
                            child: const Icon(
                              Icons.close,
                              color: Color(0xFFCC0000),
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper widget to create language buttons
  Widget _buildLanguageButton(BuildContext context, AuthViewModel authViewModel, String langCode, String label) {
    final isDisabled = authViewModel.isLoading || _isNavigating;
    final heart = langCode == 'en' ? '❤️' : '💙';

    return GestureDetector(
      onTap: isDisabled
          ? null
          : () {
              context.read<LanguageViewModel>().setLanguage(langCode);
              _navigateToLogin();
            },
      child: Container(
        width: 158.64,
        height: 43.93,
        decoration: BoxDecoration(
          color: isDisabled ? const Color(0xFFD9D9D9).withOpacity(0.6) : const Color(0xFFD9D9D9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.black,
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.25),
              offset: Offset(3, 4),
              blurRadius: 4,
            ),
          ],
        ),
        child: Center(
          child: isDisabled
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                )
              : Text(
                  '$label $heart',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    color: Colors.black,
                    height: 1.5,
                  ),
                ),
        ),
      ),
    );
  }
} 