<?php

namespace App\Http\Controllers\Administrative;

use App\Exceptions\AttendanceEditLockedException;
use App\Http\Controllers\Controller;
use App\Models\Attendance;
use App\Services\AttendanceEditGate;
use App\Support\ExcuseWorkflow;
use Illuminate\Http\Request;

class AttendanceController extends Controller
{
    public function update(Request $request, Attendance $attendance)
    {
        if ($attendance->student?->college_id !== auth()->user()->college_id) {
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

        $this->syncExcuseResolution($attendance, $validated['status']);

        return back()->with('success', 'Attendance record updated successfully.');
    }

    protected function syncExcuseResolution(Attendance $attendance, string $status): void
    {
        if (!$attendance->excuse || $attendance->excuse->status !== 'accepted') {
            return;
        }

        $resolution = match ($status) {
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
}
