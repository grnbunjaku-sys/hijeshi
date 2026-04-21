import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class FavoriteService {
  static final List<Map<String, dynamic>> _favoriteItems = [];
  static const String _storageKeyPrefix = 'favorite_items';
  static const String _legacyStorageKey = 'favorite_items';

  static final ValueNotifier<int> favoritesCountNotifier = ValueNotifier<int>(0);

  static List<Map<String, dynamic>> get favoriteItems => _favoriteItems;

  static void _notifyListeners() {
    favoritesCountNotifier.value = _favoriteItems.length;
  }

  static Future<String> _getStorageKey() async {
    final userKey = await AuthService.getUserKey();
    return '$_storageKeyPrefix\_$userKey';
  }

  static Future<void> migrateLegacyFavoritesIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final currentKey = await _getStorageKey();

    final hasCurrent = prefs.containsKey(currentKey);
    final legacyData = prefs.getString(_legacyStorageKey);

    if (!hasCurrent && legacyData != null && legacyData.isNotEmpty) {
      await prefs.setString(currentKey, legacyData);
    }
  }

  static Future<void> loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storageKey = await _getStorageKey();

      await migrateLegacyFavoritesIfNeeded();

      final String? data = prefs.getString(storageKey);

      _favoriteItems.clear();

      if (data != null && data.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(data);

        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            _favoriteItems.add(Map<String, dynamic>.from(item));
          } else if (item is Map) {
            _favoriteItems.add(Map<String, dynamic>.from(item));
          }
        }
      }

      _notifyListeners();
    } catch (e) {
      print('LOAD FAVORITES ERROR: $e');
      _favoriteItems.clear();
      _notifyListeners();
    }
  }

  static Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storageKey = await _getStorageKey();
      final String data = jsonEncode(_favoriteItems);

      await prefs.setString(storageKey, data);
      _notifyListeners();
    } catch (e) {
      print('SAVE FAVORITES ERROR: $e');
    }
  }

  static bool isFavorite(String productId) {
    return _favoriteItems.any(
          (item) => item['id'].toString() == productId.toString(),
    );
  }

  static Future<void> toggleFavorite(Map<String, dynamic> product) async {
    final id = product['id']?.toString() ?? '';

    if (id.isEmpty) return;

    final normalizedProduct = Map<String, dynamic>.from(product);

    final index = _favoriteItems.indexWhere(
          (item) => item['id'].toString() == id,
    );

    if (index != -1) {
      _favoriteItems.removeAt(index);
    } else {
      _favoriteItems.add(normalizedProduct);
    }

    await _saveFavorites();
  }

  static Future<void> removeFavorite(String productId) async {
    _favoriteItems.removeWhere(
          (item) => item['id'].toString() == productId.toString(),
    );

    await _saveFavorites();
  }

  static Future<void> clearFavorites() async {
    _favoriteItems.clear();
    await _saveFavorites();
  }
}