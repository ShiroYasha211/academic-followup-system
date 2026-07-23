<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\Student\StudentScheduleItem;
use App\Services\StudyReminderNotificationService;

class SendStudyReminders extends Command
{
    protected $signature = 'study:send-reminders';
    protected $description = 'Send due study reminders based on each item reminder schedule';

    public function handle(StudyReminderNotificationService $studyReminderNotifications)
    {
        $items = StudentScheduleItem::where('is_completed', false)
            ->whereNotNull('next_reminder_at')
            ->where('next_reminder_at', '<=', now())
            ->get();

        $sent = 0;
        foreach ($items as $item) {
            $studyReminderNotifications->notify(
                $item,
                'تذكير من مركز الدراسة',
                "حان وقت تنفيذ: {$item->display_title}"
            );
            $item->markReminderSentAndScheduleNext();
            $sent++;
        }

        $legacyItems = StudentScheduleItem::whereNull('next_reminder_at')
            ->where('is_completed', false)
            ->where('reminder_sent', false)
            ->whereNotNull('reminder_at')
            ->where('reminder_at', '<=', now())
            ->get();

        foreach ($legacyItems as $item) {
            $studyReminderNotifications->notify(
                $item,
                'تذكير من مركز الدراسة',
                "حان وقت تنفيذ: {$item->display_title}"
            );
            $item->markReminderSentAndScheduleNext();
            $sent++;
        }

        $this->info("Sent {$sent} study reminders.");

        return Command::SUCCESS;
    }
}
