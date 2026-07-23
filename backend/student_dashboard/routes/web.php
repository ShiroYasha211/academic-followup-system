<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\DesktopPairingCodeController;

// Redirect root to login
Route::redirect('/', '/admin/login');

Route::prefix('admin')
    ->name('admin.')
    ->middleware('guest')
    ->group(function () {
        Route::get('login', [App\Http\Controllers\Admin\AuthController::class, 'showLoginForm'])
            ->name('login');
        Route::post('login', [App\Http\Controllers\Admin\AuthController::class, 'login']);

        Route::get('register', [App\Http\Controllers\Auth\RegisterController::class, 'showRegistrationForm'])
            ->name('register');
        Route::post('register', [App\Http\Controllers\Auth\RegisterController::class, 'register']);
    });

Route::prefix('admin')
    ->name('admin.')
    ->middleware(['auth', 'web.access', 'status'])
    ->group(function () {
        Route::get('dashboard', [App\Http\Controllers\Admin\DashboardController::class, 'index'])
            ->name('dashboard');

        // Finance & Earnings
        Route::get('finance', [App\Http\Controllers\Admin\FinanceController::class, 'index'])->name('finance.index');

        // Profile & Password
        Route::get('profile/password', [App\Http\Controllers\Auth\PasswordController::class, 'edit'])->name('profile.password');
        Route::put('profile/password', [App\Http\Controllers\Auth\PasswordController::class, 'update'])->name('profile.password.update');

        Route::get('about', [App\Http\Controllers\Admin\DashboardController::class, 'about'])
            ->name('about');
        Route::post('logout', [App\Http\Controllers\Admin\AuthController::class, 'logout'])
            ->name('logout');

        // Academic Routes
        Route::resource('universities', App\Http\Controllers\Admin\Academic\UniversityController::class);
        Route::resource('colleges', App\Http\Controllers\Admin\Academic\CollegeController::class);
        Route::resource('majors', App\Http\Controllers\Admin\Academic\MajorController::class);
        Route::resource('subjects', App\Http\Controllers\Admin\Academic\SubjectController::class);

        // Clinical Constants
        Route::prefix('clinical')->name('clinical.')->group(function () {
            Route::resource('departments', App\Http\Controllers\Admin\Clinical\ClinicalDepartmentController::class)->except(['show']);
            Route::resource('body-systems', App\Http\Controllers\Admin\Clinical\BodySystemController::class)->except(['show']);
            Route::resource('checklists', App\Http\Controllers\Admin\Clinical\EvaluationChecklistController::class);
        });


        // User Management Routes
        Route::get('users', [App\Http\Controllers\Admin\UserController::class, 'index'])->name('users.index');
        Route::get('users/export', [App\Http\Controllers\Admin\UserController::class, 'export'])->name('users.export');
        Route::patch('users/{user}/status', [App\Http\Controllers\Admin\UserController::class, 'updateStatus'])->name('users.status');
        Route::patch('users/{user}/activate-subscription', [App\Http\Controllers\Admin\UserController::class, 'activateSubscription'])->name('users.activate-subscription');
        Route::post('users/{user}/reset-password', [App\Http\Controllers\Admin\UserController::class, 'resetPassword'])->name('users.reset-password');
        Route::post('users/{user}/kick', [App\Http\Controllers\Admin\UserController::class, 'kickSession'])->name('users.kick');
        Route::delete('users/{user}', [App\Http\Controllers\Admin\UserController::class, 'destroy'])->name('users.destroy');

        // Bulk Actions
        Route::post('users/bulk-activate', [App\Http\Controllers\Admin\UserController::class, 'bulkActivate'])->name('users.bulk-activate');
        Route::post('users/bulk-deactivate', [App\Http\Controllers\Admin\UserController::class, 'bulkDeactivate'])->name('users.bulk-deactivate');
        Route::post('users/bulk-delete', [App\Http\Controllers\Admin\UserController::class, 'bulkDelete'])->name('users.bulk-delete');

        Route::resource('administratives', App\Http\Controllers\Admin\AdministrativeController::class);
        Route::resource('delegates', App\Http\Controllers\Admin\DelegateController::class);
        
        // Delegate Transfer Routes
        Route::get('delegates-transfer', [App\Http\Controllers\Admin\DelegateTransferController::class, 'index'])->name('delegates.transfer.index');
        Route::get('delegates-transfer/{major}/{level}', [App\Http\Controllers\Admin\DelegateTransferController::class, 'show'])->name('delegates.transfer.show');
        Route::post('delegates-transfer', [App\Http\Controllers\Admin\DelegateTransferController::class, 'transfer'])->name('delegates.transfer.perform');
        Route::resource('students', App\Http\Controllers\Admin\StudentController::class);
        Route::post('students/{student}/permissions', [App\Http\Controllers\Admin\StudentController::class, 'updatePermissions'])->name('students.permissions');
        Route::post('students/bulk-reset-devices', [App\Http\Controllers\Admin\StudentController::class, 'bulkResetDevices'])->name('students.bulk-reset-devices');
        Route::post('students/{student}/reset-devices', [App\Http\Controllers\Admin\StudentController::class, 'resetDevices'])->name('students.reset-devices');
        Route::post('students/{student}/open-slot', [App\Http\Controllers\Admin\StudentController::class, 'openDeviceSlot'])->name('students.open-slot');
        Route::post('students/{student}/close-slot', [App\Http\Controllers\Admin\StudentController::class, 'closeDeviceSlot'])->name('students.close-slot');
        Route::patch('students/devices/{device}', [App\Http\Controllers\Admin\StudentController::class, 'updateDevice'])->name('students.devices.update');
        Route::delete('students/devices/{device}', [App\Http\Controllers\Admin\StudentController::class, 'destroyDevice'])->name('students.devices.destroy');
        Route::get('student-device-requests', [App\Http\Controllers\Admin\StudentController::class, 'pendingDeviceRequests'])->name('students.device-requests.pending');
        Route::post('student-device-requests/{request}/approve', [App\Http\Controllers\Admin\StudentController::class, 'approveDeviceRequest'])->name('students.device-requests.approve');
        Route::post('student-device-requests/{request}/reject', [App\Http\Controllers\Admin\StudentController::class, 'rejectDeviceRequest'])->name('students.device-requests.reject');
        Route::resource('doctors', App\Http\Controllers\Admin\DoctorController::class);
        Route::patch('doctors/{doctor}/administrative-access', [App\Http\Controllers\Admin\DoctorController::class, 'updateAdministrativeAccess'])->name('doctors.administrative-access');

        // Clinical Delegate Management
        Route::resource('clinical-delegates', App\Http\Controllers\Admin\ClinicalDelegateController::class)
            ->only(['index', 'store', 'destroy']);

        // Registration Requests
        Route::get('registration-requests', [App\Http\Controllers\Admin\RegistrationRequestController::class, 'index'])
            ->name('registration_requests.index');
        Route::post('registration-requests/{user}/approve', [App\Http\Controllers\Admin\RegistrationRequestController::class, 'approve'])
            ->name('registration_requests.approve');
        Route::post('registration-requests/{user}/reject', [App\Http\Controllers\Admin\RegistrationRequestController::class, 'reject'])
            ->name('registration_requests.reject');

        // Attendance Routes - REMOVED (Delegate Duty Only)
        // Route::get('attendance/create', [App\Http\Controllers\Admin\AttendanceController::class, 'create'])->name('attendance.create');
        // Route::get('attendance/form', [App\Http\Controllers\Admin\AttendanceController::class, 'showCorrectionForm'])->name('attendance.form');
        // Route::post('attendance/store', [App\Http\Controllers\Admin\AttendanceController::class, 'store'])->name('attendance.store');
        Route::get('attendance-edit-requests', [App\Http\Controllers\Admin\AttendanceEditRequestController::class, 'index'])->name('attendance-edit-requests.index');
        Route::get('attendance-edit-requests/lookups/users', [App\Http\Controllers\Admin\AttendanceEditRequestController::class, 'lookupUsers'])->name('attendance-edit-requests.lookup-users');
        Route::get('attendance-edit-requests/lookups/subjects', [App\Http\Controllers\Admin\AttendanceEditRequestController::class, 'lookupSubjects'])->name('attendance-edit-requests.lookup-subjects');
        Route::get('attendance-edit-requests/lookups/lectures', [App\Http\Controllers\Admin\AttendanceEditRequestController::class, 'lookupLectures'])->name('attendance-edit-requests.lookup-lectures');
        Route::get('attendance-edit-requests/lookups/qr-sessions', [App\Http\Controllers\Admin\AttendanceEditRequestController::class, 'lookupQrSessions'])->name('attendance-edit-requests.lookup-qr-sessions');
        Route::post('attendance-edit-requests/grant', [App\Http\Controllers\Admin\AttendanceEditRequestController::class, 'grantManual'])->name('attendance-edit-requests.grant');
        Route::post('attendance-edit-requests/{editRequest}/approve', [App\Http\Controllers\Admin\AttendanceEditRequestController::class, 'approve'])->name('attendance-edit-requests.approve');
        Route::post('attendance-edit-requests/{editRequest}/reject', [App\Http\Controllers\Admin\AttendanceEditRequestController::class, 'reject'])->name('attendance-edit-requests.reject');
        Route::post('attendance-edit-permissions/{permission}/revoke', [App\Http\Controllers\Admin\AttendanceEditRequestController::class, 'revoke'])->name('attendance-edit-permissions.revoke');

        // Reports Routes
        Route::get('reports', [App\Http\Controllers\Admin\ReportController::class, 'index'])->name('reports.index');
        Route::get('reports/subject', [App\Http\Controllers\Admin\ReportController::class, 'subjectReport'])->name('reports.subject');
        Route::get('reports/threshold', [App\Http\Controllers\Admin\ReportController::class, 'thresholdReport'])->name('reports.threshold');
        Route::get('reports/level-summary', [App\Http\Controllers\Admin\ReportController::class, 'levelSummary'])->name('reports.level-summary');
        Route::get('reports/doctor-performance', [App\Http\Controllers\Admin\ReportController::class, 'doctorPerformance'])->name('reports.doctor-performance');
        Route::get('reports/assignments', [App\Http\Controllers\Admin\ReportController::class, 'assignmentsReport'])->name('reports.assignments');
        Route::get('reports/system-overview', [App\Http\Controllers\Admin\ReportController::class, 'systemOverview'])->name('reports.system-overview');


        // Activity Log Routes
        Route::get('activities', [App\Http\Controllers\Admin\ActivityController::class, 'index'])->name('activities.index');
        Route::delete('activities/cleanup', [App\Http\Controllers\Admin\ActivityController::class, 'cleanup'])->name('activities.cleanup');

        // Shared Library Management
        Route::post('library/bulk-destroy', [App\Http\Controllers\Admin\LibraryController::class, 'bulkDestroy'])->name('library.bulk-destroy');
        Route::resource('library', App\Http\Controllers\Admin\LibraryController::class)->names('library');
        Route::get('library/{resource}/download', [App\Http\Controllers\Admin\LibraryController::class, 'download'])->name('library.download');

        // Storage Management Routes
        Route::get('storage', [App\Http\Controllers\Admin\StorageController::class, 'index'])->name('storage.index');
        Route::delete('storage/{type}/{id}', [App\Http\Controllers\Admin\StorageController::class, 'destroy'])->name('storage.destroy');

        // Subscription & Packages Management
        Route::patch('packages/{package}/toggle', [App\Http\Controllers\Admin\PackageController::class, 'toggleStatus'])->name('packages.toggle');
        Route::resource('packages', App\Http\Controllers\Admin\PackageController::class);
        Route::get('packages/{package}/subscribers', [App\Http\Controllers\Admin\PackageController::class, 'subscribers'])->name('packages.subscribers');
        Route::post('subscriptions/{subscription}/cancel', [App\Http\Controllers\Admin\PackageController::class, 'cancelSubscription'])->name('subscriptions.cancel');
        Route::get('cards', [App\Http\Controllers\Admin\CardController::class, 'index'])->name('cards.index');
        Route::post('cards/generate', [App\Http\Controllers\Admin\CardController::class, 'generate'])->name('cards.generate');
        Route::delete('cards/{card}', [App\Http\Controllers\Admin\CardController::class, 'destroy'])->name('cards.destroy');

        // Settings Routes
        Route::get('settings', [App\Http\Controllers\Admin\SettingController::class, 'index'])->name('settings.index');
        Route::put('settings', [App\Http\Controllers\Admin\SettingController::class, 'update'])->name('settings.update');

        // ── Flashcard / One Line Shot Management ──
        Route::prefix('flashcards')->name('flashcards.')->group(function () {
            Route::get('/', [App\Http\Controllers\Admin\FlashcardController::class, 'index'])->name('index');
            Route::get('create', [App\Http\Controllers\Admin\FlashcardController::class, 'create'])->name('create');
            Route::post('/', [App\Http\Controllers\Admin\FlashcardController::class, 'store'])->name('store');
            Route::get('store-mgmt', [App\Http\Controllers\Admin\FlashcardController::class, 'storeManagement'])->name('store-mgmt');
            Route::get('import-template', [App\Http\Controllers\Admin\FlashcardController::class, 'downloadTemplate'])->name('import-template');
            Route::post('{flashcard}/import-preview', [App\Http\Controllers\Admin\FlashcardController::class, 'importPreview'])->name('import.preview');
            Route::post('{flashcard}/import-confirm', [App\Http\Controllers\Admin\FlashcardController::class, 'importConfirm'])->name('import.confirm');
            Route::get('{flashcard}', [App\Http\Controllers\Admin\FlashcardController::class, 'show'])->name('show');
            Route::get('{flashcard}/edit', [App\Http\Controllers\Admin\FlashcardController::class, 'edit'])->name('edit');
            Route::put('{flashcard}', [App\Http\Controllers\Admin\FlashcardController::class, 'update'])->name('update');
            Route::delete('{flashcard}', [App\Http\Controllers\Admin\FlashcardController::class, 'destroy'])->name('destroy');
            Route::post('{flashcard}/publish', [App\Http\Controllers\Admin\FlashcardController::class, 'publishToStore'])->name('publish');
            Route::post('{flashcard}/clone-review', [App\Http\Controllers\Admin\FlashcardController::class, 'cloneAndReview'])->name('clone-review');
            
            // Assignment Management Routes
            Route::get('management/assignments', [App\Http\Controllers\Admin\FlashcardController::class, 'assignmentsManagement'])->name('assignments');
            Route::delete('management/assignments/{pack}', [App\Http\Controllers\Admin\FlashcardController::class, 'cancelAssignment'])->name('assignments.cancel');
            
            Route::post('{flashcard}/assign', [App\Http\Controllers\Admin\FlashcardController::class, 'assignToUser'])->name('assign');
            Route::post('{flashcard}/import', [App\Http\Controllers\Admin\FlashcardController::class, 'import'])->name('import');
            Route::post('{flashcard}/items', [App\Http\Controllers\Admin\FlashcardController::class, 'storeItem'])->name('items.store');
            Route::put('items/{item}', [App\Http\Controllers\Admin\FlashcardController::class, 'updateItem'])->name('items.update');
            Route::delete('items/{item}', [App\Http\Controllers\Admin\FlashcardController::class, 'destroyItem'])->name('items.destroy');
            Route::get('{flashcard}/preview', [App\Http\Controllers\Admin\FlashcardController::class, 'preview'])->name('preview');
            Route::post('{flashcard}/toggle-visibility', [App\Http\Controllers\Admin\FlashcardController::class, 'toggleVisibility'])->name('toggle-visibility');
            Route::post('{flashcard}/toggle-featured', [App\Http\Controllers\Admin\FlashcardController::class, 'toggleFeatured'])->name('toggle-featured');
            Route::post('users/search', [App\Http\Controllers\Admin\FlashcardController::class, 'searchStudent'])->name('users.search');
        });

        // ── Admin Quiz Management ──
        Route::prefix('quizzes')->name('quizzes.')->group(function () {
            Route::get('/', [App\Http\Controllers\Admin\QuizController::class, 'index'])->name('index');
            Route::get('create', [App\Http\Controllers\Admin\QuizController::class, 'create'])->name('create');
            Route::post('/', [App\Http\Controllers\Admin\QuizController::class, 'store'])->name('store');
            Route::get('{quiz}', [App\Http\Controllers\Admin\QuizController::class, 'show'])->name('show');
            Route::get('{quiz}/edit', [App\Http\Controllers\Admin\QuizController::class, 'edit'])->name('edit');
            Route::put('{quiz}', [App\Http\Controllers\Admin\QuizController::class, 'update'])->name('update');
            Route::get('{quiz}/results', [App\Http\Controllers\Admin\QuizController::class, 'results'])->name('results');
            Route::get('{quiz}/results/export', [App\Http\Controllers\Admin\QuizController::class, 'exportResults'])->name('results.export');
            Route::post('{quiz}/share-results', [App\Http\Controllers\Admin\QuizController::class, 'shareResults'])->name('share-results');
            Route::delete('{quiz}', [App\Http\Controllers\Admin\QuizController::class, 'destroy'])->name('destroy');
            Route::patch('{quiz}/publish', [App\Http\Controllers\Admin\QuizController::class, 'publish'])->name('publish');
            Route::patch('{quiz}/close', [App\Http\Controllers\Admin\QuizController::class, 'close'])->name('close');
        });

        // ── Admin Star Management ──
        Route::prefix('stars')->name('stars.')->group(function () {
            Route::get('/', [App\Http\Controllers\Admin\StarController::class, 'index'])->name('index');
            Route::post('/grant', [App\Http\Controllers\Admin\StarController::class, 'grant'])->name('grant');
            Route::post('/search-students', [App\Http\Controllers\Admin\StarController::class, 'searchStudents'])->name('search-students');
        });

        Route::prefix('tree-farm-rewards')->name('tree-farm-rewards.')->group(function () {
            Route::get('/', [App\Http\Controllers\Admin\TreeFarmRewardController::class, 'index'])->name('index');
            Route::get('public-farm/export', [App\Http\Controllers\Admin\TreeFarmRewardController::class, 'exportPublicFarm'])->name('public-farm.export');
            Route::get('public-farm/{profile}', [App\Http\Controllers\Admin\TreeFarmRewardController::class, 'publicFarmProfile'])->name('public-farm.show');
            Route::post('public-farm/{profile}/visibility', [App\Http\Controllers\Admin\TreeFarmRewardController::class, 'togglePublicVisibility'])->name('public-farm.visibility');
            Route::post('{reward}/approve', [App\Http\Controllers\Admin\TreeFarmRewardController::class, 'approve'])->name('approve');
            Route::post('{reward}/reject', [App\Http\Controllers\Admin\TreeFarmRewardController::class, 'reject'])->name('reject');
            Route::post('settings', [App\Http\Controllers\Admin\TreeFarmRewardController::class, 'updateSettings'])->name('update-settings');
            Route::post('adjust-balance', [App\Http\Controllers\Admin\TreeFarmRewardController::class, 'adjustBalance'])->name('adjust-balance');
            Route::post('update-catalog', [App\Http\Controllers\Admin\TreeFarmRewardController::class, 'updateCatalog'])->name('update-catalog');
        });
    });

