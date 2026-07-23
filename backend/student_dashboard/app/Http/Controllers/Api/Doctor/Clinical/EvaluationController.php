<?php

namespace App\Http\Controllers\Api\Doctor\Clinical;

use App\Http\Controllers\Api\Doctor\DoctorApiController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use App\Models\Clinical\EvaluationChecklist;
use App\Models\Clinical\ChecklistItem;
use App\Models\Clinical\MockEvaluation;
use App\Models\Clinical\StudentEvaluation;
use App\Models\Clinical\EvaluationScore;
use App\Models\Clinical\BodySystem;
use App\Models\Clinical\ClinicalCase;
use App\Models\Academic\Major;
use App\Models\Academic\Level;
use App\Models\Academic\Subject;
use App\Models\User;
use App\Services\ClinicalEvaluationPortfolioExcelExporter;
use App\Services\ClinicalEvaluationPortfolioService;

class EvaluationController extends DoctorApiController
{
    /** GET /api/doctor/clinical/evaluations/checklists */
    public function checklists(Request $request)
    {
        $user = Auth::user();
        $hiddenIds = $user->hiddenChecklists()->pluck('evaluation_checklists.id')->toArray();

        $query = EvaluationChecklist::with('items')
            ->where('is_active', true)
            ->where(function ($query) use ($user, $hiddenIds) {
                $query->where(function ($q) use ($hiddenIds) {
                    $q->whereNull('doctor_id');
                    if (!empty($hiddenIds)) {
                        $q->whereNotIn('id', $hiddenIds);
                    }
                })->orWhere('doctor_id', $user->id);
            });

        if ($request->filled('skill_type')) {
            $query->where('skill_type', $request->skill_type);
        }

        $checklists = $query->latest()->paginate(15);
        $checklists->getCollection()->transform(fn ($checklist) => $this->serializeChecklist($checklist));

        return $this->success([
            'checklists' => $checklists->items(),
            'hidden_count' => count($hiddenIds),
            'pagination' => [
                'current_page' => $checklists->currentPage(),
                'last_page' => $checklists->lastPage(),
                'per_page' => $checklists->perPage(),
                'total' => $checklists->total(),
            ],
        ]);
    }

