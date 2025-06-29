import 'package:flutter/material.dart';
import '../Database_logic/auth_manager.dart';
import '../Screens/MomStage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Dashboard.dart';

class GoogleSignInPage extends StatefulWidget {
  const GoogleSignInPage({Key? key}) : super(key: key);

  @override
  _GoogleSignInPageState createState() => _GoogleSignInPageState();
}

class _GoogleSignInPageState extends State<GoogleSignInPage> {
  bool _isLoading = false;
  final AuthManager _authManager = AuthManager();

  Future<void> _signInWithGoogle() async {
  print("\n" + "="*50);
  print("GoogleSignInPage: _signInWithGoogle called - ${DateTime.now()}");
  print("="*50);
  
  setState(() {
    _isLoading = true;
  });

  try {
    final userId = await _authManager.signInWithGoogle();
    
    if (userId != null) {
      print("GoogleSignInPage: Sign-in successful, checking if user completed onboarding");
      
      // Check if user has completed onboarding
      final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        print("GoogleSignInPage: User data found: ${userData.keys.toList()}");
        
        bool hasMomStage = userData.containsKey('momStage');
        bool hasQuestionSet1 = userData.containsKey('questionSet1');
        bool hasQuestionSet2 = userData.containsKey('questionSet2');
        
        print("GoogleSignInPage: Has momStage: $hasMomStage");
        print("GoogleSignInPage: Has questionSet1: $hasQuestionSet1");
        print("GoogleSignInPage: Has questionSet2: $hasQuestionSet2");
        
        bool hasCompletedOnboarding = hasMomStage && (hasQuestionSet1 || hasQuestionSet2);
        
        if (hasCompletedOnboarding) {
          print("GoogleSignInPage: User has completed onboarding - navigating to Dashboard");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Dashboard()),
          );
        } else {
          print("GoogleSignInPage: User needs to complete onboarding - navigating to MomStage");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MomStage()),
          );
        }
      } else {
        print("GoogleSignInPage: No user document found - navigating to MomStage");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MomStage()),
        );
      }
    } else {
      print("GoogleSignInPage: Sign-in failed or cancelled");
      _authManager.showErrorMessage(context, "Sign in was cancelled");
    }
  } catch (e) {
    print("GoogleSignInPage: Error during sign-in: $e");
    _authManager.showErrorMessage(context, "Error signing in: $e");
  } finally {
    setState(() {
      _isLoading = false;
    });
    print("="*50 + "\n");
  }
}

  @override
Widget build(BuildContext context) {
  print("\n" + "="*50);
  print("BUILDING GoogleSignInPage - ${DateTime.now()}");
  print("="*50 + "\n");
  
  return Scaffold(
    backgroundColor: const Color(0xFFF2EDE7),
    body: SafeArea(
      child: Stack(
        children: [
          // Welcome text
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 197),
              child: Column(
                children: const [
                  Text(
                    "Welcome to",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "Nuosu SIL",
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF574F4E),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "a gentle space",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "Nuosu SIL",
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF574F4E),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Google Sign In Button
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: GestureDetector(
              onTap: _isLoading ? null : _signInWithGoogle,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFD7BFB8),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromRGBO(0, 0, 0, 0.25),
                      offset: const Offset(2, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.login, size: 24), // Temporary icon instead of Google logo
                          const SizedBox(width: 12),
                          const Text(
                            "Continue with Google",
                            style: TextStyle(
                              fontFamily: "Nuosu SIL",
                              fontSize: 16,
                              color: Color(0xFF574F4E),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}