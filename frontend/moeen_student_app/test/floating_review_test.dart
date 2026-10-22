import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moeen_student_app/src/core/network/api_client.dart';
import 'package:moeen_student_app/src/core/offline/offline_cache_service.dart';
import 'package:moeen_student_app/src/features/auth/data/auth_session.dart';
import 'package:moeen_student_app/src/features/student/data/student_repositories.dart';
import 'package:moeen_student_app/src/features/student/logic/floating_review.dart';

class _Repository extends StudentContentRepository {
  _Repository() : super(ApiClient(), const OfflineCacheService());
  final answers = <Map<String, dynamic>>[];
  bool fail = false;

  @override
  Future<String> recordFlashcardProgress({
    required int itemId,
    required String responseLevel,
    String? clientEventId,
  }) async {
    if (fail) throw StateError('offline');
    answers.add({'item_id': itemId, 'event': clientEventId});
    return 'Saved';
  }
}

const _session = AuthSession(
  token: 'test-only',
  userId: 7,
  workspace: AuthWorkspace.student,
  role: 'student',
  name: 'Student',
  isPracticalDelegate: false,
  hasClinical: false,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('moeen/review_overlay');
  final calls = <MethodCall>[];
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'beginInApp') return 'lease-1';
          if (call.method == 'answers')
            return [
              {
                'item_id': 5,
                'response_level': 'easy',
                'client_event_id': '92000000-0000-4000-8000-000000000001',
              },
            ];
          if (call.method == 'status')
            return {
              'supported': true,
              'permission': false,
              'mode': 'floating',
              'running': false,
              'auto_start': true,
              'pending': 1,
              'seen_ids': [5],
            };
          return null;
        });
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'Status distinguishes denied permission from an active session',
    () async {
      final status = await FloatingReview.status();
      expect(status.supported, isTrue);
      expect(status.permission, isFalse);
      expect(status.running, isFalse);
      expect(status.autoStart, isTrue);
      expect(status.mode, ReviewDisplayMode.floating);
      expect(status.seenIds, [5]);
    },
  );

  test('Older status responses do not opt accounts into automatic review', () {
    expect(FloatingReviewStatus.fromMap({'running': true}).autoStart, isFalse);
    expect(const FloatingReviewStatus().autoStart, isFalse);
  });

  test(
    'Automatic review preference is sent independently of session state',
    () async {
      await FloatingReview.setAutoStart(true);
      expect(calls.last.method, 'setAutoStart');
      expect(calls.last.arguments, isTrue);
      await FloatingReview.setAutoStart(false);
      expect(calls.last.method, 'setAutoStart');
      expect(calls.last.arguments, isFalse);
      await FloatingReview.endSession();
      expect(calls.last.method, 'endSession');
      calls.clear();
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await FloatingReview.setAutoStart(true);
      expect(calls, isEmpty);
    },
  );

  test(
    'Configure binds the account and in-app ownership ends with its lease',
    () async {
      await FloatingReview.configure(_session);
      expect((calls.single.arguments as Map)['account'], 'user_7');
      final lease = await FloatingReview.beginInApp();
      expect(lease, 'lease-1');
      await FloatingReview.endInApp(lease!);
      expect(calls.last.arguments, 'lease-1');
      await FloatingReview.configure(
        _session.copyWith(workspace: AuthWorkspace.delegate),
      );
      expect(calls.last.method, 'stop');
    },
  );

  test(
    'Native answers are acknowledged only after successful synchronization',
    () async {
      final repository = _Repository();
      await FloatingReview.synchronize(_session, repository);
      expect(
        repository.answers.single['event'],
        '92000000-0000-4000-8000-000000000001',
      );
      expect(calls.last.method, 'acknowledge');
      expect((calls.last.arguments as Map)['account'], 'user_7');
      calls.clear();
      repository.fail = true;
      await expectLater(
        FloatingReview.synchronize(_session, repository),
        throwsStateError,
      );
      expect(calls.where((call) => call.method == 'acknowledge'), isEmpty);
    },
  );

  test('Each answer has a distinct version-four event identifier', () {
    final events = List.generate(50, (_) => FloatingReview.eventId());
    expect(events.toSet(), hasLength(50));
    for (final event in events) {
      expect(
        event,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
    }
  });
}
