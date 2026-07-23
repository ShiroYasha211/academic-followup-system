<?php

namespace App\Http\Controllers\Api\Admin;

use App\Models\CourseResource;
use App\Models\AssignmentSubmission;
use App\Models\Excuse;
use App\Models\Announcement;
use App\Models\ActivityLog;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Log;

class StorageController extends AdminApiController
{
    public function index()
    {
        $resources = CourseResource::all();
        $submissions = AssignmentSubmission::all();
        $excuses = Excuse::whereNotNull('attachment')->get();
        $announcements = Announcement::whereNotNull('attachment_path')->get();

        $totalSize = 0;
        $counts = [
            'resource' => 0,
            'submission' => 0,
            'excuse' => 0,
            'announcement' => 0,
        ];

        // This is a bit heavy but accurate for a stats overview
        $types = [
            'resource' => $resources,
            'submission' => $submissions,
            'excuse' => $excuses,
            'announcement' => $announcements
        ];

        foreach ($types as $type => $collection) {
            $counts[$type] = $collection->count();
            foreach ($collection as $item) {
                $path = $this->getPath($type, $item);
                if ($path && Storage::disk('public')->exists($path)) {
                    $totalSize += Storage::disk('public')->size($path);
                }
            }
        }

        return $this->success([
            'total_size_bytes' => $totalSize,
            'total_count' => array_sum($counts),
            'by_type' => $counts
        ]);
    }

    public function files(Request $request)
    {
        // 1. Fetch all file-holding models
        $resources = CourseResource::with('uploader')->latest()->get()->map(fn($i) => $this->transform($i, 'resource'));
        $submissions = AssignmentSubmission::with('student')->latest()->get()->map(fn($i) => $this->transform($i, 'submission'));
        $excuses = Excuse::with('student')->whereNotNull('attachment')->latest()->get()->map(fn($i) => $this->transform($i, 'excuse'));
        $announcements = Announcement::with('creator')->whereNotNull('attachment_path')->latest()->get()->map(fn($i) => $this->transform($i, 'announcement'));

        $allItems = $resources->concat($submissions)->concat($excuses)->concat($announcements)->sortByDesc('date')->values();

        if ($request->filled('type')) {
            $allItems = $allItems->where('type', $request->type)->values();
        }

        if ($request->filled('search')) {
            $search = strtolower($request->search);
            $allItems = $allItems->filter(fn($i) => str_contains(strtolower($i['title']), $search) || str_contains(strtolower($i['uploader_name']), $search))->values();
        }

        return $this->paginatedCollection($allItems, $request->per_page ?? 15);
    }

    public function destroy(Request $request)
    {
        $request->validate([
            'type' => 'required|string',
            'id' => 'required|integer',
        ]);

        $type = $request->type;
        $id = $request->id;

        $model = $this->getModel($type, $id);
        if (!$model) return $this->error('الملف غير موجود.', 404);

        $path = $this->getPath($type, $model);
        
        if ($path && Storage::disk('public')->exists($path)) {
            Storage::disk('public')->delete($path);
        }

        $title = $this->getTitle($type, $model);

        if ($type === 'announcement') {
            $model->update(['attachment_path' => null, 'attachment_type' => null]);
        } elseif ($type === 'excuse') {
            $model->update(['attachment' => null]);
        } else {
            $model->delete();
        }

        ActivityLog::log('delete', 'File', $id, $title, "حذف ملف ({$this->getTypeLabel($type)}) عبر الـ API لتوفير المساحة: {$title}");

        return $this->success(null, 'تم حذف الملف وتوفير المساحة بنجاح.');
    }

    private function transform($item, $type)
    {
        $path = $this->getPath($type, $item);
        return [
            'id' => $item->id,
            'type' => $type,
            'type_label' => $this->getTypeLabel($type),
            'title' => $this->getTitle($type, $item),
            'uploader_name' => $this->getUploaderName($type, $item),
            'path' => $path,
            'size_bytes' => ($path && Storage::disk('public')->exists($path)) ? Storage::disk('public')->size($path) : 0,
            'date' => $item->created_at ?? $item->submitted_at,
        ];
    }

    private function getPath($type, $item) {
        return match($type) {
            'resource' => $item->file_path,
            'submission' => $item->file_path,
            'excuse' => $item->attachment,
            'announcement' => $item->attachment_path,
            default => null
        };
    }

    private function getTitle($type, $item) {
        return match($type) {
            'resource' => $item->title,
            'submission' => "تسليم: " . ($item->assignment->title ?? "تكليف #{$item->assignment_id}"),
            'excuse' => "عذر طالب: " . ($item->student->name ?? "طالب #{$item->student_id}"),
            'announcement' => $item->title,
            default => 'مرفق غير معروف'
        };
    }

    private function getUploaderName($type, $item) {
        $user = match($type) {
            'resource' => $item->uploader,
            'submission' => $item->student,
            'excuse' => $item->student,
            'announcement' => $item->creator,
            default => null
        };
        return $user->name ?? 'غير معروف';
    }

    private function getTypeLabel($type) {
        return match($type) {
            'resource' => 'مصدر تعليمي',
            'submission' => 'تسليم تكليف',
            'excuse' => 'عذر طبي',
            'announcement' => 'مرفق إعلان',
            default => 'ملف'
        };
    }

    private function getModel($type, $id) {
        return match($type) {
            'resource' => CourseResource::find($id),
            'submission' => AssignmentSubmission::find($id),
            'excuse' => Excuse::find($id),
            'announcement' => Announcement::find($id),
            default => null
        };
    }
}
