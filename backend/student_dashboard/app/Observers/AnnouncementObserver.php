<?php

namespace App\Observers;

use App\Models\Announcement;
use App\Models\StudentNotification;
use App\Models\User;

class AnnouncementObserver
{
    /**
     * Handle the Announcement "created" event.
     */
    public function created(Announcement $announcement): void
    {
        // Find all students in the same Major + Level
        $students = User::whereIn('role', ['student', 'delegate'])
            ->where('major_id', $announcement->major_id)
            ->where('level_id', $announcement->level_id)
            ->get();

        foreach ($students as $student) {
            // Avoid notifying the person who created it if they are a delegate
            if ($student->id === $announcement->created_by) {
                continue;
            }

            StudentNotification::create([
                'user_id' => $student->id,
                'type'    => 'announcement',
                'title'   => 'إعلان جديد',
                'message' => "تم نشر إعلان جديد: {$announcement->title}",
                'data'    => [
                    'announcement_id' => $announcement->id,
                    'category'        => $announcement->category,
                ],
            ]);
        }
    }
}
