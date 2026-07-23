<?php

namespace App\Http\Controllers\Delegate;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Academic\Assignment;
use App\Models\Academic\Subject;
use Illuminate\Support\Facades\Auth;

class AssignmentController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        $delegate = Auth::user();

        // Fetch all assignments that belong to subjects within the delegate's Major & Level,
        // allowing them to see assignments created by Doctors/Admins as well.
        $assignments = Assignment::whereHas('subject', function ($q) use ($delegate) {
            $q->where('major_id', $delegate->major_id)
                ->where('level_id', $delegate->level_id);
        })
            ->with(['subject', 'creator']) // Eager load creator to show who added it
            ->latest()
            ->paginate(10);

        // Also get subjects for the "Create" modal dropdown
        $subjects = Subject::where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id)
            ->get();

        return view('delegate.assignments.index', compact('assignments', 'subjects'));
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $delegate = Auth::user();

        $validated = $request->validate([
            'subject_id' => 'required|exists:subjects,id',
            'title' => 'required|string|max:255',
            'description' => 'required|string',
            'due_date' => 'required|date|after_or_equal:today',
        ]);

        // Validate Subject Scope
        $subject = Subject::findOrFail($validated['subject_id']);
        if ($subject->major_id != $delegate->major_id || $subject->level_id != $delegate->level_id) {
            abort(403, 'Unauthorized action.');
        }

        Assignment::create([
            'subject_id' => $validated['subject_id'],
            'title' => $validated['title'],
            'description' => $validated['description'],
            'due_date' => $validated['due_date'],
            'created_by' => $delegate->id,
        ]);

        return redirect()->route('delegate.assignments.index')->with('success', 'تم إضافة التكليف بنجاح.');
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, Assignment $assignment)
    {
        $delegate = Auth::user();

        if ($assignment->created_by != $delegate->id) {
            abort(403);
        }

        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'required|string',
            'due_date' => 'required|date',
            'subject_id' => 'required|exists:subjects,id', // Allow changing subject?
        ]);

        // Validate Subject Scope
        $subject = Subject::findOrFail($validated['subject_id']);
        if ($subject->major_id != $delegate->major_id || $subject->level_id != $delegate->level_id) {
            abort(403, 'Unauthorized action.');
        }

        $assignment->update($validated);

        return redirect()->route('delegate.assignments.index')->with('success', 'تم تحديث التكليف بنجاح.');
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Assignment $assignment)
    {
        $delegate = Auth::user();

        if ($assignment->created_by != $delegate->id) {
            abort(403);
        }

        $assignment->delete();

        return redirect()->route('delegate.assignments.index')->with('success', 'تم حذف التكليف.');
    }
}
