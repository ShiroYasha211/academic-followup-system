<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class DoctorConversation extends Model
{
    use HasFactory;

    protected $fillable = [
        'delegate_id',
        'doctor_id',
        'subject',
        'last_message_at',
    ];

    protected $casts = [
        'last_message_at' => 'datetime',
    ];

    /**
     * Get the delegate.
     */
    public function delegate()
    {
        return $this->belongsTo(User::class, 'delegate_id');
    }

    /**
     * Get the doctor.
     */
    public function doctor()
    {
        return $this->belongsTo(User::class, 'doctor_id');
    }

    /**
     * Get all messages in this conversation.
     */
    public function messages()
    {
        return $this->hasMany(DoctorMessage::class, 'conversation_id')->orderBy('created_at', 'asc');
    }

    /**
     * Get the last message.
     */
    public function lastMessage()
    {
        return $this->hasOne(DoctorMessage::class, 'conversation_id')->latestOfMany();
    }

    /**
     * Get unread count for a user.
     */
    public function unreadCountFor($userId)
    {
        return $this->messages()
            ->where('sender_id', '!=', $userId)
            ->whereNull('read_at')
            ->count();
    }

    /**
     * Mark all messages as read for a user.
     */
    public function markAsReadFor($userId)
    {
        $this->messages()
            ->where('sender_id', '!=', $userId)
            ->whereNull('read_at')
            ->update(['read_at' => now()]);
    }

    /**
     * Get or create a conversation between delegate and doctor.
     */
    public static function getOrCreate($delegateId, $doctorId)
    {
        return self::firstOrCreate(
            ['delegate_id' => $delegateId, 'doctor_id' => $doctorId],
            ['last_message_at' => now()]
        );
    }
}
