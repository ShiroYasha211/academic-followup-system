<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class StarTransaction extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'granted_by',
        'type',
        'amount',
        'balance_after',
        'description',
        'reference_type',
        'reference_id',
    ];

    protected $casts = [
        'amount' => 'integer',
        'balance_after' => 'integer',
    ];

    // ─── Relationships ───

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function grantedBy()
    {
        return $this->belongsTo(User::class, 'granted_by');
    }

    public function reference()
    {
        return $this->morphTo();
    }

    // ─── Accessors ───

    public function getTypeLabelAttribute()
    {
        return match ($this->type) {
            'quiz_reward'       => 'مكافأة كويز',
            'doctor_gift'       => 'هدية من الدكتور',
            'admin_grant'       => 'منحة من الإدارة',
            'competition_prize' => 'جائزة مسابقة',
            'attendance_bonus'  => 'مكافأة حضور',
            'honor_board'       => 'لوحة الشرف',
            'penalty'           => 'خصم',
            'gifted'            => 'هدية مُرسلة',
            'received_gift'     => 'هدية مُستلمة',
            default             => $this->type,
        };
    }

    public function getTypeIconAttribute()
    {
        return match ($this->type) {
            'quiz_reward'       => 'fa-clipboard-question',
            'doctor_gift'       => 'fa-gift',
            'admin_grant'       => 'fa-building-columns',
            'competition_prize' => 'fa-trophy',
            'attendance_bonus'  => 'fa-calendar-check',
            'honor_board'       => 'fa-crown',
            'penalty'           => 'fa-minus-circle',
            'gifted'            => 'fa-paper-plane',
            'received_gift'     => 'fa-inbox',
            default             => 'fa-star',
        };
    }

    public function getTypeColorAttribute()
    {
        return match ($this->type) {
            'quiz_reward'       => '#10b981',
            'doctor_gift'       => '#8b5cf6',
            'admin_grant'       => '#3b82f6',
            'competition_prize' => '#f59e0b',
            'attendance_bonus'  => '#06b6d4',
            'honor_board'       => '#f59e0b',
            'penalty'           => '#ef4444',
            'gifted'            => '#94a3b8',
            'received_gift'     => '#10b981',
            default             => '#6366f1',
        };
    }

    public function getIsPositiveAttribute()
    {
        return $this->amount > 0;
    }

    // ─── Scopes ───

    public function scopeForUser($query, $userId)
    {
        return $query->where('user_id', $userId);
    }

    public function scopePositive($query)
    {
        return $query->where('amount', '>', 0);
    }

    public function scopeNegative($query)
    {
        return $query->where('amount', '<', 0);
    }
}
