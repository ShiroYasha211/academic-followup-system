# One Line Shot Reliability

## Scope

Repair account isolation, confirmed notification scheduling, background renewal,
message rotation, stable timestamps, timing precision, quiet hours, the 100-message
daily limit, and the interactive review due-date contract.

## Implementation

- Account ID is persisted with the session. Flashcard files and offline cache keys
  are namespaced by account; legacy sessions use a token digest as a safe fallback.
  Unattributed legacy files are not imported into another account.
- Logout and switching to the delegate workspace cancel the background job and
  local One Line and review alarms. Foreground and background work share a file lock.
- Server daily snapshots serialize requests under a user-row lock. Dates and
  message selections persist; explicit rescheduling rebuilds today's snapshot.
- Messages rotate by previously selected dates, independently of review answers.
- The API optionally returns three days. The client supports 100 messages per day
  with disjoint notification IDs across this horizon.
- Android WorkManager refreshes this horizon every six hours when network is
  available. Foreground refresh also reconciles system pending notifications.
- Failed/blocked entries retain their status and are retried; they are not counted
  as successfully scheduled. Past timestamps mean the planned time elapsed, not
  proof that Android displayed the notification.
- Exact alarms are used when allowed; an inexact fallback is labeled approximate.
- Quiet/active-window conflicts yield no notifications outside the allowed window.
- Interactive reviews respect next_review_at and preserve assigned times for
  remaining cards. Newly due cards can join a non-full daily schedule.

## Deployment Order

1. Deploy the backend and run `php artisan migrate --force`.
2. Run `php artisan optimize:clear`.
3. Build and install the updated student app. Restart it fully after the update.

No production database or server is changed by the local implementation steps.

## Focused Checks

- Backend: `php artisan test --compact tests/Feature/FlashcardSchedulingTest.php`.
- Flutter: `flutter test --no-pub test/one_line_scheduler_test.dart test/one_line_notifications_test.dart test/widget_test.dart test/library_counts_test.dart`.
- Targeted Flutter analysis covers the changed auth, scheduler, notification,
  storage, repository and app files.
- Android dependency compatibility: `gradlew.bat :app:checkDebugAarMetadata` using
  the Flutter-compatible JDK.

## Required Android Device Checks

Local verification completed:

- 7 backend tests passed (113 assertions), using an isolated SQLite database.
- 20 Flutter tests passed, including mocked Android notification-channel failures.
- Targeted Flutter analysis passed.
- Android `:app:checkDebugAarMetadata` passed using Java 17 with existing Gradle/AGP versions.
- The new migration was applied to the local MySQL database on 127.0.0.1.
- No physical Android device was connected; actual alarm delivery, OEM battery
  behavior, reboot recovery and periodic native execution remain device checks.

1. Enable notifications, set a short test interval, and confirm requests appear
   as scheduled. Compare actual arrival with the indicated precision.
2. Deny notifications: entries must say blocked and manual retry must not report
   successful delivery. Re-enable and retry without restarting the day.
3. Deny exact-alarm access: the schedule must say approximate and remain usable.
4. Leave and reopen the screen: unchanged dates/IDs must remain unchanged.
5. Sign out from account A, sign in to B: no A alarms, cached content, or progress
   should appear in B. Test switching to and from the delegate workspace too.
6. Close the UI without force-stopping the app. Confirm the background refresh
   renews the future horizon and persists it for the next app launch.
7. Reboot and unlock the device: verify pending alarms are restored. Force-stop
   is a separate case: Android suspends jobs/alarms until the app is reopened.
8. Test overlapping quiet/active windows, a window crossing midnight, and a
   100-message day. No slot outside the allowed date/window should be generated.
9. Answer one interactive card: remaining assigned times must not shift. A card
   with a future next_review_at must not become available early.

WorkManager and exact alarms remain subject to Android power management and OEM
restrictions. A three-day offline horizon cannot regenerate indefinitely without
network access. Native behavior requires verification on an Android device;
widget tests alone do not establish delivery guarantees.
