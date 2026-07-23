<?php

namespace App\Models\Clinical;

use App\Models\User;
use Illuminate\Database\Eloquent\Model;

class ClinicalVolunteerLog extends Model
{
    protected $fillable = [
        'clinical_volunteer_id',
        'doctor_id',
        'follow_up_status',
        'contact_method',
        'contacted_at',
        'notes',
    ];

    protected $casts = [
        'contacted_at' => 'datetime',
    ];

    public function volunteer()
    {
        return $this->belongsTo(ClinicalVolunteer::class, 'clinical_volunteer_id');
    }

    public function doctor()
    {
        return $this->belongsTo(User::class, 'doctor_id');
    }
}
