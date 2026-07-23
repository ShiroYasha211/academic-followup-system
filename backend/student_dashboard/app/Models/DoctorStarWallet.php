<?php

namespace App\Models;

use App\Models\Academic\College;
use Illuminate\Database\Eloquent\Model;

class DoctorStarWallet extends Model
{
    protected $fillable = [
        'doctor_id',
        'college_id',
        'balance',
        'total_allocated',
        'total_spent',
    ];

    protected $casts = [
        'balance' => 'integer',
        'total_allocated' => 'integer',
        'total_spent' => 'integer',
    ];

    public function doctor()
    {
        return $this->belongsTo(User::class, 'doctor_id');
    }

    public function college()
    {
        return $this->belongsTo(College::class);
    }

    public function transactions()
    {
        return $this->hasMany(DoctorStarWalletTransaction::class);
    }
}
