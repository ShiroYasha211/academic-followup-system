<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Student\TreeFarmProfile;
use App\Models\Student\TreeFarmPlant;
use App\Models\Student\TreeFarmRewardRequest;
use App\Models\Student\TreeFarmSession;
use App\Models\Academic\College;
use App\Models\Academic\Level;
use App\Models\Academic\Major;
use App\Models\Academic\University;
use App\Models\Setting;
use App\Models\User;
use App\Models\StudentNotification;
use Illuminate\Support\Carbon;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;
use PhpOffice\PhpSpreadsheet\Spreadsheet;
use PhpOffice\PhpSpreadsheet\Style\Alignment;
use PhpOffice\PhpSpreadsheet\Style\Fill;
use PhpOffice\PhpSpreadsheet\Writer\Xlsx;
use Symfony\Component\HttpFoundation\StreamedResponse;

class TreeFarmRewardController extends Controller
{
    public function index(Request $request): View
    {
        $sortBy = $request->query('sort_by', 'focus'); // 'focus' or 'coins'

        $pendingRequests = TreeFarmRewardRequest::query()
            ->with(['user:id,name,email,student_number', 'reviewer:id,name'])
            ->where('status', 'pending')
            ->latest()
            ->paginate(10, ['*'], 'pending_page');

        $recentRequests = TreeFarmRewardRequest::query()
            ->with(['user:id,name,email,student_number', 'reviewer:id,name'])
            ->whereIn('status', ['approved', 'rejected'])
            ->latest('reviewed_at')
            ->limit(10)
            ->get();

        // Query students who have started in the tree farm
        $studentsQuery = TreeFarmProfile::query()
            ->with(['user:id,name,email,student_number']);

        if ($sortBy === 'coins') {
            $studentsQuery->orderByDesc('coins_balance');
        } else {
            $studentsQuery->orderByDesc('total_focus_seconds');
        }

        $students = $studentsQuery->paginate(15, ['*'], 'students_page');

        // Advanced Analytics
        $subjectInsights = TreeFarmSession::query()
            ->select('subject_name', 
                DB::raw('count(*) as total_sessions'),
                DB::raw('sum(focused_seconds) as total_focused_seconds')
            )
            ->whereNotNull('subject_name')
            ->where('subject_name', '!=', '')
            ->groupBy('subject_name')
            ->orderByDesc('total_focused_seconds')
            ->get();

        $totalSessions = TreeFarmSession::count();
        $failedSessions = TreeFarmSession::where('awarded_plant_code', 'burned_tree')->count();
        $successSessions = $totalSessions - $failedSessions;

        $successRate = $totalSessions > 0 ? round(($successSessions / $totalSessions) * 100, 1) : 100;
        $failRate = $totalSessions > 0 ? round(($failedSessions / $totalSessions) * 100, 1) : 0;

        $atRiskStudents = TreeFarmSession::query()
            ->select('user_id',
                DB::raw('count(*) as total_sessions'),
                DB::raw('sum(case when awarded_plant_code = "burned_tree" then 1 else 0 end) as burned_sessions')
            )
            ->with('user:id,name,email,student_number')
            ->groupBy('user_id')
            ->having('total_sessions', '>=', 3)
            ->get()
            ->map(function ($row) {
                $row->failure_rate = $row->total_sessions > 0 ? round(($row->burned_sessions / $row->total_sessions) * 100, 1) : 0;
                return $row;
            })
            ->filter(function ($row) {
                return $row->failure_rate >= 50.0;
            })
            ->sortByDesc('failure_rate');

        $exchangeRate = Setting::get('tree_farm_exchange_rate', 25);
        $weeklyStarLimit = Setting::get('tree_farm_weekly_star_limit', 5);

        $allTreeFarmStudents = User::whereIn('id', TreeFarmProfile::select('user_id'))
            ->select('id', 'name', 'student_number')
            ->orderBy('name')
            ->get();

        $publicProfilesQuery = $this->publicFarmProfilesQuery($request);
        $publicSort = $request->query('public_sort', 'focus');

        match ($publicSort) {
            'plants' => $publicProfilesQuery->orderByDesc('filtered_public_plants_count'),
            'sessions' => $publicProfilesQuery->orderByDesc('filtered_public_sessions_count'),
            'latest' => $publicProfilesQuery->orderByDesc('last_public_activity_at'),
            default => $publicProfilesQuery->orderByDesc('filtered_public_focus_seconds'),
        };

        $publicSummaryRows = (clone $publicProfilesQuery)
            ->reorder()
            ->get();

        $publicProfiles = (clone $publicProfilesQuery)
            ->paginate(15, ['*'], 'public_page')
            ->withQueryString();

        $publicStats = [
            'participants' => $publicSummaryRows->count(),
            'focus_seconds' => (int) $publicSummaryRows->sum(
                fn (TreeFarmProfile $profile) => (int) ($profile->filtered_public_focus_seconds ?? 0)
            ),
            'sessions' => (int) $publicSummaryRows->sum(
                fn (TreeFarmProfile $profile) => (int) ($profile->filtered_public_sessions_count ?? 0)
            ),
            'plants' => (int) $publicSummaryRows->sum(
                fn (TreeFarmProfile $profile) => (int) ($profile->filtered_public_plants_count ?? 0)
            ),
            'universities' => $publicSummaryRows
                ->pluck('user.university_id')
                ->filter()
                ->unique()
                ->count(),
        ];

        $publicUniversitySummary = $publicSummaryRows
            ->filter(fn (TreeFarmProfile $profile) => $profile->user?->university)
            ->groupBy(fn (TreeFarmProfile $profile) => $profile->user->university_id)
            ->map(function ($profiles) {
                $first = $profiles->first();

                return [
                    'university' => $first->user->university->name,
                    'participants' => $profiles->count(),
                    'focus_seconds' => (int) $profiles->sum(
                        fn (TreeFarmProfile $profile) => (int) ($profile->filtered_public_focus_seconds ?? 0)
                    ),
                    'sessions' => (int) $profiles->sum(
                        fn (TreeFarmProfile $profile) => (int) ($profile->filtered_public_sessions_count ?? 0)
                    ),
                    'plants' => (int) $profiles->sum(
                        fn (TreeFarmProfile $profile) => (int) ($profile->filtered_public_plants_count ?? 0)
                    ),
                ];
            })
            ->sortByDesc('focus_seconds')
            ->values();

        $publicUniversities = University::orderBy('name')->get(['id', 'name']);
        $publicColleges = College::query()
            ->when(
                $request->filled('public_university_id'),
                fn (Builder $query) => $query->where('university_id', $request->integer('public_university_id'))
            )
            ->orderBy('name')
            ->get(['id', 'name', 'university_id']);
        $publicMajors = Major::query()
            ->when(
                $request->filled('public_college_id'),
                fn (Builder $query) => $query->where('college_id', $request->integer('public_college_id'))
            )
            ->orderBy('name')
            ->get(['id', 'name', 'college_id']);
        $publicLevels = Level::query()
            ->when(
                $request->filled('public_major_id'),
                fn (Builder $query) => $query->where('major_id', $request->integer('public_major_id'))
            )
            ->orderBy('name')
            ->get(['id', 'name', 'major_id']);

        $defaultPlants = [
            ['code' => 'grass', 'name' => 'عشب البداية', 'required_seconds' => 600, 'coins' => 8, 'rarity' => 'common'],
            ['code' => 'red_flower', 'name' => 'زهرة حمراء', 'required_seconds' => 900, 'coins' => 15, 'rarity' => 'common'],
            ['code' => 'blue_flower', 'name' => 'زهرة زرقاء', 'required_seconds' => 1200, 'coins' => 20, 'rarity' => 'common'],
            ['code' => 'blue_bud', 'name' => 'برعم أزرق', 'required_seconds' => 1500, 'coins' => 25, 'rarity' => 'uncommon'],
            ['code' => 'purple_flower', 'name' => 'زهرة بنفسجية', 'required_seconds' => 1800, 'coins' => 35, 'rarity' => 'uncommon'],
            ['code' => 'pine_small', 'name' => 'صنوبرة صغيرة', 'required_seconds' => 2700, 'coins' => 55, 'rarity' => 'rare'],
            ['code' => 'pine_tall', 'name' => 'صنوبرة شامخة', 'required_seconds' => 3600, 'coins' => 80, 'rarity' => 'rare'],
            ['code' => 'orange_tree', 'name' => 'شجرة برتقالية', 'required_seconds' => 5400, 'coins' => 120, 'rarity' => 'epic'],
            ['code' => 'orange_cypress', 'name' => 'سرو برتقالي', 'required_seconds' => 7200, 'coins' => 170, 'rarity' => 'legendary'],
        ];
        $plantsCatalog = Setting::get('tree_farm_plants_catalog', $defaultPlants);

        return view('admin.tree-farm-rewards.index', compact(
            'pendingRequests', 
            'recentRequests', 
            'students',
            'sortBy',
            'subjectInsights',
            'totalSessions',
            'successSessions',
            'failedSessions',
            'successRate',
            'failRate',
            'atRiskStudents',
            'exchangeRate',
            'weeklyStarLimit',
            'allTreeFarmStudents',
            'plantsCatalog',
            'publicProfiles',
            'publicStats',
            'publicUniversitySummary',
            'publicUniversities',
            'publicColleges',
            'publicMajors',
            'publicLevels',
            'publicSort'
        ));
    }

