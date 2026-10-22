# Floating MCQ Review

## Scope

Opt-in Android floating MCQ sessions. Preserve text notifications, existing
in-app review, exam protection, account isolation, and the pending import/edit fixes.

## Work

1. Add a native, non-exported foreground service with an application overlay,
   permission/status methods, a persistent Stop action, and no boot auto-start.
   Start only from the visible app after explicit permission and user action.
2. Add local presentation modes (in-app, floating, notification-only). Use the
   existing review queue/progress API and authenticated session; never persist the
   access token in native preferences. Keep pending answers scoped to the account.
3. Support one scrollable MCQ at a time, answer feedback, snooze/close, quiet
   windows, lock-screen suppression, and notification fallback.
4. Hide/hold floating content when the app is foreground, an in-app prompt owns
   the review, or exam security is active. Stop on logout/workspace switch.
5. Add optional idempotent progress events and a receipt migration so a retry
   after an ambiguous network failure cannot increment the result twice.
6. Run focused PHP/Dart checks and one native Kotlin compile. Exercise the real
   overlay/permission/lock/OEM behavior on an available Android phone at the end.

## Platform Limits

Android only, API 26+. A user-started session is not restarted from boot or after
force-stop/process death. Respect OS/other-app overlay blocking and battery
restrictions. Do not request Accessibility or full-screen intent permission.
Special-use foreground services require review against store distribution policy.
Native operation is not considered verified by widget tests or compilation alone.

## Card Presentation

- The native overlay now follows the in-app MCQ card: packaged Cairo fonts,
  existing Material icons, a white rounded surface, package accent, circular
  option indicators, and matching answer feedback colors.
- Presentation is isolated in `FloatingReviewCardView.kt`; the service retains
  its existing answer persistence, timing, suppression, and synchronization.
- Long questions and choices scroll inside a height-limited body while close
  and snooze remain outside it. Text uses Android scalable font units.
- Device visual review of this redesign is deferred at the user's request;
  the earlier device results below refer to the previous card presentation.
- A later isolated Android preview rendered the same view and packaged Release
  fonts with local sample content. The image was visually checked; the temporary
  preview app was uninstalled without changing the main app or account data.
- The redesigned native view compiled successfully in the Release build; the
  generated APK was checked for all four font assets used by the overlay.

## Verification And Deployment

- PHP scheduling/import/progress checks: 19 tests, 180 assertions passed.
- Focused Flutter suite: 20 tests passed, plus two legacy-API editing checks.
- Targeted Flutter analysis, native Kotlin compilation, and Release APK build passed.
- Samsung SM-G998U: installed as an update without clearing data; overlay permission
  and foreground-service start/stop verified through the normal settings UI.
- Physical overlay appeared automatically outside the app after the normal queue
  refresh. A screenshot confirmed the MCQ and both choices. Returning to the app
  hid it; screen-off/secure keyguard also suppressed it. Adaptive height was added
  after this visual check to remove unnecessary blank space for short questions.
  The final Release build was rechecked visually on the phone: compact height and
  header dragging both worked, and the second temporary MCQ remained unanswered.
- Device fixture: a temporary personal pack, with daily limit temporarily changed
  from 5 to 6 with user approval. One unintended navigation tap answered the first
  temporary item; a second item was display-only. Cleanup completed through the
  application UI: pack deletion succeeded and the list returned to 3 packs and
  16 cards. The daily limit was restored to 5 and the floating session stopped.
- Backend publication is required before distribution: deploy the controller and
  run `2026_10_21_000001_create_flashcard_progress_events_table.php`. Publishing
  commits to GitHub does not deploy the backend or run production migrations.
- After backend deployment, verify a controlled answer/retry returns the same
  progress without a second increment; offline/native synchronization was checked
  locally, not against production.
- Actual exam submission/security, process-death recovery, battery/OEM variations,
  and other Android models were not exercised on the production account. Sessions
  require an explicit restart after force-stop or process death by design.