Route::prefix('doctor')
    ->name('doctor.')
    ->middleware(['auth', 'web.access', 'role:doctor', 'status', 'subscribed'])
    ->group(function () {
        Route::get('dashboard', [App\Http\Controllers\Doctor\DashboardController::class, 'index'])->name('dashboard');

        // Profile & Password
        Route::get('profile/password', [App\Http\Controllers\Auth\PasswordController::class, 'edit'])->name('profile.password');
        Route::put('profile/password', [App\Http\Controllers\Auth\PasswordController::class, 'update'])->name('profile.password.update');

        // Excuses Routes
        Route::get('excuses', [App\Http\Controllers\Doctor\ExcuseController::class, 'index'])->name('excuses.index');
        Route::put('excuses/{excuse}', [App\Http\Controllers\Doctor\ExcuseController::class, 'update'])->name('excuses.update');

        // Reports Routes
        Route::get('reports', [App\Http\Controllers\Doctor\ReportController::class, 'index'])->name('reports.index');
        Route::get('reports/{subject}', [App\Http\Controllers\Doctor\DashboardController::class, 'showSubjectReport'])->name('reports.show');

        // Assignments Routes
        Route::resource('assignments', App\Http\Controllers\Doctor\AssignmentController::class)->except(['create', 'edit', 'show']);
        Route::get('assignments/{assignment}/submissions/export', [App\Http\Controllers\Doctor\AssignmentController::class, 'exportSubmissions'])->name('assignments.submissions.export');
        Route::get('assignments/{assignment}/submissions', [App\Http\Controllers\Doctor\AssignmentController::class, 'submissions'])->name('assignments.submissions');
        Route::post('submissions/{submission}/review', [App\Http\Controllers\Doctor\AssignmentController::class, 'reviewSubmission'])->name('submissions.review');

        // Inquiries Routes (Student Questions)
        Route::get('inquiries', [App\Http\Controllers\Doctor\InquiryController::class, 'index'])->name('inquiries.index');
        Route::patch('inquiries/subjects/{subject}/settings', [App\Http\Controllers\Doctor\InquiryController::class, 'updateSettings'])->name('inquiries.settings.update');
        Route::get('inquiries/{inquiry}', [App\Http\Controllers\Doctor\InquiryController::class, 'show'])->name('inquiries.show');
        Route::post('inquiries/{inquiry}/answer', [App\Http\Controllers\Doctor\InquiryController::class, 'answer'])->name('inquiries.answer');

        // Grades Routes
        Route::get('grades', [App\Http\Controllers\Doctor\GradeController::class, 'index'])->name('grades.index');
        Route::get('grades/{subject}', [App\Http\Controllers\Doctor\GradeController::class, 'show'])->name('grades.show');
        Route::post('grades/{subject}', [App\Http\Controllers\Doctor\GradeController::class, 'store'])->name('grades.store');
        Route::get('grades/{subject}/report', [App\Http\Controllers\Doctor\GradeController::class, 'report'])->name('grades.report');
        Route::post('grades/{subject}/note/{student}', [App\Http\Controllers\Doctor\GradeController::class, 'storeNote'])->name('grades.storeNote');

        // Grade Delegation & Categories
        Route::get('grades/{subject}/categories', [App\Http\Controllers\Doctor\GradeCategoryController::class, 'index'])->name('grades.categories.index');
        Route::post('grades/{subject}/categories', [App\Http\Controllers\Doctor\GradeCategoryController::class, 'store'])->name('grades.categories.store');
        Route::delete('grades/categories/{category}', [App\Http\Controllers\Doctor\GradeCategoryController::class, 'destroy'])->name('grades.categories.destroy');
        
        // Dedicated Delegation Center Routes
        Route::get('grades/{subject}/delegations', [App\Http\Controllers\Doctor\GradeCategoryController::class, 'delegations'])->name('grades.delegations.index');
        Route::post('grades/categories/{category}/delegate', [App\Http\Controllers\Doctor\GradeCategoryController::class, 'delegate'])->name('grades.categories.delegate');
        Route::post('grades/categories/{category}/revoke', [App\Http\Controllers\Doctor\GradeCategoryController::class, 'revoke'])->name('grades.categories.revoke');

        Route::get('grades/{subject}/approvals', [App\Http\Controllers\Doctor\GradeApprovalController::class, 'index'])->name('grades.approvals.index');
        Route::post('grades/approvals/bulk-action', [App\Http\Controllers\Doctor\GradeApprovalController::class, 'bulkAction'])->name('grades.approvals.bulk');

        // Attendance Routes
        Route::get('attendance', [App\Http\Controllers\Doctor\AttendanceController::class, 'index'])->name('attendance.index');
        Route::get('attendance/{subject}/create', [App\Http\Controllers\Doctor\AttendanceController::class, 'create'])->name('attendance.create');
        Route::post('attendance/{subject}', [App\Http\Controllers\Doctor\AttendanceController::class, 'store'])->name('attendance.store');
        Route::post('desktop/pairing-code', [DesktopPairingCodeController::class, 'issueForDoctor'])->name('desktop.pairing-code');
        Route::patch('attendance-records/{attendance}', [App\Http\Controllers\Doctor\AttendanceRecordController::class, 'update'])->name('attendance.records.update');
        Route::post('attendance-edit-requests', [App\Http\Controllers\AttendanceEditRequestController::class, 'store'])->name('attendance-edit-requests.store');
        Route::post('attendance/{subject}/toggle-delegate', [App\Http\Controllers\Doctor\AttendanceController::class, 'toggleDelegateAttendance'])->name('attendance.toggle-delegate');
        Route::get('attendance/{subject}/{date}/report', [App\Http\Controllers\Doctor\AttendanceController::class, 'showReport'])->name('attendance.report');

        // Messages (Chat with Delegates)
        Route::get('messages', [App\Http\Controllers\Doctor\DoctorMessageController::class, 'index'])->name('messages.index');
        Route::get('messages/create', [App\Http\Controllers\Doctor\DoctorMessageController::class, 'create'])->name('messages.create');
        Route::post('messages/start', [App\Http\Controllers\Doctor\DoctorMessageController::class, 'store'])->name('messages.store');
        Route::get('messages/{conversation}', [App\Http\Controllers\Doctor\DoctorMessageController::class, 'show'])->name('messages.show');
        Route::post('messages/{conversation}/send', [App\Http\Controllers\Doctor\DoctorMessageController::class, 'send'])->name('messages.send');

        // News Center
        Route::get('news', [App\Http\Controllers\Doctor\NewsController::class, 'index'])->name('news.index');
        Route::get('news/{batchId}', [App\Http\Controllers\Doctor\NewsController::class, 'show'])->name('news.show');
        Route::post('news/{batchId}/vote', [App\Http\Controllers\Doctor\NewsController::class, 'vote'])->name('news.vote');

        // Notifications
        Route::get('notifications', [App\Http\Controllers\Doctor\NotificationController::class, 'index'])->name('notifications.index');
        Route::post('notifications/{id}/read', [App\Http\Controllers\Doctor\NotificationController::class, 'markAsRead'])->name('notifications.markAsRead');
        Route::post('notifications/mark-all-read', [App\Http\Controllers\Doctor\NotificationController::class, 'markAllAsRead'])->name('notifications.markAllRead');

        // Financial Ledger
        Route::get('ledger', [App\Http\Controllers\FinancialController::class, 'ledger'])->name('ledger');
        Route::get('ledger/export', [App\Http\Controllers\FinancialController::class, 'exportPdf'])->name('ledger.export');

        // Clinical Training Hub
        Route::prefix('clinical')->middleware('clinical.major')->name('clinical.')->group(function () {
            // Dashboard / Overview of Centers & Departments
            Route::get('/', [App\Http\Controllers\Doctor\ClinicalController::class, 'index'])->name('index');

            // Manage Training Centers
            Route::resource('training-centers', App\Http\Controllers\Doctor\Clinical\TrainingCenterController::class)->except(['show']);

            // Manage Clinical Departments
            Route::post('departments/restore', [App\Http\Controllers\Doctor\Clinical\ClinicalDepartmentController::class, 'restoreDefaults'])->name('departments.restore');
            Route::resource('departments', App\Http\Controllers\Doctor\Clinical\ClinicalDepartmentController::class)->except(['show']);

            // Manage Body Systems
            Route::post('body-systems/restore', [App\Http\Controllers\Doctor\Clinical\BodySystemController::class, 'restoreDefaults'])->name('body-systems.restore');
            Route::resource('body-systems', App\Http\Controllers\Doctor\Clinical\BodySystemController::class)->except(['show']);

            // Manage Clinical Cases
            Route::resource('cases', App\Http\Controllers\Doctor\Clinical\ClinicalCaseController::class);

            // Assign Cases to Students
            Route::get('assignments', [App\Http\Controllers\Doctor\Clinical\AssignmentController::class, 'index'])->name('assignments.index');
            Route::post('assignments', [App\Http\Controllers\Doctor\Clinical\AssignmentController::class, 'store'])->name('assignments.store');
            Route::post('assignments/{assignment}/review', [App\Http\Controllers\Doctor\Clinical\AssignmentController::class, 'review'])->name('assignments.review');

            // QR Scanner & Logbook Records (Doctor scans student QR)
            Route::get('scanner', [App\Http\Controllers\Doctor\Clinical\LogbookScannerController::class, 'scanner'])->name('scanner');
            Route::post('scanner/process', [App\Http\Controllers\Doctor\Clinical\LogbookScannerController::class, 'processQr'])->name('scanner.process');
            Route::post('scanner/confirm', [App\Http\Controllers\Doctor\Clinical\LogbookScannerController::class, 'confirm'])->name('scanner.confirm');
            Route::get('logbook-records', [App\Http\Controllers\Doctor\Clinical\LogbookScannerController::class, 'records'])->name('logbook-records');
            Route::get('logbook-portfolios', [App\Http\Controllers\Doctor\Clinical\LogbookScannerController::class, 'portfolioStudents'])->name('logbook-portfolios.index');
            Route::get('logbook-portfolios/{student}', [App\Http\Controllers\Doctor\Clinical\LogbookScannerController::class, 'portfolioShow'])->name('logbook-portfolios.show');
            Route::get('logbook-portfolios/{student}/pdf', [App\Http\Controllers\Doctor\Clinical\LogbookScannerController::class, 'portfolioPdf'])->name('logbook-portfolios.pdf');
            Route::get('logbook-portfolios/{student}/csv', [App\Http\Controllers\Doctor\Clinical\LogbookScannerController::class, 'portfolioCsv'])->name('logbook-portfolios.csv');
            Route::get('manual-attendance', [App\Http\Controllers\Doctor\Clinical\LogbookScannerController::class, 'manualAttendance'])->name('manual-attendance');
            Route::post('manual-attendance', [App\Http\Controllers\Doctor\Clinical\LogbookScannerController::class, 'storeManualAttendance'])->name('manual-attendance.store');

            // OSCE Evaluations
            Route::prefix('evaluations')->name('evaluations.')->group(function () {
                Route::post('checklists/restore', [App\Http\Controllers\Doctor\Clinical\EvaluationController::class, 'restoreDefaults'])->name('checklists.restore');
                Route::get('checklists', [App\Http\Controllers\Doctor\Clinical\EvaluationController::class, 'checklists'])->name('checklists');
                Route::get('checklists/create', [App\Http\Controllers\Doctor\Clinical\EvaluationController::class, 'createChecklist'])->name('checklists.create');
                Route::post('checklists', [App\Http\Controllers\Doctor\Clinical\EvaluationController::class, 'storeChecklist'])->name('checklists.store');
                Route::get('checklists/{id}/edit', [App\Http\Controllers\Doctor\Clinical\EvaluationController::class, 'editChecklist'])->name('checklists.edit');
                Route::put('checklists/{id}', [App\Http\Controllers\Doctor\Clinical\EvaluationController::class, 'updateChecklist'])->name('checklists.update');
                Route::delete('checklists/{id}', [App\Http\Controllers\Doctor\Clinical\EvaluationController::class, 'destroyChecklist'])->name('checklists.destroy');
                Route::get('start', [App\Http\Controllers\Doctor\Clinical\EvaluationController::class, 'startEvaluation'])->name('start');
                Route::post('live', [App\Http\Controllers\Doctor\Clinical\EvaluationController::class, 'liveEvaluate'])->name('live');
                Route::post('submit', [App\Http\Controllers\Doctor\Clinical\EvaluationController::class, 'submitEvaluation'])->name('submit');
                Route::get('portfolios', [App\Http\Controllers\Doctor\Clinical\EvaluationController::class, 'portfolios'])->name('portfolios.index');
                Route::get('portfolios/{student}', [App\Http\Controllers\Doctor\Clinical\EvaluationController::class, 'showPortfolio'])->name('portfolios.show');
                Route::get('portfolios/{student}/excel', [App\Http\Controllers\Doctor\Clinical\EvaluationController::class, 'exportPortfolio'])->name('portfolios.excel');
                Route::get('results', [App\Http\Controllers\Doctor\Clinical\EvaluationController::class, 'results'])->name('results');
                Route::get('results/{id}', [App\Http\Controllers\Doctor\Clinical\EvaluationController::class, 'showResult'])->name('results.show');
            });

            // Rare Clinical Cases Announcements
            Route::patch('rare-cases/{rare_case}/toggle', [App\Http\Controllers\Doctor\Clinical\RareCaseController::class, 'toggleStatus'])->name('rare-cases.toggle');
            Route::resource('rare-cases', App\Http\Controllers\Doctor\Clinical\RareCaseController::class)->except(['show', 'edit', 'update']);

            // Volunteers Registry
            Route::resource('volunteers', App\Http\Controllers\Doctor\Clinical\VolunteerController::class);
            Route::patch('volunteers/{id}/toggle', [App\Http\Controllers\Doctor\Clinical\VolunteerController::class, 'toggleStatus'])->name('volunteers.toggle');
        });

        // ── Doctor Announcements (إعلانات الدكتور) ──
        Route::prefix('announcements')->name('announcements.')->group(function () {
            Route::get('/', [App\Http\Controllers\Doctor\DoctorAnnouncementController::class, 'index'])->name('index');
            Route::get('create', [App\Http\Controllers\Doctor\DoctorAnnouncementController::class, 'create'])->name('create');
            Route::post('/', [App\Http\Controllers\Doctor\DoctorAnnouncementController::class, 'store'])->name('store');
            Route::get('{announcement}/edit', [App\Http\Controllers\Doctor\DoctorAnnouncementController::class, 'edit'])->name('edit');
            Route::put('{announcement}', [App\Http\Controllers\Doctor\DoctorAnnouncementController::class, 'update'])->name('update');
            Route::delete('{announcement}', [App\Http\Controllers\Doctor\DoctorAnnouncementController::class, 'destroy'])->name('destroy');
        });

        // ── Doctor Quizzes (كويزات الدكتور) ──
        Route::prefix('quizzes')->name('quizzes.')->group(function () {
            Route::get('/', [App\Http\Controllers\Doctor\QuizController::class, 'index'])->name('index');
            Route::get('create', [App\Http\Controllers\Doctor\QuizController::class, 'create'])->name('create');
            Route::post('/', [App\Http\Controllers\Doctor\QuizController::class, 'store'])->name('store');
            Route::get('{quiz}', [App\Http\Controllers\Doctor\QuizController::class, 'show'])->name('show');
            Route::get('{quiz}/edit', [App\Http\Controllers\Doctor\QuizController::class, 'edit'])->name('edit');
            Route::put('{quiz}', [App\Http\Controllers\Doctor\QuizController::class, 'update'])->name('update');
            Route::get('{quiz}/results/export', [App\Http\Controllers\Doctor\QuizController::class, 'exportResults'])->name('results.export');
            Route::get('{quiz}/results', [App\Http\Controllers\Doctor\QuizController::class, 'results'])->name('results');
            Route::patch('{quiz}/publish', [App\Http\Controllers\Doctor\QuizController::class, 'publish'])->name('publish');
            Route::patch('{quiz}/close', [App\Http\Controllers\Doctor\QuizController::class, 'close'])->name('close');
            Route::post('{quiz}/share-results', [App\Http\Controllers\Doctor\QuizController::class, 'shareResults'])->name('share-results');
            Route::delete('{quiz}', [App\Http\Controllers\Doctor\QuizController::class, 'destroy'])->name('destroy');
        });

        // ── Doctor Stars (نجوم الدكتور) ──
        Route::get('stars', [App\Http\Controllers\Doctor\StarController::class, 'index'])->name('stars.index');
        Route::post('stars/grant', [App\Http\Controllers\Doctor\StarController::class, 'grant'])->name('stars.grant');

        // Shared Subscription Routes
        Route::get('subscription', [App\Http\Controllers\Student\SubscriptionController::class, 'index'])->name('subscription.index');
        Route::post('subscription/redeem', [App\Http\Controllers\Student\SubscriptionController::class, 'redeem'])->name('subscription.redeem');
        Route::post('subscription/subscribe', [App\Http\Controllers\Student\SubscriptionController::class, 'subscribe'])->name('subscription.subscribe');
        Route::post('subscription/auto-renew', [App\Http\Controllers\Student\SubscriptionController::class, 'toggleAutoRenew'])->name('subscription.toggleAutoRenew');

        // Shared Study Library (Unified)
        Route::get('library', [App\Http\Controllers\Student\LibraryController::class, 'index'])->name('library.index');
        Route::get('library/create', [App\Http\Controllers\Student\LibraryController::class, 'create'])->name('library.create');
        Route::post('library/upload', [App\Http\Controllers\Student\LibraryController::class, 'store'])->name('library.store');
        Route::get('library/{resource}/download', [App\Http\Controllers\Student\LibraryController::class, 'incrementDownload'])->name('library.download');
    });

