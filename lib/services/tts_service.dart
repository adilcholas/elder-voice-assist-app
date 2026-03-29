import 'package:flutter_tts/flutter_tts.dart';
import '../models/medication_model.dart';
import '../models/appointment_model.dart';

/// Singleton TTS service used across medication and appointment screens.
/// Provides pre-formatted speak methods so no screen needs to build
/// announcement strings manually.
class TtsService {
  TtsService._internal();
  static final TtsService instance = TtsService._internal();
  factory TtsService() => instance;

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  Future<void> _init() async {
    if (_initialized) return;
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45); // slower = easier for elders
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _initialized = true;
  }

  /// Speak any arbitrary text (stops prior speech first).
  Future<void> speak(String text) async {
    await _init();
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  /// Announces a medication reminder in a clear, structured sentence.
  Future<void> speakMedication(MedicationModel med) async {
    final times = med.times.map((t) => t.formatted).join(', ');
    final instructions =
        med.instructions != null && med.instructions!.isNotEmpty
            ? ' Instructions: ${med.instructions}.'
            : '';
    final status = med.isOverdue
        ? 'This medication is overdue. Please take it now.'
        : med.isDueNow
            ? 'This medication is due right now.'
            : 'Scheduled at $times.';

    final text =
        'Medication reminder. ${med.name}. Dosage: ${med.dosage}.$instructions $status';
    await speak(text);
  }

  /// Announces a doctor appointment reminder in a clear, structured sentence.
  Future<void> speakAppointment(AppointmentModel apt) async {
    final dt = apt.dateTime;
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'A M' : 'P M';
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final dateStr =
        '${months[dt.month - 1]} ${dt.day}, ${dt.year} at $hour:$minute $period';
    final location = apt.location.isNotEmpty ? ' Location: ${apt.location}.' : '';
    final notes =
        (apt.notes != null && apt.notes!.isNotEmpty) ? ' Notes: ${apt.notes}.' : '';

    final text =
        'Doctor appointment reminder. ${apt.title} with Doctor ${apt.doctorName}.'
        ' Date and time: $dateStr.$location$notes';
    await speak(text);
  }
}
