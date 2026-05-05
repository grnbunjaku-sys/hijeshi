import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> saveUser({
    required String email,
    required String name,
    String? fcmToken,
  }) async {
    try {
      final docId = email.toLowerCase();

      await _firestore.collection('users').doc(docId).set({
        'email': email,
        'name': name,
        'fcmToken': fcmToken,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (kDebugMode) {
        print("✅ User saved to Firestore: $email");
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error saving user: $e");
      }
    }
  }

  static Future<void> updateFcmToken({
    required String email,
    required String fcmToken,
  }) async {
    try {
      final docId = email.toLowerCase();

      await _firestore.collection('users').doc(docId).set({
        'fcmToken': fcmToken,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (kDebugMode) {
        print("✅ FCM token updated for $email");
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error updating FCM token: $e");
      }
    }
  }
}