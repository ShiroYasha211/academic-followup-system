<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Http\Request;
use App\Http\Controllers\Api\QrAttendanceController;
use App\Http\Controllers\Api\RegisterController as ApiRegisterController;
use App\Http\Controllers\Api\Desktop\AuthController as DesktopAuthController;
use App\Http\Controllers\Api\Desktop\AttendanceController as DesktopAttendanceController;

// Admin API Controllers
use App\Http\Controllers\Api\Admin\AuthController as AdminAuthController;
use App\Http\Controllers\Api\Admin\DashboardController as AdminDashboardController;
use App\Http\Controllers\Api\Admin\UniversityController as AdminUniversityController;
use App\Http\Controllers\Api\Admin\CollegeController as AdminCollegeController;
use App\Http\Controllers\Api\Admin\MajorController as AdminMajorController;
use App\Http\Controllers\Api\Admin\SubjectController as AdminSubjectController;
use App\Http\Controllers\Api\Admin\UserController as AdminUserController;
use App\Http\Controllers\Api\Admin\StudentController as AdminStudentController;
use App\Http\Controllers\Api\Admin\DoctorController as AdminDoctorController;
use App\Http\Controllers\Api\Admin\DelegateController as AdminDelegateController;
use App\Http\Controllers\Api\Admin\ClinicalDelegateController as AdminClinicalDelegateController;
use App\Http\Controllers\Api\Admin\ReportController as AdminReportController;
use App\Http\Controllers\Api\Admin\SettingController as AdminSettingController;
use App\Http\Controllers\Api\Admin\ActivityController as AdminActivityController;
use App\Http\Controllers\Api\Admin\FlashcardController as AdminFlashcardController;
use App\Http\Controllers\Api\Admin\LibraryController;
use App\Http\Controllers\Api\Admin\QuizController as AdminApiQuizController;
use App\Http\Controllers\Api\Admin\StarController as AdminApiStarController;
use App\Http\Controllers\Api\Admin\RegistrationRequestController as AdminRegistrationRequestController;
use App\Http\Controllers\Api\Admin\AdministrativeController as AdminAdministrativeController;
use App\Http\Controllers\Api\Admin\DelegateTransferController as AdminDelegateTransferController;
use App\Http\Controllers\Api\Admin\PackageController as AdminPackageController;
use App\Http\Controllers\Api\Admin\CardController as AdminCardController;
use App\Http\Controllers\Api\Admin\FinanceController as AdminFinanceController;
use App\Http\Controllers\Api\Admin\StorageController as AdminStorageController;
use App\Http\Controllers\Api\Admin\Clinical\ClinicalDepartmentController as AdminClinicalDepartmentController;
use App\Http\Controllers\Api\Admin\Clinical\BodySystemController as AdminBodySystemController;
use App\Http\Controllers\Api\Admin\Clinical\EvaluationChecklistController as AdminEvaluationChecklistController;
use App\Http\Controllers\Api\Admin\InfoController as AdminInfoController;

// Delegate API Controllers
use App\Http\Controllers\Api\Delegate\AuthController as DelegateAuthController;
use App\Http\Controllers\Api\Delegate\DashboardController as DelegateDashboardController;
use App\Http\Controllers\Api\Delegate\SubjectController as DelegateSubjectController;
use App\Http\Controllers\Api\Delegate\ScheduleController as DelegateScheduleController;
use App\Http\Controllers\Api\Delegate\ExamScheduleController as DelegateExamScheduleController;
use App\Http\Controllers\Api\Delegate\AssignmentController as DelegateAssignmentController;
use App\Http\Controllers\Api\Delegate\ResourceController as DelegateResourceController;
use App\Http\Controllers\Api\Delegate\AnnouncementController as DelegateAnnouncementController;
use App\Http\Controllers\Api\Delegate\ReminderController as DelegateReminderController;
use App\Http\Controllers\Api\Delegate\MessageController as DelegateMessageController;
use App\Http\Controllers\Api\Delegate\InquiryController as DelegateInquiryController;
use App\Http\Controllers\Api\Delegate\DoctorChatController as DelegateDoctorChatController;
use App\Http\Controllers\Api\Delegate\AttendanceController as DelegateAttendanceController;
use App\Http\Controllers\Api\Delegate\NotificationController as DelegateNotificationController;
use App\Http\Controllers\Api\Delegate\Clinical\SubDelegationController as DelegateSubDelegationController;
use App\Http\Controllers\Api\Delegate\Clinical\ClinicalCaseController as DelegateClinicalCaseController;
use App\Http\Controllers\Api\Delegate\StudentController as DelegateStudentController;

// Rare Case API Controllers
use App\Http\Controllers\Api\Student\Clinical\RareCaseController as StudentRareCaseController;
use App\Http\Controllers\Api\Doctor\Clinical\RareCaseController as DoctorRareCaseController;
use App\Http\Controllers\Api\Doctor\Clinical\VolunteerController as DoctorVolunteerController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

// ══════════════════════════════════════════════════════════════
// Public API Routes (No Auth Required)
// ══════════════════════════════════════════════════════════════
Route::post('register', [ApiRegisterController::class, 'register']);

// Public Academic Data (For Registration Form)
Route::prefix('public')->group(function () {
    Route::get('universities', [\App\Http\Controllers\Api\Public\DataController::class, 'universities']);
    Route::get('colleges', [\App\Http\Controllers\Api\Public\DataController::class, 'colleges']);
    Route::get('colleges/{university}', [\App\Http\Controllers\Api\Public\DataController::class, 'colleges']);
    Route::get('majors', [\App\Http\Controllers\Api\Public\DataController::class, 'majors']);
    Route::get('majors/{college}', [\App\Http\Controllers\Api\Public\DataController::class, 'majors']);
    Route::get('levels', [\App\Http\Controllers\Api\Public\DataController::class, 'levels']);
    Route::get('levels/{major}', [\App\Http\Controllers\Api\Public\DataController::class, 'levels']);
    Route::get('subjects', [\App\Http\Controllers\Api\Public\DataController::class, 'subjects']);
    Route::get('subjects/{level}', [\App\Http\Controllers\Api\Public\DataController::class, 'subjects']);
    Route::get('support-settings', [\App\Http\Controllers\Api\Public\DataController::class, 'supportSettings']);
});

// ══════════════════════════════════════════════════════════════
// Admin API — Public (No Auth Required)
// ══════════════════════════════════════════════════════════════
Route::prefix('admin')->group(function () {
    Route::post('login', [AdminAuthController::class, 'login']);
});

