<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class DelegateGradeDelegation extends Model
{
    use HasFactory;

    public const TYPE_FULL = 'full';
    public const TYPE_PARTIAL = 'partial';

    protected $fillable = [
        'category_id',
        'delegated_by_id',
        'helper_user_id',
        'delegation_type',
        'title',
        'notes',
        'due_at',
        'is_revoked',
        'revoked_at',
    ];

    protected $casts = [
        'due_at' => 'datetime',
        'is_revoked' => 'boolean',
        'revoked_at' => 'datetime',
    ];

    public function category()
    {
        return $this->belongsTo(GradeCategory::class, 'category_id');
    }

    public function delegatedBy()
    {
        return $this->belongsTo(User::class, 'delegated_by_id');
    }

    public function helperUser()
    {
        return $this->belongsTo(User::class, 'helper_user_id');
    }

    public function students()
    {
        return $this->belongsToMany(User::class, 'delegate_grade_delegation_students', 'delegation_id', 'student_id')->withTimestamps();
    }

    public function scopeActive($query)
    {
        return $query->where('is_revoked', false);
    }

    public function isFullDelegation(): bool
    {
        return $this->delegation_type === self::TYPE_FULL;
    }
}
