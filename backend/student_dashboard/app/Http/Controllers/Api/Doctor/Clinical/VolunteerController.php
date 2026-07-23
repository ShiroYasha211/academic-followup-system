<?php

namespace App\Http\Controllers\Api\Doctor\Clinical;

use App\Http\Controllers\Api\Doctor\DoctorApiController;
use App\Models\Clinical\ClinicalVolunteer;
use App\Models\Clinical\ClinicalVolunteerLog;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class VolunteerController extends DoctorApiController
{
    public function index(Request $request)
    {
        $perPage = min(max((int) $request->integer('per_page', 100), 1), 200);
        $search = trim((string) $request->query('search', ''));
        $status = $request->query('status');

        $volunteers = ClinicalVolunteer::with(['logs' => fn ($query) => $query->latest()->limit(3)])
            ->where('doctor_id', Auth::id())
            ->when($search !== '', function ($query) use ($search) {
                $query->where(function ($query) use ($search) {
                    $query
                        ->where('name', 'like', "%{$search}%")
                        ->orWhere('contact_info', 'like', "%{$search}%")
                        ->orWhere('phone_secondary', 'like', "%{$search}%")
                        ->orWhere('email', 'like', "%{$search}%")
                        ->orWhere('diagnosis', 'like', "%{$search}%")
                        ->orWhere('clinical_signs', 'like', "%{$search}%");
                });
            })
            ->when(in_array($status, ['available', 'unavailable'], true), function ($query) use ($status) {
                $query->where('is_available', $status === 'available');
            })
            ->when(in_array($status, $this->followUpStatuses(), true), function ($query) use ($status) {
                $query->where('follow_up_status', $status);
            })
            ->latest()
            ->paginate($perPage);

        $volunteers->getCollection()->transform(
            fn (ClinicalVolunteer $volunteer) => $this->serializeVolunteer($volunteer)
        );

        return $this->success($volunteers, 'تم جلب سجل المتطوعين بنجاح');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'contact_info' => 'required|string|max:255',
            'phone_secondary' => 'nullable|string|max:255',
            'email' => 'nullable|email|max:255',
            'diagnosis' => 'required|string|max:255',
            'clinical_signs' => 'nullable|string',
            'follow_up_status' => 'nullable|in:' . implode(',', $this->followUpStatuses()),
            'preferred_contact_method' => 'nullable|in:' . implode(',', $this->contactMethods()),
            'last_contacted_at' => 'nullable|date',
            'internal_notes' => 'nullable|string',
        ]);

        $this->ensureVolunteerIsUnique($validated);

        $validated['doctor_id'] = Auth::id();
        $validated['is_available'] = true;

        $volunteer = ClinicalVolunteer::create($validated);

        return $this->success($this->serializeVolunteer($volunteer), 'تم إضافة المتطوع بنجاح.', 201);
    }

    public function update(Request $request, $id)
    {
        $volunteer = ClinicalVolunteer::where('doctor_id', Auth::id())->findOrFail($id);

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'contact_info' => 'required|string|max:255',
            'phone_secondary' => 'nullable|string|max:255',
            'email' => 'nullable|email|max:255',
            'diagnosis' => 'required|string|max:255',
            'clinical_signs' => 'nullable|string',
            'follow_up_status' => 'nullable|in:' . implode(',', $this->followUpStatuses()),
            'preferred_contact_method' => 'nullable|in:' . implode(',', $this->contactMethods()),
            'last_contacted_at' => 'nullable|date',
            'internal_notes' => 'nullable|string',
        ]);

        $this->ensureVolunteerIsUnique($validated, $volunteer->id);

        $volunteer->update($validated);

        return $this->success($this->serializeVolunteer($volunteer->fresh()), 'تم تحديث بيانات المتطوع بنجاح.');
    }

    public function followUp(Request $request, $id)
    {
        $volunteer = ClinicalVolunteer::where('doctor_id', Auth::id())->findOrFail($id);

        $validated = $request->validate([
            'follow_up_status' => 'required|in:' . implode(',', $this->followUpStatuses()),
            'contact_method' => 'nullable|in:' . implode(',', $this->contactMethods()),
            'contacted_at' => 'nullable|date',
            'notes' => 'nullable|string',
        ]);

        $contactedAt = $validated['contacted_at'] ?? now();

        ClinicalVolunteerLog::create([
            'clinical_volunteer_id' => $volunteer->id,
            'doctor_id' => Auth::id(),
            'follow_up_status' => $validated['follow_up_status'],
            'contact_method' => $validated['contact_method'] ?? null,
            'contacted_at' => $contactedAt,
            'notes' => $validated['notes'] ?? null,
        ]);

        $volunteer->update([
            'follow_up_status' => $validated['follow_up_status'],
            'preferred_contact_method' => $validated['contact_method'] ?? $volunteer->preferred_contact_method,
            'last_contacted_at' => $contactedAt,
            'internal_notes' => $validated['notes'] ?? $volunteer->internal_notes,
        ]);

        return $this->success(
            $this->serializeVolunteer($volunteer->fresh('logs')),
            'تم تسجيل المتابعة بنجاح.'
        );
    }

    public function toggleStatus($id)
    {
        $volunteer = ClinicalVolunteer::where('doctor_id', Auth::id())->findOrFail($id);
        $volunteer->update(['is_available' => !$volunteer->is_available]);

        return $this->success([
            'id' => $volunteer->id,
            'is_available' => (bool) $volunteer->is_available,
        ], 'تم تحديث حالة التوفر.');
    }

    public function destroy($id)
    {
        $volunteer = ClinicalVolunteer::where('doctor_id', Auth::id())->findOrFail($id);
        $volunteer->delete();

        return $this->success(null, 'تم حذف المتطوع من السجل.');
    }

    protected function serializeVolunteer(ClinicalVolunteer $volunteer): array
    {
        return [
            'id' => $volunteer->id,
            'doctor_id' => $volunteer->doctor_id,
            'name' => $volunteer->name,
            'contact_info' => $volunteer->contact_info,
            'phone_secondary' => $volunteer->phone_secondary,
            'email' => $volunteer->email,
            'diagnosis' => $volunteer->diagnosis,
            'clinical_signs' => $volunteer->clinical_signs,
            'is_available' => (bool) $volunteer->is_available,
            'follow_up_status' => $volunteer->follow_up_status ?? 'not_contacted',
            'follow_up_status_label' => $this->followUpStatusLabel($volunteer->follow_up_status ?? 'not_contacted'),
            'preferred_contact_method' => $volunteer->preferred_contact_method,
            'preferred_contact_method_label' => $this->contactMethodLabel($volunteer->preferred_contact_method),
            'last_contacted_at' => optional($volunteer->last_contacted_at)->toISOString(),
            'last_contacted_at_label' => optional($volunteer->last_contacted_at)->format('Y-m-d H:i'),
            'internal_notes' => $volunteer->internal_notes,
            'logs' => $volunteer->relationLoaded('logs')
                ? $volunteer->logs->take(3)->map(fn (ClinicalVolunteerLog $log) => [
                    'id' => $log->id,
                    'follow_up_status' => $log->follow_up_status,
                    'follow_up_status_label' => $this->followUpStatusLabel($log->follow_up_status),
                    'contact_method' => $log->contact_method,
                    'contact_method_label' => $this->contactMethodLabel($log->contact_method),
                    'contacted_at' => optional($log->contacted_at)->toISOString(),
                    'contacted_at_label' => optional($log->contacted_at)->format('Y-m-d H:i'),
                    'notes' => $log->notes,
                ])->values()
                : [],
            'created_at' => optional($volunteer->created_at)->toISOString(),
            'updated_at' => optional($volunteer->updated_at)->toISOString(),
        ];
    }

    protected function ensureVolunteerIsUnique(array $data, ?int $ignoreId = null): void
    {
        $doctorId = Auth::id();
        $phone = trim((string) ($data['contact_info'] ?? ''));
        $secondary = trim((string) ($data['phone_secondary'] ?? ''));
        $email = trim((string) ($data['email'] ?? ''));

        $duplicatePhone = ClinicalVolunteer::where('doctor_id', $doctorId)
            ->when($ignoreId, fn ($query) => $query->where('id', '!=', $ignoreId))
            ->where(function ($query) use ($phone, $secondary) {
                if ($phone !== '') {
                    $query
                        ->where('contact_info', $phone)
                        ->orWhere('phone_secondary', $phone);
                }

                if ($secondary !== '') {
                    $query
                        ->orWhere('contact_info', $secondary)
                        ->orWhere('phone_secondary', $secondary);
                }
            })
            ->exists();

        if ($duplicatePhone) {
            abort(response()->json([
                'success' => false,
                'message' => 'يوجد متطوع مسجل بنفس رقم التواصل.',
            ], 422));
        }

        if ($email === '') {
            return;
        }

        $duplicateEmail = ClinicalVolunteer::where('doctor_id', $doctorId)
            ->when($ignoreId, fn ($query) => $query->where('id', '!=', $ignoreId))
            ->where('email', $email)
            ->exists();

        if ($duplicateEmail) {
            abort(response()->json([
                'success' => false,
                'message' => 'يوجد متطوع مسجل بنفس البريد الإلكتروني.',
            ], 422));
        }
    }

    protected function followUpStatuses(): array
    {
        return ['not_contacted', 'contacted', 'agreed', 'declined', 'needs_follow_up'];
    }

    protected function contactMethods(): array
    {
        return ['phone', 'whatsapp', 'email', 'other'];
    }

    protected function followUpStatusLabel(?string $status): string
    {
        return match ($status) {
            'contacted' => 'تم التواصل',
            'agreed' => 'موافق',
            'declined' => 'اعتذر',
            'needs_follow_up' => 'يحتاج متابعة',
            default => 'لم يتم التواصل',
        };
    }

    protected function contactMethodLabel(?string $method): string
    {
        return match ($method) {
            'phone' => 'اتصال',
            'whatsapp' => 'واتساب',
            'email' => 'بريد إلكتروني',
            'other' => 'أخرى',
            default => '',
        };
    }
}
