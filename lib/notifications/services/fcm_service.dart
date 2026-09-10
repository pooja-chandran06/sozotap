import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';
import '../../models/device_token.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Safe background message handler
  final logger = Logger();
  logger.i('Handling background FCM message: ${message.messageId}');
}

class FcmService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();

  StreamSubscription<String>? _tokenRefreshSub;

  Future<void> initialize({Function(String route)? onNavigate}) async {
    // 1. Configure Background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 2. Setup Local Notifications for Foreground Presentation
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null && onNavigate != null) {
          onNavigate(response.payload!);
        }
      },
    );

    // 3. Create Android High Priority Notification Channel
    const androidChannel = AndroidNotificationChannel(
      'emergency_sos_channel',
      'SOZOTAP SOS Emergency Alerts',
      description: 'High-priority notifications for active SOS emergency alerts.',
      importance: Importance.max,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // 4. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _logger.i('Received foreground FCM message: ${message.notification?.title}');
      final notification = message.notification;
      final data = message.data;

      if (notification != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              androidChannel.id,
              androidChannel.name,
              channelDescription: androidChannel.description,
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: const DarwinNotificationDetails(presentAlert: true, presentSound: true, presentBadge: true),
          ),
          payload: data['route'] ?? '/notifications',
        );
      }
    });

    // 5. Handle App Opened from Background / Terminated state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final route = message.data['route'];
      if (route != null && onNavigate != null) {
        onNavigate(route);
      }
    });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      final route = initialMessage.data['route'];
      if (route != null && onNavigate != null) {
        onNavigate(route);
      }
    }

    // 6. Register Token if logged in
    await registerDeviceToken();

    // 7. Token refresh listener
    _tokenRefreshSub = _messaging.onTokenRefresh.listen((newToken) {
      _saveTokenToFirestore(newToken);
    });
  }

  Future<NotificationSettings> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true,
    );
    _logger.i('User notification permission status: ${settings.authorizationStatus}');
    await registerDeviceToken();
    return settings;
  }

  Future<void> registerDeviceToken() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToFirestore(token);
      }
    } catch (e) {
      _logger.e('Failed to register FCM device token', error: e);
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final settings = await _messaging.getNotificationSettings();
      final tokenId = token.hashCode.toString();

      final deviceToken = DeviceToken(
        tokenId: tokenId,
        ownerUserId: user.uid,
        token: token,
        platform: Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'web'),
        appVersion: '1.0.0',
        notificationPermissionStatus: settings.authorizationStatus.name,
        enabled: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastSeenAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('device_tokens')
          .doc(tokenId)
          .set(deviceToken.toMap(), SetOptions(merge: true));

      _logger.i('Successfully registered FCM token for user ${user.uid}');
    } catch (e) {
      _logger.e('Failed to save device token to Firestore', error: e);
    }
  }

  void dispose() {
    _tokenRefreshSub?.cancel();
  }
}
