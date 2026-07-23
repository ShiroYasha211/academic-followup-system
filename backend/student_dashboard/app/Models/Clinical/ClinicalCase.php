<?php

namespace App\Models\Clinical;

use Illuminate\Database\Eloquent\Model;

use App\Models\User;

class ClinicalCase extends Model
{
    protected $fillable = [
        'patient_name',
        'age',
        'gender',
        'training_center_id',
        'clinical_department_id',
        'body_system_id',
        'doctor_id',
        'diagnosis_or_description',
        'status',
        'approval_status',
        'approved_by_id',
        'rejection_reason',
    ];

    public function trainingCenter()
    {
        return $this->belongsTo(TrainingCenter::class);
    }

    public function clinicalDepartment()
    {
        return $this->belongsTo(ClinicalDepartment::class);
    }

    public function bodySystem()
    {
        return $this->belongsTo(BodySystem::class);
    }

    public function doctor()
    {
        return $this->belongsTo(User::class, 'doctor_id');
    }

    public function assignments()
    {
        return $this->hasMany(CaseAssignment::class, 'clinical_case_id')
            ->with(['student.major', 'student.level', 'assigner']);
    }
}
