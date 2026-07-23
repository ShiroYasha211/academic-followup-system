<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\CourseResource;
use App\Models\AssignmentSubmission;
use App\Models\Excuse;
use App\Models\Announcement;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Log;

class StorageController extends Controller
{
    public function index(Request $request)
    {
        // 1. Fetch all file-holding models
        $resources = CourseResource::with('uploader', 'subject')->latest()->get()->map(function($item) {
            return $this->transform($item, 'resource');
        });

        $submissions = AssignmentSubmission::with('student', 'assignment.subject')->latest()->get()->map(function($item) {
            return $this->transform($item, 'submission');
        });

        $excuses = Excuse::with('student')->whereNotNull('attachment')->latest()->get()->map(function($item) {
            return $this->transform($item, 'excuse');
        });

        $announcements = Announcement::with('creator')->whereNotNull('attachment_path')->latest()->get()->map(function($item) {
            return $this->transform($item, 'announcement');
        });

        // 2. Merge and calculate stats
        $allItems = $resources->concat($submissions)->concat($excuses)->concat($announcements);
        
        $totalSize = $allItems->sum('size_bytes');
        $stats = [
            'total_size' => $this->formatBytes($totalSize),
            'total_count' => $allItems->count(),
            'by_type' => [
                'resource' => $resources->count(),
                'submission' => $submissions->count(),
                'excuse' => $excuses->count(),
                'announcement' => $announcements->count(),
            ]
        ];

        // 3. Simple Search/Filter (Collection level for simplicity)
        if ($request->filled('search')) {
            $search = strtolower($request->search);
            $allItems = $allItems->filter(function($item) use ($search) {
                return str_contains(strtolower($item['title']), $search) || 
                       str_contains(strtolower($item['uploader_name']), $search);
            });
        }

        if ($request->filled('type')) {
            $allItems = $allItems->where('type', $request->type);
        }

        // 4. Pagination (Manual collection pagination)
        $perPage = 15;
        $page = $request->get('page', 1);
        $paginatedItems = new \Illuminate\Pagination\LengthAwarePaginator(
            $allItems->forPage($page, $perPage),
            $allItems->count(),
            $perPage,
            $page,
            ['path' => $request->url(), 'query' => $request->query()]
        );

        return view('admin.storage.index', compact('paginatedItems', 'stats'));
    }

    public function destroy(Request $request, $type, $id)
    {
        try {
            $model = $this->getModel($type, $id);
            if (!$model) {
                return back()->with('error', 'الملف غير موجود.');
            }

            $path = $this->getPath($type, $model);
            
            // Delete Physical File
            if ($path && Storage::disk('public')->exists($path)) {
                Storage::disk('public')->delete($path);
            }

            // Delete Record (or Nullify if shared, but here we delete the object representing the file)
            if ($type === 'announcement' || $type === 'excuse') {
                // If it's just an attachment on a main record, we might want to just null the path
                // But usually admin wants to "delete that specific uploaded thing"
                if ($type === 'announcement') {
                    $model->update(['attachment_path' => null, 'attachment_type' => null]);
                } else {
                    $model->update(['attachment' => null]);
                }
            } else {
                $model->delete();
            }

            return back()->with('success', 'تم حذف الملف وتوفير المساحة بنجاح.');
        } catch (\Exception $e) {
            Log::error("Storage Delete Error: " . $e->getMessage());
            return back()->with('error', 'حدث خطأ أثناء محاولة الحذف.');
        }
    }

    private function transform($item, $type)
    {
        $path = $this->getPath($type, $item);
        $size = 0;
        
        // Use pre-stored size if available (Assignments have it)
        if ($type === 'submission' && isset($item->file_size)) {
            $size = $item->file_size;
        } else {
            // Get from storage (might be slow for many files, but okay for moderate admin view)
            if ($path && Storage::disk('public')->exists($path)) {
                $size = Storage::disk('public')->size($path);
            }
        }

        return [
            'id' => $item->id,
            'type' => $type,
            'type_label' => $this->getTypeLabel($type),
            'title' => $this->getTitle($type, $item),
            'uploader_name' => $this->getUploaderName($type, $item),
            'uploader_role' => $this->getUploaderRole($type, $item),
            'path' => $path,
            'url' => $path ? Storage::url($path) : '#',
            'file_ext' => $this->getExt($type, $item),
            'size_bytes' => $size,
            'size_formatted' => $this->formatBytes($size),
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
            'submission' => $item->file_name ?? "Submission #{$item->id}",
            'excuse' => "عذر غياب #{$item->id}",
            'announcement' => $item->title,
            default => 'Unknown'
        };
    }

    private function getUploaderName($type, $item) {
        return match($type) {
            'resource' => $item->uploader->name ?? 'User',
            'submission' => $item->student->name ?? 'Student',
            'excuse' => $item->student->name ?? 'Student',
            'announcement' => $item->creator->name ?? 'Admin/Delegate',
            default => 'System'
        };
    }

    private function getUploaderRole($type, $item) {
        $user = match($type) {
            'resource' => $item->uploader,
            'submission' => $item->student,
            'excuse' => $item->student,
            'announcement' => $item->creator,
            default => null
        };
        return $user->role->value ?? 'user';
    }

    private function getExt($type, $item) {
        return match($type) {
            'resource' => $item->file_type,
            'submission' => $item->file_type,
            'excuse' => pathinfo($item->attachment, PATHINFO_EXTENSION),
            'announcement' => $item->attachment_type ?? pathinfo($item->attachment_path, PATHINFO_EXTENSION),
            default => 'file'
        };
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

    private function formatBytes($bytes, $precision = 2) {
        $units = ['B', 'KB', 'MB', 'GB', 'TB'];
        $bytes = max($bytes, 0);
        $pow = floor(($bytes ? log($bytes) : 0) / log(1024));
        $pow = min($pow, count($units) - 1);
        $bytes /= pow(1024, $pow);
        return round($bytes, $precision) . ' ' . $units[$pow];
    }
}
