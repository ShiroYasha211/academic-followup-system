<?php

namespace App\Http\Controllers\Delegate;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\Academic\Subject;
use App\Models\Academic\Term;
use App\Models\User;
use App\Enums\UserRole;
use Illuminate\Routing\Controllers\HasMiddleware;
use Illuminate\Routing\Controllers\Middleware;

class SubjectController extends Controller implements HasMiddleware
{
    /**
     * Get the middleware that should be assigned to the controller.
     */
    public static function middleware(): array
    {
        return [
            new Middleware('delegate.permission:subjects,create', only: ['store']),
            new Middleware('delegate.permission:subjects,update', only: ['edit', 'update']),
            new Middleware('delegate.permission:subjects,delete', only: ['destroy']),
        ];
    }

    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        $delegate = Auth::user();

        // Fetch subjects associated with the delegate's major and level
        $subjects = Subject::with(['doctor', 'term'])
            ->where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id)
            ->latest()
            ->get();

        // Fetch terms related to the delegate's level
        $terms = Term::where('level_id', $delegate->level_id)->get();

        // Fetch all doctors from the system
        $doctors = User::where('role', UserRole::DOCTOR)->orderBy('name')->get();

        return view('delegate.subjects.index', compact('subjects', 'terms', 'doctors'));
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $delegate = Auth::user();

        $request->validate([
            'name' => 'required|string|max:255',
            'code' => 'nullable|string|max:50',
            'term_id' => 'required|exists:terms,id',
            'doctor_id' => 'required|exists:users,id',
        ]);

        // Ensure the term belongs to the delegate's level
        $term = Term::findOrFail($request->term_id);
        if ($term->level_id != $delegate->level_id) {
            abort(403, 'غير مصرح بإضافة مادة في ترم خارج مستواك الأكاديمي.');
        }

        // Ensure doctor_id belongs to a Doctor
        $doctor = User::findOrFail($request->doctor_id);
        if ($doctor->role != UserRole::DOCTOR) {
            abort(422, 'المستخدم المحدد ليس دكتوراً.');
        }

        Subject::create([
            'name' => $request->name,
            'code' => $request->code,
            'term_id' => $request->term_id,
            'doctor_id' => $request->doctor_id,
            // Inherit Academic Details from Delegate
            'level_id' => $delegate->level_id,
            'major_id' => $delegate->major_id,
        ]);

        return redirect()->route('delegate.subjects.index')
            ->with('success', 'تم إضافة المادة الدراسية بنجاح.');
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(Subject $subject)
    {
        // This won't be used since we use Modals, but kept for convention if requested directly
        return redirect()->route('delegate.subjects.index');
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, Subject $subject)
    {
        $delegate = Auth::user();

        if ($subject->major_id != $delegate->major_id || $subject->level_id != $delegate->level_id) {
            abort(403);
        }

        $request->validate([
            'name' => 'required|string|max:255',
            'code' => 'nullable|string|max:50',
            'term_id' => 'required|exists:terms,id',
            'doctor_id' => 'required|exists:users,id',
        ]);

        // Ensure the term belongs to the delegate's level
        $term = Term::findOrFail($request->term_id);
        if ($term->level_id != $delegate->level_id) {
            abort(403, 'غير مصرح بإضافة مادة في ترم خارج مستواك الأكاديمي.');
        }

        // Ensure doctor_id belongs to a Doctor
        $doctor = User::findOrFail($request->doctor_id);
        if ($doctor->role != UserRole::DOCTOR) {
            abort(422, 'المستخدم المحدد ليس دكتوراً.');
        }

        $subject->update([
            'name' => $request->name,
            'code' => $request->code,
            'term_id' => $request->term_id,
            'doctor_id' => $request->doctor_id,
        ]);

        return redirect()->route('delegate.subjects.index')
            ->with('success', 'تم تحديث بيانات المادة الدراسية بنجاح.');
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Subject $subject)
    {
        $delegate = Auth::user();

        if ($subject->major_id != $delegate->major_id || $subject->level_id != $delegate->level_id) {
            abort(403);
        }

        $attendanceCount = \App\Models\Attendance::where('subject_id', $subject->id)->count();
        if ($attendanceCount > 0) {
            return redirect()->route('delegate.subjects.index')
                ->with('error', "لا يمكن حذف هذه المادة لأنها تحتوي على {$attendanceCount} سجل حضور.");
        }

        $subject->delete();

        return redirect()->route('delegate.subjects.index')
            ->with('success', 'تم حذف المادة الدراسية بنجاح.');
    }
}
