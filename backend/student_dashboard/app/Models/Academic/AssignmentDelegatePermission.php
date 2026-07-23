<?php

namespace App\Models\Academic;

use App\Models\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AssignmentDelegatePermission extends Model
{
    protected $fillable = [
        'doctor_id',
        'delegate_id',
        'subject_id',
        'can_create',
        'can_edit_own',
        'can_delete_own',
        'can_edit_doctor_assignments',
        'can_delete_doctor_assignments',
    ];

    protected $casts = [
        'can_create' => 'boolean',
        'can_edit_own' => 'boolean',
        'can_delete_own' => 'boolean',
        'can_edit_doctor_assignments' => 'boolean',
        'can_delete_doctor_assignments' => 'boolean',
    ];

    public function doctor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'doctor_id');
    }

    public function delegate(): BelongsTo
    {
        return $this->belongsTo(User::class, 'delegate_id');
    }

    public function subject(): BelongsTo
    {
        return $this->belongsTo(Subject::class);
    }

    public function toFlags(): array
    {
        return [
            'can_create' => (bool) $this->can_create,
            'can_edit_own' => (bool) $this->can_edit_own,
            'can_delete_own' => (bool) $this->can_delete_own,
            'can_edit_doctor_assignments' => (bool) $this->can_edit_doctor_assignments,
            'can_delete_doctor_assignments' => (bool) $this->can_delete_doctor_assignments,
        ];
    }

    public static function emptyFlags(): array
    {
        return [
            'can_create' => false,
            'can_edit_own' => false,
            'can_delete_own' => false,
            'can_edit_doctor_assignments' => false,
            'can_delete_doctor_assignments' => false,
        ];
    }
}
