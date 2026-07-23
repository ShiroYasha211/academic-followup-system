<?php

namespace App\Http\Controllers\Delegate;

use App\Http\Controllers\Controller;
use App\Models\Academic\Subject;
use App\Models\Academic\Term;
use App\Models\ExamSchedule;
use App\Models\ExamScheduleItem;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Routing\Controllers\HasMiddleware;
use Illuminate\Routing\Controllers\Middleware;

class ExamScheduleController extends Controller implements HasMiddleware
{
    /**
     * Get the middleware that should be assigned to the controller.
     */
    public static function middleware(): array
    {
        return [
            new Middleware('delegate.permission:exams,create', only: ['create', 'store']),
            new Middleware('delegate.permission:exams,update', only: ['edit', 'update']),
            new Middleware('delegate.permission:exams,delete', only: ['destroy']),
        ];
    }

    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        $user = Auth::user();

        $schedules = ExamSchedule::where('major_id', $user->major_id)
            ->where('level_id', $user->level_id)
            ->with(['term', 'creator'])
            ->latest()
            ->paginate(10);

        // Data for Create Modal
        $subjects = Subject::where('major_id', $user->major_id)
            ->where('level_id', $user->level_id)
            ->get();

        $terms = Term::where('level_id', $user->level_id)
            ->get();

        return view('delegate.exams.index', compact('schedules', 'subjects', 'terms'));
    }

    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        $user = Auth::user();

        // Fetch subjects for the delegate's major and level
        $subjects = Subject::where('major_id', $user->major_id)
            ->where('level_id', $user->level_id)
            ->get();

        $terms = Term::where('level_id', $user->level_id)
            ->get();

        return view('delegate.exams.create', compact('subjects', 'terms'));
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $request->validate([
            'title' => 'required|string|max:255',
            'term_id' => 'required|exists:terms,id',
            'items' => 'required|array|min:1',
            'items.*.subject_id' => 'required|exists:subjects,id',
            'items.*.exam_date' => 'required|date',
            'items.*.start_time' => 'required',
            'items.*.end_time' => 'required|after:items.*.start_time',
            'items.*.location' => 'nullable|string|max:255',
        ]);

        $this->validateNoOverlap($request->items, $request->term_id, Auth::user());

        try {
            DB::beginTransaction();

            $user = Auth::user();

            $schedule = ExamSchedule::create([
                'major_id' => $user->major_id,
                'level_id' => $user->level_id,
                'term_id' => $request->term_id,
                'title' => $request->title,
                'description' => $request->description,
                'is_published' => $request->has('is_published'),
                'created_by' => $user->id,
            ]);

            foreach ($request->items as $item) {
                ExamScheduleItem::create([
                    'exam_schedule_id' => $schedule->id,
                    'subject_id' => $item['subject_id'],
                    'exam_date' => $item['exam_date'],
                    'start_time' => $item['start_time'],
                    'end_time' => $item['end_time'],
                    'location' => $item['location'] ?? null,
                ]);
            }

            DB::commit();
            return redirect()->route('delegate.exams.index')->with('success', 'تم إنشاء جدول الاختبارات بنجاح.');
        } catch (\Exception $e) {
            DB::rollBack();
            return back()->with('error', 'حدث خطأ أثناء حفظ الجدول: ' . $e->getMessage())->withInput();
        }
    }

    /**
     * Display the specified resource.
     */
    public function show(ExamSchedule $exam)
    {
        if ($exam->major_id !== Auth::user()->major_id || $exam->level_id !== Auth::user()->level_id) {
            abort(403);
        }

        $exam->load(['items.subject', 'term']);
        return view('delegate.exams.show', compact('exam'));
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(ExamSchedule $exam)
    {
        if ($exam->created_by !== Auth::id()) {
            abort(403);
        }

        $user = Auth::user();
        $subjects = Subject::where('major_id', $user->major_id)
            ->where('level_id', $user->level_id)
            ->get();

        $terms = Term::where('level_id', $user->level_id)
            ->get();

        $exam->load('items');

        return view('delegate.exams.edit', compact('exam', 'subjects', 'terms'));
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, ExamSchedule $exam)
    {
        if ($exam->created_by !== Auth::id()) {
            abort(403);
        }

        $request->validate([
            'title' => 'required|string|max:255',
            'term_id' => 'required|exists:terms,id',
            'items' => 'required|array|min:1',
            'items.*.subject_id' => 'required|exists:subjects,id',
            'items.*.exam_date' => 'required|date',
            'items.*.start_time' => 'required',
            'items.*.end_time' => 'required|after:items.*.start_time',
            'items.*.location' => 'nullable|string|max:255',
        ]);

        $this->validateNoOverlap($request->items, $request->term_id, Auth::user(), $exam->id);

        try {
            DB::beginTransaction();

            $exam->update([
                'term_id' => $request->term_id,
                'title' => $request->title,
                'description' => $request->description,
                'is_published' => $request->has('is_published'),
            ]);

            // Sync items: Delete all and recreate
            $exam->items()->delete();

            foreach ($request->items as $item) {
                ExamScheduleItem::create([
                    'exam_schedule_id' => $exam->id,
                    'subject_id' => $item['subject_id'],
                    'exam_date' => $item['exam_date'],
                    'start_time' => $item['start_time'],
                    'end_time' => $item['end_time'],
                    'location' => $item['location'] ?? null,
                ]);
            }

            DB::commit();
            return redirect()->route('delegate.exams.index')->with('success', 'تم تحديث جدول الاختبارات بنجاح.');
        } catch (\Exception $e) {
            DB::rollBack();
            return back()->with('error', 'حدث خطأ أثناء تحديث الجدول: ' . $e->getMessage())->withInput();
        }
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(ExamSchedule $exam)
    {
        if ($exam->created_by !== Auth::id()) {
            abort(403);
        }

        $exam->delete();
        return back()->with('success', 'تم حذف جدول الاختبارات بنجاح.');
    }

    /**
     * Validate that no exams overlap in date and time for the same major/level.
     */
    private function validateNoOverlap($items, $termId, $user, $ignoreScheduleId = null)
    {
        foreach ($items as $item) {
            $query = ExamScheduleItem::whereHas('schedule', function ($q) use ($user, $termId, $ignoreScheduleId) {
                $q->where('major_id', $user->major_id)
                    ->where('level_id', $user->level_id)
                    ->where('term_id', $termId);

                if ($ignoreScheduleId) {
                    $q->where('id', '!=', $ignoreScheduleId);
                }
            })
                ->where('exam_date', $item['exam_date'])
                ->where(function ($q) use ($item) {
                    // Check for time overlap
                    $q->whereBetween('start_time', [$item['start_time'], $item['end_time']])
                        ->orWhereBetween('end_time', [$item['start_time'], $item['end_time']])
                        ->orWhere(function ($subQ) use ($item) {
                            $subQ->where('start_time', '<=', $item['start_time'])
                                ->where('end_time', '>=', $item['end_time']);
                        });
                });

            if ($query->exists()) {
                $subject = Subject::find($item['subject_id']);
                abort(422, "يوجد تعارض في وقت الاختبار لمادة ({$subject->name}) في يوم {$item['exam_date']}. يرجى اختيار وقت آخر.");
            }
        }
    }
}
