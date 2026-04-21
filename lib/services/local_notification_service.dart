import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {}

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static Function(String?)? onNotificationTap;
  static bool _isInitialized = false;

  static Future<void> init({
    Function(String?)? onTap,
  }) async {
    if (onTap != null) {
      onNotificationTap = onTap;
    }

    if (_isInitialized) return;

    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(
      android: androidSettings,
    );

    await notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        onNotificationTap?.call(response.payload);
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    _isInitialized = true;
  }

  static Future<String?> getLaunchPayload() async {
    final NotificationAppLaunchDetails? details =
    await notificationsPlugin.getNotificationAppLaunchDetails();

    if (details == null) return null;
    if (details.didNotificationLaunchApp != true) return null;

    return details.notificationResponse?.payload;
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails(
      'hijeshi_channel',
      'Hijeshi Notifications',
      channelDescription: 'Notifications for Hijeshi app',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    await notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }
}