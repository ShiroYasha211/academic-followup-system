<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class FlashcardItem extends Model
{
    protected $fillable = [
        'pack_id',
        'item_type',
        'front_content',
        'back_content',
        'options',
        'correct_option',
        'item_color',
        'priority',
        'sort_order',
    ];

    protected $casts = [
        'options' => 'array',
        'correct_option' => 'integer',
        'sort_order' => 'integer',
    ];

    protected $appends = ['resolved_item_type', 'resolved_color', 'item_type_label'];

    public function pack(): BelongsTo
    {
        return $this->belongsTo(FlashcardPack::class, 'pack_id');
    }

    public function progress(): HasMany
    {
        return $this->hasMany(FlashcardProgress::class, 'item_id');
    }

    public function getPriorityTextAttribute(): string
    {
        return match ($this->priority) {
            'normal' => 'عادية',
            'high' => 'عالية',
            'critical' => 'حرجة',
            default => $this->priority,
        };
    }

    public function getResolvedItemTypeAttribute(): string
    {
        return $this->item_type ?: ($this->pack?->display_mode ?? 'flash_card');
    }

    public function getResolvedColorAttribute(): string
    {
        return $this->item_color ?: ($this->pack?->color ?? '#4f46e5');
    }

    public function getItemTypeLabelAttribute(): string
    {
        return FlashcardPack::itemTypeLabel($this->resolved_item_type);
    }

    public function userProgress(int $userId)
    {
        return $this->progress()->where('user_id', $userId)->first();
    }
}
