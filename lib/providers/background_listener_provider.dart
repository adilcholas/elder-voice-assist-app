import 'dart:async';
import 'package:elder_voice_assist/services/background_even_chanel.dart';
import 'package:flutter/material.dart';
import 'alert_provider.dart';

class BackgroundListenerProvider extends ChangeNotifier {
  bool _isRunning = false;
  bool get isRunning => _isRunning;

  StreamSubscription? _subscription;

  void startListening(AlertProvider alertProvider) {
    _subscription = BackgroundEventChannel.events.listen((event) async {
      if (event == "emergency_detected") {
        await alertProvider.triggerEmergency(
          elderName: "Elder User (Background)",
        );
      }
    });

    _isRunning = true;
    notifyListeners();
  }

  void stopListening() {
    _subscription?.cancel();
    _isRunning = false;
    notifyListeners();
  }
}