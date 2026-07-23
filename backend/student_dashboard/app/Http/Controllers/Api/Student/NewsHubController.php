<?php

namespace App\Http\Controllers\Api\Student;

use App\Models\Announcement;
use App\Models\DoctorAnnouncement;
use App\Models\StudentNotification;
use App\Models\Academic\Subject;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;

class NewsHubController extends StudentApiController
{
    public function index(Request $request)
    {
        $student = $request->user();
        $source = $request->query('source', 'all');
        $validSources = ['all', 'administration', 'doctor', 'delegate'];

        if (!in_array($source, $validSources, true)) {
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
        })->sort(function ($a, $b) {
            $aPinned = (bool) ($a->is_pinned ?? false);
            $bPinned = (bool) ($b->is_pinned ?? false);
            if ($aPinned !== $bPinned) return $bPinned <=> $aPinned;
            return $b->created_at <=> $a->created_at;
        })->values();

        $perPage = max(1, min((int) $request->query('per_page', 15), 50));
        $page = max((int) $request->query('page', 1), 1);
        $paginated = $items->forPage($page, $perPage)->values();

        return $this->success([
            'module' => [
                'name' => 'student_news_hub',
                'purpose' => 'Unified student news and announcements page that combines administration, doctor, and delegate feeds.',
                'how_to_use' => 'Use the source filter to switch between administration, doctor, delegate, or all sources.',
            ],
            'sources' => [
                [
                    'key' => 'administration',
                    'label' => 'Administration & News Center',
                    'description' => 'Official news center items, administrative alerts, and formal announcements for the student batch.',
                ],
                [
                    'key' => 'doctor',
                    'label' => 'Doctor Announcements',
                    'description' => 'Announcements published by doctors for subjects matching the student major and level.',
                ],
                [
                    'key' => 'delegate',
                    'label' => 'Delegate Announcements',
                    'description' => 'Operational announcements posted by the class delegate for the same major and level.',
                ],
            ],
            'filters' => [
                'current_source' => $source,
                'allowed_sources' => $validSources,
            ],
            'stats' => [
                'all' => $adminItems->count() + $doctorItems->count() + $delegateItems->count(),
                'administration' => $adminItems->count(),
                'doctor' => $doctorItems->count(),
                'delegate' => $delegateItems->count(),
            ],
            'pagination' => [
                'current_page' => $page,
                'per_page' => $perPage,
                'total' => $items->count(),
                'last_page' => (int) ceil(max($items->count(), 1) / $perPage),
            ],
            'items' => $paginated->map(fn ($item) => $this->serializeItem($item, $student))->values(),
        ]);
    }

    private function mapAdministrativeItems($student): Collection
    {
        $newsCenterItems = StudentNotification::with('sender:id,name')
            ->where('user_id', $student->id)
            ->whereIn('type', ['announcement', 'exam', 'assignment', 'poll'])
            ->get();

        $adminAnnouncements = Announcement::with('creator:id,name,role')
            ->where('major_id', $student->major_id)
            ->where('level_id', $student->level_id)
            ->whereHas('creator', function ($query) {
                $query->whereIn('role', ['admin', 'administrative']);
            })
            ->get();

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
            ->get();
    }

    private function mapDelegateItems($student): Collection
    {
        return Announcement::with('creator:id,name,role')
            ->where('major_id', $student->major_id)
            ->where('level_id', $student->level_id)
            ->whereHas('creator', function ($query) {
                $query->whereIn('role', ['delegate', 'practical_delegate']);
            })
            ->get();
    }

    private function serializeItem($item, $student = null): array
    {
        if ($item instanceof StudentNotification) {
            $pollData = null;
            if ($item->type === 'poll') {
                $studentId = $student ? $student->id : auth()->id();
                $options = \App\Models\PollOption::where('batch_id', $item->batch_id)->get();
                $votedOption = \App\Models\PollVote::where('batch_id', $item->batch_id)
                    ->where('student_id', $studentId)
                    ->first();

                $pollData = [
                    'options' => $options->map(function ($option) {
                        return [
                            'id' => $option->id,
                            'text' => $option->option_text,
                            'votes_count' => \App\Models\PollVote::where('poll_option_id', $option->id)->count(),
                        ];
                    })->toArray(),
                    'has_voted' => (bool) $votedOption,
                    'voted_option_id' => $votedOption?->poll_option_id,
                ];
            }

            return [
                'id' => 'center-' . $item->id,
                'source' => 'administration',
                'channel' => 'news_center',
                'source_label' => 'Administration & News Center',
                'channel_label' => 'News Center',
                'title' => $item->title,
                'body' => $item->message,
                'created_at' => $item->created_at?->toISOString(),
                'created_at_human' => $item->created_at?->diffForHumans(),
                'author_name' => $item->sender?->name ?? 'Administration',
                'subject_name' => null,
                'badge' => $this->centerTypeLabel($item->type),
                'icon' => $this->centerIcon($item->type),
                'attachment_url' => $item->attachment_url,
                'is_unread' => is_null($item->read_at),
                'detail_url' => url('/student/news/' . $item->batch_id),
                'open_mode' => 'link',
                'can_vote' => $item->type === 'poll',
                'poll_data' => $pollData,
            ];
        }

        if ($item instanceof DoctorAnnouncement) {
            return [
                'id' => 'doctor-' . $item->id,
                'source' => 'doctor',
                'channel' => 'doctor_announcement',
                'source_label' => 'Doctor Announcements',
                'channel_label' => 'Doctor Announcement',
                'title' => $item->title,
                'body' => $item->content,
                'created_at' => ($item->published_at ?? $item->created_at)?->toISOString(),
                'created_at_human' => ($item->published_at ?? $item->created_at)?->diffForHumans(),
                'author_name' => $item->doctor?->name ?? 'Doctor',
                'subject_name' => $item->subject?->name,
                'badge' => $item->type_label,
                'icon' => $item->type_icon,
                'attachment_url' => $item->attachment_url,
                'is_unread' => false,
                'detail_url' => null,
                'open_mode' => 'modal',
                'can_vote' => false,
            ];
        }

        if ($item instanceof Announcement) {
            $isAdmin = in_array($item->creator?->role?->value, ['admin', 'administrative']);
            return [
                'id' => ($isAdmin ? 'admin-' : 'delegate-') . $item->id,
                'source' => $isAdmin ? 'administration' : 'delegate',
                'channel' => $isAdmin ? 'admin_announcement' : 'delegate_announcement',
                'source_label' => $isAdmin ? 'Administration & News Center' : 'Delegate Announcements',
                'channel_label' => $isAdmin ? 'Administrative Announcement' : 'Delegate Announcement',
                'title' => $item->title,
                'body' => $item->content,
                'created_at' => $item->created_at?->toISOString(),
                'created_at_human' => $item->created_at?->diffForHumans(),
                'author_name' => $item->creator?->name ?? ($isAdmin ? 'Administration' : 'Delegate'),
                'subject_name' => null,
                'badge' => $this->announcementCategoryLabel($item->category),
                'icon' => $isAdmin ? 'fa-building' : 'fa-users',
                'attachment_url' => $item->attachment_url,
                'is_unread' => false,
                'detail_url' => null,
                'open_mode' => 'modal',
                'can_vote' => false,
                'is_pinned' => (bool) $item->is_pinned,
            ];
        }

        return (array) $item;
    }

    private function centerTypeLabel(string $type): string
    {
        return match ($type) {
            'announcement' => 'Official Announcement',
            'exam' => 'Exam Alert',
            'assignment' => 'Assignment Alert',
            'poll' => 'Poll',
            default => 'Alert',
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
            'urgent' => 'Urgent',
            'academic' => 'Academic',
            default => 'General',
        };
    }
}
