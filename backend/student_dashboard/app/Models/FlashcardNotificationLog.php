<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class FlashcardNotificationLog extends Model
{
    public $timestamps = false;

    protected $table = 'flashcard_notification_log';

    protected $fillable = [
        'user_id',
        'item_id',
        'pack_id',
        'sent_at',
        'was_opened',
    ];

    protected $casts = [
        'sent_at' => 'datetime',
        'was_opened' => 'boolean',
    ];

    // ── Relationships ──

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function item(): BelongsTo
    {
        return $this->belongsTo(FlashcardItem::class, 'item_id');
    }

    public function pack(): BelongsTo
    {
        return $this->belongsTo(FlashcardPack::class, 'pack_id');
    }
}
