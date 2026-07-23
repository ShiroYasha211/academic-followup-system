<?php

namespace App\Http\Controllers\Doctor;

use App\Http\Controllers\Controller;
use App\Models\CourseResource;
use App\Models\Academic\Subject;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Storage;

class ResourceController extends Controller
{
    public function index(Request $request)
    {
        $doctor = Auth::user();

        // 1. Stats Calculation
        $stats = [
            'total_files' => CourseResource::where('created_by', $doctor->id)->count(),
            'my_uploads' => CourseResource::where('created_by', $doctor->id)->count(),
            'recent_week' => CourseResource::where('created_by', $doctor->id)
                ->where('created_at', '>=', now()->subWeek())
                ->count(),
        ];

        // 2. Fetch Resources with Filters
        // Doctors can see ALL resources for subjects assigned to them
        $query = CourseResource::with(['subject', 'uploader'])
            ->whereHas('subject', function ($q) use ($doctor) {
                $q->where('doctor_id', $doctor->id);
            });

        // Search Filter
        if ($request->filled('search')) {
            $query->where('title', 'like', '%' . $request->search . '%');
        }

        // Subject Filter
        if ($request->filled('subject_id')) {
            $query->where('subject_id', $request->subject_id);
        }

        // Category Filter
        if ($request->filled('category')) {
            $query->where('category', $request->category);
        }

        // Sorting
        $sort = $request->get('sort', 'newest');
        switch ($sort) {
            case 'oldest':
                $query->oldest();
                break;
            case 'subject':
                $query->join('subjects', 'course_resources.subject_id', '=', 'subjects.id')
                    ->orderBy('subjects.name')
                    ->select('course_resources.*');
                break;
            default: // newest
                $query->latest();
        }

        $resources = $query->paginate(10);

        // 3. Dropdown Data (Only doctor's subjects)
        $subjects = Subject::where('doctor_id', $doctor->id)->get();

        // 4. Grouped Resources by Subject (for grouped view)
        $groupedResources = CourseResource::with(['subject', 'uploader'])
            ->whereHas('subject', function ($q) use ($doctor) {
                $q->where('doctor_id', $doctor->id);
            })
            ->latest()
            ->get()
            ->groupBy('subject_id');

        $viewMode = $request->get('view', 'table'); // table or grouped

        return view('doctor.resources.index', compact('resources', 'subjects', 'stats', 'groupedResources', 'viewMode', 'sort'));
    }

    public function create()
    {
        $doctor = Auth::user();

        // Fetch subjects assigned to this doctor
        $subjects = Subject::where('doctor_id', $doctor->id)->get();

        return view('doctor.resources.create', compact('subjects'));
    }

    public function store(Request $request)
    {
        $request->validate([
            'subject_id' => 'required|exists:subjects,id',
            'title' => 'required|string|max:255',
            'category' => 'required|in:lectures,references,summaries,exams,other',
            'file' => 'required|file|mimes:pdf,ppt,pptx,doc,docx,xls,xlsx,jpg,jpeg,png,zip,rar|max:51200',
            'description' => 'nullable|string',
        ]);

        // Security check: Ensure the doctor is assigned to this subject
        $subject = Subject::where('id', $request->subject_id)
            ->where('doctor_id', Auth::id())
            ->firstOrFail();

        $file = $request->file('file');
        $extension = $file->getClientOriginalExtension();

        $path = $file->store('course_resources', 'public');

        CourseResource::create([
            'subject_id' => $request->subject_id,
            'created_by' => Auth::id(),
            'title' => $request->title,
            'category' => $request->category,
            'file_path' => $path,
            'file_type' => $extension,
            'description' => $request->description,
        ]);

        return redirect()->route('doctor.resources.index')->with('success', 'تم رفع الملف بنجاح.');
    }

    public function edit(CourseResource $resource)
    {
        if ($resource->created_by !== Auth::id()) {
            abort(403);
        }

        $doctor = Auth::user();
        $subjects = Subject::where('doctor_id', $doctor->id)->get();

        return view('doctor.resources.edit', compact('resource', 'subjects'));
    }

    public function update(Request $request, CourseResource $resource)
    {
        if ($resource->created_by !== Auth::id()) {
            abort(403);
        }

        $request->validate([
            'subject_id' => 'required|exists:subjects,id',
            'title' => 'required|string|max:255',
            'category' => 'required|in:lectures,references,summaries,exams,other',
            'description' => 'nullable|string',
        ]);

        // Security check: Ensure the doctor is assigned to this subject
        Subject::where('id', $request->subject_id)
            ->where('doctor_id', Auth::id())
            ->firstOrFail();

        $resource->update([
            'subject_id' => $request->subject_id,
            'title' => $request->title,
            'category' => $request->category,
            'description' => $request->description,
        ]);

        return redirect()->route('doctor.resources.index')->with('success', 'تم تعديل الملف بنجاح.');
    }

    public function destroy(CourseResource $resource)
    {
        if ($resource->created_by !== Auth::id()) {
            abort(403);
        }

        Storage::disk('public')->delete($resource->file_path);
        $resource->delete();

        return redirect()->back()->with('success', 'تم حذف الملف بنجاح.');
    }
}
