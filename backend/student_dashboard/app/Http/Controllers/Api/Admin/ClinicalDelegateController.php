<?php

namespace App\Http\Controllers\Api\Admin;

use App\Enums\UserRole;
use App\Models\Academic\Major;
use App\Models\ClinicalDelegate;
use App\Models\User;
use App\Traits\LogsActivity;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ClinicalDelegateController extends AdminApiController
{
    use LogsActivity;

    public function index()
    {
        $majors = Major::where('has_clinical', true)
            ->with([
                'college.university',
                'levels' => fn ($query) => $query->orderBy('name'),
                'levels.clinicalDelegates.student',
            ])
            ->get()
            ->map(function (Major $major) {
                return [
                    'major' => $major,
                    'levels' => $major->levels->map(fn ($level) => [
                        'id' => $level->id,
                        'name' => $level->name,
                        'delegates' => $level->clinicalDelegates->map(fn (ClinicalDelegate $delegate) => [
                            'id' => $delegate->id,
                            'student' => $delegate->student,
                            'assigned_at' => $delegate->created_at,
                        ])->values(),
                    ])->values(),
                ];
            });

        return $this->success($majors);
    }

    public function store(Request $request)
    {
        $request->validate([
            'major_id' => 'required|exists:majors,id',
            'level_id' => 'required|exists:levels,id',
            'student_id' => 'required|exists:users,id',
        ]);

        $major = Major::where('has_clinical', true)
            ->with('levels')
            ->findOrFail($request->major_id);

        $level = $major->levels->firstWhere('id', (int) $request->level_id);

        if (! $level) {
            return $this->error('المستوى المحدد لا يتبع هذا التخصص.', 422);
        }

        $student = User::where('role', UserRole::STUDENT)
            ->where('major_id', $major->id)
            ->where('level_id', $level->id)
            ->findOrFail($request->student_id);

        $delegate = DB::transaction(function () use ($major, $level, $student, $request) {
            $student->update(['role' => UserRole::PRACTICAL_DELEGATE]);
            $student->grantAllDelegatePermissions($request->user()->id);

            return ClinicalDelegate::updateOrCreate(
                ['student_id' => $student->id],
                [
                    'major_id' => $major->id,
                    'level_id' => $level->id,
                ]
            );
        });

        $this->logCreate('ClinicalDelegate', $delegate, "تم تعيين {$student->name} كمندوب عملي لتخصص {$major->name} - {$level->name} عبر الـ API");

        return $this->success($delegate->load('student', 'major', 'level'), 'تم تعيين المندوب العملي بنجاح', 201);
    }

    public function destroy(ClinicalDelegate $clinicalDelegate)
    {
        $studentName = $clinicalDelegate->student->name ?? 'غير معروف';
        $majorName = $clinicalDelegate->major->name ?? 'غير معروف';

        DB::transaction(function () use ($clinicalDelegate) {
            $student = $clinicalDelegate->student;
            $clinicalDelegate->delete();

            if ($student && $student->role === UserRole::PRACTICAL_DELEGATE) {
                $student->update(['role' => UserRole::STUDENT]);
                $student->revokeDelegatePermissions();
            }
        });

        $this->logDelete('ClinicalDelegate', $clinicalDelegate, "تم إزالة {$studentName} كمندوب عملي لتخصص {$majorName} عبر الـ API");

        return $this->success(null, 'تم إزالة المندوب العملي بنجاح');
    }
}
