<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Api\BaseController;
use App\Models\StudentNotification;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class StarController extends BaseController
{
    /**
     * Display a paginated list of students eligible for star administration.
     * Applies academic filters and search queries.
     */
    public function index(Request $request)
    {
        // Must include all student-based roles
        $query = User::whereIn('role', ['student', 'delegate', 'practical_delegate']);

        // Academic Filters
        if ($request->filled('university_id')) {
            $query->where('university_id', $request->university_id);
        }
        if ($request->filled('college_id')) {
            $query->where('college_id', $request->college_id);
        }
        if ($request->filled('major_id')) {
            $query->where('major_id', $request->major_id);
        }
        if ($request->filled('level_id')) {
            $query->where('level_id', $request->level_id);
        }

        // Search Filter
        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%")
                  ->orWhere('student_number', 'like', "%{$search}%");
            });
        }

        // Include minimum relevant relationships & specific fields for lighter API responses
        $students = $query->with([
            'university:id,name',
            'college:id,name',
            'major:id,name',
            'level:id,name'
        ])
        ->select('id', 'name', 'email', 'student_number', 'role', 'status', 'stars_balance', 'total_stars_earned', 'university_id', 'college_id', 'major_id', 'level_id')
        ->latest()
        ->paginate($request->get('per_page', 20));

        return $this->success($students, 'تم جلب قائمة الطلاب وأرصدة النجوم بنجاح.');
    }

    /**
     * Grant or deduct stars in bulk to a specific set of users.
     */
    public function grant(Request $request)
    {
        $request->validate([
            'student_ids'   => 'required|array',
            'student_ids.*' => 'exists:users,id',
            'amount'        => 'required|integer|min:-2000|max:2000',
            'description'   => 'required|string|max:255',
        ]);

        if ($request->amount === 0) {
            return $this->error('يجب ان لا تكون القيمة المدخلة صفراً.', 400);
        }

        $admin = Auth::user();
        $processedCount = 0;

        DB::beginTransaction();
        try {
            foreach ($request->student_ids as $studentId) {
                $student = User::find($studentId);
                
                // Ensure we only process authorized roles
                if (!$student || !in_array($student->role, ['student', 'delegate', 'practical_delegate'])) {
                    continue;
                }

                if ($request->amount > 0) {
                    $student->addStars($request->amount, 'admin_grant', $admin->id, $request->description);
                } else {
                    $student->deductStars($request->amount, 'penalty', $admin->id, $request->description);
                }

                $this->notifyStudent($student, (int) $request->amount, $request->description, $admin->id);

                $processedCount++;
            }

            DB::commit();
            
            $actionWord = $request->amount > 0 ? 'منح' : 'خصم';
            return $this->success(null, "تم {$actionWord} النجوم بنجاح لـ {$processedCount} مستخدم.");

        } catch (\Exception $e) {
            DB::rollBack();
            return $this->error('حدث خطأ أثناء تنفيذ عملية تغيير أرصدة النجوم: ' . $e->getMessage(), 500);
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
