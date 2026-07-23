<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\CourseResource;
use App\Models\Academic\Subject;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class LibraryController extends Controller
{
    public function index(Request $request)
    {
        $subjects = Subject::orderBy('name')->get();
        $years = CourseResource::selectRaw('YEAR(created_at) as year')
            ->distinct()
            ->orderBy('year', 'desc')
            ->pluck('year');

        $semesters = CourseResource::select('semester_info')->distinct()->pluck('semester_info')->filter()->values();
        $lecturers = CourseResource::select('lecturer_name')->distinct()->pluck('lecturer_name')->filter()->values();

        $filters = $request->only([
            'search', 'subject_id', 'category', 'sub_category', 
            'year', 'semester_info', 'lecturer_name', 'file_type', 'uploader_role'
        ]);

        $query = CourseResource::with(['subject', 'uploader'])
            ->filter($filters);

        $totalCount = CourseResource::count();
        $resources = $query->latest()->paginate(20)->withQueryString();

        return view('admin.library.index', compact('resources', 'subjects', 'years', 'semesters', 'lecturers', 'totalCount'));
    }

    public function create()
    {
        $universities = \App\Models\Academic\University::orderBy('name')->get();
        return view('admin.library.create', compact('universities'));
    }

    public function store(Request $request)
    {
        $request->validate([
            'subject_id' => 'required|exists:subjects,id',
            'title' => 'required|string|max:255',
            'category' => 'required|in:lectures,summaries,quizzes,exams,references,other',
            'sub_category' => 'nullable|string|in:theoretical,practical,seminar,other',
            'file' => 'required|file|mimes:pdf,ppt,pptx,doc,docx,xls,xlsx,jpg,jpeg,png,zip,rar|max:51200', // 50MB
            'description' => 'nullable|string',
            'unit_coordinator' => 'nullable|string|max:255',
            'lecturer_name' => 'nullable|string|max:255',
            'semester_info' => 'required|string|max:255',
            'visibility' => 'required|in:batch,college,everyone',
        ]);

        $file = $request->file('file');
        $path = $file->store('course_resources', 'public');

        CourseResource::create([
            'subject_id' => $request->subject_id,
            'created_by' => auth()->id(),
            'title' => $request->title,
            'category' => $request->category,
            'sub_category' => $request->sub_category,
            'file_path' => $path,
            'file_type' => $file->getClientOriginalExtension(),
            'description' => $request->description,
            'unit_coordinator' => $request->unit_coordinator,
            'lecturer_name' => $request->lecturer_name,
            'semester_info' => $request->semester_info,
            'visibility' => $request->visibility,
        ]);

        return redirect()->route('admin.library.index')->with('success', 'تم رفع المورد التعليمي بنجاح إلى المكتبة المشتركة.');
    }

    public function edit(CourseResource $library)
    {
        $subjects = Subject::orderBy('name')->get();
        return view('admin.library.edit', [
            'resource' => $library,
            'subjects' => $subjects
        ]);
    }

    public function update(Request $request, CourseResource $library)
    {
        $request->validate([
            'subject_id' => 'required|exists:subjects,id',
            'title' => 'required|string|max:255',
            'category' => 'required|in:lectures,summaries,quizzes,exams,references,other',
            'sub_category' => 'nullable|string|in:theoretical,practical,seminar,other',
            'semester_info' => 'nullable|string|max:255',
            'lecturer_name' => 'nullable|string|max:255',
            'unit_coordinator' => 'nullable|string|max:255',
            'clinical_unit' => 'nullable|string|max:255',
            'visibility' => 'required|in:batch,college,everyone',
            'description' => 'nullable|string',
        ]);

        $library->update($request->all());

        return redirect()->route('admin.library.index')->with('success', 'تم تحديث بيانات الملف بنجاح.');
    }

    public function download(Request $request, CourseResource $library)
    {
        if (!$request->isMethod('HEAD')) {
            $library->increment('downloads_count');
        }
        return Storage::disk('public')->download($library->file_path, $library->title . '.' . $library->file_type);
    }

    public function destroy(CourseResource $library)
    {
        // Delete physical file
        if (Storage::disk('public')->exists($library->file_path)) {
            Storage::disk('public')->delete($library->file_path);
        }

        $library->delete();

        return redirect()->route('admin.library.index')->with('success', 'تم حذف الملف نهائياً من المكتبة.');
    }

    public function bulkDestroy(Request $request)
    {
        $ids = $request->ids;
        if (empty($ids)) {
            return redirect()->back()->with('error', 'الرجاء اختيار ملفات أولاً.');
        }

        $resources = CourseResource::whereIn('id', $ids)->get();

        foreach ($resources as $resource) {
            if (Storage::disk('public')->exists($resource->file_path)) {
                Storage::disk('public')->delete($resource->file_path);
            }
            $resource->delete();
        }

        return redirect()->route('admin.library.index')->with('success', 'تم حذف الملفات المختارة بنجاح (عدد: ' . count($ids) . ').');
    }
}
