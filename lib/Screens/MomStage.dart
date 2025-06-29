import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Templates/Custom_templates.dart';
import '../Database_logic/auth_manager.dart';
import '../Templates/navigation_helper.dart';

class MomStage extends StatefulWidget {
  const MomStage({Key? key}) : super(key: key);

  @override
  _MomStageState createState() => _MomStageState();
}

class _MomStageState extends State<MomStage> {
  final AuthManager _authManager = AuthManager();
  List<String> selectedStages = [];

  // Toggle selection
  void _toggleStage(String stage) {
    setState(() {
      if (selectedStages.contains(stage)) {
        selectedStages.remove(stage);
      } else {
        selectedStages.add(stage);
      }
    });
  }

  // Sends selected stages to Firebase and navigates to question sets
  Future<void> _submitStages() async {
    if (selectedStages.isEmpty) {
      _authManager.showErrorMessage(context, "Please select at least one stage");
      return;
    }

    try {
      bool success = await _authManager.saveUserData('momStage', selectedStages);
      if (!success) {
        _authManager.showErrorMessage(context, "Failed to save your selection. Please try again.");
        return;
      }

      print("Stages saved: $selectedStages");
      // Use your navigation helper or direct logic
      // to determine whether to open QuestionSet1 or QuestionSet2, or both:
      NavigationHelper.navigateBasedOnStages(context, selectedStages);

    } catch (e) {
      print("Error saving mom stages: $e");
      _authManager.showErrorMessage(context, "Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2EDE7),
      body: SafeArea(
        child: Stack(
          children: [
            CustomAlignedText(
              text: "What stage are you in?",
              alignment: Alignment.topCenter,
              padding: const EdgeInsets.only(top: 197),
              style: const TextStyle(
                fontFamily: "Nuosu SIL",
                fontSize: 20,
                fontWeight: FontWeight.w400,
                color: Color(0xFF574F4E),
              ),
            ),

            // Pregnant?
            _buildStageButton("pregnant?", 240),
            // Toddler mom?
            _buildStageButton("toddler mom?", 300),
            // Teen mom?
            _buildStageButton("teen mom?", 360),
            // Adult mom?
            _buildStageButton("adult mom?", 420),

            // Submit button
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: GestureDetector(
                onTap: _submitStages,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2EDE7),
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
                  child: const Center(
                    child: Text(
                      "one more step..",
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

  Widget _buildStageButton(String text, double top) {
    bool isSelected = selectedStages.contains(text);
    return Positioned(
      top: top,
      left: 20,
      right: 20,
      child: GestureDetector(
        onTap: () => _toggleStage(text),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: const Color(0xFFF2EDE7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFD7BFB8),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? const Color.fromRGBO(0, 0, 0, 0.5)
                    : const Color.fromRGBO(0, 0, 0, 0.25),
                offset: const Offset(4, 4),
                blurRadius: 4,
              ),
            ],
          ),
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: "Nuosu SIL",
                fontSize: 16,
                color: Color(0xFF574F4E),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


/*
class MomStage extends StatelessWidget {
    const MomStage({Key? key}) : super(key: key);

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            // Set the background color for the entire screen
            backgroundColor: const Color(0xFFF2EDE7),
            body: SafeArea(
                // Stack allows widgets to be positioned on top of each other
                child: Stack(
                    children: [
                        // Title text at the top of the screen
                        CustomAlignedText(
                            text: "what stage are you in?",
                            // Centers the text at the top of the screen
                            alignment: Alignment.topCenter,
                            // Pushes the text 197 pixels down from the top
                            padding: const EdgeInsets.only(top: 197),
                            // Text styling properties
                            style: const TextStyle(
                                fontFamily: "Nuosu SIL",
                                fontSize: 20,
                                fontWeight: FontWeight.w400,
                                fontStyle: FontStyle.normal,
                                color: Color(0xFF574F4E),
                            ),
                        ),
                        
                        // First question box
                        Positioned(
                            top: 240,  // Places this box below the title text
                            left: 20,  // 20 pixel margin from left edge
                            right: 20, // 20 pixel margin from right edge
                            child: CustomTextBox(
                                text: "pregnant?",
                            ),
                        ),
                        
                        // Second question box
                        Positioned(
                            top: 300,  // Places this box 80 pixels below the first box
                            left: 20,  // 20 pixel margin from left edge
                            right: 20, // 20 pixel margin from right edge
                            child: CustomTextBox(
                                text: "toddler mom?",
                            ),
                        ),

                        // Third question box
                        Positioned(
                            top: 360, 
                            left: 20,
                            right: 20, 
                            child: CustomTextBox(
                                text: "teen mom?",
                            ),
                        ),

                        // Fourth question box
                        Positioned(
                            top: 420,
                            left: 20,
                            right: 20,
                            child: CustomTextBox(
                                text: "adult mom?",
                            ),
                        ),

                        // Bottom navigation button - using template's built-in positioning
                        const CustomDirectionTextBox(
                            text: "one more step..",
                        ),
                    ],
                ),
            ),
        );
    }
}
*/