import 'package:flutter/material.dart';
import '../Templates/Custom_templates.dart';
import '../Database_logic/auth_manager.dart';
import '../Screens/Loading.dart';

class QuestionSet2 extends StatefulWidget {
  const QuestionSet2({Key? key}) : super(key: key);

  @override
  State<QuestionSet2> createState() => _QuestionSet2State();
}

class _QuestionSet2State extends State<QuestionSet2> {
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
      // Save data under "questionSet2"
      bool success = await _authManager.saveUserData('questionSet2', selectedQuestions);
      if (!success) {
        _authManager.showErrorMessage(context, "Failed to save questions");
        return;
      }
      print("QuestionSet2: Questions saved: $selectedQuestions");

      // After finishing Q2, navigate to final screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const Loading()),
      );
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
    return WillPopScope(
      onWillPop: () async {
        await _authManager.clearUserData('questionSet2');
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF2EDE7),
        body: SafeArea(
          child: Stack(
            children: [
              // Title
              CustomAlignedText(
                text: "Question set 2",
                alignment: Alignment.topCenter,
                padding: const EdgeInsets.only(top: 197),
                style: const TextStyle(
                  fontFamily: "Nuosu SIL",
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF574F4E),
                ),
              ),
              // Example questions
              _buildQuestionButton("Feeling lost outside of motherhood?", 240),
              _buildQuestionButton("Worried about others judging parenting style?", 300),
              _buildQuestionButton("Fear of getting sick and not supporting family?", 360),

              // Next button
              Positioned(
                bottom: 40,
                right: 20,
                child: GestureDetector(
                  onTap: _submitQuestions,
                  child: const CustomDirectionTextBox(
                    text: "Next",
                  ),
                ),
              ),

              // Back button
              Positioned(
                bottom: 40,
                left: 20,
                child: GestureDetector(
                  onTap: () async {
                    await _authManager.clearUserData('questionSet2');
                    Navigator.pop(context, 'backFromQ2');
                  },
                  child: const CustomDirectionTextBox(
                    text: "Back",
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
