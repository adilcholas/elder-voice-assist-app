import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/voice_state.dart';
import 'alert_provider.dart';
import 'role_provider.dart';
import 'contact_provider.dart';

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
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.48);
    await _tts.setVolume(1.0);

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
    ContactProvider? contactProvider,
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

    await _tts.speak(
        'Voice assistant activated. Say Help for emergency, or say Call and a name.');

    await _speech.listen(
      onResult: (result) async {
        _lastWords = result.recognizedWords;
        notifyListeners();

        if (_state != VoiceState.listening) return;

        final words = result.recognizedWords.toLowerCase().trim();

        if (_containsDistressKeywords(words)) {
          await _detectHelp(alertProvider, elderName: elderName);
        } else if (_containsCallKeywords(words)) {
          // Extract who to call from spoken words
          final targetName = _extractCallTarget(words);
          await _detectCall(
            roleProvider: roleProvider,
            contactProvider: contactProvider,
            targetName: targetName,
          );
        } else if (result.finalResult && words.isNotEmpty) {
          await _handleUnknownCommand();
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

  // ─────────────────────────────────────────────
  // DISTRESS DETECTION
  // ─────────────────────────────────────────────

  bool _containsDistressKeywords(String words) {
    const keywords = [
      // English
      'help', 'help me', 'emergency', 'save me', 'call ambulance', 'i fell',
      // Hindi (Romanized)
      'bachao', 'madad', 'gir gaya', 'gir gayi',
      // Hindi (Devanagari)
      'बचाओ', 'मदद', 'गिर गया', 'गिर गई',
      // Malayalam (Romanized)
      'sahayam', 'sahayikku', 'rakshikku', 'veenu',
      // Malayalam (Script)
      'സഹായം', 'സഹായിക്കൂ', 'രക്ഷിക്കൂ', 'വീണു',
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

  // ─────────────────────────────────────────────
  // CALL DETECTION — ALL LANGUAGES
  // ─────────────────────────────────────────────

  /// Returns true if the utterance contains any call-intent phrase.
  /// This includes generic caregiver calls AND named calls ("call adil").
  bool _containsCallKeywords(String words) {
    // Static keyword list (caregiver / family / generic call phrases)
    const staticKeywords = [
      // English — generic
      'call my son', 'call my daughter', 'call my caregiver',
      'call caregiver', 'make a call', 'call family', 'call friend',
      'call my doctor', 'call doctor',
      // Hindi (Romanized)
      'call karo', 'phone karo', 'phone lagao', 'call lagao',
      'mere beta ka call karo', 'mere bete ko call karo',
      'beti ko call karo', 'beta ko call karo',
      'doctor ko call karo', 'ambulance bulao',
      // Hindi (Devanagari)
      'कॉल करो', 'फोन करो', 'फोन लगाओ', 'कॉल लगाओ',
      'मेरे बेटे को कॉल करो', 'बेटा को कॉल करो', 'बेटी को कॉल करो',
      // Malayalam (Romanized)
      'vilikku', 'phone cheyyu', 'makkale vilikku',
      'mone vilikku', 'mole vilikku', 'doctore vilikku',
      // Malayalam (Script)
      'വിളിക്കൂ', 'ഫോൺ ചെയ്യൂ', 'മകനെ വിളിക്കൂ',
      'മകളെ വിളിക്കൂ', 'വിളിക്കുക',
    ];

    if (staticKeywords.any((kw) => words.contains(kw))) return true;

    // Dynamic pattern — "call [name]" in English/Hindi/Malayalam
    // Catches "call adil", "adil ko call karo", "adil vilikku", etc.
    final callPrefixPatterns = [
      RegExp(r'\bcall\s+\w+'),    // "call adil"
      RegExp(r'\w+\s+ko\s+call'), // "adil ko call karo"
      RegExp(r'\w+\s+vilikku'),   // "adil vilikku"
      RegExp(r'\w+\s+ko\s+phone'),// "adil ko phone karo"
      RegExp(r'phone\s+\w+'),     // "phone adil"
    ];

    if (callPrefixPatterns.any((p) => p.hasMatch(words))) return true;

    // Bare "call" word
    return words == 'call';
  }

  /// Strips call-verb patterns to extract the target person's name.
  /// Returns empty string if it's a generic call (no name specified).
  String _extractCallTarget(String words) {
    // Known generic patterns that do NOT contain a name
    const genericPatterns = [
      'call my son', 'call my daughter', 'call my caregiver',
      'call my doctor', 'call caregiver', 'call family', 'call friend',
      'call karo', 'phone karo', 'phone lagao', 'call lagao',
      'mere beta ka call karo', 'mere bete ko call karo',
      'beti ko call karo', 'beta ko call karo',
      'makkale vilikku', 'mone vilikku', 'mole vilikku',
      'vilikku', 'phone cheyyu',
    ];
    for (final pat in genericPatterns) {
      if (words.contains(pat)) return ''; // generic → call caregiver
    }

    // Strip call-verb words to isolate the name
    var cleaned = words
        .replaceAll(RegExp(r'\bko\b'), '')
        .replaceAll(RegExp(r'\bkaro\b'), '')
        .replaceAll(RegExp(r'\bphone\b'), '')
        .replaceAll(RegExp(r'\bcall\b'), '')
        .replaceAll(RegExp(r'\bvilikku\b'), '')
        .replaceAll(RegExp(r'\bvilichu\b'), '')
        .replaceAll(RegExp(r'\bmere\b'), '')
        .replaceAll(RegExp(r'\bmy\b'), '')
        .replaceAll(RegExp(r'\blagao\b'), '')
        .replaceAll(RegExp(r'\bplease\b'), '')
        .trim();

    // Return the first remaining word as the candidate name
    final parts = cleaned.split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.first : '';
  }

  Future<void> _detectCall({
    RoleProvider? roleProvider,
    ContactProvider? contactProvider,
    String targetName = '',
  }) async {
    if (_state == VoiceState.detectedCall ||
        _state == VoiceState.detectedHelp) {
      return;
    }

    _state = VoiceState.detectedCall;
    notifyListeners();

    await _speech.stop();

    // — Step 1: Try contact by name (if a name was extracted)
    if (targetName.isNotEmpty && contactProvider != null) {
      final contact = contactProvider.findByName(targetName);
      if (contact != null) {
        await _tts.speak('Calling ${contact.name} now.');
        await _dialNumber(contact.phone);
        return;
      } else {
        // Name heard but not in contacts — inform and fall through to caregiver
        await _tts.speak(
            'Contact "$targetName" not found. Calling your caregiver instead.');
      }
    }

    // — Step 2: Fall back to caregiver phone
    if (roleProvider != null && roleProvider.caregiverPhone.isNotEmpty) {
      await _tts.speak('Calling your caregiver now.');
      await _dialNumber(roleProvider.caregiverPhone);
    } else {
      await _tts.speak(
          'Sorry, no caregiver phone number is set up. Please add one in Settings.');
      _state = VoiceState.idle;
      notifyListeners();
    }
  }

  Future<void> _dialNumber(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      await _tts.speak("Sorry, I couldn't launch the phone call.");
      _state = VoiceState.idle;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────
  // UNKNOWN COMMAND
  // ─────────────────────────────────────────────

  Future<void> _handleUnknownCommand() async {
    if (_state != VoiceState.listening) return;

    _state = VoiceState.idle;
    notifyListeners();

    await _speech.stop();
    await _tts.speak(
        "I'm sorry, I didn't understand that. Please say Help for emergency, or Call followed by a name.");
  }

  // ─────────────────────────────────────────────
  // CONTROL
  // ─────────────────────────────────────────────

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
