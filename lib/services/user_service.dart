import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> saveUser({
    required String email,
    required String name,
    String? fcmToken,
  }) async {
    final docId = email.toLowerCase();

    await _firestore.collection('users').doc(docId).set({
      'email': email,
      'name': name,
      'fcmToken': fcmToken,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> updateFcmToken({
    required String email,
    required String fcmToken,
  }) async {
    final docId = email.toLowerCase();

    await _firestore.collection('users').doc(docId).set({
      'email': email,
      'fcmToken': fcmToken,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}