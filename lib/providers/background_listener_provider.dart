import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'alert_provider.dart';

class BackgroundListenerProvider extends ChangeNotifier {
  bool _isRunning = false;
  bool get isRunning => _isRunning;

  void startListening(AlertProvider alertProvider) {
    final service = FlutterBackgroundService();

    service.on("emergency_detected").listen((event) async {
      await alertProvider.triggerEmergency(
        elderName: "Elder User (Background)",
      );
    });

    _isRunning = true;
    notifyListeners();
  }

  void stopListening() {
    _isRunning = false;
    notifyListeners();
  }
}
