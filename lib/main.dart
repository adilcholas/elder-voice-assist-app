import 'package:elder_voice_assist/providers/alert_provider.dart';
import 'package:elder_voice_assist/providers/background_listener_provider.dart';
import 'package:elder_voice_assist/providers/theme_provider.dart';
import 'package:elder_voice_assist/providers/voice_provider.dart';
import 'package:elder_voice_assist/services/background_voice_service.dart';
import 'package:elder_voice_assist/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'providers/role_provider.dart';
import 'utils/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await BackgroundVoiceService.initializeService();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RoleProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => VoiceProvider()),
        ChangeNotifierProvider(create: (_) => BackgroundListenerProvider()),
        ChangeNotifierProvider(
          create: (_) {
            final provider = AlertProvider();
            provider.initialize(); // ⭐ LOAD SAVED ALERTS ON START
            return provider;
          },
        ),
      ],
      child: const AppView(),
    );
  }
}

class AppView extends StatefulWidget {
  const AppView({super.key});

  @override
  State<AppView> createState() => _AppViewState();
}

class _AppViewState extends State<AppView> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final roleProvider = context.read<RoleProvider>();
    _router = AppRouter.createRouter(roleProvider);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode, // ⭐ KEY LINE
    );
  }
}