// ══════════════════════════════════════════════════════════════
// Admin API — Protected (Sanctum Auth + Admin Role)
// ══════════════════════════════════════════════════════════════
Route::prefix('admin')->middleware(['auth:sanctum'])->group(function () {

    // Auth
    Route::post('logout', [AdminAuthController::class, 'logout']);
    Route::get('me', [AdminAuthController::class, 'me']);
    Route::post('devices/token', [\App\Http\Controllers\Api\DeviceTokenController::class, 'store']);
    Route::delete('devices/token', [\App\Http\Controllers\Api\DeviceTokenController::class, 'destroy']);
    Route::get('devices/status', [\App\Http\Controllers\Api\DeviceTokenController::class, 'status']);
    Route::post('devices/test-push', [\App\Http\Controllers\Api\DeviceTokenController::class, 'test']);

    // Dashboard
    Route::get('dashboard', [AdminDashboardController::class, 'index']);

    // Academic — Universities
    Route::apiResource('universities', AdminUniversityController::class)->names('api.admin.universities');

    // Academic — Colleges
    Route::apiResource('colleges', AdminCollegeController::class)->names('api.admin.colleges');
    Route::apiResource('majors', AdminMajorController::class)->names('api.admin.majors');

    // Academic — Majors
        Route::get('users/{user}/permissions', [AdminUserController::class, 'getPermissions']);
        Route::post('users/{user}/permissions', [AdminUserController::class, 'updatePermissions']);
        Route::apiResource('users', AdminUserController::class)->names('api.admin.users');
    Route::get('majors/{major}/levels', [AdminMajorController::class, 'getLevels']);

    // Academic — Subjects
    Route::apiResource('subjects', AdminSubjectController::class)->names('api.admin.subjects');

    // User Management
    Route::get('users', [AdminUserController::class, 'index']);
    Route::get('users/export', [AdminUserController::class, 'export']);
    Route::patch('users/{user}/status', [AdminUserController::class, 'updateStatus']);
    Route::post('users/{user}/reset-password', [AdminUserController::class, 'resetPassword']);
    Route::post('users/{user}/kick', [AdminUserController::class, 'kickSession']);
    Route::post('users/{user}/activate-subscription', [AdminUserController::class, 'activateSubscription']);
    Route::delete('users/{user}', [AdminUserController::class, 'destroy']);
    Route::post('users/bulk-activate', [AdminUserController::class, 'bulkActivate']);
    Route::post('users/bulk-deactivate', [AdminUserController::class, 'bulkDeactivate']);
    Route::post('users/bulk-delete', [AdminUserController::class, 'bulkDelete']);

    // Registration Requests
    Route::prefix('registration-requests')->group(function () {
        Route::get('/', [AdminRegistrationRequestController::class, 'index']);
        Route::post('approve', [AdminRegistrationRequestController::class, 'approve']);
        Route::post('reject', [AdminRegistrationRequestController::class, 'reject']);
    });

    // Students
    Route::post('students/{student}/permissions', [AdminStudentController::class, 'updatePermissions']);
    Route::apiResource('students', AdminStudentController::class)->names('api.admin.students');

    // Doctors
    Route::apiResource('doctors', AdminDoctorController::class)->names('api.admin.doctors');

    // Delegates
    Route::apiResource('delegates', AdminDelegateController::class)->names('api.admin.delegates');

    // Administrative Officials
    Route::apiResource('administratives', AdminAdministrativeController::class)->names('api.admin.administratives');

    // Clinical Delegates
    Route::apiResource('clinical-delegates', AdminClinicalDelegateController::class)
        ->only(['index', 'store', 'destroy'])->names('api.admin.clinical-delegates');

    // Delegate Transfers
    Route::prefix('delegate-transfer')->group(function () {
        Route::get('/', [AdminDelegateTransferController::class, 'index']);
        Route::get('/{major}/{level}', [AdminDelegateTransferController::class, 'show']);
        Route::post('/execute', [AdminDelegateTransferController::class, 'transfer']);
    });

    // Packages
    Route::post('packages/{package}/toggle', [AdminPackageController::class, 'toggleStatus']);
    Route::get('packages/{package}/subscribers', [AdminPackageController::class, 'subscribers']);
    Route::post('subscriptions/{subscription}/cancel', [AdminPackageController::class, 'cancelSubscription']);
    Route::apiResource('packages', AdminPackageController::class)->names('api.admin.packages');

    // Cards
    Route::post('cards/generate', [AdminCardController::class, 'generate']);
    Route::apiResource('cards', AdminCardController::class)->only(['index', 'destroy'])->names('api.admin.cards');

    // Finance & Transactions
    Route::get('finance/stats', [AdminFinanceController::class, 'index']);
    Route::get('finance/transactions', [AdminFinanceController::class, 'transactions']);

    // Storage Management
    Route::prefix('storage')->group(function () {
        Route::get('stats', [AdminStorageController::class, 'index']);
        Route::get('files', [AdminStorageController::class, 'files']);
        Route::post('delete', [AdminStorageController::class, 'destroy']);
    });

    // Reports
    Route::prefix('reports')->group(function () {
        Route::get('overview', [AdminReportController::class, 'overview']);
        Route::get('subject', [AdminReportController::class, 'subject']);
        Route::get('threshold', [AdminReportController::class, 'threshold']);
        Route::get('doctor-performance', [AdminReportController::class, 'doctorPerformance']);
        Route::get('system-overview', [AdminReportController::class, 'systemOverview']);
    });

    // Clinical Master Data
    Route::prefix('clinical')->middleware('clinical_delegate')->group(function () {
        Route::apiResource('departments', AdminClinicalDepartmentController::class);
        Route::apiResource('body-systems', AdminBodySystemController::class);
        Route::apiResource('checklists', AdminEvaluationChecklistController::class);
    });

    // Info & Support
    Route::get('info/developer', [AdminInfoController::class, 'developer']);
    Route::get('info/system', [AdminInfoController::class, 'system']);
    Route::post('change-password', [AdminAuthController::class, 'changePassword']);

    // Settings
    Route::get('settings', [AdminSettingController::class, 'index']);
    Route::put('settings', [AdminSettingController::class, 'update']);

    // Activity Log
    Route::get('activities', [AdminActivityController::class, 'index']);
    Route::delete('activities/cleanup', [AdminActivityController::class, 'cleanup']);

    // Flashcard / One Line Shot Management
    Route::prefix('flashcards')->group(function () {
        Route::get('/', [AdminFlashcardController::class, 'index']);
        Route::post('/', [AdminFlashcardController::class, 'store']);
        Route::get('{id}', [AdminFlashcardController::class, 'show']);
        Route::put('{id}', [AdminFlashcardController::class, 'update']);
        Route::delete('{id}', [AdminFlashcardController::class, 'destroy']);
        Route::post('{id}/publish', [AdminFlashcardController::class, 'publishToStore']);
        Route::post('{id}/toggle-featured', [AdminFlashcardController::class, 'toggleFeatured']);
        Route::post('{id}/assign', [AdminFlashcardController::class, 'assignToUser']);
        Route::post('{id}/import', [AdminFlashcardController::class, 'import']);
        Route::post('{id}/items', [AdminFlashcardController::class, 'storeItem']);
        Route::put('items/{itemId}', [AdminFlashcardController::class, 'updateItem']);
        Route::delete('items/{itemId}', [AdminFlashcardController::class, 'destroyItem']);
    });

    // Quiz Management
    Route::prefix('quizzes')->group(function () {
        Route::post('{quiz}/publish', [AdminApiQuizController::class, 'publish']);
        Route::post('{quiz}/close', [AdminApiQuizController::class, 'close']);
        Route::get('{quiz}/results', [AdminApiQuizController::class, 'results']);
    });
    Route::apiResource('quizzes', AdminApiQuizController::class)->names('api.admin.quizzes');

    // Star Management
    Route::prefix('stars')->group(function () {
        Route::get('students', [AdminApiStarController::class, 'index']);
        Route::post('grant', [AdminApiStarController::class, 'grant']);
    });

    // Shared Library Management
    Route::get('library/{id}/download', [LibraryController::class, 'download'])->name('api.admin.library.download');
    Route::post('library/bulk-delete', [LibraryController::class, 'bulkDestroy']);
    Route::apiResource('library', LibraryController::class)->names('api.admin.library');
});

// ══════════════════════════════════════════════════════════════
// Delegate API — Public (No Auth Required)
// ══════════════════════════════════════════════════════════════
Route::prefix('delegate')->group(function () {
    Route::post('login', [DelegateAuthController::class, 'login']);
});

