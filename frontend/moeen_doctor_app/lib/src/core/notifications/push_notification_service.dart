import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../features/auth/data/staff_auth_session.dart';
import '../network/api_client.dart';

@pragma('vm:entry-point')
Future<void> staffFirebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp();
}

class StaffPushNotificationService {
  StaffPushNotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final StreamController<String> _navigationController =
      StreamController<String>.broadcast();
  static final StreamController<Map<String, dynamic>> _refreshController =
      StreamController<Map<String, dynamic>>.broadcast();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'moeen_staff_push',
    'إشعارات معين للكادر',
    description: 'تنبيهات الدكتور والكادر الدراسي داخل تطبيق معين',
    importance: Importance.high,
    playSound: true,
  );

  static bool _initialized = false;
  static Future<void>? _initializing;
  static StreamSubscription<String>? _tokenRefreshSubscription;
  static String? _pendingNavigationPath;

  static Stream<String> get navigationRequests => _navigationController.stream;
  static Stream<Map<String, dynamic>> get refreshRequests =>
      _refreshController.stream;

  static String? takePendingNavigationPath() {
    final path = _pendingNavigationPath;
    _pendingNavigationPath = null;
    return path;
  }

  static void storePendingNavigationPath(String path) {
    _pendingNavigationPath = path;
  }

  static Future<void> initialize() async {
    if (_initialized) return;
    final initializing = _initializing;
    if (initializing != null) {
      await initializing;
      return;
    }

    _initializing = _initialize();
    try {
      await _initializing;
    } finally {
      _initializing = null;
    }
  }

  static Future<void> _initialize() async {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(
      staffFirebaseMessagingBackgroundHandler,
    );

    const androidSettings = AndroidInitializationSettings('ic_notification');
    const settings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload == null || response.payload!.isEmpty) return;
        try {
          final data = jsonDecode(response.payload!) as Map<String, dynamic>;
          _handleNotificationNavigation(data);
        } catch (error, stackTrace) {
          debugPrint('Failed to parse staff notification payload: $error');
          debugPrintStack(stackTrace: stackTrace);
        }
      },
    );

    final launchDetails = await _localNotifications
        .getNotificationAppLaunchDetails();
    final launchPayload = launchDetails?.notificationResponse?.payload;
    if (launchDetails?.didNotificationLaunchApp == true &&
        launchPayload != null &&
        launchPayload.isNotEmpty) {
      try {
        final data = jsonDecode(launchPayload) as Map<String, dynamic>;
        _pendingNavigationPath = _pathFromNotificationData(data);
      } catch (error, stackTrace) {
        debugPrint('Failed to parse staff launch notification payload: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(_channel);
    await androidPlugin?.requestNotificationsPermission();

    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => _handleNotificationNavigation(message.data),
    );

    try {
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationNavigation(initialMessage.data);
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to read initial staff FCM message: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    _initialized = true;
  }

  static Future<void> registerDevice(StaffAuthSession session) async {
    try {
      await initialize();
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;

      await _sendTokenToBackend(session: session, token: token);

      await _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((newToken) {
        unawaited(_sendTokenToBackend(session: session, token: newToken));
      });
    } catch (error, stackTrace) {
      debugPrint('Staff FCM token is currently unavailable: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static Future<void> unregisterDevice(StaffAuthSession session) async {
    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;
      await ApiClient(token: session.token).delete(
        '/${session.workspace.name}/devices/token',
        data: {'device_token': token},
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to unregister staff FCM token: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      await _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = null;
    }
  }

  static Future<void> _sendTokenToBackend({
    required StaffAuthSession session,
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
      debugPrint('Failed to register staff FCM token: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    _refreshController.add(message.data);
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
      icon: 'ic_notification',
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

  static void _handleNotificationNavigation(Map<String, dynamic> data) {
    final path = _pathFromNotificationData(data);
    if (_navigationController.hasListener) {
      _navigationController.add(path);
    } else {
      _pendingNavigationPath = path;
    }
  }

  static String _pathFromNotificationData(Map<String, dynamic> data) {
    final workspace = data['workspace']?.toString();
    final rawTarget = (data['target_screen'] ?? data['screen'])?.toString();
    final type = data['type']?.toString();
    final target = rawTarget == null || rawTarget == 'notifications'
        ? type
        : rawTarget;

    if (workspace == 'administrative') {
      return switch (target) {
        'subscription' => '/administrative/subscription',
        'ledger' => '/administrative/ledger',
        'students' => '/administrative/students',
        'doctors' => '/administrative/doctors',
        'subjects' => '/administrative/subjects',
        'excuses' || 'excuse' => '/administrative/excuses',
        'reports' || 'attendance' => '/administrative/reports',
        'news' ||
        'announcement' ||
        'alert' ||
        'notifications' => '/administrative/notifications',
        _ => '/administrative/notifications',
      };
    }

    return switch (target) {
      'assignments' || 'assignment' => '/doctor/assignments',
      'quizzes' || 'quiz' => '/doctor/quizzes',
      'grades' || 'grade' => '/doctor/grades',
      'attendance' || 'lecture_report' => '/doctor/attendance',
      'reports' => '/doctor/reports',
      'excuses' || 'excuse' => '/doctor/excuses',
      'inquiries' || 'inquiry' || 'doctor_inquiry' => '/doctor/inquiries',
      'messages' || 'message' => '/doctor/messages',
      'stars' || 'star' => '/doctor/stars',
      'library' || 'resource' || 'resources' => '/doctor/library',
      'news' || 'announcement' || 'poll' || 'alert' => '/doctor/news',
      'rare_case' || 'rare_cases' => '/doctor/rare-cases',
      'volunteer' || 'volunteers' => '/doctor/volunteers',
      'clinical' => '/doctor/clinical',
      'notifications' => '/doctor/notifications',
      _ => '/doctor/notifications',
    };
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
    return 'Moeen staff device';
  }
}