Route::prefix('student')
    ->name('student.')
    ->middleware(['auth', 'web.access', 'role:student', 'status', 'subscribed'])
    ->group(function () {
        Route::get('dashboard', [App\Http\Controllers\Student\DashboardController::class, 'index'])->name('dashboard');

        // Profile & Password
        Route::get('profile/password', [App\Http\Controllers\Auth\PasswordController::class, 'edit'])->name('profile.password');
        Route::put('profile/password', [App\Http\Controllers\Auth\PasswordController::class, 'update'])->name('profile.password.update');

        Route::resource('subjects', App\Http\Controllers\Student\SubjectController::class)->only(['index', 'show']);

        Route::get('assignments', [App\Http\Controllers\Student\AssignmentController::class, 'index'])->name('assignments.index');
        Route::post('assignments/preference', [App\Http\Controllers\Student\AssignmentController::class, 'updatePreference'])->name('assignments.updatePreference');
        Route::get('assignments/{assignment}/details', [App\Http\Controllers\Student\AssignmentController::class, 'getDetails'])->name('assignments.getDetails');
        Route::get('assignments/{assignment}', [App\Http\Controllers\Student\AssignmentController::class, 'show'])->name('assignments.show');
        Route::post('assignments/{assignment}/submit', [App\Http\Controllers\Student\AssignmentController::class, 'submit'])->name('assignments.submit');
        Route::post('assignments/{assignment}/priority', [App\Http\Controllers\Student\AssignmentController::class, 'updatePriority'])->name('assignments.updatePriority');
        // Deprecated: Global Attendance page is merged into Subject Details
        // Route::get('attendance', [App\Http\Controllers\Student\AttendanceController::class, 'index'])->name('attendance.index');
        Route::get('attendance/scan', function () {
            return view('student.attendance.scan');
        })->name('attendance.scan');
        Route::post('excuse', [App\Http\Controllers\Student\ExcuseController::class, 'store'])->name('excuse.store');
        Route::get('reminders', [App\Http\Controllers\Student\ReminderController::class, 'index'])->name('reminders.index');
        Route::get('resources', [App\Http\Controllers\Student\ResourceController::class, 'index'])->name('resources.index');
        Route::get('announcements', [App\Http\Controllers\Student\AnnouncementController::class, 'index'])->name('announcements.index');
        Route::get('news', [App\Http\Controllers\Student\NewsHubController::class, 'index'])->name('news.index');

        // Doctor Announcements (إعلانات الدكاترة)
        Route::get('doctor-announcements', [App\Http\Controllers\Student\DoctorAnnouncementController::class, 'index'])->name('doctor-announcements.index');

        // Student Quizzes (كويزات الطالب)
        Route::prefix('quizzes')->name('quizzes.')->group(function () {
            Route::get('/', [App\Http\Controllers\Student\QuizController::class, 'index'])->name('index');
            Route::get('{quiz}/take', [App\Http\Controllers\Student\QuizController::class, 'take'])->name('take');
            Route::post('attempts/{attempt}/submit', [App\Http\Controllers\Student\QuizController::class, 'submit'])->name('submit');
            Route::get('attempts/{attempt}/result', [App\Http\Controllers\Student\QuizController::class, 'result'])->name('result');
        });

        // Student Stars (نجوم الطالب)
        Route::get('stars', [App\Http\Controllers\Student\StarController::class, 'index'])->name('stars.index');
        Route::post('stars/gift', [App\Http\Controllers\Student\StarController::class, 'gift'])->name('stars.gift');

        Route::get('alerts', [App\Http\Controllers\Student\AlertController::class, 'index'])->name('alerts.index');
        Route::post('alerts/{id}/read', [App\Http\Controllers\Student\AlertController::class, 'markAsRead'])->name('alerts.read');

        // Exam Schedules
        Route::get('exams', [App\Http\Controllers\Student\ExamScheduleController::class, 'index'])->name('exams.index');

        // Grades - MOVED to Subject Details
        // Route::get('grades', [App\Http\Controllers\Student\GradeController::class, 'index'])->name('grades.index');

        // News Center details / voting
        Route::get('news/{batchId}', [App\Http\Controllers\Student\NewsController::class, 'show'])->name('news.show');
        Route::post('news/{batchId}/vote', [App\Http\Controllers\Student\NewsController::class, 'vote'])->name('news.vote');

        // Notifications
        Route::get('notifications', [App\Http\Controllers\Student\NotificationController::class, 'index'])->name('notifications.index');
        Route::post('notifications/{id}/read', [App\Http\Controllers\Student\NotificationController::class, 'markAsRead'])->name('notifications.markAsRead');
        Route::post('notifications/mark-all-read', [App\Http\Controllers\Student\NotificationController::class, 'markAllAsRead'])->name('notifications.markAllRead');

        // Financial Ledger
        Route::get('ledger', [App\Http\Controllers\FinancialController::class, 'ledger'])->name('ledger');
        Route::get('ledger/export', [App\Http\Controllers\FinancialController::class, 'exportPdf'])->name('ledger.export');

        // Messages (Chat System)
        Route::get('messages', [App\Http\Controllers\Student\MessageController::class, 'index'])->name('messages.index');
        Route::get('messages/start', [App\Http\Controllers\Student\MessageController::class, 'start'])->name('messages.start');
        Route::get('messages/{conversation}', [App\Http\Controllers\Student\MessageController::class, 'show'])->name('messages.show');
        Route::post('messages/{conversation}/send', [App\Http\Controllers\Student\MessageController::class, 'send'])->name('messages.send');

        // Card Generation (Balance-based)
        Route::middleware('permission:generate_cards')->group(function () {
            Route::get('cards-generate', [App\Http\Controllers\Student\CardGenerationController::class, 'index'])->name('cards.generate.index');
            Route::post('cards-generate', [App\Http\Controllers\Student\CardGenerationController::class, 'generate'])->name('cards.generate.store');
        });

        // Inquiries (Doctor Questions)
        Route::get('inquiries', [App\Http\Controllers\Student\InquiryController::class, 'index'])->name('inquiries.index');
        Route::get('inquiries/create', [App\Http\Controllers\Student\InquiryController::class, 'create'])->name('inquiries.create');
        Route::post('inquiries', [App\Http\Controllers\Student\InquiryController::class, 'store'])->name('inquiries.store');
        Route::get('inquiries/{inquiry}', [App\Http\Controllers\Student\InquiryController::class, 'show'])->name('inquiries.show');

        // Authorized Grade Entry
        Route::get('authorized-grades', [App\Http\Controllers\User\AuthorizedGradeController::class, 'index'])->name('authorized-grades.index');
        Route::get('authorized-grades/{category}', [App\Http\Controllers\User\AuthorizedGradeController::class, 'show'])->name('authorized-grades.show');
        Route::post('authorized-grades/{category}', [App\Http\Controllers\User\AuthorizedGradeController::class, 'store'])->name('authorized-grades.store');

        Route::prefix('clinical')->middleware('clinical.major')->name('clinical.')->group(function () {
            Route::get('/', [App\Http\Controllers\Student\Clinical\LogbookController::class, 'index'])->name('index');
            Route::get('daily-log/create', [App\Http\Controllers\Student\Clinical\LogbookController::class, 'createDailyLog'])->name('daily-log.create');
            Route::post('daily-log', [App\Http\Controllers\Student\Clinical\LogbookController::class, 'storeDailyLog'])->name('daily-log.store');
            Route::get('daily-log/{id}/qr', [App\Http\Controllers\Student\Clinical\LogbookController::class, 'showQr'])->name('show-qr');
            Route::post('daily-log/{id}/regenerate', [App\Http\Controllers\Student\Clinical\LogbookController::class, 'regenerateQr'])->name('daily-log.regenerate');
            Route::delete('daily-log/{id}/cancel', [App\Http\Controllers\Student\Clinical\LogbookController::class, 'cancelDailyLog'])->name('daily-log.cancel');
            Route::post('assignments/{assignment}/submit-review', [App\Http\Controllers\Student\Clinical\LogbookController::class, 'submitAssignment'])->name('assignments.submit');
            Route::get('logbook', [App\Http\Controllers\Student\Clinical\LogbookController::class, 'myLogbook'])->name('logbook');
            Route::get('logbook/export-pdf', [App\Http\Controllers\Student\Clinical\LogbookController::class, 'exportPdf'])->name('logbook.export_pdf');
            // Route::post('logbook/store', [LogbookController::class, 'store'])->name('logbook.store'); // This line was malformed in the instruction, assuming it's not needed or should be fixed.

            // Mock OSCE Exams
            Route::get('mock-exams', [App\Http\Controllers\Student\Clinical\MockExamController::class, 'index'])->name('mock.index');
            Route::get('mock-exams/create-custom', [App\Http\Controllers\Student\Clinical\MockExamController::class, 'createCustom'])->name('mock.create_custom');
            Route::post('mock-exams/store-custom', [App\Http\Controllers\Student\Clinical\MockExamController::class, 'storeCustom'])->name('mock.store_custom');
            Route::delete('mock-exams/{id}/destroy-custom', [App\Http\Controllers\Student\Clinical\MockExamController::class, 'destroyCustom'])->name('mock.destroy_custom');
            Route::get('mock-exams/take/{checklist}', [App\Http\Controllers\Student\Clinical\MockExamController::class, 'take'])->name('mock.take');
            Route::post('mock-exams/store', [App\Http\Controllers\Student\Clinical\MockExamController::class, 'store'])->name('mock.store');
            Route::get('mock-exams/{id}', [App\Http\Controllers\Student\Clinical\MockExamController::class, 'show'])->name('mock.show');

            Route::get('evaluations', [App\Http\Controllers\Student\Clinical\EvaluationController::class, 'index'])->name('evaluations');
            Route::get('evaluations/{id}', [App\Http\Controllers\Student\Clinical\EvaluationController::class, 'show'])->name('evaluations.show');

            // Rare Clinical Cases
            Route::get('rare-cases', [App\Http\Controllers\Student\Clinical\RareCaseController::class, 'index'])->name('rare-cases.index');
            Route::get('rare-cases/{id}', [App\Http\Controllers\Student\Clinical\RareCaseController::class, 'show'])->name('rare-cases.show');
        });

        // PDF Reports
        Route::get('reports/attendance', [App\Http\Controllers\Student\ReportController::class, 'attendancePdf'])->name('reports.attendance');
        Route::get('reports/grades', [App\Http\Controllers\Student\ReportController::class, 'gradesPdf'])->name('reports.grades');
        Route::get('reports/exams', [App\Http\Controllers\Student\ReportController::class, 'examsPdf'])->name('reports.exams');

        // Lectures Tracking
        Route::get('lectures/{subject}', [App\Http\Controllers\Student\LectureController::class, 'index'])->name('lectures.index');
        Route::post('lectures/toggle/{lecture}', [App\Http\Controllers\Student\LectureController::class, 'toggleStatus'])->name('lectures.toggle');

        // Study Schedule (Read-Only Mirror of Delegate's Schedule)
        Route::get('schedules', [App\Http\Controllers\Student\ScheduleController::class, 'index'])->name('schedules.index');

        // Student Schedule (Smart Study Hub)
        Route::get('schedule', [App\Http\Controllers\Student\StudentScheduleController::class, 'index'])->name('schedule.index');
        Route::post('schedule', [App\Http\Controllers\Student\StudentScheduleController::class, 'store'])->name('schedule.store');
        Route::post('schedule/custom-task', [App\Http\Controllers\Student\StudentScheduleController::class, 'storeCustomTask'])->name('schedule.storeCustomTask');
        Route::get('schedule/check-reminders', [App\Http\Controllers\Student\StudentScheduleController::class, 'checkReminders'])->name('schedule.checkReminders');
        Route::put('schedule/{id}', [App\Http\Controllers\Student\StudentScheduleController::class, 'update'])->name('schedule.update');
        Route::delete('schedule/{id}', [App\Http\Controllers\Student\StudentScheduleController::class, 'destroy'])->name('schedule.destroy');
        Route::post('schedule/reorder', [App\Http\Controllers\Student\StudentScheduleController::class, 'reorder'])->name('schedule.reorder');

        // Shared Study Library
        Route::get('library', [App\Http\Controllers\Student\LibraryController::class, 'index'])->name('library.index');
        Route::get('library/create', [App\Http\Controllers\Student\LibraryController::class, 'create'])->name('library.create');
        Route::post('library/upload', [App\Http\Controllers\Student\LibraryController::class, 'store'])->name('library.store');
        Route::get('library/{resource}/download', [App\Http\Controllers\Student\LibraryController::class, 'incrementDownload'])->name('library.download');

        // ── Flashcard / One Line Shot ──
        Route::prefix('flashcards')->name('flashcards.')->group(function () {
            Route::get('/', [App\Http\Controllers\Student\FlashcardController::class, 'index'])->name('index');
            Route::get('create', [App\Http\Controllers\Student\FlashcardController::class, 'create'])->name('create');
            Route::post('/', [App\Http\Controllers\Student\FlashcardController::class, 'store'])->name('store');
            Route::get('store', [App\Http\Controllers\Student\FlashcardController::class, 'publicStore'])->name('public-store');
            Route::post('clone/{flashcard}', [App\Http\Controllers\Student\FlashcardController::class, 'clonePack'])->name('clone');
            Route::get('{flashcard}', [App\Http\Controllers\Student\FlashcardController::class, 'show'])->name('show');
            Route::get('{flashcard}/edit', [App\Http\Controllers\Student\FlashcardController::class, 'edit'])->name('edit');
            Route::put('{flashcard}', [App\Http\Controllers\Student\FlashcardController::class, 'update'])->name('update');
            Route::delete('{flashcard}', [App\Http\Controllers\Student\FlashcardController::class, 'destroy'])->name('destroy');
            Route::patch('{flashcard}/toggle', [App\Http\Controllers\Student\FlashcardController::class, 'toggleActive'])->name('toggle');
            Route::put('{flashcard}/settings', [App\Http\Controllers\Student\FlashcardController::class, 'updateSettings'])->name('settings');
            Route::post('{flashcard}/import', [App\Http\Controllers\Student\FlashcardController::class, 'import'])->name('import');
            Route::post('{flashcard}/items', [App\Http\Controllers\Student\FlashcardController::class, 'storeItem'])->name('items.store');
            Route::put('items/{item}', [App\Http\Controllers\Student\FlashcardController::class, 'updateItem'])->name('items.update');
            Route::delete('items/{item}', [App\Http\Controllers\Student\FlashcardController::class, 'destroyItem'])->name('items.destroy');
            Route::get('{flashcard}/review', [App\Http\Controllers\Student\FlashcardController::class, 'review'])->name('review');
            Route::post('progress', [App\Http\Controllers\Student\FlashcardController::class, 'recordProgress'])->name('progress');
        });

        // Shared Subscription Routes
        Route::get('subscription', [App\Http\Controllers\Student\SubscriptionController::class, 'index'])->name('subscription.index');
        Route::post('subscription/redeem', [App\Http\Controllers\Student\SubscriptionController::class, 'redeem'])->name('subscription.redeem');
        Route::post('subscription/subscribe', [App\Http\Controllers\Student\SubscriptionController::class, 'subscribe'])->name('subscription.subscribe');
        Route::post('subscription/auto-renew', [App\Http\Controllers\Student\SubscriptionController::class, 'toggleAutoRenew'])->name('subscription.toggleAutoRenew');
    });

