<?php

namespace App\Observers;

use App\Models\DoctorMessage;
use App\Models\StudentNotification;

class DoctorMessageObserver
{
    /**
     * Handle the DoctorMessage "created" event.
     */
    public function created(DoctorMessage $message): void
    {
        $conversation = $message->conversation;
        if (!$conversation) {
            return;
        }

        if ($message->sender_id === $conversation->doctor_id) {
            StudentNotification::create([
                'user_id' => $conversation->delegate_id,
                'type'    => 'message',
                'title'   => 'رسالة من الدكتور',
                'message' => "لديك رسالة جديدة من الدكتور {$conversation->doctor->name}.",
                'data'    => [
                    'doctor_conversation_id' => $conversation->id,
                    'doctor_id'              => $message->sender_id,
                ],
            ]);
            return;
        }

        StudentNotification::create([
            'user_id' => $conversation->doctor_id,
            'type'    => 'message',
            'title'   => 'رسالة جديدة من المندوب',
            'message' => "لديك رسالة جديدة من المندوب {$conversation->delegate->name}.",
            'data'    => [
                'doctor_conversation_id' => $conversation->id,
                'delegate_id'            => $message->sender_id,
            ],
        ]);
    }
}