// ══════════════════════════════════════════════════════════════
// Delegate API — Protected (Sanctum Auth + Delegate Role)
// ══════════════════════════════════════════════════════════════
Route::prefix('delegate')->middleware(['auth:sanctum', 'device.validate'])->group(function () {

    // Auth
    Route::post('logout', [DelegateAuthController::class, 'logout']);
    Route::post('change-password', [DelegateAuthController::class, 'changePassword']);
    Route::get('me', [DelegateAuthController::class, 'me']);
    Route::post('devices/token', [\App\Http\Controllers\Api\DeviceTokenController::class, 'store']);
    Route::delete('devices/token', [\App\Http\Controllers\Api\DeviceTokenController::class, 'destroy']);
    Route::get('devices/status', [\App\Http\Controllers\Api\DeviceTokenController::class, 'status']);
    Route::post('devices/test-push', [\App\Http\Controllers\Api\DeviceTokenController::class, 'test']);
    Route::post('desktop/pairing-code', [\App\Http\Controllers\DesktopPairingCodeController::class, 'issueForDelegate']);

    // Dashboard
    Route::get('dashboard', [DelegateDashboardController::class, 'index']);

    // Notifications & Absence Alerts
    Route::get('notifications', [DelegateNotificationController::class, 'index']);
    Route::post('notifications', [DelegateNotificationController::class, 'store']);
    Route::post('notifications/{id}/read', [DelegateNotificationController::class, 'markAsRead']);
    Route::post('notifications/mark-all-read', [DelegateNotificationController::class, 'markAllAsRead']);

    // Basic Connectivity Test
    Route::get('health-check', function() { return response()->json(['status' => 'ok', 'user' => request()->user()->name]); });

    // Academic
    Route::get('students', [DelegateStudentController::class, 'index']);
    Route::get('students/template', [DelegateStudentController::class, 'template']);
    Route::post('students', [DelegateStudentController::class, 'store']);
    Route::patch('students/{student}', [DelegateStudentController::class, 'update']);
    Route::get('students/{student}/permissions', [DelegateStudentController::class, 'permissions']);
    Route::post('students/{student}/permissions', [DelegateStudentController::class, 'updatePermissions']);
    Route::delete('students/{student}', [DelegateStudentController::class, 'destroy']);
    Route::post('students/import', [DelegateStudentController::class, 'import']);
    
    Route::get('subjects/doctors', [DelegateSubjectController::class, 'doctors']);
    Route::get('subjects/terms', [DelegateSubjectController::class, 'terms']);
    Route::apiResource('subjects', DelegateSubjectController::class)->names('api.delegate.subjects');
    
    Route::apiResource('schedules', DelegateScheduleController::class)->names('api.delegate.schedules');
    Route::apiResource('exam-schedules', DelegateExamScheduleController::class)->names('api.delegate.exam-schedules');
    Route::get('assignments/permissions', [DelegateAssignmentController::class, 'permissions']);
    Route::apiResource('assignments', DelegateAssignmentController::class)->names('api.delegate.assignments');
    
    Route::get('resources/library/search', [DelegateResourceController::class, 'searchLibrary']);
    Route::post('resources/import', [DelegateResourceController::class, 'import']);
    Route::apiResource('resources', DelegateResourceController::class)->names('api.delegate.resources');

    // Communication
    Route::patch('announcements/{announcement}/toggle-pin', [DelegateAnnouncementController::class, 'togglePin']);
    Route::apiResource('announcements', DelegateAnnouncementController::class)->names('api.delegate.announcements');
    Route::apiResource('reminders', DelegateReminderController::class)->except(['show'])->names('api.delegate.reminders');

    // News Center (College Admin News)
    Route::prefix('news')->group(function () {
        Route::get('/', [\App\Http\Controllers\Api\Delegate\NewsController::class, 'index']);
        Route::get('{batchId}', [\App\Http\Controllers\Api\Delegate\NewsController::class, 'show']);
        Route::post('{batchId}/vote', [\App\Http\Controllers\Api\Delegate\NewsController::class, 'vote']);
        Route::post('{batchId}/read', [\App\Http\Controllers\Api\Delegate\NewsController::class, 'markAsRead']);
        Route::post('read-all', [\App\Http\Controllers\Api\Delegate\NewsController::class, 'markAllAsRead']);
    });

    // Messaging
    Route::get('messages/eligible-students', [DelegateMessageController::class, 'eligibleStudents']);
    Route::get('messages', [DelegateMessageController::class, 'index']);
    Route::get('messages/{user}', [DelegateMessageController::class, 'show']);
    Route::post('messages', [DelegateMessageController::class, 'store']);

    // Doctor Communication
    Route::get('doctor-chats/eligible-doctors', [DelegateDoctorChatController::class, 'eligibleDoctors']);
    Route::get('doctor-chats', [DelegateDoctorChatController::class, 'index']);
    Route::get('doctor-chats/{doctor}', [DelegateDoctorChatController::class, 'show']);
    Route::post('doctor-chats', [DelegateDoctorChatController::class, 'store']);

    Route::get('inquiries', [DelegateInquiryController::class, 'index']);
    Route::get('inquiries/{inquiry}', [DelegateInquiryController::class, 'show']);
    Route::post('inquiries/{inquiry}/reply', [DelegateInquiryController::class, 'storeReply']);
    Route::post('inquiries/{inquiry}/forward', [DelegateInquiryController::class, 'forward']);
    Route::patch('inquiries/{inquiry}/status', [DelegateInquiryController::class, 'updateStatus']);

    // Tracking
    Route::get('attendances/alerts', [DelegateAttendanceController::class, 'alerts']);
    Route::get('attendances', [DelegateAttendanceController::class, 'index']);
    Route::get('attendances/{subject}/create', [DelegateAttendanceController::class, 'create']);
    Route::post('attendances', [DelegateAttendanceController::class, 'store']);
    Route::get('attendances/{subject_id}/{date}/report', [DelegateAttendanceController::class, 'report']);
    Route::get('attendances/{subject_id}/{date}/report-pdf', [DelegateAttendanceController::class, 'reportPdf']);
    Route::get('attendances/{lecture}', [DelegateAttendanceController::class, 'show']);
    Route::get('attendance-edit-requests', [\App\Http\Controllers\Api\AttendanceEditRequestController::class, 'index']);
    Route::post('attendance-edit-requests', [\App\Http\Controllers\Api\AttendanceEditRequestController::class, 'store']);

    Route::get('authorized-grades', [\App\Http\Controllers\Api\Delegate\AuthorizedGradeController::class, 'index']);
    Route::get('authorized-grades/{category}', [\App\Http\Controllers\Api\Delegate\AuthorizedGradeController::class, 'show']);
    Route::post('authorized-grades/{category}/store', [\App\Http\Controllers\Api\Delegate\AuthorizedGradeController::class, 'store']);
    Route::prefix('qr-attendance')->group(function () {
        Route::post('start', [QrAttendanceController::class, 'startSession']);
        Route::get('active', [QrAttendanceController::class, 'active']);
        Route::get('{session}/token', [QrAttendanceController::class, 'rotateToken']);
        Route::get('{session}/status', [QrAttendanceController::class, 'getStatus']);
        Route::post('{session}/finalize', [QrAttendanceController::class, 'finalize']);
        Route::post('{session}/cancel', [QrAttendanceController::class, 'cancel']);
    });
    Route::get('grade-helper-delegations', [\App\Http\Controllers\Api\Delegate\GradeHelperDelegationController::class, 'index']);
    Route::get('grade-helper-delegations/students', [\App\Http\Controllers\Api\Delegate\GradeHelperDelegationController::class, 'getStudents']);
    Route::post('grade-helper-delegations', [\App\Http\Controllers\Api\Delegate\GradeHelperDelegationController::class, 'store']);
    Route::delete('grade-helper-delegations/{delegation}', [\App\Http\Controllers\Api\Delegate\GradeHelperDelegationController::class, 'revoke']);


    // Clinical - Sub-Delegation & Case Review
    Route::prefix('clinical')->group(function () {
        Route::get('delegations', [DelegateSubDelegationController::class, 'index']);
        Route::get('delegations/students', [DelegateSubDelegationController::class, 'getStudents']);
        Route::post('delegations', [DelegateSubDelegationController::class, 'store']);
        Route::delete('delegations/{id}', [DelegateSubDelegationController::class, 'revoke']);

        Route::get('cases/pending', [DelegateClinicalCaseController::class, 'pending']);
        Route::post('cases/{id}/approve', [DelegateClinicalCaseController::class, 'approve']);
        Route::post('cases/{id}/reject', [DelegateClinicalCaseController::class, 'reject']);
    });

    // Financial & Subscription (Delegates use student logic but via delegate prefix)
    Route::get('subscription', [\App\Http\Controllers\Api\Delegate\SubscriptionController::class, 'index']);
    Route::post('subscription/redeem', [\App\Http\Controllers\Api\Delegate\SubscriptionController::class, 'redeem']);
    Route::post('subscription/subscribe', [\App\Http\Controllers\Api\Delegate\SubscriptionController::class, 'subscribe']);
    Route::post('subscription/auto-renew', [\App\Http\Controllers\Api\Delegate\SubscriptionController::class, 'toggleAutoRenew']);

    Route::get('ledger', [\App\Http\Controllers\Api\Delegate\FinancialController::class, 'ledger']);
    Route::get('ledger/export', [\App\Http\Controllers\Api\Delegate\FinancialController::class, 'exportPdf']);
});

// ══════════════════════════════════════════════════════════════
// QR Attendance API
// ══════════════════════════════════════════════════════════════
Route::middleware(['web', 'auth'])->prefix('qr-attendance')->group(function () {

    // ── Delegate Endpoints ──
    Route::post('start', [QrAttendanceController::class, 'startSession']);
    Route::get('{session}/token', [QrAttendanceController::class, 'rotateToken']);
    Route::get('{session}/status', [QrAttendanceController::class, 'getStatus']);
    Route::post('{session}/finalize', [QrAttendanceController::class, 'finalize']);

    // ── Student Endpoint ──
    // Student web scanner should use the authenticated session directly.
    Route::post('scan', [QrAttendanceController::class, 'scan']);
});

Route::prefix('desktop')->group(function () {
    Route::post('pairing/exchange', [DesktopAuthController::class, 'exchange']);

    Route::middleware(['auth:sanctum', 'desktop.token'])->group(function () {
        Route::get('me', [DesktopAuthController::class, 'me']);
        Route::post('logout', [DesktopAuthController::class, 'logout']);

        Route::prefix('qr-attendance')->group(function () {
            Route::get('subjects', [DesktopAttendanceController::class, 'subjects']);
            Route::post('start', [QrAttendanceController::class, 'startSession']);
            Route::get('{session}/token', [QrAttendanceController::class, 'rotateToken']);
            Route::get('{session}/status', [QrAttendanceController::class, 'getStatus']);
            Route::post('{session}/finalize', [QrAttendanceController::class, 'finalize']);
        });
    });
});

// ══════════════════════════════════════════════════════════════
// Student API Controllers
// ══════════════════════════════════════════════════════════════
use App\Http\Controllers\Api\Student\AuthController as StudentAuthController;
use App\Http\Controllers\Api\Student\DashboardController as StudentDashboardController;
use App\Http\Controllers\Api\Student\SubjectController as StudentSubjectController;
use App\Http\Controllers\Api\Student\AssignmentController as StudentAssignmentController;
use App\Http\Controllers\Api\Student\AttendanceController as StudentAttendanceController;
use App\Http\Controllers\Api\Student\Clinical\LogbookController as StudentLogbookController;
use App\Http\Controllers\Api\Student\Clinical\EvaluationController as StudentEvaluationController;
use App\Http\Controllers\Api\Student\Clinical\MockExamController as StudentMockExamController;
use App\Http\Controllers\Api\Student\Clinical\ClinicalCaseController as StudentClinicalCaseController;
use App\Http\Controllers\Api\Student\ScheduleController as StudentBatchScheduleController;

// ══════════════════════════════════════════════════════════════
// Student API — Public (No Auth Required)
// ══════════════════════════════════════════════════════════════
Route::prefix('administrative')->group(function () {
    Route::post('login', [\App\Http\Controllers\Api\Administrative\AuthController::class, 'login']);
});

