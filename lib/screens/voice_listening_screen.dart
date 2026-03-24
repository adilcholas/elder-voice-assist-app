import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/voice_provider.dart';
import '../providers/alert_provider.dart';
import '../providers/role_provider.dart';
import '../models/voice_state.dart';
import '../utils/app_spacing.dart';
import '../utils/app_typography.dart';
import '../utils/app_colors.dart';

class VoiceListeningScreen extends StatefulWidget {
  const VoiceListeningScreen({super.key});

  @override
  State<VoiceListeningScreen> createState() => _VoiceListeningScreenState();
}

class _VoiceListeningScreenState extends State<VoiceListeningScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    // Stop listening when screen is closed
    context.read<VoiceProvider>().stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voiceProvider = context.watch<VoiceProvider>();
    final alertProvider = context.read<AlertProvider>();
    final roleProvider = context.read<RoleProvider>();
    final elderName = roleProvider.userName.isNotEmpty
        ? roleProvider.userName
        : 'Elder User';

    /// Auto navigate to emergency when help detected (once)
    if (voiceProvider.state == VoiceState.detectedHelp && !_hasNavigated) {
      _hasNavigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/elder/emergency');
      });
    }

    final isListening = voiceProvider.state == VoiceState.listening;
    final circleColor = _getCircleColor(voiceProvider.state);

    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(title: const Text('Voice Assistant')),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              /// Pulsing Animation Container
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale = isListening
                      ? 1.0 + (_pulseController.value * 0.08)
                      : 1.0;
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: circleColor.withValues(
                          alpha: isListening ? 0.2 : 0.1,
                        ),
                        boxShadow: isListening
                            ? [
                                BoxShadow(
                                  color: circleColor.withValues(alpha: 0.3),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        _getIcon(voiceProvider.state),
                        size: 90,
                        color: circleColor,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: AppSpacing.xxl),

              /// State Title
              Text(
                _getTitle(voiceProvider.state),
                textAlign: TextAlign.center,
                style: AppTypography.display,
              ),

              const SizedBox(height: AppSpacing.md),

              /// Subtitle
              Text(
                _getSubtitle(voiceProvider.state),
                textAlign: TextAlign.center,
                style: AppTypography.body,
              ),

              /// Live transcription (shows what was heard)
              if (voiceProvider.lastWords.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: circleColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: circleColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '"${voiceProvider.lastWords}"',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: circleColor,
                    ),
                  ),
                ),
              ],

              /// Error message
              if (voiceProvider.errorMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  voiceProvider.errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.error, fontSize: 15),
                ),
              ],

              const SizedBox(height: AppSpacing.xxl),

              /// Start / Stop Button
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
                        ? 'Stop Listening'
                        : 'Start Listening',
                    style: const TextStyle(fontSize: 18),
                  ),
                  style: voiceProvider.state == VoiceState.listening
                      ? ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                        )
                      : null,
                  onPressed: voiceProvider.state == VoiceState.detectedHelp
                      ? null
                      : () {
                          if (voiceProvider.state == VoiceState.listening) {
                            voiceProvider.stopListening();
                          } else {
                            _hasNavigated = false;
                            voiceProvider.startListening(
                              context,
                              alertProvider,
                              elderName: elderName,
                              roleProvider: roleProvider,
                            );
                          }
                        },
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              const Text(
                "Say 'Help' or 'Emergency' to automatically trigger emergency assistance.",
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
      case VoiceState.detectedCall:
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
      case VoiceState.detectedCall:
        return Icons.call;
    }
  }

  String _getTitle(VoiceState state) {
    switch (state) {
      case VoiceState.idle:
        return 'Voice Assistant Ready';
      case VoiceState.listening:
        return 'Listening...';
      case VoiceState.processing:
        return 'Processing Voice';
      case VoiceState.detectedHelp:
        return 'Help Detected!';
      case VoiceState.detectedCall:
        return 'Calling Caregiver...';
    }
  }

  String _getSubtitle(VoiceState state) {
    switch (state) {
      case VoiceState.idle:
        return 'Press the button and speak clearly.';
      case VoiceState.listening:
        return 'Listening for distress keywords. Speak clearly.';
      case VoiceState.processing:
        return 'Analyzing your voice input.';
      case VoiceState.detectedHelp:
        return 'Triggering emergency assistance now...';
      case VoiceState.detectedCall:
        return 'Initiating phone call now...';
    }
  }
}
