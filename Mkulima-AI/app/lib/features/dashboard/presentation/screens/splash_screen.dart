import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../config/routes/app_router.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';

/// Splash screen: shows briefly, then decides where to send the farmer.
///
/// Currently this always routes to onboarding, since [MockAuthRepository]
/// has no persisted session between app launches. Once real Firebase Auth
/// is wired in (see `mock_auth_repository.dart`), this should instead
/// check `authStateChanges` for a cached/persisted session and skip
/// straight to the dashboard for returning, already-onboarded farmers.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    await Future.delayed(AppConstants.splashMinDuration);
    if (!mounted) return;

    final isAuthenticated = ref.read(authControllerProvider).isAuthenticated;
    context.go(isAuthenticated ? AppRoutes.dashboard : AppRoutes.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.textOnPrimary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.eco_rounded, size: 52, color: AppColors.primary),
            ),
            const SizedBox(height: AppConstants.spaceLg),
            Text(
              AppConstants.appName,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.textOnPrimary,
                  ),
            ),
            const SizedBox(height: AppConstants.spaceSm),
            Text(
              'Smart farming, powered by AI',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textOnPrimary.withValues(alpha: 0.85),
                  ),
            ),
            const SizedBox(height: AppConstants.spaceXl),
            const CircularProgressIndicator(color: AppColors.textOnPrimary),
          ],
        ),
      ),
    );
  }
}
