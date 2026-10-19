import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:moeen_student_app/src/core/notifications/push_notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  var enabled = true;
  var exact = false;
  var fail = false;
  var calls = 0;
  var failuresRemaining = 0;
  final pending = <int, Map<String, dynamic>>{};
  final item = <String, dynamic>{
    'notification_id': 64101,
    'item_id': 1,
    'notification_title': 'Pack',
    'notification_body': 'Line',
    'scheduled_at': DateTime.now()
        .add(const Duration(hours: 1))
        .toIso8601String(),
  };

  setUp(() {
    enabled = true;
    exact = false;
    fail = false;
    calls = 0;
    failuresRemaining = 0;
    pending.clear();
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    PushNotificationService.backgroundMode = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'initialize':
              return true;
            case 'getNotificationAppLaunchDetails':
              return {'notificationLaunchedApp': false};
            case 'areNotificationsEnabled':
              return enabled;
            case 'canScheduleExactNotifications':
              return exact;
            case 'pendingNotificationRequests':
              return pending.values.toList();
            case 'getActiveNotifications':
              return [];
            case 'zonedSchedule':
              calls++;
              if (fail || failuresRemaining-- > 0)
                throw PlatformException(code: 'schedule_failed');
              final data = Map<String, dynamic>.from(call.arguments as Map);
              pending[data['id'] as int] = {
                'id': data['id'],
                'title': data['title'],
                'body': data['body'],
                'payload': data['payload'],
              };
              return null;
            case 'cancel':
              pending.remove((call.arguments as Map)['id']);
              return null;
            default:
              return null;
          }
        });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    PushNotificationService.backgroundMode = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'Unchanged system request is retained and labeled approximate without exact access',
    () async {
      var result =
          await PushNotificationService.reconcileOneLineShotNotifications(
            items: [item],
          );
      expect(result.single['schedule_status'], 'scheduled');
      expect(result.single['precision'], 'approximate');
      result = await PushNotificationService.reconcileOneLineShotNotifications(
        items: [item],
      );
      expect(calls, 1);
      expect(result.single['schedule_status'], 'scheduled');
    },
  );

  test(
    'Denied notification permission cancels pending request and reports blocked',
    () async {
      await PushNotificationService.reconcileOneLineShotNotifications(
        items: [item],
      );
      enabled = false;
      final result =
          await PushNotificationService.reconcileOneLineShotNotifications(
            items: [item],
          );
      expect(result.single['schedule_status'], 'blocked');
      expect(pending, isEmpty);
    },
  );

  test(
    'Native scheduling failure is not reported as a registered alarm',
    () async {
      fail = true;
      final result =
          await PushNotificationService.reconcileOneLineShotNotifications(
            items: [item],
          );
      expect(result.single['schedule_status'], 'failed');
      expect(pending, isEmpty);
    },
  );

  test(
    'Exact-alarm failure falls back and records approximate precision',
    () async {
      exact = true;
      failuresRemaining = 1;
      final result =
          await PushNotificationService.reconcileOneLineShotNotifications(
            items: [item],
          );
      expect(calls, 2);
      expect(result.single['schedule_status'], 'scheduled');
      expect(result.single['precision'], 'approximate');
      expect(pending.values.single['payload'], contains('approximate'));
    },
  );
}
