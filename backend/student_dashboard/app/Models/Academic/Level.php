<?php

namespace App\Models\Academic;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Level extends Model
{
    protected $fillable = ['major_id', 'name'];

    /**
     * Level belongs to a Major.
     */
    public function major(): BelongsTo
    {
        return $this->belongsTo(Major::class);
    }

    /**
     * Level has many Terms.
     */
    public function terms(): HasMany
    {
        return $this->hasMany(Term::class);
    }

    /**
     * Level has many practical delegates.
     */
    public function clinicalDelegates(): HasMany
    {
        return $this->hasMany(\App\Models\ClinicalDelegate::class);
    }
}