    public function publicFarmProfile(TreeFarmProfile $profile): View
    {
        $profile->load([
            'user:id,name,email,student_number,university_id,college_id,major_id,level_id',
            'user.university:id,name',
            'user.college:id,name',
            'user.major:id,name',
            'user.level:id,name',
        ]);

        $sessions = TreeFarmSession::query()
            ->where('user_id', $profile->user_id)
            ->where('farm_scope', 'public')
            ->with('plant')
            ->latest('started_at')
            ->paginate(20);

        $plants = TreeFarmPlant::query()
            ->where('user_id', $profile->user_id)
            ->where('farm_scope', 'public')
            ->latest('planted_at')
            ->limit(60)
            ->get();
        $publicPlantsCount = TreeFarmPlant::query()
            ->where('user_id', $profile->user_id)
            ->where('farm_scope', 'public')
            ->count();

        return view('admin.tree-farm-rewards.public-profile', compact(
            'profile',
            'sessions',
            'plants',
            'publicPlantsCount'
        ));
    }

    public function togglePublicVisibility(TreeFarmProfile $profile): RedirectResponse
    {
        $profile->update(['is_public' => ! $profile->is_public]);

        StudentNotification::create([
            'user_id' => $profile->user_id,
            'type' => 'tree_farm',
            'title' => $profile->is_public
                ? 'تم تفعيل ظهورك في المزرعة العامة'
                : 'تم إيقاف ظهورك في المزرعة العامة',
            'message' => $profile->is_public
                ? 'أعادت الإدارة تفعيل ظهور إنجازاتك في المزرعة العامة.'
                : 'أوقفت الإدارة ظهور إنجازاتك في المزرعة العامة. تواصل مع الإدارة إذا كنت تحتاج إلى مراجعة القرار.',
            'data' => [
                'screen' => 'tree_farm',
                'is_public' => (bool) $profile->is_public,
            ],
        ]);

        return back()->with(
            'success',
            $profile->is_public
                ? 'تم تفعيل ظهور الطالب في المزرعة العامة.'
                : 'تم إخفاء الطالب من المزرعة العامة.'
        );
    }

