import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/routes/app_router.dart';
import 'core/theme/app_theme.dart';

/// Root widget. Kept deliberately tiny — its only responsibility is wiring
/// together theming and routing. All real logic lives in feature modules.
class MkulimaApp extends ConsumerWidget {
  const MkulimaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Mkulima AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light, // farmers' feedback will decide if we expose dark mode later
      routerConfig: router,
    );
  }
}
