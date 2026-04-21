import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';
import 'user_service.dart';

class NotificationService {
  static final List<Map<String, dynamic>> _notifications = [];

  static final ValueNotifier<int> notifier = ValueNotifier<int>(0);
  static final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

  static const String _storageKey = 'hijeshi_notifications';

  static List<Map<String, dynamic>> get notifications =>
      List.unmodifiable(_notifications);

  static int get unreadCount =>
      _notifications.where((item) => item['isRead'] == false).length;

  static Future<void> loadNotifications() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_storageKey);

    _notifications.clear();

    if (raw != null && raw.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;

        for (final dynamic item in decoded) {
          if (item is Map) {
            final Map<String, dynamic> map = Map<String, dynamic>.from(item);

            if (!map.containsKey('isRead')) {
              map['isRead'] = false;
            }

            _notifications.add(map);
          }
        }
      } catch (_) {}
    }

    notifier.value++;
    unreadCountNotifier.value = unreadCount;
  }

  static Future<void> _saveNotifications() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_notifications));
  }

  static Future<void> syncTokenForLoggedInUser() async {
    final bool isLoggedIn = await AuthService.isLoggedIn();
    if (!isLoggedIn) return;

    final String? email = await AuthService.getUserEmail();
    if (email == null || email.isEmpty) return;

    final String? token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) return;

    await UserService.updateFcmToken(
      email: email,
      fcmToken: token,
    );
  }

  static Future<void> addNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    _notifications.insert(0, {
      'title': title,
      'body': body,
      'data': data ?? <String, dynamic>{},
      'createdAt': DateTime.now().toIso8601String(),
      'isRead': false,
    });

    await _saveNotifications();
    notifier.value++;
    unreadCountNotifier.value = unreadCount;
  }

  static Future<void> markAllAsRead() async {
    bool changed = false;

    for (final Map<String, dynamic> item in _notifications) {
      if (item['isRead'] != true) {
        item['isRead'] = true;
        changed = true;
      }
    }

    if (changed) {
      await _saveNotifications();
      notifier.value++;
    }

    unreadCountNotifier.value = unreadCount;
  }

  static Future<void> markAsReadAt(int index) async {
    if (index < 0 || index >= _notifications.length) return;
    if (_notifications[index]['isRead'] == true) return;

    _notifications[index]['isRead'] = true;

    await _saveNotifications();
    notifier.value++;
    unreadCountNotifier.value = unreadCount;
  }

  static Future<void> clear() async {
    _notifications.clear();
    await _saveNotifications();
    notifier.value++;
    unreadCountNotifier.value = 0;
  }
}