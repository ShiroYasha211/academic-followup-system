<?php

namespace App\Http\Controllers\Doctor\Clinical;

use App\Http\Controllers\Controller;
use App\Models\Academic\Subject;
use App\Models\Clinical\StudentDailyLog;
use App\Models\User;
use App\Services\ClinicalLogbookPortfolioService;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class LogbookScannerController extends Controller
{
    public function scanner()
    {
        return view('doctor.clinical.scanner');
    }

    public function processQr(Request $request)
    {
        $request->validate(['qr_token' => 'required|string']);

        $log = StudentDailyLog::with([
            'student',
            'trainingCenter',
            'department',
            'doctor',
            'activities.bodySystem',
            'activities.confirmedBy',
        ])->where('qr_token', $request->qr_token)
            ->where('doctor_id', Auth::id())
            ->first();

        if (!$log) {
            return response()->json(['success' => false, 'message' => 'رمز QR غير صالح.']);
        }

        if ($log->status === 'confirmed') {
            return response()->json(['success' => false, 'message' => 'هذا السجل معتمد بالكامل بالفعل.']);
        }

        if ($log->status === 'rejected') {
            return response()->json(['success' => false, 'message' => 'هذا السجل مرفوض ولا يمكن اعتماده من هذه الشاشة.']);
        }

        if ($log->status === 'pending' && $log->isExpired()) {
            return response()->json(['success' => false, 'message' => 'انتهت صلاحية رمز QR لهذا السجل.']);
        }

        return response()->json([
            'success' => true,
            'log_id' => $log->id,
            'data' => $this->serializeLog($log),
        ]);
    }

    public function confirm(Request $request)
    {
        $validated = $request->validate([
            'log_id' => 'required|exists:student_daily_logs,id',
            'action' => 'required|in:confirm,reject',
            'doctor_notes' => 'nullable|string|max:1000',
            'confirmations' => 'nullable|array',
            'confirmations.history.confirm' => 'nullable|boolean',
            'confirmations.history.diagnosis' => 'nullable|string|max:1000',
            'confirmations.exam.confirm' => 'nullable|boolean',
            'confirmations.exam.diagnosis' => 'nullable|string|max:1000',
            'confirmations.round.confirm' => 'nullable|boolean',
            'confirmations.round.diagnosis' => 'nullable|string|max:1000',
        ]);

        $log = StudentDailyLog::with('activities')
            ->where('doctor_id', Auth::id())
            ->findOrFail($validated['log_id']);

        if (!in_array($log->status, ['pending', 'partially_confirmed'], true)) {
            return response()->json(['success' => false, 'message' => 'تمت معالجة هذا السجل مسبقًا.']);
        }

        if ($validated['action'] === 'reject') {
            $log->activities()->update([
                'is_confirmed' => false,
                'diagnosis' => null,
                'confirmed_by' => null,
                'confirmed_at' => null,
            ]);

            $log->update([
                'status' => 'rejected',
                'confirmed_by' => Auth::id(),
                'confirmed_at' => now(),
                'doctor_notes' => $validated['doctor_notes'] ?? null,
            ]);

            return response()->json(['success' => true, 'message' => 'تم رفض السجل السريري.']);
        }

        $groups = $log->groupedActivities();
        $confirmations = $validated['confirmations'] ?? [];
        $selectedAny = false;

        DB::transaction(function () use ($log, $groups, $confirmations, &$selectedAny, $validated) {
            foreach ($groups as $key => $group) {
                $selection = (bool) data_get($confirmations, $key . '.confirm', false);
                if (!$selection) {
                    continue;
                }

                $selectedAny = true;
                $diagnosis = trim((string) data_get($confirmations, $key . '.diagnosis', ''));

                $log->activities()
                    ->where('activity_type', $group['activity_type'])
                    ->update([
                        'is_confirmed' => true,
                        'diagnosis' => $diagnosis !== '' ? $diagnosis : null,
                        'confirmed_by' => Auth::id(),
                        'confirmed_at' => now(),
                    ]);
            }

            if (!$selectedAny) {
                return;
            }

            $log->refresh();
            $log->syncApprovalStatus();
            $log->update([
                'confirmed_by' => Auth::id(),
                'confirmed_at' => now(),
                'doctor_notes' => $validated['doctor_notes'] ?? null,
            ]);
        });

        if (!$selectedAny) {
            return response()->json(['success' => false, 'message' => 'اختر قسمًا واحدًا على الأقل لاعتماده.']);
        }

        $log->refresh();
        $message = $log->status === 'confirmed'
            ? 'تم اعتماد جميع عناصر السجل.'
            : 'تم اعتماد جزء من عناصر السجل، وما زال المتبقي بانتظار المراجعة.';

        return response()->json([
            'success' => true,
            'message' => $message,
            'status' => $log->status,
        ]);
    }

    public function manualAttendance()
    {
        $doctorSubjects = Subject::where('doctor_id', Auth::id())
            ->select('major_id', 'level_id')
            ->distinct()
            ->get();

        $studentsQuery = User::whereIn('role', ['student', 'delegate']);
        if ($doctorSubjects->isNotEmpty()) {
            $studentsQuery->where(function ($query) use ($doctorSubjects) {
                foreach ($doctorSubjects as $subject) {
                    $query->orWhere(function ($q) use ($subject) {
                        $q->where('major_id', $subject->major_id)
                            ->where('level_id', $subject->level_id);
                    });
                }
            });
        } else {
            $studentsQuery->whereRaw('1 = 0');
        }
        $students = $studentsQuery->orderBy('name')->get();

        $trainingCenters = \App\Models\Clinical\TrainingCenter::all();
        $departments = \App\Models\Clinical\ClinicalDepartment::all();

        return view('doctor.clinical.manual_attendance', compact('students', 'trainingCenters', 'departments'));
    }

    public function storeManualAttendance(Request $request)
    {
        $request->validate([
            'student_id' => 'required|exists:users,id',
            'training_center_id' => 'required|exists:training_centers,id',
            'department_id' => 'required|exists:clinical_departments,id',
            'doctor_notes' => 'nullable|string|max:1000',
        ]);

        $doctorSubjects = Subject::where('doctor_id', Auth::id())
            ->select('major_id', 'level_id')
            ->distinct()
            ->get();

        $studentQuery = User::whereKey($request->student_id)
            ->whereIn('role', ['student', 'delegate', 'practical_delegate']);

        if ($doctorSubjects->isEmpty()) {
            $studentQuery->whereRaw('1 = 0');
        } else {
            $studentQuery->where(function ($query) use ($doctorSubjects) {
                foreach ($doctorSubjects as $subject) {
                    $query->orWhere(function ($inner) use ($subject) {
                        $inner->where('major_id', $subject->major_id)
                            ->where('level_id', $subject->level_id);
                    });
                }
            });
        }

        $studentQuery->firstOrFail();

        StudentDailyLog::create([
            'student_id' => $request->student_id,
            'training_center_id' => $request->training_center_id,
            'department_id' => $request->department_id,
            'doctor_id' => Auth::id(),
            'qr_token' => StudentDailyLog::generateToken(),
            'status' => 'confirmed',
            'confirmed_by' => Auth::id(),
            'confirmed_at' => now(),
            'doctor_notes' => $request->doctor_notes ?: 'تحضير يدوي',
            'log_date' => now()->toDateString(),
            'log_time' => now()->toTimeString(),
        ]);

        return redirect()->back()->with('success', 'تم تسجيل حضور الطالب يدويًا.');
    }

    public function records(Request $request)
    {
        $query = StudentDailyLog::with([
            'student',
            'trainingCenter',
            'department',
            'confirmedBy',
            'activities.bodySystem',
            'activities.confirmedBy',
        ])->where('doctor_id', Auth::id());

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }
        if ($request->filled('date')) {
            $query->whereDate('log_date', $request->date);
        }

        $logs = $query->latest()->paginate(20)->withQueryString();

        return view('doctor.clinical.logbook_records', compact('logs'));
    }

    public function portfolioStudents(Request $request, ClinicalLogbookPortfolioService $service)
    {
        $students = $service->studentsForDoctor(Auth::user(), $request);
        $filters = $service->filtersForDoctor(Auth::user());

        return view('doctor.clinical.logbook_portfolios.index', compact('students', 'filters'));
    }

    public function portfolioShow(Request $request, User $student, ClinicalLogbookPortfolioService $service)
    {
        $portfolio = $service->portfolioForDoctor(Auth::user(), $student, $request);
        abort_if(($portfolio['summary']['approved_activities'] ?? 0) === 0, 404);

        return view('doctor.clinical.logbook_portfolios.show', compact('portfolio'));
    }

    public function portfolioPdf(Request $request, User $student, ClinicalLogbookPortfolioService $service)
    {
        $portfolio = $service->portfolioForDoctor(Auth::user(), $student, $request);
        abort_if(($portfolio['summary']['approved_activities'] ?? 0) === 0, 404);

        $pdf = Pdf::loadView('doctor.clinical.logbook_portfolios.pdf', compact('portfolio'));
        $filename = 'clinical_portfolio_' . ($student->student_number ?: $student->id) . '_' . now()->format('Y-m-d') . '.pdf';

        return $pdf->download($filename);
    }

    public function portfolioCsv(Request $request, User $student, ClinicalLogbookPortfolioService $service)
    {
        $portfolio = $service->portfolioForDoctor(Auth::user(), $student, $request);
        abort_if(($portfolio['summary']['approved_activities'] ?? 0) === 0, 404);

        $filename = 'clinical_portfolio_' . ($student->student_number ?: $student->id) . '_' . now()->format('Y-m-d') . '.csv';
        $headers = [
            'Content-Type' => 'text/csv; charset=UTF-8',
            'Content-Disposition' => "attachment; filename={$filename}",
        ];

        return response()->streamDownload(function () use ($portfolio) {
            $handle = fopen('php://output', 'w');
            fprintf($handle, chr(0xEF) . chr(0xBB) . chr(0xBF));
            fputcsv($handle, ['نظام الجسم/المهارة', 'قصص مرضية', 'فحوصات سريرية', 'مرور', 'الإجمالي']);
            foreach ($portfolio['matrix'] as $row) {
                fputcsv($handle, [
                    $row['body_system'],
                    $row['history_taking'],
                    $row['clinical_examination'],
                    $row['round'],
                    $row['total'],
                ]);
            }
            fputcsv($handle, []);
            fputcsv($handle, ['التاريخ', 'المركز', 'القسم', 'الدكتور', 'نوع النشاط', 'النظام/الحالة', 'الملاحظات']);
            foreach ($portfolio['logs'] as $log) {
                foreach ($log['activities'] as $activity) {
                    fputcsv($handle, [
                        $log['date'],
                        $log['training_center'],
                        $log['department'],
                        $log['doctor'],
                        $activity['type_label'],
                        $activity['body_system'],
                        $activity['diagnosis'] ?: $log['doctor_notes'],
                    ]);
                }
            }
            fclose($handle);
        }, $filename, $headers);
    }

    protected function serializeLog(StudentDailyLog $log): array
    {
        $groups = [];
        foreach ($log->groupedActivities() as $key => $group) {
            $items = $group['items'];
            $groups[] = [
                'key' => $key,
                'label' => $group['label'],
                'count' => $items->count(),
                'confirmed' => $items->every(fn ($item) => (bool) $item->is_confirmed),
                'diagnosis' => $items->pluck('diagnosis')->filter()->first(),
                'items' => $items->map(function ($item) {
                    return [
                        'id' => $item->id,
                        'label' => $item->activity_type === 'round'
                            ? ($item->case_name ?: 'Round case')
                            : ($item->bodySystem->name ?? '-'),
                        'is_confirmed' => (bool) $item->is_confirmed,
                        'diagnosis' => $item->diagnosis,
                        'confirmed_at' => optional($item->confirmed_at)?->format('Y-m-d H:i'),
                    ];
                })->values(),
            ];
        }

        return [
            'student_name' => $log->student->name ?? '-',
            'student_number' => $log->student->student_number ?? '-',
            'training_center' => $log->trainingCenter->name ?? '-',
            'department' => $log->department->name ?? '-',
            'doctor_name' => $log->doctor->name ?? '-',
            'log_date' => $log->log_date->format('Y-m-d'),
            'log_time' => $log->log_time,
            'status' => $log->status,
            'status_label' => $log->status_label,
            'doctor_notes' => $log->doctor_notes,
            'groups' => $groups,
        ];
    }
}
