<?php

namespace App\Models\Academic;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Major extends Model
{
    protected $fillable = ['college_id', 'name', 'has_clinical', 'has_semesters'];

    protected $casts = [
        'has_clinical' => 'boolean',
        'has_semesters' => 'boolean',
    ];

    /**
     * Major belongs to a College.
     */
    public function college(): BelongsTo
    {
        return $this->belongsTo(College::class);
    }

    /**
     * Major has many Levels.
     */
    public function levels(): HasMany
    {
        return $this->hasMany(Level::class);
    }

    /**
     * Major has many Students.
     */
    public function students(): HasMany
    {
        return $this->hasMany(\App\Models\User::class);
    }

    /**
     * Major has many clinical delegates across its levels.
     */
    public function clinicalDelegates(): HasMany
    {
        return $this->hasMany(\App\Models\ClinicalDelegate::class);
    }

    /**
     * Legacy helper for places that still need a single representative.
     */
    public function clinicalDelegate()
    {
        return $this->hasOne(\App\Models\ClinicalDelegate::class)->latestOfMany();
    }
}
