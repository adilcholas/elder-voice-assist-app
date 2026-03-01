import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/voice_provider.dart';
import '../providers/alert_provider.dart';
import '../models/voice_state.dart';
import '../utils/app_spacing.dart';
import '../utils/app_typography.dart';
import '../utils/app_colors.dart';

class VoiceListeningScreen extends StatelessWidget {
  const VoiceListeningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final voiceProvider = context.watch<VoiceProvider>();
    final alertProvider = context.read<AlertProvider>();

    /// Auto navigate to emergency when help detected
    if (voiceProvider.state == VoiceState.detectedHelp) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/elder/emergency');
      });
    }

    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(title: const Text("Voice Assistant")),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              /// Dynamic Listening Animation Container
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getCircleColor(
                    voiceProvider.state,
                  ).withValues(alpha: 0.15),
                ),
                child: Icon(
                  _getIcon(voiceProvider.state),
                  size: 90,
                  color: _getCircleColor(voiceProvider.state),
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              /// State Title (Elder Friendly Large Text)
              Text(
                _getTitle(voiceProvider.state),
                textAlign: TextAlign.center,
                style: AppTypography.display,
              ),

              const SizedBox(height: AppSpacing.md),

              /// Subtitle Guidance (Accessibility UX)
              Text(
                _getSubtitle(voiceProvider.state),
                textAlign: TextAlign.center,
                style: AppTypography.body,
              ),

              const SizedBox(height: AppSpacing.xxl),

              /// Start / Stop Listening Button
              SizedBox(
                width: double.infinity,
                height: AppSpacing.largeButtonHeight,
                child: ElevatedButton.icon(
                  icon: Icon(
                    voiceProvider.state == VoiceState.listening
                        ? Icons.stop
                        : Icons.mic,
                    size: 28,
                  ),
                  label: Text(
                    voiceProvider.state == VoiceState.listening
                        ? "Stop Listening"
                        : "Start Listening",
                    style: const TextStyle(fontSize: 18),
                  ),
                  onPressed: () {
                    if (voiceProvider.state == VoiceState.listening) {
                      voiceProvider.stopListening();
                    } else {
                      voiceProvider.startListening(context, alertProvider);
                    }
                  },
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              /// Safety Info Text (Trust UX)
              const Text(
                "Say 'Help' to automatically trigger emergency assistance.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCircleColor(VoiceState state) {
    switch (state) {
      case VoiceState.idle:
        return AppColors.secondary;
      case VoiceState.listening:
        return AppColors.primary;
      case VoiceState.processing:
        return AppColors.warning;
      case VoiceState.detectedHelp:
        return AppColors.error;
    }
  }

  IconData _getIcon(VoiceState state) {
    switch (state) {
      case VoiceState.idle:
        return Icons.mic_none_rounded;
      case VoiceState.listening:
        return Icons.mic_rounded;
      case VoiceState.processing:
        return Icons.graphic_eq_rounded;
      case VoiceState.detectedHelp:
        return Icons.warning_rounded;
    }
  }

  String _getTitle(VoiceState state) {
    switch (state) {
      case VoiceState.idle:
        return "Voice Assistant Ready";
      case VoiceState.listening:
        return "Listening...";
      case VoiceState.processing:
        return "Processing Voice";
      case VoiceState.detectedHelp:
        return "Help Detected!";
    }
  }

  String _getSubtitle(VoiceState state) {
    switch (state) {
      case VoiceState.idle:
        return "Press the button and speak clearly.";
      case VoiceState.listening:
        return "I am listening for distress keywords.";
      case VoiceState.processing:
        return "Analyzing your voice input.";
      case VoiceState.detectedHelp:
        return "Triggering emergency assistance now.";
    }
  }
}
