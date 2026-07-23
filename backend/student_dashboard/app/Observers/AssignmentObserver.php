<?php

namespace App\Observers;

use App\Models\Academic\Assignment;
use App\Models\Student\StudentScheduleItem;
use App\Models\StudentNotification;
use App\Models\User;

class AssignmentObserver
{
    /**
     * Handle the Assignment "created" event.
     */
    public function created(Assignment $assignment): void
    {
        $subject = $assignment->subject;

        if (!$subject) {
            return;
        }

        // Find all students in the same Major + Level
        // Adjust logic if enrollment table exists, but based on current analysis it's Major/Level based.
        $students = User::whereIn('role', ['student', 'delegate'])
            ->where('major_id', $subject->major_id)
            ->where('level_id', $subject->level_id)
            ->get();

        foreach ($students as $student) {
            StudentScheduleItem::firstOrCreate(
                [
                    'user_id' => $student->id,
                    'referenceable_type' => Assignment::class,
                    'referenceable_id' => $assignment->id,
                ],
                [
                    'title' => $assignment->title,
                    'scheduled_date' => $assignment->due_date,
                    'item_type' => 'assignment',
                    'priority' => 'high',
                    'status' => 'pending',
                ]
            );

            // Notify student
            if ($student->id !== $assignment->created_by) {
                StudentNotification::create([
                    'user_id' => $student->id,
                    'type'    => 'assignment',
                    'title'   => 'تكليف جديد',
                    'message' => "تم إضافة تكليف جديد في مادة {$subject->name}: {$assignment->title}",
                    'data'    => [
                        'assignment_id' => $assignment->id,
                        'subject_id'    => $subject->id,
                    ],
                ]);
            }
        }
    }

    /**
     * Handle the Assignment "updated" event.
     */
    public function updated(Assignment $assignment): void
    {
        // Update schedule items if due date or title changes
        $items = StudentScheduleItem::where('referenceable_type', Assignment::class)
            ->where('referenceable_id', $assignment->id)
            ->get();

        foreach ($items as $item) {
            $item->update([
                'title' => $assignment->title,
                'scheduled_date' => $assignment->due_date,
            ]);
        }
    }

    /**
     * Handle the Assignment "deleted" event.
     */
    public function deleted(Assignment $assignment): void
    {
        StudentScheduleItem::where('referenceable_type', Assignment::class)
            ->where('referenceable_id', $assignment->id)
            ->delete();
    }
}
