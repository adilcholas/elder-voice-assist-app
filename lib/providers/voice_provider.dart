import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:permission_handler/permission_handler.dart';
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

  String _selectedLanguage = 'en-IN';
  String get selectedLanguage => _selectedLanguage;

  /// Debounce timer — waits for final result before acting on call commands
  Timer? _commandDebounce;

  /// Track whether we've already acted on the current listening session
  bool _commandExecuted = false;

  Future<bool> _initSpeech() async {
    if (_isInitialized) return true;
    await _tts.setLanguage(_selectedLanguage);
    await _tts.setSpeechRate(0.48);
    await _tts.setVolume(1.0);

    _isInitialized = await _speech.initialize(
      onError: (error) {
        debugPrint('[VoiceProvider] Speech error: ${error.errorMsg}');
        _errorMessage = error.errorMsg;
        _state = VoiceState.idle;
        _commandDebounce?.cancel();
        notifyListeners();
      },
      onStatus: (status) {
        debugPrint('[VoiceProvider] Speech status: $status');
        if (status == 'done' || status == 'notListening') {
          if (_state == VoiceState.listening) {
            // Speech engine stopped — process whatever we have
            _processAccumulatedWords();
          }
        }
      },
    );
    return _isInitialized;
  }

  void setLanguage(String languageCode) {
    _selectedLanguage = languageCode;
    _tts.setLanguage(languageCode);
    notifyListeners();
  }

  // Cached references for the current listening session
  AlertProvider? _currentAlertProvider;
  String _currentElderName = 'Elder User';
  RoleProvider? _currentRoleProvider;
  ContactProvider? _currentContactProvider;

  Future<void> startListening(
    BuildContext context,
    AlertProvider alertProvider, {
    String elderName = 'Elder User',
    RoleProvider? roleProvider,
    ContactProvider? contactProvider,
  }) async {
    _errorMessage = null;
    _commandExecuted = false;
    _commandDebounce?.cancel();

    final available = await _initSpeech();

    if (!available) {
      _errorMessage = 'Speech recognition not available on this device.';
      notifyListeners();
      return;
    }

    // Cache references for use in callbacks
    _currentAlertProvider = alertProvider;
    _currentElderName = elderName;
    _currentRoleProvider = roleProvider;
    _currentContactProvider = contactProvider;

    _state = VoiceState.listening;
    _lastWords = '';
    notifyListeners();

    await _speech.listen(
      onResult: (result) async {
        _lastWords = result.recognizedWords;
        notifyListeners();

        if (_commandExecuted) return;
        if (_state != VoiceState.listening) return;

        // Normalize: lowercase, trim, collapse spaces, strip leading punctuation
        final words = _normalize(result.recognizedWords);
        if (words.isEmpty) return;

        debugPrint('[VoiceProvider] Heard (normalized): "$words" (final: ${result.finalResult})');

        // PRIORITY 1: Distress/emergency keywords — act IMMEDIATELY (even on partial)
        if (_containsDistressKeywords(words)) {
          _commandExecuted = true;
          _commandDebounce?.cancel();
          await _detectHelp(alertProvider, elderName: elderName,
              roleProvider: roleProvider);
          return;
        }

        // PRIORITY 2: Call commands — wait for FINAL result to get the full name
        if (_containsCallIntent(words)) {
          if (result.finalResult) {
            // Final result — act now
            _commandDebounce?.cancel();
            _commandExecuted = true;
            final targetName = _extractCallTarget(words);
            debugPrint('[VoiceProvider] Call target extracted: "$targetName"');
            await _detectCall(
              roleProvider: roleProvider,
              contactProvider: contactProvider,
              targetName: targetName,
            );
          } else {
            // Partial result — set/reset debounce timer.
            // If no final result arrives, this timer will process what we have.
            _commandDebounce?.cancel();
            _commandDebounce = Timer(const Duration(milliseconds: 2500), () {
              if (!_commandExecuted && _state == VoiceState.listening) {
                _commandExecuted = true;
                final targetName = _extractCallTarget(
                    _lastWords.toLowerCase().trim());
                debugPrint(
                    '[VoiceProvider] Debounce fired, call target: "$targetName"');
                _detectCall(
                  roleProvider: roleProvider,
                  contactProvider: contactProvider,
                  targetName: targetName,
                );
              }
            });
          }
          return;
        }

        // PRIORITY 3: Unknown command — only on final result
        if (result.finalResult && words.isNotEmpty) {
          _commandDebounce?.cancel();
          _commandExecuted = true;
          await _handleUnknownCommand();
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
      localeId: _selectedLanguage,
      listenOptions: SpeechListenOptions(
        cancelOnError: false,
        partialResults: true,
        onDevice: false,
      ),
    );
  }

  /// Called when the speech engine status becomes 'done' or 'notListening'
  /// and we haven't acted yet — process whatever words we accumulated.
  void _processAccumulatedWords() {
    if (_commandExecuted) {
      _state = VoiceState.idle;
      notifyListeners();
      return;
    }

    final words = _normalize(_lastWords);
    if (words.isEmpty) {
      _state = VoiceState.idle;
      notifyListeners();
      return;
    }

    _commandDebounce?.cancel();
    _commandExecuted = true;

    if (_containsDistressKeywords(words)) {
      _detectHelp(_currentAlertProvider!, elderName: _currentElderName,
          roleProvider: _currentRoleProvider);
    } else if (_containsCallIntent(words)) {
      final targetName = _extractCallTarget(words);
      _detectCall(
        roleProvider: _currentRoleProvider,
        contactProvider: _currentContactProvider,
        targetName: targetName,
      );
    } else {
      _handleUnknownCommand();
    }
  }

  // ─────────────────────────────────────────────
  // DISTRESS DETECTION
  // ─────────────────────────────────────────────

  bool _containsDistressKeywords(String words) {
    const keywords = [
      // English
      'help', 'help me', 'emergency', 'save me', 'call ambulance',
      'i fell', 'i fall', 'fallen', 'danger',
      // Hindi (Romanized — multiple transliterations)
      'bachao', 'bachav', 'madad', 'madath', 'gir gaya', 'gir gayi',
      'gir gaye', 'bacha lo', 'bacha le', 'emergency hai',
      'koi bachao', 'help karo', 'sahayata',
      // Hindi (Devanagari)
      'बचाओ', 'मदद', 'गिर गया', 'गिर गई', 'गिर गये',
      'बचा लो', 'सहायता', 'एमरजेंसी', 'हेल्प',
      // Malayalam (Romanized — multiple transliterations)
      'sahayam', 'sahayikku', 'sahayikkoo', 'rakshikku', 'rakshikkoo',
      'veenu', 'veezhu', 'rakshikkanam', 'sahayam venam',
      'help cheyyoo', 'help cheyyu',
      // Malayalam (Script)
      'സഹായം', 'സഹായിക്കൂ', 'രക്ഷിക്കൂ', 'വീണു',
      'രക്ഷിക്കണം', 'സഹായം വേണം', 'ഹെൽപ്പ്',
    ];
    return keywords.any((kw) => words.contains(kw));
  }

  Future<void> _detectHelp(
    AlertProvider alertProvider, {
    String elderName = 'Elder User',
    RoleProvider? roleProvider,
  }) async {
    if (_state == VoiceState.detectedHelp) return;

    _state = VoiceState.detectedHelp;
    notifyListeners();

    await _speech.stop();

    // Trigger emergency alert
    await alertProvider.triggerEmergency(elderName: elderName);

    // ALSO call caregiver phone if available
    if (roleProvider != null && roleProvider.caregiverPhone.isNotEmpty) {
      await _tts.speak('Help detected. Calling your caregiver now.');
      // Small delay so TTS can start before the dial screen takes over
      await Future.delayed(const Duration(milliseconds: 1500));
      await _dialNumber(roleProvider.caregiverPhone);
    } else {
      await _tts.speak(
        'Help detected. Emergency alert sent. No caregiver phone is set up.',
      );
    }
  }

  // ─────────────────────────────────────────────
  // CALL DETECTION — ALL LANGUAGES
  // ─────────────────────────────────────────────

  /// Returns true if the utterance contains any call-intent phrase.
  /// This does NOT distinguish between generic "call caregiver" vs "call Adil".
  /// That is handled by _extractCallTarget.
  bool _containsCallIntent(String words) {
    // ---- Dynamic regex patterns (\S+ matches Unicode names too) ----
    final callPatterns = [
      RegExp(r'\bcall\s+\S+'),          // "call adil", "call son"
      RegExp(r'\S+\s+ko\s+call'),       // "adil ko call karo"
      RegExp(r'\S+\s+ko\s+phone'),      // "adil ko phone karo"
      RegExp(r'\S+\s+vilikku'),         // "adil vilikku"
      RegExp(r'\S+\s+vilikkoo'),        // "adil vilikkoo"
      RegExp(r'\S+\s+vilikkuka'),       // "adil vilikkuka"
      RegExp(r'\S+\s+vilichu'),         // "adil vilichu"
      RegExp(r'\bphone\s+\S+'),         // "phone adil"
      RegExp(r'\bring\s+\S+'),          // "ring adil"
      // Malayalam script suffixes
      RegExp(r'\S+\s+(?:വിളിക്കൂ|വിളിക്കുക|ഫോൺ\s+ചെയ്യൂ|ഫോൺ\s+ചെയ്യുക)'),
      // Hindi Devanagari
      RegExp(r'\S+\s+को\s+(?:कॉल|फोन)'),
    ];

    if (callPatterns.any((p) => p.hasMatch(words))) return true;

    // ---- Static keyword list (multi-language, no-name generic phrases) ----
    const staticKeywords = [
      // English
      'call my son', 'call my daughter', 'call my caregiver',
      'call caregiver', 'make a call', 'call family', 'call friend',
      'call my doctor', 'call doctor', 'call my friend',
      'phone call', 'make call', 'ring',
      // Hindi (Romanized)
      'call karo', 'phone karo', 'phone lagao', 'call lagao',
      'mere beta ko call karo', 'mere bete ko call karo',
      'beti ko call karo', 'beta ko call karo',
      'doctor ko call karo', 'ambulance bulao',
      'phone milao', 'call milao',
      'ko call karo', 'ko phone karo', 'ko phone lagao',
      'ko call lagao', 'ko call milao',
      // Hindi (Devanagari)
      'कॉल करो', 'फोन करो', 'फोन लगाओ', 'कॉल लगाओ',
      'मेरे बेटे को कॉल करो', 'बेटा को कॉल करो', 'बेटी को कॉल करो',
      'को कॉल करो', 'को फोन करो', 'फोन मिलाओ',
      // Malayalam (Romanized standalone — without a name)
      'phone cheyyu', 'phone cheyyoo',
      'makkale vilikku', 'mone vilikku', 'mole vilikku',
      'doctore vilikku', 'phone cheyyuka',
      'ne vilikku', 'ne vilikkoo', 'ne vilikkuka',
      // Malayalam (Script)
      'വിളിക്കൂ', 'ഫോൺ ചെയ്യൂ', 'മകനെ വിളിക്കൂ',
      'മകളെ വിളിക്കൂ', 'വിളിക്കുക', 'ഫോൺ ചെയ്യുക',
      'നെ വിളിക്കൂ', 'നെ വിളിക്കുക',
    ];

    if (staticKeywords.any((kw) => words.contains(kw))) return true;

    // Bare "call" word only
    if (RegExp(r'^\s*call\s*$').hasMatch(words)) return true;

    return false;
  }

  /// Normalize text: lowercase, trim, collapse spaces, strip leading punctuation.
  String _normalize(String raw) {
    return raw
        .toLowerCase()
        .trim()
        // strip common punctuation that STT sometimes appends
        .replaceAll(RegExp(r'[,\.!?;:"]+'), '')
        // collapse multiple spaces
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
  }

  /// Strips call-verb patterns to extract the target person's name.
  /// Returns empty string ONLY if it is truly a no-name generic command.
  String _extractCallTarget(String words) {
    // Phrases that are PURELY generic (no name embedded)
    // NOTE: bare verb words like "vilikku" alone are generic,
    // but "<name> vilikku" must NOT be blocked here.
    const strictGenericPhrases = [
      'call my caregiver', 'call caregiver',
      'make a call', 'make call', 'phone call',
      'call karo', 'phone karo', 'phone lagao', 'call lagao',
      'phone milao', 'call milao',
      'phone cheyyu', 'phone cheyyoo', 'phone cheyyuka',
      'कॉल करो', 'फोन करो', 'फोन लगाओ', 'कॉल लगाओ', 'फोन मिलाओ',
      // Malayalam standalone (no name prefix)
      'vilikku', 'vilikkoo', 'vilikkuka', 'vilichu',
      'mone vilikku', 'mole vilikku', 'makkale vilikku', 'doctore vilikku',
      'ne vilikku', 'ne vilikkoo', 'ne vilikkuka',
      'വിളിക്കൂ', 'ഫോൺ ചെയ്യൂ', 'വിളിക്കുക', 'ഫോൺ ചെയ്യുക',
      'നെ വിളിക്കൂ', 'നെ വിളിക്കുക',
      'മകനെ വിളിക്കൂ', 'മകളെ വിളിക്കൂ',
    ];

    final trimmed = words.trim();

    // ---- 1. English: "call my X" / "call X" ----
    final callMyMatch = RegExp(r'^call\s+my\s+(.+)$').firstMatch(trimmed);
    if (callMyMatch != null) {
      return _cleanTrailingNoise(callMyMatch.group(1)!.trim());
    }
    final callMatch = RegExp(r'^call\s+(.+)$').firstMatch(trimmed);
    if (callMatch != null) {
      return _cleanTrailingNoise(callMatch.group(1)!.trim());
    }

    // ---- 2. English: "ring X" / "phone X" ----
    final phoneMatch = RegExp(r'^(?:phone|ring)\s+(.+)$').firstMatch(trimmed);
    if (phoneMatch != null) {
      return _cleanTrailingNoise(phoneMatch.group(1)!.trim());
    }

    // ---- 3. Hindi Romanized: "adil ko call karo" → "adil" ----
    // \S+ handles both ASCII and Unicode names
    final hindiMatch = RegExp(
            r'^(.+?)\s+ko\s+(?:call|phone)\s*(?:karo|lagao|milao|karna)?\s*$')
        .firstMatch(trimmed);
    if (hindiMatch != null) {
      var name = hindiMatch.group(1)!.trim();
      name = name.replaceAll(RegExp(r'\b(?:mere|mera|meri)\b'), '').trim();
      debugPrint('[VoiceProvider] Hindi extraction: "$name"');
      return name;
    }

    // ---- 4. Hindi Devanagari: "अदिल को कॉल करो" ----
    final hindiDevaMatch = RegExp(
            r'^(.+?)\s+को\s+(?:कॉल|फोन)\s*(?:करो|लगाओ|मिलाओ)?\s*$')
        .firstMatch(trimmed);
    if (hindiDevaMatch != null) {
      var name = hindiDevaMatch.group(1)!.trim();
      name = name.replaceAll(RegExp(r'(?:मेरे|मेरा|मेरी)'), '').trim();
      debugPrint('[VoiceProvider] Hindi-Deva extraction: "$name"');
      return name;
    }

    // ---- 5. Malayalam Romanized: "adil vilikku" / "adil ne vilikku" ----
    // (.+?) is greedy-lazy so it captures everything before the verb
    final mlMatch = RegExp(
            r'^(.+?)\s+(?:ne\s+)?(?:vilikku|vilikkoo|vilikkuka|vilichu|phone\s+cheyyu|phone\s+cheyyoo|phone\s+cheyyuka)\s*$')
        .firstMatch(trimmed);
    if (mlMatch != null) {
      final name = mlMatch.group(1)!.trim();
      debugPrint('[VoiceProvider] Malayalam-Roman extraction: "$name"');
      return name;
    }

    // ---- 6. Malayalam Script: "അദിൽ വിളിക്കൂ" ----
    final mlScriptMatch = RegExp(
            r'^(.+?)\s+(?:നെ\s+)?(?:വിളിക്കൂ|വിളിക്കുക|ഫോൺ\s+ചെയ്യൂ|ഫോൺ\s+ചെയ്യുക)\s*$')
        .firstMatch(trimmed);
    if (mlScriptMatch != null) {
      final name = mlScriptMatch.group(1)!.trim();
      debugPrint('[VoiceProvider] Malayalam-Script extraction: "$name"');
      return name;
    }

    // ---- 7. Strict generic check → caregiver fallback ----
    if (strictGenericPhrases.any((pat) => trimmed == pat ||
        trimmed.endsWith(' $pat') ||
        trimmed.startsWith('$pat '))) {
      debugPrint('[VoiceProvider] Generic command detected, falling back to caregiver');
      return '';
    }

    // ---- 8. Token scrub fallback ----
    var cleaned = trimmed
        .replaceAll(
            RegExp(
                r'\b(?:ko|karo|phone|call|vilikku|vilikkoo|vilikkuka|vilichu|ring)\b'),
            '')
        .replaceAll(
            RegExp(
                r'\b(?:mere|mera|meri|my|please|now|lagao|milao|cheyyu|cheyyoo|ne|make|a)\b'),
            '')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();

    debugPrint('[VoiceProvider] Token-scrub fallback name: "$cleaned"');
    if (cleaned.isEmpty) return '';

    final parts = cleaned.split(RegExp(r'\s+'));
    for (final p in parts) {
      if (p.isNotEmpty && p.length > 1) return p;
    }
    return parts.isNotEmpty && parts.first.isNotEmpty ? parts.first : '';
  }

  /// Remove trailing noise words after the name
  String _cleanTrailingNoise(String s) {
    return s
        .replaceAll(RegExp(r'\s+(?:now|please|quickly|fast|jaldi)\s*$'), '')
        .trim();
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

    debugPrint('[VoiceProvider] _detectCall: targetName="$targetName", '
        'contactProvider=${contactProvider != null}, '
        'contacts count=${contactProvider?.contacts.length ?? 0}');

    // — Step 1: Try contact by name/relationship (if a name was extracted)
    if (targetName.isNotEmpty && contactProvider != null) {
      final contact = contactProvider.findByName(targetName);
      debugPrint('[VoiceProvider] findByName("$targetName") => ${contact?.name ?? "null"}');
      if (contact != null) {
        await _tts.speak('Calling ${contact.name} now.');
        await Future.delayed(const Duration(milliseconds: 1200));
        await _dialNumber(contact.phone);
        return;
      }

      // Also try matching relationship words
      // Map common Hindi/Malayalam relationship words to English
      final relationshipMap = {
        // Hindi
        'beta': 'son', 'bete': 'son', 'beti': 'daughter',
        'बेटा': 'son', 'बेटे': 'son', 'बेटी': 'daughter',
        'doctor': 'doctor', 'dost': 'friend', 'दोस्त': 'friend',
        'डॉक्टर': 'doctor',
        // Malayalam
        'mone': 'son', 'mon': 'son', 'mole': 'daughter', 'mol': 'daughter',
        'മകൻ': 'son', 'മകൾ': 'daughter',
        // English
        'son': 'son', 'daughter': 'daughter', 'friend': 'friend',
        'caregiver': 'caregiver',
      };

      final mappedRelationship = relationshipMap[targetName.toLowerCase()];
      if (mappedRelationship != null) {
        final relContact = contactProvider.findByName(mappedRelationship);
        if (relContact != null) {
          await _tts.speak('Calling ${relContact.name} now.');
          await Future.delayed(const Duration(milliseconds: 1200));
          await _dialNumber(relContact.phone);
          return;
        }
      }

      // Name heard but not in contacts
      await _tts.speak(
        'No contact named "$targetName" found. Please add the contact first.',
      );
      _state = VoiceState.idle;
      notifyListeners();
      return;
    }

    // — Step 2: No specific name → fall back to caregiver phone
    if (roleProvider != null && roleProvider.caregiverPhone.isNotEmpty) {
      await _tts.speak('Calling your caregiver now.');
      await Future.delayed(const Duration(milliseconds: 1200));
      await _dialNumber(roleProvider.caregiverPhone);
    } else {
      await _tts.speak(
        'Sorry, no caregiver phone number is set up. Please add one in Settings.',
      );
      _state = VoiceState.idle;
      notifyListeners();
    }
  }

  Future<void> _dialNumber(String phone) async {
    final status = await Permission.phone.request();
    if (!status.isGranted) {
      await _tts.speak("Phone permission is required to make calls.");
      _state = VoiceState.idle;
      notifyListeners();
      return;
    }
    debugPrint('[VoiceProvider] Dialing: $phone');
    bool? res = await FlutterPhoneDirectCaller.callNumber(phone);
    if (res == null || !res) {
      await _tts.speak("Sorry, I couldn't make the phone call.");
      _state = VoiceState.idle;
      notifyListeners();
    } else {
      // Call initiated successfully, reset state after a delay
      await Future.delayed(const Duration(seconds: 2));
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

    // Respond in the selected language
    String message;
    if (_selectedLanguage.startsWith('hi')) {
      message = 'माफ़ कीजिए, मुझे समझ नहीं आया। मदद के लिए "बचाओ" बोलें, या कॉल करने के लिए "कॉल करो" बोलें।';
    } else if (_selectedLanguage.startsWith('ml')) {
      message = 'ക്ഷമിക്കണം, എനിക്ക് മനസ്സിലായില്ല. സഹായത്തിന് "സഹായം" എന്ന് പറയൂ, അല്ലെങ്കിൽ വിളിക്കാൻ "വിളിക്കൂ" എന്ന് പറയൂ.';
    } else {
      message = "I'm sorry, I didn't understand that. Say Help for emergency, or Call followed by a name.";
    }
    await _tts.speak(message);
  }

  // ─────────────────────────────────────────────
  // CONTROL
  // ─────────────────────────────────────────────

  void stopListening() {
    _speech.stop();
    _tts.stop();
    _commandDebounce?.cancel();
    _commandExecuted = false;
    _state = VoiceState.idle;
    _lastWords = '';
    notifyListeners();
  }

  void resetState() {
    _state = VoiceState.idle;
    _lastWords = '';
    _errorMessage = null;
    _commandDebounce?.cancel();
    _commandExecuted = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _commandDebounce?.cancel();
    _speech.cancel();
    super.dispose();
  }
}
