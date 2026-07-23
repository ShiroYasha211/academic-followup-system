<?php

namespace App\Observers;

use App\Jobs\SendPushNotificationJob;
use App\Models\StudentNotification;
use App\Services\PushNotificationService;

class StudentNotificationObserver
{
    public function created(StudentNotification $studentNotification): void
    {
        if (! $studentNotification->user_id) {
            return;
        }

        if (config('services.firebase.queue')) {
            SendPushNotificationJob::dispatch($studentNotification->id);
            return;
        }

        app(PushNotificationService::class)->sendStudentNotification($studentNotification);
    }
}
