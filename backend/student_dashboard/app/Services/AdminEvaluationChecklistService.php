<?php

namespace App\Services;

use App\Models\Clinical\ChecklistItem;
use App\Models\Clinical\EvaluationChecklist;
use App\Models\Clinical\MockEvaluation;
use App\Models\Clinical\StudentEvaluation;
use Illuminate\Support\Facades\DB;

class AdminEvaluationChecklistService
{
    public function createStandard(array $data): EvaluationChecklist
    {
        return DB::transaction(fn () => $this->createStandardWithoutTransaction($data));
    }

    public function updateStandard(EvaluationChecklist $checklist, array $data): array
    {
        return DB::transaction(function () use ($checklist, $data) {
            if ($this->hasEvaluationUsage($checklist)) {
                $checklist->update(['is_active' => false]);

                $data['source_checklist_id'] = $checklist->source_checklist_id ?: $checklist->id;

                return [
                    'checklist' => $this->createStandardWithoutTransaction($data),
                    'versioned' => true,
                ];
            }

            $checklist->update([
                'title' => $data['title'],
                'description' => $data['description'] ?? null,
                'skill_type' => $data['skill_type'],
                'time_limit_minutes' => $data['time_limit_minutes'] ?? null,
                'is_practice_allowed' => $this->booleanValue(
                    $data['is_practice_allowed'] ?? $checklist->is_practice_allowed
                ),
                'total_marks' => $this->totalMarks($data['items']),
            ]);

            $checklist->items()->delete();
            $this->createItems($checklist, $data['items']);

            return [
                'checklist' => $checklist->load('items.subItems'),
                'versioned' => false,
            ];
        });
    }

    private function hasEvaluationUsage(EvaluationChecklist $checklist): bool
    {
        return StudentEvaluation::where('checklist_id', $checklist->id)->exists()
            || MockEvaluation::where('checklist_id', $checklist->id)->exists();
    }

    private function createStandardWithoutTransaction(array $data): EvaluationChecklist
    {
        $checklist = EvaluationChecklist::create([
            'title' => $data['title'],
            'description' => $data['description'] ?? null,
            'doctor_id' => null,
            'source_checklist_id' => $data['source_checklist_id'] ?? null,
            'skill_type' => $data['skill_type'],
            'time_limit_minutes' => $data['time_limit_minutes'] ?? null,
            'is_practice_allowed' => $this->booleanValue($data['is_practice_allowed'] ?? false),
            'total_marks' => $this->totalMarks($data['items']),
            'is_active' => true,
        ]);

        $this->createItems($checklist, $data['items']);

        return $checklist->load('items.subItems');
    }

    private function booleanValue(mixed $value): bool
    {
        return filter_var($value, FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE) ?? false;
    }

    private function totalMarks(array $items): int
    {
        return collect($items)->sum(fn ($item) => (int) ($item['marks'] ?? 0));
    }

    private function createItems(EvaluationChecklist $checklist, array $items): void
    {
        foreach ($items as $i => $item) {
            $mainItem = ChecklistItem::create([
                'checklist_id' => $checklist->id,
                'description' => $item['description'],
                'marks' => $item['marks'],
                'sort_order' => $i + 1,
            ]);

            if (empty($item['sub_items'])) {
                continue;
            }

            foreach ($item['sub_items'] as $j => $subItem) {
                ChecklistItem::create([
                    'checklist_id' => $checklist->id,
                    'parent_id' => $mainItem->id,
                    'description' => $subItem['description'],
                    'marks' => $subItem['marks'] ?? 0,
                    'sort_order' => $j + 1,
                ]);
            }
        }
    }
}
