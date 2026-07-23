<?php

namespace App\Http\Controllers\Delegate;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Grade;
use App\Models\User;
use App\Models\Academic\Subject;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use App\Enums\UserRole;

class GradeController extends Controller
{
    /**
     * Display subjects with grade counts
     */
    public function index()
    {
        $delegate = Auth::user();

        $subjects = Subject::where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id)
            ->withCount(['grades' => function ($query) use ($delegate) {
                $query->whereHas('student', function ($q) use ($delegate) {
                    $q->where('major_id', $delegate->major_id)
                        ->where('level_id', $delegate->level_id);
                });
            }])
            ->get();

        // Stats
        $totalGrades = Grade::whereIn('subject_id', $subjects->pluck('id'))->count();
        $continuousCount = Grade::whereIn('subject_id', $subjects->pluck('id'))->where('type', 'continuous')->count();
        $finalCount = Grade::whereIn('subject_id', $subjects->pluck('id'))->where('type', 'final')->count();

        $stats = [
            'total' => $totalGrades,
            'continuous' => $continuousCount,
            'final' => $finalCount,
            'subjects' => $subjects->count(),
        ];

        return view('delegate.grades.index', compact('subjects', 'stats'));
    }

    /**
     * Show form to add grades (Excel or Quick Entry)
     */
    public function create(Request $request)
    {
        $delegate = Auth::user();

        $subjects = Subject::where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id)
            ->get();

        $students = User::whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE])
            ->where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id)
            ->orderBy('name')
            ->get();

        $selectedSubject = $request->get('subject_id');

        return view('delegate.grades.create', compact('subjects', 'students', 'selectedSubject'));
    }

    /**
     * Show grades for a specific subject
     */
    public function show(Subject $subject)
    {
        $delegate = Auth::user();

        // Verify subject belongs to delegate's scope
        if ($subject->major_id != $delegate->major_id || $subject->level_id != $delegate->level_id) {
            abort(403);
        }

        $students = User::whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE])
            ->where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id)
            ->orderBy('name')
            ->get();

        $grades = Grade::where('subject_id', $subject->id)
            ->whereIn('student_id', $students->pluck('id'))
            ->get()
            ->groupBy('student_id');

        return view('delegate.grades.show', compact('subject', 'students', 'grades'));
    }

    /**
     * Store grades from quick entry form
     */
    public function storeQuick(Request $request)
    {
        $validated = $request->validate([
            'subject_id' => 'required|exists:subjects,id',
            'type' => 'required|in:continuous,final',
            'category' => 'nullable|string|max:100',
            'max_score' => 'required|numeric|min:1|max:100',
            'grades' => 'required|array',
            'grades.*.student_id' => 'required|exists:users,id',
            'grades.*.score' => 'nullable|numeric|min:0',
        ]);

        $delegate = Auth::user();
        $maxScore = $validated['max_score'];
        $saved = 0;
        $errors = [];

        DB::beginTransaction();
        try {
            foreach ($validated['grades'] as $index => $gradeData) {
                if (!empty($gradeData['score']) || $gradeData['score'] === '0' || $gradeData['score'] === 0) {
                    $score = floatval($gradeData['score']);

                    // Validate score doesn't exceed max
                    if ($score > $maxScore) {
                        $student = User::find($gradeData['student_id']);
                        $errors[] = ($student ? $student->name : 'طالب') . ": الدرجة ($score) أعلى من الدرجة النهائية ($maxScore)";
                        continue;
                    }

                    Grade::updateOrCreate(
                        [
                            'student_id' => $gradeData['student_id'],
                            'subject_id' => $validated['subject_id'],
                            'type' => $validated['type'],
                            'category' => $validated['category'] ?? null,
                        ],
                        [
                            'score' => $score,
                            'max_score' => $maxScore,
                            'created_by' => $delegate->id,
                        ]
                    );
                    $saved++;
                }
            }
            DB::commit();
        } catch (\Exception $e) {
            DB::rollBack();
            return redirect()->back()->with('error', 'حدث خطأ أثناء حفظ الدرجات.');
        }

        if (count($errors) > 0) {
            return redirect()->back()->with('error', 'تم حفظ ' . $saved . ' درجة. الأخطاء: ' . implode(' | ', array_slice($errors, 0, 3)));
        }

        return redirect()->route('delegate.grades.index')
            ->with('success', "تم حفظ $saved درجة بنجاح.");
    }

    /**
     * Store grades from Excel upload
     */
    public function storeExcel(Request $request)
    {
        $validated = $request->validate([
            'subject_id' => 'required|exists:subjects,id',
            'type' => 'required|in:continuous,final',
            'category' => 'nullable|string|max:100',
            'max_score' => 'required|numeric|min:1|max:100',
            'excel_data' => 'required|string',
        ]);

        $delegate = Auth::user();
        $excelData = json_decode($validated['excel_data'], true);
        $maxScore = $validated['max_score'];

        if (!$excelData || !is_array($excelData)) {
            return redirect()->back()->with('error', 'بيانات الملف غير صالحة.');
        }

        // Get students for lookup
        $students = User::whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE])
            ->where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id)
            ->get()
            ->keyBy('student_number');

        $saved = 0;
        $notFound = [];
        $scoreErrors = [];

        DB::beginTransaction();
        try {
            foreach ($excelData as $row) {
                $studentNumber = trim($row['student_number'] ?? '');
                $score = $row['score'] ?? null;

                if (empty($studentNumber) || ($score === null && $score !== 0)) {
                    continue;
                }

                $student = $students->get($studentNumber);
                if (!$student) {
                    $notFound[] = $studentNumber;
                    continue;
                }

                $scoreValue = floatval($score);

                // Validate score doesn't exceed max
                if ($scoreValue > $maxScore) {
                    $scoreErrors[] = $studentNumber;
                    continue;
                }

                Grade::updateOrCreate(
                    [
                        'student_id' => $student->id,
                        'subject_id' => $validated['subject_id'],
                        'type' => $validated['type'],
                        'category' => $validated['category'] ?? null,
                    ],
                    [
                        'score' => $scoreValue,
                        'max_score' => $maxScore,
                        'created_by' => $delegate->id,
                    ]
                );
                $saved++;
            }
            DB::commit();
        } catch (\Exception $e) {
            DB::rollBack();
            return redirect()->back()->with('error', 'حدث خطأ أثناء حفظ الدرجات: ' . $e->getMessage());
        }

        $message = "تم حفظ $saved درجة بنجاح.";
        if (count($notFound) > 0) {
            $message .= " (لم يتم العثور على " . count($notFound) . " طالب)";
        }
        if (count($scoreErrors) > 0) {
            $message .= " (" . count($scoreErrors) . " درجات تجاوزت الحد الأقصى)";
        }

        return redirect()->route('delegate.grades.index')->with('success', $message);
    }

    /**
     * Update a single grade
     */
    public function update(Request $request, Grade $grade)
    {
        $validated = $request->validate([
            'score' => 'required|numeric|min:0',
        ]);

        $grade->update([
            'score' => $validated['score'],
            'created_by' => Auth::id(),
        ]);

        return redirect()->back()->with('success', 'تم تحديث الدرجة.');
    }

    /**
     * Delete a grade
     */
    public function destroy(Grade $grade)
    {
        $grade->delete();
        return redirect()->back()->with('success', 'تم حذف الدرجة.');
    }

    /**
     * Download Excel template with student data
     */
    public function downloadTemplate()
    {
        $delegate = Auth::user();

        $students = User::whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE])
            ->where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id)
            ->orderBy('name')
            ->get(['name', 'student_number']);

        // Create CSV content
        $csvContent = "\xEF\xBB\xBF"; // UTF-8 BOM for Arabic support
        $csvContent .= "رقم القيد,اسم الطالب,الدرجة\n";

        foreach ($students as $student) {
            $csvContent .= "{$student->student_number},{$student->name},\n";
        }

        $filename = 'grades_template_' . date('Y-m-d') . '.csv';

        return response($csvContent)
            ->header('Content-Type', 'text/csv; charset=UTF-8')
            ->header('Content-Disposition', 'attachment; filename="' . $filename . '"');
    }
}
