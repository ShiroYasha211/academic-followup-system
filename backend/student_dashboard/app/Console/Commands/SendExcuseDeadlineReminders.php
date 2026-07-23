<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\Attendance;
use App\Models\StudentNotification;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class SendExcuseDeadlineReminders extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'attendance:remind-deadlines';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Send notifications to students who have absences approaching the excuse deadline (5 days past absence).';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $this->info('Starting excuse deadline reminders check...');

        // Logic:
        // Deadline is 7 days.
        // We want to remind them when 2 days are left.
        // So we look for absences that occurred exactly 5 days ago.

        $targetDate = Carbon::today()->subDays(5)->format('Y-m-d');

        $this->info("Checking for absences on date: {$targetDate}");

        $absences = Attendance::whereDate('date', $targetDate)
            ->where('status', 'absent')
            ->whereDoesntHave('excuse') // No excuse submitted yet
            ->with(['student', 'subject'])
            ->get();

        $count = 0;

        foreach ($absences as $attendance) {
            // Double check deadline just in case logic changes
            $deadline = Carbon::parse($attendance->date)->addDays(7);
            $daysLeft = now()->diffInDays($deadline, false);

            // Create Notification
            StudentNotification::create([
                'user_id' => $attendance->student_id,
                'type' => 'alert', // alert type for red icon/emphasis
                'title' => 'تنبيه: مهلة العذر قاربت على الانتهاء',
                'message' => "باقي يومين فقط لتقديم عذر لغيابك في مادة {$attendance->subject->name} بتاريخ {$attendance->date->format('Y-m-d')}.",
                'data' => [
                    'attendance_id' => $attendance->id,
                    'subject_id' => $attendance->subject_id,
                    'action_url' => route('student.attendance.index'), // Direct them to attendance page
                ]
            ]);

            $count++;
        }

        $this->info("Sent {$count} reminders.");
    }
}
