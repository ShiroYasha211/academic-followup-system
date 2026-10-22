# Review Scheduling Coordination Fix

## Scope
- Make the server daily queue authoritative for in-app review, notifications and the Android bubble.
- Persist a review occurrence key so intentional repeat rounds do not conflict with completed items.
- Keep future cards pending; restart only after the current round finishes.
- Separate completion from explicit snooze, and disallow background in-app prompts.
- Preserve existing One Line text notifications, quiz protection and user data.

## Delivery
1. Completed: stable server review rounds and an authenticated manual-restart endpoint, using the existing schedule table.
2. Completed: Flutter consumes the server queue without synthetic schedules, synchronizes it to Android, reconciles reminders without replaying overdue cards, and targets the notified occurrence.
3. Completed: Android tracks occurrence completion, reevaluates on lifecycle/queue changes, and uses a main-thread due-time callback independent of network refresh. Completion no longer snoozes all cards.
4. Local checks and release packaging complete; physical-device validation remains pending.

## Acceptance
- Leaving the app does not manufacture another reminder for an old card.
- A future card remains pending even when all currently available cards were answered.
- Answering a card does not defer another card's scheduled time.
- The background bubble and in-app page agree on the next occurrence and its time.
- Automatic/manual repeats have stable times and new occurrence keys.
- Device validation remains pending until the user connects the phone; backend changes must be deployed before testing the new API.

## Local Verification - 2026-10-22
- Flutter: 33 focused tests passed across queue selection, prompt lifecycle/channel coordination, notification reconciliation, One Line scheduling, and existing card editing.
- Backend: 16 tests passed with 156 assertions, including stable pending times, repeat rounds, manual-restart guards, event retry safety and preserving a partial legacy day during upgrade.
- Flutter analysis: 17 affected source/test files, no issues.
- Kotlin release compilation and `flutter build apk --release --no-pub` passed.
- Release APK: `frontend/moeen_student_app/build/app/outputs/flutter-apk/app-release.apk`, 93,280,143 bytes.
- APK SHA-256: `B2FDD77F8B6309C41C581CB263DB9634AA2530F69C06F4EE6F2A697852FECDB7`.
- APK signature verification passed (v2, one signer).
- Git whitespace checks and PHP syntax checks passed.
- The widget/channel tests use mock transport and an in-memory repository. They are not physical-device or production API evidence.

## Changed Areas
- Backend: `FlashcardController.php`, `FlashcardReviewScheduleService.php`, the flashcard API route and `FlashcardSchedulingTest.php`.
- Flutter: `app.dart`, `push_notification_service.dart`, `flashcard_local_store.dart`, `student_repositories.dart`, `floating_review.dart`, `smart_review_queue.dart`, and the affected review provider/helpers/prompt/session/today widgets and student-shell lifecycle.
- Android: `ReviewOverlayBridge.kt`, `FloatingReviewService.kt` and `MainActivity.kt`. The bubble and card visual components are unchanged.
- Regression tests: queue selection, screen/channel coordination, native bridge contract and notification reconciliation. Existing scheduler/editing tests were rerun.

## Deployment And Phone Check
- No new schema migration. Deploy the changed controller, new schedule service and API route together before using the new APK.
- Existing `flashcard_daily_schedules` and `flashcard_progress_events` migrations must already be installed.
- No deployment, commit, push, phone installation or real-account answer was performed as part of the local checks above.
- Physical scenario: confirm an upcoming MCQ and its time, leave the app, verify no early reminder/hidden in-app lease, wait for the same occurrence's bubble and notification, answer it, then verify the next card keeps its scheduled time.
- Also verify an old notification cannot open an unrelated earlier card, closing/reopening does not restart a round, and lock/quiz suppression remains intact.
