import 'package:flutter/foundation.dart';

class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  // Default Settings
  bool _isDebugMode = false; // Hidden by default
  double _fakeThreshold = 50.0; // Default is 50%

  bool get isDebugMode => _isDebugMode;
  double get fakeThreshold => _fakeThreshold;

  void toggleDebugMode(bool value) {
    _isDebugMode = value;
    notifyListeners(); // Update UI
  }

  void setThreshold(double value) {
    _fakeThreshold = value;
    notifyListeners(); // Update UI
  }
}
