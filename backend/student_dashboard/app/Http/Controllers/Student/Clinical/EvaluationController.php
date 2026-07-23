<?php

namespace App\Http\Controllers\Student\Clinical;

use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\Auth;

use App\Models\Clinical\StudentEvaluation;

class EvaluationController extends Controller
{
    public function index()
    {
        $student = Auth::user();

        $evaluations = StudentEvaluation::with(['checklist', 'doctor'])
            ->where('student_id', $student->id)
            ->latest()
            ->get();

        // Stats
        $avgPercentage = $evaluations->avg('percentage') ?? 0;
        $totalEvals = $evaluations->count();
        $excellentCount = $evaluations->where('grade', 'excellent')->count();

        // Radar Chart Data Logic (Categorizing checklist items by keywords to form skills)
        $chartData = [
            'History Taking' => ['score' => 0, 'max' => 0],
            'Clinical Examination' => ['score' => 0, 'max' => 0],
            'Communication' => ['score' => 0, 'max' => 0],
            'Professionalism' => ['score' => 0, 'max' => 0],
            'Diagnosis & Management' => ['score' => 0, 'max' => 0],
            'Other' => ['score' => 0, 'max' => 0],
        ];

        // Fetch scores for all student's evaluations to build the overall radar chart
        $allScores = \App\Models\Clinical\EvaluationScore::with('checklistItem')
            ->whereIn('evaluation_id', $evaluations->pluck('id'))
            ->get();

        foreach ($allScores as $sc) {
            $desc = strtolower($sc->checklistItem->description ?? '');
            $obtained = $sc->marks_obtained;
            $max = $sc->checklistItem->marks ?? 0;

            if (str_contains($desc, 'history') || str_contains($desc, 'قصة') || str_contains($desc, 'symptoms')) {
                $category = 'History Taking';
            } elseif (str_contains($desc, 'exam') || str_contains($desc, 'فحص') || str_contains($desc, 'signs')) {
                $category = 'Clinical Examination';
            } elseif (str_contains($desc, 'communication') || str_contains($desc, 'تواصل') || str_contains($desc, 'explain')) {
                $category = 'Communication';
            } elseif (str_contains($desc, 'professionalism') || str_contains($desc, 'احترافية') || str_contains($desc, 'ethics')) {
                $category = 'Professionalism';
            } elseif (str_contains($desc, 'diagnosis') || str_contains($desc, 'management') || str_contains($desc, 'تشخيص') || str_contains($desc, 'علاج')) {
                $category = 'Diagnosis & Management';
            } else {
                $category = 'Other';
            }

            $chartData[$category]['score'] += $obtained;
            $chartData[$category]['max'] += $max;
        }

        // Format for Chart.js
        $radarLabels = [];
        $radarData = [];
        foreach ($chartData as $cat => $vals) {
            if ($vals['max'] > 0) {
                // If the category has been tested, calculate percentage
                $radarLabels[] = $cat;
                $radarData[] = round(($vals['score'] / $vals['max']) * 100);
            }
        }

        return view('student.clinical.evaluations', compact('evaluations', 'avgPercentage', 'totalEvals', 'excellentCount', 'radarLabels', 'radarData'));
    }

    public function show($id)
    {
        $evaluation = StudentEvaluation::with(['checklist', 'doctor', 'scores.checklistItem'])
            ->where('student_id', Auth::id())
            ->findOrFail($id);

        return view('student.clinical.evaluation_detail', compact('evaluation'));
    }
}
