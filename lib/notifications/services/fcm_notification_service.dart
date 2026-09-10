import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';
import '../domain/models/device_token_model.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('Handling background message: ${message.messageId}');
  }
}

class FcmNotificationService {
  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final Logger _logger = Logger();

  FcmNotificationService({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
    FlutterLocalNotificationsPlugin? localNotifications,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _localNotifications = localNotifications ?? FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
    'sozotap_sos_channel',
    'Emergency SOS Alerts',
    description: 'High priority notifications for emergency SOS broadcasts.',
    importance: Importance.max,
    playSound: true,
  );

  Future<void> initialize({
    required Function(String route) onNavigateToRoute,
  }) async {
    try {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Initialize local notifications for foreground display
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();
      const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            onNavigateToRoute(payload);
          }
        },
      );

      // Create Android Notification Channel
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_androidChannel);

      // Foreground message listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          _logger.i('Foreground FCM message received: ${message.notification?.title}');
        }
        _showForegroundNotification(message);
      });

      // Background message opened app listener
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        final route = message.data['route'] as String? ?? message.data['deepLink'] as String?;
        if (route != null && route.isNotEmpty) {
          onNavigateToRoute(route);
        }
      });

      // Terminated state initial message check
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        final route = initialMessage.data['route'] as String? ?? initialMessage.data['deepLink'] as String?;
        if (route != null && route.isNotEmpty) {
          onNavigateToRoute(route);
        }
      }

      // Listen for token refreshes
      _messaging.onTokenRefresh.listen((newToken) {
        registerDeviceToken(newToken);
      });

      if (kDebugMode) _logger.i('FcmNotificationService initialized successfully.');
    } catch (e, stackTrace) {
      _logger.e('Failed to initialize FcmNotificationService', error: e, stackTrace: stackTrace);
    }
  }

  Future<bool> requestNotificationPermissions() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      final isGranted = settings.authorizationStatus == AuthorizationStatus.authorized;
      if (isGranted) {
        final token = await _messaging.getToken();
        if (token != null) {
          await registerDeviceToken(token, permissionStatus: 'granted');
        }
      }
      return isGranted;
    } catch (e) {
      _logger.e('Error requesting notification permission: $e');
      return false;
    }
  }

  Future<void> registerDeviceToken(String token, {String permissionStatus = 'granted'}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final tokenId = sha256.convert(utf8.encode(token)).toString().substring(0, 20);
      final deviceIdHash = sha256.convert(utf8.encode('${user.uid}_${defaultTargetPlatform.name}')).toString();

      final now = DateTime.now();

      final deviceToken = DeviceTokenModel(
        tokenId: tokenId,
        token: token,
        platform: defaultTargetPlatform.name,
        appVersion: '1.0.0',
        deviceIdHash: deviceIdHash,
        createdAt: now,
        updatedAt: now,
        lastSeenAt: now,
        enabled: true,
        notificationPermissionStatus: permissionStatus,
      );

      await _firestore
          .collection('device_tokens')
          .doc(user.uid)
          .collection('tokens')
          .doc(tokenId)
          .set(deviceToken.toFirestore(), SetOptions(merge: true));

      if (kDebugMode) {
        _logger.i('FCM device token registered safely for user ${user.uid}');
      }
    } catch (e, stackTrace) {
      _logger.e('Error registering device token in Firestore', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> disableTokenOnLogout() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final token = await _messaging.getToken();
      if (token != null) {
        final tokenId = sha256.convert(utf8.encode(token)).toString().substring(0, 20);
        await _firestore
            .collection('device_tokens')
            .doc(user.uid)
            .collection('tokens')
            .doc(tokenId)
            .update({
          'enabled': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      _logger.w('Error disabling FCM token on logout: $e');
    }
  }

  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      final route = message.data['route'] as String? ?? message.data['deepLink'] as String? ?? '/';

      _localNotifications.show(
        notification.hashCode,
        notification.title ?? 'SOZOTAP Notification',
        notification.body ?? 'Emergency notification received.',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.max,
            priority: Priority.high,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(presentAlert: true, presentSound: true),
        ),
        payload: route,
      );
    }
  }
}
