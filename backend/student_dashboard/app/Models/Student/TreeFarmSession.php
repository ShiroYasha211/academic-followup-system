<?php

namespace App\Models\Student;

use App\Models\User;
use Illuminate\Database\Eloquent\Model;

class TreeFarmSession extends Model
{
    protected $fillable = [
        'user_id',
        'subject_id',
        'subject_name',
        'client_uuid',
        'farm_scope',
        'source',
        'status',
        'started_at',
        'ended_at',
        'planned_seconds',
        'focused_seconds',
        'heartbeat_count',
        'last_heartbeat_at',
        'grace_seconds_used',
        'awarded_plant_code',
        'awarded_coins',
        'rejection_reason',
        'synced_at',
    ];

    protected $casts = [
        'started_at' => 'datetime',
        'ended_at' => 'datetime',
        'last_heartbeat_at' => 'datetime',
        'synced_at' => 'datetime',
        'planned_seconds' => 'integer',
        'focused_seconds' => 'integer',
        'heartbeat_count' => 'integer',
        'grace_seconds_used' => 'integer',
        'awarded_coins' => 'integer',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function plant()
    {
        return $this->hasOne(TreeFarmPlant::class);
    }
}
