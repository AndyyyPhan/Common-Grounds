// lib/services/messaging_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Top-level function for handling background messages
/// Must be top-level or static to work with Firebase Messaging
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📬 Background message received: ${message.messageId}');
  debugPrint('📬 Title: ${message.notification?.title}');
  debugPrint('📬 Body: ${message.notification?.body}');
  debugPrint('📬 Data: ${message.data}');
}

class MessagingService {
  MessagingService._();
  static final instance = MessagingService._();

  final _users = FirebaseFirestore.instance.collection('users');
  final _localNotifications = FlutterLocalNotificationsPlugin();

  // Global navigation key for navigation from notifications
  static GlobalKey<NavigatorState>? navigatorKey;

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

    // Initialize local notifications for Android foreground messages
    await _initializeLocalNotifications();

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📬 Foreground message received: ${message.messageId}');
      _handleForegroundMessage(message);
    });

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📬 Notification tapped (background): ${message.messageId}');
      _handleNotificationTap(message);
    });

    // Check if app was opened from a notification (terminated state)
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint(
        '📬 App opened from notification: ${initialMessage.messageId}',
      );
      _handleNotificationTap(initialMessage);
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

  /// Initialize local notifications for Android
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('📬 Local notification tapped: ${response.payload}');
        // Handle notification tap from local notification
        if (response.payload != null) {
          _navigateToWavesTab();
        }
      },
    );

    // Create Android notification channel for matches
    const androidChannel = AndroidNotificationChannel(
      'matches',
      'Match Notifications',
      description: 'Notifications for new mutual matches',
      importance: Importance.high,
      sound: RawResourceAndroidNotificationSound('notification'),
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);
  }

  /// Handle foreground messages (show local notification)
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    // Show local notification
    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'matches',
          'Match Notifications',
          channelDescription: 'Notifications for new mutual matches',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFF4CAF50), // Green for friendship
          sound: RawResourceAndroidNotificationSound('notification'),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data['type'],
    );
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    final type = message.data['type'];

    if (type == 'mutual_match') {
      // Navigate to Waves tab (Matched section)
      _navigateToWavesTab();
    }
  }

  /// Navigate to the Waves tab
  void _navigateToWavesTab() {
    final navigator = navigatorKey?.currentState;
    if (navigator == null) {
      debugPrint('📬 Navigator not available yet');
      return;
    }

    // Navigate to waves page
    // The navigation logic depends on your app structure
    // For now, we'll just log it - you can customize this
    debugPrint('📬 Would navigate to /waves tab');
  }
}
