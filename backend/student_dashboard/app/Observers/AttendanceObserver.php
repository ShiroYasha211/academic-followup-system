<?php

namespace App\Observers;

use App\Models\Attendance;
use App\Models\StudentNotification;

class AttendanceObserver
{
    public function created(Attendance $attendance): void
    {
        $this->notifyWhenAbsent($attendance);
    }

    public function updated(Attendance $attendance): void
    {
        $this->notifyWhenAbsent($attendance);
    }

    protected function notifyWhenAbsent(Attendance $attendance): void
    {
        if ($attendance->status !== Attendance::STATUS_ABSENT) {
            return;
        }

        $statusChanged = $attendance->wasRecentlyCreated || $attendance->wasChanged('status');

        if (!$statusChanged) {
            return;
        }

        $previousStatus = $attendance->getOriginal('status');
        $wasQrPresence = $previousStatus === Attendance::STATUS_PRESENT
            && $attendance->attendance_method === 'qr';

        StudentNotification::create([
            'user_id' => $attendance->student_id,
            'type' => 'attendance',
            'title' => $wasQrPresence ? 'تم تعديل حالة حضورك' : 'تسجيل غياب',
            'message' => $wasQrPresence
                ? "تم تعديل حالة حضورك في مادة {$attendance->subject->name} بتاريخ {$attendance->date->format('Y-m-d')} إلى غياب بعد المراجعة النهائية."
                : "تم تسجيل غيابك في مادة {$attendance->subject->name} بتاريخ {$attendance->date->format('Y-m-d')}.",
            'data' => [
                'event' => $wasQrPresence ? 'attendance_changed_after_review' : 'absence_recorded',
                'attendance_id' => $attendance->id,
                'subject_id' => $attendance->subject_id,
                'subject_name' => $attendance->subject->name,
                'date' => $attendance->date->format('Y-m-d'),
            ],
        ]);
    }
}
