<?php

namespace App\Models\Clinical;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use App\Models\User;

class RareCase extends Model
{
    use SoftDeletes;

    protected $table = 'clinical_rare_cases';

    protected $fillable = [
        'doctor_id',
        'patient_name',
        'hospital',
        'department',
        'room_number',
        'diagnosis',
        'clinical_signs',
        'attachment_path',
        'is_active',
        'status',
        'expires_at',
        'internal_notes',
        'views_count',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'expires_at' => 'datetime',
    ];

    public function doctor()
    {
        return $this->belongsTo(User::class, 'doctor_id');
    }
}
