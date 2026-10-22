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

Android only, API 26+. Sessions are not restarted in the background after boot,
force-stop or process death; an opted-in account resumes on its next app opening.
Respect OS/other-app overlay blocking and battery
restrictions. Do not request Accessibility or full-screen intent permission.
Special-use foreground services require review against store distribution policy.
Native operation is not considered verified by widget tests or compilation alone.

## Automatic Session Resume

- An opt-in `auto_start_<account>` preference is stored on the device separately
  from service state; existing accounts remain opted out until they enable it.
- Session configuration on app launch/resume restores the service only for the
  current account, floating mode, a visible non-exam activity, and granted overlay
  and notification permissions. It does not prompt for permissions automatically.
- Disabling the switch, ending the session in settings, or using the notification
  Stop action clears automatic activation. Logout/workspace switching stops the
  session but preserves the account's preference for its next student login.
- No boot receiver, background restart loop, or persisted token is introduced.
  Opening the app again after reboot/force-stop is still required. Existing exam,
  lock-screen, quiet-time and due-MCQ checks remain in effect.
- Updated QA: six Flutter bridge tests passed as part of 23 related Flutter tests;
  targeted analysis and Release compilation passed. The Release APK was installed
  and automatic enable/reopen and disable/reopen were verified through the real
  app. Another 21 isolated native device scenarios covered service lifecycle,
  permissions, account isolation, display filtering, local answers and large text.
  See `one-line-release-qa-2026-10-22.md` for evidence and remaining release gates.

## Card Presentation

### Bubble-First Interaction

- Due valid MCQs now show a draggable launcher-icon bubble, not an unsolicited
  question. Its badge counts unique due items not completed today; future and
  malformed items are excluded. Position is saved per account using normalized
  coordinates constrained to system-bar/cutout-safe bounds.
- Tap opens a question. Close returns to the bubble without completing it.
  Answer feedback offers an explicit Next button for remaining due items; the
  last answer closes after feedback. No automatic jump to the next question.
- Long press opens a snooze action, also exposed to accessibility services.
  Snooze uses the existing review interval and survives service recreation.
- A separate normal-importance ready channel announces newly due IDs once per
  account/day. Refresh/restart does not re-alert the same items. Existing ready
  notification counts can update silently; dismissed reminders stay dismissed.
- The bubble uses a 450ms right-to-left entry transition and respects disabled
  system animations. App foreground, exam security, lock, quiet time, logout and
  service Stop suppress both bubble and question through the existing gates.
- Backend and API contracts are unchanged. Native compile and 22 isolated device
  scenarios passed during implementation; these tests use local questions only.
  The subsequent bubble Release APK was built, signature-verified and installed
  as an update on SM-G998U; its installed SHA-256 matched the local build exactly.

- The native overlay now follows the in-app MCQ card: packaged Cairo fonts,
  existing Material icons, a white rounded surface, package accent, circular
  option indicators, and matching answer feedback colors.
- Presentation is isolated in `FloatingReviewCardView.kt`; the service retains
  its existing answer persistence, timing, suppression, and synchronization.
- Long questions and choices scroll inside a height-limited body while close
  and snooze remain outside it. Text uses Android scalable font units.
- End-to-end overlay review of this redesign was deferred at the user's request;
  the earlier overlay results below refer to the previous card presentation.
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
  and other Android models were not comprehensively exercised on the production
  account. Force-stop/open automatic recovery was verified in the updated QA;
  returning to the app is still required, rather than restarting from background.
