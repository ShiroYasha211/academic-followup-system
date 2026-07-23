<?php

namespace App\Models\Academic;

use Illuminate\Database\Eloquent\Model;
use App\Models\User;

class AssignmentPriority extends Model
{
    protected $table = 'student_assignment_priorities';

    protected $fillable = [
        'user_id',
        'assignment_id',
        'priority',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function assignment()
    {
        return $this->belongsTo(Assignment::class);
    }
}