Route::prefix('administrative')->middleware(['auth:sanctum', 'administrative', 'status'])->group(function () {
    Route::post('logout', [\App\Http\Controllers\Api\Administrative\AuthController::class, 'logout']);
    Route::get('me', [\App\Http\Controllers\Api\Administrative\AuthController::class, 'me']);
    Route::post('change-password', [\App\Http\Controllers\Api\Administrative\AuthController::class, 'changePassword']);
    Route::post('devices/token', [\App\Http\Controllers\Api\DeviceTokenController::class, 'store']);
    Route::delete('devices/token', [\App\Http\Controllers\Api\DeviceTokenController::class, 'destroy']);
    Route::get('devices/status', [\App\Http\Controllers\Api\DeviceTokenController::class, 'status']);
    Route::post('devices/test-push', [\App\Http\Controllers\Api\DeviceTokenController::class, 'test']);

    Route::get('dashboard', [\App\Http\Controllers\Api\Administrative\DashboardController::class, 'index']);

    Route::get('subscription', [\App\Http\Controllers\Api\Administrative\SubscriptionController::class, 'index']);
    Route::post('subscription/redeem', [\App\Http\Controllers\Api\Administrative\SubscriptionController::class, 'redeem']);
    Route::post('subscription/subscribe', [\App\Http\Controllers\Api\Administrative\SubscriptionController::class, 'subscribe']);
    Route::post('subscription/auto-renew', [\App\Http\Controllers\Api\Administrative\SubscriptionController::class, 'toggleAutoRenew']);

    Route::get('ledger', [\App\Http\Controllers\Api\Administrative\FinancialController::class, 'ledger']);
    Route::get('ledger/export', [\App\Http\Controllers\Api\Administrative\FinancialController::class, 'exportPdf']);

    Route::middleware('subscribed')->group(function () {
        Route::get('settings', [\App\Http\Controllers\Administrative\ApiCollegeSettingsController::class, 'show']);
        Route::put('settings', [\App\Http\Controllers\Administrative\ApiCollegeSettingsController::class, 'update']);

        Route::get('delegates', [\App\Http\Controllers\Api\Administrative\DelegateController::class, 'index']);
        Route::patch('delegates/{user}/role', [\App\Http\Controllers\Api\Administrative\DelegateController::class, 'updateRole']);
        Route::post('delegates/{user}/permissions', [\App\Http\Controllers\Api\Administrative\DelegateController::class, 'updatePermissions']);

        Route::get('majors/{major}/levels', [\App\Http\Controllers\Api\Administrative\MajorController::class, 'getLevels']);

        Route::get('notifications/create-data', [\App\Http\Controllers\Api\Administrative\NotificationController::class, 'createData']);
        Route::get('notifications', [\App\Http\Controllers\Api\Administrative\NotificationController::class, 'index']);
        Route::post('notifications', [\App\Http\Controllers\Api\Administrative\NotificationController::class, 'store']);
        Route::get('notifications/{batchId}', [\App\Http\Controllers\Api\Administrative\NotificationController::class, 'show']);
        Route::delete('notifications/{batchId}', [\App\Http\Controllers\Api\Administrative\NotificationController::class, 'destroy']);

        Route::get('excuses', [\App\Http\Controllers\Administrative\ApiExcuseManagementController::class, 'index']);
        Route::patch('excuses/{excuse}', [\App\Http\Controllers\Administrative\ApiExcuseManagementController::class, 'update']);
        Route::patch('attendance/{attendance}', [\App\Http\Controllers\Administrative\ApiAttendanceController::class, 'update']);

        Route::get('reports', [\App\Http\Controllers\Administrative\ApiReportController::class, 'index']);
        Route::get('reports/attendance', [\App\Http\Controllers\Administrative\ApiReportController::class, 'attendance']);
          Route::get('reports/subject/pdf', [\App\Http\Controllers\Api\Administrative\ReportController::class, 'subjectPdf']);
          Route::get('reports/subject/excel', [\App\Http\Controllers\Api\Administrative\ReportController::class, 'subjectExcel']);
          Route::get('reports/subject', [\App\Http\Controllers\Api\Administrative\ReportController::class, 'subjectReport']);
          Route::get('reports/threshold/pdf', [\App\Http\Controllers\Api\Administrative\ReportController::class, 'thresholdPdf']);
          Route::get('reports/threshold/excel', [\App\Http\Controllers\Api\Administrative\ReportController::class, 'thresholdExcel']);
          Route::post('reports/threshold/notify', [\App\Http\Controllers\Api\Administrative\ReportController::class, 'notifyThreshold']);
          Route::get('reports/threshold', [\App\Http\Controllers\Api\Administrative\ReportController::class, 'thresholdReport']);
          Route::get('reports/level-summary/pdf', [\App\Http\Controllers\Api\Administrative\ReportController::class, 'levelSummaryPdf']);
          Route::get('reports/level-summary/excel', [\App\Http\Controllers\Api\Administrative\ReportController::class, 'levelSummaryExcel']);
          Route::get('reports/level-summary', [\App\Http\Controllers\Api\Administrative\ReportController::class, 'levelSummary']);
          Route::get('reports/doctor-performance/pdf', [\App\Http\Controllers\Api\Administrative\ReportController::class, 'doctorPerformancePdf']);
          Route::get('reports/doctor-performance/excel', [\App\Http\Controllers\Api\Administrative\ReportController::class, 'doctorPerformanceExcel']);
          Route::get('reports/doctor-performance', [\App\Http\Controllers\Api\Administrative\ReportController::class, 'doctorPerformance']);
          Route::get('reports/comparison/excel', [\App\Http\Controllers\Api\Administrative\ReportController::class, 'comparisonExcel']);
          Route::get('reports/comparison', [\App\Http\Controllers\Api\Administrative\ReportController::class, 'comparison']);

        Route::apiResource('students', \App\Http\Controllers\Api\Administrative\StudentController::class);
        Route::get('doctors/{doctor}/star-wallet', [\App\Http\Controllers\Api\Administrative\DoctorController::class, 'starWallet']);
        Route::post('doctors/{doctor}/star-wallet/top-up', [\App\Http\Controllers\Api\Administrative\DoctorController::class, 'topUpStarWallet']);
        Route::apiResource('doctors', \App\Http\Controllers\Api\Administrative\DoctorController::class);
        Route::apiResource('majors', \App\Http\Controllers\Api\Administrative\MajorController::class)->except(['create', 'edit']);
        Route::apiResource('subjects', \App\Http\Controllers\Api\Administrative\SubjectController::class)->except(['create', 'edit']);

        Route::get('exams/create-data', [\App\Http\Controllers\Api\Administrative\ExamScheduleController::class, 'createData']);
        Route::get('exams/helper/levels/{major}', [\App\Http\Controllers\Api\Administrative\ExamScheduleController::class, 'getLevels']);
        Route::get('exams/helper/subjects/{level}', [\App\Http\Controllers\Api\Administrative\ExamScheduleController::class, 'getSubjects']);
        Route::apiResource('exams', \App\Http\Controllers\Api\Administrative\ExamScheduleController::class)->except(['create', 'edit']);

        Route::get('schedules/create-data', [\App\Http\Controllers\Api\Administrative\AcademicScheduleController::class, 'createData']);
        Route::get('schedules/helper/subjects/{level}', [\App\Http\Controllers\Api\Administrative\AcademicScheduleController::class, 'getSubjectsWithDoctors']);
        Route::apiResource('schedules', \App\Http\Controllers\Api\Administrative\AcademicScheduleController::class)->except(['create', 'edit']);
    });
});

Route::prefix('student')->group(function () {
    Route::post('login', [StudentAuthController::class, 'login']);
});

