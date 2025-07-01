import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'login_view.dart';

// Circle configuration class for decorative elements
class CircleConfig {
  final double? left;
  final double? right;
  final double? top;
  final double? bottom;
  final double size;
  final Color color;
  final double opacity;

  const CircleConfig({
    this.left,
    this.right,
    this.top,
    this.bottom,
    required this.size,
    required this.color,
    this.opacity = 0.3,
  });
}

// Circle configurations for decorative background
const decorativeCircles = [
  CircleConfig(
    left: 30,
    top: 60,
    size: 100,
    color: Color(0xFFEFD4E2), // Pink
    opacity: 0.25,
  ),
  CircleConfig(
    right: 40,
    top: 150,
    size: 80,
    color: Color(0xFFEDE4C6), // Yellow
    opacity: 0.2,
  ),
  CircleConfig(
    left: 50,
    top: 280,
    size: 60,
    color: Color(0xFFD8DAC5), // Green
    opacity: 0.25,
  ),
  CircleConfig(
    right: 20,
    bottom: 200,
    size: 90,
    color: Color(0xFFEFD4E2), // Pink
    opacity: 0.2,
  ),
  CircleConfig(
    left: 40,
    bottom: 150,
    size: 70,
    color: Color(0xFFEDE4C6), // Yellow
    opacity: 0.25,
  ),
  // Additional circles for better framing
  CircleConfig(
    right: 60,
    bottom: 300,
    size: 50,
    color: Color(0xFFD8DAC5), // Green
    opacity: 0.2,
  ),
  CircleConfig(
    left: 70,
    bottom: 250,
    size: 45,
    color: Color(0xFFEFD4E2), // Pink
    opacity: 0.15,
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
          backgroundColor: const Color(0xFFF2EDE7),
          body: SafeArea(
            child: Stack(
              children: [
                // Decorative circles
                ...decorativeCircles.map((circle) => Positioned(
                  left: circle.left,
                  right: circle.right,
                  top: circle.top,
                  bottom: circle.bottom,
                  child: Container(
                    width: circle.size,
                    height: circle.size,
                    decoration: BoxDecoration(
                      color: circle.color.withOpacity(circle.opacity),
                      shape: BoxShape.circle,
                    ),
                  ),
                )),

                // Mother image
                Positioned(
                  top: 128,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Image.asset(
                      'lib/assets/mother.png',
                      width: 300,
                      height: 300,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                // Welcome text
                Positioned(
                  top: 438,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: const Text(
                      "We're here to help you connect with \nother mothers at your stage.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: "Nuosu SIL",
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF574F4E),
                      ),
                    ),
                  ),
                ),

                // Get Started Button (Replaced Google Sign-in)
                Positioned(
                  bottom: 60,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: (viewModel.isLoading || _isNavigating) ? null : _navigateToLogin,
                      child: Container(
                        width: 240,
                        height: 50,
                        decoration: BoxDecoration(
                          color: (viewModel.isLoading || _isNavigating) 
                              ? const Color(0xFF574F4E).withOpacity(0.6)
                              : const Color(0xFF574F4E),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 0.25),
                              offset: Offset(0, 4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Center(
                          child: (viewModel.isLoading || _isNavigating)
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  "Get Started",
                                  style: TextStyle(
                                    fontFamily: "Nuosu SIL",
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),

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
} 