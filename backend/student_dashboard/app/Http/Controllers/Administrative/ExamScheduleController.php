<?php

namespace App\Http\Controllers\Administrative;

use App\Http\Controllers\Controller;
use App\Models\Academic\Major;
use App\Models\Academic\Level;
use App\Models\Academic\Subject;
use App\Models\Academic\Term;
use App\Models\ExamSchedule;
use App\Models\ExamScheduleItem;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class ExamScheduleController extends Controller
{
    /**
     * Display a listing of the exam schedules in the admin's college.
     */
    public function index()
    {
        $collegeId = Auth::user()->college_id;

        $schedules = ExamSchedule::whereHas('major', function($q) use ($collegeId) {
                $q->where('college_id', $collegeId);
            })
            ->with(['major', 'level', 'term', 'creator'])
            ->latest()
            ->paginate(15);

        return view('administrative.exams.index', compact('schedules'));
    }

    /**
     * Show the form for creating a new exam schedule.
     */
    public function create()
    {
        $collegeId = Auth::user()->college_id;
        $majors = Major::where('college_id', $collegeId)->with('levels')->get();
        
        return view('administrative.exams.create', compact('majors'));
    }

    /**
     * Store a newly created exam schedule in storage.
     */
    public function store(Request $request)
    {
        $request->validate([
            'major_id' => 'required|exists:majors,id',
            'level_id' => 'required|exists:levels,id',
            'term_id' => 'required|exists:terms,id',
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'items' => 'required|array|min:1',
            'items.*.subject_id' => 'required|exists:subjects,id',
            'items.*.exam_date' => 'required|date',
            'items.*.start_time' => 'required',
            'items.*.end_time' => 'required|after:items.*.start_time',
            'items.*.location' => 'nullable|string|max:255',
        ]);

        $this->assertScheduleScope($request->all());

        try {
            DB::beginTransaction();

            $schedule = ExamSchedule::create([
                'major_id' => $request->major_id,
                'level_id' => $request->level_id,
                'term_id' => $request->term_id,
                'title' => $request->title,
                'description' => $request->description,
                'is_published' => $request->has('is_published'),
                'created_by' => Auth::id(),
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
            return redirect()->route('administrative.exams.index')->with('success', 'تم إنشاء جدول الاختبارات بنجاح.');
        } catch (\Exception $e) {
            DB::rollBack();
            return back()->with('error', 'حدث خطأ أثناء حفظ الجدول: ' . $e->getMessage())->withInput();
        }
    }

    /**
     * Show the form for editing the specified exam schedule.
     */
    public function edit(ExamSchedule $exam)
    {
        // Security check: ensure the schedule belongs to the admin's college
        $this->authorizeCollegeAccess($exam);

        $collegeId = Auth::user()->college_id;
        $majors = Major::where('college_id', $collegeId)->with('levels')->get();
        
        $exam->load('items');
        
        // Fetch subjects for the current major/level to populate the dropdowns
        $subjects = Subject::where('major_id', $exam->major_id)
            ->where('level_id', $exam->level_id)
            ->get();
            
        $terms = Term::where('level_id', $exam->level_id)->get();

        return view('administrative.exams.edit', compact('exam', 'majors', 'subjects', 'terms'));
    }

    /**
     * Display the specified exam schedule (Admin Preview).
     */
    public function show(ExamSchedule $exam)
    {
        $this->authorizeCollegeAccess($exam);
        
        $exam->load(['items.subject', 'major', 'level', 'term', 'creator']);
        
        // Wrap in a collection to reuse the student view logic which expects multiple schedules
        $schedules = collect([$exam]);
        
        return view('administrative.exams.show', compact('exam', 'schedules'));
    }

    /**
     * Update the specified exam schedule in storage.
     */
    public function update(Request $request, ExamSchedule $exam)
    {
        $this->authorizeCollegeAccess($exam);

        $request->validate([
            'major_id' => 'required|exists:majors,id',
            'level_id' => 'required|exists:levels,id',
            'term_id' => 'required|exists:terms,id',
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'items' => 'required|array|min:1',
            'items.*.subject_id' => 'required|exists:subjects,id',
            'items.*.exam_date' => 'required|date',
            'items.*.start_time' => 'required',
            'items.*.end_time' => 'required|after:items.*.start_time',
            'items.*.location' => 'nullable|string|max:255',
        ]);

        $this->assertScheduleScope($request->all());

        try {
            DB::beginTransaction();

            $exam->update([
                'major_id' => $request->major_id,
                'level_id' => $request->level_id,
                'term_id' => $request->term_id,
                'title' => $request->title,
                'description' => $request->description,
                'is_published' => $request->has('is_published'),
            ]);

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
            return redirect()->route('administrative.exams.index')->with('success', 'تم تحديث جدول الاختبارات بنجاح.');
        } catch (\Exception $e) {
            DB::rollBack();
            return back()->with('error', 'حدث خطأ أثناء تحديث الجدول: ' . $e->getMessage())->withInput();
        }
    }

    /**
     * Remove the specified exam schedule from storage.
     */
    public function destroy(ExamSchedule $exam)
    {
        $this->authorizeCollegeAccess($exam);
        $exam->delete();
        return back()->with('success', 'تم حذف جدول الاختبارات بنجاح.');
    }

    /**
     * Get levels for a major (API helper).
     */
    public function getLevels(Major $major)
    {
        if ($major->college_id !== Auth::user()->college_id) {
            return response()->json([], 403);
        }
        return response()->json($major->levels);
    }

    /**
     * Get subjects and terms for a level (API helper).
     */
    public function getSubjects(Level $level)
    {
        // Check if level belongs to the college via its major
        if ($level->major->college_id !== Auth::user()->college_id) {
            return response()->json([], 403);
        }

        $subjects = Subject::where('major_id', $level->major_id)
            ->where('level_id', $level->id)
            ->get();

        $terms = Term::where('level_id', $level->id)->get();

        return response()->json([
            'subjects' => $subjects,
            'terms' => $terms
        ]);
    }

    /**
     * Helper to authorize access to schedules within the admin's college.
     */
    private function authorizeCollegeAccess(ExamSchedule $exam)
    {
        if ($exam->major->college_id !== Auth::user()->college_id) {
            abort(403);
        }
    }

    private function assertScheduleScope(array $payload): void
    {
        $major = Major::findOrFail($payload['major_id']);
        $level = Level::with('major')->findOrFail($payload['level_id']);
        $term = Term::findOrFail($payload['term_id']);

        if ($major->college_id !== Auth::user()->college_id || $level->major->college_id !== Auth::user()->college_id) {
            abort(403);
        }

        if ((int) $level->major_id !== (int) $major->id) {
            abort(422, 'المستوى المحدد لا يتبع التخصص المحدد.');
        }

        if ((int) $term->level_id !== (int) $level->id) {
            abort(422, 'الترم المحدد لا يتبع المستوى المحدد.');
        }

        foreach ($payload['items'] ?? [] as $item) {
            $subject = Subject::findOrFail($item['subject_id']);
            if ((int) $subject->major_id !== (int) $major->id || (int) $subject->level_id !== (int) $level->id) {
                abort(422, 'إحدى المواد لا تنتمي إلى التخصص أو المستوى المحدد.');
            }
        }
    }
}
