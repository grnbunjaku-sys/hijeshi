import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class CartService {
  static final List<Map<String, dynamic>> _cartItems = [];
  static const String _storageKeyPrefix = 'cart_items';
  static const String _legacyStorageKey = 'cart_items';

  static final ValueNotifier<int> cartCountNotifier = ValueNotifier<int>(0);
  static final ValueNotifier<double> cartTotalNotifier = ValueNotifier<double>(0);

  static List<Map<String, dynamic>> get cartItems => _cartItems;

  static int get itemCount {
    int total = 0;
    for (final item in _cartItems) {
      total += _getQuantity(item);
    }
    return total;
  }

  static double get totalPrice {
    double total = 0;
    for (final item in _cartItems) {
      final price = double.tryParse(item['price'].toString()) ?? 0;
      final quantity = _getQuantity(item);
      total += price * quantity;
    }
    return total;
  }

  static int _getQuantity(Map<String, dynamic> item) {
    final quantity = item['quantity'];

    if (quantity is int) return quantity;
    if (quantity is double) return quantity.toInt();
    if (quantity is String) return int.tryParse(quantity) ?? 1;

    return 1;
  }

  static String _getVariantId(Map<String, dynamic> item) {
    return (item['variantId'] ?? '').toString();
  }

  static String getCartKeyForItem(Map<String, dynamic> item) {
    final productId = (item['id'] ?? '').toString();
    final variantId = _getVariantId(item);

    if (variantId.isNotEmpty) {
      return '$productId::$variantId';
    }

    return productId;
  }

  static void _notifyListeners() {
    cartCountNotifier.value = itemCount;
    cartTotalNotifier.value = totalPrice;
  }

  static Future<String> _getStorageKey() async {
    final userKey = await AuthService.getUserKey();
    return '$_storageKeyPrefix\_$userKey';
  }

  static Future<void> migrateLegacyCartIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final currentKey = await _getStorageKey();

    final hasCurrent = prefs.containsKey(currentKey);
    final legacyData = prefs.getString(_legacyStorageKey);

    if (!hasCurrent && legacyData != null && legacyData.isNotEmpty) {
      await prefs.setString(currentKey, legacyData);
    }
  }

  static Future<void> loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final storageKey = await _getStorageKey();

    await migrateLegacyCartIfNeeded();

    final String? data = prefs.getString(storageKey);

    _cartItems.clear();

    if (data != null && data.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(data);

        for (final item in decoded) {
          final mappedItem = Map<String, dynamic>.from(item);

          mappedItem['quantity'] = _getQuantity(mappedItem);
          mappedItem['variantId'] = (mappedItem['variantId'] ?? '').toString();
          mappedItem['selectedVariantText'] =
              (mappedItem['selectedVariantText'] ?? '').toString();

          _cartItems.add(mappedItem);
        }
      } catch (_) {
        _cartItems.clear();
      }
    }

    _notifyListeners();
  }

  static Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final storageKey = await _getStorageKey();
    final String data = jsonEncode(_cartItems);

    await prefs.setString(storageKey, data);
    _notifyListeners();
  }

  static Future<void> addToCart(Map<String, dynamic> product) async {
    final normalizedProduct = {
      ...product,
      'variantId': (product['variantId'] ?? '').toString(),
      'selectedVariantText': (product['selectedVariantText'] ?? '').toString(),
    };

    final newItemKey = getCartKeyForItem(normalizedProduct);

    final index = _cartItems.indexWhere(
          (item) => getCartKeyForItem(item) == newItemKey,
    );

    if (index != -1) {
      _cartItems[index]['quantity'] = _getQuantity(_cartItems[index]) + 1;
    } else {
      _cartItems.add({
        ...normalizedProduct,
        'quantity': 1,
      });
    }

    await _saveCart();
  }

  static Future<void> increaseQuantity(String productId, {String? variantId}) async {
    final normalizedVariantId = (variantId ?? '').toString();

    final index = _cartItems.indexWhere(
          (item) =>
      item['id'].toString() == productId &&
          _getVariantId(item) == normalizedVariantId,
    );

    if (index != -1) {
      _cartItems[index]['quantity'] = _getQuantity(_cartItems[index]) + 1;
      await _saveCart();
      return;
    }

    _notifyListeners();
  }

  static Future<void> decreaseQuantity(String productId, {String? variantId}) async {
    final normalizedVariantId = (variantId ?? '').toString();

    final index = _cartItems.indexWhere(
          (item) =>
      item['id'].toString() == productId &&
          _getVariantId(item) == normalizedVariantId,
    );

    if (index != -1) {
      final currentQty = _getQuantity(_cartItems[index]);

      if (currentQty > 1) {
        _cartItems[index]['quantity'] = currentQty - 1;
      } else {
        _cartItems.removeAt(index);
      }

      await _saveCart();
      return;
    }

    _notifyListeners();
  }

  static Future<void> removeFromCart(String productId, {String? variantId}) async {
    final normalizedVariantId = (variantId ?? '').toString();

    _cartItems.removeWhere(
          (item) =>
      item['id'].toString() == productId &&
          _getVariantId(item) == normalizedVariantId,
    );

    await _saveCart();
  }

  static Future<void> removeByVariantId(String variantId) async {
    final normalizedVariantId = variantId.toString();

    _cartItems.removeWhere(
          (item) => _getVariantId(item) == normalizedVariantId,
    );

    await _saveCart();
  }

  static Future<void> removeByCartKey(String cartKey) async {
    _cartItems.removeWhere(
          (item) => getCartKeyForItem(item) == cartKey,
    );

    await _saveCart();
  }

  static Future<void> clearCart() async {
    _cartItems.clear();
    await _saveCart();
  }
}