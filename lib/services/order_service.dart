import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';
import 'cart_service.dart';

class OrderService {
  static final List<Map<String, dynamic>> _orders = [];

  static const String _storageKeyPrefix = 'orders';
  static final ValueNotifier<int> notifier = ValueNotifier<int>(0);

  static const String _baseUrl = 'https://api.hijeshicosmetics.com/api';

  static List<Map<String, dynamic>> get orders => List.unmodifiable(_orders);

  static Future<String> _getStorageKey() async {
    final userKey = await AuthService.getUserKey();
    return '${_storageKeyPrefix}_$userKey';
  }

  static Future<List<Map<String, dynamic>>> _loadLocalOrdersOnly() async {
    final prefs = await SharedPreferences.getInstance();
    final storageKey = await _getStorageKey();

    final String? raw = prefs.getString(storageKey);
    final List<Map<String, dynamic>> localOrders = [];

    if (raw != null && raw.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;

        for (final item in decoded) {
          if (item is Map) {
            localOrders.add(Map<String, dynamic>.from(item));
          }
        }
      } catch (_) {
        return [];
      }
    }

    return localOrders;
  }

  static Future<void> loadOrders() async {
    final bool isLoggedIn = await AuthService.isLoggedIn();
    final String? userEmail = await AuthService.getUserEmail();

    _orders.clear();

    if (!isLoggedIn || userEmail == null || userEmail.isEmpty) {
      final localOrders = await _loadLocalOrdersOnly();
      _orders.addAll(localOrders);
      notifier.value++;
      return;
    }

    try {
      final uri = Uri.parse(
        '$_baseUrl/my-orders?email=${Uri.encodeComponent(userEmail)}',
      );

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;

        if (data['success'] == true && data['orders'] is List) {
          final List<dynamic> fetchedOrders = data['orders'] as List<dynamic>;

          for (final item in fetchedOrders) {
            if (item is Map) {
              _orders.add(Map<String, dynamic>.from(item));
            }
          }

          notifier.value++;
          return;
        }
      }

      final localOrders = await _loadLocalOrdersOnly();
      _orders.addAll(localOrders);
      notifier.value++;
    } catch (e) {
      debugPrint('OrderService loadOrders error: $e');

      final localOrders = await _loadLocalOrdersOnly();
      _orders.addAll(localOrders);
      notifier.value++;
    }
  }

  static Future<void> _saveOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final storageKey = await _getStorageKey();
    await prefs.setString(storageKey, jsonEncode(_orders));
    notifier.value++;
  }

  static Future<void> createOrderFromCurrentCart({
    String status = 'Completed',
  }) async {
    final List<Map<String, dynamic>> cartSnapshot = CartService.cartItems
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    if (cartSnapshot.isEmpty) return;

    final double total = CartService.totalPrice;
    final int totalItems = CartService.itemCount;
    final DateTime now = DateTime.now();

    final String orderNumber =
        '#HJ${now.millisecondsSinceEpoch.toString().substring(5)}';

    _orders.insert(0, {
      'orderNumber': orderNumber,
      'status': status,
      'createdAt': now.toIso8601String(),
      'total': total,
      'currency': 'EUR',
      'totalItems': totalItems,
      'items': cartSnapshot,
    });

    await _saveOrders();
  }

  static Future<void> clearOrders() async {
    _orders.clear();
    await _saveOrders();
  }
}