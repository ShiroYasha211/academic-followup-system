<?php

namespace App\Models\Clinical;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class MockScore extends Model
{
    use HasFactory;

    protected $fillable = [
        'mock_evaluation_id',
        'checklist_item_id',
        'marks_obtained',
        'notes',
    ];

    protected $casts = [
        'marks_obtained' => 'float',
    ];

    public function mockEvaluation()
    {
        return $this->belongsTo(MockEvaluation::class, 'mock_evaluation_id');
    }

    public function checklistItem()
    {
        return $this->belongsTo(ChecklistItem::class, 'checklist_item_id');
    }

    // Helper to get score label similar to EvaluationScore
    public function getScoreLabelAttribute()
    {
        if (!$this->checklistItem) return 'not_done';

        $max = (float) $this->checklistItem->marks;
        $obtained = (float) $this->marks_obtained;
        if ($max > 0 && $obtained >= $max) return 'done';
        if ($obtained > 0) return 'partial';
        return 'not_done';
    }
}
