<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class GradePermission extends Model
{
    use HasFactory;

    protected $fillable = [
        'category_id',
        'authorized_user_id',
    ];

    public function category()
    {
        return $this->belongsTo(GradeCategory::class, 'category_id');
    }

    public function authorizedUser()
    {
        return $this->belongsTo(User::class, 'authorized_user_id');
    }
}
