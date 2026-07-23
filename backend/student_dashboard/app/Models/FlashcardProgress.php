<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class FlashcardProgress extends Model
{
    protected $table = 'flashcard_progress';

    protected $fillable = [
        'user_id',
        'item_id',
        'times_shown',
        'times_correct',
        'last_response',
        'review_weight',
        'last_shown_at',
        'next_review_at',
    ];

    protected $casts = [
        'last_shown_at' => 'datetime',
        'next_review_at' => 'datetime',
        'times_shown' => 'integer',
        'times_correct' => 'integer',
        'review_weight' => 'integer',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function item(): BelongsTo
    {
        return $this->belongsTo(FlashcardItem::class, 'item_id');
    }

    public function getAccuracyAttribute(): float
    {
        if ($this->times_shown === 0) {
            return 0;
        }

        return round(($this->times_correct / $this->times_shown) * 100, 1);
    }

    public function isDue(): bool
    {
        if (!$this->next_review_at) {
            return true;
        }

        return $this->next_review_at->isPast();
    }
}
