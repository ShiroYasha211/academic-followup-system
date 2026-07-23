<?php

namespace App\Observers;

use App\Models\CourseResource;
use App\Models\StudentNotification;
use App\Models\User;

class ResourceObserver
{
    /**
     * Handle the CourseResource "created" event.
     */
    public function created(CourseResource $resource): void
    {
        $subject = $resource->subject;
        if (!$subject) return;

        // Find all students in the same Major + Level
        $students = User::whereIn('role', ['student', 'delegate'])
            ->where('major_id', $subject->major_id)
            ->where('level_id', $subject->level_id)
            ->get();

        foreach ($students as $student) {
            if ($student->id === $resource->created_by) {
                continue;
            }

            StudentNotification::create([
                'user_id' => $student->id,
                'type'    => 'resource',
                'title'   => 'مورد دراسي جديد',
                'message' => "تم إضافة ملف جديد في مادة {$subject->name}: {$resource->title}",
                'data'    => [
                    'resource_id' => $resource->id,
                    'subject_id'  => $subject->id,
                    'category'    => $resource->category,
                ],
            ]);
        }
    }
}
