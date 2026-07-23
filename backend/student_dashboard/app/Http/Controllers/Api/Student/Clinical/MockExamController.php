<?php

namespace App\Http\Controllers\Api\Student\Clinical;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\Clinical\EvaluationChecklist;
use App\Models\Clinical\ChecklistItem;
use App\Models\Clinical\MockEvaluation;
use App\Models\Clinical\MockScore;

class MockExamController extends Controller
{
    /**
     * Get available checklists and previous mock attempts
     */
    public function index(Request $request)
    {
        $student = $request->user();

        $checklists = EvaluationChecklist::with(['creator', 'doctor'])
            ->forStudent($student->id)
            ->get();

        $previousMocks = MockEvaluation::with('checklist:id,title')
            ->where('student_id', $student->id)
            ->latest()
            ->get()
            ->map(function ($evaluation) {
                return $this->serializeEvaluation($evaluation);
            });

        return response()->json([
            'success' => true,
            'data' => [
                'available_checklists' => $checklists,
                'previous_attempts' => $previousMocks,
            ]
        ], 200);
    }

    /**
     * Create/Store a Custom Checklist created by the student
     */
    public function storeCustom(Request $request)
    {
        $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'items' => 'required|array|min:1',
            'items.*.description' => 'required|string',
            'items.*.marks' => 'required|numeric|min:1',
        ]);

        $student = $request->user();
        $totalMarks = collect($request->items)->sum('marks');

        // Fallback doctor_id since it's required by the schema
        $fallbackDoctor = \App\Models\User::where('role', 'doctor')->first();
        $fallbackDoctorId = $fallbackDoctor ? $fallbackDoctor->id : 1;

        $checklist = EvaluationChecklist::create([
            'title' => $request->title,
            'description' => $request->description,
            'skill_type' => 'other',
            'time_limit_minutes' => 10, // Default for custom
            'total_marks' => $totalMarks,
            'is_active' => true,
            'creator_type' => \App\Models\User::class,
            'creator_id' => $student->id,
            'doctor_id' => $fallbackDoctorId,
        ]);

        foreach ($request->items as $index => $item) {
            ChecklistItem::create([
                'checklist_id' => $checklist->id,
                'description' => $item['description'],
                'marks' => $item['marks'],
                'sort_order' => $index + 1,
            ]);
        }

        $checklist->load('items');

        return response()->json([
            'success' => true,
            'message' => 'تم إنشاء النموذج التجريبي المخصص بنجاح.',
            'data' => $checklist
        ], 201);
    }

    /**
     * Delete a Custom Checklist created by the student
     */
    public function destroyCustom($checklist_id, Request $request)
    {
        $student = $request->user();

        $checklist = EvaluationChecklist::where('id', $checklist_id)
            ->where('creator_type', \App\Models\User::class)
            ->where('creator_id', $student->id)
            ->firstOrFail();

        $checklist->items()->delete();

        $evaluations = MockEvaluation::where('checklist_id', $checklist->id)->get();
        foreach ($evaluations as $eval) {
            $eval->scores()->delete();
            $eval->delete();
        }

        $checklist->delete();

        return response()->json([
            'success' => true,
            'message' => 'تم حذف النموذج المخصص بنجاح.',
        ], 200);
    }

    /**
     * Get Checklist details to start taking the exam
     */
    public function take($checklist_id)
    {
        $student = request()->user();
        $checklist = EvaluationChecklist::with(['creator', 'doctor'])
            ->forStudent($student->id)
            ->with('items')
            ->findOrFail($checklist_id);

        if (!$checklist->is_active) {
            return response()->json(['success' => false, 'message' => 'هذا النموذج غير متاح حالياً.'], 403);
        }

        return response()->json([
            'success' => true,
            'data' => $checklist
        ], 200);
    }

    /**
     * Submit an attempted Mock Exam
     */
    public function submit(Request $request, $checklist_id)
    {
        $request->validate([
            'time_taken' => 'required|integer', // Time taken in seconds
            'scores' => 'required|array', // Structure: {"item_id": {"score": "done", "notes": "good"}}
        ]);

        $student = $request->user();
        $checklist = EvaluationChecklist::with(['creator', 'doctor'])
            ->forStudent($student->id)
            ->with('items')
            ->findOrFail($checklist_id);

        $totalMaxMarks = 0;
        $totalObtainedMarks = 0;
        $calculatedScores = [];

        foreach ($checklist->items as $item) {
            $maxMarks = is_numeric($item->marks) ? $item->marks : 1;
            $itemData = $request->scores[$item->id] ?? [];

            $scoreValue = is_array($itemData) ? ($itemData['score'] ?? null) : $itemData;
            $notesValue = is_array($itemData) ? ($itemData['notes'] ?? null) : null;

            $obtained = match ($scoreValue) {
                'done' => $maxMarks,
                'partial' => $maxMarks / 2,
                default => 0, // 'not_done'
            };

            $totalMaxMarks += $maxMarks;
            $totalObtainedMarks += $obtained;

            $calculatedScores[] = [
                'checklist_item_id' => $item->id,
                'marks_obtained' => $obtained,
                'notes' => $notesValue,
            ];
        }

        $percentage = $totalMaxMarks > 0 ? ($totalObtainedMarks / $totalMaxMarks) * 100 : 0;

        $grade = 'fail';
        if ($percentage >= 90) $grade = 'excellent';
        elseif ($percentage >= 80) $grade = 'vgood';
        elseif ($percentage >= 70) $grade = 'good';
        elseif ($percentage >= 60) $grade = 'pass';

        $mockEvaluation = MockEvaluation::create([
            'student_id' => $student->id,
            'checklist_id' => $checklist->id,
            'percentage' => $percentage,
            'grade' => $grade,
            'time_taken' => $request->time_taken,
        ]);

        foreach ($calculatedScores as $score) {
            MockScore::create([
                'mock_evaluation_id' => $mockEvaluation->id,
                'checklist_item_id' => $score['checklist_item_id'],
                'marks_obtained' => $score['marks_obtained'],
                'notes' => $score['notes'],
            ]);
        }

        $mockEvaluation->load('scores.checklistItem');

        return response()->json([
            'success' => true,
            'message' => 'تم إنهاء وتسليم الاختبار التجريبي بنجاح.',
            'data' => [
                'evaluation_id' => $mockEvaluation->id,
                'percentage' => $percentage,
                'grade' => $grade,
            ]
        ], 201);
    }

    /**
     * Show the detailed results of a submitted Mock Exam along with its specific Radar Chart
     */
    public function showResult($evaluation_id, Request $request)
    {
        $student = $request->user();

        $evaluation = MockEvaluation::with(['checklist', 'scores.checklistItem'])
            ->where('student_id', $student->id)
            ->findOrFail($evaluation_id);

        $chartData = [
            'History Taking' => ['score' => 0, 'max' => 0, 'ar' => 'أخذ القصة'],
            'Clinical Examination' => ['score' => 0, 'max' => 0, 'ar' => 'الفحص السريري'],
            'Communication' => ['score' => 0, 'max' => 0, 'ar' => 'التواصل'],
            'Professionalism' => ['score' => 0, 'max' => 0, 'ar' => 'الاحترافية'],
            'Diagnosis & Management' => ['score' => 0, 'max' => 0, 'ar' => 'التشخيص والعلاج'],
            'Other' => ['score' => 0, 'max' => 0, 'ar' => 'أخرى'],
        ];

        foreach ($evaluation->scores as $sc) {
            $desc = strtolower($sc->checklistItem->description ?? '');
            $obtained = $sc->marks_obtained;
            $max = $sc->checklistItem->marks ?? 0;

            if (str_contains($desc, 'history') || str_contains($desc, 'قصة') || str_contains($desc, 'symptoms') || str_contains($desc, 'السوابق')) {
                $category = 'History Taking';
            } elseif (str_contains($desc, 'exam') || str_contains($desc, 'فحص') || str_contains($desc, 'signs') || str_contains($desc, 'علامات')) {
                $category = 'Clinical Examination';
            } elseif (str_contains($desc, 'communication') || str_contains($desc, 'تواصل') || str_contains($desc, 'explain') || str_contains($desc, 'شرح')) {
                $category = 'Communication';
            } elseif (str_contains($desc, 'professionalism') || str_contains($desc, 'احترافية') || str_contains($desc, 'ethics') || str_contains($desc, 'أخلاقيات')) {
                $category = 'Professionalism';
            } elseif (str_contains($desc, 'diagnosis') || str_contains($desc, 'management') || str_contains($desc, 'تشخيص') || str_contains($desc, 'علاج') || str_contains($desc, 'تدبير')) {
                $category = 'Diagnosis & Management';
            } else {
                $category = 'Other';
            }

            $chartData[$category]['score'] += $obtained;
            $chartData[$category]['max'] += $max;
        }

        $radarData = [];
        foreach ($chartData as $enKey => $vals) {
            if ($vals['max'] > 0) {
                $percentage = round(($vals['score'] / $vals['max']) * 100);
                $radarData[] = [
                    'label_en' => $enKey,
                    'label_ar' => $vals['ar'],
                    'percentage' => $percentage,
                    'score_obtained' => $vals['score'],
                    'score_max' => $vals['max']
                ];
            }
        }

        return response()->json([
            'success' => true,
            'data' => [
                'evaluation' => $this->serializeEvaluation($evaluation),
                'radar_chart' => $radarData,
            ]
        ], 200);
    }

    protected function serializeEvaluation(MockEvaluation $evaluation): array
    {
        $data = $evaluation->toArray();
        $data['grade_label'] = $evaluation->grade_label;
        $data['grade_color'] = $evaluation->grade_color;
        $data['formatted_time'] = $evaluation->formatted_time;

        if ($evaluation->relationLoaded('scores')) {
            $data['scores'] = $evaluation->scores->map(function ($score) {
                $item = $score->checklistItem;
                return array_merge($score->toArray(), [
                    'score_label' => $score->score_label,
                    'max_marks' => $item?->marks,
                    'checklist_item' => $item,
                ]);
            })->values();
        }

        return $data;
    }
}
