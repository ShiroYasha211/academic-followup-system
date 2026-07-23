<?php

namespace App\Http\Controllers\Student\Clinical;

use App\Http\Controllers\Controller;
use App\Models\Clinical\BodySystem;
use App\Models\Clinical\CaseAssignment;
use App\Models\Clinical\ClinicalDepartment;
use App\Models\Clinical\DailyLogActivity;
use App\Models\Clinical\StudentDailyLog;
use App\Models\Clinical\TrainingCenter;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\Rule;

class LogbookController extends Controller
{
    public function index()
    {
        $student = Auth::user();

        $assignments = CaseAssignment::with([
            'clinicalCase.trainingCenter',
            'clinicalCase.clinicalDepartment',
            'clinicalCase.bodySystem',
            'assigner',
            'reviewer',
        ])->where('student_id', $student->id)
            ->latest()
            ->get();

        $confirmedCount = StudentDailyLog::where('student_id', $student->id)->confirmed()->count();
        $pendingCount = StudentDailyLog::where('student_id', $student->id)->whereIn('status', ['pending', 'partially_confirmed'])->count();

        $pendingLogs = StudentDailyLog::with(['trainingCenter', 'department', 'doctor'])
            ->where('student_id', $student->id)
            ->pending()
            ->latest()
            ->get();

        return view('student.clinical.index', compact('assignments', 'confirmedCount', 'pendingCount', 'pendingLogs'));
    }

    public function createDailyLog()
    {
        $student = Auth::user();
        $centers = TrainingCenter::orderBy('name')->get();
        $departments = ClinicalDepartment::orderBy('name')->get();
        $bodySystems = BodySystem::orderBy('name')->get();
        $doctors = User::where('role', 'doctor')
            ->whereHas('subjects', function ($query) use ($student) {
                $query->where('major_id', $student->major_id)
                    ->where('level_id', $student->level_id);
            })
            ->orderBy('name')
            ->get();

        return view('student.clinical.create_daily_log', compact('centers', 'departments', 'bodySystems', 'doctors'));
    }

    public function storeDailyLog(Request $request)
    {
        $student = Auth::user();
        $request->validate([
            'training_center_id' => 'required|exists:training_centers,id',
            'department_id' => 'required|exists:clinical_departments,id',
            'doctor_id' => ['required', Rule::exists('users', 'id')->where('role', 'doctor')],
            'histories' => 'nullable|array',
            'histories.*.body_system_id' => 'required|exists:body_systems,id',
            'exams' => 'nullable|array',
            'exams.*.body_system_id' => 'required|exists:body_systems,id',
            'did_round' => 'nullable',
            'rounds' => 'nullable|array',
            'rounds.*.case_name' => 'required|string|max:255',
        ]);

        $doctor = User::where('role', 'doctor')
            ->whereHas('subjects', function ($query) use ($student) {
                $query->where('major_id', $student->major_id)
                    ->where('level_id', $student->level_id);
            })
            ->findOrFail($request->doctor_id);

        $historyCount = count($request->histories ?? []);
        $examCount = count($request->exams ?? []);
        $didRound = $request->has('did_round');

        $dailyLog = StudentDailyLog::create([
            'student_id' => $student->id,
            'training_center_id' => $request->training_center_id,
            'department_id' => $request->department_id,
            'doctor_id' => $doctor->id,
            'history_count' => $historyCount,
            'exam_count' => $examCount,
            'did_round' => $didRound,
            'round_notes' => $request->round_notes,
            'qr_token' => StudentDailyLog::generateToken(),
            'status' => 'pending',
            'log_date' => now()->toDateString(),
            'log_time' => now()->toTimeString(),
        ]);

        foreach ($request->histories ?? [] as $history) {
            DailyLogActivity::create([
                'daily_log_id' => $dailyLog->id,
                'activity_type' => 'history_taking',
                'body_system_id' => $history['body_system_id'],
            ]);
        }

        foreach ($request->exams ?? [] as $exam) {
            DailyLogActivity::create([
                'daily_log_id' => $dailyLog->id,
                'activity_type' => 'clinical_examination',
                'body_system_id' => $exam['body_system_id'],
            ]);
        }

        if ($didRound) {
            foreach ($request->rounds ?? [] as $round) {
                DailyLogActivity::create([
                    'daily_log_id' => $dailyLog->id,
                    'activity_type' => 'round',
                    'case_name' => $round['case_name'],
                ]);
            }
        }

        return redirect()->route('student.clinical.show-qr', $dailyLog->id);
    }

