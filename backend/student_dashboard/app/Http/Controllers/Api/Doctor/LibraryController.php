<?php

namespace App\Http\Controllers\Api\Doctor;

use App\Models\Academic\Subject;
use App\Models\CourseResource;
use Illuminate\Http\Request;

class LibraryController extends DoctorApiController
{
    public function index(Request $request)
    {
        $doctor = $request->user();
        $collegeId = $doctor->college_id;

        $uploadSubjects = Subject::where('doctor_id', $doctor->id)
            ->orderBy('name')
            ->select('id', 'name', 'level_id', 'major_id')
            ->get();

        $subjects = Subject::whereHas('major', fn ($query) => $query->where('college_id', $collegeId))
            ->with(['major:id,name,college_id', 'level:id,name'])
            ->orderBy('name')
            ->select('id', 'name', 'level_id', 'major_id')
            ->get();

        $uniqueMetadata = CourseResource::select('semester_info', 'lecturer_name')
            ->whereHas('subject.major', function ($query) use ($collegeId) {
                $query->where('college_id', $collegeId);
            })
            ->get();

        $filters = $request->only([
            'search',
            'level_id',
            'subject_id',
            'category',
            'sub_category',
            'year',
            'semester_info',
            'lecturer_name',
            'file_type',
            'uploader_role',
        ]);
        $doctorSubjectIds = $uploadSubjects->pluck('id');

        $query = CourseResource::with([
                'subject:id,name,doctor_id,major_id,level_id',
                'subject.major:id,name,college_id',
                'subject.level:id,name',
                'uploader:id,name,role',
            ])
            ->filter($filters)
            ->where(function ($builder) use ($doctor, $collegeId, $doctorSubjectIds) {
                $builder->where('visibility', 'everyone')
                    ->orWhere('created_by', $doctor->id)
                    ->orWhere(function ($query) use ($collegeId) {
                        $query->where('visibility', 'college')
                            ->whereHas('subject.major', fn ($subjectQuery) => $subjectQuery->where('college_id', $collegeId));
                    })
                    ->orWhere(function ($query) use ($doctorSubjectIds) {
                        $query->where('visibility', 'batch')
                            ->whereIn('subject_id', $doctorSubjectIds);
                    });
            });

        if ($request->boolean('my_uploads')) {
            $query->where('created_by', $doctor->id);
        }

        $resources = $query->latest()->paginate($request->boolean('grouped') ? $request->integer('per_page', 100) : $request->integer('per_page', 15));
        $groups = collect();

        if ($request->boolean('grouped')) {
            $groups = $resources->getCollection()
                ->groupBy('subject_id')
                ->map(function ($items) {
                    $first = $items->first();
                    $subject = $first?->subject;

                    return [
                        'subject' => $subject ? [
                            'id' => $subject->id,
                            'name' => $subject->name,
                            'major' => $subject->major?->name,
                            'level' => $subject->level?->name,
                        ] : null,
                        'count' => $items->count(),
                        'resources' => $items->values(),
                    ];
                })
                ->sortBy(fn ($group) => $group['subject']['name'] ?? '')
                ->values();
        }

        return $this->success([
            'filters' => [
                'subjects' => $subjects,
                'upload_subjects' => $uploadSubjects,
                'semesters' => $uniqueMetadata->pluck('semester_info')->filter()->unique()->values(),
                'lecturers' => $uniqueMetadata->pluck('lecturer_name')->filter()->unique()->values(),
                'years' => CourseResource::selectRaw('YEAR(created_at) as year')
                    ->distinct()
                    ->orderBy('year', 'desc')
                    ->pluck('year'),
            ],
            'resources' => $resources,
            'groups' => $groups,
        ]);
    }

    public function store(Request $request)
    {
        $doctor = $request->user();

        $validated = $request->validate([
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

        Subject::where('id', $validated['subject_id'])
            ->where('doctor_id', $doctor->id)
            ->firstOrFail();

        $file = $request->file('file');
        $path = $file->store('course_resources', 'public');

        $resource = CourseResource::create([
            'subject_id' => $validated['subject_id'],
            'created_by' => $doctor->id,
            'title' => $validated['title'],
            'category' => $validated['category'],
            'sub_category' => $validated['sub_category'] ?? null,
            'custom_category_type' => $validated['custom_category_type'] ?? null,
            'file_path' => $path,
            'file_type' => $file->getClientOriginalExtension(),
            'description' => $validated['description'] ?? null,
            'unit_coordinator' => $validated['unit_coordinator'] ?? null,
            'lecturer_name' => $validated['lecturer_name'] ?? null,
            'semester_info' => $validated['semester_info'],
            'visibility' => $validated['visibility'],
        ]);

        return $this->success($resource->load('subject:id,name'), 'تم رفع المورد التعليمي بنجاح.', 201);
    }

    public function incrementDownload(Request $request, CourseResource $resource)
    {
        $doctor = $request->user();
        $resource->loadMissing('subject.major');
        $doctorSubjectIds = Subject::where('doctor_id', $doctor->id)->pluck('id');
        $visible = $resource->visibility === 'everyone'
            || $resource->created_by === $doctor->id
            || ($resource->visibility === 'college' && $resource->subject?->major?->college_id === $doctor->college_id)
            || ($resource->visibility === 'batch' && $doctorSubjectIds->contains($resource->subject_id));

        if (!$visible) {
            return $this->error('ليس لديك صلاحية للوصول لهذا الملف.', 403);
        }

        $resource->increment('downloads_count');

        return $this->success([
            'download_url' => asset('storage/' . $resource->file_path),
        ]);
    }
}
