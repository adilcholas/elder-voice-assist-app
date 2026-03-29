import 'package:elder_voice_assist/screens/health_overview_screen.dart';
import 'package:elder_voice_assist/screens/medication_screen.dart';
import 'package:elder_voice_assist/screens/contacts_screen.dart';
import 'package:elder_voice_assist/services/notification_service.dart';
import 'package:go_router/go_router.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/link_elder_screen.dart';
import '../screens/elder_home_screen.dart';
import '../screens/voice_listening_screen.dart';
import '../screens/emergency_alert_screen.dart';
import '../screens/caregiver_dashboard_screen.dart';
import '../screens/alert_detail_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/appointments_screen.dart';
import '../providers/role_provider.dart';
import '../models/user_role.dart';
import '../models/alert_model.dart';

class AppRouter {
  static GoRouter createRouter(RoleProvider roleProvider) {
    return GoRouter(
      initialLocation: '/',
      refreshListenable: roleProvider,
      redirect: (context, state) {
        final location = state.matchedLocation;
        final isAuthRoute = location == '/login' || location == '/signup';

        // 1. Still loading from Firebase/Firestore, show splash screen
        if (roleProvider.isLoading) {
          if (location == '/') return null;
          return '/';
        }

        // 2. Not logged in
        if (!roleProvider.isLoggedIn) {
          if (isAuthRoute) return null; // let them login or signup
          return '/login'; // redirect others to login
        }

        // 3. Logged in logic
        final role = roleProvider.role;
        final profile = roleProvider.profile;

        if (role == UserRole.caregiver) {
          final isLinked = profile?.linkedUserIds.isNotEmpty == true;
          
          if (!isLinked) {
            // Must link before accessing dashboard
            if (location != '/caregiver/link') return '/caregiver/link';
            return null;
          }
        }

        // Redirect from auth routes or splash to correct home
        if (isAuthRoute || location == '/') {
          if (role == UserRole.elder) return '/elder/home';
          if (role == UserRole.caregiver) return '/caregiver/dashboard';
        }

        // Protect specific paths
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
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignupScreen(),
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
        GoRoute(
          path: '/elder/appointments',
          builder: (context, state) => const AppointmentsScreen(),
        ),
        GoRoute(
          path: '/elder/contacts',
          builder: (context, state) => const ContactsScreen(),
        ),

        /// CAREGIVER ROUTES
        GoRoute(
          path: '/caregiver/dashboard',
          builder: (context, state) => const CaregiverDashboardScreen(),
        ),
        GoRoute(
          path: '/caregiver/link',
          builder: (context, state) => const LinkElderScreen(),
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
