import 'package:flutter/material.dart';
import '../Screens/QuestionSet1.dart';
import '../Screens/QuestionSet2.dart';

class NavigationHelper {
  static Future<void> navigateBasedOnStages(
      BuildContext context, List<String> selectedStages) async {
    bool hasYoungChild = selectedStages.any(
        (stage) => stage == "pregnant?" || stage == "toddler mom?");
    bool hasOlderChild = selectedStages.any(
        (stage) => stage == "teen mom?" || stage == "adult mom?");

    if (hasYoungChild && hasOlderChild) {
      // Mismatch → open QSet1 in mismatch mode
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const QuestionSet1(isMismatch: true)),
      );
    } else if (hasYoungChild) {
      // Only young
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const QuestionSet1(isMismatch: false)),
      );
    } else if (hasOlderChild) {
      // Only older
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const QuestionSet2()),
      );
    } else {
      // None selected or unknown case
      // Possibly do something else or show an error
    }
  }
}



// add a class for navigation to see if there was a miss match 
// if there was then it will navigate to the first question set and then to the seocnd question set
