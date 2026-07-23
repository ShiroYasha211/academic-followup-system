<?php

namespace App\Models\Student;

use App\Models\User;
use Illuminate\Database\Eloquent\Model;

class TreeFarmThought extends Model
{
    protected $fillable = [
        'user_id',
        'tree_farm_session_id',
        'client_uuid',
        'body',
        'reminder_at',
        'synced_at',
    ];

    protected $casts = [
        'reminder_at' => 'datetime',
        'synced_at' => 'datetime',
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
