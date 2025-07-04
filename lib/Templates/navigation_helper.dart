import 'package:flutter/material.dart';
import '../views/challenges_view.dart';

class NavigationHelper {
  static Future<void> navigateBasedOnStages(
      BuildContext context, List<String> selectedStages) async {
    // REFACTORED: Use helper methods to detect stage categories
    final stageCategories = _categorizeStages(selectedStages);
    
    // REFACTORED: Use helper method to determine navigation route
    final route = _determineNavigationRoute(stageCategories);
    
    // REFACTORED: Use helper method to perform navigation
    _navigateToRoute(context, route);
  }

  // REFACTORED: Private helper to categorize stages
  static _StageCategories _categorizeStages(List<String> selectedStages) {
    return _StageCategories(
      hasTryingMoms: _hasStageInCategory(selectedStages, _tryingMomsStages),
      hasYoungChild: _hasStageInCategory(selectedStages, _youngChildStages),
      hasOlderChild: _hasStageInCategory(selectedStages, _olderChildStages),
    );
  }

  // REFACTORED: Generic helper to check if any stage exists in a category
  static bool _hasStageInCategory(List<String> selectedStages, List<String> categoryStages) {
    return selectedStages.any((stage) => categoryStages.contains(stage));
  }

  // REFACTORED: Private helper to determine the correct route based on stage combinations
  static _NavigationRoute _determineNavigationRoute(_StageCategories categories) {
    if (categories.hasTryingMoms && !categories.hasYoungChild && !categories.hasOlderChild) {
      // Only trying moms → direct to trying moms question set (set 3)
      return _NavigationRoute(isMismatch: false, startingSet: 3);
    } else if (categories.hasTryingMoms && (categories.hasYoungChild || categories.hasOlderChild)) {
      // Trying moms + other stages → combined flow (trying + others)
      return _NavigationRoute(isMismatch: true, startingSet: 3);
    } else if (categories.hasYoungChild && categories.hasOlderChild) {
      // Mismatch → open unified challenges view with both sets
      return _NavigationRoute(isMismatch: true, startingSet: 1);
    } else if (categories.hasYoungChild) {
      // Only young → unified challenges view starting with set 1
      return _NavigationRoute(isMismatch: false, startingSet: 1);
    } else if (categories.hasOlderChild) {
      // Only older → unified challenges view starting with set 2
      return _NavigationRoute(isMismatch: false, startingSet: 2);
    } else {
      // None selected or unknown case - return null to indicate no navigation
      return _NavigationRoute(isMismatch: false, startingSet: 1, shouldNavigate: false);
    }
  }

  // REFACTORED: Private helper to perform the actual navigation
  static void _navigateToRoute(BuildContext context, _NavigationRoute route) {
    if (!route.shouldNavigate) {
      // Handle unknown case - possibly show an error or do nothing
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChallengesView(
          isMismatch: route.isMismatch,
          startingSet: route.startingSet,
        ),
      ),
    );
  }

  // REFACTORED: Centralized stage definitions to eliminate hardcoded values
  static const List<String> _tryingMomsStages = ["trying moms?"];
  static const List<String> _youngChildStages = ["pregnant?", "toddler mom?"];
  static const List<String> _olderChildStages = ["teen mom?", "adult mom?"];

  // REFACTORED: Helper method to get all available stages (useful for validation)
  static List<String> _getAllStages() {
    return [
      ..._tryingMomsStages,
      ..._youngChildStages,
      ..._olderChildStages,
    ];
  }

  // REFACTORED: Helper method to validate if a stage is recognized
  static bool _isValidStage(String stage) {
    return _getAllStages().contains(stage);
  }
}

// REFACTORED: Private data classes to encapsulate related data
class _StageCategories {
  final bool hasTryingMoms;
  final bool hasYoungChild;
  final bool hasOlderChild;

  const _StageCategories({
    required this.hasTryingMoms,
    required this.hasYoungChild,
    required this.hasOlderChild,
  });
}

class _NavigationRoute {
  final bool isMismatch;
  final int startingSet;
  final bool shouldNavigate;

  const _NavigationRoute({
    required this.isMismatch,
    required this.startingSet,
    this.shouldNavigate = true,
  });
}



// add a class for navigation to see if there was a miss match 
// if there was then it will navigate to the first question set and then to the seocnd question set
