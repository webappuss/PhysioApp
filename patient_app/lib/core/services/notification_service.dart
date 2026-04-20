import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';

// Top-level handler for background messages (must be a top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM Background] ${message.notification?.title}: ${message.notification?.body}');
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref.watch(apiClientProvider));
});

class NotificationService {
  final ApiClient _api;
  NotificationService(this._api);

  Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Request permission (iOS + Android 13+)
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      await _registerToken();
    }

    // Refresh token when it rotates
    FirebaseMessaging.instance.onTokenRefresh.listen(_sendTokenToServer);

    // Handle notification tap when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap from background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if app was opened from a terminated notification
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _handleNotificationTap(initial);
  }

  Future<void> _registerToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) await _sendTokenToServer(token);
  }

  Future<void> _sendTokenToServer(String token) async {
    try {
      await _api.post('/patient/fcm-token', data: {
        'fcm_token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
      });
    } catch (_) {
      // Non-critical — retry on next launch
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM Foreground] ${message.notification?.title}');
    // In-app notification handled by the UI layer
  }

  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] as String?;
    final id   = data['id'] as String?;

    // Navigation handled via GoRouter — push route based on type
    switch (type) {
      case 'booking_confirmed':
      case 'booking_reminder':
        if (id != null) _pendingRoute = '/bookings/$id';
      case 'checkin_reminder':
        _pendingRoute = '/checkin';
      case 'payment_success':
        if (id != null) _pendingRoute = '/bookings/$id';
    }
  }

  String? _pendingRoute;

  /// Call from app shell after auth is confirmed to consume pending deep-link
  String? consumePendingRoute() {
    final r = _pendingRoute;
    _pendingRoute = null;
    return r;
  }
}
