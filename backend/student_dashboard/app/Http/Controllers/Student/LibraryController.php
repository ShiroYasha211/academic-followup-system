<?php

namespace App\Http\Controllers\Student;

use App\Http\Controllers\Controller;
use App\Models\CourseResource;
use App\Models\Academic\Subject;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class LibraryController extends Controller
{
    public function index(Request $request)
    {
        $user = Auth::user();

        // 1. Fetch Subjects for Filter
        if ($user->hasRole('doctor')) {
            $subjects = \App\Models\Academic\Subject::where('doctor_id', $user->id)
                ->orderBy('name')
                ->get();
        } else {
            $subjects = Subject::where('major_id', $user->major_id)
                ->orderBy('level_id')
                ->orderBy('name')
                ->get();
        }

        // 2. Fetch Years, Semesters, and Lecturers for Filters
        $uniqueMetadata = CourseResource::select('semester_info', 'lecturer_name')
            ->whereHas('subject', function($q) use ($user) {
                if (!$user->hasRole('doctor')) {
                    $q->where('major_id', $user->major_id);
                } else {
                    $q->where('doctor_id', $user->id);
                }
            })
            ->get();

        $semesters = $uniqueMetadata->pluck('semester_info')->filter()->unique()->values();
        $lecturers = $uniqueMetadata->pluck('lecturer_name')->filter()->unique()->values();

        $years = CourseResource::selectRaw('YEAR(created_at) as year')
            ->distinct()
            ->orderBy('year', 'desc')
            ->pluck('year');

        // 3. Apply Filters
        $filters = $request->only([
            'search', 'level_id', 'subject_id', 'category', 'sub_category', 
            'year', 'semester_info', 'lecturer_name', 'file_type', 'uploader_role'
        ]);
        $filters['major_id'] = $user->major_id;

        $query = CourseResource::with(['subject', 'uploader'])
            ->filter($filters);

        // Visibility Constraints
        $query->where(function ($q) use ($user) {
            if ($user->hasRole('doctor')) {
                // Doctors see public files or their own
                $q->where('visibility', 'everyone')
                  ->orWhere('created_by', $user->id);
            } else {
                // Students/Delegates see public, college-wide, or batch-specific
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
            }
        });

        // Filter by My Uploads
        if ($request->has('my_uploads')) {
            $query->where('created_by', $user->id);
        }

        // 4. Sorting
        $sort = $request->get('sort', 'newest');
        $query->latest();

        // 5. View Mode
        $viewMode = $request->get('view', 'by_subject'); // table | by_subject | by_year

        $resources = null;
        $groupedResources = null;
        $totalCount = 0;

        if ($viewMode === 'table') {
            $resources = $query->paginate(15)->withQueryString();
            $totalCount = $resources->total();
        } else {
            $allResources = $query->get();
            $totalCount = $allResources->count();

            if ($viewMode === 'by_year') {
                $groupedResources = $allResources->groupBy(function ($item) {
                    return $item->created_at->format('Y');
                })->sortKeysDesc();
            } else {
                // by_subject (default)
                $groupedResources = $allResources->groupBy(function ($item) {
                    return $item->subject->name ?? 'أخرى';
                })->sortKeys();
            }
        }

        return view('student.library.index', compact(
            'resources',
            'groupedResources',
            'subjects',
            'years',
            'semesters',
            'lecturers',
            'viewMode',
            'totalCount'
        ));
    }

    public function create()
    {
        $user = Auth::user();

        // Check for granular permission (Students/Delegates) or role (Doctors)
        if (!$user->hasRole('doctor') && !$user->hasPermission('upload_shared_library')) {
            abort(403, 'ليس لديك صلاحية الرفع في المكتبة المشتركة.');
        }

        if ($user->hasRole('doctor')) {
            $subjects = \App\Models\Academic\Subject::where('doctor_id', $user->id)
                ->orderBy('name')
                ->get();
        } else {
            $subjects = Subject::where('major_id', $user->major_id)
                ->orderBy('level_id')
                ->orderBy('name')
                ->get();
        }

        return view('student.library.create', compact('subjects'));
    }

    public function incrementDownload(Request $request, CourseResource $resource)
    {
        if (!$request->isMethod('HEAD')) {
            $resource->increment('downloads_count');
        }
        return \Illuminate\Support\Facades\Storage::disk('public')->download($resource->file_path, $resource->title . '.' . $resource->file_type);
    }

    public function store(Request $request)
    {
        $user = Auth::user();
        
        // 1. Authorize - Check for granular permission or doctor role
        if (!$user->hasRole('doctor') && !$user->hasPermission('upload_shared_library')) {
            abort(403, 'ليس لديك صلاحية الرفع في المكتبة المشتركة.');
        }

        // 2. Validate
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

        // 3. Process File
        $file = $request->file('file');
        $path = $file->store('course_resources', 'public');

        // 4. Create Resource
        CourseResource::create([
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

        $redirectRoute = 'student.library.index';
        if (request()->routeIs('delegate.*')) $redirectRoute = 'delegate.library.index';
        if (request()->routeIs('doctor.*')) $redirectRoute = 'doctor.library.index';

        return redirect()->route($redirectRoute)->with('success', 'تم رفع المورد التعليمي بنجاح إلى المكتبة المشتركة.');
    }
}
