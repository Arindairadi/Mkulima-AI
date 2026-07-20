import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/dashboard/presentation/screens/splash_screen.dart';
import '../../features/dashboard/presentation/screens/main_shell.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/weather/presentation/screens/weather_screen.dart';
import '../../features/market/presentation/screens/market_screen.dart';
import '../../features/farm_management/presentation/screens/farm_list_screen.dart';
import '../../features/voice_assistant/presentation/screens/voice_assistant_screen.dart';
import '../../features/disease_detection/presentation/screens/disease_detection_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';

class AppRoutes {
  AppRoutes._();
  static const splash = '/';
  static const onboarding = '/onboarding';

  static const dashboard = '/dashboard';
  static const weather = '/weather';
  static const market = '/market';
  static const farmManagement = '/farm-management';
  static const voiceAssistant = '/voice-assistant';

  static const diseaseDetection = '/disease-detection';
  static const notifications = '/notifications';
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();

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
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.diseaseDetection,
        builder: (context, state) => const DiseaseDetectionScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
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