    public function exportPublicFarm(Request $request): StreamedResponse
    {
        $profiles = $this->publicFarmProfilesQuery($request)
            ->orderByDesc('filtered_public_focus_seconds')
            ->get();

        $spreadsheet = new Spreadsheet();
        $sheet = $spreadsheet->getActiveSheet();
        $sheet->setTitle('المزرعة العامة');
        $sheet->setRightToLeft(true);

        $headers = [
            'الترتيب',
            'اسم الطالب',
            'الاسم الظاهر',
            'الرقم الجامعي',
            'الجامعة',
            'الكلية',
            'التخصص',
            'المستوى',
            'ساعات التركيز العامة',
            'عدد الجلسات',
            'عدد النباتات',
            'آخر نشاط',
            'حالة الظهور',
        ];
        $sheet->fromArray($headers, null, 'A1');

        foreach ($profiles->values() as $index => $profile) {
            $user = $profile->user;
            $sheet->fromArray([
                $index + 1,
                $user?->name ?? 'مستخدم محذوف',
                $profile->use_alias && $profile->public_name
                    ? $profile->public_name
                    : ($user?->name ?? 'مستخدم محذوف'),
                $user?->student_number,
                $user?->university?->name,
                $user?->college?->name,
                $user?->major?->name,
                $user?->level?->name,
                round(((int) ($profile->filtered_public_focus_seconds ?? 0)) / 3600, 2),
                (int) ($profile->filtered_public_sessions_count ?? 0),
                (int) ($profile->filtered_public_plants_count ?? 0),
                $profile->last_public_activity_at
                    ? Carbon::parse($profile->last_public_activity_at)->format('Y-m-d H:i')
                    : null,
                $profile->is_public ? 'ظاهر' : 'مخفي',
            ], null, 'A' . ($index + 2));
        }

        $lastColumn = 'M';
        $lastRow = max(2, $profiles->count() + 1);
        $sheet->getStyle("A1:{$lastColumn}1")->applyFromArray([
            'font' => ['bold' => true, 'color' => ['rgb' => 'FFFFFF']],
            'fill' => [
                'fillType' => Fill::FILL_SOLID,
                'startColor' => ['rgb' => '166534'],
            ],
            'alignment' => [
                'horizontal' => Alignment::HORIZONTAL_CENTER,
                'vertical' => Alignment::VERTICAL_CENTER,
            ],
        ]);
        $sheet->getStyle("A1:{$lastColumn}{$lastRow}")
            ->getAlignment()
            ->setVertical(Alignment::VERTICAL_CENTER);
        $sheet->freezePane('A2');
        $sheet->setAutoFilter("A1:{$lastColumn}{$lastRow}");

        foreach (range('A', $lastColumn) as $column) {
            $sheet->getColumnDimension($column)->setAutoSize(true);
        }

        $filename = 'public_tree_farm_' . now()->format('Y-m-d_H-i') . '.xlsx';

        return response()->streamDownload(function () use ($spreadsheet) {
            (new Xlsx($spreadsheet))->save('php://output');
            $spreadsheet->disconnectWorksheets();
        }, $filename, [
            'Content-Type' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ]);
    }

