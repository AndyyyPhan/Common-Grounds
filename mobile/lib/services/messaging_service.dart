// lib/services/messaging_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class MessagingService {
  MessagingService._();
  static final instance = MessagingService._();

  final _users = FirebaseFirestore.instance.collection('users');

  Future<void> initForUser(String uid) async {
    final messaging = FirebaseMessaging.instance;

    // iOS permission prompt; Android auto-grants but this is safe to call.
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (kDebugMode) {
      debugPrint('FCM Permission: ${settings.authorizationStatus}');
    }

    // get & save token
    final token = await messaging.getToken();
    if (token != null) {
      await _users.doc(uid).set({
        'fcmToken': token,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));
    }

    // keep token up to date (rotation)
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await _users.doc(uid).set({
        'fcmToken': newToken,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));
    });
  }
}
