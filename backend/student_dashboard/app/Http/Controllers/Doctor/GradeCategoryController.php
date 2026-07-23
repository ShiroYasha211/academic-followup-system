<?php

namespace App\Http\Controllers\Doctor;

use App\Http\Controllers\Controller;
use App\Models\GradeCategory;
use App\Models\GradePermission;
use App\Models\StudentNotification;
use App\Models\Academic\Subject;
use App\Models\User;
use App\Enums\UserRole;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class GradeCategoryController extends Controller
{
    /**
     * Display a listing of categories (Breakdown marks).
     */
    public function index($subjectId)
    {
        $subject = Subject::where('doctor_id', Auth::id())->findOrFail($subjectId);
        
        $categories = GradeCategory::where('subject_id', $subjectId)->get();

        $totalMaxScore = $categories->sum('max_score');

        return view('doctor.grades.categories.index', compact('subject', 'categories', 'totalMaxScore'));
    }

    /**
     * Dedicated Delegation Center.
     */
    public function delegations($subjectId)
    {
        $subject = Subject::where('doctor_id', Auth::id())->findOrFail($subjectId);
        
        $categories = GradeCategory::where('subject_id', $subjectId)
            ->with(['permissions.authorizedUser'])
            ->get();

        $students = $this->eligibleUsersQuery($subject)
            ->orderBy('name')
            ->get();

        return view('doctor.grades.delegations.index', compact('subject', 'categories', 'students'));
    }

    /**
     * Store a new category.
     */
    public function store(Request $request, $subjectId)
    {
        $request->validate([
            'name' => 'required|string|max:100',
            'max_score' => 'required|numeric|min:0.5|max:40',
        ]);

        $subject = Subject::where('doctor_id', Auth::id())->findOrFail($subjectId);

        // Check if total max_score exceeds 40
        $currentTotal = GradeCategory::where('subject_id', $subjectId)->sum('max_score');
        if (($currentTotal + $request->max_score) > 40.01) { // 40.01 to handle float precision
            return back()->with('error', 'إجمالي درجات أعمال السنة لا يمكن أن يتجاوز 40 درجة.');
        }

        GradeCategory::create([
            'subject_id' => $subjectId,
            'doctor_id' => Auth::id(),
            'name' => $request->name,
            'max_score' => $request->max_score,
        ]);

        return back()->with('success', 'تم إضافة تصنيف الدرجات بنجاح.');
    }

    /**
     * Delegate a category to a student.
     */
    public function delegate(Request $request, $categoryId)
    {
        $category = GradeCategory::where('doctor_id', Auth::id())->findOrFail($categoryId);
        $subject = $category->subject;

        $validated = $request->validate([
            'authorized_user_id' => 'required|integer',
        ]);

        $authorizedUser = $this->eligibleUsersQuery($subject)
            ->whereKey($validated['authorized_user_id'])
            ->first();

        if (!$authorizedUser) {
            return back()->with('error', 'الطالب المحدد غير مؤهل للتفويض في هذه المادة.');
        }

        // Check if already delegated
        $exists = GradePermission::where('category_id', $categoryId)
            ->where('authorized_user_id', $authorizedUser->id)
            ->exists();

        if ($exists) {
            return back()->with('error', 'هذا الطالب مفوض بالفعل لهذا التصنيف.');
        }

        GradePermission::create([
            'category_id' => $categoryId,
            'authorized_user_id' => $authorizedUser->id,
        ]);

        $this->notifyGradeDelegation($category, $authorizedUser, false);

        return back()->with('success', 'تم تفويض الطالب بنجاح.');
    }

    /**
     * Revoke delegation.
     */
    public function revoke(Request $request, $categoryId)
    {
        $request->validate([
            'authorized_user_id' => 'required|exists:users,id',
        ]);

        $category = GradeCategory::where('doctor_id', Auth::id())->findOrFail($categoryId);
        $authorizedUser = User::findOrFail($request->authorized_user_id);

        $deleted = GradePermission::where('category_id', $categoryId)
            ->where('authorized_user_id', $request->authorized_user_id)
            ->delete();

        if ($deleted > 0) {
            $this->notifyGradeDelegation($category, $authorizedUser, true);
        }

        return back()->with('success', 'تم سحب التفويض بنجاح.');
    }

    /**
     * Remove a category.
     */
    public function destroy($categoryId)
    {
        $category = GradeCategory::where('doctor_id', Auth::id())->findOrFail($categoryId);
        
        // Check if category has grades already
        if ($category->grades()->exists()) {
            return back()->with('error', 'لا يمكن حذف هذا التصنيف لوجود درجات مسجلة عليه بالفعل.');
        }

        $category->delete();

        return back()->with('success', 'تم حذف التصنيف بنجاح.');
    }

    protected function eligibleUsersQuery(Subject $subject): Builder
    {
        return User::query()
            ->whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE, UserRole::PRACTICAL_DELEGATE])
            ->where('major_id', $subject->major_id)
            ->where('level_id', $subject->level_id);
    }

    protected function notifyGradeDelegation(GradeCategory $category, User $user, bool $revoked): void
    {
        $category->loadMissing('subject', 'doctor');

        StudentNotification::create([
            'user_id' => $user->id,
            'college_id' => $user->college_id,
            'sender_id' => Auth::id(),
            'type' => 'grade_delegation',
            'title' => $revoked ? 'تم سحب تفويض الدرجات' : 'تم تفويضك لرصد درجات',
            'message' => $revoked
                ? "تم سحب تفويض رصد درجات {$category->name} في مادة {$category->subject?->name}."
                : "فوضك الدكتور لرصد درجات {$category->name} في مادة {$category->subject?->name}.",
            'data' => [
                'category_id' => $category->id,
                'subject_id' => $category->subject_id,
                'doctor_id' => $category->doctor_id,
                'revoked' => $revoked,
                'screen' => 'authorized_grades',
                'target_screen' => 'authorized_grades',
            ],
        ]);
    }
}
