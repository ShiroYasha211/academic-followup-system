import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../features/auth/data/auth_session.dart';
import '../network/api_client.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class PushNotificationService {
  PushNotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'moeen_push',
    'إشعارات معين',
    description: 'إشعارات الحساب والتنبيهات الدراسية داخل تطبيق معين',
    importance: Importance.high,
    playSound: true,
  );

  static bool _initialized = false;
  static StreamSubscription<String>? _tokenRefreshSubscription;

  static Future<void> initialize() async {
    if (_initialized) return;

    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const settings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(settings);

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(_channel);
    await androidPlugin?.requestNotificationsPermission();

    await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    _initialized = true;
  }

  static Future<void> registerDevice(AuthSession session) async {
    await initialize();

    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;

    await _sendTokenToBackend(session: session, token: token);

    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((newToken) {
      unawaited(_sendTokenToBackend(session: session, token: newToken));
    });
  }

  static Future<void> unregisterDevice(AuthSession session) async {
    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;

      await ApiClient(token: session.token).delete(
        '/${session.workspace.name}/devices/token',
        data: {'device_token': token},
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to unregister FCM token: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      await _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = null;
    }
  }

  static Future<void> _sendTokenToBackend({
    required AuthSession session,
    required String token,
  }) async {
    try {
      await ApiClient(token: session.token).post(
        '/${session.workspace.name}/devices/token',
        data: {
          'device_token': token,
          'platform': _platformName,
          'device_name': _deviceName,
          'app_version': '1.0.0+1',
        },
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to register FCM token: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] ?? 'إشعار جديد';
    final body =
        notification?.body ??
        message.data['body'] ??
        message.data['message'] ??
        '';

    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(body.toString()),
    );

    await _localNotifications.show(
      message.hashCode,
      title.toString(),
      body.toString(),
      NotificationDetails(android: androidDetails),
      payload: jsonEncode(message.data),
    );
  }

  static String get _platformName {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'android';
  }

  static String get _deviceName {
    if (kIsWeb) return 'Web';
    if (Platform.isAndroid) return 'Android device';
    if (Platform.isIOS) return 'iOS device';
    return 'Moeen device';
  }
}
