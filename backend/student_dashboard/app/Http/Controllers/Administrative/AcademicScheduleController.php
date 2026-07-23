<?php

namespace App\Http\Controllers\Administrative;

use App\Http\Controllers\Controller;
use App\Models\Academic\Major;
use App\Models\Academic\Level;
use App\Models\Academic\Subject;
use App\Models\Academic\Schedule;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class AcademicScheduleController extends Controller
{
    /**
     * Display a listing of schedules.
     */
    public function index()
    {
        $collegeId = Auth::user()->college_id;

        $schedules = Schedule::whereHas('subject.major', function($q) use ($collegeId) {
                $q->where('college_id', $collegeId);
            })
            ->with(['subject.major', 'subject.level', 'subject.doctor', 'creator'])
            ->latest()
            ->paginate(15);

        return view('administrative.schedules.index', compact('schedules'));
    }

    public function show(Schedule $schedule)
    {
        $this->authorizeCollegeAccess($schedule->subject->major);

        $majorId = $schedule->subject->major_id;
        $levelId = $schedule->subject->level_id;

        $schedules = Schedule::whereHas('subject', function($q) use ($majorId, $levelId) {
                $q->where('major_id', $majorId)->where('level_id', $levelId);
            })
            ->with(['subject.doctor', 'creator'])
            ->get();

        $major = $schedule->subject->major;
        $level = $schedule->subject->level;

        return view('administrative.schedules.show', compact('schedules', 'major', 'level'));
    }

    /**
     * Show the form for creating a new schedule.
     */
    public function create()
    {
        $collegeId = Auth::user()->college_id;
        $majors = Major::where('college_id', $collegeId)->with('levels')->get();
        
        return view('administrative.schedules.create', compact('majors'));
    }

    /**
     * Store a newly created schedule in storage.
     */
    public function store(Request $request)
    {
        $request->validate([
            'subject_id' => 'required|exists:subjects,id',
            'day_of_week' => 'required|integer|between:1,7',
            'start_time' => 'required',
            'end_time' => 'required|after:start_time',
            'hall_name' => 'nullable|string|max:255',
        ]);

        $subject = Subject::findOrFail($request->subject_id);
        
        // Security check
        if ($subject->major->college_id !== Auth::user()->college_id) {
            abort(403);
        }

        Schedule::create([
            'subject_id' => $request->subject_id,
            'day_of_week' => $request->day_of_week,
            'start_time' => $request->start_time,
            'end_time' => $request->end_time,
            'hall_name' => $request->hall_name ?: null,
            'created_by' => Auth::id(),
        ]);

        return redirect()->route('administrative.schedules.index')->with('success', 'تم إضافة الجدول بنجاح.');
    }

    /**
     * Show the form for editing the specified schedule.
     */
    public function edit(Schedule $schedule)
    {
        $this->authorizeCollegeAccess($schedule);

        $collegeId = Auth::user()->college_id;
        $majors = Major::where('college_id', $collegeId)->with('levels')->get();
        
        $schedule->load('subject');
        
        // Fetch subjects for the current major/level to populate the dropdown
        $subjects = Subject::where('major_id', $schedule->subject->major_id)
            ->where('level_id', $schedule->subject->level_id)
            ->with('doctor')
            ->get();

        return view('administrative.schedules.edit', compact('schedule', 'majors', 'subjects'));
    }

    /**
     * Update the specified schedule in storage.
     */
    public function update(Request $request, Schedule $schedule)
    {
        $this->authorizeCollegeAccess($schedule);

        $request->validate([
            'subject_id' => 'required|exists:subjects,id',
            'day_of_week' => 'required|integer|between:1,7',
            'start_time' => 'required',
            'end_time' => 'required|after:start_time',
            'hall_name' => 'nullable|string|max:255',
        ]);

        $subject = Subject::findOrFail($request->subject_id);
        
        // Security check for the new subject
        if ($subject->major->college_id !== Auth::user()->college_id) {
            abort(403);
        }

        $schedule->update([
            'subject_id' => $request->subject_id,
            'day_of_week' => $request->day_of_week,
            'start_time' => $request->start_time,
            'end_time' => $request->end_time,
            'hall_name' => $request->hall_name ?: null,
            // We usually don't update created_by on update
        ]);

        return redirect()->route('administrative.schedules.index')->with('success', 'تم تحديث الجدول بنجاح.');
    }

    /**
     * Remove the specified schedule from storage.
     */
    public function destroy(Schedule $schedule)
    {
        $this->authorizeCollegeAccess($schedule);
        $schedule->delete();
        return redirect()->route('administrative.schedules.index')->with('success', 'تم حذف الجدول بنجاح.');
    }

    /**
     * Get subjects with doctors for a level (API helper).
     */
    public function getSubjectsWithDoctors(Level $level)
    {
        if ($level->major->college_id !== Auth::user()->college_id) {
            return response()->json([], 403);
        }

        $subjects = Subject::where('major_id', $level->major_id)
            ->where('level_id', $level->id)
            ->with('doctor:id,name')
            ->get(['id', 'name', 'doctor_id']);

        return response()->json($subjects);
    }

    /**
     * Helper to authorize access to schedules within the admin's college.
     */
    private function authorizeCollegeAccess($model)
    {
        $major = $model instanceof Major ? $model : $model->subject->major;
        
        if ($major->college_id !== Auth::user()->college_id) {
            abort(403);
        }
    }
}
