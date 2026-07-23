<?php

namespace App\Http\Controllers\Api\Desktop;

use App\Models\Academic\Subject;
use Illuminate\Support\Str;
use Illuminate\Http\Request;
use App\Http\Controllers\Api\BaseController;

class AttendanceController extends BaseController
{
    public function subjects(Request $request)
    {
        $user = $request->user();
        $workspace = $this->workspaceFromToken($request);

        $subjects = match ($workspace) {
            'doctor' => Subject::query()
                ->where('doctor_id', $user->id),
            'delegate' => Subject::query()
                ->where('major_id', $user->major_id)
                ->where('level_id', $user->level_id)
                ->where('allow_delegate_attendance', true),
            default => Subject::query()->whereRaw('1 = 0'),
        };

        $data = $subjects
            ->with([
                'doctor:id,name',
                'major:id,name',
                'level:id,name',
            ])
            ->orderBy('name')
            ->get([
                'id',
                'name',
                'code',
                'major_id',
                'level_id',
                'doctor_id',
                'allow_delegate_attendance',
            ])
            ->map(fn (Subject $subject) => [
                'id' => $subject->id,
                'name' => $subject->name,
                'code' => $subject->code,
                'doctor' => $subject->doctor ? [
                    'id' => $subject->doctor->id,
                    'name' => $subject->doctor->name,
                ] : null,
                'major' => $subject->major ? [
                    'id' => $subject->major->id,
                    'name' => $subject->major->name,
                ] : null,
                'level' => $subject->level ? [
                    'id' => $subject->level->id,
                    'name' => $subject->level->name,
                ] : null,
                'allow_delegate_attendance' => (bool) $subject->allow_delegate_attendance,
            ])
            ->values();

        return $this->success([
            'workspace' => $workspace,
            'subjects' => $data,
        ], 'تم جلب المواد المتاحة للتحضير.');
    }

    protected function workspaceFromToken(Request $request): ?string
    {
        $token = $request->user()?->currentAccessToken();

        if (!$token) {
            return null;
        }

        foreach ($token->abilities ?? [] as $ability) {
            if (str_starts_with($ability, 'workspace:')) {
                return Str::after($ability, 'workspace:');
            }
        }

        return null;
    }
}
