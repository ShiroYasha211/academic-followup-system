# Moeen Project Brief

## Goal
`Moeen` is a university management and student support system with:
- Laravel backend and web dashboards for `admin`, `administrative`, `doctor`, `delegate`, and `student`.
- Flutter mobile app currently focused on `student`, with growing support for `delegate`.
- Windows Flutter desktop app for QR attendance display and monitoring.

Core domains:
- academic structure and schedules
- attendance and QR attendance
- assignments and excuses
- grades and delegated grading
- study center and reminders
- news, notifications, messaging, inquiries
- clinical/practical section
- quizzes, stars, subscription, ledger, shared library, course resources

## Important Paths
- Backend root: `E:\Projects\student_dashboard`
- Flutter student app: `E:\Projects\Moeen\frontend\moeen_student_app`
- Flutter desktop app: `E:\Projects\Moeen\desktop`

Backend important folders:
- `app/Http/Controllers/Api/...`
- `app/Http/Controllers/...` for web dashboards
- `app/Models/...`
- `routes/api.php`
- `routes/web.php`
- `routes/console.php`
- `resources/views/...`
- `database/migrations/...`

Flutter app important folders:
- `lib/src/core/...`
- `lib/src/features/auth/...`
- `lib/src/features/student/...`
- `lib/src/features/delegate/...`
- `lib/src/shared/widgets/...`

## Stack
- Backend: Laravel 12, PHP 8.2, MySQL, Sanctum
- Frontend mobile: Flutter, Riverpod, GoRouter, Flutter Secure Storage, Firebase Messaging
- Frontend desktop: Flutter Windows
- Notifications: Firebase Cloud Messaging
- File export/import: Excel/PDF support in backend

## Agreed Rules And Constraints
- Use `apply_patch` for manual code edits.
- Do not revert unrelated user changes.
- Preserve existing design language unless we explicitly redesign a page.
- Prefer fixing backend logic at the source, not only patching frontend symptoms.
- For frontend, keep files split by feature/screen; avoid giant single files when possible.
- Arabic UI text must remain UTF-8 and must not be re-saved with broken encoding.
- QR, subscription, reminders, and permission-sensitive flows must be enforced in backend, not frontend only.

## Things Already Solved
- Multiple Arabic encoding issues in Laravel Blade and Flutter screens.
- Delegate news route parameter bug.
- Delegate attendance page encoding issues and unofficial lecture support.
- Delegate dashboard null subject crash.
- Teacher dashboard lacked practical/clinical entry points; added/fixed.
- Evaluation lists visibility and edit validation fixes.
- Doctor filtering in clinical daily log now restricted to relevant doctors.
- Clinical logbook and task workflow expanded.
- Desktop QR attendance pairing flow and monitoring flow implemented.
- Firebase push integrated and verified working after proper server config.
- Student app auth, splash, register, session persistence, sidebar, multiple major student pages implemented.
- Student study center redesigned and study session columns/actions added.
- Student practical/clinical section added and shown only for eligible students.
- Subscription pricing bug fixed so users with delegate capability get delegate package pricing.
- Study reminders integrated with notification flow.
- Deprivation/warning logic unified to use subject `max_absences` and college threshold.
- Assignment details bug fixed: no false `pending review` before submission; overdue submission now locked.

## Do Not Change These Without Need
- Established student app identity/colors/logo direction.
- Role model: `student`, `practical_delegate`, `delegate`, `doctor`, `administrative`, `admin`.
- Sanctum-based auth contracts already used by mobile and desktop.
- Firebase device registration and push flow unless there is a real bug.
- Desktop QR flow contract unless updating both backend and desktop app together.
- Existing subscription behavior where delegate-capable users must use delegate subscription pricing.

## Runtime / Commands
Backend local:
```bash
cd E:\Projects\student_dashboard
php artisan serve --host=0.0.0.0 --port=8000
```

Backend checks:
```bash
php artisan test
php -l path\to\file.php
php artisan route:list
```

Important production scheduler:
```bash
* * * * * cd /var/www/moeen_app && php artisan schedule:run >> /dev/null 2>&1
```

Flutter app:
```bash
cd E:\Projects\Moeen\frontend\moeen_student_app
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
flutter run
```

Desktop app:
```bash
cd E:\Projects\Moeen\desktop
flutter pub get
flutter analyze
flutter run -d windows
```

## Important Operational Notes
- Firebase on backend depends on service account JSON and correct `.env` values.
- Scheduled study reminders require Laravel scheduler/cron.
- If Flutter reports missing old assets after renaming images, run:
```bash
flutter clean
flutter pub get
```

## Most Important Files
- Backend:
  - `app/Http/Controllers/Api/Student/SubjectController.php`
  - `app/Http/Controllers/Api/Student/AttendanceController.php`
  - `app/Http/Controllers/Api/Student/AssignmentController.php`
  - `app/Http/Controllers/Api/Student/StudentScheduleController.php`
  - `app/Http/Controllers/Api/Student/AuthController.php`
  - `app/Services/PushNotificationService.php`
  - `routes/api.php`
  - `routes/console.php`
- Flutter:
  - `lib/src/core/router/app_router.dart`
  - `lib/src/features/auth/...`
  - `lib/src/features/student/presentation/student_shell.dart`
  - `lib/src/features/student/presentation/student_dashboard_screen.dart`
  - `lib/src/features/student/presentation/student_assignments_screen.dart`
  - `lib/src/features/student/presentation/student_study_center_screen.dart`
  - `lib/src/features/student/presentation/student_study_session_screen.dart`
  - `lib/src/features/student/presentation/student_subject_detail_screen.dart`
  - `lib/src/features/student/presentation/widgets/student_content_widgets.dart`
  - `lib/src/features/student/data/student_repositories.dart`

## Design Decisions
- Student app uses sidebar, not bottom nav, because features are many.
- Student app identity is premium/modern, based on the Moeen logo and Arabic-first UI.
- Reuse shared UI/components where safe, but keep role-specific business logic separate.
- Clinical/practical features are conditionally visible based on eligibility/data.
- For assignments:
  - `available` means not submitted and still open
  - `submitted` means sent by student
  - `pending` means under review
  - `missing` means deadline passed without submission
- For deprivation:
  - use `subject.max_absences`
  - use college `absence_deprivation_percentage`
  - show `safe`, `warning`, `actual ban` states clearly

## Current Unfinished / Likely Next Tasks
- Continue delegate mobile app until feature parity with needed web flows.
- Review remaining delegate pages for cleanup, splitting, and parity.
- Continue practical delegate behavior in mobile app where needed.
- End-to-end regression testing on student/delegate apps after recent assignment/deprivation fixes.
- Possible visual cleanup of any remaining mojibake text in untouched Flutter files.
- Broader review of reminders, notifications, and message counters after more real-device testing.

## Known Sensitive Areas
- Arabic encoding in Flutter and Blade files.
- Assignment status mapping between backend and frontend.
- Reminder scheduling vs push delivery.
- Attendance uniqueness and QR finalize flow.
- Subscription and role-based pricing.
- Role switching between student and delegate workspaces.


## Codex Token-Saving Rules
- Do not scan the whole repository unless explicitly asked.
- Start by reading this file, then inspect only the files related to the current task.
- Before editing, briefly state which files you need to inspect and why.
- Do not print full file contents unless necessary.
- Prefer small diffs and targeted patches.
- Do not run broad test suites unless requested; run only relevant checks first.
- If a task seems to require many files, ask for confirmation before expanding scope.