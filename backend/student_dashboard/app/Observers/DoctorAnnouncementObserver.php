<?php

namespace App\Observers;

use App\Models\DoctorAnnouncement;
use App\Models\StudentNotification;
use App\Models\User;

class DoctorAnnouncementObserver
{
    public function created(DoctorAnnouncement $announcement): void
    {
        if (! $this->shouldNotify($announcement)) {
            return;
        }

        $this->notifyStudents($announcement);
    }

    public function updated(DoctorAnnouncement $announcement): void
    {
        if (! $announcement->wasChanged('is_published') || ! $this->shouldNotify($announcement)) {
            return;
        }

        $this->notifyStudents($announcement);
    }

    protected function shouldNotify(DoctorAnnouncement $announcement): bool
    {
        return (bool) $announcement->is_published
            && $announcement->published_at
            && $announcement->published_at->lte(now());
    }

    protected function notifyStudents(DoctorAnnouncement $announcement): void
    {
        $announcement->loadMissing('subject', 'doctor');

        $subject = $announcement->subject;

        if (! $subject) {
            return;
        }

        $students = User::whereIn('role', ['student', 'delegate'])
            ->where('major_id', $subject->major_id)
            ->where('level_id', $subject->level_id)
            ->get();

        foreach ($students as $student) {
            if ($student->id === $announcement->doctor_id) {
                continue;
            }

            $exists = StudentNotification::where('user_id', $student->id)
                ->where('type', 'announcement')
                ->where('data->doctor_announcement_id', $announcement->id)
                ->exists();

            if ($exists) {
                continue;
            }

            StudentNotification::create([
                'user_id' => $student->id,
                'college_id' => $student->college_id,
                'sender_id' => $announcement->doctor_id,
                'type' => 'announcement',
                'title' => 'إعلان جديد من الدكتور',
                'message' => "تم نشر إعلان جديد في مادة {$subject->name}: {$announcement->title}",
                'attachment_path' => $announcement->attachment_path,
                'attachment_name' => $announcement->attachment_name,
                'data' => [
                    'doctor_announcement_id' => $announcement->id,
                    'subject_id' => $subject->id,
                    'doctor_id' => $announcement->doctor_id,
                    'source' => 'doctor',
                    'screen' => 'news_hub',
                    'target_screen' => 'news_hub',
                ],
            ]);
        }
    }
}
