<?php

namespace App\Http\Controllers\Api\Delegate;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Http\Controllers\Api\Delegate\DelegateApiController;
use App\Models\Announcement;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Storage;

class AnnouncementController extends DelegateApiController
{
    /**
     * Display a listing of announcements with statistics and filters.
     */
    public function index(Request $request)
    {
        $delegate = $request->user();
        $category = $request->get('category', 'all');
        $queryStr = $request->get('q');

        $query = Announcement::where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id);

        if ($category !== 'all') {
            $query->where('category', $category);
        }

        if ($queryStr) {
            $query->where(function($q) use ($queryStr) {
                $q->where('title', 'like', "%{$queryStr}%")
                  ->orWhere('content', 'like', "%{$queryStr}%");
            });
        }

        $announcements = $query->with('creator:id,name')
            ->orderBy('is_pinned', 'desc')
            ->orderBy('created_at', 'desc')
            ->paginate(15);

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

        return $this->success([
            'stats' => $stats,
            'announcements' => $announcements
        ], 'تم جلب الإعلانات بنجاح');
    }

    /**
     * Store a newly created announcement.
     */
    public function store(Request $request)
    {
        $delegate = $request->user();

        $validator = Validator::make($request->all(), [
            'category' => 'required|in:academic,general,urgent',
            'title' => 'required|string|max:255',
            'content' => 'required|string',
            'attachment' => 'nullable|file|max:10240', // 10MB max
            'is_pinned' => 'nullable|boolean',
        ]);

        if ($validator->fails()) {
            return $this->error('بيانات غير صالحة', 422, $validator->errors());
        }

        $data = $request->only(['title', 'content', 'category', 'is_pinned']);
        $data['major_id'] = $delegate->major_id;
        $data['level_id'] = $delegate->level_id;
        $data['created_by'] = $delegate->id;
        $data['is_pinned'] = $request->boolean('is_pinned');

        if ($request->hasFile('attachment')) {
            $file = $request->file('attachment');
            $data['attachment_path'] = $file->store('announcements', 'public');
            
            // Determine attachment type
            $mimeType = $file->getMimeType();
            $data['attachment_type'] = str_starts_with($mimeType, 'image/') ? 'image' : 'document';
        }

        $announcement = Announcement::create($data);

        return $this->success($announcement->load('creator'), 'تم نشر الإعلان بنجاح', 201);
    }

    /**
     * Update the specified announcement.
     */
    public function update(Request $request, string $id)
    {
        $delegate = $request->user();

        $announcement = Announcement::find($id);

        if (!$announcement || $announcement->created_by !== $delegate->id) {
            return $this->error('الإعلان غير موجود أو غير مصرح لك', 404);
        }

        $validator = Validator::make($request->all(), [
            'category' => 'required|in:academic,general,urgent',
            'title' => 'required|string|max:255',
            'content' => 'required|string',
            'attachment' => 'nullable|file|max:10240',
            'is_pinned' => 'nullable|boolean',
            'remove_attachment' => 'nullable|boolean'
        ]);

        if ($validator->fails()) {
            return $this->error('بيانات غير صالحة', 422, $validator->errors());
        }

        $data = $request->only(['title', 'content', 'category', 'is_pinned']);
        $data['is_pinned'] = $request->boolean('is_pinned');

        // Handle attachment removal
        if ($request->boolean('remove_attachment')) {
            if ($announcement->attachment_path) {
                Storage::disk('public')->delete($announcement->attachment_path);
            }
            $data['attachment_path'] = null;
            $data['attachment_type'] = null;
        }

        if ($request->hasFile('attachment')) {
            if ($announcement->attachment_path) {
                Storage::disk('public')->delete($announcement->attachment_path);
            }
            $file = $request->file('attachment');
            $data['attachment_path'] = $file->store('announcements', 'public');
            $mimeType = $file->getMimeType();
            $data['attachment_type'] = str_starts_with($mimeType, 'image/') ? 'image' : 'document';
        }

        $announcement->update($data);

        return $this->success($announcement->load('creator'), 'تم تحديث الإعلان بنجاح');
    }

    /**
     * Toggle the pinned status of an announcement.
     */
    public function togglePin(Request $request, string $id)
    {
        $delegate = $request->user();
        $announcement = Announcement::find($id);

        if (!$announcement || $announcement->created_by !== $delegate->id) {
            return $this->error('الإعلان غير موجود أو غير مصرح لك', 404);
        }

        $announcement->update([
            'is_pinned' => !$announcement->is_pinned
        ]);

        $message = $announcement->is_pinned ? 'تم تثبيت الخبر' : 'تم إلغاء تثبيت الخبر';
        return $this->success($announcement, $message);
    }

    /**
     * Remove the specified announcement.
     */
    public function destroy(Request $request, string $id)
    {
        $delegate = $request->user();

        $announcement = Announcement::find($id);

        if (!$announcement || $announcement->created_by !== $delegate->id) {
            return $this->error('الإعلان غير موجود أو غير مصرح لك', 404);
        }

        if ($announcement->attachment_path) {
            Storage::disk('public')->delete($announcement->attachment_path);
        }

        $announcement->delete();

        return $this->success(null, 'تم حذف الإعلان بنجاح');
    }
}
