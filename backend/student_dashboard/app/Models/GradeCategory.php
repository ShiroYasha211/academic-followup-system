<?php

namespace App\Models;

use App\Models\Academic\Subject;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class GradeCategory extends Model
{
    use HasFactory;

    protected $fillable = [
        'subject_id',
        'doctor_id',
        'name',
        'max_score',
    ];

    public function subject()
    {
        return $this->belongsTo(Subject::class);
    }

    public function doctor()
    {
        return $this->belongsTo(User::class, 'doctor_id');
    }

    public function permissions()
    {
        return $this->hasMany(GradePermission::class, 'category_id');
    }

    public function grades()
    {
        return $this->hasMany(Grade::class, 'category_id');
    }

    /**
     * Get authorized students for this category.
     */
    public function authorizedUsers()
    {
        return $this->hasManyThrough(User::class, GradePermission::class, 'category_id', 'id', 'id', 'authorized_user_id');
    }

    public function delegateGradeDelegations()
    {
        return $this->hasMany(DelegateGradeDelegation::class, 'category_id');
    }
}
