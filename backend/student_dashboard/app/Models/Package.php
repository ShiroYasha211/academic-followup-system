<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Package extends Model
{
    protected $fillable = [
        'name',
        'slug',
        'price_student',
        'price_doctor',
        'price_delegate',
        'price_administrative',
        'duration_days',
        'is_active',
        'description',
    ];

    public function subscriptions()
    {
        return $this->hasMany(Subscription::class);
    }

    public function activeSubscribersCount(): int
    {
        return $this->subscriptions()->where('status', 'active')->where('ends_at', '>', now())->count();
    }

    public function getPriceForRole(string $role): float
    {
        return (float) match ($role) {
            'student' => $this->price_student,
            'doctor' => $this->price_doctor,
            'delegate', 'practical_delegate' => $this->price_delegate,
            'administrative' => $this->price_administrative,
            default => 0,
        };
    }
}
