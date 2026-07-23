<?php

namespace App\Http\Controllers\Admin;

use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Models\Academic\Lecture;
use App\Models\Academic\Subject;
use App\Models\AttendanceEditPermission;
use App\Models\AttendanceEditRequest;
use App\Models\QrAttendanceSession;
use App\Models\StudentNotification;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class AttendanceEditRequestController extends Controller
{
    public function index(Request $request)
    {
        $this->ensurePrimaryAdmin($request);

        $status = $request->input('status', AttendanceEditRequest::STATUS_PENDING);

        $query = AttendanceEditRequest::with([
            'requester:id,name,email,role,major_id,level_id',
            'requester.major:id,name',
            'requester.level:id,name',
            'subject:id,name,code',
            'lecture:id,title,lecture_number,date',
            'qrSession:id,title,lecture_number,date',
            'reviewedBy:id,name',
            'permission',
        ])->latest();

        if ($status !== 'all') {
            $query->where('status', $status);
        }

        $requests = $query->paginate(15)->withQueryString();

        $activePermissions = AttendanceEditPermission::active()
            ->with([
                'user:id,name,email,role',
                'grantedBy:id,name',
                'subject:id,name,code',
                'lecture:id,title,lecture_number,date',
                'qrSession:id,title,lecture_number,date',
                'request:id,reason',
            ])
            ->latest('expires_at')
            ->paginate(10, ['*'], 'permissions_page');

        $pendingCount = AttendanceEditRequest::pending()->count();
        $activePermissionsCount = AttendanceEditPermission::active()->count();
        $expiringPermissionsCount = AttendanceEditPermission::active()
            ->where('expires_at', '<=', now()->addHours(2))
            ->count();

        return view('admin.attendance-edit-requests.index', compact(
            'requests',
            'activePermissions',
            'pendingCount',
            'activePermissionsCount',
            'expiringPermissionsCount',
            'status'
        ));
    }

    public function lookupUsers(Request $request)
    {
        $this->ensurePrimaryAdmin($request);

        $term = trim((string) $request->input('q', ''));

        $users = User::whereIn('role', [
            UserRole::DOCTOR->value,
            UserRole::DELEGATE->value,
            UserRole::PRACTICAL_DELEGATE->value,
        ])
            ->when($term !== '', function ($query) use ($term) {
                $query->where(function ($scope) use ($term) {
                    $scope
                        ->where('name', 'like', "%{$term}%")
                        ->orWhere('email', 'like', "%{$term}%")
                        ->orWhere('role', 'like', "%{$term}%");
                });
            })
            ->orderBy('name')
            ->limit(25)
            ->get(['id', 'name', 'email', 'role']);

        return response()->json([
            'results' => $users->map(fn (User $user) => [
                'id' => $user->id,
                'label' => $user->name,
                'meta' => trim(($user->email ?? '-') . ' - ' . ($user->role instanceof UserRole ? $user->role->value : (string) $user->role)),
            ])->values(),
        ]);
    }

    public function lookupSubjects(Request $request)
    {
        $this->ensurePrimaryAdmin($request);

        $term = trim((string) $request->input('q', ''));

        $subjects = Subject::query()
            ->when($term !== '', function ($query) use ($term) {
                $query->where(function ($scope) use ($term) {
                    $scope
                        ->where('name', 'like', "%{$term}%")
                        ->orWhere('code', 'like', "%{$term}%");
                });
            })
            ->orderBy('name')
            ->limit(25)
            ->get(['id', 'name', 'code']);

        return response()->json([
            'results' => $subjects->map(fn (Subject $subject) => [
                'id' => $subject->id,
                'label' => $subject->name,
                'meta' => $subject->code ?: null,
            ])->values(),
        ]);
    }

    public function lookupLectures(Request $request)
    {
        $this->ensurePrimaryAdmin($request);

        $term = trim((string) $request->input('q', ''));

        $lectures = Lecture::with('subject:id,name,code')
            ->when($request->filled('subject_id'), fn ($query) => $query->where('subject_id', $request->integer('subject_id')))
            ->when($request->filled('date'), fn ($query) => $query->whereDate('date', $request->input('date')))
            ->when($term !== '', function ($query) use ($term) {
                $query->where(function ($scope) use ($term) {
                    $scope
                        ->where('title', 'like', "%{$term}%")
                        ->orWhere('lecture_number', 'like', "%{$term}%")
                        ->orWhere('date', 'like', "%{$term}%")
                        ->orWhereHas('subject', function ($subjectQuery) use ($term) {
                            $subjectQuery
                                ->where('name', 'like', "%{$term}%")
                                ->orWhere('code', 'like', "%{$term}%");
                        });
                });
            })
            ->latest('date')
            ->latest('id')
            ->limit(30)
            ->get(['id', 'subject_id', 'title', 'lecture_number', 'date']);

        return response()->json([
            'results' => $lectures->map(fn (Lecture $lecture) => [
                'id' => $lecture->id,
                'label' => $lecture->title ?: 'محاضرة بدون عنوان',
                'meta' => collect([
                    $lecture->date?->format('Y-m-d'),
                    $lecture->subject?->name,
                    $lecture->lecture_number ? "رقم {$lecture->lecture_number}" : null,
                ])->filter()->implode(' - '),
                'subject_id' => $lecture->subject_id,
                'date' => $lecture->date?->format('Y-m-d'),
            ])->values(),
        ]);
    }

    public function lookupQrSessions(Request $request)
    {
        $this->ensurePrimaryAdmin($request);

        $term = trim((string) $request->input('q', ''));

        $sessions = QrAttendanceSession::with(['subject:id,name,code', 'delegate:id,name'])
            ->when($request->filled('subject_id'), fn ($query) => $query->where('subject_id', $request->integer('subject_id')))
            ->when($request->filled('date'), fn ($query) => $query->whereDate('date', $request->input('date')))
            ->when($term !== '', function ($query) use ($term) {
                $query->where(function ($scope) use ($term) {
                    $scope
                        ->where('title', 'like', "%{$term}%")
                        ->orWhere('lecture_number', 'like', "%{$term}%")
                        ->orWhere('date', 'like', "%{$term}%")
                        ->orWhereHas('subject', function ($subjectQuery) use ($term) {
                            $subjectQuery
                                ->where('name', 'like', "%{$term}%")
                                ->orWhere('code', 'like', "%{$term}%");
                        })
                        ->orWhereHas('delegate', fn ($delegateQuery) => $delegateQuery->where('name', 'like', "%{$term}%"));
                });
            })
            ->latest('date')
            ->latest('id')
            ->limit(30)
            ->get(['id', 'subject_id', 'delegate_id', 'title', 'lecture_number', 'date']);

        return response()->json([
            'results' => $sessions->map(fn (QrAttendanceSession $session) => [
                'id' => $session->id,
                'label' => $session->title ?: 'جلسة QR بدون عنوان',
                'meta' => collect([
                    $session->date?->format('Y-m-d'),
                    $session->subject?->name,
                    $session->delegate?->name ? "بواسطة {$session->delegate->name}" : null,
                ])->filter()->implode(' - '),
                'subject_id' => $session->subject_id,
                'date' => $session->date?->format('Y-m-d'),
            ])->values(),
        ]);
    }

    public function approve(Request $request, AttendanceEditRequest $editRequest)
    {
        $this->ensurePrimaryAdmin($request);

        if ($editRequest->status !== AttendanceEditRequest::STATUS_PENDING) {
            return back()->with('error', 'هذا الطلب ليس معلقًا.');
        }

        $validated = $request->validate([
            'expires_hours' => 'required|integer|min:1|max:168',
            'admin_note' => 'nullable|string|max:2000',
        ]);

        DB::transaction(function () use ($editRequest, $validated) {
            $expiresAt = now()->addHours((int) $validated['expires_hours']);

            $editRequest->update([
                'status' => AttendanceEditRequest::STATUS_APPROVED,
                'reviewed_by' => auth()->id(),
                'reviewed_at' => now(),
                'admin_note' => $validated['admin_note'] ?? null,
                'granted_until' => $expiresAt,
            ]);

            $permission = AttendanceEditPermission::create([
                'user_id' => $editRequest->requester_id,
                'granted_by' => auth()->id(),
                'attendance_edit_request_id' => $editRequest->id,
                'subject_id' => $editRequest->subject_id,
                'lecture_id' => $editRequest->lecture_id,
                'qr_attendance_session_id' => $editRequest->qr_attendance_session_id,
                'date' => $editRequest->date,
                'reason' => $editRequest->reason,
                'expires_at' => $expiresAt,
            ]);

            $this->notifyRequester($editRequest, 'تم قبول طلب تعديل الحضور', "تم فتح تعديل الحضور لك حتى {$permission->expires_at->format('Y-m-d H:i')}.");
        });

        return back()->with('success', 'تم قبول الطلب وفتح صلاحية التعديل.');
    }

    public function reject(Request $request, AttendanceEditRequest $editRequest)
    {
        $this->ensurePrimaryAdmin($request);

        if ($editRequest->status !== AttendanceEditRequest::STATUS_PENDING) {
            return back()->with('error', 'هذا الطلب ليس معلقًا.');
        }

        $validated = $request->validate([
            'admin_note' => 'nullable|string|max:2000',
        ]);

        $editRequest->update([
            'status' => AttendanceEditRequest::STATUS_REJECTED,
            'reviewed_by' => auth()->id(),
            'reviewed_at' => now(),
            'admin_note' => $validated['admin_note'] ?? null,
        ]);

        $message = 'تم رفض طلب فتح تعديل الحضور.';
        if (!empty($validated['admin_note'])) {
            $message .= "\nملاحظة الأدمن: {$validated['admin_note']}";
        }

        $this->notifyRequester($editRequest, 'تم رفض طلب تعديل الحضور', $message);

        return back()->with('success', 'تم رفض الطلب.');
    }

    public function grant(Request $request)
    {
        $this->ensurePrimaryAdmin($request);

        $validated = $request->validate([
            'user_id' => [
                'required',
                'integer',
                Rule::exists('users', 'id')->where(fn ($query) => $query->whereIn('role', [
                    UserRole::DOCTOR->value,
                    UserRole::DELEGATE->value,
                    UserRole::PRACTICAL_DELEGATE->value,
                ])),
            ],
            'lecture_id' => 'nullable|integer|exists:lectures,id',
            'subject_id' => 'nullable|integer|exists:subjects,id',
            'date' => 'nullable|date|required_without:lecture_id',
            'reason' => 'nullable|string|max:2000',
            'expires_hours' => 'required|integer|min:1|max:168',
        ]);

        $lecture = !empty($validated['lecture_id'])
            ? Lecture::find($validated['lecture_id'])
            : null;

        $permission = AttendanceEditPermission::create([
            'user_id' => $validated['user_id'],
            'granted_by' => auth()->id(),
            'subject_id' => $lecture?->subject_id ?? ($validated['subject_id'] ?? null),
            'lecture_id' => $lecture?->id,
            'date' => $lecture?->date ?? ($validated['date'] ?? null),
            'reason' => $validated['reason'] ?? 'فتح يدوي من الأدمن الرئيسي',
            'expires_at' => now()->addHours((int) $validated['expires_hours']),
        ]);

        StudentNotification::create([
            'user_id' => $permission->user_id,
            'type' => 'attendance_edit_request',
            'title' => 'تم فتح تعديل الحضور',
            'message' => "تم فتح صلاحية تعديل الحضور لك حتى {$permission->expires_at->format('Y-m-d H:i')}.",
            'data' => [
                'permission_id' => $permission->id,
                'subject_id' => $permission->subject_id,
                'lecture_id' => $permission->lecture_id,
                'date' => $permission->date?->format('Y-m-d'),
            ],
        ]);

        return back()->with('success', 'تم فتح صلاحية التعديل يدويًا.');
    }

    public function grantManual(Request $request)
    {
        $this->ensurePrimaryAdmin($request);

        $validated = $request->validate([
            'user_id' => [
                'required',
                'integer',
                Rule::exists('users', 'id')->where(fn ($query) => $query->whereIn('role', [
                    UserRole::DOCTOR->value,
                    UserRole::DELEGATE->value,
                    UserRole::PRACTICAL_DELEGATE->value,
                ])),
            ],
            'scope_type' => 'required|in:lecture,subject_date,qr',
            'lecture_id' => 'nullable|integer|exists:lectures,id',
            'qr_attendance_session_id' => 'nullable|integer|exists:qr_attendance_sessions,id',
            'subject_id' => 'nullable|integer|exists:subjects,id',
            'date' => 'nullable|date',
            'reason' => 'nullable|string|max:2000',
            'expires_hours' => 'required|integer|min:1|max:168',
        ]);

        $lecture = $validated['scope_type'] === 'lecture' && !empty($validated['lecture_id'])
            ? Lecture::find($validated['lecture_id'])
            : null;
        $qrSession = $validated['scope_type'] === 'qr' && !empty($validated['qr_attendance_session_id'])
            ? QrAttendanceSession::find($validated['qr_attendance_session_id'])
            : null;

        if ($validated['scope_type'] === 'lecture' && !$lecture) {
            return back()->withInput()->with('error', 'يرجى اختيار محاضرة صحيحة لفتح التعديل.');
        }

        if ($validated['scope_type'] === 'qr' && !$qrSession) {
            return back()->withInput()->with('error', 'يرجى اختيار جلسة QR صحيحة لفتح التعديل.');
        }

        if ($validated['scope_type'] === 'subject_date' && (empty($validated['subject_id']) || empty($validated['date']))) {
            return back()->withInput()->with('error', 'يرجى اختيار المادة والتاريخ عند فتح التعديل بنطاق مادة وتاريخ.');
        }

        $permission = AttendanceEditPermission::create([
            'user_id' => $validated['user_id'],
            'granted_by' => auth()->id(),
            'subject_id' => $lecture?->subject_id ?? $qrSession?->subject_id ?? ($validated['subject_id'] ?? null),
            'lecture_id' => $lecture?->id,
            'qr_attendance_session_id' => $qrSession?->id,
            'date' => $lecture?->date ?? $qrSession?->date ?? ($validated['date'] ?? null),
            'reason' => $validated['reason'] ?? 'فتح يدوي من الأدمن الرئيسي',
            'expires_at' => now()->addHours((int) $validated['expires_hours']),
        ]);

        StudentNotification::create([
            'user_id' => $permission->user_id,
            'type' => 'attendance_edit_request',
            'title' => 'تم فتح تعديل الحضور',
            'message' => "تم فتح صلاحية تعديل الحضور لك حتى {$permission->expires_at->format('Y-m-d H:i')}.",
            'data' => [
                'permission_id' => $permission->id,
                'subject_id' => $permission->subject_id,
                'lecture_id' => $permission->lecture_id,
                'qr_attendance_session_id' => $permission->qr_attendance_session_id,
                'date' => $permission->date?->format('Y-m-d'),
            ],
        ]);

        return back()->with('success', 'تم فتح صلاحية التعديل يدويًا.');
    }

    public function revoke(Request $request, AttendanceEditPermission $permission)
    {
        $this->ensurePrimaryAdmin($request);

        if ($permission->revoked_at) {
            return back()->with('error', 'هذه الصلاحية مغلقة مسبقًا.');
        }

        $permission->update([
            'revoked_at' => now(),
            'revoked_by' => auth()->id(),
        ]);

        return back()->with('success', 'تم إغلاق صلاحية التعديل.');
    }

    protected function notifyRequester(AttendanceEditRequest $request, string $title, string $message): void
    {
        StudentNotification::create([
            'user_id' => $request->requester_id,
            'type' => 'attendance_edit_request',
            'title' => $title,
            'message' => $message,
            'data' => [
                'request_id' => $request->id,
                'status' => $request->status,
                'subject_id' => $request->subject_id,
                'lecture_id' => $request->lecture_id,
                'date' => $request->date?->format('Y-m-d'),
            ],
        ]);
    }

    protected function ensurePrimaryAdmin(Request $request): void
    {
        if ($request->user()?->role !== UserRole::ADMIN) {
            abort(403, 'هذه الصفحة متاحة للأدمن الرئيسي فقط.');
        }
    }
}
