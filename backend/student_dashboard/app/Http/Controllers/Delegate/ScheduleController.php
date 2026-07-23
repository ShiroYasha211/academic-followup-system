<?php

namespace App\Http\Controllers\Delegate;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Academic\Schedule;
use App\Models\Academic\Subject;
use Illuminate\Support\Facades\Auth;
use Illuminate\Routing\Controllers\HasMiddleware;
use Illuminate\Routing\Controllers\Middleware;

class ScheduleController extends Controller implements HasMiddleware
{
    /**
     * Get the middleware that should be assigned to the controller.
     */
    public static function middleware(): array
    {
        return [
            new Middleware('delegate.permission:schedules,create', only: ['create', 'store']),
            new Middleware('delegate.permission:schedules,update', only: ['edit', 'update']),
            new Middleware('delegate.permission:schedules,delete', only: ['destroy']),
        ];
    }

    public function index()
    {
        $delegate = Auth::user();

        // Get schedules for subjects in the delegate's major/level
        $schedules = Schedule::whereHas('subject', function ($q) use ($delegate) {
            $q->where('major_id', $delegate->major_id)
                ->where('level_id', $delegate->level_id);
        })
            ->with('subject')
            ->orderBy('day_of_week')
            ->orderBy('start_time')
            ->get();

        return view('delegate.schedules.index', compact('schedules'));
    }

    public function create()
    {
        $delegate = Auth::user();

        $subjects = Subject::where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id)
            ->get();

        return view('delegate.schedules.create', compact('subjects'));
    }

    public function store(Request $request)
    {
        $delegate = Auth::user();

        $validated = $request->validate([
            'subject_id' => 'required|exists:subjects,id',
            'day_of_week' => 'required|integer|between:1,7',
            'start_time' => 'required',
            'end_time' => 'required|after:start_time',
            'hall_name' => 'nullable|string|max:255',
        ]);

        // Validation Scope Check
        $subject = Subject::findOrFail($validated['subject_id']);
        if ($subject->major_id != $delegate->major_id || $subject->level_id != $delegate->level_id) {
            abort(403);
        }

        $validated['created_by'] = Auth::id();
        Schedule::create($validated);

        return redirect()->route('delegate.schedules.index')->with('success', 'تم إضافة الموعد بنجاح.');
    }

    public function edit(Schedule $schedule)
    {
        $delegate = Auth::user();

        // Scope Check
        if ($schedule->subject->major_id != $delegate->major_id || $schedule->subject->level_id != $delegate->level_id) {
            abort(403);
        }

        $subjects = Subject::where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id)
            ->get();

        return view('delegate.schedules.edit', compact('schedule', 'subjects'));
    }

    public function update(Request $request, Schedule $schedule)
    {
        $delegate = Auth::user();

        // Scope Check (Initial)
        if ($schedule->subject->major_id != $delegate->major_id || $schedule->subject->level_id != $delegate->level_id) {
            abort(403);
        }

        $validated = $request->validate([
            'subject_id' => 'required|exists:subjects,id',
            'day_of_week' => 'required|integer|between:1,7',
            'start_time' => 'required',
            'end_time' => 'required|after:start_time',
            'hall_name' => 'nullable|string|max:255',
        ]);

        // Validation Scope Check (New Subject)
        $newSubject = Subject::findOrFail($validated['subject_id']);
        if ($newSubject->major_id != $delegate->major_id || $newSubject->level_id != $delegate->level_id) {
            abort(403);
        }

        $schedule->update($validated);

        return redirect()->route('delegate.schedules.index')->with('success', 'تم تحديث الموعد بنجاح.');
    }

    public function destroy(Schedule $schedule)
    {
        $delegate = Auth::user();

        // Scope Check: Ensure schedule belongs to delegate's major/level
        if ($schedule->subject->major_id != $delegate->major_id || $schedule->subject->level_id != $delegate->level_id) {
            abort(403);
        }

        $schedule->delete();
        return redirect()->route('delegate.schedules.index')->with('success', 'تم حذف الموعد.');
    }
}
