<?php

namespace App\Services;

use App\Models\Academic\Lecture;
use App\Models\Student\StudentScheduleItem;
use App\Models\StudentNotification;

class StudyReminderNotificationService
{
    public function notify(StudentScheduleItem $item, ?string $title = null, ?string $message = null): StudentNotification
    {
        $item->loadMissing('referenceable');

        $lectureId = $item->referenceable instanceof Lecture ? $item->referenceable->id : null;

        return StudentNotification::create([
            'user_id' => $item->user_id,
            'type' => 'study_reminder',
            'title' => $title ?: 'تذكير بالمذاكرة',
            'message' => $message ?: "حان وقت: {$item->display_title}",
            'data' => [
                'schedule_item_id' => $item->id,
                'lecture_id' => $lectureId,
                'target_screen' => 'study_session',
                'action_url' => '/student/study-center/' . $item->id . '/session',
            ],
        ]);
    }
}
