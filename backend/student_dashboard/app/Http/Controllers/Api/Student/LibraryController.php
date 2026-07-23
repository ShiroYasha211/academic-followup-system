<?php

namespace App\Http\Controllers\Api\Student;

use Illuminate\Http\Request;
use App\Models\CourseResource;
use App\Models\Academic\Subject;

class LibraryController extends StudentApiController
{
    /**
     * Get the Shared Study Library.
     */
    public function index(Request $request)
    {
        $user = $request->user();

        $subjects = Subject::where('major_id', $user->major_id)
            ->orderBy('level_id')
            ->orderBy('name')
            ->select('id', 'name')
            ->get();

        $uniqueMetadata = CourseResource::select('semester_info', 'lecturer_name')
            ->whereHas('subject', function($q) use ($user) {
                $q->where('major_id', $user->major_id);
            })
            ->get();

        $semesters = $uniqueMetadata->pluck('semester_info')->filter()->unique()->values();
        $lecturers = $uniqueMetadata->pluck('lecturer_name')->filter()->unique()->values();

        $years = CourseResource::selectRaw('YEAR(created_at) as year')
            ->distinct()
            ->orderBy('year', 'desc')
            ->pluck('year');

        $filters = $request->only([
            'search', 'level_id', 'subject_id', 'category', 'sub_category', 
            'year', 'semester_info', 'lecturer_name', 'file_type', 'uploader_role'
        ]);
        $filters['major_id'] = $user->major_id;

        $query = CourseResource::with(['subject:id,name', 'uploader:id,name'])
            ->filter($filters);

        $query->where(function ($q) use ($user) {
            $q->where('visibility', 'everyone')
                ->orWhere(function ($sq) use ($user) {
                    $sq->where('visibility', 'college')
                        ->whereHas('subject', function ($uq) use ($user) {
                            $uq->where('major_id', $user->major_id);
                        });
                })
                ->orWhere(function ($sq) use ($user) {
                    $sq->where('visibility', 'batch')
                        ->whereHas('subject', function ($uq) use ($user) {
                            $uq->where('major_id', $user->major_id)
                            ->where('level_id', $user->level_id);
                        });
                })
                ->orWhere('created_by', $user->id);
        });

        if ($request->has('my_uploads')) {
            $query->where('created_by', $user->id);
        }

        $query->latest();
        $resources = $query->paginate(15);

        return $this->success([
            'filters' => [
                'subjects' => $subjects,
                'semesters' => $semesters,
                'lecturers' => $lecturers,
                'years' => $years,
                'can_upload' => $user->hasPermission('upload_shared_library'),
            ],
            'resources' => $resources,
        ]);
    }

    /**
     * Increment download count and return download URL.
     */
    public function incrementDownload(Request $request, $id)
    {
        $resource = CourseResource::findOrFail($id);

        // Check if student can see it
        $user = $request->user();
        $isVisible = false;
        if ($resource->visibility === 'everyone' || $resource->created_by === $user->id) {
            $isVisible = true;
        } elseif ($resource->visibility === 'college' && $resource->subject->major_id == $user->major_id) {
            $isVisible = true;
        } elseif ($resource->visibility === 'batch' && $resource->subject->major_id == $user->major_id && $resource->subject->level_id == $user->level_id) {
            $isVisible = true;
        }

        if (!$isVisible) {
            return $this->error('ليس لديك صلاحية للوصول لهذا الملف.', 403);
        }

        $resource->increment('downloads_count');

        return $this->success([
            'download_url' => asset('storage/' . $resource->file_path),
        ]);
    }

    /**
     * Store a new resource.
     */
    public function store(Request $request)
    {
        $user = $request->user();
        
        if (!$user->hasPermission('upload_shared_library')) {
            return $this->error('ليس لديك صلاحية الرفع في المكتبة المشتركة.', 403);
        }

        $request->validate([
            'subject_id' => 'required|exists:subjects,id',
            'title' => 'required|string|max:255',
            'category' => 'required|in:lectures,summaries,quizzes,exams,other',
            'sub_category' => 'nullable|string|in:theoretical,practical,seminar,other',
            'custom_category_type' => 'nullable|string|max:255',
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
            'created_by' => $user->id,
            'title' => $request->title,
            'category' => $request->category,
            'sub_category' => $request->sub_category,
            'custom_category_type' => $request->custom_category_type,
            'file_path' => $path,
            'file_type' => $file->getClientOriginalExtension(),
            'description' => $request->description,
            'unit_coordinator' => $request->unit_coordinator,
            'lecturer_name' => $request->lecturer_name,
            'semester_info' => $request->semester_info,
            'visibility' => $request->visibility,
        ]);

        return $this->success(['resource' => $resource], 'تم رفع المورد التعليمي بنجاح إلى المكتبة المشتركة.', 201);
    }
}