    public function showQr($id)
    {
        $student = Auth::user();
        $dailyLog = StudentDailyLog::with(['trainingCenter', 'department', 'doctor', 'activities.bodySystem'])
            ->where('student_id', $student->id)
            ->findOrFail($id);

        return view('student.clinical.show_qr', compact('dailyLog'));
    }

    public function myLogbook()
    {
        $student = Auth::user();

        $entries = StudentDailyLog::with([
            'trainingCenter',
            'department',
            'doctor',
            'confirmedBy',
            'activities.bodySystem',
            'activities.confirmedBy',
        ])->where('student_id', $student->id)
            ->latest()
            ->paginate(20);

        return view('student.clinical.logbook', compact('entries'));
    }

    public function regenerateQr($id)
    {
        $student = Auth::user();
        $dailyLog = StudentDailyLog::where('student_id', $student->id)
            ->where('status', 'pending')
            ->findOrFail($id);

        $dailyLog->update([
            'qr_token' => StudentDailyLog::generateToken(),
            'created_at' => now(),
        ]);

        return redirect()->route('student.clinical.show-qr', $dailyLog->id)
            ->with('success', 'تم تجديد الباركود بنجاح.');
    }

    public function cancelDailyLog($id)
    {
        $student = Auth::user();
        $dailyLog = StudentDailyLog::where('student_id', $student->id)
            ->where('status', 'pending')
            ->findOrFail($id);

        $dailyLog->activities()->delete();
        $dailyLog->delete();

        return redirect()->route('student.clinical.index')
            ->with('success', 'تم حذف السجل بنجاح.');
    }

    public function submitAssignment(Request $request, CaseAssignment $assignment)
    {
        $student = Auth::user();
        abort_unless($assignment->student_id === $student->id, 403);

        if (!in_array($assignment->status, ['assigned', 'rejected'], true)) {
            return back()->with('error', 'هذه المهمة ليست متاحة للإرسال حاليًا.');
        }

        $validated = $request->validate([
            'student_completion_message' => 'required|string|min:5|max:2000',
        ]);

        $assignment->update([
            'status' => 'submitted_for_review',
            'student_completion_message' => trim($validated['student_completion_message']),
            'submitted_at' => now(),
            'reviewed_at' => null,
            'reviewed_by' => null,
            'review_notes' => null,
            'is_completed' => false,
            'completed_at' => null,
        ]);

        return back()->with('success', 'تم إرسال إنجاز المهمة إلى الدكتور للمراجعة.');
    }

    public function exportPdf()
    {
        $student = Auth::user();

        $entries = StudentDailyLog::with(['trainingCenter', 'department', 'doctor', 'confirmedBy', 'activities.bodySystem'])
            ->where('student_id', $student->id)
            ->where('status', 'confirmed')
            ->orderBy('log_date', 'asc')
            ->get();

        if ($entries->isEmpty()) {
            return redirect()->back()->with('error', 'لا يوجد سجلات معتمدة لتصديرها.');
        }

        $pdf = \Barryvdh\DomPDF\Facade\Pdf::loadView('student.clinical.pdf.student_logbook', compact('student', 'entries'));

        return $pdf->download('Clinical_Logbook_' . $student->university_id . '.pdf');
    }
}
