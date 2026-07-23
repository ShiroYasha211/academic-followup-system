<?php

namespace App\Http\Controllers\Api\Student;

use App\Models\Academic\Subject;
use App\Models\Grade;
use App\Models\GradeCategory;
use Illuminate\Http\Request;

class GradeController extends StudentApiController
{
    /**
     * Get student grades grouped by subject and doctor-defined categories.
     */
    public function index(Request $request)
    {
        $student = $request->user();

        $subjects = Subject::where('major_id', $student->major_id)
            ->where('level_id', $student->level_id)
            ->get(['id', 'name']);

        $subjectIds = $subjects->pluck('id');

        $grades = Grade::where('student_id', $student->id)
            ->whereIn('subject_id', $subjectIds)
            ->with(['gradeCategory:id,name,max_score', 'subject:id,name'])
            ->get();

        $results = [];

        foreach ($subjects as $subject) {
            $subjectGrades = $grades->where('subject_id', $subject->id);
            $gradeCategories = GradeCategory::where('subject_id', $subject->id)
                ->orderBy('created_at')
                ->get();

            $items = [];
            $totalMark = 0.0;
            $maxPossibleMark = 0.0;

            if ($gradeCategories->isNotEmpty()) {
                foreach ($gradeCategories as $category) {
                    $grade = $subjectGrades->firstWhere('category_id', $category->id);
                    $score = $grade?->score !== null ? (float) $grade->score : null;
                    $maxScore = (float) $category->max_score;

                    $items[] = [
                        'category_name' => $category->name,
                        'type' => 'category',
                        'score' => $score,
                        'max_score' => $maxScore,
                        'status' => $grade?->status ?? 'not_entered',
                        'date' => $grade?->created_at?->format('Y-m-d'),
                    ];

                    if ($grade?->status === 'approved') {
                        $totalMark += (float) $grade->score;
                    }

                    $maxPossibleMark += $maxScore;
                }
            } else {
                foreach ($subjectGrades->where('type', 'continuous')->whereNull('category_id') as $grade) {
                    $maxScore = (float) ($grade->max_score ?? 0);

                    $items[] = [
                        'category_name' => $grade->category ?? 'أعمال السنة',
                        'type' => 'general_continuous',
                        'score' => (float) $grade->score,
                        'max_score' => $maxScore,
                        'status' => $grade->status,
                        'date' => $grade->created_at->format('Y-m-d'),
                    ];

                    if ($grade->status === 'approved') {
                        $totalMark += (float) $grade->score;
                    }

                    $maxPossibleMark += $maxScore;
                }
            }

            foreach ($subjectGrades->where('type', 'final') as $grade) {
                $maxScore = (float) ($grade->max_score ?? 0);

                $items[] = [
                    'category_name' => 'الاختبار النهائي',
                    'type' => 'final',
                    'score' => (float) $grade->score,
                    'max_score' => $maxScore,
                    'status' => $grade->status,
                    'date' => $grade->created_at->format('Y-m-d'),
                ];

                if ($grade->status === 'approved') {
                    $totalMark += (float) $grade->score;
                }

                $maxPossibleMark += $maxScore;
            }

            $results[] = [
                'subject_id' => $subject->id,
                'subject_name' => $subject->name,
                'total_score' => round($totalMark, 2),
                'max_possible' => round($maxPossibleMark, 2),
                'percentage' => $maxPossibleMark > 0 ? round(($totalMark / $maxPossibleMark) * 100, 1) : 0,
                'categories' => $items,
            ];
        }

        return $this->success([
            'grades' => $results,
            'summary' => [
                'total_subjects' => $subjects->count(),
                'graded_subjects' => count(array_filter($results, fn ($result) => count($result['categories']) > 0)),
            ],
        ]);
    }
}
