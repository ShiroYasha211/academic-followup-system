<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use App\Models\Academic\Major;
use App\Models\Academic\Level;

class Reminder extends Model
{
    use HasFactory;

    protected $fillable = [
        'title',
        'description',
        'event_date',
        'notify_at',
        'major_id',
        'level_id',
        'created_by',
    ];

    protected $casts = [
        'event_date' => 'datetime',
        'notify_at' => 'datetime',
    ];

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
