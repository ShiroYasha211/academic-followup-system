<?php

namespace App\Http\Controllers\Student;

use App\Http\Controllers\Controller;
use App\Models\FlashcardItem;
use App\Models\FlashcardPack;
use App\Models\FlashcardProgress;
use App\Models\PublicPackStore;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class FlashcardController extends Controller
{
    public function index(Request $request)
    {
        $user = Auth::user();

        $packs = FlashcardPack::forUser($user->id)
            ->whereNull('parent_pack_id')
            ->with('childPacks')
            ->latest()
            ->get();

        foreach ($packs as $pack) {
            $pack->items_count = $pack->cardsCount();
        }

        $totalPacks = $packs->count();
        $activePacks = $packs->where('is_active', true)->count();
        $totalCards = $packs->sum('items_count');

        return view('student.flashcards.index', compact('packs', 'totalPacks', 'activePacks', 'totalCards'));
    }

    public function create()
    {
        $parentPacks = $this->availableParentPacks(Auth::id());

        return view('student.flashcards.create', compact('parentPacks'));
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string|max:1000',
            'color' => 'nullable|string|max:7',
            'display_mode' => 'required|in:flash_card,one_line,qa,mcq',
            'notifications_enabled' => 'boolean',
            'daily_notification_count' => 'integer|min:1|max:50',
            'repeat_cycle' => 'required|in:daily,weekly,monthly',
            'quiet_start' => 'nullable|date_format:H:i',
            'quiet_end' => 'nullable|date_format:H:i',
            'parent_pack_id' => 'nullable|integer',
        ]);

        $parentPack = $this->resolveParentPack($validated['parent_pack_id'] ?? null, Auth::id());

        $pack = Auth::user()->flashcardPacks()->create([
            'title' => $validated['title'],
            'description' => $validated['description'] ?? null,
            'color' => $validated['color'] ?? '#4f46e5',
            'display_mode' => $validated['display_mode'],
            'notifications_enabled' => (bool) ($validated['notifications_enabled'] ?? false),
            'daily_notification_count' => $validated['daily_notification_count'] ?? 5,
            'repeat_cycle' => $validated['repeat_cycle'],
            'quiet_start' => $validated['quiet_start'] ?? null,
            'quiet_end' => $validated['quiet_end'] ?? null,
            'parent_pack_id' => $parentPack?->id,
        ]);

        return redirect()->route('student.flashcards.show', $pack)
            ->with('success', 'تم إنشاء الحزمة بنجاح. يمكنك الآن إضافة الأسئلة أو إنشاء حزم فرعية داخلها.');
    }

    public function show(FlashcardPack $flashcard)
    {
        $this->authorizeOwnership($flashcard);

        $items = $this->displayItemsForPack($flashcard)
            ->values();

        $directHighPriorityCount = $items->whereIn('priority', ['high', 'critical'])->count();
        $childPacks = $flashcard->childPacks()->latest()->get();
        foreach ($childPacks as $childPack) {
            $childPack->items_count = $childPack->cardsCount();
        }

        $parentPacks = $this->availableParentPacks(Auth::id(), $flashcard);

        return view('student.flashcards.show', compact(
            'flashcard',
            'items',
            'directHighPriorityCount',
            'childPacks',
            'parentPacks'
        ));
    }

    public function edit(FlashcardPack $flashcard)
    {
        $this->authorizeOwnership($flashcard);
        $parentPacks = $this->availableParentPacks(Auth::id(), $flashcard);

        return view('student.flashcards.edit', compact('flashcard', 'parentPacks'));
    }

    public function update(Request $request, FlashcardPack $flashcard)
    {
        $this->authorizeOwnership($flashcard);

        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string|max:1000',
            'color' => 'nullable|string|max:7',
            'display_mode' => 'required|in:flash_card,one_line,qa,mcq',
            'notifications_enabled' => 'boolean',
            'daily_notification_count' => 'integer|min:1|max:50',
            'repeat_cycle' => 'required|in:daily,weekly,monthly',
            'quiet_start' => 'nullable|date_format:H:i',
            'quiet_end' => 'nullable|date_format:H:i',
            'parent_pack_id' => 'nullable|integer',
        ]);

        $parentPack = $this->resolveParentPack($validated['parent_pack_id'] ?? null, Auth::id(), $flashcard);

        $flashcard->update([
            'title' => $validated['title'],
            'description' => $validated['description'] ?? null,
            'color' => $validated['color'] ?? '#4f46e5',
            'display_mode' => $validated['display_mode'],
            'notifications_enabled' => (bool) ($validated['notifications_enabled'] ?? false),
            'daily_notification_count' => $validated['daily_notification_count'] ?? 5,
            'repeat_cycle' => $validated['repeat_cycle'],
            'quiet_start' => $validated['quiet_start'] ?? null,
            'quiet_end' => $validated['quiet_end'] ?? null,
            'parent_pack_id' => $flashcard->is_assigned ? $flashcard->parent_pack_id : $parentPack?->id,
        ]);

        return redirect()->route('student.flashcards.show', $flashcard)
            ->with('success', 'تم تحديث الحزمة بنجاح.');
    }

    public function destroy(FlashcardPack $flashcard)
    {
        $this->authorizeOwnership($flashcard);
        $this->deletePackTree($flashcard);

        return redirect()->route('student.flashcards.index')
            ->with('success', 'تم حذف الحزمة وكل محتواها المتداخل بنجاح.');
    }

    public function toggleActive(FlashcardPack $flashcard)
    {
        $this->authorizeOwnership($flashcard);
        $flashcard->update(['is_active' => !$flashcard->is_active]);

        return back()->with('success', $flashcard->is_active ? 'تم تفعيل الحزمة.' : 'تم إيقاف الحزمة.');
    }

    public function updateSettings(Request $request, FlashcardPack $flashcard)
    {
        $this->authorizeOwnership($flashcard);

        $validated = $request->validate([
            'notifications_enabled' => 'boolean',
            'daily_notification_count' => 'integer|min:1|max:50',
            'repeat_cycle' => 'required|in:daily,weekly,monthly',
            'quiet_start' => 'nullable|date_format:H:i',
            'quiet_end' => 'nullable|date_format:H:i',
            'display_mode' => 'required|in:flash_card,one_line,qa,mcq',
        ]);

        $flashcard->update([
            'notifications_enabled' => (bool) ($validated['notifications_enabled'] ?? false),
            'daily_notification_count' => $validated['daily_notification_count'] ?? $flashcard->daily_notification_count,
            'repeat_cycle' => $validated['repeat_cycle'],
            'quiet_start' => $validated['quiet_start'] ?? null,
            'quiet_end' => $validated['quiet_end'] ?? null,
            'display_mode' => $validated['display_mode'],
        ]);

        return back()->with('success', 'تم تحديث إعدادات الحزمة بنجاح.');
    }

    public function import(Request $request, FlashcardPack $flashcard)
    {
        $this->authorizeOwnership($flashcard);
        $this->assertCanManageItems($flashcard);

        $request->validate([
            'file' => 'required|file|mimes:xlsx,csv,xls',
        ]);

        $file = $request->file('file');
        $extension = $file->getClientOriginalExtension();

        try {
            $rows = $this->parseSpreadsheet($file->getPathname(), $extension);
            $itemsCountBefore = $flashcard->items()->count();

            $items = [];
            foreach ($rows as $index => $row) {
                if (empty($row[0])) {
                    continue;
                }

                $itemData = [
                    'pack_id' => $flashcard->id,
                    'item_type' => $flashcard->display_mode,
                    'front_content' => trim((string) $row[0]),
                    'priority' => 'normal',
                    'sort_order' => $itemsCountBefore + $index,
                    'created_at' => now(),
                    'updated_at' => now(),
                ];

                switch ($flashcard->display_mode) {
                    case 'one_line':
                        $itemData['back_content'] = null;
                        break;
                    case 'mcq':
                        $options = [];
                        foreach ([1, 2, 3, 4, 5, 6] as $columnIndex) {
                            if (!empty($row[$columnIndex])) {
                                $options[] = trim((string) $row[$columnIndex]);
                            }
                        }
                        $itemData['options'] = json_encode($options);
                        $itemData['correct_option'] = isset($row[7]) && is_numeric($row[7]) ? (int) $row[7] : 0;
                        $itemData['back_content'] = null;
                        break;
                    default:
                        $itemData['back_content'] = isset($row[1]) ? trim((string) $row[1]) : null;
                        break;
                }

                $items[] = $itemData;
            }

            if (empty($items)) {
                return back()->with('error', 'الملف لا يحتوي على بيانات صالحة.');
            }

            FlashcardItem::insert($items);

            return back()->with('success', 'تم استيراد ' . count($items) . ' عنصرًا بنجاح.');
        } catch (\Exception $e) {
            return back()->with('error', 'حدث خطأ أثناء قراءة الملف: ' . $e->getMessage());
        }
    }

    public function storeItem(Request $request, FlashcardPack $flashcard)
    {
        $this->authorizeOwnership($flashcard);
        $this->assertCanManageItems($flashcard);

        $itemType = $request->input('item_type', $flashcard->display_mode);
        $validated = $this->validateItemPayload($request, $itemType);

        $flashcard->items()->create($this->mapItemData($validated, $flashcard, $itemType));

        return back()->with('success', 'تمت إضافة العنصر بنجاح.');
    }

    public function updateItem(Request $request, FlashcardItem $item)
    {
        $this->authorizeOwnership($item->pack);
        $this->assertCanManageItems($item->pack);

        $itemType = $request->input('item_type', $item->resolved_item_type);
        $validated = $this->validateItemPayload($request, $itemType);

        $item->update($this->mapItemData($validated, $item->pack, $itemType, false));

        return back()->with('success', 'تم تحديث العنصر بنجاح.');
    }

    public function destroyItem(FlashcardItem $item)
    {
        $this->authorizeOwnership($item->pack);
        $this->assertCanManageItems($item->pack);
        $item->delete();

        return back()->with('success', 'تم حذف العنصر.');
    }

    public function publicStore(Request $request)
    {
        $query = PublicPackStore::with(['pack.user:id,name', 'pack' => function ($q) {
            $q->withCount('items');
        }])
            ->where('is_active', true)
            ->whereHas('pack', fn ($q) => $q->where('is_public', true));

        if ($request->filled('display_mode')) {
            $query->whereHas('pack', function ($q) use ($request) {
                $q->where('display_mode', $request->display_mode);
            });
        }

        if ($request->filled('search')) {
            $search = $request->search;
            $query->whereHas('pack', function ($q) use ($search) {
                $q->where('title', 'like', "%{$search}%")
                    ->orWhere('description', 'like', "%{$search}%");
            });
        }

        $storeItems = $query->latest()->paginate(12)->withQueryString();
        $storeItems->getCollection()->transform(function ($storeItem) {
            $storeItem->pack->items_count = $storeItem->pack->cardsCount();

            return $storeItem;
        });

        return view('student.flashcards.store', compact('storeItems'));
    }

    public function clonePack(FlashcardPack $flashcard)
    {
        $user = Auth::user();

        $existing = FlashcardPack::where('user_id', $user->id)
            ->where('source_pack_id', $flashcard->id)
            ->whereNull('parent_pack_id')
            ->first();

        if ($existing) {
            return back()->with('info', 'لقد قمت بسحب هذه الحزمة مسبقًا.');
        }

        $newPack = DB::transaction(function () use ($flashcard, $user) {
            $newPack = $this->cloneAssignedTree($flashcard, $user->id);
            $flashcard->storeEntry?->increment('downloads_count');

            return $newPack;
        });

        return redirect()->route('student.flashcards.show', $newPack)
            ->with('success', 'تم سحب الحزمة بكل تفرعاتها بنجاح.');
    }

    public function review(FlashcardPack $flashcard)
    {
        $this->authorizeOwnership($flashcard);

        $items = $flashcard->effectiveItems()
            ->with('pack:id,title,color,display_mode')
            ->orderByRaw("FIELD(priority, 'critical', 'high', 'normal')")
            ->orderBy('sort_order')
            ->orderBy('id')
            ->get();

        $progressMap = FlashcardProgress::where('user_id', Auth::id())
            ->whereIn('item_id', $items->pluck('id'))
            ->get()
            ->keyBy('item_id');

        $items = $items
            ->map(function (FlashcardItem $item) use ($progressMap) {
                $item->user_progress = $progressMap->get($item->id);

                return $item;
            })
            ->sortBy(function (FlashcardItem $item) {
                $progress = $item->user_progress;

                return [
                    $progress?->isDue() === false ? 1 : 0,
                    $progress?->review_weight ? -1 * $progress->review_weight : -2,
                    match ($item->priority) {
                        'critical' => 0,
                        'high' => 1,
                        default => 2,
                    },
                    $item->sort_order,
                ];
            })
            ->values();

        return view('student.flashcards.review', compact('flashcard', 'items'));
    }

    public function recordProgress(Request $request)
    {
        $validated = $request->validate([
            'item_id' => 'required|exists:flashcard_items,id',
            'response_level' => 'nullable|in:easy,medium,hard',
            'is_correct' => 'nullable|boolean',
        ]);

        $responseLevel = $validated['response_level'] ?? $this->mapLegacyResponse((bool) ($validated['is_correct'] ?? false));
        $user = Auth::user();
        $item = FlashcardItem::with('pack')->findOrFail($validated['item_id']);

        if (!$this->userCanAccessItemPack($user->id, $item->pack_id)) {
            abort(403, 'ليس لديك صلاحية تسجيل التقدم لهذا العنصر.');
        }

        $progress = FlashcardProgress::firstOrCreate(
            ['user_id' => $user->id, 'item_id' => $item->id],
            ['times_shown' => 0, 'times_correct' => 0, 'review_weight' => 2]
        );

        $progress->times_shown += 1;
        if (in_array($responseLevel, ['easy', 'medium'], true)) {
            $progress->times_correct += 1;
        }

        $progress->last_response = $responseLevel;
        $progress->review_weight = match ($responseLevel) {
            'easy' => 1,
            'medium' => 2,
            'hard' => 3,
        };
        $progress->last_shown_at = now();
        $progress->next_review_at = $this->calculateNextReview($item->pack, $progress, $responseLevel);
        $progress->save();

        if ($request->wantsJson() || $request->isJson()) {
            return response()->json([
                'success' => true,
                'progress' => $progress->fresh(),
            ]);
        }

        return back()->with('success', 'تم تسجيل التقدم.');
    }

    private function authorizeOwnership(FlashcardPack $pack): void
    {
        if ($pack->user_id !== Auth::id()) {
            abort(403, 'ليس لديك صلاحية الوصول إلى هذه الحزمة.');
        }
    }

    private function availableParentPacks(int $userId, ?FlashcardPack $currentPack = null): Collection
    {
        $packs = FlashcardPack::forUser($userId)
            ->whereNull('source_pack_id')
            ->orderBy('title')
            ->get();

        if (!$currentPack) {
            return $packs;
        }

        $blockedIds = $currentPack->descendantPackIds();
        $blockedIds[] = $currentPack->id;

        return $packs->reject(fn (FlashcardPack $pack) => in_array($pack->id, $blockedIds, true))->values();
    }

    private function resolveParentPack(?int $parentPackId, int $userId, ?FlashcardPack $currentPack = null): ?FlashcardPack
    {
        if (!$parentPackId) {
            return null;
        }

        $parentPack = FlashcardPack::where('id', $parentPackId)
            ->where('user_id', $userId)
            ->whereNull('source_pack_id')
            ->firstOrFail();

        if ($currentPack && in_array($parentPack->id, $currentPack->descendantPackIds(), true)) {
            abort(422, 'لا يمكن نقل الحزمة داخل إحدى الحزم التابعة لها.');
        }

        return $parentPack;
    }

    private function assertCanManageItems(FlashcardPack $pack): void
    {
        if ($pack->is_assigned) {
            abort(422, 'الحزم المعيّنة من المتجر أو الإدارة لا تقبل تعديل العناصر مباشرة. عدّل المصدر أو أنشئ حزمة خاصة بك.');
        }
    }

    private function validateItemPayload(Request $request, string $itemType): array
    {
        $rules = [
            'item_type' => 'nullable|in:flash_card,one_line,qa,mcq',
            'front_content' => 'required|string',
            'item_color' => 'nullable|string|max:7',
            'priority' => 'required|in:normal,high,critical',
        ];

        if ($itemType === 'mcq') {
            $rules['options'] = 'required|array|min:2|max:6';
            $rules['options.*'] = 'required|string|max:500';
            $rules['correct_option'] = 'required|integer|min:0';
        } elseif ($itemType !== 'one_line') {
            $rules['back_content'] = 'required|string';
        }

        return $request->validate($rules);
    }

    private function mapItemData(array $validated, FlashcardPack $pack, string $itemType, bool $isCreate = true): array
    {
        $data = [
            'item_type' => $itemType,
            'front_content' => $validated['front_content'],
            'back_content' => $itemType === 'one_line' || $itemType === 'mcq' ? null : ($validated['back_content'] ?? null),
            'item_color' => $validated['item_color'] ?? null,
            'priority' => $validated['priority'],
        ];

        if ($isCreate) {
            $data['sort_order'] = $pack->items()->count();
        }

        if ($itemType === 'mcq') {
            $options = array_values(array_filter($validated['options'] ?? [], fn ($option) => $option !== null && $option !== ''));
            $data['options'] = $options;
            $data['correct_option'] = (int) ($validated['correct_option'] ?? 0);
        } else {
            $data['options'] = null;
            $data['correct_option'] = null;
        }

        return $data;
    }

    private function displayItemsForPack(FlashcardPack $pack): Collection
    {
        if ($pack->is_assigned && $pack->sourcePack) {
            return $pack->sourcePack->items()->with('pack:id,title,color,display_mode')->get();
        }

        return $pack->items()->with('pack:id,title,color,display_mode')->get();
    }

    private function deletePackTree(FlashcardPack $pack): void
    {
        $pack->load('childPacks');

        foreach ($pack->childPacks as $childPack) {
            $this->deletePackTree($childPack);
        }

        $pack->delete();
    }

    private function cloneAssignedTree(FlashcardPack $sourcePack, int $userId, ?int $parentCloneId = null): FlashcardPack
    {
        $clone = $sourcePack->replicate(['user_id', 'is_public', 'source_pack_id', 'parent_pack_id']);
        $clone->user_id = $userId;
        $clone->is_public = false;
        $clone->source_pack_id = $sourcePack->id;
        $clone->parent_pack_id = $parentCloneId;
        $clone->save();

        $sourcePack->loadMissing('childPacks');
        foreach ($sourcePack->childPacks as $childPack) {
            $this->cloneAssignedTree($childPack, $userId, $clone->id);
        }

        return $clone;
    }

    private function parseSpreadsheet(string $path, string $extension): array
    {
        $rows = [];

        if ($extension === 'csv') {
            $handle = fopen($path, 'r');
            $isFirst = true;
            while (($data = fgetcsv($handle)) !== false) {
                if ($isFirst && $this->looksLikeHeader($data)) {
                    $isFirst = false;
                    continue;
                }
                $isFirst = false;
                $rows[] = $data;
            }
            fclose($handle);
        } else {
            if (class_exists('\PhpOffice\PhpSpreadsheet\IOFactory')) {
                $spreadsheet = \PhpOffice\PhpSpreadsheet\IOFactory::load($path);
                $worksheet = $spreadsheet->getActiveSheet();
                $isFirst = true;
                foreach ($worksheet->getRowIterator() as $row) {
                    $cellIterator = $row->getCellIterator();
                    $cellIterator->setIterateOnlyExistingCells(false);
                    $data = [];
                    foreach ($cellIterator as $cell) {
                        $data[] = $cell->getValue();
                    }
                    if ($isFirst && $this->looksLikeHeader($data)) {
                        $isFirst = false;
                        continue;
                    }
                    $isFirst = false;
                    $rows[] = $data;
                }
            } else {
                throw new \RuntimeException('يرجى تثبيت الحزمة phpoffice/phpspreadsheet لدعم ملفات Excel.');
            }
        }

        return $rows;
    }

    private function looksLikeHeader(array $row): bool
    {
        $headerKeywords = ['front', 'back', 'question', 'answer', 'column', 'type', 'a', 'b'];

        foreach ($row as $cell) {
            if (in_array(strtolower(trim((string) ($cell ?? ''))), $headerKeywords, true)) {
                return true;
            }
        }

        return false;
    }

    private function mapLegacyResponse(bool $isCorrect): string
    {
        return $isCorrect ? 'easy' : 'hard';
    }

    private function calculateNextReview(FlashcardPack $pack, FlashcardProgress $progress, string $responseLevel)
    {
        $now = now();

        $scheduleMap = [
            'daily' => ['easy' => 3, 'medium' => 1, 'hard' => 0.25],
            'weekly' => ['easy' => 7, 'medium' => 3, 'hard' => 1],
            'monthly' => ['easy' => 30, 'medium' => 7, 'hard' => 2],
        ];

        $cycle = $scheduleMap[$pack->repeat_cycle] ?? $scheduleMap['daily'];
        $days = $cycle[$responseLevel] ?? 1;

        if ($responseLevel === 'easy') {
            $days = min(45, $days + max(0, $progress->times_correct - 1));
        }

        if ($responseLevel === 'hard') {
            return $now->copy()->addHours((int) max(4, $days * 24));
        }

        return $now->copy()->addDays((int) ceil($days));
    }

    private function userCanAccessItemPack(int $userId, int $itemPackId): bool
    {
        if (FlashcardPack::where('user_id', $userId)->where('id', $itemPackId)->exists()) {
            return true;
        }

        $sourcePacks = FlashcardPack::where('user_id', $userId)
            ->whereNotNull('source_pack_id')
            ->with('sourcePack')
            ->get();

        foreach ($sourcePacks as $assignedPack) {
            if ($assignedPack->source_pack_id === $itemPackId) {
                return true;
            }

            if ($assignedPack->sourcePack && in_array($itemPackId, $assignedPack->sourcePack->descendantPackIds(), true)) {
                return true;
            }
        }

        return false;
    }
}
