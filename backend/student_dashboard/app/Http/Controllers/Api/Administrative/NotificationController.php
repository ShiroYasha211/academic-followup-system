<?php

namespace App\Http\Controllers\Api\Administrative;

use App\Jobs\SendBatchPushNotificationsJob;
use App\Enums\UserRole;
use App\Models\Academic\Major;
use App\Models\PollOption;
use App\Models\PollVote;
use App\Models\StudentNotification;
use App\Models\User;
use App\Services\PushNotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class NotificationController extends AdministrativeApiController
{
    public function index(Request $request)
    {
        $query = StudentNotification::where('college_id', $this->college()->id)
            ->whereNotNull('batch_id');

        $query->when($request->type, fn ($q) => $q->where('type', $request->type));
        $query->when($request->from_date, fn ($q) => $q->whereDate('created_at', '>=', $request->from_date));
        $query->when($request->to_date, fn ($q) => $q->whereDate('created_at', '<=', $request->to_date));

        $broadcasts = $query->select(
            'batch_id',
            'title',
            'type',
            'created_at',
            DB::raw('count(*) as total_count'),
            DB::raw('count(read_at) as read_count')
        )
            ->groupBy('batch_id', 'title', 'type', 'created_at')
            ->latest()
            ->paginate($request->integer('per_page', 10));

        $typeStats = StudentNotification::where('college_id', $this->college()->id)
            ->whereNotNull('batch_id')
            ->select('type', DB::raw('count(distinct batch_id) as total'))
            ->groupBy('type')
            ->pluck('total', 'type');

        return $this->success([
            'broadcasts' => $broadcasts->items(),
            'pagination' => [
                'current_page' => $broadcasts->currentPage(),
                'last_page' => $broadcasts->lastPage(),
                'per_page' => $broadcasts->perPage(),
                'total' => $broadcasts->total(),
            ],
            'type_stats' => $typeStats,
        ]);
    }

    public function createData()
    {
        return $this->success([
            'majors' => Major::where('college_id', $this->college()->id)->with('levels:id,name,major_id')->get(['id', 'name']),
            'targets' => ['all', 'major', 'level', 'doctors', 'delegates'],
            'types' => ['announcement', 'exam', 'assignment', 'attendance', 'poll'],
        ]);
    }

    public function store(Request $request)
    {
        $admin = $this->administrative();
        $college = $this->college();

        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'message' => 'required|string',
            'type' => 'required|in:announcement,exam,assignment,attendance,poll',
            'target' => 'required|in:all,major,level,doctors,delegates',
            'major_id' => [
                'required_if:target,major,level',
                Rule::exists('majors', 'id')->where(fn ($query) => $query->where('college_id', $college->id)),
            ],
            'level_id' => [
                'required_if:target,level',
                Rule::exists('levels', 'id')->where(function ($query) use ($college) {
                    $query->whereIn('major_id', Major::where('college_id', $college->id)->pluck('id'));
                }),
            ],
            'attachment' => 'nullable|file|mimes:pdf,doc,docx,jpg,jpeg,png|max:10240',
            'poll_options' => 'required_if:type,poll|array|min:2',
            'poll_options.*' => 'required_if:type,poll|string|max:255',
        ]);

        $query = User::where('college_id', $college->id);

        if ($validated['target'] === 'major') {
            $query->where('id', '!=', $admin->id);
            $query->where('major_id', $validated['major_id']);
        } elseif ($validated['target'] === 'level') {
            $query->where('id', '!=', $admin->id);
            $query->where('level_id', $validated['level_id']);
        } elseif ($validated['target'] === 'doctors') {
            $query->where('role', UserRole::DOCTOR);
        } elseif ($validated['target'] === 'delegates') {
            $query->where('id', '!=', $admin->id);
            $query->whereIn('role', [UserRole::DELEGATE, UserRole::PRACTICAL_DELEGATE]);
        } else {
            $query->where('id', '!=', $admin->id);
        }

        $users = $query->get(['id']);

        if ($admin->isDoctorWithAdministrativeAccess()) {
            $users = $users->push($admin)->unique('id')->values();
        }

        if ($users->isEmpty()) {
            return $this->error('لا يوجد مستخدمون ضمن الفئة المستهدفة.', 422);
        }

        $attachmentPath = null;
        $attachmentName = null;
        if ($request->hasFile('attachment')) {
            $file = $request->file('attachment');
            $attachmentName = $file->getClientOriginalName();
            $attachmentPath = $file->store('notifications/attachments', 'public');
        }

        $batchId = (string) Str::uuid();

        DB::transaction(function () use ($validated, $users, $college, $admin, $batchId, $attachmentPath, $attachmentName) {
            $rows = [];

            foreach ($users as $user) {
                $rows[] = [
                    'user_id' => $user->id,
                    'college_id' => $college->id,
                    'sender_id' => $admin->id,
                    'batch_id' => $batchId,
                    'type' => $validated['type'],
                    'title' => $validated['title'],
                    'message' => $validated['message'],
                    'attachment_path' => $attachmentPath,
                    'attachment_name' => $attachmentName,
                    'created_at' => now(),
                    'updated_at' => now(),
                ];
            }

            foreach (array_chunk($rows, 500) as $chunk) {
                StudentNotification::insert($chunk);
            }

            if ($validated['type'] === 'poll') {
                foreach ($validated['poll_options'] as $optionText) {
                    if (!empty($optionText)) {
                        PollOption::create([
                            'batch_id' => $batchId,
                            'option_text' => $optionText,
                        ]);
                    }
                }
            }
        });


        if (config('services.firebase.queue')) {
            SendBatchPushNotificationsJob::dispatch($batchId);
        } else {
            app(PushNotificationService::class)->sendBatchByBatchId($batchId);
        }
        return $this->success([
            'batch_id' => $batchId,
            'recipients_count' => $users->count(),
        ], 'تم إرسال الإعلان بنجاح', 201);
    }

    public function show(string $batchId)
    {
        $notifications = StudentNotification::where('batch_id', $batchId)
            ->where('college_id', $this->college()->id)
            ->with('user:id,name,email')
            ->get();

        if ($notifications->isEmpty()) {
            return $this->error('الإعلان غير موجود.', 404);
        }

        $first = $notifications->first();
        $stats = [
            'title' => $first->title,
            'message' => $first->message,
            'type' => $first->type,
            'attachment_name' => $first->attachment_name,
            'attachment_url' => $first->attachment_url,
            'created_at' => $first->created_at,
            'total_count' => $notifications->count(),
            'read_count' => $notifications->whereNotNull('read_at')->count(),
            'poll_options' => [],
            'total_votes' => 0,
        ];

        if ($first->type === 'poll') {
            $options = PollOption::where('batch_id', $batchId)->get();
            $totalVotes = PollVote::where('batch_id', $batchId)->count();
            $stats['total_votes'] = $totalVotes;

            foreach ($options as $option) {
                $count = PollVote::where('poll_option_id', $option->id)->count();
                $stats['poll_options'][] = [
                    'id' => $option->id,
                    'text' => $option->option_text,
                    'count' => $count,
                    'percentage' => $totalVotes > 0 ? round(($count / $totalVotes) * 100, 1) : 0,
                ];
            }
        }

        return $this->success([
            'stats' => $stats,
            'recipients' => $notifications->map(fn ($item) => [
                'id' => $item->user_id,
                'name' => $item->user?->name,
                'email' => $item->user?->email,
                'read_at' => $item->read_at?->format('Y-m-d H:i:s'),
            ])->values(),
        ]);
    }

    public function destroy(string $batchId)
    {
        DB::transaction(function () use ($batchId) {
            PollVote::where('batch_id', $batchId)->delete();
            PollOption::where('batch_id', $batchId)->delete();
            StudentNotification::where('batch_id', $batchId)
                ->where('college_id', $this->college()->id)
                ->delete();
        });

        return $this->success(null, 'تم حذف الإعلان بنجاح');
    }
}




