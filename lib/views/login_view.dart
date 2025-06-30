import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Database_logic/simple_auth_manager.dart';
import 'challenges_view.dart';
import 'stage_selection_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final SimpleAuthManager _authManager = SimpleAuthManager();
  
  // Form controllers
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // State management
  bool _isSignUp = true; // Start with sign up mode
  bool _rememberMe = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadRememberedUsername();
  }

  Future<void> _loadRememberedUsername() async {
    // Check for remembered username
    final rememberedUsername = await _authManager.getRememberedUsername();
    if (rememberedUsername != null && mounted) {
      setState(() {
        _usernameController.text = rememberedUsername;
        _rememberMe = true;
        _isSignUp = false; // Switch to sign in if user is remembered
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_usernameController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = "Please fill in all fields";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isSignUp) {
        final result = await _authManager.signUp(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
          rememberMe: _rememberMe,
        );
        
        if (result.success) {
          _onAuthComplete(true, _usernameController.text.trim());
        } else {
          setState(() {
            _errorMessage = result.message;
          });
        }
      } else {
        final result = await _authManager.signIn(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
          rememberMe: _rememberMe,
        );
        
        if (result.success) {
          _onAuthComplete(true, _usernameController.text.trim());
        } else {
          setState(() {
            _errorMessage = result.message;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = "An error occurred. Please try again.";
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _onAuthComplete(bool success, String? username) async {
    if (success && username != null && mounted) {
      // Check if user has completed mother stage to determine navigation
      final userData = await _authManager.getUserData();
      
      // Check if user has a valid momStage (not null and not empty)
      bool hasMomStage = false;
      if (userData != null && userData.containsKey('momStage')) {
        final momStageValue = userData['momStage'];
        if (momStageValue != null) {
          if (momStageValue is List && momStageValue.isNotEmpty) {
            hasMomStage = true;
          } else if (momStageValue is String && momStageValue.isNotEmpty) {
            hasMomStage = true;
          }
        }
      }
      
      if (hasMomStage) {
        // Returning user who has completed mother stage - go to challenges
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ChallengesView(isMismatch: false)),
        );
      } else {
        // New user who needs to complete mother stage selection
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const StageSelectionView()),
        );
      }
    }
  }

  void _toggleMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2EDE7),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 340,
              constraints: const BoxConstraints(maxHeight: 500),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFF2EDE7),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.1),
                    offset: Offset(0, 4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header (without close button)
                  _buildHeader(),
                  
                  // Toggle buttons (Sign Up / Sign In)
                  _buildToggleButtons(),
                  
                  const SizedBox(height: 20),
                  
                  // Form fields
                  _buildForm(),
                  
                  // Remember me checkbox
                  _buildRememberMe(),
                  
                  // Error message
                  if (_errorMessage != null) _buildErrorMessage(),
                  
                  const SizedBox(height: 20),
                  
                  // Submit button
                  _buildSubmitButton(),
                  
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Text(
          _isSignUp ? "Create Account" : "Welcome Back",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF574F4E),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButtons() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFE6E3E0),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          // Sign Up button
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!_isSignUp) _toggleMode();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: _isSignUp ? const Color(0xFF574F4E) : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Center(
                  child: Text(
                    "Sign Up",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _isSignUp ? Colors.white : const Color(0xFF574F4E),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Sign In button
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_isSignUp) _toggleMode();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: !_isSignUp ? const Color(0xFF574F4E) : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Center(
                  child: Text(
                    "Sign In",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: !_isSignUp ? Colors.white : const Color(0xFF574F4E),
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

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Username field
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: const Color(0xFFD7BFB8),
                width: 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.1),
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: TextField(
              controller: _usernameController,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF574F4E),
              ),
              decoration: InputDecoration(
                hintText: "Username",
                hintStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF999999),
                ),
                prefixIcon: const Icon(
                  Icons.person_outline,
                  color: Color(0xFF999999),
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
            ),
          ),
          
          const SizedBox(height: 15),
          
          // Password field
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: const Color(0xFFD7BFB8),
                width: 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.1),
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF574F4E),
              ),
              decoration: InputDecoration(
                hintText: "Password",
                hintStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF999999),
                ),
                prefixIcon: const Icon(
                  Icons.lock_outline,
                  color: Color(0xFF999999),
                  size: 20,
                ),
                suffixIcon: GestureDetector(
                  onTap: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  child: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: const Color(0xFF999999),
                    size: 20,
                  ),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRememberMe() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _rememberMe = !_rememberMe;
              });
            },
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: _rememberMe ? const Color(0xFF574F4E) : Colors.white,
                border: Border.all(
                  color: const Color(0xFFD7BFB8),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: _rememberMe
                  ? const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            "Remember me",
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF574F4E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
              _errorMessage!,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFFCC0000),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: _isLoading ? null : _handleSubmit,
        child: Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF574F4E),
            borderRadius: BorderRadius.circular(25),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.2),
                offset: Offset(0, 4),
                blurRadius: 8,
              ),
            ],
          ),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    _isSignUp ? "Create Account" : "Sign In",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
} 