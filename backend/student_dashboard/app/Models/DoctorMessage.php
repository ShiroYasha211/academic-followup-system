<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class DoctorMessage extends Model
{
    use HasFactory;

    protected $fillable = [
        'conversation_id',
        'sender_id',
        'body',
        'read_at',
    ];

    protected $casts = [
        'read_at' => 'datetime',
    ];

    /**
     * Get the conversation.
     */
    public function conversation()
    {
        return $this->belongsTo(DoctorConversation::class, 'conversation_id');
    }

    /**
     * Get the sender.
     */
    public function sender()
    {
        return $this->belongsTo(User::class, 'sender_id');
    }
}
