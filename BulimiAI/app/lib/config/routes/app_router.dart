import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/dashboard/presentation/screens/splash_screen.dart';
import '../../features/dashboard/presentation/screens/main_shell.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/authentication/presentation/screens/login_screen.dart';
import '../../features/weather/presentation/screens/weather_screen.dart';
import '../../features/market/presentation/screens/market_screen.dart';
import '../../features/farm_management/presentation/screens/farm_list_screen.dart';
import '../../features/voice_assistant/presentation/screens/voice_assistant_screen.dart';
import '../../features/disease_detection/presentation/screens/disease_detection_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';

/// Route path constants. Every feature module's routes are registered in
/// this one file so navigation stays declarative, testable, and easy to
/// scan as the app grows past 8+ feature modules.
class AppRoutes {
  AppRoutes._();
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';

  // Bottom-nav tab roots
  static const dashboard = '/dashboard';
  static const weather = '/weather';
  static const market = '/market';
  static const farmManagement = '/farm-management';
  static const voiceAssistant = '/voice-assistant';

  // Pushed on top of the shell (not tabs)
  static const diseaseDetection = '/disease-detection';
  static const notifications = '/notifications';
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Riverpod provider so the router can later react to auth state (e.g.
/// redirect to /login when the user signs out) via GoRouter's `redirect`,
/// once real Firebase Auth (rather than the mock repository) is wired in.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),

      // Screens pushed on top of the bottom-nav shell, reached via quick
      // actions rather than tabs.
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.diseaseDetection,
        builder: (context, state) => const DiseaseDetectionScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),

      // Bottom-navigation shell: 5 tabs, each with its own navigation
      // branch so per-tab state/history is preserved when switching tabs.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.dashboard, builder: (context, state) => const DashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.weather, builder: (context, state) => const WeatherScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.market, builder: (context, state) => const MarketScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.farmManagement, builder: (context, state) => const FarmListScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.voiceAssistant, builder: (context, state) => const VoiceAssistantScreen()),
          ]),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.uri}')),
    ),
  );
});
