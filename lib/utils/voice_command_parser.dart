import 'package:flutter/foundation.dart';

/// Extracted pure-logic utilities from VoiceProvider for testability.
/// These functions contain NO platform dependencies (no TTS, STT, phone calls).
class VoiceCommandParser {
  /// Normalize text: lowercase, trim, collapse spaces, strip common punctuation.
  static String normalize(String raw) {
    return raw
        .toLowerCase()
        .trim()
        // strip common punctuation that STT sometimes appends
        .replaceAll(RegExp(r'[,\.!?;:\"]+'), '')
        // collapse multiple spaces
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
  }

  /// Returns true if the normalized words contain any distress/emergency keyword.
  static bool containsDistressKeywords(String words) {
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

  /// Returns true if the utterance contains any call-intent phrase.
  static bool containsCallIntent(String words) {
    // ---- Dynamic regex patterns (\S+ matches Unicode names too) ----
    final callPatterns = [
      RegExp(r'\bcall\s+\S+'),          // "call <name>", "call son"
      RegExp(r'\S+\s+ko\s+call'),       // "<name> ko call karo"
      RegExp(r'\S+\s+ko\s+phone'),      // "<name> ko phone karo"
      RegExp(r'\S+\s+vilikku'),         // "<name> vilikku"
      RegExp(r'\S+\s+vilikkoo'),        // "<name> vilikkoo"
      RegExp(r'\S+\s+vilikkuka'),       // "<name> vilikkuka"
      RegExp(r'\S+\s+vilichu'),         // "<name> vilichu"
      RegExp(r'\bphone\s+\S+'),         // "phone <name>"
      RegExp(r'\bring\s+\S+'),          // "ring <name>"
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

  /// Strips call-verb patterns to extract the target person's name.
  /// Returns empty string ONLY if it is truly a no-name generic command.
  static String extractCallTarget(String words) {
    // Phrases that are PURELY generic (no name embedded)
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

    // ---- 0. Strict generic check FIRST (exact match only) ----
    // Must run before regex extraction, otherwise patterns like "call X"
    // would extract noise words (e.g. "phone call" → "call", "call karo" → "karo")
    if (strictGenericPhrases.contains(trimmed)) {
      debugPrint(
          '[VoiceCommandParser] Generic command detected, falling back to caregiver');
      return '';
    }

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

    // ---- 3. Hindi Romanized: "<name> ko call karo" → "<name>" ----
    final hindiMatch = RegExp(
            r'^(.+?)\s+ko\s+(?:call|phone)\s*(?:karo|lagao|milao|karna)?\s*$')
        .firstMatch(trimmed);
    if (hindiMatch != null) {
      var name = hindiMatch.group(1)!.trim();
      name = name.replaceAll(RegExp(r'\b(?:mere|mera|meri)\b'), '').trim();
      debugPrint('[VoiceCommandParser] Hindi extraction: "$name"');
      return name;
    }

    // ---- 4. Hindi Devanagari: "अदिल को कॉल करो" ----
    final hindiDevaMatch = RegExp(
            r'^(.+?)\s+को\s+(?:कॉल|फोन)\s*(?:करो|लगाओ|मिलाओ)?\s*$')
        .firstMatch(trimmed);
    if (hindiDevaMatch != null) {
      var name = hindiDevaMatch.group(1)!.trim();
      name = name.replaceAll(RegExp(r'(?:मेरे|मेरा|मेरी)'), '').trim();
      debugPrint('[VoiceCommandParser] Hindi-Deva extraction: "$name"');
      return name;
    }

    // ---- 5. Malayalam Romanized: "<name> vilikku" / "<name> ne vilikku" ----
    final mlMatch = RegExp(
            r'^(.+?)\s+(?:ne\s+)?(?:vilikku|vilikkoo|vilikkuka|vilichu|phone\s+cheyyu|phone\s+cheyyoo|phone\s+cheyyuka)\s*$')
        .firstMatch(trimmed);
    if (mlMatch != null) {
      final name = mlMatch.group(1)!.trim();
      debugPrint('[VoiceCommandParser] Malayalam-Roman extraction: "$name"');
      return name;
    }

    // ---- 6. Malayalam Script: "അദിൽ വിളിക്കൂ" ----
    final mlScriptMatch = RegExp(
            r'^(.+?)\s+(?:നെ\s+)?(?:വിളിക്കൂ|വിളിക്കുക|ഫോൺ\s+ചെയ്യൂ|ഫോൺ\s+ചെയ്യുക)\s*$')
        .firstMatch(trimmed);
    if (mlScriptMatch != null) {
      final name = mlScriptMatch.group(1)!.trim();
      debugPrint('[VoiceCommandParser] Malayalam-Script extraction: "$name"');
      return name;
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

    debugPrint('[VoiceCommandParser] Token-scrub fallback name: "$cleaned"');
    if (cleaned.isEmpty) return '';

    final parts = cleaned.split(RegExp(r'\s+'));
    for (final p in parts) {
      if (p.isNotEmpty && p.length > 1) return p;
    }
    return parts.isNotEmpty && parts.first.isNotEmpty ? parts.first : '';
  }

  /// Remove trailing noise words after the name
  static String _cleanTrailingNoise(String s) {
    return s
        .replaceAll(RegExp(r'\s+(?:now|please|quickly|fast|jaldi)\s*$'), '')
        .trim();
  }
}
