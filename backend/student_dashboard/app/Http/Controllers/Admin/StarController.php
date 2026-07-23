<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\StarTransaction;
use App\Models\Academic\University;
use App\Models\Academic\College;
use App\Models\Academic\Major;
use App\Models\Academic\Level;
use App\Models\StudentNotification;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class StarController extends Controller
{
    /**
     * Display student search and star granting interface.
     */
    public function index(Request $request)
    {
        $universities = University::all();

        // ── Students Tab filters ──────────────────────────────────────────
        $query = User::whereIn('role', ['student', 'delegate', 'practical_delegate']);

        if ($request->filled('university_id')) $query->where('university_id', $request->university_id);
        if ($request->filled('college_id'))    $query->where('college_id', $request->college_id);
        if ($request->filled('major_id'))      $query->where('major_id', $request->major_id);
        if ($request->filled('level_id'))      $query->where('level_id', $request->level_id);
        if ($request->filled('role_filter'))   $query->where('role', $request->role_filter);
        if ($request->filled('status_filter')) $query->where('status', $request->status_filter);
        if ($request->filled('search')) {
            $s = $request->search;
            $query->where(fn($q) => $q->where('name', 'like', "%{$s}%")
                                      ->orWhere('email', 'like', "%{$s}%")
                                      ->orWhere('student_number', 'like', "%{$s}%"));
        }

        $students = $query->with(['university', 'college', 'major', 'level'])
            ->latest()
            ->paginate(20)
            ->withQueryString();

        // ── Honor Board Tab filters ───────────────────────────────────────
        $honorQuery = User::whereIn('role', ['student', 'delegate', 'practical_delegate'])
            ->where('stars_balance', '>', 0);

        if ($request->filled('h_university_id')) $honorQuery->where('university_id', $request->h_university_id);
        if ($request->filled('h_college_id'))    $honorQuery->where('college_id', $request->h_college_id);
        if ($request->filled('h_major_id'))      $honorQuery->where('major_id', $request->h_major_id);
        if ($request->filled('h_level_id'))      $honorQuery->where('level_id', $request->h_level_id);
        if ($request->filled('h_role_filter'))   $honorQuery->where('role', $request->h_role_filter);
        if ($request->filled('h_min_stars'))     $honorQuery->where('stars_balance', '>=', (int)$request->h_min_stars);

        $honorBoard = $honorQuery
            ->with(['university', 'college', 'major', 'level'])
            ->orderByDesc('stars_balance')
            ->orderByDesc('total_stars_earned')
            ->orderBy('name')
            ->limit(50)
            ->get();

        $honorStats = [
            'count'         => $honorBoard->count(),
            'total_balance' => $honorBoard->sum('stars_balance'),
            'top_balance'   => (int) ($honorBoard->first()?->stars_balance ?? 0),
        ];

        // ── Global Summary Stats ──────────────────────────────────────────
        $summaryStats = [
            'total_stars'         => (int) User::whereIn('role', ['student', 'delegate', 'practical_delegate'])->sum('stars_balance'),
            'students_with_stars' => User::whereIn('role', ['student', 'delegate', 'practical_delegate'])->where('stars_balance', '>', 0)->count(),
            'top_balance'         => (int) (User::whereIn('role', ['student', 'delegate', 'practical_delegate'])->max('stars_balance') ?? 0),
            'today_granted'       => (int) StarTransaction::where('type', 'admin_grant')
                                        ->whereDate('created_at', today())
                                        ->sum('amount'),
        ];

        return view('admin.stars.index', compact(
            'students',
            'honorBoard',
            'honorStats',
            'summaryStats',
            'universities'
        ));
    }

    /**
     * Grant stars to selected students.
     */
    public function grant(Request $request)
    {
        $request->validate([
            'student_ids' => 'required|array',
            'student_ids.*' => 'exists:users,id',
            'amount'      => 'required|integer|min:-1000|max:1000',
            'description' => 'required|string|max:255',
        ]);

        if ((int) $request->amount === 0) {
            return back()->with('error', 'يجب أن لا تكون قيمة النجوم صفرًا.');
        }

        $admin = Auth::user();
        $count = 0;

        DB::beginTransaction();
        try {
            foreach ($request->student_ids as $studentId) {
                $student = User::find($studentId);
                if (!$student) continue;

                if ($request->amount > 0) {
                    $student->addStars($request->amount, 'admin_grant', $admin->id, $request->description);
                } elseif ($request->amount < 0) {
                    $student->deductStars($request->amount, 'penalty', $admin->id, $request->description);
                }

                if ($request->amount !== 0) {
                    $this->notifyStudent($student, (int) $request->amount, $request->description, $admin->id);
                }

                $count++;
            }

            DB::commit();
            $actionWord = $request->amount > 0 ? 'منح' : 'خصم';
            return back()->with('success', "تم {$actionWord} " . abs((int) $request->amount) . " نجوم بنجاح لـ {$count} مستخدم.");
        } catch (\Exception $e) {
            DB::rollBack();
            return back()->with('error', 'حدث خطأ أثناء تنفيذ عملية النجوم: ' . $e->getMessage());
        }
    }

    private function notifyStudent(User $student, int $amount, string $description, int $adminId): void
    {
        $absoluteAmount = abs($amount);
        $isGrant = $amount > 0;

        StudentNotification::create([
            'user_id' => $student->id,
            'sender_id' => $adminId,
            'type' => 'stars',
            'title' => $isGrant ? '⭐ منحة نجوم من الإدارة' : 'خصم نجوم من الإدارة',
            'message' => $isGrant
                ? "تم منحك {$absoluteAmount} نجمة من الإدارة. السبب: {$description}"
                : "تم خصم {$absoluteAmount} نجمة من رصيدك من الإدارة. السبب: {$description}",
            'data' => [
                'amount' => $amount,
                'description' => $description,
                'source' => 'admin_stars',
                'screen' => 'stars',
                'target_screen' => 'stars',
            ],
        ]);
    }
}
