<?php

namespace App\Models\Clinical;

use Illuminate\Database\Eloquent\Model;

class EvaluationScore extends Model
{
    protected $fillable = ['evaluation_id', 'checklist_item_id', 'score', 'marks_obtained', 'note'];

    public function evaluation()
    {
        return $this->belongsTo(StudentEvaluation::class, 'evaluation_id');
    }

    public function checklistItem()
    {
        return $this->belongsTo(ChecklistItem::class, 'checklist_item_id');
    }

    public function getScoreLabelAttribute(): string
    {
        return match ($this->score) {
            'done' => 'أداء كامل',
            'partial' => 'أداء جزئي',
            'not_done' => 'لم ينفذ',
            default => '-',
        };
    }
}
