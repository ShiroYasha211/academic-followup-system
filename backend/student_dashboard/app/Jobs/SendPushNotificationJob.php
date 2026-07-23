<?php

namespace App\Jobs;

use App\Models\StudentNotification;
use App\Services\PushNotificationService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class SendPushNotificationJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(public int $notificationId)
    {
    }

    public function handle(PushNotificationService $pushNotificationService): void
    {
        $notification = StudentNotification::find($this->notificationId);

        if (! $notification) {
            return;
        }

        $pushNotificationService->sendStudentNotification($notification);
    }
}
