import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/voice_state.dart';
import 'alert_provider.dart';
import 'role_provider.dart';

class VoiceProvider extends ChangeNotifier {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  VoiceState _state = VoiceState.idle;
  VoiceState get state => _state;

  String _lastWords = '';
  String get lastWords => _lastWords;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<bool> _initSpeech() async {
    if (_isInitialized) return true;
    _isInitialized = await _speech.initialize(
      onError: (error) {
        _errorMessage = error.errorMsg;
        _state = VoiceState.idle;
        notifyListeners();
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (_state == VoiceState.listening) {
            _state = VoiceState.idle;
            notifyListeners();
          }
        }
      },
    );
    return _isInitialized;
  }

  Future<void> startListening(
    BuildContext context,
    AlertProvider alertProvider, {
    String elderName = 'Elder User',
    RoleProvider? roleProvider,
  }) async {
    _errorMessage = null;
    final available = await _initSpeech();

    if (!available) {
      _errorMessage = 'Speech recognition not available on this device.';
      notifyListeners();
      return;
    }

    _state = VoiceState.listening;
    _lastWords = '';
    notifyListeners();

    await _tts.speak('Voice assistant activated. Say help if you need assistance.');

    await _speech.listen(
      onResult: (result) async {
        _lastWords = result.recognizedWords;
        notifyListeners();

        if (_state != VoiceState.listening) return;

        final words = result.recognizedWords.toLowerCase();
        if (_containsDistressKeywords(words)) {
          await _detectHelp(alertProvider, elderName: elderName);
        } else if (_containsCallKeywords(words)) {
          await _detectCall(roleProvider);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
      listenOptions: SpeechListenOptions(
        cancelOnError: false,
        partialResults: true,
        onDevice: false,
      ),
    );
  }

  bool _containsDistressKeywords(String words) {
    const keywords = [
      'help',
      'help me',
      'emergency',
      'save me',
      'call ambulance',
      'i fell',
    ];
    return keywords.any((kw) => words.contains(kw));
  }

  Future<void> _detectHelp(
    AlertProvider alertProvider, {
    String elderName = 'Elder User',
  }) async {
    if (_state == VoiceState.detectedHelp) return;

    _state = VoiceState.detectedHelp;
    notifyListeners();

    await _speech.stop();
    await _tts.speak('Help detected. Contacting your caregiver now.');
    await alertProvider.triggerEmergency(elderName: elderName);
  }

  bool _containsCallKeywords(String words) {
    const keywords = [
      'call my son',
      'call my daughter',
      'call my caregiver',
      'call caregiver',
      'make a call',
      'call family',
      'call friend',
    ];
    return keywords.any((kw) => words.contains(kw)) || words == 'call';
  }

  Future<void> _detectCall(RoleProvider? roleProvider) async {
    if (_state == VoiceState.detectedCall || _state == VoiceState.detectedHelp) return;

    _state = VoiceState.detectedCall;
    notifyListeners();

    await _speech.stop();

    if (roleProvider != null && roleProvider.caregiverPhone.isNotEmpty) {
      await _tts.speak('Calling your caregiver now.');
      final uri = Uri.parse('tel:${roleProvider.caregiverPhone}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await _tts.speak('Sorry, I couldn\'t launch the phone call.');
      }
    } else {
      await _tts.speak('Sorry, no caregiver phone number is setup.');
    }
  }

  void stopListening() {
    _speech.stop();
    _tts.stop();
    _state = VoiceState.idle;
    _lastWords = '';
    notifyListeners();
  }

  void resetState() {
    _state = VoiceState.idle;
    _lastWords = '';
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }
}
