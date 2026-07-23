<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class FlashcardPack extends Model
{
    protected $fillable = [
        'user_id',
        'title',
        'description',
        'color',
        'icon',
        'display_mode',
        'notifications_enabled',
        'daily_notification_count',
        'repeat_cycle',
        'schedule_mode',
        'schedule_weekdays',
        'active_from_time',
        'active_to_time',
        'daily_card_limit',
        'pack_priority',
        'smart_review_enabled',
        'smart_review_frequency_minutes',
        'restart_mode',
        'quiet_start',
        'quiet_end',
        'is_active',
        'is_public',
        'source_pack_id',
        'parent_pack_id',
    ];

    protected $casts = [
        'notifications_enabled' => 'boolean',
        'is_active' => 'boolean',
        'is_public' => 'boolean',
        'daily_notification_count' => 'integer',
        'schedule_weekdays' => 'array',
        'daily_card_limit' => 'integer',
        'smart_review_enabled' => 'boolean',
        'smart_review_frequency_minutes' => 'integer',
    ];

    protected $appends = ['is_assigned'];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function items(): HasMany
    {
        return $this->hasMany(FlashcardItem::class, 'pack_id');
    }

    public function parentPack(): BelongsTo
    {
        return $this->belongsTo(self::class, 'parent_pack_id');
    }

    public function childPacks(): HasMany
    {
        return $this->hasMany(self::class, 'parent_pack_id');
    }

    public function sourcePack(): BelongsTo
    {
        return $this->belongsTo(self::class, 'source_pack_id');
    }

    public function storeEntry(): HasOne
    {
        return $this->hasOne(PublicPackStore::class, 'pack_id');
    }

    public function notificationLogs(): HasMany
    {
        return $this->hasMany(FlashcardNotificationLog::class, 'pack_id');
    }

    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    public function scopePublic($query)
    {
        return $query->where('is_public', true);
    }

    public function scopeForUser($query, int $userId)
    {
        return $query->where('user_id', $userId);
    }

    public function effectiveItems()
    {
        $packIds = $this->is_assigned
            ? $this->resolvedSourcePack()->descendantPackIds()
            : $this->descendantPackIds();

        return FlashcardItem::whereIn('pack_id', $packIds);
    }

    public function cardsCount(): int
    {
        return $this->effectiveItems()->count();
    }

    public function highPriorityCount(): int
    {
        return $this->effectiveItems()->whereIn('priority', ['high', 'critical'])->count();
    }

    public function getDisplayModeTextAttribute(): string
    {
        return self::itemTypeLabel($this->display_mode);
    }

    public function getRepeatCycleTextAttribute(): string
    {
        return match ($this->repeat_cycle) {
            'daily' => 'يومي',
            'weekly' => 'أسبوعي',
            'monthly' => 'شهري',
            default => $this->repeat_cycle,
        };
    }

    public function getIsAssignedAttribute(): bool
    {
        if ($this->source_pack_id === null) {
            return false;
        }

        if ($this->relationLoaded('items') && $this->items->isNotEmpty()) {
            return false;
        }

        if ($this->relationLoaded('childPacks') && $this->childPacks->isNotEmpty()) {
            return false;
        }

        return !$this->items()->exists() && !$this->childPacks()->exists();
    }

    public function resolvedSourcePack(): self
    {
        return $this->sourcePack ?? $this;
    }

    public function effectivePackIds(): array
    {
        return $this->is_assigned
            ? $this->resolvedSourcePack()->descendantPackIds()
            : $this->descendantPackIds();
    }

    public function descendantPackIds(): array
    {
        $ids = [$this->id];
        $children = $this->relationLoaded('childPacks')
            ? $this->childPacks
            : $this->childPacks()->get();

        foreach ($children as $child) {
            $ids = array_merge($ids, $child->descendantPackIds());
        }

        return array_values(array_unique($ids));
    }

    public function isDescendantOf(?int $candidateParentId): bool
    {
        if (!$candidateParentId) {
            return false;
        }

        $current = $this->parentPack()->first();

        while ($current) {
            if ($current->id === $candidateParentId) {
                return true;
            }

            $current = $current->parentPack()->first();
        }

        return false;
    }

    public static function itemTypeLabel(?string $type): string
    {
        return match ($type) {
            'flash_card' => 'بطاقة تعليمية',
            'one_line' => 'نص واحد',
            'qa' => 'سؤال وجواب',
            'mcq' => 'اختيارات',
            default => $type ?: 'غير محدد',
        };
    }
}
