<?php

namespace App\Observers;

use App\Models\Message;
use App\Models\StudentNotification;

class MessageObserver
{
    /**
     * Handle the Message "created" event.
     */
    public function created(Message $message): void
    {
        // Only notify the student if the sender is NOT the student
        // Assuming delegate_to_student or similar type
        if ($message->sender_id !== $message->receiver_id) {
            StudentNotification::create([
                'user_id' => $message->receiver_id,
                'type'    => 'message',
                'title'   => 'رسالة جديدة',
                'message' => "لديك رسالة جديدة من المندوب.",
                'data'    => [
                    'conversation_id' => $message->conversation_id,
                    'sender_id'       => $message->sender_id,
                ],
            ]);
        }
    }
}
