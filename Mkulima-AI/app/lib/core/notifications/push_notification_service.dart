import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/notifications/domain/entities/notification_entity.dart';
import '../../features/notifications/presentation/providers/notifications_provider.dart';

/// Wires Firebase Cloud Messaging into the existing Notifications feature.
///
/// NOT called automatically — this requires Firebase to be initialized
/// first (see the setup steps in `firebase_auth_repository_impl.dart`).
/// Once Firebase is set up, call `PushNotificationService.initialize(ref)`
/// once, early in `main.dart` after `Firebase.initializeApp()`.
///
/// IMPORTANT: this only handles *receiving* pushes on the device. Actually
/// *sending* a push (e.g. "flood alert for Kiryandongo farmers") requires
/// your backend to call the Firebase Admin SDK with a service-account key —
/// that's a separate piece (a small addition to `bulimi_ai_backend`) that
/// needs your own Firebase project's service account JSON, which nothing
/// here can generate for you. Download it from Firebase Console →
/// Project Settings → Service Accounts, keep it out of Git entirely (add
/// to `.gitignore`), and load its path via an environment variable in the
/// backend, the same way GEMINI_API_KEY is handled.
class PushNotificationService {
  static Future<void> initialize(Ref ref) async {
    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(alert: true, badge: true, sound: true);

    // Foreground messages: the app is open, so add directly to the existing
    // notifications feed instead of showing a system tray notification.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _addToFeed(ref, message);
    });

    // App was in the background and the user tapped the notification.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _addToFeed(ref, message);
    });

    // Cold start: app was fully closed and opened via a notification tap.
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _addToFeed(ref, initialMessage);
    }
  }

  static void _addToFeed(Ref ref, RemoteMessage message) {
    final controller = ref.read(notificationsProvider.notifier);
    final data = message.data;

    controller.addNotification(
      AppNotification(
        id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        type: _parseType(data['type']),
        title: message.notification?.title ?? 'Mkulima AI',
        message: message.notification?.body ?? '',
        timestamp: DateTime.now(),
      ),
    );
  }

  static NotificationType _parseType(String? value) {
    switch (value) {
      case 'weather_alert':
        return NotificationType.weatherAlert;
      case 'pest_outbreak':
        return NotificationType.pestOutbreak;
      case 'disease_risk':
        return NotificationType.diseaseRisk;
      case 'market_opportunity':
        return NotificationType.marketOpportunity;
      default:
        return NotificationType.reminder;
    }
  }
}
