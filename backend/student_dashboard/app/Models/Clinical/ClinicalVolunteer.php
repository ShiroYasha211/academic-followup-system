<?php

namespace App\Models\Clinical;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use App\Models\User;

class ClinicalVolunteer extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'doctor_id',
        'name',
        'contact_info',
        'phone_secondary',
        'email',
        'diagnosis',
        'clinical_signs',
        'is_available',
        'follow_up_status',
        'preferred_contact_method',
        'last_contacted_at',
        'internal_notes',
    ];

    protected $casts = [
        'is_available' => 'boolean',
        'last_contacted_at' => 'datetime',
    ];

    /**
     * Get the doctor who added the volunteer.
     */
    public function doctor()
    {
        return $this->belongsTo(User::class, 'doctor_id');
    }

    public function logs()
    {
        return $this->hasMany(ClinicalVolunteerLog::class, 'clinical_volunteer_id');
    }
}
