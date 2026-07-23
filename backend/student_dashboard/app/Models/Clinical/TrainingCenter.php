<?php

namespace App\Models\Clinical;

use Illuminate\Database\Eloquent\Model;

class TrainingCenter extends Model
{
    protected $fillable = [
        'name',
        'location',
        'description',
    ];

    public function cases()
    {
        return $this->hasMany(ClinicalCase::class);
    }
}
