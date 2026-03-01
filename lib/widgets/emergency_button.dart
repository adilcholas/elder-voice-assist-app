import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_radius.dart';
import '../utils/app_typography.dart';

class EmergencyButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;

  const EmergencyButton({
    super.key,
    required this.onPressed,
    this.label = "EMERGENCY",
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          shape: const CircleBorder(),
          elevation: 10,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_rounded, size: 48, color: Colors.white),
            const SizedBox(height: 12),
            Text(
              label,
              style: AppTypography.title.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
