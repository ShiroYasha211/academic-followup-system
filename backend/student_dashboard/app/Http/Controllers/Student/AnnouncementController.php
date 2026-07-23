<?php

namespace App\Http\Controllers\Student;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\Announcement;

class AnnouncementController extends Controller
{
    public function index(Request $request)
    {
        $student = Auth::user();
        $category = $request->query('category');

        $baseQuery = Announcement::where('major_id', $student->major_id)
            ->where('level_id', $student->level_id);

        // Statistics
        $stats = [
            'total' => (clone $baseQuery)->count(),
            'academic' => (clone $baseQuery)->where('category', 'academic')->count(),
            'general' => (clone $baseQuery)->where('category', 'general')->count(),
            'urgent' => (clone $baseQuery)->where('category', 'urgent')->count(),
        ];

        // Pinned announcements (if column exists)
        $pinnedAnnouncements = collect();
        if (\Schema::hasColumn('announcements', 'is_pinned')) {
            $pinnedAnnouncements = (clone $baseQuery)
                ->where('is_pinned', true)
                ->latest()
                ->take(3)
                ->get();
        }

        // Main query
        $query = (clone $baseQuery)->latest();

        if ($category && in_array($category, ['academic', 'general', 'urgent'])) {
            $query->where('category', $category);
        }

        $announcements = $query->paginate(10);

        return view('student.announcements.index', compact('announcements', 'category', 'stats', 'pinnedAnnouncements'));
    }
}
