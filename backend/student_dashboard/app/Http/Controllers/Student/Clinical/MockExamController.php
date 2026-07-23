<?php

namespace App\Http\Controllers\Student\Clinical;

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
     * Display a list of available checklists for mock exams and previous attempts.
     */
    public function index()
    {
        $student = Auth::user();

        $checklists = EvaluationChecklist::with(['creator', 'doctor'])
            ->forStudent($student->id)
            ->get();

        $previousMocks = MockEvaluation::with('checklist')
            ->where('student_id', $student->id)
            ->latest()
            ->get();

        return view('student.clinical.mock.index', compact('checklists', 'previousMocks'));
    }

    /**
     * Start a new mock exam session for a specific checklist.
     */
    public function take($checklist_id)
    {
        $checklist = EvaluationChecklist::with(['creator', 'doctor'])
            ->forStudent(Auth::id())
            ->with('items')
            ->findOrFail($checklist_id);

        if (!$checklist->is_active) {
            return redirect()->route('student.clinical.mock.index')->with('error', 'هذا النموذج غير متاح حالياً.');
        }

        return view('student.clinical.mock.take', compact('checklist'));
    }

    /**
     * Submit and grade the mock exam.
     */
    public function store(Request $request)
    {
        $request->validate([
            'checklist_id' => 'required|exists:evaluation_checklists,id',
            'time_taken' => 'required|integer', // Time taken in seconds
            'scores' => 'required|array',
        ]);

        $student = Auth::user();
        $checklist = EvaluationChecklist::with(['creator', 'doctor'])
            ->forStudent($student->id)
            ->with('items')
            ->findOrFail($request->checklist_id);

        $totalMaxMarks = 0;
        $totalObtainedMarks = 0;

        // Calculate scores
        $calculatedScores = [];
        foreach ($checklist->items as $item) {
            // Skip parent items, their score is derived from children
            if ($item->subItems()->count() > 0) {
                continue;
            }

            $maxMarks = is_numeric($item->marks) ? $item->marks : 1;

            // Updated expecting array shape: scores[item_id] = ['score' => 'done|partial|not_done', 'notes' => 'text']
            $itemData = $request->scores[$item->id] ?? [];
            $scoreValue = $itemData['score'] ?? null;
            $notesValue = $itemData['notes'] ?? null;

            $obtained = match ($scoreValue) {
                'done' => $maxMarks,
                'partial' => $maxMarks / 2, // Half marks for partial
                default => 0, // 'not_done' or missing gives 0
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

        // Save Mock Evaluation
        $mockEvaluation = MockEvaluation::create([
            'student_id' => $student->id,
            'checklist_id' => $checklist->id,
            'percentage' => $percentage,
            'grade' => $grade,
            'time_taken' => $request->time_taken,
        ]);

        // Save Scores
        foreach ($calculatedScores as $score) {
            MockScore::create([
                'mock_evaluation_id' => $mockEvaluation->id,
                'checklist_item_id' => $score['checklist_item_id'],
                'marks_obtained' => $score['marks_obtained'],
                'notes' => $score['notes'],
            ]);
        }

        return redirect()->route('student.clinical.mock.show', $mockEvaluation->id)
            ->with('success', 'تم إنهاء الاختبار التجريبي بنجاح!');
    }

    /**
     * Show the results of a submitted mock exam.
     */
    public function show($id)
    {
        $student = Auth::user();

        $evaluation = MockEvaluation::with(['checklist', 'scores.checklistItem'])
            ->where('student_id', $student->id)
            ->findOrFail($id);

        /** Compute Radar Data exactly like the main Evaluation Controller */
        $chartData = [
            'History Taking' => ['score' => 0, 'max' => 0],
            'Clinical Examination' => ['score' => 0, 'max' => 0],
            'Communication' => ['score' => 0, 'max' => 0],
            'Professionalism' => ['score' => 0, 'max' => 0],
            'Diagnosis & Management' => ['score' => 0, 'max' => 0],
            'Other' => ['score' => 0, 'max' => 0],
        ];

        foreach ($evaluation->scores as $sc) {
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

        $radarLabels = [];
        $radarData = [];
        foreach ($chartData as $cat => $vals) {
            if ($vals['max'] > 0) {
                $radarLabels[] = $cat;
                $radarData[] = round(($vals['score'] / $vals['max']) * 100);
            }
        }

        return view('student.clinical.mock.result', compact('evaluation', 'radarLabels', 'radarData'));
    }

    /**
     * Show the form for creating a new custom mock checklist.
     */
    public function createCustom()
    {
        return view('student.clinical.mock.create');
    }

    /**
     * Store a newly created custom mock checklist in storage.
     */
    public function storeCustom(Request $request)
    {
        $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'items' => 'required|array|min:1',
            'items.*.description' => 'required|string',
            'items.*.marks' => 'required|numeric|min:1',
            'items.*.sub_items' => 'nullable|array',
            'items.*.sub_items.*.description' => 'required_with:items.*.sub_items|string',
            'items.*.sub_items.*.marks' => 'required_with:items.*.sub_items|numeric|min:1',
        ]);

        $student = Auth::user();

        // Calculate total marks from items
        $totalMarks = 0;
        foreach ($request->items as $item) {
            $totalMarks += (float)$item['marks'];
            if (!empty($item['sub_items'])) {
                $subTotal = collect($item['sub_items'])->sum('marks');
                if ($subTotal !== (float)$item['marks']) {
                    return back()->withInput()->withErrors(['items' => "مجموع درجات العناصر الفرعية يجب أن يساوي درجة العنصر الرئيسي '{$item['description']}' ({$item['marks']})."]);
                }
            }
        }

        $checklist = EvaluationChecklist::create([
            'title' => $request->title,
            'description' => $request->description,
            'doctor_id' => null,
            'skill_type' => 'procedure',
            'time_limit_minutes' => 10,
            'total_marks' => $totalMarks,
            'is_active' => true,
            'creator_type' => \App\Models\User::class,
            'creator_id' => $student->id,
        ]);

        foreach ($request->items as $index => $item) {
            $mainItem = ChecklistItem::create([
                'checklist_id' => $checklist->id,
                'description' => $item['description'],
                'marks' => $item['marks'],
                'sort_order' => $index + 1,
            ]);

            if (!empty($item['sub_items'])) {
                foreach ($item['sub_items'] as $j => $subItem) {
                    ChecklistItem::create([
                        'checklist_id' => $checklist->id,
                        'parent_id' => $mainItem->id,
                        'description' => $subItem['description'],
                        'marks' => $subItem['marks'],
                        'sort_order' => $j + 1,
                    ]);
                }
            }
        }

        return redirect()->route('student.clinical.mock.index')->with('success', 'تم إنشاء النموذج التجريبي بنجاح!');
    }

    /**
     * Remove the specified custom mock checklist.
     */
    public function destroyCustom($id)
    {
        $student = Auth::user();

        $checklist = EvaluationChecklist::where('id', $id)
            ->where('creator_type', \App\Models\User::class)
            ->where('creator_id', $student->id)
            ->firstOrFail();

        // Delete associated items (if not cascaded in DB)
        $checklist->items()->delete();

        // Delete associated mock evaluations and scores
        $evaluations = MockEvaluation::where('checklist_id', $checklist->id)->get();
        foreach ($evaluations as $eval) {
            $eval->scores()->delete();
            $eval->delete();
        }

        $checklist->delete();

        return redirect()->route('student.clinical.mock.index')->with('success', 'تم حذف النموذج التجريبي بنجاح.');
    }
}
