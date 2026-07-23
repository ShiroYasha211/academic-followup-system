<?php

namespace App\Http\Controllers\Student;

use App\Http\Controllers\Controller;
use App\Models\Academic\Subject;
use App\Models\Announcement;
use App\Models\DoctorAnnouncement;
use App\Models\StudentNotification;
use Illuminate\Http\Request;
use Illuminate\Pagination\LengthAwarePaginator;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Str;

class NewsHubController extends Controller
{
    public function index(Request $request)
    {
        $student = Auth::user();
        $source = $request->query('source', 'all');
        $validSources = ['all', 'administration', 'doctor', 'delegate'];

        if (! in_array($source, $validSources, true)) {
            $source = 'all';
        }

        $adminItems = $this->mapAdministrativeItems($student);
        $doctorItems = $this->mapDoctorItems($student);
        $delegateItems = $this->mapDelegateItems($student);

        $items = (match ($source) {
            'administration' => $adminItems,
            'doctor' => $doctorItems,
            'delegate' => $delegateItems,
            default => $adminItems->merge($doctorItems)->merge($delegateItems),
        })->sortByDesc('created_at')->values();

        $perPage = 12;
        $page = LengthAwarePaginator::resolveCurrentPage();
        $paginatedItems = new LengthAwarePaginator(
            $items->forPage($page, $perPage)->values(),
            $items->count(),
            $perPage,
            $page,
            [
                'path' => $request->url(),
                'query' => $request->query(),
            ]
        );

        $stats = [
            'all' => $adminItems->count() + $doctorItems->count() + $delegateItems->count(),
            'administration' => $adminItems->count(),
            'doctor' => $doctorItems->count(),
            'delegate' => $delegateItems->count(),
        ];

        $sources = [
            [
                'key' => 'administration',
                'label' => 'الإدارة والمركز',
                'description' => 'يشمل أخبار المركز الإخباري الرسمية والتنبيهات الإدارية والإعلانات العامة الموجهة لدفعتك.',
            ],
            [
                'key' => 'doctor',
                'label' => 'إعلانات الدكتور',
                'description' => 'يشمل الإعلانات الأكاديمية الصادرة من دكاترة المواد المرتبطة بتخصصك ومستواك.',
            ],
            [
                'key' => 'delegate',
                'label' => 'إعلانات المندوب',
                'description' => 'يشمل التنبيهات التشغيلية والإعلانات السريعة التي ينشرها مندوب الدفعة لطلاب المستوى نفسه.',
            ],
        ];

        return view('student.news.hub', [
            'items' => $paginatedItems,
            'source' => $source,
            'stats' => $stats,
            'sources' => $sources,
        ]);
    }

    private function mapAdministrativeItems($student): Collection
    {
        $newsCenterItems = StudentNotification::with('sender:id,name')
            ->where('user_id', $student->id)
            ->whereIn('type', ['announcement', 'exam', 'assignment', 'poll'])
            ->get()
            ->map(function (StudentNotification $item) {
                return [
                    'id' => 'center-' . $item->id,
                    'source' => 'administration',
                    'channel' => 'news_center',
                    'source_label' => 'الإدارة والمركز',
                    'channel_label' => 'المركز الإخباري',
                    'title' => $item->title,
                    'body' => $item->message,
                    'excerpt' => Str::limit($item->message, 180),
                    'created_at' => $item->created_at,
                    'created_at_human' => $item->created_at->diffForHumans(),
                    'author_name' => $item->sender?->name ?? 'الإدارة',
                    'subject_name' => null,
                    'badge' => $this->centerTypeLabel($item->type),
                    'badge_class' => $this->centerBadgeClass($item->type),
                    'icon' => $this->centerIcon($item->type),
                    'attachment_url' => $item->attachment_url,
                    'is_unread' => is_null($item->read_at),
                    'detail_url' => $item->batch_id ? route('student.news.show', $item->batch_id) : null,
                    'open_mode' => 'link',
                    'can_vote' => $item->type === 'poll',
                ];
            });

        $adminAnnouncements = Announcement::with('creator:id,name,role')
            ->where('major_id', $student->major_id)
            ->where('level_id', $student->level_id)
            ->whereHas('creator', function ($query) {
                $query->whereIn('role', ['admin', 'administrative']);
            })
            ->get()
            ->map(function (Announcement $item) {
                return [
                    'id' => 'admin-' . $item->id,
                    'source' => 'administration',
                    'channel' => 'admin_announcement',
                    'source_label' => 'الإدارة والمركز',
                    'channel_label' => 'إعلان إداري',
                    'title' => $item->title,
                    'body' => $item->content,
                    'excerpt' => Str::limit($item->content, 180),
                    'created_at' => $item->created_at,
                    'created_at_human' => $item->created_at->diffForHumans(),
                    'author_name' => $item->creator?->name ?? 'الإدارة',
                    'subject_name' => null,
                    'badge' => $this->announcementCategoryLabel($item->category),
                    'badge_class' => $this->announcementBadgeClass($item->category),
                    'icon' => 'fa-building',
                    'attachment_url' => $item->attachment_url,
                    'is_unread' => false,
                    'detail_url' => null,
                    'open_mode' => 'modal',
                    'can_vote' => false,
                ];
            });

        return $newsCenterItems->merge($adminAnnouncements);
    }