Route::prefix('delegate')
    ->name('delegate.')
    ->middleware(['auth', 'web.access', 'role:delegate', 'status', 'subscribed'])
    ->group(function () {
        Route::get('dashboard', [App\Http\Controllers\Delegate\DashboardController::class, 'index'])->name('dashboard');

        // Profile & Password
        Route::get('profile/password', [App\Http\Controllers\Auth\PasswordController::class, 'edit'])->name('profile.password');
        Route::put('profile/password', [App\Http\Controllers\Auth\PasswordController::class, 'update'])->name('profile.password.update');

        // Doctor Chat
        Route::post('doctor-chat/{conversation}/send', [App\Http\Controllers\Delegate\DoctorChatController::class, 'send'])->name('doctor-chat.send');

        // Shared Library Access for Delegate
        Route::get('library', [App\Http\Controllers\Student\LibraryController::class, 'index'])->name('library.index');
        Route::get('library/create', [App\Http\Controllers\Student\LibraryController::class, 'create'])->name('library.create');
        Route::post('library', [App\Http\Controllers\Student\LibraryController::class, 'store'])->name('library.store');
        Route::get('library/{resource}/download', [App\Http\Controllers\Student\LibraryController::class, 'incrementDownload'])->name('library.download');

        // Shared Subscription Routes
        Route::get('subscription', [App\Http\Controllers\Student\SubscriptionController::class, 'index'])->name('subscription.index');
        Route::post('subscription/redeem', [App\Http\Controllers\Student\SubscriptionController::class, 'redeem'])->name('subscription.redeem');
        Route::post('subscription/subscribe', [App\Http\Controllers\Student\SubscriptionController::class, 'subscribe'])->name('subscription.subscribe');
        Route::post('subscription/auto-renew', [App\Http\Controllers\Student\SubscriptionController::class, 'toggleAutoRenew'])->name('subscription.toggleAutoRenew');

        // Card Generation (Balance-based)
        Route::get('cards-generate', [App\Http\Controllers\Student\CardGenerationController::class, 'index'])->name('cards.generate.index');
        Route::post('cards-generate', [App\Http\Controllers\Student\CardGenerationController::class, 'generate'])->name('cards.generate.store');

        // Students Management
        Route::get('students/template', [App\Http\Controllers\Delegate\StudentController::class, 'downloadTemplate'])->name('students.template');
        Route::post('students/import', [App\Http\Controllers\Delegate\StudentController::class, 'import'])->name('students.import');
        Route::post('students/{student}/permissions', [App\Http\Controllers\Delegate\StudentController::class, 'updatePermissions'])->name('students.permissions');
        Route::resource('students', App\Http\Controllers\Delegate\StudentController::class);

        // Subjects & Schedule
        Route::resource('subjects', App\Http\Controllers\Delegate\SubjectController::class)->except(['create', 'show']);
        Route::resource('schedules', App\Http\Controllers\Delegate\ScheduleController::class)->except(['show']);

        // News Center
        Route::get('news', [App\Http\Controllers\Delegate\NewsController::class, 'index'])->name('news.index');
        Route::get('news/{batchId}', [App\Http\Controllers\Delegate\NewsController::class, 'show'])->name('news.show');
        Route::post('news/{batchId}/vote', [App\Http\Controllers\Delegate\NewsController::class, 'vote'])->name('news.vote');

        // Notifications
        Route::get('notifications', [App\Http\Controllers\Delegate\NotificationController::class, 'index'])->name('notifications.index');
        Route::post('notifications', [App\Http\Controllers\Delegate\NotificationController::class, 'store'])->name('notifications.store');

        // Financial Ledger
        Route::get('ledger', [App\Http\Controllers\FinancialController::class, 'ledger'])->name('ledger');
        Route::get('ledger/export', [App\Http\Controllers\FinancialController::class, 'exportPdf'])->name('ledger.export');

        // Attendance
        Route::get('attendance', [App\Http\Controllers\Delegate\AttendanceController::class, 'index'])->name('attendance.index');
        Route::get('attendance/unofficial/create', [App\Http\Controllers\Delegate\AttendanceController::class, 'createUnofficial'])->name('attendance.unofficial.create');
        Route::post('attendance/unofficial', [App\Http\Controllers\Delegate\AttendanceController::class, 'storeUnofficial'])->name('attendance.unofficial.store');
        Route::get('attendance/unofficial/{lecture}/report', [App\Http\Controllers\Delegate\AttendanceController::class, 'showUnofficialReport'])->name('attendance.unofficial.report');
        Route::get('attendance/{subject}/create', [App\Http\Controllers\Delegate\AttendanceController::class, 'create'])->name('attendance.create');
        Route::get('attendance/{subject}/check', [App\Http\Controllers\Delegate\AttendanceController::class, 'check'])->name('attendance.check');
        Route::post('attendance/{subject}', [App\Http\Controllers\Delegate\AttendanceController::class, 'store'])->name('attendance.store');
        Route::post('desktop/pairing-code', [DesktopPairingCodeController::class, 'issueForDelegate'])->name('desktop.pairing-code');
        Route::post('attendance-edit-requests', [App\Http\Controllers\AttendanceEditRequestController::class, 'store'])->name('attendance-edit-requests.store');
        // Assignments
        Route::resource('assignments', App\Http\Controllers\Delegate\AssignmentController::class)->except(['create', 'edit', 'show']);

        // Announcements
        Route::resource('announcements', App\Http\Controllers\Delegate\AnnouncementController::class)->except(['create', 'edit', 'show']);
        Route::post('announcements/{announcement}/toggle-pin', [App\Http\Controllers\Delegate\AnnouncementController::class, 'togglePin'])->name('announcements.togglePin');

        // Reminders
        Route::resource('reminders', App\Http\Controllers\Delegate\ReminderController::class)->except(['create', 'edit', 'show']);

        // Exam Schedules
        Route::resource('exams', App\Http\Controllers\Delegate\ExamScheduleController::class);

        // Course Resources
        Route::get('resources', [App\Http\Controllers\Delegate\ResourceController::class, 'index'])->name('resources.index');
        Route::get('resources/search-library', [App\Http\Controllers\Delegate\ResourceController::class, 'searchLibrary'])->name('resources.search-library');
        Route::get('resources/create', [App\Http\Controllers\Delegate\ResourceController::class, 'create'])->name('resources.create');
        Route::post('resources', [App\Http\Controllers\Delegate\ResourceController::class, 'store'])->name('resources.store');
        Route::get('resources/{resource}/edit', [App\Http\Controllers\Delegate\ResourceController::class, 'edit'])->name('resources.edit');
        Route::put('resources/{resource}', [App\Http\Controllers\Delegate\ResourceController::class, 'update'])->name('resources.update');
        Route::post('resources/import', [App\Http\Controllers\Delegate\ResourceController::class, 'import'])->name('resources.import');
        Route::delete('resources/{resource}', [App\Http\Controllers\Delegate\ResourceController::class, 'destroy'])->name('resources.destroy');

        // Attendance Report Route (Correctly placed inside group)
        Route::get('attendance/{subject}/{date}/report', [App\Http\Controllers\Delegate\AttendanceController::class, 'showReport'])->name('attendance.report');

        // Grades - REMOVED (Doctor Only)
        // Route::get('grades', [App\Http\Controllers\Delegate\GradeController::class, 'index'])->name('grades.index');
        // Route::get('grades/create', [App\Http\Controllers\Delegate\GradeController::class, 'create'])->name('grades.create');
        // Route::get('grades/{subject}', [App\Http\Controllers\Delegate\GradeController::class, 'show'])->name('grades.show');
        // Route::post('grades/quick', [App\Http\Controllers\Delegate\GradeController::class, 'storeQuick'])->name('grades.storeQuick');
        // Route::post('grades/excel', [App\Http\Controllers\Delegate\GradeController::class, 'storeExcel'])->name('grades.storeExcel');
        // Route::get('grades/template/download', [App\Http\Controllers\Delegate\GradeController::class, 'downloadTemplate'])->name('grades.downloadTemplate');
        // Route::put('grades/{grade}', [App\Http\Controllers\Delegate\GradeController::class, 'update'])->name('grades.update');
        // Route::delete('grades/{grade}', [App\Http\Controllers\Delegate\GradeController::class, 'destroy'])->name('grades.destroy');

        // Messages (Chat System)
        Route::get('messages', [App\Http\Controllers\Delegate\MessageController::class, 'index'])->name('messages.index');
        Route::get('messages/create', [App\Http\Controllers\Delegate\MessageController::class, 'create'])->name('messages.create');
        Route::post('messages/start', [App\Http\Controllers\Delegate\MessageController::class, 'store'])->name('messages.store');
        Route::get('messages/{conversation}', [App\Http\Controllers\Delegate\MessageController::class, 'show'])->name('messages.show');
        Route::post('messages/{conversation}/send', [App\Http\Controllers\Delegate\MessageController::class, 'send'])->name('messages.send');

        // Student Inquiries
        Route::get('inquiries', [App\Http\Controllers\Delegate\InquiryController::class, 'index'])->name('inquiries.index');
        Route::get('inquiries/{inquiry}', [App\Http\Controllers\Delegate\InquiryController::class, 'show'])->name('inquiries.show');
        Route::post('inquiries/{inquiry}/forward', [App\Http\Controllers\Delegate\InquiryController::class, 'forward'])->name('inquiries.forward');
        Route::post('inquiries/{inquiry}/answer', [App\Http\Controllers\Delegate\InquiryController::class, 'answer'])->name('inquiries.answer');
        Route::post('inquiries/{inquiry}/close', [App\Http\Controllers\Delegate\InquiryController::class, 'close'])->name('inquiries.close');

        // Authorized Grade Entry (for Delegate if assigned)
        Route::get('authorized-grades', [App\Http\Controllers\User\AuthorizedGradeController::class, 'index'])->name('authorized-grades.index');
        Route::get('authorized-grades/{category}', [App\Http\Controllers\User\AuthorizedGradeController::class, 'show'])->name('authorized-grades.show');
        Route::post('authorized-grades/{category}', [App\Http\Controllers\User\AuthorizedGradeController::class, 'store'])->name('authorized-grades.store');
        Route::post('authorized-grades/{category}/helpers', [App\Http\Controllers\Delegate\GradeHelperDelegationController::class, 'store'])->name('authorized-grades.helpers.store');
        Route::delete('authorized-grades/helpers/{delegation}', [App\Http\Controllers\Delegate\GradeHelperDelegationController::class, 'revoke'])->name('authorized-grades.helpers.revoke');

        // Doctor Chat (Chat with Doctors)
        Route::get('doctor-chat', [App\Http\Controllers\Delegate\DoctorChatController::class, 'index'])->name('doctor-chat.index');
        Route::get('doctor-chat/create', [App\Http\Controllers\Delegate\DoctorChatController::class, 'create'])->name('doctor-chat.create');
        Route::post('doctor-chat/start', [App\Http\Controllers\Delegate\DoctorChatController::class, 'store'])->name('doctor-chat.store');
        Route::get('doctor-chat/{conversation}', [App\Http\Controllers\Delegate\DoctorChatController::class, 'show'])->name('doctor-chat.show');
        Route::post('doctor-chat/{conversation}/send', [App\Http\Controllers\Delegate\DoctorChatController::class, 'send'])->name('doctor-chat.send');

        // Clinical Access for Practical Delegates (Delegate Role)
        Route::middleware('clinical_delegate')->group(function () {
            Route::prefix('clinical')->name('clinical.')->group(function () {
                // Sub-delegations management
                Route::get('delegations', [App\Http\Controllers\Delegate\Clinical\SubDelegationController::class, 'index'])->name('delegations.index');
                Route::post('delegations', [App\Http\Controllers\Delegate\Clinical\SubDelegationController::class, 'store'])->name('delegations.store');
                Route::patch('delegations/{delegation}/revoke', [App\Http\Controllers\Delegate\Clinical\SubDelegationController::class, 'revoke'])->name('delegations.revoke');

                Route::get('cases/pending', [App\Http\Controllers\Delegate\Clinical\ClinicalCaseController::class, 'pending'])->name('cases.pending');
                Route::post('cases/{case}/approve', [App\Http\Controllers\Delegate\Clinical\ClinicalCaseController::class, 'approve'])->name('cases.approve');
                Route::post('cases/{case}/reject', [App\Http\Controllers\Delegate\Clinical\ClinicalCaseController::class, 'reject'])->name('cases.reject');

                Route::resource('cases', App\Http\Controllers\Delegate\Clinical\ClinicalCaseController::class);
            });
        });
    });

