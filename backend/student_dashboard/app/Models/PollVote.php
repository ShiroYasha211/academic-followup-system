<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PollVote extends Model
{
    use HasFactory;

    protected $fillable = [
        'batch_id',
        'poll_option_id',
        'student_id',
    ];

    /**
     * Get the poll option that this vote belongs to.
     */
    public function pollOption()
    {
        return $this->belongsTo(PollOption::class);
    }

    /**
     * Get the student that cast this vote.
     */
    public function student()
    {
        return $this->belongsTo(User::class, 'student_id');
    }
}
