<?php

namespace App\Models\Academic;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Semester extends Model
{
    protected $fillable = ['term_id', 'name'];

    /**
     * Semester belongs to a Term.
     */
    public function term(): BelongsTo
    {
        return $this->belongsTo(Term::class);
    }

    /**
     * Semester has many Subjects.
     */
    public function subjects(): HasMany
    {
        return $this->hasMany(Subject::class);
    }
}
