<?php

namespace App\Http\Controllers\Api\Doctor;

use App\Enums\UserRole;
use App\Models\Academic\Subject;
use App\Models\Grade;
use App\Models\StudentNote;
use App\Models\User;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class GradeController extends DoctorApiController
{
    /** GET /api/doctor/grades */
    public function index()
    {
        $subjects = Subject::where('doctor_id', Auth::id())->with(['major', 'level'])->get();
        $subjectIds = $subjects->pluck('id');

        $gradeStats = Grade::whereIn('subject_id', $subjectIds)
            ->where('status', 'approved')
            ->select(
                'subject_id',
                DB::raw('SUM(score) as total_score'),
                DB::raw('COUNT(DISTINCT student_id) as graded_students')
            )
            ->groupBy('subject_id')
            ->get()
            ->keyBy('subject_id');

        $studentsCountMap = User::whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE, UserRole::PRACTICAL_DELEGATE])
            ->whereIn('major_id', $subjects->pluck('major_id')->unique())
            ->whereIn('level_id', $subjects->pluck('level_id')->unique())
            ->select('major_id', 'level_id', DB::raw('count(*) as count'))
            ->groupBy('major_id', 'level_id')
            ->get()
            ->keyBy(fn ($i) => $i->major_id . '_' . $i->level_id);

        $data = $subjects->map(function ($subject) use ($gradeStats, $studentsCountMap) {
            $stats = $gradeStats->get($subject->id);
            $key = $subject->major_id . '_' . $subject->level_id;

            return [
                'id' => $subject->id,
                'name' => $subject->name,
                'major' => $subject->major?->name,
                'level' => $subject->level?->name,
                'grade_settings' => $subject->gradeSettingsPayload(),
                'students_count' => $studentsCountMap->has($key) ? $studentsCountMap->get($key)->count : 0,
                'graded_students' => $stats?->graded_students ?? 0,
                'average_grade' => $stats && $stats->graded_students > 0
                    ? round($stats->total_score / $stats->graded_students, 1)
                    : null,
            ];
        });

        return $this->success($data);
    }

    /** GET /api/doctor/grades/{subject} */
    public function show(Request $request, $id)
    {
        $subject = Subject::where('doctor_id', Auth::id())
            ->with('gradeCategories')
            ->findOrFail($id);

        $hasCategories = $subject->gradeCategories->isNotEmpty();

        $students = User::whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE, UserRole::PRACTICAL_DELEGATE])
            ->where('major_id', $subject->major_id)
            ->where('level_id', $subject->level_id)
            ->with([
                'grades' => fn ($query) => $query->where('subject_id', $subject->id),
                'studentNotes' => fn ($query) => $query
                    ->where('subject_id', $subject->id)
                    ->where('doctor_id', Auth::id())
                    ->latest()
                    ->limit(3),
            ])
            ->orderBy('name')
            ->get()
            ->map(function ($student) use ($hasCategories) {
                $finalGrade = $student->grades->where('type', 'final')->first();
                $continuousGrades = $student->grades
                    ->where('type', 'continuous')
                    ->where('status', 'approved');
                if ($hasCategories) {
                    $continuousGrades = $continuousGrades->whereNotNull('category_id');
                }
                $continuous = $continuousGrades
                    ->sum('score');

                return [
                    'id' => $student->id,
                    'name' => $student->name,
                    'student_number' => $student->student_number,
                    'continuous' => round((float) $continuous, 2),
                    'final' => $finalGrade?->score,
                    'total' => round((float) $continuous + (float) ($finalGrade?->score ?? 0), 2),
                    'category_grades' => $student->grades
                        ->where('type', 'continuous')
                        ->whereNotNull('category_id')
                        ->values()
                        ->map(fn ($grade) => [
                            'category_id' => $grade->category_id,
                            'score' => $grade->score,
                            'status' => $grade->status,
                        ]),
                    'notes' => $student->studentNotes
                        ->map(fn ($note) => [
                            'id' => $note->id,
                            'note' => $note->note,
                            'created_at' => $note->created_at,
                        ])
                        ->values(),
                ];
            });

        $totals = $students->pluck('total')->filter(fn ($value) => $value > 0);
        $pendingCount = Grade::where('subject_id', $subject->id)
            ->where('status', 'pending')
            ->count();

        return $this->success([
            'subject' => [
                'id' => $subject->id,
                'name' => $subject->name,
                'grade_settings' => $subject->gradeSettingsPayload(),
            ],
            'categories' => $subject->gradeCategories,
            'students' => $students,
            'pending_count' => $pendingCount,
            'stats' => [
                'total_students' => $students->count(),
                'graded' => $totals->count(),
                'average' => $totals->count() > 0 ? round($totals->avg(), 1) : 0,
                'highest' => $totals->max() ?? 0,
                'lowest' => $totals->min() ?? 0,
                'pass_rate' => $totals->count() > 0
                    ? round($totals->filter(fn ($value) => $value >= $subject->gradePassingScore())->count() / $totals->count() * 100)
                    : 0,
            ],
        ]);
    }

    /** PUT /api/doctor/grades/{subject}/settings */
    public function updateSettings(Request $request, $id)
    {
        $subject = Subject::where('doctor_id', Auth::id())->findOrFail($id);

        $validated = $request->validate([
            'total_max_score' => 'required|numeric|min:1|max:1000',
            'continuous_max_score' => 'required|numeric|min:0|max:1000',
            'final_max_score' => 'required|numeric|min:0|max:1000',
            'passing_score' => 'required|numeric|min:0|max:1000',
        ]);

        $total = (float) $validated['total_max_score'];
        $continuousMax = (float) $validated['continuous_max_score'];
        $finalMax = (float) $validated['final_max_score'];
        $passing = (float) $validated['passing_score'];

        if (round($continuousMax + $finalMax, 2) !== round($total, 2)) {
            return $this->error('مجموع أعمال السنة والاختبار النهائي يجب أن يساوي الدرجة النهائية.', 422);
        }

        if ($passing > $total) {
            return $this->error('درجة النجاح لا يمكن أن تتجاوز الدرجة النهائية.', 422);
        }

        $invalidContinuous = Grade::where('subject_id', $subject->id)
            ->where('type', 'continuous')
            ->whereNull('category_id')
            ->where('score', '>', $continuousMax)
            ->with('student:id,name,student_number')
            ->get()
            ->map(fn ($grade) => [
                'student_id' => $grade->student_id,
                'name' => $grade->student?->name,
                'student_number' => $grade->student?->student_number,
                'score' => $grade->score,
                'type' => 'continuous',
            ]);

        $invalidFinal = Grade::where('subject_id', $subject->id)
            ->where('type', 'final')
            ->where('score', '>', $finalMax)
            ->with('student:id,name,student_number')
            ->get()
            ->map(fn ($grade) => [
                'student_id' => $grade->student_id,
                'name' => $grade->student?->name,
                'student_number' => $grade->student?->student_number,
                'score' => $grade->score,
                'type' => 'final',
            ]);

        $categoriesTotal = $subject->gradeCategories()->sum('max_score');
        if ($categoriesTotal > ($continuousMax + 0.01)) {
            return $this->error('مجموع تصنيفات أعمال السنة الحالي يتجاوز الحد الجديد.', 422, [
                'categories_total' => round((float) $categoriesTotal, 2),
                'continuous_max_score' => $continuousMax,
            ]);
        }

        $invalidStudents = $invalidContinuous->concat($invalidFinal)->values();
        if ($invalidStudents->isNotEmpty()) {
            return $this->error('لا يمكن حفظ الإعدادات لأن هناك درجات طلاب تتجاوز الحدود الجديدة.', 422, [
                'invalid_students' => $invalidStudents,
            ]);
        }

        $subject->update([
            'grade_total_max_score' => $total,
            'grade_continuous_max_score' => $continuousMax,
            'grade_final_max_score' => $finalMax,
            'grade_passing_score' => $passing,
        ]);

        Grade::where('subject_id', $subject->id)
            ->where('type', 'continuous')
            ->whereNull('category_id')
            ->update(['max_score' => $continuousMax]);

        Grade::where('subject_id', $subject->id)
            ->where('type', 'final')
            ->update(['max_score' => $finalMax]);

        return $this->success([
            'subject' => [
                'id' => $subject->id,
                'name' => $subject->name,
                'grade_settings' => $subject->fresh()->gradeSettingsPayload(),
            ],
        ], 'تم تحديث إعدادات الدرجات بنجاح.');
    }

    /** POST /api/doctor/grades/{subject} */
    public function store(Request $request, $id)
    {
        $subject = Subject::where('doctor_id', Auth::id())->findOrFail($id);

        $request->validate([
            'grades' => 'required|array',
            'grades.*.student_id' => 'required|exists:users,id',
            'grades.*.continuous' => 'nullable|numeric|min:0|max:' . $subject->gradeContinuousMaxScore(),
            'grades.*.final' => 'nullable|numeric|min:0|max:' . $subject->gradeFinalMaxScore(),
            'grades.*.categories' => 'nullable|array',
            'grades.*.categories.*' => 'nullable|numeric|min:0',
        ]);

        $hasCategories = $subject->gradeCategories()->exists();

        foreach ($request->grades as $gradeData) {
            $studentId = $gradeData['student_id'];

            if ($hasCategories) {
                Grade::where('subject_id', $subject->id)
                    ->where('student_id', $studentId)
                    ->where('type', 'continuous')
                    ->whereNull('category_id')
                    ->delete();
            } elseif (array_key_exists('continuous', $gradeData) && $gradeData['continuous'] !== null && $gradeData['continuous'] !== '') {
                Grade::updateOrCreate(
                    [
                        'subject_id' => $subject->id,
                        'student_id' => $studentId,
                        'type' => 'continuous',
                        'category_id' => null,
                    ],
                    [
                        'category' => 'أعمال السنة',
                        'score' => $gradeData['continuous'],
                        'max_score' => $subject->gradeContinuousMaxScore(),
                        'created_by' => Auth::id(),
                        'status' => 'approved',
                    ]
                );
            }

            if (array_key_exists('final', $gradeData) && $gradeData['final'] !== null && $gradeData['final'] !== '') {
                Grade::updateOrCreate(
                    [
                        'subject_id' => $subject->id,
                        'student_id' => $studentId,
                        'type' => 'final',
                    ],
                    [
                        'category' => 'final',
                        'score' => $gradeData['final'],
                        'max_score' => $subject->gradeFinalMaxScore(),
                        'created_by' => Auth::id(),
                        'status' => 'approved',
                    ]
                );
            }

            foreach (($gradeData['categories'] ?? []) as $categoryId => $score) {
                if ($score === null || $score === '') {
                    continue;
                }

                $category = $subject->gradeCategories()->find($categoryId);
                if (! $category) {
                    continue;
                }

                Grade::updateOrCreate(
                    [
                        'subject_id' => $subject->id,
                        'student_id' => $studentId,
                        'type' => 'continuous',
                        'category_id' => $category->id,
                    ],
                    [
                        'category' => $category->name,
                        'score' => $score,
                        'max_score' => $category->max_score,
                        'created_by' => Auth::id(),
                        'status' => 'approved',
                    ]
                );
            }
        }

        return $this->success(null, 'تم حفظ الدرجات بنجاح.');
    }

    /** GET /api/doctor/grades/{subject}/report */
    public function report($id)
    {
        return $this->success($this->buildReportData($id));
    }

    /** GET /api/doctor/grades/{subject}/report/pdf */
    public function reportPdf($id)
    {
        $data = $this->buildReportData($id);
        $subject = $data['subject'];
        $stats = $data['stats'];
        $students = collect($data['students']);
        $generatedAt = now()->format('Y-m-d H:i');

        // تعريف دالة الاختصار لمعالجة وتشكيل النصوص العربية للـ PDF
        $ar = fn($text) => \App\Helpers\ArabicHelper::fixArabic((string) $text, true);

        // بناء صفوف الجدول مع تشكيل النصوص (معكوسة الترتيب برمجياً لتظهر من اليمين لليسار)
        $rows = $students->map(function ($student) use ($ar) {
            $isPassed = $student['status'] === 'passed';
            $statusBg = $isPassed ? '#e6f4ea' : '#fce8e6';
            $statusColor = $isPassed ? '#137333' : '#c5221f';
            $statusLabel = $isPassed ? 'ناجح' : 'راسب';
            
            return '<tr>'
                . '<td style="text-align: center;">'
                . '<span style="background-color:' . $statusBg . '; color:' . $statusColor . '; padding: 3px 8px; border-radius: 6px; font-weight: 700; font-size: 10px; display: inline-block;">' 
                . e($ar($statusLabel)) 
                . '</span>'
                . '</td>'
                . '<td style="text-align: center;">' . e($ar($student['grade_label'])) . '</td>'
                . '<td style="text-align: center; font-size: 13px; color: #163f8f;"><strong>' . e($student['total']) . '</strong></td>'
                . '<td style="text-align: center;">' . e($student['final'] ?? '-') . '</td>'
                . '<td style="text-align: center;">' . e($student['continuous']) . '</td>'
                . '<td style="text-align: center; color: #475569;">' . e($student['student_number']) . '</td>'
                . '<td style="text-align: right; font-weight: bold;">' . e($ar($student['name'])) . '</td>'
                . '<td style="text-align: center;">' . e($student['rank']) . '</td>'
                . '</tr>';
        })->implode('');

        $html = <<<HTML
<!doctype html>
<html lang="ar">
<head>
<meta charset="utf-8">
<style>
@page {
    margin: 30px 35px;
}
body { 
    direction: ltr; 
    font-family: DejaVu Sans, sans-serif; 
    color: #0f172a; 
    font-size: 11px; 
    line-height: 1.4;
    text-align: right;
}
.header {
    border-bottom: 2px double #163f8f;
    padding-bottom: 12px;
    margin-bottom: 20px;
    direction: ltr;
}
.header-table {
    width: 100%;
    border-collapse: collapse;
}
.header-table td {
    border: none;
    padding: 0;
    vertical-align: top;
}
.header-right {
    text-align: right;
}
.header-left {
    text-align: left;
    color: #475569;
}
h1 { 
    margin: 0 0 6px; 
    font-size: 20px; 
    color: #163f8f;
}
.subtitle {
    font-size: 12px;
    color: #475569;
}
.stats { 
    width: 100%; 
    border-collapse: separate; 
    border-spacing: 10px; 
    margin-bottom: 22px; 
    direction: ltr;
}
.stats td { 
    background: #f8fafc; 
    border: 1px solid #e2e8f0; 
    border-radius: 12px; 
    padding: 12px; 
    text-align: center;
    width: 33.33%;
}
.label { 
    color: #64748b; 
    font-size: 10px; 
    font-weight: bold;
    margin-bottom: 4px;
}
.value { 
    font-size: 16px; 
    font-weight: 800; 
    color: #0f172a;
}
.value-highlight {
    color: #163f8f;
}
table.data { 
    width: 100%; 
    border-collapse: collapse; 
    margin-bottom: 30px;
    direction: ltr;
}
table.data th { 
    background: #f1f5f9; 
    color: #1e293b; 
    padding: 10px 8px; 
    font-weight: bold;
    border-bottom: 2px solid #cbd5e1;
    font-size: 11px;
}
table.data td { 
    border-bottom: 1px solid #e2e8f0; 
    padding: 9px 8px; 
    vertical-align: middle;
}
table.data tr:nth-child(even) td { 
    background: #f8fafc; 
}
.footer {
    margin-top: 40px;
    padding-top: 15px;
    direction: ltr;
}
.signature-table {
    width: 100%;
    border-collapse: collapse;
    margin-top: 20px;
}
.signature-table td {
    border: none;
    width: 50%;
    color: #334155;
    font-size: 11px;
}
</style>
</head>
<body>
  <div class="header">
    <table class="header-table">
      <tr>
        <!-- معلومات المستوى والقسم تظهر لليسار بصرياً فتوضع أولاً في كود الـ LTR -->
        <td class="header-left">
          <div><strong>{$ar('القسم / المستوى:')}</strong> {$ar($subject['major'])} - {$ar($subject['level'])}</div>
          <div style="margin-top: 4px;"><strong>{$ar('تاريخ التصدير:')}</strong> {$generatedAt}</div>
        </td>
        <!-- عنوان المادة والتقرير يظهر لليمين بصرياً فيوضع ثانياً في كود الـ LTR -->
        <td class="header-right">
          <h1>{$ar('تقرير رصد درجات الطلاب')}</h1>
          <div class="subtitle"><strong>{$ar('المادة:')}</strong> {$ar($subject['name'])}</div>
        </td>
      </tr>
    </table>
  </div>

  <table class="stats">
    <tr>
      <td>
        <div class="label">{$ar('إجمالي الطلاب')}</div>
        <div class="value">{$stats['students_count']}</div>
      </td>
      <td>
        <div class="label">{$ar('المتوسط العام')}</div>
        <div class="value value-highlight">{$stats['average']}</div>
      </td>
      <td>
        <div class="label">{$ar('نسبة النجاح')}</div>
        <div class="value" style="color: #137333;">{$stats['pass_rate']}%</div>
      </td>
    </tr>
    <tr>
      <td>
        <div class="label">{$ar('الدرجة الأعلى')}</div>
        <div class="value" style="color: #137333;">{$stats['highest']}</div>
      </td>
      <td>
        <div class="label">{$ar('الدرجة الأدنى')}</div>
        <div class="value" style="color: #c5221f;">{$stats['lowest']}</div>
      </td>
      <td>
        <div class="label">{$ar('ناجح / راسب')}</div>
        <div class="value">{$stats['passed']} / {$stats['failed']}</div>
      </td>
    </tr>
  </table>

  <table class="data">
    <thead>
      <!-- ترتيب عناوين الأعمدة معكوس برمجياً لتظهر من اليمين لليسار بصرياً -->
      <tr>
        <th style="width: 10%; text-align: center;">{$ar('الحالة')}</th>
        <th style="width: 11%; text-align: center;">{$ar('التقدير')}</th>
        <th style="width: 11%; text-align: center;">{$ar('المجموع')}</th>
        <th style="width: 11%; text-align: center;">{$ar('النهائي')}</th>
        <th style="width: 12%; text-align: center;">{$ar('أعمال السنة')}</th>
        <th style="width: 15%; text-align: center;">{$ar('رقم القيد')}</th>
        <th style="width: 32%; text-align: right;">{$ar('اسم الطالب')}</th>
        <th style="width: 8%; text-align: center;">{$ar('الترتيب')}</th>
      </tr>
    </thead>
    <tbody>{$rows}</tbody>
  </table>

  <div class="footer">
    <table class="signature-table">
      <tr>
        <!-- توقيع رئيس القسم يظهر يساراً فيوضع أولاً في كود الـ LTR -->
        <td class="header-left" style="text-align: left;">
          <strong>{$ar('اعتماد رئيس القسم:')}</strong> _______________________
        </td>
        <!-- توقيع أستاذ المادة يظهر يميناً فيوضع ثانياً في كود الـ LTR -->
        <td class="header-right" style="text-align: right;">
          <strong>{$ar('توقيع أستاذ المادة:')}</strong> _______________________
        </td>
      </tr>
    </table>
    <div style="text-align: center; margin-top: 35px; color: #94a3b8; font-size: 9px;">
      {$ar('تم توليد هذا التقرير آلياً بواسطة نظام معين لإدارة الكليات والدرجات')}
    </div>
  </div>
</body>
</html>
HTML;

        $pdf = Pdf::loadHTML($html)->setPaper('a4');
        return $pdf->download('grade_report_' . $subject['id'] . '.pdf');
    }

    private function buildReportData($id): array
    {
        $subject = Subject::where('doctor_id', Auth::id())->with(['major', 'level', 'gradeCategories'])->findOrFail($id);
        $hasCategories = $subject->gradeCategories->isNotEmpty();
        $totalMaxScore = $subject->gradeTotalMaxScore();
        $passingScore = $subject->gradePassingScore();

        $students = User::whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE, UserRole::PRACTICAL_DELEGATE])
            ->where('major_id', $subject->major_id)
            ->where('level_id', $subject->level_id)
            ->with(['grades' => fn ($query) => $query->where('subject_id', $subject->id)])
            ->orderBy('name')
            ->get();

        $studentsData = $students->map(function ($student) use ($hasCategories, $totalMaxScore, $passingScore) {
            $finalGrade = $student->grades->where('type', 'final')->where('status', 'approved')->first();
            $continuousGrades = $student->grades->where('type', 'continuous')->where('status', 'approved');
            if ($hasCategories) {
                $continuousGrades = $continuousGrades->whereNotNull('category_id');
            }
            $continuous = $continuousGrades->sum('score');
            $total = round((float) $continuous + (float) ($finalGrade?->score ?? 0), 2);

            return [
                'id' => $student->id,
                'name' => $student->name,
                'student_number' => $student->student_number,
                'continuous' => round((float) $continuous, 2),
                'final' => $finalGrade?->score,
                'total' => $total,
                'grade_label' => $this->gradeLabel($total, $totalMaxScore, $passingScore),
                'status' => $total >= $passingScore ? 'passed' : 'failed',
            ];
        })->sortByDesc('total')->values();

        $rankedStudents = $studentsData->map(function ($student, $index) {
            $student['rank'] = $index + 1;
            return $student;
        });

        $totals = $rankedStudents->pluck('total')->filter(fn ($value) => $value > 0);
        $passed = $totals->filter(fn ($value) => $value >= $passingScore)->count();
        $failed = $totals->count() - $passed;
        $percentage = fn ($value) => $totalMaxScore > 0 ? ((float) $value / $totalMaxScore) * 100 : 0;

        return [
            'subject' => [
                'id' => $subject->id,
                'name' => $subject->name,
                'major' => $subject->major?->name,
                'level' => $subject->level?->name,
                'grade_settings' => $subject->gradeSettingsPayload(),
            ],
            'stats' => [
                'total_students' => $students->count(),
                'students_count' => $students->count(),
                'graded' => $totals->count(),
                'average' => $totals->count() > 0 ? round($totals->avg(), 1) : 0,
                'highest' => $totals->max() ?? 0,
                'lowest' => $totals->min() ?? 0,
                'passed' => $passed,
                'failed' => $failed,
                'pass_rate' => $totals->count() > 0 ? round($passed / $totals->count() * 100) : 0,
                'distribution' => [
                    'excellent' => $totals->filter(fn ($value) => $percentage($value) >= 90)->count(),
                    'very_good' => $totals->filter(fn ($value) => $percentage($value) >= 80 && $percentage($value) < 90)->count(),
                    'good' => $totals->filter(fn ($value) => $percentage($value) >= 70 && $percentage($value) < 80)->count(),
                    'pass' => $totals->filter(fn ($value) => $value >= $passingScore && $percentage($value) < 70)->count(),
                    'fail' => $totals->filter(fn ($value) => $value < $passingScore)->count(),
                ],
            ],
            'students' => $rankedStudents,
        ];
    }

    private function gradeLabel(float|int $score, float|int $totalMaxScore = 100, float|int $passingScore = 50): string
    {
        $percentage = $totalMaxScore > 0 ? ((float) $score / (float) $totalMaxScore) * 100 : 0;

        if ($percentage >= 90) return 'ممتاز';
        if ($percentage >= 80) return 'جيد جدًا';
        if ($percentage >= 70) return 'جيد';
        if ($score >= $passingScore) return 'مقبول';
        return 'راسب';
    }

    /** POST /api/doctor/grades/{subject}/note/{student} */
    public function storeNote(Request $request, $subjectId, $studentId)
    {
        $subject = Subject::where('doctor_id', Auth::id())->findOrFail($subjectId);

        $request->validate(['note' => 'required|string|max:500']);

        StudentNote::create([
            'subject_id' => $subject->id,
            'student_id' => $studentId,
            'doctor_id' => Auth::id(),
            'note' => $request->note,
        ]);

        return $this->success(null, 'تم إرسال الملاحظة بنجاح.', 201);
    }
}
