<?php

namespace App\Models\Academic;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class University extends Model
{
    protected $fillable = ['name', 'code', 'address', 'logo'];

    /**
     * University has many Colleges.
     */
    public function colleges(): HasMany
    {
        return $this->hasMany(College::class);
    }

    /**
     * University has many Users (Students, Doctors, etc.).
     */
    public function users(): HasMany
    {
        return $this->hasMany(\App\Models\User::class);
    }
}
