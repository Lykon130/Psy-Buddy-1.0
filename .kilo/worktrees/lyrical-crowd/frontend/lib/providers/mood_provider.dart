import 'package:flutter/material.dart';

class MoodProvider extends ChangeNotifier {
  String _currentEmotion = 'neutral';

  String get currentEmotion => _currentEmotion;

  void setEmotion(String emotion) {
    if (_currentEmotion != emotion) {
      _currentEmotion = emotion;
      notifyListeners();
    }
  }
}
