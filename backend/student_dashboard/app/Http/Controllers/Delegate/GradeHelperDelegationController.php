<?php

namespace App\Http\Controllers\Delegate;

use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Models\DelegateGradeDelegation;
use App\Models\User;
use Illuminate\Http\Request;

class GradeHelperDelegationController extends Controller
{
    public function store(Request $request, int $categoryId)
    {
        $delegate = $request->user();

        $validated = $request->validate([
            'helper_user_id' => 'required|exists:users,id',
            'delegation_type' => 'required|in:full,partial',
            'title' => 'required|string|max:255',
            'notes' => 'nullable|string|max:1000',
            'due_at' => 'nullable|date',
            'student_ids' => 'nullable|array',
            'student_ids.*' => 'exists:users,id',
        ]);

        if ((int) $validated['helper_user_id'] === (int) $delegate->id) {
            return back()->withErrors(['helper_user_id' => 'لا يمكن إنشاء مهمة مساعدة لنفس حساب المندوب.'])->withInput();
        }

        $category = $delegate->delegatedGradeCategories()
            ->with(['subject:id,name,major_id,level_id', 'doctor:id,name'])
            ->findOrFail($categoryId);

        $eligibleIds = User::query()
            ->whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE, UserRole::PRACTICAL_DELEGATE])
            ->where('major_id', $category->subject->major_id)
            ->where('level_id', $category->subject->level_id)
            ->pluck('id');

        if (!$eligibleIds->contains((int) $validated['helper_user_id'])) {
            return back()->withErrors(['helper_user_id' => 'المستخدم المحدد خارج النطاق الأكاديمي المفوض.'])->withInput();
        }

        $existingTask = DelegateGradeDelegation::query()
            ->where('category_id', $category->id)
            ->where('delegated_by_id', $delegate->id)
            ->where('helper_user_id', $validated['helper_user_id'])
            ->where('is_revoked', false)
            ->exists();

        if ($existingTask) {
            return back()->withErrors(['helper_user_id' => 'توجد بالفعل مهمة مساعدة فعالة لهذا المستخدم على نفس الفئة.'])->withInput();
        }

        $selectedIds = collect($validated['student_ids'] ?? [])
            ->map(fn ($id) => (int) $id)
            ->unique()
            ->values();

        if ($validated['delegation_type'] === DelegateGradeDelegation::TYPE_PARTIAL) {
            if ($selectedIds->isEmpty() || $selectedIds->diff($eligibleIds)->isNotEmpty()) {
                return back()->withErrors(['student_ids' => 'الطلاب المحددون خارج النطاق الأكاديمي المفوض.'])->withInput();
            }
        }

        $task = DelegateGradeDelegation::create([
            'category_id' => $category->id,
            'delegated_by_id' => $delegate->id,
            'helper_user_id' => $validated['helper_user_id'],
            'delegation_type' => $validated['delegation_type'],
            'title' => $validated['title'],
            'notes' => $validated['notes'] ?? null,
            'due_at' => $validated['due_at'] ?? null,
        ]);

        if ($selectedIds->isNotEmpty()) {
            $task->students()->sync($selectedIds);
        }

        return back()->with('success', 'تم إنشاء مهمة المساعدة ورصدها ضمن التفويضات النشطة.');
    }

    public function revoke(Request $request, DelegateGradeDelegation $delegation)
    {
        if ((int) $delegation->delegated_by_id !== (int) $request->user()->id) {
            abort(403);
        }

        $delegation->update([
            'is_revoked' => true,
            'revoked_at' => now(),
        ]);

        return back()->with('success', 'تم سحب مهمة المساعدة بنجاح.');
    }
}
