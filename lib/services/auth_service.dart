import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'cart_service.dart';
import 'favorite_service.dart';

class AuthService {
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  static const String _userKeyKey = 'user_key';

  static const String baseUrl = "https://api.hijeshicosmetics.com/api";

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/register"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "name": name,
          "email": email,
          "password": password,
        }),
      );

      print("REGISTER STATUS: ${response.statusCode}");
      print("REGISTER BODY: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (data['success'] == true) {
          await _saveUserLocally(
            name: data['user']['name'] ?? '',
            email: data['user']['email'] ?? '',
          );

          await CartService.loadCart();
          await FavoriteService.loadFavorites();
        }
        return data;
      }

      return {
        "success": false,
        "message": data['message'] ?? "Register failed",
        "errors": data['errors'],
      };
    } catch (e) {
      print("REGISTER ERROR: $e");
      return {
        "success": false,
        "message": "Gabim në server: $e",
      };
    }
  }

  static Future<Map<String, dynamic>> loginApi({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      print("LOGIN STATUS: ${response.statusCode}");
      print("LOGIN BODY: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (data['success'] == true) {
          await _saveUserLocally(
            name: data['user']['name'] ?? '',
            email: data['user']['email'] ?? '',
          );

          await CartService.loadCart();
          await FavoriteService.loadFavorites();
        }
        return data;
      }

      return {
        "success": false,
        "message": data['message'] ?? "Login failed",
        "errors": data['errors'],
      };
    } catch (e) {
      print("LOGIN ERROR: $e");
      return {
        "success": false,
        "message": "Gabim në server: $e",
      };
    }
  }

  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/forgot-password"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "email": email,
        }),
      );

      print("FORGOT PASSWORD STATUS: ${response.statusCode}");
      print("FORGOT PASSWORD BODY: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      }

      return {
        "success": false,
        "message": data['message'] ?? "Request failed",
        "errors": data['errors'],
      };
    } catch (e) {
      print("FORGOT PASSWORD ERROR: $e");
      return {
        "success": false,
        "message": "Gabim në server: $e",
      };
    }
  }

  static Future<void> _saveUserLocally({
    required String name,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setString(_userNameKey, name);
    await prefs.setString(_userEmailKey, email);
    await prefs.setString(_userKeyKey, _buildUserKey(email));
  }

  static String _buildUserKey(String email) {
    final normalized = email.trim().toLowerCase();

    if (normalized.isEmpty) {
      return 'guest';
    }

    return normalized
        .replaceAll('@', '_at_')
        .replaceAll('.', '_dot_')
        .replaceAll(RegExp(r'[^a-z0-9_]+'), '_');
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_isLoggedInKey, false);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userKeyKey);

    await CartService.loadCart();
    await FavoriteService.loadFavorites();
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  static Future<String> getUserKey() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;

    if (!isLoggedIn) return 'guest';

    final savedUserKey = prefs.getString(_userKeyKey);
    if (savedUserKey != null && savedUserKey.isNotEmpty) {
      return savedUserKey;
    }

    final email = prefs.getString(_userEmailKey) ?? '';
    final generated = _buildUserKey(email);

    await prefs.setString(_userKeyKey, generated);
    return generated;
  }
}