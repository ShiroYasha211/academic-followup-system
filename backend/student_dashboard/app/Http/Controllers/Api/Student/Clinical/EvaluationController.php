<?php

namespace App\Http\Controllers\Api\Student\Clinical;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Clinical\StudentEvaluation;
use App\Models\Clinical\EvaluationScore;

class EvaluationController extends Controller
{
    /**
     * Get Student OSCE Evaluations and Radar Chart Data
     */
    public function index(Request $request)
    {
        $student = $request->user();

        // 1. Fetch Evaluations
        $evaluations = StudentEvaluation::with(['checklist:id,title', 'doctor:id,name', 'scores.checklistItem'])
            ->where('student_id', $student->id)
            ->latest()
            ->get();

        // 2. Overview Stats
        $avgPercentage = $evaluations->avg('percentage') ? round($evaluations->avg('percentage'), 1) : 0;
        $totalEvals = $evaluations->count();
        $excellentCount = $evaluations->where('grade', 'excellent')->count();

        // 3. Radar Chart Data Logic
        $chartData = [
            'History Taking' => ['score' => 0, 'max' => 0, 'ar' => 'أخذ القصة'],
            'Clinical Examination' => ['score' => 0, 'max' => 0, 'ar' => 'الفحص السريري'],
            'Communication' => ['score' => 0, 'max' => 0, 'ar' => 'التواصل'],
            'Professionalism' => ['score' => 0, 'max' => 0, 'ar' => 'الاحترافية'],
            'Diagnosis & Management' => ['score' => 0, 'max' => 0, 'ar' => 'التشخيص والعلاج'],
            'Other' => ['score' => 0, 'max' => 0, 'ar' => 'أخرى'],
        ];

        // Fetch scores for all student's evaluations to build the overall radar chart
        $allScores = EvaluationScore::with('checklistItem')
            ->whereIn('evaluation_id', $evaluations->pluck('id'))
            ->get();

        foreach ($allScores as $sc) {
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

        // Format for JSON Response
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
                'stats' => [
                    'average_percentage' => $avgPercentage,
                    'total_evaluations' => $totalEvals,
                    'excellent_count' => $excellentCount,
                ],
                'radar_chart' => $radarData,
                'evaluations' => $evaluations
                    ->map(fn (StudentEvaluation $evaluation) => $this->serializeEvaluation($evaluation, true))
                    ->values(),
            ]
        ], 200);
    }

    public function show(Request $request, StudentEvaluation $evaluation)
    {
        abort_unless((int) $evaluation->student_id === (int) $request->user()->id, 404);

        $evaluation->load([
            'checklist:id,title,description',
            'doctor:id,name',
            'clinicalCase:id,patient_name,diagnosis_or_description',
            'bodySystem:id,name',
            'scores.checklistItem',
        ]);

        return response()->json([
            'success' => true,
            'data' => [
                'evaluation' => $this->serializeEvaluation($evaluation, true),
            ],
        ]);
    }

    protected function serializeEvaluation(StudentEvaluation $evaluation, bool $includeScores = false): array
    {
        $data = $evaluation->toArray();
        $data['grade_label'] = $evaluation->grade_label;
        $data['grade_color'] = $evaluation->grade_color;
        $data['formatted_time'] = $evaluation->formatted_time;

        if ($includeScores) {
            $data['scores'] = $evaluation->scores->map(function (EvaluationScore $score) {
                $item = $score->checklistItem;

                return array_merge($score->toArray(), [
                    'score_label' => $score->score_label,
                    'checklist_item' => $item ? [
                        'id' => $item->id,
                        'description' => $item->description,
                        'marks' => $item->marks,
                        'parent_id' => $item->parent_id ?? null,
                    ] : null,
                ]);
            })->values();
        }

        return $data;
    }
}