    private function publicFarmProfilesQuery(Request $request): Builder
    {
        $request->validate([
            'public_search' => ['nullable', 'string', 'max:120'],
            'public_university_id' => ['nullable', 'integer', 'exists:universities,id'],
            'public_college_id' => ['nullable', 'integer', 'exists:colleges,id'],
            'public_major_id' => ['nullable', 'integer', 'exists:majors,id'],
            'public_level_id' => ['nullable', 'integer', 'exists:levels,id'],
            'public_from' => ['nullable', 'date'],
            'public_to' => ['nullable', 'date', 'after_or_equal:public_from'],
            'public_visibility' => ['nullable', 'in:public,hidden,all'],
            'public_sort' => ['nullable', 'in:focus,plants,sessions,latest'],
        ]);

        $from = $request->date('public_from');
        $to = $request->date('public_to');

        $sessionFilter = function (Builder $query) use ($from, $to) {
            $query->where('focused_seconds', '>', 0)
                ->when($from, fn (Builder $builder) => $builder->whereDate('started_at', '>=', $from))
                ->when($to, fn (Builder $builder) => $builder->whereDate('started_at', '<=', $to));
        };

        $plantFilter = function (Builder $query) use ($from, $to) {
            $query->when($from, fn (Builder $builder) => $builder->whereDate('planted_at', '>=', $from))
                ->when($to, fn (Builder $builder) => $builder->whereDate('planted_at', '<=', $to));
        };

        return TreeFarmProfile::query()
            ->with([
                'user:id,name,email,student_number,university_id,college_id,major_id,level_id',
                'user.university:id,name',
                'user.college:id,name',
                'user.major:id,name',
                'user.level:id,name',
            ])
            ->whereHas('publicSessions', $sessionFilter)
            ->when(
                $request->query('public_visibility', 'public') === 'public',
                fn (Builder $query) => $query->where('is_public', true)
            )
            ->when(
                $request->query('public_visibility') === 'hidden',
                fn (Builder $query) => $query->where('is_public', false)
            )
            ->when($request->filled('public_search'), function (Builder $query) use ($request) {
                $search = trim((string) $request->query('public_search'));
                $query->where(function (Builder $builder) use ($search) {
                    $builder->where('public_name', 'like', "%{$search}%")
                        ->orWhereHas('user', function (Builder $userQuery) use ($search) {
                            $userQuery->where('name', 'like', "%{$search}%")
                                ->orWhere('email', 'like', "%{$search}%")
                                ->orWhere('student_number', 'like', "%{$search}%");
                        });
                });
            })
            ->whereHas('user', function (Builder $query) use ($request) {
                $query
                    ->when(
                        $request->filled('public_university_id'),
                        fn (Builder $builder) => $builder->where('university_id', $request->integer('public_university_id'))
                    )
                    ->when(
                        $request->filled('public_college_id'),
                        fn (Builder $builder) => $builder->where('college_id', $request->integer('public_college_id'))
                    )
                    ->when(
                        $request->filled('public_major_id'),
                        fn (Builder $builder) => $builder->where('major_id', $request->integer('public_major_id'))
                    )
                    ->when(
                        $request->filled('public_level_id'),
                        fn (Builder $builder) => $builder->where('level_id', $request->integer('public_level_id'))
                    );
            })
            ->withCount([
                'publicSessions as filtered_public_sessions_count' => $sessionFilter,
                'publicPlants as filtered_public_plants_count' => $plantFilter,
            ])
            ->withSum([
                'publicSessions as filtered_public_focus_seconds' => $sessionFilter,
            ], 'focused_seconds')
            ->withMax([
                'publicSessions as last_public_activity_at' => $sessionFilter,
            ], 'started_at');
    }

