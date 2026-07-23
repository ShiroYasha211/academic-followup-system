<?php

namespace App\Models\Student;

use App\Models\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class TreeFarmProfile extends Model
{
    protected $fillable = [
        'user_id',
        'public_name',
        'is_public',
        'use_alias',
        'coins_balance',
        'total_focus_seconds',
        'total_public_focus_seconds',
    ];

    protected $casts = [
        'is_public' => 'boolean',
        'use_alias' => 'boolean',
        'coins_balance' => 'integer',
        'total_focus_seconds' => 'integer',
        'total_public_focus_seconds' => 'integer',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function publicSessions(): HasMany
    {
        return $this->hasMany(TreeFarmSession::class, 'user_id', 'user_id')
            ->where('farm_scope', 'public');
    }

    public function publicPlants(): HasMany
    {
        return $this->hasMany(TreeFarmPlant::class, 'user_id', 'user_id')
            ->where('farm_scope', 'public');
    }
}
