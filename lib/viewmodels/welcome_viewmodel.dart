import 'package:flutter/material.dart';
import '../models/welcome_model.dart';

class WelcomeViewModel extends ChangeNotifier {
  WelcomeModel _model = const WelcomeModel();

  WelcomeModel get model => _model;

  void _updateModel(WelcomeModel newModel) {
    _model = newModel;
    notifyListeners();
  }

  void initialize() {
    print("WelcomeViewModel: Welcome screen initialized");
    // Any initialization logic can go here
    // For now, this is a simple static welcome screen
  }

  void updateVisibility(bool isVisible) {
    _updateModel(_model.copyWith(isVisible: isVisible));
  }

  @override
  void dispose() {
    print("WelcomeViewModel: Disposing");
    super.dispose();
  }
} 