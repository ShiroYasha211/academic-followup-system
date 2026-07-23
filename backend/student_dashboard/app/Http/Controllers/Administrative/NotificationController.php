<?php

namespace App\Http\Controllers\Administrative;

use App\Jobs\SendBatchPushNotificationsJob;
use App\Http\Controllers\Controller;
use App\Models\StudentNotification;
use App\Models\User;
use App\Enums\UserRole;
use App\Services\PushNotificationService;
use App\Models\Academic\Major;
use App\Models\Academic\Level;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

use App\Models\PollOption;
use App\Models\PollVote;

class NotificationController extends Controller
{
    /**
     * Display a listing of notifications sent by this admin.
     */
    public function index(Request $request)
    {
        $college = auth()->user()->college;
        
        $query = StudentNotification::where('college_id', $college->id)
            ->whereNotNull('batch_id');

        // Apply filters
        $query->when($request->type, function ($q) use ($request) {
            return $q->where('type', $request->type);
        });

        $query->when($request->from_date, function ($q) use ($request) {
            return $q->whereDate('created_at', '>=', $request->from_date);
        });

        $query->when($request->to_date, function ($q) use ($request) {
            return $q->whereDate('created_at', '<=', $request->to_date);
        });

        $broadcasts = $query->select('batch_id', 'title', 'type', 'created_at', DB::raw('count(*) as total_count'), DB::raw('count(read_at) as read_count'))
            ->groupBy('batch_id', 'title', 'type', 'created_at')
            ->latest()
            ->paginate(10)
            ->withQueryString();

        return view('administrative.notifications.index', compact('broadcasts'));
    }

    /**
     * Show the form for creating a new notification.
     */
    public function create()
    {
        $college = auth()->user()->college;
        $majors = Major::where('college_id', $college->id)->get();
        return view('administrative.notifications.create', compact('majors'));
    }

    /**
     * Store a newly created notification (Broadcast).
     */
    public function store(Request $request)
    {
        $admin = auth()->user();
        $college = $admin->college;

        $request->validate([
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
            'attachment' => 'nullable|file|mimes:pdf,doc,docx,jpg,jpeg,png|max:10240', // 10MB max
            'poll_options' => 'required_if:type,poll|array|min:2',
            'poll_options.*' => 'required_if:type,poll|string|max:255',
        ]);

        $query = User::where('college_id', $college->id);

        if ($request->target == 'major') {
            $query->where('id', '!=', $admin->id);
            $query->where('major_id', $request->major_id);
        } elseif ($request->target == 'level') {
            $query->where('id', '!=', $admin->id);
            $query->where('level_id', $request->level_id);
        } elseif ($request->target == 'doctors') {
            $query->where('role', UserRole::DOCTOR);
        } elseif ($request->target == 'delegates') {
            $query->where('id', '!=', $admin->id);
            $query->whereIn('role', [UserRole::DELEGATE, UserRole::PRACTICAL_DELEGATE]);
        } else {
            $query->where('id', '!=', $admin->id);
        }

        $users = $query->get();

        if ($admin->isDoctorWithAdministrativeAccess()) {
            $users = $users->push($admin)->unique('id')->values();
        }

        if ($users->isEmpty()) {
            return back()->with('error', "لا يوجد مستخدمين ضمن الفئة المستهدفة.")->withInput();
        }

        $attachmentPath = null;
        $attachmentName = null;
        if ($request->hasFile('attachment')) {
            $file = $request->file('attachment');
            $attachmentName = $file->getClientOriginalName();
            $attachmentPath = $file->store('notifications/attachments', 'public');
        }

        $batchId = Str::uuid()->toString();
        
        DB::transaction(function () use ($request, $users, $college, $admin, $batchId, $attachmentPath, $attachmentName) {
            $data = [];
            foreach ($users as $user) {
                $data[] = [
                    'user_id' => $user->id,
                    'college_id' => $college->id,
                    'sender_id' => $admin->id,
                    'batch_id' => $batchId,
                    'type' => $request->type,
                    'title' => $request->title,
                    'message' => $request->message,
                    'attachment_path' => $attachmentPath,
                    'attachment_name' => $attachmentName,
                    'created_at' => now(),
                    'updated_at' => now(),
                ];
            }

            foreach (array_chunk($data, 500) as $chunk) {
                StudentNotification::insert($chunk);
            }

            if ($request->type === 'poll') {
                foreach ($request->poll_options as $optionText) {
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

        return redirect()->route('administrative.notifications.index')
            ->with('success', "تم إرسال " . ($request->type === 'poll' ? "الاستفتاء" : "التنبيه") . " إلى " . count($users) . " مستخدم بنجاح.");
    }

    /**
     * Show details of a specific broadcast.
     */
    public function show($batchId)
    {
        $college = auth()->user()->college;
        
        $notifications = StudentNotification::where('batch_id', $batchId)
            ->where('college_id', $college->id)
            ->get();

        if ($notifications->isEmpty()) {
            abort(404);
        }

        $first = $notifications->first();
        
        $stats = [
            'title' => $first->title,
            'message' => $first->message,
            'type' => $first->type,
            'attachment_path' => $first->attachment_path,
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
                    'text' => $option->option_text,
                    'count' => $count,
                    'percentage' => $totalVotes > 0 ? round(($count / $totalVotes) * 100, 1) : 0,
                ];
            }
        }

        return view('administrative.notifications.show', compact('notifications', 'stats', 'batchId'));
    }

    /**
     * Remove the specified broadcast.
     */
    public function destroy($batchId)
    {
        $college = auth()->user()->college;

        DB::transaction(function () use ($batchId, $college) {
            // Delete votes if it's a poll
            PollVote::where('batch_id', $batchId)->delete();
            
            // Delete poll options
            PollOption::where('batch_id', $batchId)->delete();

            // Delete the notifications themselves
            StudentNotification::where('batch_id', $batchId)
                ->where('college_id', $college->id)
                ->delete();
        });


        return redirect()->route('administrative.notifications.index')
            ->with('success', "تم حذف الإعلان وجميع البيانات المرتبطة به بنجاح.");
    }
}


