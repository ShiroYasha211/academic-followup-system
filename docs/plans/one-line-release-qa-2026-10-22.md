# One Line Release QA - 2026-10-22

## Scope

One Line scheduling/notifications, Excel/CSV import, personal item editing,
native floating MCQ review, and opt-in automatic session resume. This is not
a whole-system certification or an audit of unrelated modules.

## Automated Results

- Flutter: 23 passing tests across the scheduler, notifications, editing, and
  floating-review bridge suites.
- Laravel: 19 passing tests / 180 assertions on in-memory SQLite. Coverage
  includes actual XLSX and CSV files, duplicate strategies, file ownership,
  linked-pack protection, valid answer indices, stable daily schedules,
  multi-day separation, quiet windows, user isolation, and idempotent retries.
- Targeted analysis: no issues in the 12 selected Dart source/test files.
- Native Android: 17 scenarios passed on Samsung SM-G998U using unchanged
  production bridge/service/view sources in a temporary isolated QA app. The
  transport was stubbed; no production token or backend connection was used.
- Four additional device scenarios passed: denied/restored overlay permission
  and denied/restored notification permission. Saved opt-in survived denial,
  no forbidden startup occurred, and reconfiguration restored the service.

## Device Scenarios

Default opt-out; enable; resume after service stop; repeated initialization
without duplicate service; disable; notification Stop; logout; account isolation;
display-mode switching; exam startup suppression; foreground suppression; real
overlay window; immediate removal during exam protection; future/non-MCQ filtering;
quiet/disabled review suppression; local answer persistence/disabled choices;
and long Arabic questions with six options and 160% font scale.

The large-font visual check found clipped icon glyphs. Icons now use dp like
Flutter icons while question/option text still uses scalable sp. The native
scenarios were rerun successfully and the corrected image was visually checked.
Initial harness failures were corrected in the isolated test runner (qualified
instrumentation name, main-thread dispatch, and synchronous scroll assertion);
they were not application crashes. The temporary QA app was uninstalled.

## Release And Deployment Gates

- Release APK built successfully and its APK v2 signature verified. Installed
  as an update on SM-G998U without clearing main-app data. SHA-256:
  `F9C5493067486F9C53A21BF88ED0F1B238D00B5244BD882A2751F15903FBB844`.
- Main Release app: the switch started the service; after force-stop and reopening
  the home screen, the service resumed with automatic activation enabled, without
  visiting One Line. Switching off and repeating force-stop/open left it stopped.
  The app reached its normal home screen and no Flutter/native crash entries were
  observed in the inspected process log after these checks.
- Device state restored: automatic activation off (its initial new-setting value),
  manual floating session active (as before QA). Daily limit 5, interval 30 minutes,
  and 08:00-23:00 window were not edited. No real pack or answer was created.
- Production backend deployment and migration have not been verified in this run.
  Deploy commit `5bbc503` (or a descendant) and apply
  `2026_10_21_000001_create_flashcard_progress_events_table.php` before distribution.
- A controlled server answer/retry should be checked after deployment. Native
  device answers above were local fixtures, not production synchronization.
- No production exam was entered or submitted. Exam-mode suppression was tested
  through the native security gate, not by taking a real student's exam.
- Other OEMs, reboot behavior, secure-lock recovery, prolonged battery restrictions,
  MySQL concurrency and Play Store special-use FGS review remain unverified here.
- No Git commit/push or server deployment is part of this QA request.

## Subsequent Bubble Release

- Bubble-first review and automatic resume were subsequently authorized for
  publication. The native sources passed 22 isolated device scenarios, including
  due-only unique counts, no automatic question opening, unchanged count on close,
  explicit Next after answers, drag-position persistence and snooze persistence.
- Release build and signature verification passed. The update was installed on
  SM-G998U without clearing data. Local and installed APK SHA-256 were equal:
  `2E8FF10EB075DBBBFF3D6A53D0F4B33094D9EA6650C310F14F042A27BCCCB6E6`.
- Six Flutter floating-review tests were rerun successfully before publication.
- No further backend changes or server deployment were included in this release.
