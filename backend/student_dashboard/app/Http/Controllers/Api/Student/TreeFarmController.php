<?php

namespace App\Http\Controllers\Api\Student;

use App\Http\Controllers\Controller;
use App\Models\Setting;
use App\Models\Student\TreeFarmPlant;
use App\Models\Student\TreeFarmProfile;
use App\Models\Student\TreeFarmRewardRequest;
use App\Models\Student\TreeFarmSession;
use App\Models\Student\TreeFarmThought;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class TreeFarmController extends Controller
{
    private const HEARTBEAT_SECONDS = 30;
    private const OFFLINE_WINDOW_HOURS = 24;
    private const CONVERSION_RATE = 25;

    private const PLANTS = [
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

    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $profile = $this->profileFor($user);

        return response()->json($this->summary($user, $profile));
    }

    public function leaderboard(Request $request): JsonResponse
    {
        return response()->json([
            'leaderboard' => $this->leaderboardRows($request->user()),
        ]);
    }

    public function publicFarm(Request $request): JsonResponse
    {
        $user = $request->user();

        return response()->json([
            'rows'  => $this->publicFarmRows($user),
            'stats' => $this->publicFarmStats($user),
        ]);
    }

    public function updateProfile(Request $request): JsonResponse
    {
        $data = $request->validate([
            'public_name' => ['nullable', 'string', 'max:40'],
            'is_public' => ['sometimes', 'boolean'],
            'use_alias' => ['sometimes', 'boolean'],
        ]);

        $profile = $this->profileFor($request->user());
        $profile->update($data);

        return response()->json([
            'message' => 'تم تحديث إعدادات المزرعة',
            'profile' => $this->formatProfile($profile->fresh(), $request->user()),
        ]);
    }

    public function start(Request $request): JsonResponse
    {
        $data = $request->validate([
            'farm_scope' => ['required', Rule::in(['private', 'public'])],
            'planned_minutes' => ['required', 'integer', 'min:10', 'max:240'],
            'client_uuid' => ['nullable', 'string', 'max:80'],
        ]);

        $user = $request->user();

        $active = TreeFarmSession::query()
            ->where('user_id', $user->id)
            ->where('status', 'active')
            ->latest()
            ->first();

        if ($active) {
            return response()->json([
                'message' => 'لديك جلسة تركيز نشطة بالفعل',
                'session' => $this->formatSession($active),
            ], 409);
        }

        if (!empty($data['client_uuid'])) {
            $existing = TreeFarmSession::where('client_uuid', $data['client_uuid'])->first();
            if ($existing) {
                return response()->json(['session' => $this->formatSession($existing)]);
            }
        }

        $session = TreeFarmSession::create([
            'user_id' => $user->id,
            'client_uuid' => $data['client_uuid'] ?? null,
            'farm_scope' => $data['farm_scope'],
            'source' => 'online',
            'status' => 'active',
            'started_at' => now(),
            'planned_seconds' => $data['planned_minutes'] * 60,
            'focused_seconds' => 0,
            'heartbeat_count' => 0,
            'grace_seconds_used' => 0,
        ]);

        return response()->json([
            'message' => 'بدأت جلسة التركيز',
            'session' => $this->formatSession($session),
        ], 201);
    }

    public function heartbeat(Request $request, TreeFarmSession $session): JsonResponse
    {
        $this->assertOwnedSession($request, $session);

        if ($session->status !== 'active') {
            return response()->json(['message' => 'جلسة التركيز لم تعد نشطة'], 422);
        }

        $session->increment('heartbeat_count');
        $session->forceFill(['last_heartbeat_at' => now()])->save();

        return response()->json(['session' => $this->formatSession($session->fresh())]);
    }

    public function grace(Request $request, TreeFarmSession $session): JsonResponse
    {
        $this->assertOwnedSession($request, $session);

        $data = $request->validate([
            'seconds' => ['required', 'integer', 'min:60', 'max:180'],
        ]);

        if ($session->status !== 'active') {
            return response()->json(['message' => 'جلسة التركيز لم تعد نشطة'], 422);
        }

        $remaining = max(0, 180 - (int) $session->grace_seconds_used);
        if ($remaining === 0) {
            return response()->json(['message' => 'تم استخدام مهلة الخروج المتاحة لهذه الجلسة'], 422);
        }

        $session->update([
            'grace_seconds_used' => (int) $session->grace_seconds_used + min($remaining, (int) $data['seconds']),
        ]);

        return response()->json([
            'message' => 'تم تسجيل المهلة',
            'session' => $this->formatSession($session->fresh()),
        ]);
    }

    public function finish(Request $request, TreeFarmSession $session): JsonResponse
    {
        $this->assertOwnedSession($request, $session);

        $request->validate([
            'finish_reason' => ['nullable', Rule::in(['completed', 'interrupted', 'burned'])],
        ]);

        if ($session->status !== 'active') {
            return response()->json([
                'message' => 'تم إنهاء هذه الجلسة مسبقًا',
                'session' => $this->formatSession($session),
            ]);
        }

        $profile = $this->profileFor($request->user());

        $result = DB::transaction(function () use ($session, $profile) {
            $focusedSeconds = $this->trustedFocusSeconds($session, now());
            return $this->completeSession($session, $profile, $focusedSeconds, 'completed');
        });

        return response()->json(array_merge([
            'message' => $result['plant'] ? 'تمت إضافة الشجرة إلى مزرعتك' : 'انتهت الجلسة قبل الحد الأدنى للشجرة',
        ], $result, [
            'summary' => $this->summary($request->user(), $profile->fresh()),
        ]));
    }

    public function offlineSync(Request $request): JsonResponse
    {
        $data = $request->validate([
            'sessions' => ['nullable', 'array'],
            'sessions.*.client_uuid' => ['required', 'string', 'max:80'],
            'sessions.*.farm_scope' => ['required', Rule::in(['private', 'public'])],
            'sessions.*.planned_seconds' => ['required', 'integer', 'min:600', 'max:14400'],
            'sessions.*.started_at' => ['required', 'date'],
            'sessions.*.ended_at' => ['required', 'date'],
            'sessions.*.heartbeat_count' => ['required', 'integer', 'min:0', 'max:28800'],
            'sessions.*.grace_seconds_used' => ['nullable', 'integer', 'min:0', 'max:180'],
            'sessions.*.subject_id' => ['nullable', 'integer', 'exists:subjects,id'],
            'sessions.*.subject_name' => ['nullable', 'string', 'max:255'],
            'thoughts' => ['nullable', 'array'],
            'thoughts.*.client_uuid' => ['required', 'string', 'max:80'],
            'thoughts.*.body' => ['required', 'string', 'max:1000'],
            'thoughts.*.reminder_at' => ['nullable', 'date'],
        ]);

        $user = $request->user();
        $profile = $this->profileFor($user);
        $accepted = [];
        $rejected = [];
        $syncedThoughts = [];

        DB::transaction(function () use ($data, $user, $profile, &$accepted, &$rejected, &$syncedThoughts) {
            foreach ($data['sessions'] ?? [] as $payload) {
                $existing = TreeFarmSession::where('client_uuid', $payload['client_uuid'])->first();
                if ($existing) {
                    $accepted[] = $this->formatSession($existing);
                    continue;
                }

                $startedAt = Carbon::parse($payload['started_at']);
                $endedAt = Carbon::parse($payload['ended_at']);

                $session = TreeFarmSession::create([
                    'user_id' => $user->id,
                    'subject_id' => $payload['subject_id'] ?? null,
                    'subject_name' => $payload['subject_name'] ?? null,
                    'client_uuid' => $payload['client_uuid'],
                    'farm_scope' => $payload['farm_scope'],
                    'source' => 'offline',
                    'status' => 'pending_sync',
                    'started_at' => $startedAt,
                    'ended_at' => $endedAt,
                    'planned_seconds' => $payload['planned_seconds'],
                    'heartbeat_count' => $payload['heartbeat_count'],
                    'grace_seconds_used' => $payload['grace_seconds_used'] ?? 0,
                ]);

                $rejectionReason = $this->offlineRejectionReason($payload, $startedAt, $endedAt);
                if ($rejectionReason) {
                    $session->update([
                        'status' => 'rejected',
                        'rejection_reason' => $rejectionReason,
                        'synced_at' => now(),
                    ]);
                    $rejected[] = $this->formatSession($session->fresh());
                    continue;
                }

                $focusedSeconds = min(
                    (int) $payload['planned_seconds'],
                    ((int) $payload['heartbeat_count'] * self::HEARTBEAT_SECONDS) + self::HEARTBEAT_SECONDS + (int) ($payload['grace_seconds_used'] ?? 0),
                    max(0, $endedAt->diffInSeconds($startedAt))
                );

                $result = $this->completeSession($session, $profile, $focusedSeconds, 'synced');
                $accepted[] = $result['session'];
            }

            foreach ($data['thoughts'] ?? [] as $payload) {
                $thought = TreeFarmThought::firstOrCreate(
                    ['client_uuid' => $payload['client_uuid']],
                    [
                        'user_id' => $user->id,
                        'body' => $payload['body'],
                        'reminder_at' => isset($payload['reminder_at']) ? Carbon::parse($payload['reminder_at']) : null,
                        'synced_at' => now(),
                    ]
                );
                $syncedThoughts[] = $this->formatThought($thought);
            }
        });

        return response()->json([
            'accepted_sessions' => $accepted,
            'rejected_sessions' => $rejected,
            'synced_thoughts' => $syncedThoughts,
            'summary' => $this->summary($user, $profile->fresh()),
        ]);
    }

    public function storeThought(Request $request): JsonResponse
    {
        $data = $request->validate([
            'client_uuid' => ['nullable', 'string', 'max:80'],
            'session_id' => ['nullable', 'integer'],
            'body' => ['required', 'string', 'max:1000'],
            'reminder_at' => ['nullable', 'date'],
        ]);

        $thought = TreeFarmThought::create([
            'user_id' => $request->user()->id,
            'tree_farm_session_id' => $data['session_id'] ?? null,
            'client_uuid' => $data['client_uuid'] ?? null,
            'body' => $data['body'],
            'reminder_at' => isset($data['reminder_at']) ? Carbon::parse($data['reminder_at']) : null,
            'synced_at' => now(),
        ]);

        return response()->json([
            'message' => 'تم حفظ الفكرة',
            'thought' => $this->formatThought($thought),
        ], 201);
    }

    public function rewardRequest(Request $request): JsonResponse
    {
        $conversionRate = Setting::get('tree_farm_exchange_rate', 25);

        $data = $request->validate([
            'coins_amount' => ['required', 'integer', 'min:' . $conversionRate],
        ]);

        $profile = $this->profileFor($request->user());
        $pendingCoins = TreeFarmRewardRequest::query()
            ->where('user_id', $request->user()->id)
            ->where('status', 'pending')
            ->sum('coins_amount');
        $availableCoins = max(0, (int) $profile->coins_balance - (int) $pendingCoins);

        if ($data['coins_amount'] > $availableCoins) {
            return response()->json(['message' => 'رصيد العملات المتاح لا يكفي لهذا الطلب'], 422);
        }

        $stars = intdiv((int) $data['coins_amount'], $conversionRate);
        if ($stars < 1) {
            return response()->json(['message' => 'أقل طلب مكافأة هو ' . $conversionRate . ' عملة'], 422);
        }

        $weeklyLimit = Setting::get('tree_farm_weekly_star_limit', 5);
        if ($weeklyLimit > 0) {
            $startOfWeek = now()->startOfWeek();
            $starsThisWeek = TreeFarmRewardRequest::query()
                ->where('user_id', $request->user()->id)
                ->whereIn('status', ['pending', 'approved'])
                ->where('created_at', '>=', $startOfWeek)
                ->sum('stars_amount');

            if (($starsThisWeek + $stars) > $weeklyLimit) {
                $remaining = max(0, $weeklyLimit - $starsThisWeek);
                return response()->json([
                    'message' => "لقد تجاوزت الحد الأقصى الأسبوعي لاستبدال النجوم ({$weeklyLimit} نجوم). المتبقي المتاح لك هذا الأسبوع: {$remaining} نجوم."
                ], 422);
            }
        }

        $reward = TreeFarmRewardRequest::create([
            'user_id' => $request->user()->id,
            'coins_amount' => $data['coins_amount'],
            'stars_amount' => $stars,
            'conversion_rate' => $conversionRate,
            'status' => 'pending',
        ]);

        return response()->json([
            'message' => 'تم إرسال طلب المكافأة للمراجعة',
            'reward_request' => $this->formatRewardRequest($reward),
        ], 201);
    }

    public function logSession(Request $request): JsonResponse
    {
        $data = $request->validate([
            'farm_scope'      => ['required', Rule::in(['private', 'public'])],
            'focused_seconds' => ['required', 'integer', 'min:0', 'max:14400'],
            'started_at'      => ['required', 'date'],
            'ended_at'        => ['required', 'date'],
            'client_uuid'     => ['nullable', 'string', 'max:80'],
            'subject_id'      => ['nullable', 'integer', 'exists:subjects,id'],
            'subject_name'    => ['nullable', 'string', 'max:255'],
        ]);

        $user    = $request->user();
        $profile = $this->profileFor($user);

        // منع التكرار بـ client_uuid
        if (!empty($data['client_uuid'])) {
            $exists = TreeFarmSession::where('client_uuid', $data['client_uuid'])->exists();
            if ($exists) {
                return response()->json(['message' => 'تم تسجيل هذه الجلسة مسبقاً']);
            }
        }

        $result = DB::transaction(function () use ($data, $user, $profile) {
            $focusedSeconds = (int) $data['focused_seconds'];

            $session = TreeFarmSession::create([
                'user_id'          => $user->id,
                'subject_id'       => $data['subject_id'] ?? null,
                'subject_name'     => $data['subject_name'] ?? null,
                'client_uuid'      => $data['client_uuid'] ?? null,
                'farm_scope'       => $data['farm_scope'],
                'source'           => 'offline',
                'status'           => 'completed',
                'started_at'       => Carbon::parse($data['started_at']),
                'ended_at'         => Carbon::parse($data['ended_at']),
                'planned_seconds'  => $focusedSeconds,
                'focused_seconds'  => $focusedSeconds,
                'heartbeat_count'  => 0,
                'grace_seconds_used' => 0,
                'synced_at'        => now(),
            ]);

            return $this->completeSession($session, $profile, $focusedSeconds, 'completed');
        });

        return response()->json([
            'message' => $result['plant']
                ? 'تم تسجيل الجلسة وإضافة الشجرة'
                : 'تم تسجيل الجلسة',
            'plant'   => $result['plant'],
            'profile' => $this->formatProfile($profile->fresh(), $user),
        ], 201);
    }

    private function completeSession(TreeFarmSession $session, TreeFarmProfile $profile, int $focusedSeconds, string $successStatus): array
    {
        $plantDefinition = $this->plantForSeconds($focusedSeconds);
        
        if (!$plantDefinition) {
            $plantDefinition = [
                'code' => 'burned_tree',
                'name' => 'شجرة ذابلة',
                'required_seconds' => $focusedSeconds,
                'coins' => 0,
                'rarity' => 'common',
            ];
            $endedStatus = 'burned';
        } else {
            $endedStatus = $successStatus;
        }

        $session->update([
            'status' => $endedStatus,
            'ended_at' => $session->ended_at ?: now(),
            'focused_seconds' => $focusedSeconds,
            'awarded_plant_code' => $plantDefinition['code'],
            'awarded_coins' => $plantDefinition['coins'],
            'synced_at' => now(),
        ]);

        $plant = TreeFarmPlant::create([
            'user_id' => $session->user_id,
            'subject_id' => $session->subject_id,
            'subject_name' => $session->subject_name,
            'tree_farm_session_id' => $session->id,
            'farm_scope' => $session->farm_scope,
            'plant_code' => $plantDefinition['code'],
            'name' => $plantDefinition['name'],
            'rarity' => $plantDefinition['rarity'],
            'required_seconds' => $plantDefinition['required_seconds'],
            'coins_awarded' => $plantDefinition['coins'],
            'status' => 'synced',
            'planted_at' => now(),
        ]);

        if ($plantDefinition['coins'] > 0) {
            $profile->increment('coins_balance', $plantDefinition['coins']);
        }
        $profile->increment('total_focus_seconds', $focusedSeconds);
        if ($session->farm_scope === 'public') {
            $profile->increment('total_public_focus_seconds', $focusedSeconds);
        }

        return [
            'session' => $this->formatSession($session->fresh()),
            'plant' => $this->formatPlant($plant),
        ];
    }

    private function trustedFocusSeconds(TreeFarmSession $session, Carbon $endedAt): int
    {
        $elapsed = max(0, $endedAt->diffInSeconds($session->started_at));
        $heartbeatSeconds = $session->heartbeat_count > 0
            ? ((int) $session->heartbeat_count * self::HEARTBEAT_SECONDS) + self::HEARTBEAT_SECONDS + (int) $session->grace_seconds_used
            : $elapsed;

        return min((int) $session->planned_seconds, $elapsed, $heartbeatSeconds);
    }

    private function offlineRejectionReason(array $payload, Carbon $startedAt, Carbon $endedAt): ?string
    {
        if ($startedAt->lt(now()->subHours(self::OFFLINE_WINDOW_HOURS))) {
            return 'انتهت مهلة مزامنة الجلسة الأوفلاين';
        }

        if ($endedAt->lte($startedAt)) {
            return 'وقت الجلسة غير صالح';
        }

        if ((int) $payload['heartbeat_count'] <= 0) {
            return 'لا توجد نبضات تركيز كافية لاعتماد الجلسة';
        }

        return null;
    }

    private function getPlantsCatalog(): array
    {
        return Setting::get('tree_farm_plants_catalog', self::PLANTS);
    }

    private function plantForSeconds(int $seconds): ?array
    {
        $selected = null;
        foreach ($this->getPlantsCatalog() as $plant) {
            if ($seconds >= $plant['required_seconds']) {
                $selected = $plant;
            }
        }

        return $selected;
    }

    private function profileFor($user): TreeFarmProfile
    {
        return TreeFarmProfile::firstOrCreate(['user_id' => $user->id]);
    }

    private function summary($user, TreeFarmProfile $profile): array
    {
        $conversionRate = Setting::get('tree_farm_exchange_rate', 25);
        $weeklyLimit = Setting::get('tree_farm_weekly_star_limit', 5);

        $startOfWeek = now()->startOfWeek();
        $starsThisWeek = TreeFarmRewardRequest::query()
            ->where('user_id', $user->id)
            ->whereIn('status', ['pending', 'approved'])
            ->where('created_at', '>=', $startOfWeek)
            ->sum('stars_amount');

        $weeklyStarsRemaining = $weeklyLimit > 0 ? max(0, $weeklyLimit - $starsThisWeek) : null;

        return [
            'settings' => [
                'heartbeat_seconds' => self::HEARTBEAT_SECONDS,
                'offline_window_hours' => self::OFFLINE_WINDOW_HOURS,
                'conversion_rate' => $conversionRate,
                'grace_min_seconds' => 60,
                'grace_max_seconds' => 180,
                'weekly_limit' => $weeklyLimit,
                'weekly_stars_remaining' => $weeklyStarsRemaining,
            ],
            'plant_catalog' => $this->getPlantsCatalog(),
            'profile' => $this->formatProfile($profile, $user),
            'active_session' => optional(TreeFarmSession::where('user_id', $user->id)->where('status', 'active')->latest()->first(), fn ($session) => $this->formatSession($session)),
            'plants' => TreeFarmPlant::where('user_id', $user->id)->latest('planted_at')->limit(60)->get()->map(fn ($plant) => $this->formatPlant($plant))->values(),
            'reward_requests' => TreeFarmRewardRequest::where('user_id', $user->id)->latest()->limit(20)->get()->map(fn ($reward) => $this->formatRewardRequest($reward))->values(),
            'thoughts' => TreeFarmThought::where('user_id', $user->id)->latest()->limit(20)->get()->map(fn ($thought) => $this->formatThought($thought))->values(),
            'leaderboard' => $this->leaderboardRows($user),
        ];
    }

    private function leaderboardRows($user)
    {
        return TreeFarmProfile::query()
            ->with('user:id,name,major_id,level_id')
            ->where('is_public', true)
            ->whereHas('user', function ($query) use ($user) {
                $query->where('major_id', $user->major_id)->where('level_id', $user->level_id);
            })
            ->orderByDesc('total_focus_seconds')
            ->limit(30)
            ->get()
            ->values()
            ->map(function ($profile, $index) {
                return [
                    'rank'          => $index + 1,
                    'name'          => $profile->use_alias && $profile->public_name ? $profile->public_name : $profile->user?->name,
                    'focus_seconds' => (int) $profile->total_focus_seconds,
                    'coins'         => (int) $profile->coins_balance,
                ];
            });
    }

    private function publicFarmRows($user): \Illuminate\Support\Collection
    {
        return TreeFarmProfile::query()
            ->with('user:id,name,university_id')
            ->where('is_public', true)
            ->where('total_public_focus_seconds', '>', 0)
            ->whereHas('user', function ($query) use ($user) {
                $query->where('university_id', $user->university_id)
                      ->whereNotNull('university_id');
            })
            ->orderByDesc('total_public_focus_seconds')
            ->limit(100)
            ->get()
            ->values()
            ->map(function ($profile, $index) {
                return [
                    'rank'                      => $index + 1,
                    'name'                      => $profile->use_alias && $profile->public_name
                                                        ? $profile->public_name
                                                        : $profile->user?->name,
                    'public_focus_seconds'      => (int) $profile->total_public_focus_seconds,
                    'total_focus_seconds'       => (int) $profile->total_focus_seconds,
                    'coins'                     => (int) $profile->coins_balance,
                ];
            });
    }

    private function publicFarmStats($user): array
    {
        $baseQuery = TreeFarmProfile::query()
            ->where('is_public', true)
            ->where('total_public_focus_seconds', '>', 0)
            ->whereHas('user', function ($query) use ($user) {
                $query->where('university_id', $user->university_id)
                      ->whereNotNull('university_id');
            });

        $total = (clone $baseQuery)->count();
        $totalPublicSeconds = (clone $baseQuery)->sum('total_public_focus_seconds');

        return [
            'participant_count'         => $total,
            'total_public_focus_seconds'=> (int) $totalPublicSeconds,
        ];
    }

    private function formatProfile(TreeFarmProfile $profile, $user): array
    {
        return [
            'public_name' => $profile->public_name,
            'display_name' => $profile->use_alias && $profile->public_name ? $profile->public_name : $user->name,
            'is_public' => (bool) $profile->is_public,
            'use_alias' => (bool) $profile->use_alias,
            'coins_balance' => (int) $profile->coins_balance,
            'total_focus_seconds' => (int) $profile->total_focus_seconds,
            'total_public_focus_seconds' => (int) $profile->total_public_focus_seconds,
        ];
    }

    private function formatSession(TreeFarmSession $session): array
    {
        return [
            'id' => $session->id,
            'client_uuid' => $session->client_uuid,
            'subject_id' => $session->subject_id,
            'subject_name' => $session->subject_name,
            'farm_scope' => $session->farm_scope,
            'source' => $session->source,
            'status' => $session->status,
            'started_at' => optional($session->started_at)->toIso8601String(),
            'ended_at' => optional($session->ended_at)->toIso8601String(),
            'planned_seconds' => (int) $session->planned_seconds,
            'focused_seconds' => (int) $session->focused_seconds,
            'heartbeat_count' => (int) $session->heartbeat_count,
            'last_heartbeat_at' => optional($session->last_heartbeat_at)->toIso8601String(),
            'grace_seconds_used' => (int) $session->grace_seconds_used,
            'awarded_plant_code' => $session->awarded_plant_code,
            'awarded_coins' => (int) $session->awarded_coins,
            'rejection_reason' => $session->rejection_reason,
        ];
    }

    private function formatPlant(TreeFarmPlant $plant): array
    {
        return [
            'id' => $plant->id,
            'session_id' => $plant->tree_farm_session_id,
            'subject_id' => $plant->subject_id,
            'subject_name' => $plant->subject_name,
            'farm_scope' => $plant->farm_scope,
            'plant_code' => $plant->plant_code,
            'name' => $plant->name,
            'rarity' => $plant->rarity,
            'required_seconds' => (int) $plant->required_seconds,
            'coins_awarded' => (int) $plant->coins_awarded,
            'status' => $plant->status,
            'planted_at' => optional($plant->planted_at)->toIso8601String(),
        ];
    }

    private function formatRewardRequest(TreeFarmRewardRequest $reward): array
    {
        return [
            'id' => $reward->id,
            'coins_amount' => (int) $reward->coins_amount,
            'stars_amount' => (int) $reward->stars_amount,
            'conversion_rate' => (int) $reward->conversion_rate,
            'status' => $reward->status,
            'reviewed_at' => optional($reward->reviewed_at)->toIso8601String(),
            'rejection_reason' => $reward->rejection_reason,
        ];
    }

    private function formatThought(TreeFarmThought $thought): array
    {
        return [
            'id' => $thought->id,
            'client_uuid' => $thought->client_uuid,
            'body' => $thought->body,
            'reminder_at' => optional($thought->reminder_at)->toIso8601String(),
            'synced_at' => optional($thought->synced_at)->toIso8601String(),
            'created_at' => optional($thought->created_at)->toIso8601String(),
        ];
    }

    private function assertOwnedSession(Request $request, TreeFarmSession $session): void
    {
        abort_if($session->user_id !== $request->user()->id, 403);
    }
}
