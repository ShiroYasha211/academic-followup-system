<?php

namespace App\Http\Controllers\Api\Admin;

use App\Models\CourseResource;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;

class LibraryController extends AdminApiController
{
    public function index(Request $request)
    {
        $filters = $request->only([
            'search', 'subject_id', 'category', 'sub_category', 
            'year', 'semester_info', 'lecturer_name', 'file_type', 'uploader_role',
            'major_id', 'level_id'
        ]);

        $query = CourseResource::with(['subject.major', 'uploader'])
            ->filter($filters);

        $resources = $query->latest()->paginate($request->per_page ?? 15);

        // Add download_url to each item
        $resources->getCollection()->transform(function ($resource) {
            $resource->download_url = route('api.admin.library.download', $resource->id);
            return $resource;
        });

        return $this->paginated($resources, 'تم جلب ملفات المكتبة بنجاح');
    }

    public function show($id)
    {
        $resource = CourseResource::with(['subject.major', 'uploader'])->findOrFail($id);
        $resource->download_url = route('api.admin.library.download', $resource->id);
        
        return $this->success($resource);
    }

    public function store(Request $request)
    {
        $request->validate([
            'subject_id' => 'required|exists:subjects,id',
            'title' => 'required|string|max:255',
            'category' => 'required|in:lectures,summaries,quizzes,exams,references,other',
            'sub_category' => 'nullable|string|in:theoretical,practical,seminar,other',
            'file' => 'required|file|mimes:pdf,ppt,pptx,doc,docx,xls,xlsx,jpg,jpeg,png,zip,rar|max:51200',
            'description' => 'nullable|string',
            'unit_coordinator' => 'nullable|string|max:255',
            'lecturer_name' => 'nullable|string|max:255',
            'semester_info' => 'required|string|max:255',
            'visibility' => 'required|in:batch,college,everyone',
        ]);

        $file = $request->file('file');
        $path = $file->store('course_resources', 'public');

        $resource = CourseResource::create([
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

        return $this->success($resource, 'تم رفع الملف بنجاح', 201);
    }

    public function update(Request $request, $id)
    {
        $resource = CourseResource::findOrFail($id);

        $request->validate([
            'subject_id' => 'exists:subjects,id',
            'title' => 'string|max:255',
            'category' => 'in:lectures,summaries,quizzes,exams,references,other',
            'sub_category' => 'nullable|string|in:theoretical,practical,seminar,other',
            'semester_info' => 'string|max:255',
            'lecturer_name' => 'nullable|string|max:255',
            'visibility' => 'in:batch,college,everyone',
            'description' => 'nullable|string',
        ]);

        $resource->update($request->all());

        return $this->success($resource, 'تم تحديث بيانات الملف بنجاح');
    }

    public function destroy($id)
    {
        $resource = CourseResource::findOrFail($id);

        if (Storage::disk('public')->exists($resource->file_path)) {
            Storage::disk('public')->delete($resource->file_path);
        }

        $resource->delete();

        return $this->success(null, 'تم حذف الملف نهائياً');
    }

    public function bulkDestroy(Request $request)
    {
        $request->validate([
            'ids' => 'required|array',
            'ids.*' => 'exists:course_resources,id',
        ]);

        $ids = $request->ids;
        $resources = CourseResource::whereIn('id', $ids)->get();

        foreach ($resources as $resource) {
            if (Storage::disk('public')->exists($resource->file_path)) {
                Storage::disk('public')->delete($resource->file_path);
            }
            $resource->delete();
        }

        return $this->success(null, 'تم حذف الملفات المختارة بنجاح (عدد: ' . count($ids) . ')');
    }

    public function download($id)
    {
        $resource = CourseResource::findOrFail($id);
        
        $resource->increment('downloads_count');

        return Storage::disk('public')->download($resource->file_path, $resource->title . '.' . $resource->file_type);
    }
}
