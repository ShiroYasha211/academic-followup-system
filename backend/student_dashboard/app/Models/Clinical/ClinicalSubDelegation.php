<?php

namespace App\Models\Clinical;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use App\Models\User;

class ClinicalSubDelegation extends Model
{
    use HasFactory;

    protected $fillable = [
        'delegator_id',
        'student_id',
        'expires_at',
        'is_revoked',
    ];

    protected $casts = [
        'expires_at' => 'datetime',
        'is_revoked' => 'boolean',
    ];

    public function delegator()
    {
        return $this->belongsTo(User::class, 'delegator_id');
    }

    public function student()
    {
        return $this->belongsTo(User::class, 'student_id');
    }
}
