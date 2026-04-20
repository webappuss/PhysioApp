import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM Background] ${message.notification?.title}');
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref.watch(apiClientProvider));
});

class NotificationService {
  final ApiClient _api;
  NotificationService(this._api);

  Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true, badge: true, sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      await _registerToken();
    }

    FirebaseMessaging.instance.onTokenRefresh.listen(_sendToken);
    FirebaseMessaging.onMessage.listen(_handleForeground);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _handleTap(initial);
  }

  Future<void> _registerToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) await _sendToken(token);
  }

  Future<void> _sendToken(String token) async {
    try {
      await _api.post('/physio/fcm-token', data: {
        'fcm_token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
      });
    } catch (_) {}
  }

  void _handleForeground(RemoteMessage message) {
    debugPrint('[FCM Foreground] ${message.notification?.title}');
  }

  String? _pendingRoute;

  void _handleTap(RemoteMessage message) {
    final type = message.data['type'] as String?;
    final id   = message.data['id'] as String?;

    switch (type) {
      case 'new_booking':
      case 'booking_reminder':
        if (id != null) _pendingRoute = '/bookings/$id';
      case 'booking_cancelled':
        _pendingRoute = '/bookings';
    }
  }

  String? consumePendingRoute() {
    final r = _pendingRoute;
    _pendingRoute = null;
    return r;
  }
}
