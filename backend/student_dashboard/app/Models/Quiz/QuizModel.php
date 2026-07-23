<?php

namespace App\Models\Quiz;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class QuizModel extends Model
{
    use HasFactory;

    protected $fillable = [
        'quiz_id',
        'name',
        'access_code',
    ];

    // ─── Relationships ───

    public function quiz()
    {
        return $this->belongsTo(Quiz::class);
    }

    public function questions()
    {
        return $this->hasMany(QuizQuestion::class);
    }

    public function attempts()
    {
        return $this->hasMany(QuizAttempt::class);
    }

    // ─── Accessors ───

    public function getQuestionsCountAttribute()
    {
        return $this->questions()->count();
    }

    public function getTotalScoreAttribute()
    {
        return $this->questions()->sum('score');
    }
}
