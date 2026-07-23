<?php

namespace App\Http\Controllers\Administrative;

use App\Http\Controllers\Controller;
use App\Models\Academic\Subject;
use App\Models\Academic\Term;
use App\Models\Academic\Major;
use App\Models\User;
use App\Enums\UserRole;
use App\Traits\LogsActivity;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class SubjectController extends Controller
{
    use LogsActivity;

    /**
     * Display a listing of subjects within the admin's college.
     */
    public function index()
    {
        $college = auth()->user()->college;

        if (!$college) {
            abort(403, 'حسابك غير مرتبط بكلية. يرجى التواصل مع مدير النظام.');
        }

        // Major IDs for this college
        $majorIds = Major::where('college_id', $college->id)->pluck('id');

        $subjects = Subject::whereIn('major_id', $majorIds)
            ->with(['major', 'level', 'term', 'doctor'])
            ->latest()
            ->paginate(15);

        // Data for dropdowns
        $terms = Term::whereIn('level_id', function($query) use ($majorIds) {
                $query->select('id')->from('levels')->whereIn('major_id', $majorIds);
            })
            ->with('level.major')
            ->get();

        $doctors = User::where('college_id', $college->id)
            ->where('role', UserRole::DOCTOR)
            ->get();

        return view('administrative.subjects.index', compact('subjects', 'terms', 'doctors', 'college'));
    }

    /**
     * Store a newly created subject.
     */
    public function store(Request $request)
    {
        $college = auth()->user()->college;
        $majorIds = Major::where('college_id', $college->id)->pluck('id');

        $request->validate([
            'name' => 'required|string|max:255',
            'code' => 'nullable|string|max:50',
            'term_id' => [
                'required',
                'exists:terms,id',
                function ($attribute, $value, $fail) use ($majorIds) {
                    $term = Term::with('level')->find($value);
                    if (!$term || !in_array($term->level->major_id, $majorIds->toArray())) {
                        $fail('الترم المحدد لا ينتمي لكليتك.');
                    }
                },
            ],
            'doctor_id' => [
                'nullable',
                Rule::exists('users', 'id')->where(function ($query) use ($college) {
                    return $query->where('college_id', $college->id)
                                 ->where('role', UserRole::DOCTOR->value);
                }),
            ],
        ], [
            'term_id.required' => 'يرجى اختيار الترم (الفصل الدراسي) لهذه المادة.',
        ]);

        $term = Term::with('level')->findOrFail($request->term_id);

        $subject = Subject::create([
            'name' => $request->name,
            'code' => $request->code,
            'description' => $request->description,
            'term_id' => $term->id,
            'semester_id' => $request->semester_id,
            'level_id' => $term->level_id,
            'major_id' => $term->level->major_id,
            'doctor_id' => $request->doctor_id,
        ]);

        $this->logCreate('Subject', $subject, "تم إضافة مادة: {$subject->name} بواسطة مسؤول الكلية");

        return redirect()->route('administrative.subjects.index')
            ->with('success', 'تم إضافة المادة الدراسية بنجاح.');
    }

    /**
     * Update the specified subject.
     */
    public function update(Request $request, Subject $subject)
    {
        $college = auth()->user()->college;
        $majorIds = Major::where('college_id', $college->id)->pluck('id');

        // Ensure subject belongs to this college
        if (!in_array($subject->major_id, $majorIds->toArray())) {
            abort(403);
        }

        $request->validate([
            'name' => 'required|string|max:255',
            'code' => 'nullable|string|max:50',
            'term_id' => [
                'required',
                'exists:terms,id',
                function ($attribute, $value, $fail) use ($majorIds) {
                    $term = Term::with('level')->find($value);
                    if (!$term || !in_array($term->level->major_id, $majorIds->toArray())) {
                        $fail('الترم المحدد لا ينتمي لكليتك.');
                    }
                },
            ],
            'doctor_id' => [
                'nullable',
                Rule::exists('users', 'id')->where(function ($query) use ($college) {
                    return $query->where('college_id', $college->id)
                                 ->where('role', UserRole::DOCTOR->value);
                }),
            ],
        ]);

        $updateData = [
            'name' => $request->name,
            'code' => $request->code,
            'semester_id' => $request->semester_id,
            'doctor_id' => $request->doctor_id,
        ];

        if ($request->term_id != $subject->term_id) {
            $term = Term::with('level')->findOrFail($request->term_id);
            $updateData['term_id'] = $term->id;
            $updateData['level_id'] = $term->level_id;
            $updateData['major_id'] = $term->level->major_id;
        }

        $subject->update($updateData);

        $this->logUpdate('Subject', $subject, "تم تعديل مادة: {$subject->name} بواسطة مسؤول الكلية");

        return redirect()->route('administrative.subjects.index')
            ->with('success', 'تم تحديث بيانات المادة بنجاح.');
    }

    /**
     * Remove the specified subject.
     */
    public function destroy(Subject $subject)
    {
        $college = auth()->user()->college;
        $majorIds = Major::where('college_id', $college->id)->pluck('id');

        if (!in_array($subject->major_id, $majorIds->toArray())) {
            abort(403);
        }

        // Optional: Check for attendances
        $attendanceCount = \App\Models\Attendance::where('subject_id', $subject->id)->count();
        if ($attendanceCount > 0) {
             return redirect()->route('administrative.subjects.index')
                ->with('error', "لا يمكن حذف هذه المادة لأنها تحتوي على {$attendanceCount} سجل حضور.");
        }

        $this->logDelete('Subject', $subject, "تم حذف مادة: {$subject->name} بواسطة مسؤول الكلية");

        $subject->delete();
        
        return redirect()->route('administrative.subjects.index')
            ->with('success', 'تم حذف المادة بنجاح.');
    }
}