// ══════════════════════════════════════════════════════════════
// Student API — Protected (Sanctum Auth + CheckUserStatus)
// ══════════════════════════════════════════════════════════════
Route::prefix('student')->middleware(['auth:sanctum', \App\Http\Middleware\CheckUserStatus::class, 'device.validate'])->group(function () {

    // Auth & Profile
    Route::post('logout', [StudentAuthController::class, 'logout']);
    Route::post('change-password', [StudentAuthController::class, 'changePassword']);
    Route::patch('profile/email', [StudentAuthController::class, 'updateEmail']);
    Route::get('me', [StudentAuthController::class, 'me']);
    Route::get('support-settings', [StudentAuthController::class, 'supportSettings']);
    Route::post('devices/request', [StudentAuthController::class, 'storeDeviceRequest']);
    Route::post('devices/token', [\App\Http\Controllers\Api\DeviceTokenController::class, 'store']);
    Route::delete('devices/token', [\App\Http\Controllers\Api\DeviceTokenController::class, 'destroy']);
    Route::get('devices/status', [\App\Http\Controllers\Api\DeviceTokenController::class, 'status']);
    Route::post('devices/test-push', [\App\Http\Controllers\Api\DeviceTokenController::class, 'test']);

    // ─── News Center ───
    Route::get('news-hub', [\App\Http\Controllers\Api\Student\NewsHubController::class, 'index']);
    Route::get('announcements', [\App\Http\Controllers\Api\Student\AnnouncementController::class, 'index']);
    Route::get('doctor-announcements', [\App\Http\Controllers\Api\Student\DoctorAnnouncementController::class, 'index']);
    Route::get('notifications', [\App\Http\Controllers\Api\Student\NotificationController::class, 'index']);
    Route::get('notifications/unread-count', [\App\Http\Controllers\Api\Student\NotificationController::class, 'unreadCount']);
    Route::post('notifications/{id}/read', [\App\Http\Controllers\Api\Student\NotificationController::class, 'markAsRead']);
    Route::post('notifications/{id}/vote', [\App\Http\Controllers\Api\Student\NotificationController::class, 'vote']);
    Route::delete('notifications/{id}/vote', [\App\Http\Controllers\Api\Student\NotificationController::class, 'unvote']);
    Route::post('notifications/mark-all-read', [\App\Http\Controllers\Api\Student\NotificationController::class, 'markAllAsRead']);
    Route::get('reminders', [\App\Http\Controllers\Api\Student\ReminderController::class, 'index']);
    Route::get('resources', [\App\Http\Controllers\Api\Student\ResourceController::class, 'index']);

    // Dashboard
    Route::get('dashboard', [StudentDashboardController::class, 'index']);

    // Subjects, Lectures & Library
    Route::get('subjects', [StudentSubjectController::class, 'index']);
    Route::get('subjects/{subject_id}', [StudentSubjectController::class, 'show']);
    Route::post('lectures/{lecture_id}/toggle-listen', [StudentSubjectController::class, 'toggleListen']);

    // Shared Study Library
    Route::get('library', [\App\Http\Controllers\Api\Student\LibraryController::class, 'index']);
    Route::post('library/upload', [\App\Http\Controllers\Api\Student\LibraryController::class, 'store']);
    Route::get('library/{resource}/download', [\App\Http\Controllers\Api\Student\LibraryController::class, 'incrementDownload']);


    // Batch Study Schedule & Exams
    Route::get('schedules', [StudentBatchScheduleController::class, 'index']); // (Read-only mirror of Delegate's)
    Route::get('exams', [\App\Http\Controllers\Api\Student\ExamScheduleController::class, 'index']);

    // Student Schedule (Smart Study Hub) - legacy /schedule alias + canonical /study-center
    Route::get('study-center', [\App\Http\Controllers\Api\Student\StudentScheduleController::class, 'index']);
    Route::post('study-center', [\App\Http\Controllers\Api\Student\StudentScheduleController::class, 'store']);
    Route::post('study-center/custom-task', [\App\Http\Controllers\Api\Student\StudentScheduleController::class, 'storeCustomTask']);
    Route::get('study-center/check-reminders', [\App\Http\Controllers\Api\Student\StudentScheduleController::class, 'checkReminders']);
    Route::get('study-center/{id}/session', [\App\Http\Controllers\Api\Student\StudentScheduleController::class, 'session']);
    Route::post('study-center/{id}/columns', [\App\Http\Controllers\Api\Student\StudentScheduleController::class, 'storeColumn']);
    Route::put('study-center/columns/{column}', [\App\Http\Controllers\Api\Student\StudentScheduleController::class, 'updateColumn']);
    Route::delete('study-center/columns/{column}', [\App\Http\Controllers\Api\Student\StudentScheduleController::class, 'destroyColumn']);
    Route::post('study-center/columns/{column}/increment', [\App\Http\Controllers\Api\Student\StudentScheduleController::class, 'incrementColumn']);
    Route::post('study-center/columns/{column}/undo-last-action', [\App\Http\Controllers\Api\Student\StudentScheduleController::class, 'undoColumnLastAction']);
    Route::post('study-center/{id}/undo-last-action', [\App\Http\Controllers\Api\Student\StudentScheduleController::class, 'undoLastAction']);
    Route::put('study-center/{id}', [\App\Http\Controllers\Api\Student\StudentScheduleController::class, 'update']);
    Route::delete('study-center/{id}', [\App\Http\Controllers\Api\Student\StudentScheduleController::class, 'destroy']);
    Route::post('study-center/reorder', [\App\Http\Controllers\Api\Student\StudentScheduleController::class, 'reorder']);
    Route::get('schedule', [\App\Http\Controllers\Api\Student\StudentScheduleController::class, 'index']);
    Route::post('schedule', [\App\Http\Controllers\Api\Student\StudentScheduleController::class, 'store']);
    Route::post('schedule/custom-task', [\App\Http\Controllers\Api\Student\StudentScheduleController::class, 'storeCustomTask']);
    Route::get('schedule/check-reminders', [\App\Http\Controllers\Api\Student\StudentScheduleController::class, 'checkReminders']);
    Route::put('schedule/{id}', [\App\Http\Controllers\Api\Student\StudentScheduleController::class, 'update']);
    Route::delete('schedule/{id}', [\App\Http\Controllers\Api\Student\StudentScheduleController::class, 'destroy']);
    Route::post('schedule/reorder', [\App\Http\Controllers\Api\Student\StudentScheduleController::class, 'reorder']);

    // Assignments
    Route::get('assignments', [StudentAssignmentController::class, 'index']);
    Route::post('assignments/preference', [StudentAssignmentController::class, 'updatePreference']);
    Route::get('assignments/{assignment_id}/details', [StudentAssignmentController::class, 'getDetails']);
    Route::get('assignments/{assignment_id}', [StudentAssignmentController::class, 'show']);
    Route::post('assignments/{assignment_id}/submit', [StudentAssignmentController::class, 'submit']);
    Route::post('assignments/{assignment_id}/priority', [StudentAssignmentController::class, 'updatePriority']);

    // Card Generation (Balance-based)
    Route::middleware('permission:generate_cards')->group(function () {
        Route::get('cards-generate', [\App\Http\Controllers\Api\Student\CardGenerationController::class, 'index']);
        Route::post('cards-generate', [\App\Http\Controllers\Api\Student\CardGenerationController::class, 'generate']);
    });

    // Subscription Management
    Route::get('subscription', [\App\Http\Controllers\Api\Student\SubscriptionController::class, 'index']);
    Route::post('subscription/redeem', [\App\Http\Controllers\Api\Student\SubscriptionController::class, 'redeem']);
    Route::post('subscription/subscribe', [\App\Http\Controllers\Api\Student\SubscriptionController::class, 'subscribe']);
    Route::post('subscription/auto-renew', [\App\Http\Controllers\Api\Student\SubscriptionController::class, 'toggleAutoRenew']);

    // Messages (Chat System)
    Route::get('messages', [\App\Http\Controllers\Api\Student\MessageController::class, 'index']);
    Route::get('messages/start', [\App\Http\Controllers\Api\Student\MessageController::class, 'start']);
    Route::get('messages/{conversation}', [\App\Http\Controllers\Api\Student\MessageController::class, 'show']);
    Route::post('messages/{conversation}/send', [\App\Http\Controllers\Api\Student\MessageController::class, 'send']);

    // Inquiries (Doctor Questions)
    Route::get('inquiries', [\App\Http\Controllers\Api\Student\InquiryController::class, 'index']);
    Route::get('inquiries/options', [\App\Http\Controllers\Api\Student\InquiryController::class, 'options']);
    Route::post('inquiries', [\App\Http\Controllers\Api\Student\InquiryController::class, 'store']);
    Route::get('inquiries/{inquiry}', [\App\Http\Controllers\Api\Student\InquiryController::class, 'show']);

    // Financial Ledger
    Route::get('ledger', [\App\Http\Controllers\Api\Student\FinancialController::class, 'ledger']);
    Route::get('ledger/export', [\App\Http\Controllers\Api\Student\FinancialController::class, 'exportPdf']);

    Route::get('flashcard-settings', [\App\Http\Controllers\Api\Student\FlashcardController::class, 'settings']);
    Route::put('flashcard-settings', [\App\Http\Controllers\Api\Student\FlashcardController::class, 'updateUserSettings']);

    // Flashcard / One Line Shot
    Route::prefix('flashcards')->group(function () {
        Route::get('/', [\App\Http\Controllers\Api\Student\FlashcardController::class, 'index']);
        Route::post('/', [\App\Http\Controllers\Api\Student\FlashcardController::class, 'store']);
        Route::get('store', [\App\Http\Controllers\Api\Student\FlashcardController::class, 'publicStore']);
        Route::post('clone/{id}', [\App\Http\Controllers\Api\Student\FlashcardController::class, 'clonePack']);
        Route::get('daily-queue', [\App\Http\Controllers\Api\Student\FlashcardController::class, 'getDailyQueue']);
        Route::get('one-line-notifications', [\App\Http\Controllers\Api\Student\FlashcardController::class, 'oneLineNotifications']);
        Route::get('upcoming', [\App\Http\Controllers\Api\Student\FlashcardController::class, 'upcoming']);
        Route::get('history', [\App\Http\Controllers\Api\Student\FlashcardController::class, 'history']);
        Route::get('difficulty', [\App\Http\Controllers\Api\Student\FlashcardController::class, 'difficulty']);
        Route::get('analytics', [\App\Http\Controllers\Api\Student\FlashcardController::class, 'analytics']);
        Route::get('import-template', [\App\Http\Controllers\Api\Student\FlashcardController::class, 'downloadImportTemplate']);
        Route::get('settings', [\App\Http\Controllers\Api\Student\FlashcardController::class, 'settings']);
        Route::put('settings', [\App\Http\Controllers\Api\Student\FlashcardController::class, 'updateUserSettings']);
        Route::post('progress', [\App\Http\Controllers\Api\Student\FlashcardController::class, 'recordProgress']);
        Route::get('{id}', [\App\Http\Controllers\Api\Student\FlashcardController::class, 'show']);
        Route::put('{id}', [\App\Http\Controllers\Api\Student\FlashcardController::class, 'update']);
        Route::delete('{id}', [\App\Http\Controllers\Api\Student\FlashcardController::class, 'destroy']);
        Route::post('{id}/toggle', [\App\Http\Controllers\Api\Student\FlashcardController::class, 'toggleActive']);
        Route::put('{id}/settings', [\App\Http\Controllers\Api\Student\FlashcardController::class, 'updateSettings']);
        Route::post('{id}/import-preview', [\App\Http\Controllers\Api\Student\FlashcardController::class, 'importPreview']);
        Route::post('{id}/import-confirm', [\App\Http\Controllers\Api\Student\FlashcardController::class, 'importConfirm']);
        Route::post('{id}/import', [\App\Http\Controllers\Api\Student\FlashcardController::class, 'import']);
        Route::post('{id}/items', [\App\Http\Controllers\Api\Student\FlashcardController::class, 'storeItem']);
        Route::put('items/{itemId}', [\App\Http\Controllers\Api\Student\FlashcardController::class, 'updateItem']);
        Route::delete('items/{itemId}', [\App\Http\Controllers\Api\Student\FlashcardController::class, 'destroyItem']);
        Route::get('{id}/review', [\App\Http\Controllers\Api\Student\FlashcardController::class, 'review']);
    });

    // PDF Reports
    Route::get('reports/attendance', [\App\Http\Controllers\Api\Student\ReportController::class, 'attendancePdf']);
    Route::get('reports/grades', [\App\Http\Controllers\Api\Student\ReportController::class, 'gradesPdf']);
    Route::get('reports/exams', [\App\Http\Controllers\Api\Student\ReportController::class, 'examsPdf']);

    // Attendance & Grades
    Route::get('attendance', [StudentAttendanceController::class, 'index']);
    Route::get('grades', [\App\Http\Controllers\Api\Student\GradeController::class, 'index']);
    Route::post('excuse', [\App\Http\Controllers\Api\Student\ExcuseController::class, 'store']);

    // Clinical Section
    Route::prefix('clinical')->middleware('clinical.major')->group(function () {

        // Logbook
        Route::get('logbook', [StudentLogbookController::class, 'index']);
        Route::post('logbook', [StudentLogbookController::class, 'store']);
        Route::post('logbook/{log_id}/regenerate-qr', [StudentLogbookController::class, 'regenerateQr']);
        Route::put('logbook/{log_id}', [StudentLogbookController::class, 'update']);
        Route::delete('logbook/{log_id}', [StudentLogbookController::class, 'destroy']);
        Route::post('assignments/{assignment_id}/submit-review', [StudentLogbookController::class, 'submitAssignment']);
        Route::get('logbook/export-pdf', [StudentLogbookController::class, 'exportPdf']);

        // Evaluations (OSCE)
        Route::get('evaluations', [StudentEvaluationController::class, 'index']);
        Route::get('evaluations/{evaluation}', [StudentEvaluationController::class, 'show']);

        // Mock Exams
        Route::get('mock-exams', [StudentMockExamController::class, 'index']);
        Route::post('mock-exams/custom', [StudentMockExamController::class, 'storeCustom']);
        Route::delete('mock-exams/custom/{checklist_id}', [StudentMockExamController::class, 'destroyCustom']);
        Route::get('mock-exams/{checklist_id}/take', [StudentMockExamController::class, 'take']);
        Route::post('mock-exams/{checklist_id}/submit', [StudentMockExamController::class, 'submit']);
        Route::get('mock-exams/results/{evaluation_id}', [StudentMockExamController::class, 'showResult']);

        // Pending Cases for Sub-Delegates
        Route::middleware('clinical_delegate')->group(function () {
            Route::get('cases/pending', [StudentClinicalCaseController::class, 'pending']);
        });

        // Rare Cases
        Route::get('rare-cases', [StudentRareCaseController::class, 'index']);
        Route::get('rare-cases/{id}', [StudentRareCaseController::class, 'show']);

    });

    // ─── Quizzes (MCQ Exams) ───
    Route::middleware('device.primary')->group(function () {
        Route::get('quizzes', [\App\Http\Controllers\Api\Student\QuizController::class, 'index']);
        Route::get('quizzes/{quiz}/take', [\App\Http\Controllers\Api\Student\QuizController::class, 'take']);
        Route::post('quizzes/{attempt}/submit', [\App\Http\Controllers\Api\Student\QuizController::class, 'submit']);
        Route::get('quizzes/results/{attempt}', [\App\Http\Controllers\Api\Student\QuizController::class, 'result']);
    });

    // ─── My Stars (نجومي) ───
    Route::get('stars', [\App\Http\Controllers\Api\Student\StarController::class, 'index']);
    Route::get('stars/search-users', [\App\Http\Controllers\Api\Student\StarController::class, 'searchUsers']);
    Route::post('stars/gift', [\App\Http\Controllers\Api\Student\StarController::class, 'gift']);

    // Tree Farm
    Route::prefix('tree-farm')->group(function () {
        Route::get('/', [\App\Http\Controllers\Api\Student\TreeFarmController::class, 'index']);
        Route::get('leaderboard', [\App\Http\Controllers\Api\Student\TreeFarmController::class, 'leaderboard']);
        Route::get('public-farm', [\App\Http\Controllers\Api\Student\TreeFarmController::class, 'publicFarm']);
        Route::patch('profile', [\App\Http\Controllers\Api\Student\TreeFarmController::class, 'updateProfile']);
        Route::post('sessions', [\App\Http\Controllers\Api\Student\TreeFarmController::class, 'logSession']);
        Route::post('sessions/start', [\App\Http\Controllers\Api\Student\TreeFarmController::class, 'start']);
        Route::post('sessions/{session}/heartbeat', [\App\Http\Controllers\Api\Student\TreeFarmController::class, 'heartbeat']);
        Route::post('sessions/{session}/grace', [\App\Http\Controllers\Api\Student\TreeFarmController::class, 'grace']);
        Route::post('sessions/{session}/finish', [\App\Http\Controllers\Api\Student\TreeFarmController::class, 'finish']);
        Route::post('offline-sync', [\App\Http\Controllers\Api\Student\TreeFarmController::class, 'offlineSync']);
        Route::post('log', [\App\Http\Controllers\Api\Student\TreeFarmController::class, 'logSession']);
        Route::post('thoughts', [\App\Http\Controllers\Api\Student\TreeFarmController::class, 'storeThought']);
        Route::post('reward-requests', [\App\Http\Controllers\Api\Student\TreeFarmController::class, 'rewardRequest']);
    });

    // ─── QR Attendance (Student Scan) ───
    Route::post('qr-attendance/scan', [\App\Http\Controllers\Api\QrAttendanceController::class, 'scan'])
        ->middleware('device.primary');

    // ─── Authorized Delegations (Monitoring) ───
    Route::get('authorized-grades', [\App\Http\Controllers\Api\Student\AuthorizedGradeController::class, 'index']);
    Route::get('authorized-grades/{category}', [\App\Http\Controllers\Api\Student\AuthorizedGradeController::class, 'show']);
    Route::post('authorized-grades/{category}/store', [\App\Http\Controllers\Api\Student\AuthorizedGradeController::class, 'store']);
});

