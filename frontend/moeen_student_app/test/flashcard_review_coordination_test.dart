import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:moeen_student_app/src/core/network/api_client.dart';
import 'package:moeen_student_app/src/core/notifications/push_notification_service.dart';
import 'package:moeen_student_app/src/core/offline/connectivity_service.dart';
import 'package:moeen_student_app/src/core/offline/offline_cache_service.dart';
import 'package:moeen_student_app/src/features/student/data/flashcard_local_store.dart';
import 'package:moeen_student_app/src/features/student/data/student_repositories.dart';
import 'package:moeen_student_app/src/features/student/presentation/student_content_screens.dart';

class _Store extends FlashcardLocalStore {
  _Store() : super(accountKey: 'coordination-test');
  FlashcardLocalState state = const FlashcardLocalState();
  @override
  Future<FlashcardLocalState> load() async => state;
  @override
  Future<void> save(FlashcardLocalState value) async {
    state = value;
  }
}

class _Repository extends StudentContentRepository {
  _Repository(this.data) : super(ApiClient(), const OfflineCacheService());
  Map<String, dynamic> data;
  Completer<void>? gate;
  final answers = <int>[];
  @override
  Future<Map<String, dynamic>> flashcardDailyQueue() async {
    if (gate != null) await gate!.future;
    return data;
  }

  @override
  Future<String> recordFlashcardProgress({
    required int itemId,
    required String responseLevel,
    String? clientEventId,
  }) async {
    answers.add(itemId);
    data = {
      ...data,
      'queue': (data['queue'] as List)
          .where((item) => item['item_id'] != itemId)
          .toList(),
    };
    return 'Saved';
  }
}

class _Online extends ConnectivityService {
  @override
  Future<bool> isOnline() async => true;
}

class _ReviewButton extends ConsumerWidget {
  const _ReviewButton();
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () =>
            showStudentFlashcardSmartReviewPrompt(context: context, ref: ref),
        child: const Text('Review'),
      ),
    ),
  );
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const native = MethodChannel('moeen/review_overlay');
  const notifications = MethodChannel(
    'dexterous.com/flutter/local_notifications',
  );
  final calls = <MethodCall>[];
  Map<String, dynamic> card(int id, DateTime at) => {
    'item_id': id,
    'item_type': 'mcq',
    'review_key': 'cycle:$id',
    'scheduled_at': at.toIso8601String(),
    'front_content': 'Question $id',
    'pack_title': 'Test pack',
    'options': ['Correct', 'Other'],
    'correct_option': 0,
  };
  Map<String, dynamic> queue(List<Map<String, dynamic>> items) => {
    'queue': items,
    'settings': {'smart_review_enabled': true},
    'review_schedule_version': 2,
  };

  Future<void> open(
    WidgetTester tester,
    _Store store,
    _Repository repository,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          flashcardLocalStoreProvider.overrideWithValue(store),
          studentContentRepositoryProvider.overrideWithValue(repository),
          connectivityServiceProvider.overrideWithValue(_Online()),
        ],
        child: const MaterialApp(home: _ReviewButton()),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    calls.clear();
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    PushNotificationService.backgroundMode = true;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(native, (
      call,
    ) async {
      calls.add(call);
      if (call.method == 'beginInApp') return 'test-lease';
      if (call.method == 'status')
        return {
          'running': true,
          'mode': 'floating',
          'seen_ids': [],
          'seen_keys': [],
        };
      return null;
    });
    binding.defaultBinaryMessenger.setMockMethodCallHandler(notifications, (
      call,
    ) async {
      if (call.method == 'initialize') return true;
      if (call.method == 'pendingNotificationRequests' ||
          call.method == 'getActiveNotifications')
        return [];
      if (call.method == 'getNotificationAppLaunchDetails')
        return {'notificationLaunchedApp': false};
      return null;
    });
  });
  tearDown(() {
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    PushNotificationService.backgroundMode = false;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(native, null);
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      notifications,
      null,
    );
  });

  testWidgets(
    'Background transition during queue fetch releases the lease without opening a hidden card',
    (tester) async {
      final repository = _Repository(
        queue([card(1, DateTime.now().subtract(const Duration(minutes: 1)))]),
      );
      repository.gate = Completer<void>();
      await open(tester, _Store(), repository);
      await tester.tap(find.text('Review'));
      await tester.pump();
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      repository.gate!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(calls.last.method, 'endInApp');
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant({TargetPlatform.android}),
  );

  testWidgets(
    'Answer handoff records only this occurrence without snoozing the following future card',
    (tester) async {
      final store = _Store();
      final next = card(2, DateTime.now().add(const Duration(minutes: 2)));
      final repository = _Repository(
        queue([
          card(1, DateTime.now().subtract(const Duration(minutes: 1))),
          next,
        ]),
      );
      await open(tester, store, repository);
      await tester.tap(find.text('Review'));
      await tester.pumpAndSettle();
      expect(find.text('Question 1'), findsOneWidget);
      await tester.tap(find.text('Correct'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      expect(repository.answers, [1]);
      expect(store.state.smartReviewCompletedKeys, ['cycle:1']);
      expect(store.state.smartReviewSnoozeUntil, isNull);
      expect(calls.where((call) => call.method == 'snooze'), isEmpty);
      final updates = calls
          .where((call) => call.method == 'updateQueue')
          .toList();
      expect(((updates.last.arguments as Map)['data'] as Map)['queue'], [next]);
      expect(find.byType(Dialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant({TargetPlatform.android}),
  );

  test(
    'Concurrent queue caching and completion keep both the pending schedule and completed occurrence',
    () async {
      final store = _Store();
      final next = card(2, DateTime.now().add(const Duration(minutes: 2)));
      await Future.wait([
        store.cacheDailyQueue(queue([next])),
        store.markSmartReviewItemCompletedToday(1, reviewKey: 'cycle:1'),
        store.cacheHome({'packs': []}),
      ]);
      expect(store.state.smartReviewCompletedKeys, ['cycle:1']);
      expect(store.state.dailyQueue?['queue'], [next]);
    },
  );
}
