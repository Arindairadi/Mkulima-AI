import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/constants/app_constants.dart';

/// A titled card container used on the dashboard and most feature screens,
/// so every module (weather, market, farm management...) shares one visual
/// building block instead of re-implementing card chrome each time.
class AppSectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  final IconData? icon;

  const AppSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: AppColors.primary),
                  const SizedBox(width: AppConstants.spaceSm),
                ],
                Expanded(
                  child: Text(title, style: Theme.of(context).textTheme.titleMedium),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: AppConstants.spaceSm),
            child,
          ],
        ),
      ),
    );
  }
}

/// Colored alert banner used for weather alerts, disease-risk warnings,
/// and market opportunities (Sections 1, 2, 4, 8 of the brief).
class AppAlertBanner extends StatelessWidget {
  final String message;
  final Color color;
  final IconData icon;

  const AppAlertBanner({
    super.key,
    required this.message,
    required this.color,
    this.icon = Icons.warning_amber_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spaceMd,
        vertical: AppConstants.spaceSm + 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppConstants.spaceSm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Generic loading / error / empty state wrapper for AsyncValue-driven
/// screens, so every feature handles the three states consistently.
class AsyncStateView<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final String emptyMessage;

  const AsyncStateView({
    super.key,
    required this.value,
    required this.builder,
    this.emptyMessage = 'Nothing to show yet.',
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: (data) => builder(data),
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppConstants.spaceLg),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, st) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppConstants.spaceLg),
        child: Center(
          child: Text(
            err.toString(),
            style: const TextStyle(color: AppColors.danger),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