// ══════════════════════════════════════════════════════════════
// Doctor API Controllers
// ══════════════════════════════════════════════════════════════
use App\Http\Controllers\Api\Doctor\DoctorAnnouncementController as DoctorAnnouncementApiController;
use App\Http\Controllers\Api\Student\DoctorAnnouncementController as StudentDoctorAnnouncementApiController;
use App\Http\Controllers\Api\Doctor\AuthController as DoctorAuthController;
use App\Http\Controllers\Api\Doctor\AttendanceController as DoctorAttendanceController;
use App\Http\Controllers\Api\Doctor\DashboardController as DoctorDashboardController;
use App\Http\Controllers\Api\Doctor\ExcuseController as DoctorExcuseController;
use App\Http\Controllers\Api\Doctor\ReportController as DoctorReportController;
use App\Http\Controllers\Api\Doctor\AssignmentController as DoctorAssignmentController;
use App\Http\Controllers\Api\Doctor\InquiryController as DoctorInquiryController;
use App\Http\Controllers\Api\Doctor\GradeController as DoctorGradeController;
use App\Http\Controllers\Api\Doctor\GradeCategoryController as DoctorGradeCategoryController;
use App\Http\Controllers\Api\Doctor\GradeApprovalController as DoctorGradeApprovalController;
use App\Http\Controllers\Api\Doctor\MessageController as DoctorMessageController;
use App\Http\Controllers\Api\Doctor\NewsController as DoctorNewsController;
use App\Http\Controllers\Api\Doctor\NotificationController as DoctorNotificationController;
use App\Http\Controllers\Api\Doctor\SubscriptionController as DoctorSubscriptionController;
use App\Http\Controllers\Api\Doctor\FinancialController as DoctorFinancialController;
use App\Http\Controllers\Api\Doctor\LibraryController as DoctorLibraryController;
use App\Http\Controllers\Api\Doctor\QuizController as DoctorQuizController;
use App\Http\Controllers\Api\Doctor\SubjectOptionController as DoctorSubjectOptionController;
use App\Http\Controllers\Api\Doctor\StarController as DoctorStarApiController;
use App\Http\Controllers\Api\Doctor\Clinical\ClinicalController as DoctorClinicalController;
use App\Http\Controllers\Api\Doctor\Clinical\TrainingCenterController as DoctorTrainingCenterController;
use App\Http\Controllers\Api\Doctor\Clinical\DepartmentController as DoctorDepartmentController;
use App\Http\Controllers\Api\Doctor\Clinical\BodySystemController as DoctorBodySystemController;
use App\Http\Controllers\Api\Doctor\Clinical\CaseController as DoctorCaseController;
use App\Http\Controllers\Api\Doctor\Clinical\CaseAssignmentController as DoctorCaseAssignmentController;
use App\Http\Controllers\Api\Doctor\Clinical\LogbookController as DoctorLogbookController;
use App\Http\Controllers\Api\Doctor\Clinical\EvaluationController as DoctorEvaluationController;

