import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Color constants provided for the brand
  static const Color primary = Color(0xFFE76F51); // Warm terracotta

  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(
      const Duration(seconds: 3),
    ); // Increased slightly for brand recognition
    if (mounted) {
      context.go('/role-selection');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Clean background to make the logo pop
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // The new Aura logo
            Image.asset(
              'assets/images/aura.png',
              width: 180, // Adjusted for visibility
              height: 180,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
