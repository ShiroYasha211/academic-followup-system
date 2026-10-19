import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:moeen_student_app/src/core/network/api_client.dart';
import 'package:moeen_student_app/src/core/offline/offline_cache_service.dart';
import 'package:moeen_student_app/src/features/auth/data/auth_session.dart';
import 'package:moeen_student_app/src/features/student/data/flashcard_local_store.dart';
import 'package:moeen_student_app/src/features/student/data/student_repositories.dart';
import 'package:moeen_student_app/src/features/student/logic/one_line_notification_scheduler.dart';

class _Store extends FlashcardLocalStore {
  FlashcardLocalState state = const FlashcardLocalState();
  Map<String, dynamic>? cached;
  @override
  Future<T> withScheduleLock<T>(Future<T> Function() operation) => operation();
  @override
  Future<FlashcardLocalState> load() async => state;
  @override
  Future<void> cacheOneLineNotifications(Map<String, dynamic> data) async {
    cached = data;
  }

  @override
  Future<Map<String, dynamic>?> loadOneLineNotifications() async => cached;
  @override
  Future<void> saveOneLineScheduleState({
    required String date,
    required String signature,
    required List<Map<String, dynamic>> items,
  }) async {
    state = state.copyWith(
      oneLineScheduleDate: date,
      oneLineScheduleSignature: signature,
      oneLineScheduledItems: items,
    );
  }
}

class _Repository extends StudentContentRepository {
  _Repository(this.data) : super(ApiClient(), const OfflineCacheService());
  final Map<String, dynamic> data;
  int calls = 0;
  @override
  Future<Map<String, dynamic>> flashcardOneLineNotifications({
    bool reschedule = false,
  }) async {
    calls++;
    return data;
  }
}

final _now = DateTime.utc(2026, 10, 19, 8);
Map<String, dynamic> _source({int count = 1, bool enabled = true}) => {
  'date': '2026-10-19',
  'settings': {'one_line_notifications_enabled': enabled},
  'items': List.generate(
    count,
    (index) => {
      'item_id': index + 1,
      'notification_body': 'Line $index',
      'scheduled_at': _now.add(Duration(minutes: index + 1)).toIso8601String(),
    },
  ),
};

void main() {
  test('Failed items remain failed and are retried on the same day', () async {
    final store = _Store();
    var attempts = 0;
    final scheduler = OneLineNotificationScheduler(
      _Repository(_source()),
      store,
      now: () => _now,
      reconcile: (items) async => items
          .map(
            (item) => {
              ...item,
              'schedule_status': ++attempts == 1 ? 'failed' : 'scheduled',
            },
          )
          .toList(),
    );
    expect(await scheduler.sync(), 0);
    expect(
      store.state.oneLineScheduledItems.single['schedule_status'],
      'failed',
    );
    expect(await scheduler.sync(), 1);
    expect(attempts, 2);
  });

  test('Platform failure does not save a successful schedule', () async {
    final store = _Store();
    final scheduler = OneLineNotificationScheduler(
      _Repository(_source()),
      store,
      now: () => _now,
      reconcile: (_) async => throw StateError('platform unavailable'),
    );
    await expectLater(scheduler.sync(), throwsStateError);
    expect(store.state.oneLineScheduleSignature, isNull);
  });

  test('All 100 messages have distinct notification IDs', () async {
    final store = _Store();
    final scheduler = OneLineNotificationScheduler(
      _Repository(_source(count: 100)),
      store,
      now: () => _now,
      reconcile: (items) async => items
          .map((item) => {...item, 'schedule_status': 'scheduled'})
          .toList(),
    );
    expect(await scheduler.sync(), 100);
    expect(
      store.state.oneLineScheduledItems
          .map((item) => item['notification_id'])
          .toSet(),
      hasLength(100),
    );
  });

  test('Disabling cancels an existing schedule during the same day', () async {
    final store = _Store();
    var cancelled = false;
    final scheduler = OneLineNotificationScheduler(
      _Repository(_source(enabled: false)),
      store,
      now: () => _now,
      cancel: () async => cancelled = true,
    );
    expect(await scheduler.sync(), 0);
    expect(cancelled, isTrue);
    expect(store.state.oneLineScheduledItems, isEmpty);
  });

  test(
    'Forced refresh waits behind an existing sync rather than being dropped',
    () async {
      final store = _Store();
      final repository = _Repository(_source());
      final gate = Completer<void>();
      var calls = 0;
      final scheduler = OneLineNotificationScheduler(
        repository,
        store,
        now: () => _now,
        reconcile: (items) async {
          if (++calls == 1) await gate.future;
          return items
              .map((item) => {...item, 'schedule_status': 'scheduled'})
              .toList();
        },
      );
      final first = scheduler.sync();
      final second = scheduler.sync(force: true);
      gate.complete();
      expect(await first, 1);
      expect(await second, 1);
      expect(repository.calls, 2);
    },
  );

  test('Expired account does not schedule old messages', () async {
    var called = false;
    final scheduler = OneLineNotificationScheduler(
      _Repository(_source()),
      _Store(),
      now: () => _now,
      isCurrentSession: () async => false,
      reconcile: (items) async {
        called = true;
        return items;
      },
    );
    expect(await scheduler.sync(), 0);
    expect(called, isFalse);
  });

  test('Account storage keys are unique and survive a new login token', () {
    AuthSession session(int id, String token) => AuthSession(
      userId: id,
      token: token,
      workspace: AuthWorkspace.student,
      role: 'student',
      name: 'Student',
      isPracticalDelegate: false,
      hasClinical: false,
    );
    expect(
      FlashcardLocalStore.keyFor(session(1, 'a')),
      FlashcardLocalStore.keyFor(session(1, 'b')),
    );
    expect(
      FlashcardLocalStore.keyFor(session(1, 'a')),
      isNot(FlashcardLocalStore.keyFor(session(2, 'a'))),
    );
  });

  test(
    'Three hundred future requests use distinct IDs across three days',
    () async {
      final data = _source(count: 100);
      data['items'] = [
        for (var day = 0; day < 3; day++)
          ...List.generate(
            100,
            (index) => {
              'item_id': day * 100 + index,
              'notification_body': 'Line',
              'scheduled_at': _now
                  .add(Duration(days: day, minutes: index + 1))
                  .toIso8601String(),
            },
          ),
      ];
      final store = _Store();
      final scheduler = OneLineNotificationScheduler(
        _Repository(data),
        store,
        now: () => _now,
        reconcile: (items) async => items
            .map((item) => {...item, 'schedule_status': 'scheduled'})
            .toList(),
      );
      expect(await scheduler.sync(), 300);
      expect(
        store.state.oneLineScheduledItems
            .map((item) => item['notification_id'])
            .toSet(),
        hasLength(300),
      );
    },
  );

  test(
    'Late response cannot replace a newer manually generated plan',
    () async {
      final old = _source()..['generated_at'] = '2026-10-19T07:00:00Z';
      final newer = _source()..['generated_at'] = '2026-10-19T07:30:00Z';
      (newer['items'] as List).first['notification_body'] = 'New line';
      final store = _Store()..cached = newer;
      final scheduler = OneLineNotificationScheduler(
        _Repository(old),
        store,
        now: () => _now,
        reconcile: (items) async => items
            .map((item) => {...item, 'schedule_status': 'scheduled'})
            .toList(),
      );
      await scheduler.sync(data: old);
      expect(
        store.state.oneLineScheduledItems.single['notification_body'],
        'New line',
      );
    },
  );
}
