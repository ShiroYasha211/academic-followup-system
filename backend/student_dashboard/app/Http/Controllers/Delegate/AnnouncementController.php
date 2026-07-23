<?php

namespace App\Http\Controllers\Delegate;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Announcement;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Storage;

class AnnouncementController extends Controller
{
    public function index(Request $request)
    {
        $delegate = Auth::user();
        $category = $request->get('category', 'all');

        // Get announcements with filters
        $announcements = Announcement::where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id)
            ->ofCategory($category)
            ->pinnedFirst()
            ->paginate(10);

        // Get statistics
        $stats = [
            'total' => Announcement::where('major_id', $delegate->major_id)
                ->where('level_id', $delegate->level_id)->count(),
            'urgent' => Announcement::where('major_id', $delegate->major_id)
                ->where('level_id', $delegate->level_id)
                ->where('category', 'urgent')->count(),
            'academic' => Announcement::where('major_id', $delegate->major_id)
                ->where('level_id', $delegate->level_id)
                ->where('category', 'academic')->count(),
            'general' => Announcement::where('major_id', $delegate->major_id)
                ->where('level_id', $delegate->level_id)
                ->where('category', 'general')->count(),
            'pinned' => Announcement::where('major_id', $delegate->major_id)
                ->where('level_id', $delegate->level_id)
                ->where('is_pinned', true)->count(),
        ];

        return view('delegate.announcements.index', compact('announcements', 'stats', 'category'));
    }

    public function store(Request $request)
    {
        $delegate = Auth::user();

        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'content' => 'required|string',
            'category' => 'required|in:academic,general,urgent',
            'attachment' => 'nullable|file|mimes:jpg,jpeg,png,gif,pdf,doc,docx,xls,xlsx,ppt,pptx|max:10240',
        ]);

        $data = [
            'title' => $validated['title'],
            'content' => $validated['content'],
            'category' => $validated['category'],
            'major_id' => $delegate->major_id,
            'level_id' => $delegate->level_id,
            'created_by' => $delegate->id,
        ];

        // Handle attachment upload
        if ($request->hasFile('attachment')) {
            $file = $request->file('attachment');
            $path = $file->store('announcements', 'public');
            $data['attachment_path'] = $path;

            // Determine attachment type
            $mimeType = $file->getMimeType();
            if (str_starts_with($mimeType, 'image/')) {
                $data['attachment_type'] = 'image';
            } else {
                $data['attachment_type'] = 'document';
            }
        }

        Announcement::create($data);

        return redirect()->back()->with('success', 'تم نشر الخبر بنجاح.');
    }

    public function update(Request $request, Announcement $announcement)
    {
        $delegate = Auth::user();

        if ($announcement->created_by != $delegate->id) {
            abort(403);
        }

        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'content' => 'required|string',
            'category' => 'required|in:academic,general,urgent',
            'attachment' => 'nullable|file|mimes:jpg,jpeg,png,gif,pdf,doc,docx,xls,xlsx,ppt,pptx|max:10240',
            'remove_attachment' => 'nullable|boolean',
        ]);

        $data = [
            'title' => $validated['title'],
            'content' => $validated['content'],
            'category' => $validated['category'],
        ];

        // Handle attachment removal
        if ($request->input('remove_attachment')) {
            if ($announcement->attachment_path) {
                Storage::disk('public')->delete($announcement->attachment_path);
            }
            $data['attachment_path'] = null;
            $data['attachment_type'] = null;
        }

        // Handle new attachment upload
        if ($request->hasFile('attachment')) {
            // Delete old attachment if exists
            if ($announcement->attachment_path) {
                Storage::disk('public')->delete($announcement->attachment_path);
            }

            $file = $request->file('attachment');
            $path = $file->store('announcements', 'public');
            $data['attachment_path'] = $path;

            $mimeType = $file->getMimeType();
            if (str_starts_with($mimeType, 'image/')) {
                $data['attachment_type'] = 'image';
            } else {
                $data['attachment_type'] = 'document';
            }
        }

        $announcement->update($data);

        return redirect()->back()->with('success', 'تم تحديث الخبر بنجاح.');
    }

    public function togglePin(Announcement $announcement)
    {
        $delegate = Auth::user();

        if ($announcement->created_by != $delegate->id) {
            abort(403);
        }

        $announcement->update([
            'is_pinned' => !$announcement->is_pinned
        ]);

        $message = $announcement->is_pinned ? 'تم تثبيت الخبر.' : 'تم إلغاء تثبيت الخبر.';

        return redirect()->back()->with('success', $message);
    }

    public function destroy(Announcement $announcement)
    {
        $delegate = Auth::user();

        if ($announcement->created_by != $delegate->id) {
            abort(403);
        }

        // Delete attachment if exists
        if ($announcement->attachment_path) {
            Storage::disk('public')->delete($announcement->attachment_path);
        }

        $announcement->delete();

        return redirect()->back()->with('success', 'تم حذف الخبر.');
    }
}