    /** GET /api/doctor/clinical/evaluations/checklists/hidden */
    public function hiddenChecklists(Request $request)
    {
        $user = Auth::user();

        $query = $user->hiddenChecklists()
            ->with('items')
            ->whereNull('evaluation_checklists.doctor_id')
            ->where('evaluation_checklists.is_active', true)
            ->orderBy('doctor_hidden_checklists.created_at', 'desc');

        if ($request->filled('skill_type')) {
            $query->where('evaluation_checklists.skill_type', $request->skill_type);
        }

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('evaluation_checklists.title', 'like', "%{$search}%")
                    ->orWhere('evaluation_checklists.description', 'like', "%{$search}%");
            });
        }

        $checklists = $query->paginate(15);
        $checklists->getCollection()->transform(fn ($checklist) => $this->serializeChecklist($checklist, true));

        return $this->success([
            'checklists' => $checklists->items(),
            'hidden_count' => $checklists->total(),
            'pagination' => [
                'current_page' => $checklists->currentPage(),
                'last_page' => $checklists->lastPage(),
                'per_page' => $checklists->perPage(),
                'total' => $checklists->total(),
            ],
        ]);
    }

    /** GET /api/doctor/clinical/evaluations/checklists/{id} */
    public function showChecklist($id)
    {
        $checklist = $this->findAccessibleChecklist($id);
        $data = $this->serializeChecklist($checklist);
        $data['items'] = $this->checklistItemsTree($checklist);

        return $this->success($data);
    }

    /** POST /api/doctor/clinical/evaluations/checklists */
    public function storeChecklist(Request $request)
    {
        $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'skill_type' => 'required|in:history_taking,clinical_examination,procedure,communication',
            'time_limit_minutes' => 'nullable|integer|min:1',
            'is_practice_allowed' => 'nullable|boolean',
            'tracks_admin_updates' => 'nullable|boolean',
            'items' => 'required|array|min:1',
            'items.*.description' => 'required|string|max:500',
            'items.*.marks' => 'required|integer|min:1|max:100',
            'items.*.sub_items' => 'nullable|array',
            'items.*.sub_items.*.description' => 'required_with:items.*.sub_items|string|max:500',
            'items.*.sub_items.*.marks' => 'required_with:items.*.sub_items|integer|min:1|max:100',
        ]);

        $totalMarks = 0;
        foreach ($request->items as $item) {
            $totalMarks += (int)$item['marks'];
            if (!empty($item['sub_items'])) {
                $subTotal = collect($item['sub_items'])->sum('marks');
                if ($subTotal !== (int)$item['marks']) {
                    return $this->error("مجموع درجات العناصر الفرعية يجب أن يساوي درجة العنصر الرئيسي '{$item['description']}' ({$item['marks']}).", 422);
                }
            }
        }

        $checklist = EvaluationChecklist::create([
            'title' => $request->title,
            'description' => $request->description,
            'doctor_id' => Auth::id(),
            'skill_type' => $request->skill_type,
            'time_limit_minutes' => $request->time_limit_minutes,
            'is_practice_allowed' => $request->boolean('is_practice_allowed'),
            'total_marks' => $totalMarks,
        ]);

        foreach ($request->items as $i => $item) {
            $mainItem = ChecklistItem::create([
                'checklist_id' => $checklist->id,
                'description' => $item['description'],
                'marks' => $item['marks'],
                'sort_order' => $i + 1,
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

        return $this->success($checklist->load('items'), 'تم إنشاء قائمة التقييم بنجاح.', 201);
    }

    /** PUT /api/doctor/clinical/evaluations/checklists/{id} */
    public function updateChecklist(Request $request, $id)
    {
        $user = Auth::user();
        $checklist = EvaluationChecklist::where(function ($q) use ($user) {
            $q->whereNull('doctor_id')->orWhere('doctor_id', $user->id);
        })->findOrFail($id);

        $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'skill_type' => 'required|in:history_taking,clinical_examination,procedure,communication',
            'time_limit_minutes' => 'nullable|integer|min:1',
            'is_practice_allowed' => 'nullable|boolean',
            'tracks_admin_updates' => 'nullable|boolean',
            'items' => 'required|array|min:1',
            'items.*.description' => 'required|string|max:500',
            'items.*.marks' => 'required|integer|min:1|max:100',
            'items.*.sub_items' => 'nullable|array',
            'items.*.sub_items.*.description' => 'required_with:items.*.sub_items|string|max:500',
            'items.*.sub_items.*.marks' => 'required_with:items.*.sub_items|integer|min:1|max:100',
        ]);

        $totalMarks = 0;
        foreach ($request->items as $item) {
            $totalMarks += (int)$item['marks'];
            if (!empty($item['sub_items'])) {
                $subTotal = collect($item['sub_items'])->sum('marks');
                if ($subTotal !== (int)$item['marks']) {
                    return $this->error("مجموع درجات العناصر الفرعية يجب أن يساوي درجة العنصر الرئيسي '{$item['description']}' ({$item['marks']}).", 422);
                }
            }
        }

        if (is_null($checklist->doctor_id)) {
            // Hide standard and create personal copy
            $user->hiddenChecklists()->syncWithoutDetaching([$checklist->id]);

            $newChecklist = EvaluationChecklist::create([
                'title' => $request->title,
                'description' => $request->description,
                'doctor_id' => $user->id,
                'source_checklist_id' => $checklist->source_checklist_id ?: $checklist->id,
                'synced_admin_checklist_id' => $checklist->id,
                'tracks_admin_updates' => $request->boolean('tracks_admin_updates', true),
                'skill_type' => $request->skill_type,
                'time_limit_minutes' => $request->time_limit_minutes,
                'is_practice_allowed' => $request->boolean('is_practice_allowed'),
                'tracks_admin_updates' => $request->boolean('tracks_admin_updates', $checklist->tracks_admin_updates),
                'total_marks' => $totalMarks,
            ]);

            foreach ($request->items as $i => $item) {
                $mainItem = ChecklistItem::create([
                    'checklist_id' => $newChecklist->id,
                    'description' => $item['description'],
                    'marks' => $item['marks'],
                    'sort_order' => $i + 1,
                ]);

                if (!empty($item['sub_items'])) {
                    foreach ($item['sub_items'] as $j => $subItem) {
                        ChecklistItem::create([
                            'checklist_id' => $newChecklist->id,
                            'parent_id' => $mainItem->id,
                            'description' => $subItem['description'],
                            'marks' => $subItem['marks'],
                            'sort_order' => $j + 1,
                        ]);
                    }
                }
            }

            return $this->success($newChecklist->load('items'), 'تم إنشاء نسخة مخصصة من القائمة الأساسية بنجاح.', 201);
        } else {
            $checklist->update([
                'title' => $request->title,
                'description' => $request->description,
                'skill_type' => $request->skill_type,
                'time_limit_minutes' => $request->time_limit_minutes,
                'is_practice_allowed' => $request->boolean('is_practice_allowed'),
                'total_marks' => $totalMarks,
            ]);

            $checklist->items()->delete();
        foreach ($request->items as $i => $item) {
            $mainItem = ChecklistItem::create([
                'checklist_id' => $checklist->id,
                'description' => $item['description'],
                'marks' => $item['marks'],
                'sort_order' => $i + 1,
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

        }
        return $this->success($checklist->load('items'), 'تم تحديث قائمة التقييم بنجاح.');
    }

    /** POST /api/doctor/clinical/evaluations/checklists/{id}/sync-admin-update */
    public function syncAdminChecklistUpdate($id)
    {
        $user = Auth::user();
        $checklist = EvaluationChecklist::with('items.subItems')
            ->where('doctor_id', $user->id)
            ->where('is_active', true)
            ->findOrFail($id);

        if (!$checklist->source_checklist_id || !$checklist->tracks_admin_updates) {
            return $this->error('هذه القائمة غير مرتبطة بتحديثات الأدمن.', 422);
        }

        $latestStandard = $this->latestStandardChecklistFor($checklist);
        if (!$this->hasNewerStandardChecklist($checklist, $latestStandard)) {
            return $this->success(
                $this->serializeChecklist($checklist->fresh('items.subItems')),
                'قائمتك محدثة بالفعل.'
            );
        }

        $updatedChecklist = DB::transaction(function () use ($checklist, $latestStandard) {
            if ($this->hasChecklistUsage($checklist)) {
                $checklist->update(['is_active' => false]);

                return $this->createDoctorChecklistFromStandard($latestStandard, $checklist);
            }

            $this->replaceDoctorChecklistWithStandard($checklist, $latestStandard);

            return $checklist->fresh('items.subItems');
        });

        return $this->success(
            $this->serializeChecklist($updatedChecklist),
            'تم تحديث قائمتك من نسخة الأدمن بنجاح.'
        );
    }

    /** DELETE /api/doctor/clinical/evaluations/checklists/{id} */
    public function destroyChecklist($id)
    {
        $user = Auth::user();
        $checklist = EvaluationChecklist::where(function ($q) use ($user) {
            $q->whereNull('doctor_id')->orWhere('doctor_id', $user->id);
        })->findOrFail($id);

        if (is_null($checklist->doctor_id)) {
            $user->hiddenChecklists()->syncWithoutDetaching([$checklist->id]);
            return $this->success(null, 'تم إخفاء القائمة الأساسية من مساحتك.');
        } else {
            $checklist->items()->delete();
            $checklist->delete();
            return $this->success(null, 'تم حذف قائمة التقييم بنجاح.');
        }
    }

    public function restoreDefaults()
    {
        Auth::user()->hiddenChecklists()->detach();
        return $this->success(null, 'تم استرداد قوائم التقييم الأساسية بنجاح.');
    }

    /** POST /api/doctor/clinical/evaluations/checklists/{id}/restore */
    public function restoreChecklist($id)
    {
        $user = Auth::user();
        $checklist = $user->hiddenChecklists()
            ->with('items')
            ->where('evaluation_checklists.id', $id)
            ->whereNull('evaluation_checklists.doctor_id')
            ->first();

        if (!$checklist) {
            return $this->error('قائمة التقييم غير مخفية أو لا يمكن استرجاعها.', 404);
        }

        $user->hiddenChecklists()->detach($checklist->id);

        return $this->success(
            $this->serializeChecklist($checklist),
            'تم استرجاع قائمة التقييم بنجاح.'
        );
    }

    /** GET /api/doctor/clinical/evaluations/start-data */
    public function startData()
    {
        $doctorId = Auth::id();
        $hiddenIds = Auth::user()->hiddenChecklists()->pluck('evaluation_checklists.id')->toArray();

        $checklists = EvaluationChecklist::with('items')
            ->where('is_active', true)
            ->where(function ($query) use ($doctorId, $hiddenIds) {
                $query->whereNull('doctor_id')
                    ->when(!empty($hiddenIds), function ($hiddenQuery) use ($hiddenIds) {
                        $hiddenQuery->whereNotIn('id', $hiddenIds);
                    })
                    ->orWhere('doctor_id', $doctorId);
            })
            ->latest()
            ->get()
            ->map(fn (EvaluationChecklist $checklist) => $this->serializeChecklist($checklist))
            ->values();

        $students = User::with(['major:id,name', 'level:id,name'])
            ->inDoctorClinicalScope($doctorId)
            ->orderBy('name')
            ->limit(25)
            ->get(['id', 'name', 'student_number', 'major_id', 'level_id', 'role']);

        $doctorSubjects = Subject::where('doctor_id', $doctorId)
            ->select('major_id', 'level_id')
            ->distinct()
            ->get();
        $majorIds = $doctorSubjects->pluck('major_id')->filter()->unique()->values();
        $levelIds = $doctorSubjects->pluck('level_id')->filter()->unique()->values();

        $bodySystems = BodySystem::all(['id', 'name']);
        $cases = ClinicalCase::with(['trainingCenter:id,name', 'clinicalDepartment:id,name', 'bodySystem:id,name'])
            ->where('doctor_id', $doctorId)
            ->where('status', 'active')
            ->latest()
            ->limit(50)
            ->get(['id', 'patient_name', 'diagnosis_or_description', 'training_center_id', 'clinical_department_id', 'body_system_id']);

        return $this->success([
            'checklists' => $checklists,
            'students' => $students,
            'majors' => Major::whereIn('id', $majorIds)->orderBy('name')->get(['id', 'name']),
            'levels' => Level::whereIn('id', $levelIds)->orderBy('name')->get(['id', 'name', 'major_id']),
            'body_systems' => $bodySystems,
            'cases' => $cases->map(fn (ClinicalCase $case) => [
                'id' => $case->id,
                'patient_name' => $case->patient_name,
                'diagnosis_or_description' => $case->diagnosis_or_description,
                'diagnosis' => $case->diagnosis_or_description,
                'body_system_id' => $case->body_system_id,
                'training_center' => $case->trainingCenter,
                'clinical_department' => $case->clinicalDepartment,
                'body_system' => $case->bodySystem,
            ])->values(),
        ]);
    }

    /** GET /api/doctor/clinical/evaluations/students */
    public function students(Request $request)
    {
        $doctorId = Auth::id();
        $query = User::with(['major:id,name', 'level:id,name'])
            ->inDoctorClinicalScope($doctorId)
            ->when($request->filled('search'), function ($q) use ($request) {
                $search = $request->search;
                $q->where(function ($searchQuery) use ($search) {
                    $searchQuery->where('name', 'like', "%{$search}%")
                        ->orWhere('student_number', 'like', "%{$search}%")
                        ->orWhere('email', 'like', "%{$search}%");
                });
            })
            ->when($request->filled('major_id'), fn ($q) => $q->where('major_id', $request->major_id))
            ->when($request->filled('level_id'), fn ($q) => $q->where('level_id', $request->level_id))
            ->orderBy('name');

        $students = $query->paginate((int) $request->input('per_page', 25));

        return $this->success([
            'students' => $students->items(),
            'pagination' => [
                'current_page' => $students->currentPage(),
                'last_page' => $students->lastPage(),
                'per_page' => $students->perPage(),
                'total' => $students->total(),
            ],
        ]);
    }

    /** GET /api/doctor/clinical/evaluations/checklists/{id}/take */
    public function takeChecklist($id)
    {
        $checklist = $this->findAccessibleChecklist($id);

        return $this->success([
            'checklist' => $this->serializeChecklist($checklist->load('items.subItems')),
            'items_tree' => $this->checklistItemsTree($checklist),
        ]);
    }

    /** POST /api/doctor/clinical/evaluations/submit */
    public function submit(Request $request)
    {
        $request->validate([
            'checklist_id' => 'required|exists:evaluation_checklists,id',
            'student_id' => 'required|exists:users,id',
            'body_system_id' => 'nullable|exists:body_systems,id',
            'procedure_type' => 'nullable|string',
            'clinical_case_id' => 'nullable|exists:clinical_cases,id',
            'timer_type' => 'nullable|in:fixed,open,custom',
            'time_limit_seconds' => 'nullable|integer|min:0',
            'time_taken_seconds' => 'nullable|integer|min:0',
            'scores' => 'required|array',
            'scores.*.score' => 'required|in:done,partial,not_done',
            'scores.*.note' => 'nullable|string|max:1000',
            'doctor_feedback' => 'nullable|string',
        ]);

        $doctorId = Auth::id();
        $checklist = $this->findAccessibleChecklist($request->checklist_id)->load('items.subItems');

        $studentExists = User::inDoctorClinicalScope($doctorId)
            ->where('id', $request->student_id)
            ->exists();
        if (!$studentExists) {
            return $this->error('الطالب خارج نطاقك السريري ولا يمكن تقييمه.', 403);
        }

        if ($request->filled('clinical_case_id')) {
            $caseExists = ClinicalCase::where('doctor_id', $doctorId)
                ->where('status', 'active')
                ->where('id', $request->clinical_case_id)
                ->exists();
            if (!$caseExists) {
                return $this->error('الحالة السريرية غير متاحة لهذا التقييم.', 403);
            }
        }

        // Calculate total score
        $totalObtained = 0;
        $scoreableItems = $this->scoreableItems($checklist);
        $totalMax = $scoreableItems->sum('marks');

        foreach ($scoreableItems as $item) {
            $scoreValue = $request->scores[$item->id]['score'] ?? 'not_done';
            $marks = match ($scoreValue) {
                'done' => $item->marks,
                'partial' => round($item->marks / 2),
                default => 0,
            };
            $totalObtained += $marks;
        }

        $percentage = $totalMax > 0 ? round(($totalObtained / $totalMax) * 100) : 0;
        $grade = match (true) {
            $percentage >= 90 => 'excellent',
            $percentage >= 75 => 'good',
            $percentage >= 60 => 'acceptable',
            $percentage >= 50 => 'weak',
            default => 'fail',
        };

        $evaluation = StudentEvaluation::create([
            'checklist_id' => $checklist->id,
            'student_id' => $request->student_id,
            'doctor_id' => Auth::id(),
            'body_system_id' => $request->body_system_id,
            'procedure_type' => $request->procedure_type,
            'clinical_case_id' => $request->clinical_case_id,
            'timer_type' => $request->timer_type ?? 'fixed',
            'time_limit_seconds' => $request->time_limit_seconds,
            'time_taken_seconds' => $request->time_taken_seconds ?? 0,
            'max_score' => $totalMax,
            'total_score' => $totalObtained,
            'percentage' => $percentage,
            'grade' => $grade,
            'doctor_feedback' => $request->doctor_feedback,
        ]);

        // Save individual scores
        foreach ($scoreableItems as $item) {
            $scoreValue = $request->scores[$item->id]['score'] ?? 'not_done';
            $marks = match ($scoreValue) {
                'done' => $item->marks,
                'partial' => round($item->marks / 2),
                default => 0,
            };

            EvaluationScore::create([
                'evaluation_id' => $evaluation->id,
                'checklist_item_id' => $item->id,
                'score' => $scoreValue,
                'marks_obtained' => $marks,
                'note' => $request->scores[$item->id]['note'] ?? null,
            ]);
        }

        return $this->success([
            'evaluation_id' => $evaluation->id,
            'obtained_marks' => $totalObtained,
            'total_marks' => $totalMax,
            'percentage' => $percentage,
            'grade' => $grade,
        ], 'تم حفظ نتيجة التقييم بنجاح.');
    }

    /** GET /api/doctor/clinical/evaluations/results */
    public function portfolioStudents(
        Request $request,
        ClinicalEvaluationPortfolioService $service
    ) {
        $students = $service->studentsForDoctor(Auth::user(), $request);

        return $this->success([
            'students' => $students->items(),
            'filters' => $service->filtersForDoctor(Auth::user()),
            'pagination' => [
                'current_page' => $students->currentPage(),
                'last_page' => $students->lastPage(),
                'per_page' => $students->perPage(),
                'total' => $students->total(),
            ],
        ]);
    }

    public function portfolioShow(
        Request $request,
        User $student,
        ClinicalEvaluationPortfolioService $service
    ) {
        return $this->success(
            $service->portfolioForDoctor(Auth::user(), $student, $request)
        );
    }

    public function portfolioExcel(
        Request $request,
        User $student,
        ClinicalEvaluationPortfolioService $service,
        ClinicalEvaluationPortfolioExcelExporter $exporter
    ) {
        return $exporter->download(
            $service->portfolioForDoctor(Auth::user(), $student, $request)
        );
    }

    public function results(Request $request)
    {
        $baseQuery = StudentEvaluation::where('doctor_id', Auth::id());

        $filters = [
            'students' => User::query()
                ->whereIn('id', (clone $baseQuery)->select('student_id'))
                ->orderBy('name')
                ->get(['id', 'name', 'student_number']),
            'checklists' => EvaluationChecklist::query()
                ->whereIn('id', (clone $baseQuery)->select('checklist_id'))
                ->orderBy('title')
                ->get(['id', 'title', 'skill_type']),
        ];

        $query = StudentEvaluation::with(['student:id,name,student_number', 'checklist:id,title,skill_type'])
            ->where('doctor_id', Auth::id());

        if ($request->filled('checklist_id')) {
            $query->where('checklist_id', $request->checklist_id);
        }
        if ($request->filled('student_id')) {
            $query->where('student_id', $request->student_id);
        }
        if ($request->filled('grade')) {
            $query->where('grade', $request->grade);
        }

        $statsQuery = clone $query;
        $count = (clone $statsQuery)->count();
        $average = $count > 0 ? round((clone $statsQuery)->avg('percentage'), 1) : 0;
        $passed = (clone $statsQuery)
            ->whereIn('grade', ['excellent', 'good', 'acceptable'])
            ->count();
        $failed = max(0, $count - $passed);
        $averageTime = $count > 0 ? round((clone $statsQuery)->avg('time_taken_seconds')) : 0;

        $paginator = $query->latest()->paginate(20);
        $items = collect($paginator->items())
            ->map(fn ($evaluation) => $this->serializeEvaluationSummary($evaluation))
            ->values();

        return response()->json([
            'success' => true,
            'message' => 'تم جلب نتائج التقييم بنجاح',
            'data' => $items,
            'stats' => [
                'total' => $count,
                'average_percentage' => $average,
                'passed' => $passed,
                'failed' => $failed,
                'average_time_seconds' => $averageTime,
            ],
            'filters' => $filters,
            'pagination' => [
                'current_page' => $paginator->currentPage(),
                'last_page' => $paginator->lastPage(),
                'per_page' => $paginator->perPage(),
                'total' => $paginator->total(),
            ],
        ]);
    }

    /** GET /api/doctor/clinical/evaluations/results/{id} */
    public function showResult($id)
    {
        $evaluation = StudentEvaluation::with([
            'student:id,name,student_number',
            'checklist.items.subItems',
            'scores.checklistItem',
        ])->where('doctor_id', Auth::id())->findOrFail($id);

        return $this->success($this->serializeEvaluationDetails($evaluation));
    }

    private function findAccessibleChecklist($id): EvaluationChecklist
    {
        $user = Auth::user();
        $hiddenIds = $user->hiddenChecklists()->pluck('evaluation_checklists.id')->toArray();

        return EvaluationChecklist::with('items.subItems')
            ->where('id', $id)
            ->where('is_active', true)
            ->where(function ($query) use ($user, $hiddenIds) {
                $query->where(function ($standard) use ($hiddenIds) {
                    $standard->whereNull('doctor_id');
                    if (!empty($hiddenIds)) {
                        $standard->whereNotIn('id', $hiddenIds);
                    }
                })->orWhere('doctor_id', $user->id);
            })
            ->firstOrFail();
    }

    private function scoreableItems(EvaluationChecklist $checklist)
    {
        $items = $checklist->items;
        $leaves = $items->filter(fn ($item) => $item->subItems->isEmpty());

        return $leaves->isNotEmpty() ? $leaves : $items;
    }

    private function checklistItemsTree(EvaluationChecklist $checklist): array
    {
        return $checklist->items
            ->whereNull('parent_id')
            ->values()
            ->map(function ($item) {
                return [
                    'id' => $item->id,
                    'description' => $item->description,
                    'marks' => $item->marks,
                    'sort_order' => $item->sort_order,
                    'sub_items' => $item->subItems->values()->map(fn ($subItem) => [
                        'id' => $subItem->id,
                        'parent_id' => $subItem->parent_id,
                        'description' => $subItem->description,
                        'marks' => $subItem->marks,
                        'sort_order' => $subItem->sort_order,
                    ])->all(),
                ];
            })
            ->all();
    }

    private function serializeEvaluationSummary(StudentEvaluation $evaluation): array
    {
        return [
            'id' => $evaluation->id,
            'student' => $evaluation->student,
            'checklist' => $evaluation->checklist ? [
                'id' => $evaluation->checklist->id,
                'title' => $evaluation->checklist->title,
                'skill_type' => $evaluation->checklist->skill_type,
            ] : null,
            'total_score' => $evaluation->total_score,
            'max_score' => $evaluation->max_score,
            'percentage' => (float) $evaluation->percentage,
            'grade' => $evaluation->grade,
            'grade_label' => $this->evaluationGradeLabel($evaluation->grade),
            'grade_color' => $this->evaluationGradeColor($evaluation->grade),
            'timer_type' => $evaluation->timer_type,
            'time_limit_seconds' => $evaluation->time_limit_seconds,
            'time_taken_seconds' => $evaluation->time_taken_seconds,
            'formatted_time' => $this->formatSeconds($evaluation->time_taken_seconds),
            'doctor_feedback' => $evaluation->doctor_feedback,
            'created_at' => $evaluation->created_at,
        ];
    }

    private function serializeEvaluationDetails(StudentEvaluation $evaluation): array
    {
        $scores = $evaluation->scores->mapWithKeys(function ($score) {
            return [
                $score->checklist_item_id => [
                    'id' => $score->id,
                    'checklist_item_id' => $score->checklist_item_id,
                    'score' => $score->score,
                    'score_label' => $this->scoreLabel($score->score),
                    'marks_obtained' => $score->marks_obtained,
                    'note' => $score->note,
                    'checklist_item' => $score->checklistItem,
                ],
            ];
        });

        $done = $evaluation->scores->where('score', 'done')->count();
        $partial = $evaluation->scores->where('score', 'partial')->count();
        $notDone = $evaluation->scores->where('score', 'not_done')->count();
        $weaknesses = $evaluation->scores
            ->whereIn('score', ['partial', 'not_done'])
            ->values()
            ->map(fn ($score) => [
                'description' => optional($score->checklistItem)->description,
                'score' => $score->score,
                'score_label' => $this->scoreLabel($score->score),
                'marks_obtained' => $score->marks_obtained,
                'max_marks' => optional($score->checklistItem)->marks,
                'note' => $score->note,
            ]);

        $data = $this->serializeEvaluationSummary($evaluation);
        $data['scores'] = $evaluation->scores->map(fn ($score) => [
            'id' => $score->id,
            'checklist_item_id' => $score->checklist_item_id,
            'score' => $score->score,
            'score_label' => $this->scoreLabel($score->score),
            'marks_obtained' => $score->marks_obtained,
            'note' => $score->note,
            'checklist_item' => $score->checklistItem,
        ])->values();
        $data['scores_by_item'] = $scores;
        $data['status_counts'] = [
            'done' => $done,
            'partial' => $partial,
            'not_done' => $notDone,
            'total' => $done + $partial + $notDone,
        ];
        $data['weaknesses'] = $weaknesses;
        $data['checklist'] = $evaluation->checklist ? [
            'id' => $evaluation->checklist->id,
            'title' => $evaluation->checklist->title,
            'description' => $evaluation->checklist->description,
            'skill_type' => $evaluation->checklist->skill_type,
            'time_limit_minutes' => $evaluation->checklist->time_limit_minutes,
            'total_marks' => $evaluation->checklist->total_marks,
            'items' => $this->checklistItemsTree($evaluation->checklist),
        ] : null;

        return $data;
    }

    private function evaluationGradeLabel(?string $grade): string
    {
        return match ($grade) {
            'excellent' => 'ممتاز',
            'good' => 'جيد جدا',
            'acceptable' => 'مقبول',
            'weak' => 'ضعيف',
            'fail' => 'راسب',
            default => '-',
        };
    }

    private function evaluationGradeColor(?string $grade): string
    {
        return match ($grade) {
            'excellent' => '#059669',
            'good' => '#2563eb',
            'acceptable' => '#d97706',
            'weak' => '#dc2626',
            'fail' => '#991b1b',
            default => '#64748b',
        };
    }

    private function scoreLabel(?string $score): string
    {
        return match ($score) {
            'done' => 'تم بالكامل',
            'partial' => 'تم جزئيا',
            'not_done' => 'لم يتم',
            default => '-',
        };
    }

    private function formatSeconds(?int $seconds): string
    {
        if (!$seconds || $seconds < 1) {
            return '-';
        }
        $minutes = floor($seconds / 60);
        $remaining = $seconds % 60;

        return sprintf('%d:%02d', $minutes, $remaining);
    }

    private function serializeChecklist(EvaluationChecklist $checklist, bool $isHidden = false): array
    {
        $latestStandard = $this->latestStandardChecklistFor($checklist);

        return [
            'id' => $checklist->id,
            'title' => $checklist->title,
            'description' => $checklist->description,
            'doctor_id' => $checklist->doctor_id,
            'source_checklist_id' => $checklist->source_checklist_id,
            'synced_admin_checklist_id' => $checklist->synced_admin_checklist_id,
            'tracks_admin_updates' => (bool) $checklist->tracks_admin_updates,
            'skill_type' => $checklist->skill_type,
            'time_limit_minutes' => $checklist->time_limit_minutes,
            'is_practice_allowed' => (bool) $checklist->is_practice_allowed,
            'total_marks' => $checklist->total_marks,
            'is_active' => (bool) $checklist->is_active,
            'is_standard' => is_null($checklist->doctor_id),
            'is_hidden' => $isHidden,
            'has_admin_update' => $this->hasNewerStandardChecklist($checklist, $latestStandard),
            'latest_standard_checklist' => $latestStandard ? [
                'id' => $latestStandard->id,
                'title' => $latestStandard->title,
                'updated_at' => $latestStandard->updated_at,
            ] : null,
            'items' => $checklist->relationLoaded('items') ? $checklist->items : [],
            'created_at' => $checklist->created_at,
            'updated_at' => $checklist->updated_at,
        ];
    }

    private function latestStandardChecklistFor(EvaluationChecklist $checklist): ?EvaluationChecklist
    {
        if (
            is_null($checklist->doctor_id) ||
            is_null($checklist->source_checklist_id) ||
            !$checklist->tracks_admin_updates
        ) {
            return null;
        }

        $sourceId = (int) $checklist->source_checklist_id;

        return EvaluationChecklist::query()
            ->with('items.subItems')
            ->whereNull('doctor_id')
            ->where('is_active', true)
            ->where(function ($query) use ($sourceId) {
                $query->where('id', $sourceId)
                    ->orWhere('source_checklist_id', $sourceId);
            })
            ->latest('updated_at')
            ->latest('id')
            ->first();
    }

    private function hasNewerStandardChecklist(EvaluationChecklist $checklist, ?EvaluationChecklist $latestStandard): bool
    {
        if (!$latestStandard) {
            return false;
        }

        $syncedAdminId = (int) ($checklist->synced_admin_checklist_id ?: $checklist->source_checklist_id);

        if ((int) $latestStandard->id !== $syncedAdminId) {
            return true;
        }

        return $latestStandard->updated_at && $checklist->updated_at
            ? $latestStandard->updated_at->gt($checklist->updated_at)
            : false;
    }

    private function hasChecklistUsage(EvaluationChecklist $checklist): bool
    {
        return StudentEvaluation::where('checklist_id', $checklist->id)->exists()
            || MockEvaluation::where('checklist_id', $checklist->id)->exists();
    }

    private function createDoctorChecklistFromStandard(
        EvaluationChecklist $standard,
        EvaluationChecklist $previous
    ): EvaluationChecklist {
        $newChecklist = EvaluationChecklist::create([
            'title' => $standard->title,
            'description' => $standard->description,
            'doctor_id' => $previous->doctor_id,
            'source_checklist_id' => $previous->source_checklist_id,
            'synced_admin_checklist_id' => $standard->id,
            'tracks_admin_updates' => $previous->tracks_admin_updates,
            'skill_type' => $standard->skill_type,
            'time_limit_minutes' => $standard->time_limit_minutes,
            'is_practice_allowed' => $standard->is_practice_allowed,
            'total_marks' => $standard->total_marks,
            'is_active' => true,
        ]);

        $this->copyChecklistItems($standard, $newChecklist);

        return $newChecklist->load('items.subItems');
    }

    private function replaceDoctorChecklistWithStandard(
        EvaluationChecklist $checklist,
        EvaluationChecklist $standard
    ): void {
        $checklist->update([
            'title' => $standard->title,
            'description' => $standard->description,
            'synced_admin_checklist_id' => $standard->id,
            'skill_type' => $standard->skill_type,
            'time_limit_minutes' => $standard->time_limit_minutes,
            'is_practice_allowed' => $standard->is_practice_allowed,
            'total_marks' => $standard->total_marks,
            'is_active' => true,
        ]);

        $checklist->items()->delete();
        $this->copyChecklistItems($standard, $checklist);
    }

    private function copyChecklistItems(EvaluationChecklist $source, EvaluationChecklist $target): void
    {
        $source->loadMissing('items.subItems');

        foreach ($source->items->whereNull('parent_id')->values() as $i => $item) {
            $mainItem = ChecklistItem::create([
                'checklist_id' => $target->id,
                'description' => $item->description,
                'marks' => $item->marks,
                'sort_order' => $i + 1,
            ]);

            foreach ($item->subItems as $j => $subItem) {
                ChecklistItem::create([
                    'checklist_id' => $target->id,
                    'parent_id' => $mainItem->id,
                    'description' => $subItem->description,
                    'marks' => $subItem->marks,
                    'sort_order' => $j + 1,
                ]);
            }
        }
    }
}
