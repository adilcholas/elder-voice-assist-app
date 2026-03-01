import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:speech_to_text/speech_to_text.dart';

class BackgroundVoiceService {
  static final SpeechToText _speech = SpeechToText();

  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        initialNotificationTitle: "ElderVoiceAssist",
        initialNotificationContent: "Listening for emergency keywords...",
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  /// iOS background handler (required even if minimal)
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }

  /// Main background logic
  static void onStart(ServiceInstance service) async {
    /// Ensure foreground mode (Android 12+ compliance)
    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();
    }

    bool available = await _speech.initialize();

    if (!available) return;

    _startListeningLoop(service);
  }

  static void _startListeningLoop(ServiceInstance service) async {
    _speech.listen(
      onResult: (result) {
        final words = result.recognizedWords.toLowerCase();

        if (words.contains("help") ||
            words.contains("emergency") ||
            words.contains("save me")) {
          service.invoke("emergency_detected");
        }
      },
    );

    /// Restart listening if it stops (important for continuous background)
    Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (!_speech.isListening) {
        await _speech.listen(
          onResult: (result) {
            final words = result.recognizedWords.toLowerCase();

            if (words.contains("help") ||
                words.contains("emergency") ||
                words.contains("save me")) {
              service.invoke("emergency_detected");
            }
          },
        );
      }
    });
  }

  static Future<void> startService() async {
    final service = FlutterBackgroundService();
    await service.startService();
  }

  static Future<void> stopService() async {
    final service = FlutterBackgroundService();

    if (service is AndroidServiceInstance) {
      service.invoke("stop_service");
    }

    await _speech.stop();
  }
}
