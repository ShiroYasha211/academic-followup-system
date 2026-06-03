import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

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
  static const int _flashcardReviewNotificationId = 64021;
  static final StreamController<String> _navigationController =
      StreamController<String>.broadcast();
  static final StreamController<Map<String, dynamic>> _refreshController =
      StreamController<Map<String, dynamic>>.broadcast();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'moeen_push',
    'إشعارات معين',
    description: 'إشعارات الحساب والتنبيهات الدراسية داخل تطبيق معين',
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
    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.UTC);
    } catch (_) {}

    // Initialize local notifications first (offline-first, no Firebase dependency)
    try {
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
            debugPrint('Failed to parse notification payload: $error');
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
          debugPrint('Failed to parse launch notification payload: $error');
          debugPrintStack(stackTrace: stackTrace);
        }
      }

      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.createNotificationChannel(_channel);
      await androidPlugin?.requestNotificationsPermission();
      await androidPlugin?.requestExactAlarmsPermission();
    } catch (e, s) {
      debugPrint('Failed to initialize local notifications: $e\n$s');
    }

    // Initialize Firebase (wrapped in try-catch to keep app functional if FCM fails)
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

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
      FirebaseMessaging.onMessageOpenedApp.listen(
        (message) => _handleNotificationNavigation(message.data),
      );

      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationNavigation(initialMessage.data);
      }
    } catch (e, s) {
      debugPrint('Failed to initialize Firebase Messaging: $e\n$s');
    }

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

  static Future<void> scheduleFlashcardSmartReview({
    required Duration delay,
  }) async {
    try {
      await initialize();
      if (delay <= Duration.zero) return;

      final androidDetails = AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_notification',
        styleInformation: const BigTextStyleInformation(
          'لديك كرت سريع جاهز للمراجعة الآن.',
        ),
      );

      try {
        await _localNotifications.zonedSchedule(
          _flashcardReviewNotificationId,
          'One Line Shot',
          'لديك كرت سريع جاهز للمراجعة الآن.',
          tz.TZDateTime.now(tz.UTC).add(delay),
          NotificationDetails(android: androidDetails),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: jsonEncode({
            'screen': 'one_line_shot_quick_review',
            'type': 'one_line_shot',
          }),
        );
      } catch (error) {
        debugPrint('Failed to schedule exact review alarm, trying inexact: $error');
        await _localNotifications.zonedSchedule(
          _flashcardReviewNotificationId,
          'One Line Shot',
          'لديك كرت سريع جاهز للمراجعة الآن.',
          tz.TZDateTime.now(tz.UTC).add(delay),
          NotificationDetails(android: androidDetails),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: jsonEncode({
            'screen': 'one_line_shot_quick_review',
            'type': 'one_line_shot',
          }),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to schedule flashcard review notification: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static Future<void> cancelFlashcardSmartReview() async {
    try {
      await initialize();
      await _localNotifications.cancel(_flashcardReviewNotificationId);
    } catch (error, stackTrace) {
      debugPrint('Failed to cancel flashcard review notification: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
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
    final rawTargetScreen = (data['target_screen'] ?? data['screen'])
        ?.toString();
    final notificationType = data['type']?.toString();
    final targetScreen =
        rawTargetScreen == null || rawTargetScreen == 'notifications' || rawTargetScreen.isEmpty
        ? (notificationType ?? '')
        : rawTargetScreen;
    final scheduleItemId =
        data['schedule_item_id']?.toString() ??
        data['study_item_id']?.toString() ??
        data['item_id']?.toString();

    if ((targetScreen == 'study_session' || targetScreen == 'study_reminder') &&
        scheduleItemId != null &&
        scheduleItemId.isNotEmpty) {
      return '/student/study-center/$scheduleItemId/session';
    }

    final inquiryId = data['inquiry_id']?.toString();
    if (targetScreen == 'inquiry' && inquiryId != null && inquiryId.isNotEmpty) {
      return '/student/inquiries/$inquiryId';
    }

    final assignmentId = data['assignment_id']?.toString();
    if (targetScreen == 'assignment' && assignmentId != null && assignmentId.isNotEmpty) {
      return '/student/assignments/$assignmentId';
    }

    final conversationId = data['conversation_id']?.toString() ??
        data['doctor_conversation_id']?.toString();
    if (targetScreen == 'message' && conversationId != null && conversationId.isNotEmpty) {
      return '/student/messages/$conversationId';
    }

    final packId = data['pack_id']?.toString();
    if ((targetScreen == 'flashcard_assignment' || targetScreen == 'flashcard_review' || targetScreen == 'flashcards') &&
        packId != null &&
        packId.isNotEmpty) {
      return '/student/flashcards/$packId';
    }

    final subjectId = data['subject_id']?.toString();
    if (subjectId != null && subjectId.isNotEmpty) {
      if (targetScreen == 'attendance' ||
          targetScreen == 'absence_warning' ||
          targetScreen == 'lecture_report' ||
          targetScreen == 'excuse') {
        return '/student/subjects/$subjectId?tab=attendance';
      }
    }

    return switch (targetScreen) {
      'study_center' || 'study' || 'study_reminder' => '/student/study-center',
      'quizzes' || 'quiz' => '/student/quizzes',
      'assignments' || 'assignment' => '/student/assignments',
      'schedule' || 'schedules' => '/student/schedules',
      'reminders' || 'reminder' => '/student/reminders',
      'resources' || 'resource' => '/student/resources',
      'library' => '/student/library',
      'authorized_grades' || 'grade_delegation' => '/student/authorized-grades',
      'stars' || 'star' || 'tree_farm' => '/student/stars',
      'inquiries' || 'inquiry' || 'doctor_inquiry' => '/student/inquiries',
      'messages' || 'message' => '/student/messages',
      'news' || 'news_hub' || 'announcement' || 'alert' || 'absence_warning' => '/student/news',
      'rare_case' || 'rare_cases' => '/student/clinical/rare-cases',
      'clinical_assignment' => '/student/clinical/assignments',
      'clinical' => '/student/clinical',
      'one_line_shot' ||
      'one_line_shot_quick_review' ||
      'flashcards' ||
      'flashcard_review' ||
      'flashcard_assignment' => '/student/flashcards/quick-review',
      'notifications' => '/student/notifications',
      _ => '/student/notifications',
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
    return 'Moeen device';
  }

  static Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    try {
      await initialize();
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
      );
      final androidDetails = AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_notification',
        playSound: true,
      );
      await _localNotifications.show(
        DateTime.now().millisecond,
        title,
        body,
        NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        ),
      );
    } catch (error) {
      debugPrint('Failed to show local notification: $error');
    }
  }

  static Future<void> scheduleFocusWarningNotification({
    required Duration delay,
    required Duration countdownDuration,
  }) async {
    try {
      await initialize();
      final targetTime = DateTime.now().add(delay).add(countdownDuration);

      final androidDetails = AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_notification',
        playSound: true,
        usesChronometer: true,
        chronometerCountDown: true,
        when: targetTime.millisecondsSinceEpoch,
        ongoing: true,
        timeoutAfter: countdownDuration.inMilliseconds, // يختفي تلقائياً بعد انتهاء العد التنازلي
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
      );

      // 1. جدولة إشعار التحذير بعد 10 ثوانٍ
      try {
        await _localNotifications.zonedSchedule(
          64022,
          '🚨 شجرتك في خطر الجفاف!',
          'لقد غادرت وضع التركيز! عد للتطبيق لإنقاذ شجرتك.',
          tz.TZDateTime.now(tz.UTC).add(delay),
          NotificationDetails(
            android: androidDetails,
            iOS: iosDetails,
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (error) {
        debugPrint('Failed to schedule exact alarm, trying inexact: $error');
        await _localNotifications.zonedSchedule(
          64022,
          '🚨 شجرتك في خطر الجفاف!',
          'لقد غادرت وضع التركيز! عد للتطبيق لإنقاذ شجرتك.',
          tz.TZDateTime.now(tz.UTC).add(delay),
          NotificationDetails(
            android: androidDetails,
            iOS: iosDetails,
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }

      // 2. جدولة إشعار الفشل الفعلي بعد انتهاء المهلة (10 ثوانٍ + 30 ثانية = 40 ثانية)
      final failureAndroidDetails = AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_notification',
        playSound: true,
        ongoing: false,
      );

      final failureDelay = delay + countdownDuration;
      try {
        await _localNotifications.zonedSchedule(
          64024,
          '🥀 للأسف! جفت شجرتك',
          'لقد قضيت وقتاً طويلاً خارج التطبيق وفشلت الجلسة.',
          tz.TZDateTime.now(tz.UTC).add(failureDelay),
          NotificationDetails(
            android: failureAndroidDetails,
            iOS: iosDetails,
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (error) {
        await _localNotifications.zonedSchedule(
          64024,
          '🥀 للأسف! جفت شجرتك',
          'لقد قضيت وقتاً طويلاً خارج التطبيق وفشلت الجلسة.',
          tz.TZDateTime.now(tz.UTC).add(failureDelay),
          NotificationDetails(
            android: failureAndroidDetails,
            iOS: iosDetails,
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }

    } catch (error, stackTrace) {
      debugPrint('Failed to schedule focus warning notification: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static Future<void> cancelFocusWarningNotification() async {
    try {
      await initialize();
      await _localNotifications.cancel(64022);
      await _localNotifications.cancel(64024);
    } catch (error) {
      debugPrint('Failed to cancel focus warning notification: $error');
    }
  }
}
