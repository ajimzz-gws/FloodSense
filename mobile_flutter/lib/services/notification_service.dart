import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Shows system notifications for flood alerts.
///
/// In this prototype the phone decides when to alert. Later the same
/// [showFloodAlert] call can be fired by a Firebase topic message instead.
class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'flood_alerts';
  static const _channelName = 'Flood alerts';

  Future<void> init() async {
    const settings = InitializationSettings(
      // White silhouette of the logo (Android tints small icons itself).
      android: AndroidInitializationSettings('@drawable/ic_stat_flood'),
    );
    await _plugin.initialize(settings: settings);
  }

  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? true;
  }

  Future<void> showFloodAlert({
    required int id,
    required String title,
    required String body,
    required Color color,
  }) async {
    final details = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Warnings when a river near you rises',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      color: color,
      colorized: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 600, 300, 600, 300, 600]),
      styleInformation: BigTextStyleInformation(body),
      ticker: title,
    );
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(android: details),
    );
  }
}
