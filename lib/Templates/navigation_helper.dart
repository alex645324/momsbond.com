import 'package:flutter/material.dart';
import '../views/challenges_view.dart';

class NavigationHelper {
  static Future<void> navigateBasedOnStages(
      BuildContext context, List<String> selectedStages) async {
    bool hasYoungChild = selectedStages.any(
        (stage) => stage == "pregnant?" || stage == "toddler mom?");
    bool hasOlderChild = selectedStages.any(
        (stage) => stage == "teen mom?" || stage == "adult mom?");

    if (hasYoungChild && hasOlderChild) {
      // Mismatch → open unified challenges view with both sets
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ChallengesView(isMismatch: true)),
      );
    } else if (hasYoungChild) {
      // Only young → unified challenges view starting with set 1
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ChallengesView(isMismatch: false)),
      );
    } else if (hasOlderChild) {
      // Only older → unified challenges view starting with set 2
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ChallengesView(isMismatch: false, startingSet: 2)),
      );
    } else {
      // None selected or unknown case
      // Possibly do something else or show an error
    }
  }
}



// add a class for navigation to see if there was a miss match 
// if there was then it will navigate to the first question set and then to the seocnd question set