Route::prefix('administrative')
    ->name('administrative.')
    ->middleware(['auth', 'web.access', 'administrative', 'status', 'subscribed'])
    ->group(function () {
        Route::get('dashboard', [App\Http\Controllers\Administrative\DashboardController::class, 'index'])->name('dashboard');
        Route::get('settings', [App\Http\Controllers\Administrative\CollegeSettingsController::class, 'edit'])->name('settings');
        Route::put('settings', [App\Http\Controllers\Administrative\CollegeSettingsController::class, 'update'])->name('settings.update');

        // Profile & Password
        Route::get('profile/password', [App\Http\Controllers\Auth\PasswordController::class, 'edit'])->name('profile.password');
        Route::put('profile/password', [App\Http\Controllers\Auth\PasswordController::class, 'update'])->name('profile.password.update');

        // Subscription Routes
        Route::get('subscription', [App\Http\Controllers\Student\SubscriptionController::class, 'index'])->name('subscription.index');
        Route::post('subscription/redeem', [App\Http\Controllers\Student\SubscriptionController::class, 'redeem'])->name('subscription.redeem');
        Route::post('subscription/subscribe', [App\Http\Controllers\Student\SubscriptionController::class, 'subscribe'])->name('subscription.subscribe');
        Route::post('subscription/auto-renew', [App\Http\Controllers\Student\SubscriptionController::class, 'toggleAutoRenew'])->name('subscription.toggleAutoRenew');

        // Financial Ledger
        Route::get('ledger', [App\Http\Controllers\FinancialController::class, 'ledger'])->name('ledger');
        Route::get('ledger/export', [App\Http\Controllers\FinancialController::class, 'exportPdf'])->name('ledger.export');

        // Delegate Management
        Route::get('delegates', [App\Http\Controllers\Administrative\DelegateController::class, 'index'])->name('delegates.index');
        Route::patch('delegates/{user}/role', [App\Http\Controllers\Administrative\DelegateController::class, 'updateRole'])->name('delegates.update-role');
        Route::post('delegates/{user}/permissions', [App\Http\Controllers\Administrative\DelegateController::class, 'updatePermissions'])->name('delegates.permissions');

        // Academic Helpers
        Route::get('majors/{major}/levels', [App\Http\Controllers\Api\Admin\MajorController::class, 'getLevels'])->name('majors.levels');

        // Notifications System
        Route::get('notifications', [App\Http\Controllers\Administrative\NotificationController::class, 'index'])->name('notifications.index');
        Route::get('notifications/create', [App\Http\Controllers\Administrative\NotificationController::class, 'create'])->name('notifications.create');
        Route::post('notifications', [App\Http\Controllers\Administrative\NotificationController::class, 'store'])->name('notifications.store');
        Route::get('notifications/{batchId}', [App\Http\Controllers\Administrative\NotificationController::class, 'show'])->name('notifications.show');
        Route::delete('notifications/{batchId}', [App\Http\Controllers\Administrative\NotificationController::class, 'destroy'])->name('notifications.destroy');

        // Excuses
        Route::get('excuses', [App\Http\Controllers\Administrative\ExcuseController::class, 'index'])->name('excuses.index');
        Route::patch('excuses/{excuse}', [App\Http\Controllers\Administrative\ExcuseController::class, 'update'])->name('excuses.update');
        Route::patch('attendance/{attendance}', [App\Http\Controllers\Administrative\AttendanceController::class, 'update'])->name('attendance.update');

        // Reports System
        Route::get('reports', [App\Http\Controllers\Administrative\ReportController::class, 'index'])->name('reports.index');
        Route::get('reports/attendance', [App\Http\Controllers\Administrative\ReportController::class, 'attendance'])->name('reports.attendance');
        Route::get('reports/subject', [App\Http\Controllers\Administrative\ReportController::class, 'subjectReport'])->name('reports.subject');
        Route::get('reports/threshold', [App\Http\Controllers\Administrative\ReportController::class, 'thresholdReport'])->name('reports.threshold');
        Route::get('reports/level-summary', [App\Http\Controllers\Administrative\ReportController::class, 'levelSummary'])->name('reports.level-summary');
        Route::get('reports/doctor-performance', [App\Http\Controllers\Administrative\ReportController::class, 'doctorPerformance'])->name('reports.doctor-performance');




        // Management Resources
        Route::resource('students', App\Http\Controllers\Administrative\StudentController::class)->except(['create', 'show', 'edit']);
        Route::post('doctors/{doctor}/star-wallet/top-up', [App\Http\Controllers\Administrative\DoctorController::class, 'topUpStarWallet'])->name('doctors.star-wallet.top-up');
        Route::resource('doctors', App\Http\Controllers\Administrative\DoctorController::class)->except(['create', 'show', 'edit']);
        Route::resource('majors', App\Http\Controllers\Administrative\MajorController::class)->except(['create', 'show', 'edit']);
        Route::resource('subjects', App\Http\Controllers\Administrative\SubjectController::class)->except(['create', 'show', 'edit']);

        // Exam Schedules
        Route::get('exams/helper/levels/{major}', [App\Http\Controllers\Administrative\ExamScheduleController::class, 'getLevels'])->name('exams.helper.levels');
        Route::get('exams/helper/subjects/{level}', [App\Http\Controllers\Administrative\ExamScheduleController::class, 'getSubjects'])->name('exams.helper.subjects');
        Route::resource('exams', App\Http\Controllers\Administrative\ExamScheduleController::class)->names('exams');

        // Academic Schedules (Lectures)
        Route::get('schedules/helper/subjects/{level}', [App\Http\Controllers\Administrative\AcademicScheduleController::class, 'getSubjectsWithDoctors'])->name('schedules.helper.subjects');
        Route::resource('schedules', App\Http\Controllers\Administrative\AcademicScheduleController::class)->names('schedules');

        // Placeholder for future administrative features
        // Route::resource('notifications', ...);
        // Route::get('reports', ...);
    });

// Separate Clinical Access for Students who are Practical Delegates
Route::prefix('student')
    ->name('student.')
    ->middleware(['auth', 'web.access', 'role:student', 'status', 'clinical_delegate'])
    ->group(function () {
        Route::prefix('clinical')->name('clinical.')->group(function () {
            Route::get('cases/pending', [App\Http\Controllers\Delegate\Clinical\ClinicalCaseController::class, 'pending'])->name('cases.pending');
            Route::resource('cases', App\Http\Controllers\Delegate\Clinical\ClinicalCaseController::class);
        });
    });
