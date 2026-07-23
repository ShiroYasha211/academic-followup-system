<?php

namespace App\Models\Clinical;

use Illuminate\Database\Eloquent\Model;

class BodySystem extends Model
{
    protected $fillable = [
        'doctor_id',
        'name',
        'description',
    ];

    public function cases()
    {
        return $this->hasMany(ClinicalCase::class);
    }

    public function doctor()
    {
        return $this->belongsTo(\App\Models\User::class, 'doctor_id');
    }

    public function hiddenBy()
    {
        return $this->belongsToMany(\App\Models\User::class, 'doctor_hidden_body_systems', 'body_system_id', 'doctor_id')->withTimestamps();
    }

    public function scopeForDoctor($query, $user)
    {
        $hiddenIds = $user->hiddenBodySystems()->pluck('body_systems.id')->toArray();
        return $query->where(function ($q) use ($user, $hiddenIds) {
            $q->whereNull('doctor_id');
            if (!empty($hiddenIds)) {
                $q->whereNotIn('id', $hiddenIds);
            }
        })->orWhere('doctor_id', $user->id);
    }
}
