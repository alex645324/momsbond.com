// Import necessary Flutter packages for UI
import 'package:flutter/material.dart';
// Import Firebase packages for database and authentication
import 'package:cloud_firestore/cloud_firestore.dart';
// Import Firebase configuration - fix the import path
import '../Database_logic/firebase_options.dart';
import '../Database_logic/auth_manager.dart';
import '../Screens/MomStage.dart';

class NewMomsPage extends StatefulWidget {
  const NewMomsPage({Key? key}) : super(key: key);

  @override
  _NewMomsPageState createState() => _NewMomsPageState();
}

class _NewMomsPageState extends State<NewMomsPage> {
  final TextEditingController _nameController = TextEditingController();
  bool isLoading = true; // To track authentication status
  final AuthManager _authManager = AuthManager();

  @override
  void initState() {
    super.initState();
    // Add a delay before checking authentication to ensure Firebase is ready
    Future.delayed(const Duration(seconds: 2), () {
      _checkAuthStatus();
    });
  }

  /// **Checks authentication status and updates UI**
  void _checkAuthStatus() {
    // We can just update the UI state since auth is handled in main.dart
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// **Saves the user's name and navigates to the MomStage screen**
  Future<void> _submitName() async {
    String name = _nameController.text.trim();
    if (name.isEmpty) {
      print("Name is empty. Not submitting.");
      return;
    }

    try {
      // Use the auth manager to save the user's name
      bool success = await _authManager.saveUserData('username', name);
      
      if (success) {
        print("Name submitted: $name");
        
        // Navigate to the MomStage screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MomStage()),
        );
      } else {
        _authManager.showErrorMessage(context, "Failed to save your name. Please try again.");
      }
    } catch (e) {
      print("Error submitting name: $e");
      _authManager.showErrorMessage(context, "Error: $e");
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF2EDE7),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2EDE7),
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 197),
                child: Text(
                  "What is your name?",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: "Nuosu SIL",
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.normal,
                    color: Color(0xFF574F4E),
                  ),
                ),
              ),
            ),

            Align(
              alignment: Alignment.center,
              child: Container(
                width: 226,
                height: 43,
                decoration: BoxDecoration(
                  color: Color(0xFFF2EDE7),
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                  border: Border.all(color: Color(0xFFD7BFB8), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.25),
                      offset: Offset(4, 4),
                      blurRadius: 4,
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Center(
                  child: TextField(
                    controller: _nameController,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: "Nuosu SIL",
                      fontSize: 14,
                      color: Color(0xFF574F4E),
                    ),
                    decoration: const InputDecoration(
                      hintText: "Type here..",
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: 40,
              right: 20,
              child: GestureDetector(
                onTap: _submitName,
                child: Container(
                  width: 120,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(0xFFF2EDE7),
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                    border: Border.all(color: Color(0xFFD7BFB8), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.25),
                        offset: Offset(2, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: const Center(
                    child: Text(
                      "ready to move on..",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: "Nuosu SIL",
                        fontSize: 14,
                        color: Color(0xFF574F4E),
                      ),
                    ),
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
