<?php

namespace App\Http\Controllers\Api\Admin\Clinical;

use App\Http\Controllers\Api\Admin\AdminApiController;
use App\Models\Clinical\EvaluationChecklist;
use App\Services\AdminEvaluationChecklistService;
use Illuminate\Http\Request;

class EvaluationChecklistController extends AdminApiController
{
    public function __construct(private AdminEvaluationChecklistService $checklistService)
    {
    }

    public function index(Request $request)
    {
        $query = EvaluationChecklist::whereNull('doctor_id')
            ->where('is_active', true)
            ->with('items');

        if ($request->filled('search')) {
            $query->where('title', 'like', '%' . $request->search . '%');
        }

        if ($request->filled('skill_type')) {
            $query->where('skill_type', $request->skill_type);
        }

        return $this->paginated($query->latest()->paginate($request->per_page ?? 15));
    }

    public function show($id)
    {
        $checklist = EvaluationChecklist::whereNull('doctor_id')
            ->where('is_active', true)
            ->with('items.subItems')
            ->findOrFail($id);
        return $this->success($checklist);
    }

    public function store(Request $request)
    {
        $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'skill_type' => 'required|in:history_taking,clinical_examination,procedure,communication',
            'time_limit_minutes' => 'nullable|integer|min:1',
            'is_practice_allowed' => 'boolean',
            'items' => 'required|array|min:1',
            'items.*.description' => 'required|string|max:500',
            'items.*.marks' => 'required|integer|min:1',
            'items.*.sub_items' => 'nullable|array',
        ]);

        $checklist = $this->checklistService->createStandard([
            'title' => $request->title,
            'description' => $request->description,
            'skill_type' => $request->skill_type,
            'time_limit_minutes' => $request->time_limit_minutes,
            'is_practice_allowed' => $request->input('is_practice_allowed', true),
            'items' => $request->items,
        ]);

        return $this->success($checklist->load('items.subItems'), 'تم إنشاء قائمة التقييم بنجاح.', 201);
    }

    public function update(Request $request, $id)
    {
        $checklist = EvaluationChecklist::whereNull('doctor_id')
            ->where('is_active', true)
            ->findOrFail($id);

        $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'skill_type' => 'required|in:history_taking,clinical_examination,procedure,communication',
            'time_limit_minutes' => 'nullable|integer|min:1',
            'is_practice_allowed' => 'boolean',
            'items' => 'required|array|min:1',
        ]);

        $result = $this->checklistService->updateStandard($checklist, [
            'title' => $request->title,
            'description' => $request->description,
            'skill_type' => $request->skill_type,
            'time_limit_minutes' => $request->time_limit_minutes,
            'is_practice_allowed' => $request->input('is_practice_allowed', $checklist->is_practice_allowed),
            'items' => $request->items,
        ]);

        $message = $result['versioned']
            ? 'تم إنشاء نسخة محدثة من قائمة التقييم مع حفظ النسخة القديمة للنتائج السابقة.'
            : 'تم تحديث قائمة التقييم بنجاح.';

        return $this->success($result['checklist']->load('items.subItems'), $message);
    }

    public function destroy($id)
    {
        $checklist = EvaluationChecklist::whereNull('doctor_id')
            ->where('is_active', true)
            ->findOrFail($id);

        $checklist->update(['is_active' => false]);

        return $this->success(null, 'تم أرشفة قائمة التقييم بنجاح.');
    }
}
