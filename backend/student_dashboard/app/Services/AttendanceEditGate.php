<?php

namespace App\Services;

use App\Exceptions\AttendanceEditLockedException;
use App\Models\Attendance;
use App\Models\AttendanceChangeLog;
use App\Models\AttendanceEditPermission;
use App\Models\User;
use Illuminate\Support\Arr;

class AttendanceEditGate
{
    public function upsertAttendance(array $lookup, array $values, User $actor): Attendance
    {
        $attendance = Attendance::where($lookup)->first();

        if ($attendance) {
            return $this->updateAttendance($attendance, $values, $actor);
        }

        return Attendance::create(array_merge($lookup, $values));
    }

    public function updateAttendance(Attendance $attendance, array $values, User $actor): Attendance
    {
        $permission = null;

        if ($this->requiresUnlock($attendance, $values)) {
            $permission = $this->activePermissionFor($actor, $attendance);

            if (!$permission) {
                throw new AttendanceEditLockedException(context: $this->lockContext($attendance));
            }
        }

        $trackedBefore = $this->trackedValues($attendance);
        $attendance->update($values);
        $attendance->refresh();
        $trackedAfter = $this->trackedValues($attendance);

        if ($trackedBefore !== $trackedAfter) {
            $this->logChange($attendance, $actor, $trackedBefore, $trackedAfter, $permission);
        }

        return $attendance;
    }

    public function requiresUnlock(Attendance $attendance, array $values = []): bool
    {
        if (!$attendance->exists) {
            return false;
        }

        if ($this->isInitialQrFinalReview($attendance, $values)) {
            return false;
        }

        foreach ($this->trackedKeys() as $key) {
            if (array_key_exists($key, $values) && $this->normalize($attendance->{$key}) !== $this->normalize($values[$key])) {
                return true;
            }
        }

        return false;
    }

    public function activePermissionFor(User $actor, Attendance $attendance): ?AttendanceEditPermission
    {
        return AttendanceEditPermission::active()
            ->where('user_id', $actor->id)
            ->where(function ($query) use ($attendance) {
                if ($attendance->lecture_id) {
                    $query->orWhere('lecture_id', $attendance->lecture_id);
                }

                if ($attendance->qr_attendance_session_id) {
                    $query->orWhere('qr_attendance_session_id', $attendance->qr_attendance_session_id);
                }

                $query->orWhere(function ($scope) use ($attendance) {
                    $scope->where('subject_id', $attendance->subject_id)
                        ->whereDate('date', $attendance->date);
                });
            })
            ->latest('expires_at')
            ->first();
    }

    protected function isInitialQrFinalReview(Attendance $attendance, array $values): bool
    {
        return $attendance->qr_attendance_session_id !== null
            && $attendance->lecture_id === null
            && !empty($values['lecture_id']);
    }

    protected function logChange(
        Attendance $attendance,
        User $actor,
        array $before,
        array $after,
        ?AttendanceEditPermission $permission
    ): void {
        AttendanceChangeLog::create([
            'attendance_id' => $attendance->id,
            'changed_by' => $actor->id,
            'attendance_edit_permission_id' => $permission?->id,
            'attendance_edit_request_id' => $permission?->attendance_edit_request_id,
            'student_id' => $attendance->student_id,
            'subject_id' => $attendance->subject_id,
            'lecture_id' => $attendance->lecture_id,
            'qr_attendance_session_id' => $attendance->qr_attendance_session_id,
            'date' => $attendance->date,
            'old_status' => $before['status'] ?? null,
            'new_status' => $after['status'] ?? null,
            'changes' => [
                'before' => $before,
                'after' => $after,
            ],
        ]);
    }

    protected function trackedValues(Attendance $attendance): array
    {
        return Arr::only($attendance->getAttributes(), $this->trackedKeys());
    }

    protected function trackedKeys(): array
    {
        return [
            'status',
            'subject_id',
            'lecture_id',
            'date',
            'recorded_by',
            'attendance_method',
            'qr_attendance_session_id',
        ];
    }

    protected function normalize(mixed $value): string
    {
        if ($value instanceof \DateTimeInterface) {
            return $value->format('Y-m-d');
        }

        return (string) ($value ?? '');
    }

    protected function lockContext(Attendance $attendance): array
    {
        return [
            'attendance_id' => $attendance->id,
            'subject_id' => $attendance->subject_id,
            'lecture_id' => $attendance->lecture_id,
            'qr_attendance_session_id' => $attendance->qr_attendance_session_id,
            'date' => $attendance->date?->format('Y-m-d'),
        ];
    }
}
