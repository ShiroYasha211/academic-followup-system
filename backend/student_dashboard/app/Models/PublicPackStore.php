<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PublicPackStore extends Model
{
    protected $table = 'public_pack_store';

    protected $fillable = [
        'pack_id',
        'published_by',
        'category',
        'downloads_count',
        'is_featured',
        'is_active',
    ];

    protected $casts = [
        'is_featured' => 'boolean',
        'is_active' => 'boolean',
        'downloads_count' => 'integer',
    ];

    // ── Relationships ──

    public function pack(): BelongsTo
    {
        return $this->belongsTo(FlashcardPack::class, 'pack_id');
    }

    public function publisher(): BelongsTo
    {
        return $this->belongsTo(User::class, 'published_by');
    }
}
