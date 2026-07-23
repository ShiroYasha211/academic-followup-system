<?php

namespace App\Models\Academic;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class College extends Model
{
    protected $fillable = [
        'university_id', 
        'name',
        'absence_deprivation_percentage',
        'excuses_deadline_days',
        'excuse_receiver',
        'qr_rotation_seconds',
        'doctor_initial_star_balance',
    ];

    protected $casts = [
        'doctor_initial_star_balance' => 'integer',
    ];

    /**
     * College belongs to a University.
     */
    public function university(): BelongsTo
    {
        return $this->belongsTo(University::class);
    }

    /**
     * College has many Majors.
     */
    public function majors(): HasMany
    {
        return $this->hasMany(Major::class);
    }

    /**
     * College has many Users (Students, Doctors, etc.).
     */
    public function users(): HasMany
    {
        return $this->hasMany(\App\Models\User::class);
    }
}
