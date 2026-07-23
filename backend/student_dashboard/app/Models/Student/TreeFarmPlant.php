<?php

namespace App\Models\Student;

use App\Models\User;
use Illuminate\Database\Eloquent\Model;

class TreeFarmPlant extends Model
{
    protected $fillable = [
        'user_id',
        'subject_id',
        'subject_name',
        'tree_farm_session_id',
        'farm_scope',
        'plant_code',
        'name',
        'rarity',
        'required_seconds',
        'coins_awarded',
        'status',
        'planted_at',
    ];

    protected $casts = [
        'required_seconds' => 'integer',
        'coins_awarded' => 'integer',
        'planted_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function session()
    {
        return $this->belongsTo(TreeFarmSession::class, 'tree_farm_session_id');
    }
}
