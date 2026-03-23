import 'package:elder_voice_assist/screens/health_overview_screen.dart';
import 'package:elder_voice_assist/screens/medication_screen.dart';
import 'package:elder_voice_assist/services/notification_service.dart';
import 'package:go_router/go_router.dart';
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
import '../models/alert_model.dart';

class AppRouter {
  static GoRouter createRouter(RoleProvider roleProvider) {
    return GoRouter(
      initialLocation: '/',
      refreshListenable: roleProvider,
      redirect: (context, state) {
        final role = roleProvider.role;
        final location = state.matchedLocation;

        if (location == '/') return '/role-selection';
        if (location == '/role-selection') return null;

        if (role == null) return '/role-selection';

        final isGoingToCaregiver = location.startsWith('/caregiver');
        final isGoingToElder = location.startsWith('/elder');

        if (role == UserRole.elder && isGoingToCaregiver) {
          return '/elder/home';
        }
        if (role == UserRole.caregiver && isGoingToElder) {
          return '/caregiver/dashboard';
        }

        return null;
      },
      routes: [
        GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
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
        GoRoute(
          path: '/elder/health',
          builder: (context, state) => const HealthOverviewScreen(),
        ),
        GoRoute(
          path: '/elder/medications',
          builder: (context, state) => const MedicationScreen(),
        ),

        /// CAREGIVER ROUTES
        GoRoute(
          path: '/caregiver/dashboard',
          builder: (context, state) => const CaregiverDashboardScreen(),
        ),

        /// Alert detail accepts either 'extra' (AlertModel) or path param id
        GoRoute(
          path: '/alertDetail/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            final alert = state.extra as AlertModel?;
            return AlertDetailScreen(alertId: id, alert: alert);
          },
        ),

        /// COMMON
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    );
  }

  static void initializeNotifications() {
    NotificationService().onNotificationTap = (alertId) {
      // The router needs context — we store a navigator key for this
      // This is called from a notification; we push via GoRouter
    };
  }
}
