<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use App\Models\Academic\Major;
use App\Models\Academic\Level;
use Illuminate\Support\Facades\Storage;

class Announcement extends Model
{
    use HasFactory;

    protected $fillable = [
        'title',
        'content',
        'attachment_path',
        'attachment_type',
        'category',
        'is_pinned',
        'views_count',
        'major_id',
        'level_id',
        'created_by',
    ];

    protected $casts = [
        'is_pinned' => 'boolean',
        'views_count' => 'integer',
    ];

    protected $appends = ['attachment_url'];

    // Accessor for attachment URL
    public function getAttachmentUrlAttribute()
    {
        if ($this->attachment_path) {
            return asset(Storage::url($this->attachment_path));
        }
        return null;
    }

    // Scope for pinned announcements first
    public function scopePinnedFirst($query)
    {
        return $query->orderBy('is_pinned', 'desc')->latest();
    }

    // Scope for category filter
    public function scopeOfCategory($query, $category)
    {
        if ($category && $category !== 'all') {
            return $query->where('category', $category);
        }
        return $query;
    }

    public function major()
    {
        return $this->belongsTo(Major::class);
    }

    public function level()
    {
        return $this->belongsTo(Level::class);
    }

    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }
}
