# One Line usage reliability

## Scope and acceptance

- In-app review is opt-in per session: screen entry, periodic badge refresh and
  lifecycle resume must never open a review dialog. Due-count badges use the
  existing One Line drawer entry; explicit review/notification taps still work.
- Floating review outside the app and text-notification delivery remain enabled
  according to their existing independent settings.
- Manual pack review reads all four item types, including text-only One Line.
- Start Review never creates a pack; when no timed reviews are due it opens the
  pack directory for manual selection. Existing automatic schedules stay intact.
- Pack details expose the existing owned-pack delete menu and invalidate related
  views/schedules after deletion. Linked source content remains protected.
- Settings wait for successful loading before initializing drafts; numeric input
  is committed explicitly, never from widget disposal. Errors preserve drafts.
- A visible permissions section reports real notification and overlay grants.
  Each permission opens Android settings on demand and refreshes after return.
- Text-notification fetching is independent from the interactive review state;
  failures are not presented as an empty successful schedule. Empty schedules
  identify disabled delivery, ineligible packs or exhausted time windows.
- Missing Excel runtime support returns an actionable message, and a read-only
  Artisan command checks deployment readiness. Installing production dependencies
  requires actual server access and must not be claimed from local checks.

## Delivery sequence

1. Completed: manual review/navigation/delete and settings draft lifecycle.
2. Completed: permissions presentation/native bridge and notification diagnostics.
3. Completed locally: Excel readiness, focused regression checks and delivery notes.

## Verification

Use the existing Flutter widget/repository tests and Laravel feature tests for
the changed flows. Compile the Android bridge if the local toolchain is available.
Do not run a full release build, deploy, install over the user's app, or push Git
changes without a new request. Native permission behavior needs a device check;
widget mocks alone cannot establish Android settings behavior.

## Local verification results

- Quiet in-app review: a focused widget test covers entry, 31 seconds of idle
  time and pause/resume with a due item and smart review enabled. No native
  in-app lease or dialog is opened; the due count remains available.
- Flutter analyzer: no issues in changed production files and new widget checks.
- Flutter focused checks: manual text review, empty-review navigation, delayed
  settings load, explicit numeric save (including Arabic digits), denied/granted
  permission display, settings reopening and lifecycle refresh passed. Existing
  editing and in-app/native handoff checks also passed.
- Laravel: 28 scheduling/import/editing tests, 208 assertions passed on isolated
  in-memory SQLite. Includes a real XLSX and simulated missing Excel reader.
- `flashcards:check-import`: local Excel/CSV runtime is ready.
- Android `compileReleaseKotlin` passed without rebuilding a Flutter APK.
- Release APK built and installed as an update on Samsung SM-G998U without
  clearing application data. APK v2 signature verified; local and installed
  SHA-256 match: `3B6BD560E74FBEF3A8D0FE7800075B7E1A8901D383B5A87A594BA5FDD72D43C1`.
  Delivery file: `release_apks/Moeen_Students.apk` (93,296,999 bytes).
- Application startup passed; no matching Flutter/native fatal errors appeared
  in the inspected process log. Existing overlay and notification grants were
  read and left unchanged. No real pack or answer was created.
- Physical permission-screen verification completed after the user activated
  access: both permission rows displayed allowed, matching Android's existing
  grants. Both in-app settings controls opened the corresponding Android pages
  (`OverlaySettingsActivity` and `AppNotificationSettingsActivity`). Returning
  from overlay settings retained the correct displayed state. No permission
  switches were changed. Denied-to-granted transitions were covered by isolated
  widget checks, not by revoking permissions on the user's production app.
- Screenshots are retained locally under the ignored student-app directory
  `build/verification/one-line-usage-2026-10-26/`. No matching Flutter/native fatal
  errors appeared in the inspected process log after these checks. No production
  subscription or authorization was bypassed.
- Backend deployed to `/var/www/moeen_app` at `b6c721d` via fast-forward pull.
  Existing server-local storage/cache ignore-file changes were left untouched.
- Production Composer initially rejected installation because `ext-gd` was
  missing. With explicit approval, installed `php8.2-gd` and the matching PHP
  8.2.35 patch packages. Ran locked `composer install --no-dev --prefer-dist
  --optimize-autoloader --no-interaction`; PhpSpreadsheet 2.4.5 installed.
- Production `composer check-platform-reqs --no-dev` and
  `php artisan flashcards:check-import` passed. A generated temporary XLSX was
  written/read successfully (`XLSX_WRITE_READ_OK`) and removed, without touching
  user records. Cleared Laravel caches and reloaded PHP 8.2 FPM; PHP-FPM and
  nginx reported active. No migrations or account-data changes were performed.
- Public post-deployment checks: `/admin/login` HTTP 200; unauthenticated
  `/api/student/flashcards` HTTP 401 as expected. An authenticated import through
  the phone/web remains the user's final acceptance check, not claimed here.
- Final quiet-review release copied to `release_apks/Moeen_Students.apk`,
  APK v2 signature verified, SHA-256
  `ABE33CD01543133F2749E9F21E568D1877B429AFF988FCEFAA465C1CE7AA1E6B`.
  This supersedes the earlier installed permissions-only release above. After
  the phone reconnected, installed it as an update without clearing data and
  verified the installed base APK SHA-256 matches the final delivery file.

## Production deployment requirement

The client's missing PhpSpreadsheet message is a server dependency problem;
updating the phone app alone cannot install that dependency. In the existing
Laravel checkout, after reviewing/pulling the approved backend commit, run:

```sh
composer install --no-dev --prefer-dist --optimize-autoloader
composer check-platform-reqs --no-dev
php artisan flashcards:check-import
php artisan optimize:clear
```

Do not use `composer update` or ignore platform requirements. Resolve any PHP
extensions reported by Composer for the production PHP version, and verify the
web/FPM runtime as well as CLI. These changes add no database migration.

## Manual acceptance

1. Open One Line with denied notifications/overlay: each row must show denied.
   Tap each row/icon, grant in Android settings, return and verify live status.
   Deny again to confirm recovery remains available, without repeated prompts.
2. Open an existing text-only pack: manual review must display its text. Start
   Review on an empty daily queue must open pack selection, never create a pack.
3. Delay network loading, then open settings: no editable default values should
   appear before loading finishes. Edit/save, reopen and verify persistence.
   Close without saving numbers and verify no write was submitted.
4. Import a real XLSX, preview/confirm it, review the resulting items, edit one,
   and remove an owned test pack through its details menu after confirmation.
5. Verify text and interactive schedules independently. Disabled packs, manual
   schedule days, no text content, unavailable time windows and server failures
   must not all look like the same empty successful schedule.
