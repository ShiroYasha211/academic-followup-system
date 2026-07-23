<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ExamSchedule extends Model
{
    use HasFactory;

    protected $fillable = [
        'major_id',
        'level_id',
        'term_id',
        'title',
        'description',
        'is_published',
        'created_by',
    ];

    protected $casts = [
        'is_published' => 'boolean',
    ];

    public function items()
    {
        return $this->hasMany(ExamScheduleItem::class);
    }

    public function major()
    {
        return $this->belongsTo(\App\Models\Academic\Major::class);
    }

    public function level()
    {
        return $this->belongsTo(\App\Models\Academic\Level::class);
    }

    public function term()
    {
        return $this->belongsTo(\App\Models\Academic\Term::class);
    }

    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }
}