// ══════════════════════════════════════════════════════════════
// Doctor API — Public (No Auth Required)
// ══════════════════════════════════════════════════════════════
Route::prefix('doctor')->group(function () {
    Route::post('login', [DoctorAuthController::class, 'login']);
});

// ══════════════════════════════════════════════════════════════
// Doctor API — Protected (Sanctum Auth + Doctor Role)
// ══════════════════════════════════════════════════════════════
Route::prefix('doctor')->middleware(['auth:sanctum', 'role:doctor', 'status'])->group(function () {

    // Auth
    Route::post('logout', [DoctorAuthController::class, 'logout']);
    Route::get('me', [DoctorAuthController::class, 'me']);
    Route::post('change-password', [DoctorAuthController::class, 'changePassword']);
    Route::patch('profile/email', [DoctorAuthController::class, 'updateEmail']);
    Route::post('devices/token', [\App\Http\Controllers\Api\DeviceTokenController::class, 'store']);
    Route::delete('devices/token', [\App\Http\Controllers\Api\DeviceTokenController::class, 'destroy']);
    Route::get('devices/status', [\App\Http\Controllers\Api\DeviceTokenController::class, 'status']);
    Route::post('devices/test-push', [\App\Http\Controllers\Api\DeviceTokenController::class, 'test']);

    // Dashboard
    Route::get('dashboard', [DoctorDashboardController::class, 'index']);
    Route::get('badges', [DoctorDashboardController::class, 'badges']);

    // Financial & Subscription
    Route::get('ledger', [DoctorFinancialController::class, 'ledger']);
    Route::get('ledger/export', [DoctorFinancialController::class, 'exportPdf']);
    Route::get('subscription', [DoctorSubscriptionController::class, 'index']);
    Route::post('subscription/redeem', [DoctorSubscriptionController::class, 'redeem']);
    Route::post('subscription/subscribe', [DoctorSubscriptionController::class, 'subscribe']);
    Route::post('subscription/auto-renew', [DoctorSubscriptionController::class, 'toggleAutoRenew']);

    Route::middleware('subscribed')->group(function () {
    Route::post('desktop/pairing-code', [\App\Http\Controllers\DesktopPairingCodeController::class, 'issueForDoctor']);
    Route::get('subjects/options', [DoctorSubjectOptionController::class, 'index']);

    // Attendance
    Route::get('attendances', [DoctorAttendanceController::class, 'index']);
    Route::post('attendances', [DoctorAttendanceController::class, 'store']);
    Route::get('attendances/{lecture}', [DoctorAttendanceController::class, 'show']);
    Route::get('attendance', [DoctorAttendanceController::class, 'index']);
    Route::get('attendance/{subject}/create', [DoctorAttendanceController::class, 'create']);
    Route::post('attendance/{subject}', [DoctorAttendanceController::class, 'storeForSubject']);
    Route::patch('attendance-records/{attendance}', [\App\Http\Controllers\Doctor\ApiAttendanceRecordController::class, 'update']);
    Route::get('attendance-edit-requests', [\App\Http\Controllers\Api\AttendanceEditRequestController::class, 'index']);
    Route::post('attendance-edit-requests', [\App\Http\Controllers\Api\AttendanceEditRequestController::class, 'store']);
    Route::post('attendance/{subject}/toggle-delegate', [DoctorAttendanceController::class, 'toggleDelegate']);
    Route::get('attendance/{subject}/{date}/report', [DoctorAttendanceController::class, 'report']);
    Route::get('attendance/{subject}/{date}/report-pdf', [DoctorAttendanceController::class, 'reportPdf']);

    // Excuses
    Route::get('excuses', [DoctorExcuseController::class, 'index']);
    Route::put('excuses/{excuse}', [DoctorExcuseController::class, 'update']);

    // Reports
    Route::get('reports', [\App\Http\Controllers\Doctor\ApiReportController::class, 'index']);
    Route::get('reports/{subject}/pdf', [\App\Http\Controllers\Doctor\ApiReportController::class, 'pdf']);
    Route::get('reports/{subject}', [\App\Http\Controllers\Doctor\ApiReportController::class, 'show']);

    // Assignments
    Route::get('assignments', [DoctorAssignmentController::class, 'index']);
    Route::post('assignments', [DoctorAssignmentController::class, 'store']);
    Route::get('assignments/delegate-permissions', [DoctorAssignmentController::class, 'delegatePermissions']);
    Route::put('assignments/delegate-permissions', [DoctorAssignmentController::class, 'updateDelegatePermissions']);
    Route::get('assignments/{assignment}', [DoctorAssignmentController::class, 'show']);
    Route::put('assignments/{assignment}', [DoctorAssignmentController::class, 'update']);
    Route::delete('assignments/{assignment}', [DoctorAssignmentController::class, 'destroy']);
    Route::get('assignments/{assignment}/submissions', [DoctorAssignmentController::class, 'submissions']);
    Route::get('assignments/{assignment}/submissions/export', [DoctorAssignmentController::class, 'exportSubmissions']);
    Route::post('submissions/{submission}/review', [DoctorAssignmentController::class, 'reviewSubmission']);

    // Inquiries
    Route::get('inquiries', [DoctorInquiryController::class, 'index']);
    Route::get('inquiries/settings', [DoctorInquiryController::class, 'settings']);
    Route::patch('inquiries/subjects/{subject}/settings', [DoctorInquiryController::class, 'updateSettings']);
    Route::get('inquiries/{id}', [DoctorInquiryController::class, 'show']);
    Route::post('inquiries/{id}/answer', [DoctorInquiryController::class, 'answer']);

    // Grades
    Route::get('grades', [DoctorGradeController::class, 'index']);
    Route::get('grades/{subject}', [DoctorGradeController::class, 'show']);
    Route::put('grades/{subject}/settings', [DoctorGradeController::class, 'updateSettings']);
    Route::post('grades/{subject}', [DoctorGradeController::class, 'store']);
    Route::get('grades/{subject}/report', [DoctorGradeController::class, 'report']);
    Route::get('grades/{subject}/report/pdf', [DoctorGradeController::class, 'reportPdf']);
    Route::post('grades/{subject}/note/{student}', [DoctorGradeController::class, 'storeNote']);
    Route::get('grades/{subject}/categories', [DoctorGradeCategoryController::class, 'index']);
    Route::post('grades/{subject}/categories', [DoctorGradeCategoryController::class, 'store']);
    Route::put('grades/categories/{category}', [DoctorGradeCategoryController::class, 'update']);
    Route::delete('grades/categories/{category}', [DoctorGradeCategoryController::class, 'destroy']);
    Route::get('grades/{subject}/delegations', [DoctorGradeCategoryController::class, 'delegations']);
    Route::post('grades/categories/{category}/delegate', [DoctorGradeCategoryController::class, 'delegate']);
    Route::post('grades/categories/{category}/revoke', [DoctorGradeCategoryController::class, 'revoke']);
    Route::get('grades/{subject}/approvals', [DoctorGradeApprovalController::class, 'index']);
    Route::post('grades/approvals/bulk-action', [DoctorGradeApprovalController::class, 'bulkAction']);

    // Messages
    Route::get('messages', [DoctorMessageController::class, 'index']);
    Route::get('messages/delegates', [DoctorMessageController::class, 'delegates']);
    Route::get('messages/{conversation}', [DoctorMessageController::class, 'show']);
    Route::get('messages/{conversation}/delegate-info', [DoctorMessageController::class, 'delegateInfo']);
    Route::post('messages', [DoctorMessageController::class, 'store']);
    Route::post('messages/start', [DoctorMessageController::class, 'store']);
    Route::post('messages/{conversation}/send', [DoctorMessageController::class, 'send']);

    // News Center
    Route::get('news', [DoctorNewsController::class, 'index']);
    Route::get('news/{batchId}', [DoctorNewsController::class, 'show']);
    Route::post('news/{batchId}/vote', [DoctorNewsController::class, 'vote']);

    // Notifications
    Route::get('notifications', [DoctorNotificationController::class, 'index']);
    Route::post('notifications/{id}/read', [DoctorNotificationController::class, 'markAsRead']);
    Route::post('notifications/mark-all-read', [DoctorNotificationController::class, 'markAllAsRead']);

    // Content & Interaction
    Route::get('announcements', [DoctorAnnouncementApiController::class, 'index']);
    Route::post('announcements', [DoctorAnnouncementApiController::class, 'store']);
    Route::get('announcements/{id}', [DoctorAnnouncementApiController::class, 'show']);
    Route::put('announcements/{id}', [DoctorAnnouncementApiController::class, 'update']);
    Route::delete('announcements/{id}', [DoctorAnnouncementApiController::class, 'destroy']);
    Route::get('quizzes', [DoctorQuizController::class, 'index']);
    Route::post('quizzes', [DoctorQuizController::class, 'store']);
    Route::get('quizzes/{quiz}', [DoctorQuizController::class, 'show']);
    Route::put('quizzes/{quiz}', [DoctorQuizController::class, 'update']);
    Route::delete('quizzes/{quiz}', [DoctorQuizController::class, 'destroy']);
    Route::get('quizzes/{quiz}/results/export', [DoctorQuizController::class, 'exportResults']);
    Route::get('quizzes/{quiz}/results', [DoctorQuizController::class, 'results']);
    Route::patch('quizzes/{quiz}/publish', [DoctorQuizController::class, 'publish']);
    Route::patch('quizzes/{quiz}/close', [DoctorQuizController::class, 'close']);
    Route::post('quizzes/{quiz}/share-results', [DoctorQuizController::class, 'shareResults']);
    Route::get('stars', [DoctorStarApiController::class, 'index']);
    Route::post('stars/grant', [DoctorStarApiController::class, 'grant']);
    Route::get('library', [DoctorLibraryController::class, 'index']);
    Route::post('library/upload', [DoctorLibraryController::class, 'store']);
    Route::get('library/{resource}/download', [DoctorLibraryController::class, 'incrementDownload']);
    Route::prefix('qr-attendance')->group(function () {
        Route::post('start', [QrAttendanceController::class, 'startSession']);
        Route::get('active', [QrAttendanceController::class, 'active']);
        Route::get('{session}/token', [QrAttendanceController::class, 'rotateToken']);
        Route::get('{session}/status', [QrAttendanceController::class, 'getStatus']);
        Route::post('{session}/finalize', [QrAttendanceController::class, 'finalize']);
        Route::post('{session}/cancel', [QrAttendanceController::class, 'cancel']);
    });

    // Clinical Section
    Route::prefix('clinical')->middleware('clinical.major')->group(function () {

        // Overview
        Route::get('overview', [DoctorClinicalController::class, 'index']);

        // Training Centers
        Route::get('training-centers', [DoctorTrainingCenterController::class, 'index']);
        Route::post('training-centers', [DoctorTrainingCenterController::class, 'store']);
        Route::put('training-centers/{id}', [DoctorTrainingCenterController::class, 'update']);
        Route::delete('training-centers/{id}', [DoctorTrainingCenterController::class, 'destroy']);

        // Departments
        Route::post('departments/restore', [DoctorDepartmentController::class, 'restoreDefaults']);
        Route::get('departments', [DoctorDepartmentController::class, 'index']);
        Route::post('departments', [DoctorDepartmentController::class, 'store']);
        Route::put('departments/{id}', [DoctorDepartmentController::class, 'update']);
        Route::delete('departments/{id}', [DoctorDepartmentController::class, 'destroy']);

        // Body Systems
        Route::post('body-systems/restore', [DoctorBodySystemController::class, 'restoreDefaults']);
        Route::get('body-systems', [DoctorBodySystemController::class, 'index']);
        Route::post('body-systems', [DoctorBodySystemController::class, 'store']);
        Route::put('body-systems/{id}', [DoctorBodySystemController::class, 'update']);
        Route::delete('body-systems/{id}', [DoctorBodySystemController::class, 'destroy']);

        // Cases
        Route::get('cases', [DoctorCaseController::class, 'index']);
        Route::post('cases', [DoctorCaseController::class, 'store']);
        Route::get('cases/{id}', [DoctorCaseController::class, 'show']);
        Route::put('cases/{id}', [DoctorCaseController::class, 'update']);
        Route::delete('cases/{id}', [DoctorCaseController::class, 'destroy']);

        // Case Assignments
        Route::get('assignments', [DoctorCaseAssignmentController::class, 'index']);
        Route::post('assignments', [DoctorCaseAssignmentController::class, 'store']);
        Route::post('assignments/{assignment}/review', [DoctorCaseAssignmentController::class, 'review']);

        // Logbook / QR
        Route::post('logbook/scan', [DoctorLogbookController::class, 'processQr']);
        Route::post('logbook/confirm', [DoctorLogbookController::class, 'confirm']);
        Route::get('logbook/students', [DoctorLogbookController::class, 'portfolioStudents']);
        Route::get('logbook/students/{student}', [DoctorLogbookController::class, 'portfolioShow']);
        Route::get('logbook/students/{student}/pdf', [DoctorLogbookController::class, 'portfolioPdf']);
        Route::get('logbook/students/{student}/csv', [DoctorLogbookController::class, 'portfolioCsv']);
        Route::get('logbook/records', [DoctorLogbookController::class, 'records']);
        Route::post('logbook/manual', [DoctorLogbookController::class, 'manualAttendance']);

        // Evaluations
        Route::post('evaluations/checklists/restore', [DoctorEvaluationController::class, 'restoreDefaults']);
        Route::get('evaluations/checklists/hidden', [DoctorEvaluationController::class, 'hiddenChecklists']);
        Route::get('evaluations/checklists', [DoctorEvaluationController::class, 'checklists']);
        Route::get('evaluations/checklists/{id}', [DoctorEvaluationController::class, 'showChecklist']);
        Route::post('evaluations/checklists', [DoctorEvaluationController::class, 'storeChecklist']);
        Route::post('evaluations/checklists/{id}/restore', [DoctorEvaluationController::class, 'restoreChecklist']);
        Route::post('evaluations/checklists/{id}/sync-admin-update', [DoctorEvaluationController::class, 'syncAdminChecklistUpdate']);
        Route::put('evaluations/checklists/{id}', [DoctorEvaluationController::class, 'updateChecklist']);
        Route::delete('evaluations/checklists/{id}', [DoctorEvaluationController::class, 'destroyChecklist']);
        Route::get('evaluations/students', [DoctorEvaluationController::class, 'students']);
        Route::get('evaluations/checklists/{id}/take', [DoctorEvaluationController::class, 'takeChecklist']);
        Route::get('evaluations/start-data', [DoctorEvaluationController::class, 'startData']);
        Route::post('evaluations/submit', [DoctorEvaluationController::class, 'submit']);
        Route::get('evaluations/portfolios', [DoctorEvaluationController::class, 'portfolioStudents']);
        Route::get('evaluations/portfolios/{student}', [DoctorEvaluationController::class, 'portfolioShow']);
        Route::get('evaluations/portfolios/{student}/excel', [DoctorEvaluationController::class, 'portfolioExcel']);
        Route::get('evaluations/results', [DoctorEvaluationController::class, 'results']);
        Route::get('evaluations/results/{id}', [DoctorEvaluationController::class, 'showResult']);

        // Rare Clinical Cases
        Route::get('rare-cases', [DoctorRareCaseController::class, 'index']);
        Route::post('rare-cases', [DoctorRareCaseController::class, 'store']);
        Route::put('rare-cases/{id}', [DoctorRareCaseController::class, 'update']);
        Route::patch('rare-cases/{id}/toggle', [DoctorRareCaseController::class, 'toggleStatus']);
        Route::delete('rare-cases/{id}', [DoctorRareCaseController::class, 'destroy']);

        // Volunteers Registry
        Route::get('volunteers', [DoctorVolunteerController::class, 'index']);
        Route::post('volunteers', [DoctorVolunteerController::class, 'store']);
        Route::put('volunteers/{id}', [DoctorVolunteerController::class, 'update']);
        Route::post('volunteers/{id}/follow-up', [DoctorVolunteerController::class, 'followUp']);
        Route::patch('volunteers/{id}/toggle', [DoctorVolunteerController::class, 'toggleStatus']);
        Route::delete('volunteers/{id}', [DoctorVolunteerController::class, 'destroy']);

        // Doctor Announcements (إعلاناتي)
        Route::get('announcements', [DoctorAnnouncementApiController::class, 'index']);
        Route::post('announcements', [DoctorAnnouncementApiController::class, 'store']);
        Route::get('announcements/{id}', [DoctorAnnouncementApiController::class, 'show']);
        Route::put('announcements/{id}', [DoctorAnnouncementApiController::class, 'update']);
        Route::delete('announcements/{id}', [DoctorAnnouncementApiController::class, 'destroy']);
    });
    });
});
