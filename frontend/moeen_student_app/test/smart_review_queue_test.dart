import 'package:flutter_test/flutter_test.dart';
import 'package:moeen_student_app/src/features/student/data/flashcard_local_store.dart';
import 'package:moeen_student_app/src/features/student/logic/smart_review_queue.dart';

void main() {
  final now = DateTime(2026, 10, 22, 9, 5);
  final future = {
    'item_id': 2,
    'item_type': 'mcq',
    'review_key': 'round-1:2',
    'scheduled_at': DateTime(2026, 10, 22, 9, 30).toIso8601String(),
  };
  final old = {
    'item_id': 1,
    'item_type': 'mcq',
    'review_key': 'round-1:1',
    'scheduled_at': DateTime(2026, 10, 22, 9).toIso8601String(),
  };
  final data = {
    'date': '2026-10-22',
    'queue': [future],
    'reviewed_today': [old],
  };

  test(
    'No old card is substituted while the next card is still in the future',
    () {
      const state = FlashcardLocalState(
        smartReviewAutoRestart: true,
        dailyReviewRestartDate: '2026-10-22',
      );
      expect(SmartReviewQueue.pending(data, state, now: now), hasLength(1));
      expect(
        SmartReviewQueue.pending(data, state, availableOnly: true, now: now),
        isEmpty,
      );
    },
  );

  test('An empty server queue never fabricates local repeat times', () {
    expect(
      SmartReviewQueue.pending(
        {...data, 'queue': []},
        const FlashcardLocalState(smartReviewAutoRestart: true),
        now: now,
      ),
      isEmpty,
    );
  });

  test('Completing an occurrence does not hide an intentional later round', () {
    const state = FlashcardLocalState(
      smartReviewSeenDate: '2026-10-22',
      smartReviewSeenItemIds: [1],
      smartReviewCompletedKeys: ['round-1:1'],
    );
    final repeat = {...old, 'review_key': 'round-2:1'};
    final result = SmartReviewQueue.pending(
      {
        'queue': [old, repeat],
      },
      state,
      now: now,
      availableOnly: true,
    );
    expect(result.single['review_key'], 'round-2:1');
  });

  test(
    'Availability changes at the actual scheduled instant without rebuilding times',
    () {
      final at = DateTime.parse(future['scheduled_at']! as String);
      const state = FlashcardLocalState();
      expect(
        SmartReviewQueue.pending(
          data,
          state,
          now: at.subtract(const Duration(seconds: 1)),
          availableOnly: true,
        ),
        isEmpty,
      );
      expect(
        SmartReviewQueue.pending(
          data,
          state,
          now: at,
          availableOnly: true,
        ).single['scheduled_at'],
        future['scheduled_at'],
      );
    },
  );

  test('Quiet windows and stale cached days do not create ready cards', () {
    expect(
      SmartReviewQueue.pending(
        {
          'queue': [old],
          'settings': {'quiet_start': '09:00', 'quiet_end': '10:00'},
        },
        const FlashcardLocalState(),
        now: now,
        availableOnly: true,
      ),
      isEmpty,
    );
    expect(
      SmartReviewQueue.pending(
        {...data, 'date': '2026-10-21'},
        const FlashcardLocalState(),
        now: now,
      ),
      isEmpty,
    );
  });
}
