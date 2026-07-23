<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DoctorStarWalletTransaction extends Model
{
    protected $fillable = [
        'doctor_star_wallet_id',
        'performed_by',
        'type',
        'amount',
        'balance_after',
        'recipient_count',
        'stars_per_recipient',
        'description',
        'metadata',
    ];

    protected $casts = [
        'amount' => 'integer',
        'balance_after' => 'integer',
        'recipient_count' => 'integer',
        'stars_per_recipient' => 'integer',
        'metadata' => 'array',
    ];

    public function wallet()
    {
        return $this->belongsTo(DoctorStarWallet::class, 'doctor_star_wallet_id');
    }

    public function performer()
    {
        return $this->belongsTo(User::class, 'performed_by');
    }
}