    public function approve(TreeFarmRewardRequest $reward): RedirectResponse
    {
        if ($reward->status !== 'pending') {
            return back()->with('error', 'تمت مراجعة هذا الطلب مسبقًا.');
        }

        DB::transaction(function () use ($reward) {
            $profile = TreeFarmProfile::where('user_id', $reward->user_id)->lockForUpdate()->first();

            if (!$profile || $profile->coins_balance < $reward->coins_amount) {
                $reward->update([
                    'status' => 'rejected',
                    'reviewed_by' => auth()->id(),
                    'reviewed_at' => now(),
                    'rejection_reason' => 'رصيد العملات لم يعد كافيًا عند المراجعة.',
                ]);

                StudentNotification::create([
                    'user_id' => $reward->user_id,
                    'type' => 'tree_farm',
                    'title' => '❌ رفض طلب استبدال النجوم',
                    'message' => 'للأسف، تم رفض طلبك لاستبدال ' . number_format($reward->coins_amount) . ' عملة. السبب: رصيد العملات لم يعد كافياً عند المراجعة.',
                    'data' => [
                        'coins_amount' => $reward->coins_amount,
                        'stars_amount' => $reward->stars_amount,
                        'status' => 'rejected',
                    ],
                ]);

                return;
            }

            $profile->decrement('coins_balance', $reward->coins_amount);
            $reward->user->addStars(
                $reward->stars_amount,
                'admin_grant',
                auth()->id(),
                'مكافأة مزرعة الأشجار',
                $reward
            );

            $reward->update([
                'status' => 'approved',
                'reviewed_by' => auth()->id(),
                'reviewed_at' => now(),
                'rejection_reason' => null,
            ]);

            StudentNotification::create([
                'user_id' => $reward->user_id,
                'type' => 'tree_farm',
                'title' => '🎉 اعتماد استبدال النجوم',
                'message' => "تمت الموافقة على طلبك لاستبدال " . number_format($reward->coins_amount) . " عملة بـ " . number_format($reward->stars_amount) . " نجوم. مبروك!",
                'data' => [
                    'coins_amount' => $reward->coins_amount,
                    'stars_amount' => $reward->stars_amount,
                    'status' => 'approved',
                ],
            ]);
        });

        return back()->with('success', 'تم اعتماد طلب المكافأة وتحويل العملات إلى نجوم.');
    }

