<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class StudentDevice extends Model
{
    use HasFactory;

    public const TYPE_PRIMARY = 'primary';
    public const TYPE_SECONDARY = 'secondary';

    protected $fillable = [
        'student_id',
        'device_id',
        'device_name',
        'platform',
        'app_version',
        'device_type',
        'is_primary',
        'is_active',
        'is_temporary',
        'expires_at',
        'approved_by',
        'approved_at',
        'last_login_at',
    ];

    protected $casts = [
        'is_primary' => 'boolean',
        'is_active' => 'boolean',
        'is_temporary' => 'boolean',
        'expires_at' => 'datetime',
        'approved_at' => 'datetime',
        'last_login_at' => 'datetime',
    ];

    public function isValid(): bool
    {
        if (!$this->is_active) {
            return false;
        }
        if ($this->is_temporary && $this->expires_at && $this->expires_at->isPast()) {
            return false;
        }
        return true;
    }

    public function isExpired(): bool
    {
        return $this->is_temporary && $this->expires_at && $this->expires_at->isPast();
    }

    public function student()
    {
        return $this->belongsTo(User::class, 'student_id');
    }

    public function approvedBy()
    {
        return $this->belongsTo(User::class, 'approved_by');
    }

    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    public function scopePrimary($query)
    {
        return $query->where('is_primary', true);
    }

    public function scopeSecondary($query)
    {
        return $query->where('device_type', self::TYPE_SECONDARY);
    }
}
