import 'dart:async';
import 'package:flutter/material.dart';
import '../models/voice_state.dart';
import 'alert_provider.dart';

class VoiceProvider extends ChangeNotifier {
  VoiceState _state = VoiceState.idle;
  VoiceState get state => _state;

  Timer? _listeningTimer;

  void startListening(BuildContext context, AlertProvider alertProvider) {
    _state = VoiceState.listening;
    notifyListeners();

    /// Simulate voice detection delay (MVP)
    _listeningTimer?.cancel();
    _listeningTimer = Timer(const Duration(seconds: 4), () {
      _detectHelp(context, alertProvider);
    });
  }

  Future<void> _detectHelp(
    BuildContext context,
    AlertProvider alertProvider,
  ) async {
    _state = VoiceState.detectedHelp;
    notifyListeners();

    await alertProvider.triggerEmergency(elderName: "Elder User");
  }

  void stopListening() {
    _listeningTimer?.cancel();
    _state = VoiceState.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    _listeningTimer?.cancel();
    super.dispose();
  }
}
