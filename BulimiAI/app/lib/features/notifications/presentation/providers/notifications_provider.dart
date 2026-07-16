import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/notification_entity.dart';

/// Mock notification feed. In Step 13 this becomes the client-side view of
/// server-pushed alerts delivered via Firebase Cloud Messaging (already in
/// pubspec.yaml) — weather alerts, pest/disease risk, and market
/// opportunities pushed from the backend, plus locally-scheduled farming
/// reminders. The `AppNotification` shape stays the same either way.
class NotificationsController extends StateNotifier<List<AppNotification>> {
  NotificationsController()
      : super([
          AppNotification(
            id: 'n1',
            type: NotificationType.weatherAlert,
            title: 'Flood risk in Kiryandongo',
            message: 'Heavy rainfall expected in the next 24 hours. Delay fertilizer application.',
            timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          ),
          AppNotification(
            id: 'n2',
            type: NotificationType.marketOpportunity,
            title: 'Beans prices up in Kampala',
            message: 'Beans are selling for more in Kampala than your local market this week.',
            timestamp: DateTime.now().subtract(const Duration(hours: 6)),
          ),
          AppNotification(
            id: 'n3',
            type: NotificationType.diseaseRisk,
            title: 'Coffee leaf rust risk rising',
            message: 'Humid conditions this week increase the risk of coffee leaf rust. Scout your farm closely.',
            timestamp: DateTime.now().subtract(const Duration(days: 1)),
            isRead: true,
          ),
          AppNotification(
            id: 'n4',
            type: NotificationType.reminder,
            title: 'Time to record this week\'s expenses',
            message: 'You haven\'t logged any farm expenses in the last 7 days.',
            timestamp: DateTime.now().subtract(const Duration(days: 2)),
            isRead: true,
          ),
        ]);

  /// Adds a new notification to the top of the feed — used by
  /// `PushNotificationService` when a real FCM push arrives.
  void addNotification(AppNotification notification) {
    state = [notification, ...state];
  }

  void markAsRead(String id) {
    state = [for (final n in state) if (n.id == id) n.copyWith(isRead: true) else n];
  }

  void markAllAsRead() {
    state = [for (final n in state) n.copyWith(isRead: true)];
  }

  int get unreadCount => state.where((n) => !n.isRead).length;
}

final notificationsProvider =
    StateNotifierProvider<NotificationsController, List<AppNotification>>((ref) => NotificationsController());

final unreadNotificationsCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).where((n) => !n.isRead).length;
});
