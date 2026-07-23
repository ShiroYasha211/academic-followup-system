<?php

namespace App\Http\Controllers\Delegate;

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
        $user = Auth::user();

        // 1. Stats Calculation
        $stats = [
            'total_files' => CourseResource::whereHas('subject', function ($q) use ($user) {
                $q->where('major_id', $user->major_id)->where('level_id', $user->level_id);
            })->count(),
            'my_uploads' => CourseResource::where('created_by', $user->id)->count(),
            'recent_week' => CourseResource::whereHas('subject', function ($q) use ($user) {
                $q->where('major_id', $user->major_id)->where('level_id', $user->level_id);
            })->where('created_at', '>=', now()->subWeek())->count(),
        ];

        // 2. Fetch Resources with Filters
        $query = CourseResource::with(['subject', 'uploader'])
            ->whereHas('subject', function ($q) use ($user) {
                $q->where('major_id', $user->major_id)
                    ->where('level_id', $user->level_id);
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

        // 3. Dropdown Data
        $subjects = Subject::where('major_id', $user->major_id)
            ->where('level_id', $user->level_id)
            ->get();

        // 4. Grouped Resources by Subject (for grouped view)
        $groupedResources = CourseResource::with(['subject', 'uploader'])
            ->whereHas('subject', function ($q) use ($user) {
                $q->where('major_id', $user->major_id)
                    ->where('level_id', $user->level_id);
            })
            ->latest()
            ->get()
            ->groupBy('subject_id');

        $viewMode = $request->get('view', 'table'); // table or grouped

        return view('delegate.resources.index', compact('resources', 'subjects', 'stats', 'groupedResources', 'viewMode', 'sort'));
    }

    public function create()
    {
        $user = Auth::user();

        // Fetch subjects for the list
        $subjects = Subject::where('major_id', $user->major_id)
            ->where('level_id', $user->level_id)
            ->get();

        return view('delegate.resources.create', compact('subjects'));
    }

    public function store(Request $request)
    {
        $request->validate([
            'subject_id' => 'required|exists:subjects,id',
            'title' => 'required|string|max:255',
            'category' => 'required|in:lectures,references,summaries,exams,other,quizzes',
            'sub_category' => 'nullable|string|in:theoretical,practical,seminar,other',
            'custom_category_type' => 'nullable|string|max:255',
            'file' => 'required|file|mimes:pdf,ppt,pptx,doc,docx,xls,xlsx,jpg,jpeg,png,zip,rar|max:51200',
            'description' => 'nullable|string',
            'unit_coordinator' => 'nullable|string|max:255',
            'lecturer_name' => 'nullable|string|max:255',
            'clinical_unit' => 'nullable|string|max:255',
            'semester_info' => 'nullable|string|max:255',
        ]);

        $file = $request->file('file');
        $extension = $file->getClientOriginalExtension();

        $path = $file->store('course_resources', 'public');

        CourseResource::create([
            'subject_id' => $request->subject_id,
            'created_by' => Auth::id(),
            'title' => $request->title,
            'category' => $request->category,
            'sub_category' => $request->sub_category,
            'custom_category_type' => $request->custom_category_type,
            'file_path' => $path,
            'file_type' => $extension,
            'description' => $request->description,
            'unit_coordinator' => $request->unit_coordinator,
            'lecturer_name' => $request->lecturer_name,
            'clinical_unit' => $request->clinical_unit,
            'semester_info' => $request->semester_info,
            'visibility' => 'batch', // Default for course resources
        ]);

        return redirect()->route('delegate.resources.index')->with('success', 'تم رفع الملف بنجاح.');
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

    private function getFileType($extension)
    {
        $images = ['jpg', 'jpeg', 'png', 'gif'];
        $docs = ['pdf', 'doc', 'docx', 'txt'];
        $slides = ['ppt', 'pptx'];
        $archives = ['zip', 'rar'];

        if (in_array(strtolower($extension), $images)) return 'image';
        if (in_array(strtolower($extension), $docs)) return 'document';
        if (in_array(strtolower($extension), $slides)) return 'presentation';
        if (in_array(strtolower($extension), $archives)) return 'archive';

        return 'other';
    }

    /**
     * Import a resource from the Global Library to the current batch's subject.
     * This performs a "Soft Clone" (Metadata copy, same file path).
     */
    public function import(Request $request)
    {
        $request->validate([
            'resource_id' => 'required|exists:course_resources,id',
            'subject_id' => 'required|exists:subjects,id',
        ]);

        $original = CourseResource::findOrFail($request->resource_id);

        // Prevent duplicate import for the same subject
        $exists = CourseResource::where('subject_id', $request->subject_id)
            ->where('file_path', $original->file_path)
            ->exists();

        if ($exists) {
            return back()->with('error', 'هذا الملف موجود بالفعل في هذا المقرر.');
        }

        CourseResource::create([
            'subject_id' => $request->subject_id,
            'created_by' => Auth::id(), // The delegate who imported it
            'title' => $original->title,
            'category' => $original->category,
            'file_path' => $original->file_path, // Soft Clone: Point to same file
            'file_type' => $original->file_type,
            'description' => $original->description . " (تم استيراده من المكتبة)",
        ]);

        return back()->with('success', 'تم استيراد الملف إلى مقررك بنجاح.');
    }

    /**
     * Search the global library for import (AJAX)
     */
    public function searchLibrary(Request $request)
    {
        $query = $request->get('q');
        $user = Auth::user();

        $resources = CourseResource::with(['subject', 'uploader'])
            ->whereHas('subject', function ($q) use ($user) {
                $q->where('major_id', $user->major_id);
            })
            ->when($query, function ($q) use ($query) {
                $q->where('title', 'like', "%{$query}%")
                    ->orWhereHas('subject', function ($sq) use ($query) {
                        $sq->where('name', 'like', "%{$query}%");
                    });
            })
            ->latest()
            ->take(20)
            ->get()
            ->map(function ($resource) {
                return [
                    'id' => $resource->id,
                    'title' => $resource->title,
                    'subject_name' => $resource->subject->name ?? 'غير محدد',
                    'category' => $resource->category,
                    'file_type' => $resource->file_type,
                    'uploader_name' => $resource->uploader->name ?? 'غير معروف',
                    'created_at' => $resource->created_at->format('Y/m/d'),
                ];
            });

        return response()->json($resources);
    }
    public function edit(CourseResource $resource)
    {
        if ($resource->created_by !== Auth::id()) {
            abort(403);
        }

        $user = Auth::user();
        $subjects = Subject::where('major_id', $user->major_id)
            ->where('level_id', $user->level_id)
            ->get();

        return view('delegate.resources.edit', compact('resource', 'subjects'));
    }

    public function update(Request $request, CourseResource $resource)
    {
        if ($resource->created_by !== Auth::id()) {
            abort(403);
        }

        $request->validate([
            'subject_id' => 'required|exists:subjects,id',
            'title' => 'required|string|max:255',
            'category' => 'required|in:lectures,references,summaries,exams,other,quizzes',
            'sub_category' => 'nullable|string|in:theoretical,practical,seminar,other',
            'custom_category_type' => 'nullable|string|max:255',
            'description' => 'nullable|string',
            'unit_coordinator' => 'nullable|string|max:255',
            'lecturer_name' => 'nullable|string|max:255',
            'clinical_unit' => 'nullable|string|max:255',
            'semester_info' => 'nullable|string|max:255',
        ]);

        $resource->update([
            'subject_id' => $request->subject_id,
            'title' => $request->title,
            'category' => $request->category,
            'sub_category' => $request->sub_category,
            'custom_category_type' => $request->custom_category_type,
            'description' => $request->description,
            'unit_coordinator' => $request->unit_coordinator,
            'lecturer_name' => $request->lecturer_name,
            'clinical_unit' => $request->clinical_unit,
            'semester_info' => $request->semester_info,
        ]);

        return redirect()->route('delegate.resources.index')->with('success', 'تم تعديل الملف بنجاح.');
    }
}
