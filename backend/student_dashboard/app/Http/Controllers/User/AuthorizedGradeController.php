<?php

namespace App\Http\Controllers\User;

use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Models\DelegateGradeDelegation;
use App\Models\Grade;
use App\Models\GradeCategory;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class AuthorizedGradeController extends Controller
{
    public function index()
    {
        $user = Auth::user();

        $directDelegations = $user->delegatedGradeCategories()
            ->with(['subject.major', 'subject.level', 'doctor'])
            ->get();

        $helperTasks = $user->delegatedGradeHelperTasks()
            ->active()
            ->with(['category.subject.major', 'category.subject.level', 'category.doctor', 'delegatedBy', 'helperUser', 'students'])
            ->get();

        return view('user.grades.authorized.index', compact('directDelegations', 'helperTasks'));
    }

    public function show($categoryId)
    {
        $user = Auth::user();

        [$category, $helperTask, $students] = $this->resolveCategoryAccess($user, (int) $categoryId);

        $delegateHelperCandidates = collect();
        $delegateHelperTasks = collect();
        $delegateHelperStudentScope = collect();

        if ($user->role === UserRole::DELEGATE && !$helperTask) {
            $delegateHelperCandidates = $this->eligibleStudentsQuery($category)
                ->where('id', '!=', $user->id)
                ->orderBy('name')
                ->get(['id', 'name', 'student_number', 'role']);

            $delegateHelperStudentScope = $this->eligibleStudentsQuery($category)
                ->orderBy('name')
                ->get(['id', 'name', 'student_number', 'role']);

            $delegateHelperTasks = $user->issuedGradeHelperTasks()
                ->active()
                ->where('category_id', $category->id)
                ->with(['helperUser', 'students'])
                ->latest()
                ->get();
        }

        $delegationContext = $this->buildDelegationContext($user, $category, $helperTask, $students);

        return view('user.grades.authorized.show', compact(
            'category',
            'students',
            'helperTask',
            'delegateHelperCandidates',
            'delegateHelperTasks',
            'delegateHelperStudentScope',
            'delegationContext'
        ));
    }

    public function store(Request $request, $categoryId)
    {
        $user = Auth::user();

        [$category, $helperTask, $students] = $this->resolveCategoryAccess($user, (int) $categoryId);
        $allowedStudentIds = $students->pluck('id');

        $request->validate([
            'grades' => 'required|array',
            'grades.*.student_id' => 'required|exists:users,id',
            'grades.*.score' => 'nullable|numeric|min:0|max:' . $category->max_score,
        ]);

        DB::beginTransaction();

        try {
            foreach ($request->grades as $gradeData) {
                if (!array_key_exists('score', $gradeData) || $gradeData['score'] === null || $gradeData['score'] === '') {
                    continue;
                }

                if (!$allowedStudentIds->contains((int) $gradeData['student_id'])) {
                    return back()->with('error', 'بعض الطلاب المحددين خارج نطاق التفويض المسموح لك.');
                }

                Grade::updateOrCreate(
                    [
                        'student_id' => $gradeData['student_id'],
                        'subject_id' => $category->subject_id,
                        'category_id' => $category->id,
                        'type' => 'continuous',
                    ],
                    [
                        'score' => $gradeData['score'],
                        'max_score' => $category->max_score,
                        'created_by' => $user->id,
                        'status' => 'pending',
                    ]
                );
            }

            DB::commit();
        } catch (\Throwable $exception) {
            DB::rollBack();

            return back()->with('error', 'حدث خطأ أثناء حفظ الدرجات.');
        }

        $redirectRoute = $user->role === UserRole::DELEGATE
            ? 'delegate.authorized-grades.index'
            : 'student.authorized-grades.index';

        return redirect()->route($redirectRoute)
            ->with('success', 'تم حفظ الدرجات وإرسالها إلى الدكتور للمراجعة والاعتماد.');
    }

    protected function resolveCategoryAccess(User $user, int $categoryId): array
    {
        $category = $user->delegatedGradeCategories()
            ->with(['subject.major', 'subject.level', 'doctor'])
            ->find($categoryId);

        $helperTask = null;

        if (!$category) {
            $helperTask = $user->delegatedGradeHelperTasks()
                ->active()
                ->with(['category.subject.major', 'category.subject.level', 'category.doctor', 'delegatedBy', 'students'])
                ->where('category_id', $categoryId)
                ->latest()
                ->firstOrFail();

            $category = $helperTask->category;
        }

        $students = $this->eligibleStudentsQuery($category)
            ->with(['grades' => function ($query) use ($category) {
                $query->where('category_id', $category->id);
            }])
            ->orderBy('name');

        if ($helperTask && $helperTask->delegation_type === DelegateGradeDelegation::TYPE_PARTIAL) {
            $students->whereIn('id', $helperTask->students->pluck('id'));
        }

        return [$category, $helperTask, $students->get(['users.id', 'users.name', 'users.student_number', 'users.role'])];
    }

    protected function eligibleStudentsQuery(GradeCategory $category)
    {
        $subject = $category->subject;

        return User::query()
            ->whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE, UserRole::PRACTICAL_DELEGATE])
            ->where('major_id', $subject->major_id)
            ->where('level_id', $subject->level_id);
    }

    protected function buildDelegationContext(User $user, GradeCategory $category, ?DelegateGradeDelegation $helperTask, $students): array
    {
        return [
            'access_mode' => $helperTask ? 'helper_task' : 'direct_delegation',
            'subject_name' => $category->subject->name,
            'major_name' => $category->subject->major?->name,
            'level_name' => $category->subject->level?->name,
            'doctor_name' => $category->doctor?->name,
            'can_delegate_helpers' => $user->role === UserRole::DELEGATE && !$helperTask,
            'student_scope_count' => $students->count(),
            'helper_task' => $helperTask,
            'scope_label' => $helperTask
                ? ($helperTask->delegation_type === DelegateGradeDelegation::TYPE_PARTIAL ? 'طلاب محددون فقط' : 'كل طلاب الفئة')
                : 'تفويض مباشر من الدكتور',
        ];
    }
}