    public function reject(Request $request, TreeFarmRewardRequest $reward): RedirectResponse
    {
        if ($reward->status !== 'pending') {
            return back()->with('error', 'تمت مراجعة هذا الطلب مسبقًا.');
        }

        $data = $request->validate([
            'rejection_reason' => ['nullable', 'string', 'max:500'],
        ]);

        DB::transaction(function () use ($reward, $data) {
            $reason = $data['rejection_reason'] ?? 'تم رفض الطلب من الإدارة.';
            $reward->update([
                'status' => 'rejected',
                'reviewed_by' => auth()->id(),
                'reviewed_at' => now(),
                'rejection_reason' => $reason,
            ]);

            StudentNotification::create([
                'user_id' => $reward->user_id,
                'type' => 'tree_farm',
                'title' => '❌ رفض طلب استبدال النجوم',
                'message' => "للأسف، تم رفض طلبك لاستبدال " . number_format($reward->coins_amount) . " عملة. السبب: {$reason}",
                'data' => [
                    'coins_amount' => $reward->coins_amount,
                    'stars_amount' => $reward->stars_amount,
                    'status' => 'rejected',
                ],
            ]);
        });

        return back()->with('success', 'تم رفض طلب المكافأة.');
    }

    public function updateSettings(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'tree_farm_exchange_rate' => ['required', 'integer', 'min:1'],
            'tree_farm_weekly_star_limit' => ['required', 'integer', 'min:0'],
        ]);

        Setting::set('tree_farm_exchange_rate', $data['tree_farm_exchange_rate']);
        Setting::set('tree_farm_weekly_star_limit', $data['tree_farm_weekly_star_limit']);

        return back()->with('success', 'تم تحديث شروط تبديل المكافآت والحدود بنجاح.');
    }

    public function adjustBalance(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'user_id' => ['required', 'exists:users,id'],
            'adjustment_type' => ['required', 'in:coins,stars'],
            'action' => ['required', 'in:add,deduct'],
            'amount' => ['required', 'integer', 'min:1'],
            'description' => ['required', 'string', 'max:500'],
        ]);

        DB::transaction(function () use ($data) {
            $user = User::findOrFail($data['user_id']);
            $profile = TreeFarmProfile::firstOrCreate(['user_id' => $user->id]);
            $amount = (int)$data['amount'];

            if ($data['adjustment_type'] === 'coins') {
                if ($data['action'] === 'add') {
                    $profile->increment('coins_balance', $amount);
                } else {
                    $profile->decrement('coins_balance', min($amount, $profile->coins_balance));
                }
            } else {
                // Adjust stars
                if ($data['action'] === 'add') {
                    $user->addStars($amount, 'admin_grant', auth()->id(), $data['description']);
                } else {
                    $user->deductStars($amount, 'penalty', auth()->id(), $data['description']);
                }
            }

            // Build dynamic notification title and message based on the adjustment parameters
            if ($data['adjustment_type'] === 'coins') {
                $title = $data['action'] === 'add' ? '🪙 مكافأة عملات جديدة' : '🪙 سحب عملات من محفظتك';
                $message = $data['action'] === 'add' 
                    ? "تم منحك مكافأة إضافية قدرها " . number_format($amount) . " عملة في مزرعة الأشجار من الإدارة. ملاحظة: {$data['description']}"
                    : "تم سحب " . number_format($amount) . " عملة من رصيد مزرعتك من قبل الإدارة. السبب: {$data['description']}";
            } else {
                $title = $data['action'] === 'add' ? '⭐ منحة نجوم أكاديمية' : '🥀 خصم نجوم أكاديمية';
                $message = $data['action'] === 'add'
                    ? "تم منحك " . number_format($amount) . " نجمة أكاديمية من قبل الإدارة. ملاحظة: {$data['description']}"
                    : "تم خصم " . number_format($amount) . " نجمة من رصيدك الأكاديمي من قبل الإدارة. السبب: {$data['description']}";
            }

            StudentNotification::create([
                'user_id' => $user->id,
                'type' => 'tree_farm',
                'title' => $title,
                'message' => $message,
                'data' => [
                    'adjustment_type' => $data['adjustment_type'],
                    'action' => $data['action'],
                    'amount' => $amount,
                    'description' => $data['description'],
                ],
            ]);
        });

        $adjTypeLabel = $data['adjustment_type'] === 'coins' ? 'عملات' : 'نجوم';
        $actionLabel = $data['action'] === 'add' ? 'إضافة' : 'خصم';
        return back()->with('success', "تمت عملية {$actionLabel} {$data['amount']} {$adjTypeLabel} للطالب بنجاح.");
    }

    public function updateCatalog(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'plants' => ['required', 'array'],
            'plants.*.code' => ['required', 'string'],
            'plants.*.required_minutes' => ['required', 'integer', 'min:1'],
            'plants.*.coins' => ['required', 'integer', 'min:0'],
        ]);

        $defaultPlants = [
            ['code' => 'grass', 'name' => 'عشب البداية', 'required_seconds' => 600, 'coins' => 8, 'rarity' => 'common'],
            ['code' => 'red_flower', 'name' => 'زهرة حمراء', 'required_seconds' => 900, 'coins' => 15, 'rarity' => 'common'],
            ['code' => 'blue_flower', 'name' => 'زهرة زرقاء', 'required_seconds' => 1200, 'coins' => 20, 'rarity' => 'common'],
            ['code' => 'blue_bud', 'name' => 'برعم أزرق', 'required_seconds' => 1500, 'coins' => 25, 'rarity' => 'uncommon'],
            ['code' => 'purple_flower', 'name' => 'زهرة بنفسجية', 'required_seconds' => 1800, 'coins' => 35, 'rarity' => 'uncommon'],
            ['code' => 'pine_small', 'name' => 'صنوبرة صغيرة', 'required_seconds' => 2700, 'coins' => 55, 'rarity' => 'rare'],
            ['code' => 'pine_tall', 'name' => 'صنوبرة شامخة', 'required_seconds' => 3600, 'coins' => 80, 'rarity' => 'rare'],
            ['code' => 'orange_tree', 'name' => 'شجرة برتقالية', 'required_seconds' => 5400, 'coins' => 120, 'rarity' => 'epic'],
            ['code' => 'orange_cypress', 'name' => 'سرو برتقالي', 'required_seconds' => 7200, 'coins' => 170, 'rarity' => 'legendary'],
        ];

        $currentCatalog = Setting::get('tree_farm_plants_catalog', $defaultPlants);

        $updatedCatalog = collect($currentCatalog)->map(function ($plant) use ($data) {
            $input = collect($data['plants'])->firstWhere('code', $plant['code']);
            if ($input) {
                $plant['required_seconds'] = (int) $input['required_minutes'] * 60;
                $plant['coins'] = (int) $input['coins'];
            }
            return $plant;
        })->toArray();

        Setting::set('tree_farm_plants_catalog', $updatedCatalog);

        return back()->with('success', 'تم تحديث كتالوج البذور وأسعار النباتات بنجاح.');
    }
}
