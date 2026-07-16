import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/notification_entity.dart';
import '../providers/notifications_provider.dart';

final _timeFormat = DateFormat('MMM d, h:mm a');

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  IconData _iconFor(NotificationType type) {
    switch (type) {
      case NotificationType.weatherAlert:
        return Icons.wb_cloudy_outlined;
      case NotificationType.pestOutbreak:
        return Icons.pest_control_outlined;
      case NotificationType.diseaseRisk:
        return Icons.bug_report_outlined;
      case NotificationType.marketOpportunity:
        return Icons.trending_up;
      case NotificationType.reminder:
        return Icons.notifications_active_outlined;
    }
  }

  Color _colorFor(NotificationType type) {
    switch (type) {
      case NotificationType.weatherAlert:
        return AppColors.floodAlert;
      case NotificationType.pestOutbreak:
      case NotificationType.diseaseRisk:
        return AppColors.danger;
      case NotificationType.marketOpportunity:
        return AppColors.success;
      case NotificationType.reminder:
        return AppColors.secondary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final controller = ref.read(notificationsProvider.notifier);
    final sorted = [...notifications]..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        actions: [
          TextButton(
            onPressed: controller.markAllAsRead,
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: sorted.isEmpty
          ? const Center(child: Text('No alerts right now.'))
          : ListView.separated(
              padding: const EdgeInsets.all(AppConstants.spaceMd),
              itemCount: sorted.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppConstants.spaceSm),
              itemBuilder: (context, i) {
                final n = sorted[i];
                return Card(
                  color: n.isRead ? null : AppColors.primary.withValues(alpha: 0.05),
                  child: ListTile(
                    onTap: () => controller.markAsRead(n.id),
                    leading: CircleAvatar(
                      backgroundColor: _colorFor(n.type).withValues(alpha: 0.15),
                      child: Icon(_iconFor(n.type), color: _colorFor(n.type), size: 20),
                    ),
                    title: Text(
                      n.title,
                      style: TextStyle(fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(n.message),
                        const SizedBox(height: 4),
                        Text(
                          _timeFormat.format(n.timestamp),
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}