    private function mapDoctorItems($student): Collection
    {
        $subjectIds = Subject::where('major_id', $student->major_id)
            ->where('level_id', $student->level_id)
            ->pluck('id');

        return DoctorAnnouncement::published()
            ->with(['doctor:id,name', 'subject:id,name'])
            ->whereIn('subject_id', $subjectIds)
            ->get()
            ->map(function (DoctorAnnouncement $item) {
                $createdAt = $item->published_at ?? $item->created_at;

                return [
                    'id' => 'doctor-' . $item->id,
                    'source' => 'doctor',
                    'channel' => 'doctor_announcement',
                    'source_label' => 'إعلانات الدكتور',
                    'channel_label' => 'إعلان دكتور',
                    'title' => $item->title,
                    'body' => $item->content,
                    'excerpt' => Str::limit($item->content, 180),
                    'created_at' => $createdAt,
                    'created_at_human' => $createdAt->diffForHumans(),
                    'author_name' => $item->doctor?->name ?? 'عضو هيئة تدريس',
                    'subject_name' => $item->subject?->name,
                    'badge' => $item->type_label,
                    'badge_class' => $this->doctorBadgeClass($item->type),
                    'icon' => $item->type_icon,
                    'attachment_url' => $item->attachment_url,
                    'is_unread' => false,
                    'detail_url' => null,
                    'open_mode' => 'modal',
                    'can_vote' => false,
                ];
            });
    }

    private function mapDelegateItems($student): Collection
    {
        return Announcement::with('creator:id,name,role')
            ->where('major_id', $student->major_id)
            ->where('level_id', $student->level_id)
            ->whereHas('creator', function ($query) {
                $query->whereIn('role', ['delegate', 'practical_delegate']);
            })
            ->get()
            ->map(function (Announcement $item) {
                return [
                    'id' => 'delegate-' . $item->id,
                    'source' => 'delegate',
                    'channel' => 'delegate_announcement',
                    'source_label' => 'إعلانات المندوب',
                    'channel_label' => 'إعلان مندوب',
                    'title' => $item->title,
                    'body' => $item->content,
                    'excerpt' => Str::limit($item->content, 180),
                    'created_at' => $item->created_at,
                    'created_at_human' => $item->created_at->diffForHumans(),
                    'author_name' => $item->creator?->name ?? 'المندوب',
                    'subject_name' => null,
                    'badge' => $this->announcementCategoryLabel($item->category),
                    'badge_class' => $this->announcementBadgeClass($item->category),
                    'icon' => 'fa-users',
                    'attachment_url' => $item->attachment_url,
                    'is_unread' => false,
                    'detail_url' => null,
                    'open_mode' => 'modal',
                    'can_vote' => false,
                ];
            });
    }

    private function centerTypeLabel(string $type): string
    {
        return match ($type) {
            'announcement' => 'إعلان رسمي',
            'exam' => 'تنبيه اختبار',
            'assignment' => 'تكليف',
            'poll' => 'استطلاع',
            default => 'تنبيه',
        };
    }

    private function centerBadgeClass(string $type): string
    {
        return match ($type) {
            'announcement' => 'badge-admin',
            'exam' => 'badge-danger',
            'assignment' => 'badge-warning',
            'poll' => 'badge-success',
            default => 'badge-neutral',
        };
    }

    private function centerIcon(string $type): string
    {
        return match ($type) {
            'announcement' => 'fa-newspaper',
            'exam' => 'fa-calendar-check',
            'assignment' => 'fa-file-circle-check',
            'poll' => 'fa-square-poll-vertical',
            default => 'fa-bell',
        };
    }

    private function announcementCategoryLabel(?string $category): string
    {
        return match ($category) {
            'urgent' => 'عاجل',
            'academic' => 'أكاديمي',
            default => 'عام',
        };
    }

    private function announcementBadgeClass(?string $category): string
    {
        return match ($category) {
            'urgent' => 'badge-danger',
            'academic' => 'badge-info',
            default => 'badge-neutral',
        };
    }

    private function doctorBadgeClass(?string $type): string
    {
        return match ($type) {
            'warning' => 'badge-danger',
            'quiz_alert' => 'badge-warning',
            default => 'badge-info',
        };
    }
}
