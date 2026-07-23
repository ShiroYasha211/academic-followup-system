<?php

namespace App\Http\Controllers\Doctor;

use App\Exceptions\AttendanceEditLockedException;
use App\Http\Controllers\Controller;
use App\Models\Attendance;
use App\Services\AttendanceEditGate;
use App\Support\ExcuseWorkflow;
use Illuminate\Http\Request;

class AttendanceRecordController extends Controller
{
    public function update(Request $request, Attendance $attendance)
    {
        if ($attendance->subject?->doctor_id !== auth()->id()) {
            abort(403);
        }

        $validated = $request->validate([
            'status' => 'required|in:' . implode(',', ExcuseWorkflow::editableAttendanceStatuses()),
        ]);

        try {
            app(AttendanceEditGate::class)->updateAttendance($attendance, [
                'status' => $validated['status'],
                'recorded_by' => auth()->id(),
            ], $request->user());
        } catch (AttendanceEditLockedException $exception) {
            return back()->with('error', $exception->getMessage());
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
                'reviewed_by' => auth()->id(),
            ]);
        }

        return back()->with('success', 'Attendance record updated successfully.');
    }
}
