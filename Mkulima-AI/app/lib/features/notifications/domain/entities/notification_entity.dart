import 'package:equatable/equatable.dart';

enum NotificationType { weatherAlert, pestOutbreak, diseaseRisk, marketOpportunity, reminder }

class AppNotification extends Equatable {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        type: type,
        title: title,
        message: message,
        timestamp: timestamp,
        isRead: isRead ?? this.isRead,
      );

  @override
  List<Object?> get props => [id, type, title, message, timestamp, isRead];
}
