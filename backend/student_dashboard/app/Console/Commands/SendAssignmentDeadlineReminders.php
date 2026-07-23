<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\Student\StudentScheduleItem;
use App\Models\StudentNotification;
use Carbon\Carbon;

class SendAssignmentDeadlineReminders extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'assignment:remind-deadlines';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Send notifications for pending assignments due in 2 days.';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $this->info('Starting assignment deadline reminders check...');

        // Check for assignments due in exactly 2 days
        $targetDate = Carbon::today()->addDays(2)->format('Y-m-d');

        $this->info("Checking for assignments due on: {$targetDate}");

        $items = StudentScheduleItem::where('item_type', 'assignment')
            ->whereDate('scheduled_date', $targetDate)
            ->where('status', '!=', 'completed')
            ->with(['user']) // Student
            ->get();

        $count = 0;

        foreach ($items as $item) {
            // Create Notification
            StudentNotification::create([
                'user_id' => $item->user_id,
                'type' => 'alert',
                'title' => 'تذكير: موعد تسليم التكليف اقترب',
                'message' => "باقي يومين على موعد تسليم التكليف: {$item->title}.",
                'data' => [
                    'schedule_item_id' => $item->id,
                    'action_url' => route('student.schedule.index'), // Link to Study Hub (where assignments tab will be)
                ]
            ]);

            $count++;
        }

        $this->info("Sent {$count} assignment reminders.");
    }
}
