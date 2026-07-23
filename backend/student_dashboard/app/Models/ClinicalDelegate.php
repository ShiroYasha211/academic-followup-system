<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ClinicalDelegate extends Model
{
    protected $fillable = ['student_id', 'major_id', 'level_id'];

    /**
     * The student assigned as clinical delegate.
     */
    public function student(): BelongsTo
    {
        return $this->belongsTo(User::class, 'student_id');
    }

    /**
     * The major this delegate is responsible for.
     */
    public function major(): BelongsTo
    {
        return $this->belongsTo(\App\Models\Academic\Major::class);
    }

    /**
     * The level this practical delegate is responsible for.
     */
    public function level(): BelongsTo
    {
        return $this->belongsTo(\App\Models\Academic\Level::class);
    }
}
