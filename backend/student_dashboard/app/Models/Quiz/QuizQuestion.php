<?php

namespace App\Models\Quiz;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class QuizQuestion extends Model
{
    use HasFactory;

    protected $fillable = [
        'quiz_model_id',
        'question_text',
        'question_image',
        'question_type',
        'score',
        'time_limit_seconds',
        'correction_note',
        'info_source',
        'order',
    ];

    protected $casts = [
        'score' => 'decimal:2',
        'time_limit_seconds' => 'integer',
    ];

    // ─── Relationships ───

    public function quizModel()
    {
        return $this->belongsTo(QuizModel::class);
    }

    public function options()
    {
        return $this->hasMany(QuizOption::class, 'question_id');
    }

    public function answers()
    {
        return $this->hasMany(QuizAnswer::class, 'question_id');
    }

    // ─── Accessors ───

    public function getCorrectOptionAttribute()
    {
        return $this->options()->where('is_correct', true)->first();
    }

    public function getImageUrlAttribute()
    {
        return $this->question_image ? asset('storage/' . $this->question_image) : null;
    }

    public function getTypeLabelAttribute()
    {
        return match ($this->question_type) {
            'multiple_choice' => 'اختيار من متعدد',
            'true_false'      => 'صح أو خطأ',
            default           => $this->question_type,
        };
    }
}
