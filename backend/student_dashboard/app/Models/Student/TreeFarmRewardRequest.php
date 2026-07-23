<?php

namespace App\Models\Student;

use App\Models\User;
use Illuminate\Database\Eloquent\Model;

class TreeFarmRewardRequest extends Model
{
    protected $fillable = [
        'user_id',
        'coins_amount',
        'stars_amount',
        'conversion_rate',
        'status',
        'reviewed_by',
        'reviewed_at',
        'rejection_reason',
    ];

    protected $casts = [
        'coins_amount' => 'integer',
        'stars_amount' => 'integer',
        'conversion_rate' => 'integer',
        'reviewed_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function reviewer()
    {
        return $this->belongsTo(User::class, 'reviewed_by');
    }
}
