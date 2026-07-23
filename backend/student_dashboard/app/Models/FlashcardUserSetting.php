<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class FlashcardUserSetting extends Model
{
    protected $fillable = [
        'user_id',
        'smart_review_enabled',
        'active_from_time',
        'active_to_time',
        'quiet_start',
        'quiet_end',
        'daily_card_limit',
        'smart_review_frequency_minutes',
        'auto_restart_enabled',
        'prompt_mode',
        'one_line_notifications_enabled',
        'one_line_daily_limit',
        'one_line_frequency_minutes',
        'one_line_active_from_time',
        'one_line_active_to_time',
        'one_line_quiet_start',
        'one_line_quiet_end',
    ];

    protected $casts = [
        'smart_review_enabled' => 'boolean',
        'daily_card_limit' => 'integer',
        'smart_review_frequency_minutes' => 'integer',
        'auto_restart_enabled' => 'boolean',
        'one_line_notifications_enabled' => 'boolean',
        'one_line_daily_limit' => 'integer',
        'one_line_frequency_minutes' => 'integer',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
