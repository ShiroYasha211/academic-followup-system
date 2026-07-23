<?php

namespace App\Http\Controllers\Delegate;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;
use App\Models\Academic\Subject;
use App\Models\Attendance;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use App\Enums\UserRole;

class NotificationController extends Controller
{
    public function index(Request $request)
    {
        $delegate = Auth::user();
        $filter = $request->get('filter', 'all');

        // Fetch students in scope
        $students = User::whereIn('role', [UserRole::STUDENT, UserRole::DELEGATE])
            ->where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id)
            ->get();

        $studentIds = $students->pluck('id');

        // Fetch subjects in scope
        $subjects = Subject::where('major_id', $delegate->major_id)
            ->where('level_id', $delegate->level_id)
            ->get()
            ->keyBy('id');

        // Optimized Query: Get all absences for these students matching these subjects in ONE query
        $absencesData = Attendance::whereIn('student_id', $studentIds)
            ->whereIn('subject_id', $subjects->keys())
            ->where('status', 'absent')
            ->select('student_id', 'subject_id', DB::raw('count(*) as absence_count'))
            ->groupBy('student_id', 'subject_id')
            ->get();

        $report = [];

        foreach ($absencesData as $data) {
            $student = $students->firstWhere('id', $data->student_id);
            $subject = $subjects->get($data->subject_id);

            if ($student && $subject && $data->absence_count > 0) {
                $report[] = [
                    'student' => $student,
                    'subject' => $subject,
                    'absences' => $data->absence_count,
                ];
            }
        }

        // Sort by highest absences
        usort($report, function ($a, $b) {
            return $b['absences'] <=> $a['absences'];
        });

        // Calculate stats
        $stats = [
            'total' => count($report),
            'danger' => count(array_filter($report, fn($r) => $r['absences'] >= 5)),
            'warning' => count(array_filter($report, fn($r) => $r['absences'] >= 3 && $r['absences'] < 5)),
            'normal' => count(array_filter($report, fn($r) => $r['absences'] < 3)),
        ];

        // Apply filter
        if ($filter === 'danger') {
            $report = array_filter($report, fn($r) => $r['absences'] >= 5);
        } elseif ($filter === 'warning') {
            $report = array_filter($report, fn($r) => $r['absences'] >= 3 && $r['absences'] < 5);
        } elseif ($filter === 'normal') {
            $report = array_filter($report, fn($r) => $r['absences'] < 3);
        }

        // Get sent notifications history
        $sentAlerts = DB::table('notifications')
            ->where('type', 'App\Notifications\AbsenceWarning')
            ->whereIn('notifiable_id', $students->pluck('id'))
            ->orderBy('created_at', 'desc')
            ->limit(20)
            ->get()
            ->map(function ($n) use ($students) {
                $data = json_decode($n->data, true);
                $student = $students->firstWhere('id', $n->notifiable_id);
                return [
                    'id' => $n->id,
                    'student_name' => $student ? $student->name : 'غير معروف',
                    'title' => $data['title'] ?? '',
                    'message' => $data['message'] ?? '',
                    'created_at' => $n->created_at,
                ];
            });

        return view('delegate.notifications.index', compact('report', 'stats', 'filter', 'sentAlerts'));
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'student_id' => 'required|exists:users,id',
            'subject_id' => 'required|exists:subjects,id',
            'message' => 'required|string',
        ]);

        $subject = Subject::findOrFail($validated['subject_id']);

        DB::table('notifications')->insert([
            'id' => \Illuminate\Support\Str::uuid(),
            'type' => 'App\Notifications\AbsenceWarning',
            'notifiable_type' => 'App\Models\User',
            'notifiable_id' => $validated['student_id'],
            'data' => json_encode([
                'title' => 'تنبيه غياب: ' . $subject->name,
                'message' => $validated['message'],
                'subject_id' => $subject->id,
                'sender_id' => Auth::id(),
            ]),
            'read_at' => null,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return redirect()->back()->with('success', 'تم إرسال التنبيه للطالب بنجاح.');
    }
}
