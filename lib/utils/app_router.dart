import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../screens/splash_screen.dart';
import '../screens/role_selection_screen.dart';
import '../screens/elder_home_screen.dart';
import '../screens/voice_listening_screen.dart';
import '../screens/emergency_alert_screen.dart';
import '../screens/caregiver_dashboard_screen.dart';
import '../screens/alert_detail_screen.dart';
import '../screens/settings_screen.dart';
import '../providers/role_provider.dart';
import '../models/user_role.dart';

class AppRouter {
  static GoRouter createRouter(RoleProvider roleProvider) {
    return GoRouter(
      initialLocation: '/',
      refreshListenable: roleProvider,
      redirect: (context, state) {
  final role = roleProvider.role;
  final location = state.matchedLocation;

  // If app opens at root, send to role selection
  if (location == '/') {
    return '/role-selection';
  }

  // Allow access to role selection always
  if (location == '/role-selection') {
    return null;
  }

  // If role not selected, block all routes except role selection
  if (role == null) {
    return '/role-selection';
  }

  // Role-based protection
  final isGoingToCaregiver = location.startsWith('/caregiver');
  final isGoingToElder = location.startsWith('/elder');

  if (role == UserRole.elder && isGoingToCaregiver) {
    return '/elder/home';
  }

  if (role == UserRole.caregiver && isGoingToElder) {
    return '/caregiver/dashboard';
  }

  // No redirect needed
  return null;
},
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/role-selection',
          builder: (context, state) => const RoleSelectionScreen(),
        ),

        /// ELDER ROUTES
        GoRoute(
          path: '/elder/home',
          builder: (context, state) => const ElderHomeScreen(),
        ),
        GoRoute(
          path: '/elder/voice',
          builder: (context, state) => const VoiceListeningScreen(),
        ),
        GoRoute(
          path: '/elder/emergency',
          builder: (context, state) => const EmergencyAlertScreen(),
        ),

        /// CAREGIVER ROUTES
        GoRoute(
          path: '/caregiver/dashboard',
          builder: (context, state) => const CaregiverDashboardScreen(),
        ),
        GoRoute(
          path: '/caregiver/alert-detail',
          builder: (context, state) => const AlertDetailScreen(),
        ),

        /// COMMON
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    );
  }
}
