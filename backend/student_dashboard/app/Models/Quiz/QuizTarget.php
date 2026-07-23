<?php

namespace App\Models\Quiz;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use App\Models\Academic\University;
use App\Models\Academic\College;
use App\Models\Academic\Major;
use App\Models\Academic\Level;

class QuizTarget extends Model
{
    use HasFactory;

    protected $fillable = [
        'quiz_id',
        'university_id',
        'college_id',
        'major_id',
        'level_id',
    ];

    // ─── Relationships ───

    public function quiz()
    {
        return $this->belongsTo(Quiz::class);
    }

    public function university()
    {
        return $this->belongsTo(University::class);
    }

    public function college()
    {
        return $this->belongsTo(College::class);
    }

    public function major()
    {
        return $this->belongsTo(Major::class);
    }

    public function level()
    {
        return $this->belongsTo(Level::class);
    }
}
