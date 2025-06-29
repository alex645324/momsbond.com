import 'package:flutter/material.dart';
import '../Templates/Custom_templates.dart';
import '../Database_logic/auth_manager.dart';
import '../Screens/QuestionSet2.dart';
import '../Screens/Loading.dart';

class QuestionSet1 extends StatefulWidget {
  final bool isMismatch; 
  // If true, the user has both young (pregnant/toddler) and older (teen/adult) stages.

  const QuestionSet1({
    Key? key,
    required this.isMismatch,
  }) : super(key: key);

  @override
  _QuestionSet1State createState() => _QuestionSet1State();
}

class _QuestionSet1State extends State<QuestionSet1> {
  final AuthManager _authManager = AuthManager();
  List<String> selectedQuestions = [];

  void _toggleQuestion(String question) {
    setState(() {
      if (selectedQuestions.contains(question)) {
        selectedQuestions.remove(question);
      } else {
        selectedQuestions.add(question);
      }
    });
  }

  Future<void> _submitQuestions() async {
    if (selectedQuestions.isEmpty) {
      _authManager.showErrorMessage(context, "Please select at least one question");
      return;
    }

    try {
      // Save data under "questionSet1"
      bool success = await _authManager.saveUserData('questionSet1', selectedQuestions);
      if (!success) {
        _authManager.showErrorMessage(context, "Failed to save questions");
        return;
      }

      print("QuestionSet1: Questions saved: $selectedQuestions");

      if (widget.isMismatch) {
        // If mismatch, go on to QuestionSet2
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const QuestionSet2()),
        );
      } else {
        // Non-mismatch flow can go to Loading or some final screen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Loading()),
        );
      }
    } catch (e) {
      print("Error saving question set: $e");
      _authManager.showErrorMessage(context, "Error: $e");
    }
  }

  Widget _buildQuestionButton(String text, double top) {
    bool isSelected = selectedQuestions.contains(text);
    return Positioned(
      top: top,
      left: 20,
      right: 20,
      child: GestureDetector(
        onTap: () => _toggleQuestion(text),
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

  @override
  Widget build(BuildContext context) {
    print("QuestionSet1: Building widget tree");
    
    return WillPopScope(
      onWillPop: () async {
        await _authManager.clearUserData('questionSet1');
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF2EDE7),
        body: SafeArea(
          child: Stack(
            children: [
              // Title
              Positioned(
                top: 197,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    "Question set 1",
                    style: const TextStyle(
                      fontFamily: "Nuosu SIL",
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF574F4E),
                    ),
                  ),
                ),
              ),

              // Example questions
              _buildQuestionButton("Worry about weight and body changes?", 240),
              _buildQuestionButton("Postpartum depression or anxiety?", 300),
              _buildQuestionButton("Loneliness because friends don't understand motherhood?", 360),

              // Next button
              Positioned(
                bottom: 40,
                right: 20,
                child: GestureDetector(
                  onTap: _submitQuestions,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2EDE7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFD7BFB8),
                        width: 1,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.25),
                          offset: Offset(2, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Text(
                      "Next",
                      style: TextStyle(
                        fontFamily: "Nuosu SIL",
                        fontSize: 14,
                        color: Color(0xFF574F4E),
                      ),
                    ),
                  ),
                ),
              ),

              // Back button
              Positioned(
                bottom: 40,
                left: 20,
                child: GestureDetector(
                  onTap: () async {
                    await _authManager.clearUserData('questionSet1');
                    Navigator.pop(context, 'backFromQ1');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2EDE7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFD7BFB8),
                        width: 1,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.25),
                          offset: Offset(2, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Text(
                      "Back",
                      style: TextStyle(
                        fontFamily: "Nuosu SIL",
                        fontSize: 14,
                        color: Color(0xFF574F4E),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}




/*


class QuestionSet1 extends StatelessWidget {
    const QuestionSet1({Key? key}) : super(key: key);

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
                            text: "Going through or been through..",
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
                                text: " Worry about weight and body changes?",
                            ),
                        ),
                        
                        // Second question box
                        Positioned(
                            top: 300,  // Places this box 80 pixels below the first box
                            left: 20,  // 20 pixel margin from left edge
                            right: 20, // 20 pixel margin from right edge
                            child: CustomTextBox(
                                text: "Postpartum depression or anxiety?",
                            ),
                        ),

                        // Third question box
                        Positioned(
                            top: 360, 
                            left: 20,
                            right: 20, 
                            child: CustomTextBox(
                                text: "Loneliness because friends don't understand motherhood?",
                            ),
                        ),
                        // Bottom navigation button - using template's built-in positioning
                        const CustomDirectionTextBox(
                            text: "Next",
                        ),

                    // "Back button wrapped with GestureDetector
                        Positioned(
                            bottom: 40,
                            left: 20,
                            child: GestureDetector(
                                onTap: () {
                                    Navigator.pop(context);
                                },
                                child: const CustomDirectionTextBox(
                                    text: "Back",
                                    right: null,
                                    left: 20,
                                ),
                            ),
                        ),
                    ],
                ),
            ),
        );
    }
}
*/