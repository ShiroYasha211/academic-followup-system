<?php

namespace App\Http\Controllers\Student;

use App\Http\Controllers\Controller;
use App\Models\Academic\Subject;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class ResourceController extends Controller
{
    public function index(Request $request)
    {
        $user = Auth::user();

        // 1. Stats Calculation
        $stats = [
            'total_files' => \App\Models\CourseResource::whereHas('subject', function ($q) use ($user) {
                $q->where('major_id', $user->major_id)->where('level_id', $user->level_id);
            })->count(),
            'recent_week' => \App\Models\CourseResource::whereHas('subject', function ($q) use ($user) {
                $q->where('major_id', $user->major_id)->where('level_id', $user->level_id);
            })->where('created_at', '>=', now()->subWeek())->count(),
        ];

        // 2. Fetch Resources with Filters
        $query = \App\Models\CourseResource::with(['subject', 'uploader'])
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

        // Scheduled Filter
        if ($request->filled('scheduled') && $request->scheduled == '1') {
            $query->whereHas('scheduleItems', function ($q) use ($user) {
                $q->where('user_id', $user->id);
            });
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
        // Only fetch if view is grouped to save performance, but user wants "exact same", so we fetch it.
        // Similar to Delegate controller logic.
        $groupedResourcesQuery = \App\Models\CourseResource::with(['subject', 'uploader'])
            ->whereHas('subject', function ($q) use ($user) {
                $q->where('major_id', $user->major_id)
                    ->where('level_id', $user->level_id);
            });

        // Apply filters to grouped query as well so "Grouped View" reflects searches
        if ($request->filled('search')) {
            $groupedResourcesQuery->where('title', 'like', '%' . $request->search . '%');
        }
        if ($request->filled('subject_id')) {
            $groupedResourcesQuery->where('subject_id', $request->subject_id);
        }
        if ($request->filled('category')) {
            $groupedResourcesQuery->where('category', $request->category);
        }
        if ($request->filled('scheduled') && $request->scheduled == '1') {
            $groupedResourcesQuery->whereHas('scheduleItems', function ($q) use ($user) {
                $q->where('user_id', $user->id);
            });
        }

        $groupedResources = $groupedResourcesQuery->latest()->get()->groupBy('subject_id');

        $viewMode = $request->get('view', 'grouped'); // Default to grouped for student as it's nicer? Or table? Delegate defaults to table. Let's default to table to match.
        // Actually, user said "Like delegate section... look how it is divided". Delegate resources page has a toggle.

        // Fetch scheduled resources for this student
        $scheduledResourceIds = \App\Models\Student\StudentScheduleItem::where('user_id', $user->id)
            ->where('referenceable_type', \App\Models\CourseResource::class)
            ->pluck('referenceable_id')
            ->toArray();

        return view('student.resources.index', compact('resources', 'subjects', 'stats', 'groupedResources', 'viewMode', 'sort', 'scheduledResourceIds'));
    }
}
