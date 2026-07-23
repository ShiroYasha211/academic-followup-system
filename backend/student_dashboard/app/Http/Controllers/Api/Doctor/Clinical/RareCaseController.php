<?php

namespace App\Http\Controllers\Api\Doctor\Clinical;

use App\Http\Controllers\Api\Doctor\DoctorApiController;
use App\Models\Clinical\RareCase;
use App\Models\StudentNotification;
use App\Models\User;
use App\Enums\UserRole;
use App\Services\PushNotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class RareCaseController extends DoctorApiController
{
    public function index(Request $request)
    {
        $perPage = min(max((int) $request->integer('per_page', 100), 1), 200);
        $status = $request->query('status');

        $cases = RareCase::where('doctor_id', Auth::id())
            ->when(in_array($status, $this->statuses(), true), fn ($query) => $query->where('status', $status))
            ->latest()
            ->paginate($perPage);

        $cases->getCollection()->transform(
            fn (RareCase $case) => $this->serializeCase($case)
        );

        return $this->success($cases, 'تم جلب الحالات النادرة بنجاح');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'hospital' => 'required|string|max:255',
            'department' => 'required|string|max:255',
            'diagnosis' => 'required|string|max:255',
            'patient_name' => 'nullable|string|max:255',
            'room_number' => 'nullable|string|max:50',
            'clinical_signs' => 'nullable|string',
            'attachment' => 'nullable|image|max:5120',
            'status' => 'nullable|in:' . implode(',', $this->statuses()),
            'expires_at' => 'nullable|date',
            'internal_notes' => 'nullable|string',
        ]);

        $data = $validated;
        unset($data['attachment']);
        $data['doctor_id'] = Auth::id();
        $data['status'] = $data['status'] ?? 'published';
        $data['is_active'] = $data['status'] === 'published';

        if ($request->hasFile('attachment')) {
            $data['attachment_path'] = $request->file('attachment')->store('clinical/rare_cases', 'public');
        }

        $rareCase = RareCase::create($data);

        $recipientsCount = $rareCase->status === 'published'
            ? $this->notifyCollegeStudents($rareCase)
            : 0;

        return $this->success([
            'case' => $this->serializeCase($rareCase),
            'recipients_count' => $recipientsCount,
        ], 'تم نشر الحالة وإرسال الإشعار للطلاب بنجاح.', 201);
    }

    public function update(Request $request, $id)
    {
        $case = RareCase::where('doctor_id', Auth::id())->findOrFail($id);

        $validated = $request->validate([
            'hospital' => 'required|string|max:255',
            'department' => 'required|string|max:255',
            'diagnosis' => 'required|string|max:255',
            'patient_name' => 'nullable|string|max:255',
            'room_number' => 'nullable|string|max:50',
            'clinical_signs' => 'nullable|string',
            'attachment' => 'nullable|image|max:5120',
            'status' => 'nullable|in:' . implode(',', $this->statuses()),
            'expires_at' => 'nullable|date',
            'internal_notes' => 'nullable|string',
        ]);

        $data = $validated;
        unset($data['attachment']);

        if ($request->hasFile('attachment')) {
            if ($case->attachment_path) {
                Storage::disk('public')->delete($case->attachment_path);
            }

            $data['attachment_path'] = $request->file('attachment')->store('clinical/rare_cases', 'public');
        }

        if (array_key_exists('status', $data)) {
            $data['is_active'] = $data['status'] === 'published';
        }

        $case->update($data);

        return $this->success([
            'case' => $this->serializeCase($case->fresh()),
        ], 'تم تعديل إعلان الحالة النادرة بنجاح.');
    }

    public function toggleStatus($id)
    {
        $case = RareCase::where('doctor_id', Auth::id())->findOrFail($id);
        $isActive = !$case->is_active;
        $case->update([
            'is_active' => $isActive,
            'status' => $isActive ? 'published' : 'closed',
        ]);

        return $this->success([
            'id' => $case->id,
            'is_active' => (bool) $case->is_active,
            'status' => $case->status,
            'status_label' => $this->statusLabel($case->status),
        ], 'تم تحديث حالة الإعلان.');
    }

    public function destroy($id)
    {
        $case = RareCase::where('doctor_id', Auth::id())->findOrFail($id);

        if ($case->attachment_path) {
            Storage::disk('public')->delete($case->attachment_path);
        }

        $case->delete();

        return $this->success(null, 'تم حذف إعلان الحالة النادرة.');
    }

    protected function serializeCase(RareCase $case): array
    {
        return [
            'id' => $case->id,
            'doctor_id' => $case->doctor_id,
            'patient_name' => $case->patient_name,
            'hospital' => $case->hospital,
            'department' => $case->department,
            'room_number' => $case->room_number,
            'diagnosis' => $case->diagnosis,
            'clinical_signs' => $case->clinical_signs,
            'attachment_path' => $case->attachment_path,
            'attachment_url' => $case->attachment_path ? asset('storage/' . $case->attachment_path) : null,
            'is_active' => (bool) $case->is_active,
            'status' => $case->status ?? ($case->is_active ? 'published' : 'closed'),
            'status_label' => $this->statusLabel($case->status ?? ($case->is_active ? 'published' : 'closed')),
            'expires_at' => optional($case->expires_at)->toISOString(),
            'expires_at_label' => optional($case->expires_at)->format('Y-m-d H:i'),
            'internal_notes' => $case->internal_notes,
            'views_count' => (int) ($case->views_count ?? 0),
            'created_at' => optional($case->created_at)->toISOString(),
            'updated_at' => optional($case->updated_at)->toISOString(),
            'created_at_label' => optional($case->created_at)->format('Y-m-d H:i'),
            'updated_at_label' => optional($case->updated_at)->format('Y-m-d H:i'),
        ];
    }

    protected function notifyCollegeStudents(RareCase $rareCase): int
    {
        $doctor = Auth::user();
        $collegeId = $doctor->college_id;

        if (! $collegeId) {
            return 0;
        }

        $students = User::query()
            ->where('college_id', $collegeId)
            ->where('status', 'active')
            ->whereIn('role', [
                UserRole::STUDENT->value,
                UserRole::DELEGATE->value,
                UserRole::PRACTICAL_DELEGATE->value,
            ])
            ->get(['id']);

        if ($students->isEmpty()) {
            return 0;
        }

        $batchId = 'rare-case-' . $rareCase->id . '-' . Str::uuid();
        $now = now();
        $title = 'إعلان حالة نادرة';
        $message = 'تم نشر حالة نادرة جديدة: ' . $rareCase->diagnosis;

        $rows = $students->map(fn (User $student) => [
            'user_id' => $student->id,
            'college_id' => $collegeId,
            'sender_id' => $doctor->id,
            'batch_id' => $batchId,
            'type' => 'rare_case',
            'title' => $title,
            'message' => $message,
            'attachment_path' => $rareCase->attachment_path,
            'attachment_name' => $rareCase->attachment_path ? basename($rareCase->attachment_path) : null,
            'data' => json_encode([
                'rare_case_id' => $rareCase->id,
                'doctor_id' => $doctor->id,
                'screen' => 'rare_case',
                'target_screen' => 'rare_case',
            ], JSON_UNESCAPED_UNICODE),
            'created_at' => $now,
            'updated_at' => $now,
        ])->all();

        foreach (array_chunk($rows, 500) as $chunk) {
            StudentNotification::insert($chunk);
        }

        try {
            app(PushNotificationService::class)->sendBatchByBatchId($batchId);
        } catch (\Throwable $exception) {
            Log::warning('Rare case push notification failed.', [
                'rare_case_id' => $rareCase->id,
                'batch_id' => $batchId,
                'error' => $exception->getMessage(),
            ]);
        }

        return $students->count();
    }

    protected function statuses(): array
    {
        return ['draft', 'published', 'closed', 'archived'];
    }

    protected function statusLabel(?string $status): string
    {
        return match ($status) {
            'draft' => 'مسودة',
            'closed' => 'مغلقة',
            'archived' => 'مؤرشفة',
            default => 'منشورة',
        };
    }
}
