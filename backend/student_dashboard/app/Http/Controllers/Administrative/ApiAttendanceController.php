<?php

namespace App\Http\Controllers\Administrative;

use App\Exceptions\AttendanceEditLockedException;
use App\Http\Controllers\Api\Administrative\AdministrativeApiController;
use App\Models\Attendance;
use App\Services\AttendanceEditGate;
use App\Support\ExcuseWorkflow;
use Illuminate\Http\Request;

class ApiAttendanceController extends AdministrativeApiController
{
    public function update(Request $request, Attendance $attendance)
    {
        if ($attendance->student?->college_id !== $this->college()->id) {
            return $this->error('The attendance record does not belong to this college.', 403);
        }

        $validated = $request->validate([
            'status' => 'required|in:' . implode(',', ExcuseWorkflow::editableAttendanceStatuses()),
        ]);

        try {
            app(AttendanceEditGate::class)->updateAttendance($attendance, [
                'status' => $validated['status'],
                'recorded_by' => $this->administrative()->id,
            ], $this->administrative());
        } catch (AttendanceEditLockedException $exception) {
            return $this->error($exception->getMessage(), 403, $exception->context());
        }

        if ($attendance->excuse && $attendance->excuse->status === 'accepted') {
            $resolution = match ($validated['status']) {
                ExcuseWorkflow::STATUS_PERMITTED => ExcuseWorkflow::RESOLUTION_PERMISSION,
                ExcuseWorkflow::STATUS_EXEMPTED => ExcuseWorkflow::RESOLUTION_EXEMPTION,
                'absent' => ExcuseWorkflow::RESOLUTION_KEEP_ABSENT,
                default => $attendance->excuse->resolution,
            };

            $attendance->excuse->update([
                'resolution' => $resolution,
                'reviewed_by' => $this->administrative()->id,
            ]);
        }

        return $this->success($attendance->fresh(['student:id,name,student_number', 'subject:id,name', 'excuse']), 'Attendance record updated successfully.');
    }
}
