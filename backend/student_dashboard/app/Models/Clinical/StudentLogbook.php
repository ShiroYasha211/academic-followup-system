<?php

namespace App\Models\Clinical;

use Illuminate\Database\Eloquent\Model;
use App\Models\User;

class StudentLogbook extends Model
{
    protected $fillable = [
        'student_id',
        'clinical_case_id',
        'case_assignment_id',
        'confirmed_by',
        'task_type',
        'notes',
        'qr_token',
        'status',
        'confirmed_at',
    ];

    protected $casts = [
        'confirmed_at' => 'datetime',
    ];

    // ─── Relationships ───

    public function student()
    {
        return $this->belongsTo(User::class, 'student_id');
    }

    public function clinicalCase()
    {
        return $this->belongsTo(ClinicalCase::class, 'clinical_case_id');
    }

    public function caseAssignment()
    {
        return $this->belongsTo(CaseAssignment::class, 'case_assignment_id');
    }

    public function confirmedBy()
    {
        return $this->belongsTo(User::class, 'confirmed_by');
    }

    // ─── Scopes ───

    public function scopePending($query)
    {
        return $query->where('status', 'pending');
    }

    public function scopeConfirmed($query)
    {
        return $query->where('status', 'confirmed');
    }

    // ─── Helpers ───

    public static function generateToken(): string
    {
        return bin2hex(random_bytes(32));
    }

    public function isExpired(): bool
    {
        // QR tokens expire after 30 minutes
        return $this->created_at->diffInMinutes(now()) > 30;
    }
}
