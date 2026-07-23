<?php

namespace App\Http\Controllers\Api\Admin;

use App\Models\FlashcardItem;
use App\Models\FlashcardPack;
use App\Models\PublicPackStore;
use App\Models\StudentNotification;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class FlashcardController extends AdminApiController
{
    public function index(Request $request)
    {
        $query = FlashcardPack::with(['user:id,name,role', 'storeEntry'])
            ->whereNull('parent_pack_id');

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('title', 'like', "%{$search}%")
                    ->orWhereHas('user', fn ($u) => $u->where('name', 'like', "%{$search}%"));
            });
        }

        if ($request->filled('type')) {
            if ($request->type === 'public') {
                $query->where('is_public', true);
            } elseif ($request->type === 'private') {
                $query->where('is_public', false);
            }
        }

        if ($request->filled('display_mode')) {
            $displayMode = $request->display_mode;
            $query->where(function ($q) use ($displayMode) {
                $q->where('display_mode', $displayMode)
                    ->orWhereHas('items', fn ($items) => $items->where('item_type', $displayMode));
            });
        }

        $packs = $query->latest()->paginate(20);
        $packs->getCollection()->transform(function (FlashcardPack $pack) {
            $pack->items_count = $pack->cardsCount();
            $pack->children_count = $pack->childPacks()->count();
            $pack->item_type_summary = $this->itemTypeSummary($pack);

            return $pack;
        });

        return $this->paginated($packs);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string|max:1000',
            'color' => 'nullable|string|max:7',
            'display_mode' => 'nullable|in:flash_card,one_line,qa,mcq',
            'category' => 'nullable|string|max:255',
            'parent_pack_id' => 'nullable|integer',
            'smart_review_enabled' => 'boolean',
            'daily_card_limit' => 'integer|min:1|max:100',
            'schedule_mode' => 'nullable|in:daily,weekdays,weekly,monthly,manual',
            'pack_priority' => 'nullable|in:high,medium,low',
            'smart_review_frequency_minutes' => 'integer|min:1|max:1440',
            'restart_mode' => 'nullable|in:none,all,hard_only,wrong_only',
        ]);

        $parentPack = $this->resolveAdminParentPack($validated['parent_pack_id'] ?? null, $request->user()->id);

        $pack = FlashcardPack::create([
            'user_id' => $request->user()->id,
            'title' => $validated['title'],
            'description' => $validated['description'] ?? null,
            'color' => $validated['color'] ?? '#4f46e5',
            'display_mode' => $validated['display_mode'] ?? 'one_line',
            'notifications_enabled' => $request->boolean('notifications_enabled', true),
            'smart_review_enabled' => $request->boolean('smart_review_enabled', true),
            'daily_notification_count' => $validated['daily_card_limit'] ?? 5,
            'daily_card_limit' => $validated['daily_card_limit'] ?? 5,
            'repeat_cycle' => 'daily',
            'schedule_mode' => $validated['schedule_mode'] ?? 'daily',
            'pack_priority' => $validated['pack_priority'] ?? 'medium',
            'smart_review_frequency_minutes' => $validated['smart_review_frequency_minutes'] ?? 30,
            'restart_mode' => $validated['restart_mode'] ?? 'none',
            'quiet_start' => null,
            'quiet_end' => null,
            'is_public' => true,
            'parent_pack_id' => $parentPack?->id,
        ]);

        if (!$parentPack) {
            PublicPackStore::create([
                'pack_id' => $pack->id,
                'published_by' => $request->user()->id,
                'category' => $validated['category'] ?? null,
            ]);
        }

        return $this->success(['pack' => $pack], 'تم إنشاء الحزمة بنجاح.', 201);
    }

    public function show($id)
    {
        $pack = FlashcardPack::with(['user:id,name,role', 'storeEntry', 'childPacks:id,user_id,parent_pack_id,title,color,display_mode,is_active,source_pack_id'])
            ->findOrFail($id);

        $pack->items_count = $pack->cardsCount();
        $pack->item_type_summary = $this->itemTypeSummary($pack);

        $items = ($pack->is_assigned && $pack->sourcePack)
            ? $pack->sourcePack->items()->with('pack:id,title,color,display_mode')->orderBy('sort_order')->orderBy('id')->get()
            : $pack->items()->with('pack:id,title,color,display_mode')->orderBy('sort_order')->orderBy('id')->get();

        return $this->success([
            'pack' => $pack,
            'items' => $items,
            'child_packs' => $pack->childPacks->map(function (FlashcardPack $childPack) {
                $childPack->items_count = $childPack->cardsCount();

                return $childPack;
            })->values(),
        ]);
    }

    public function update(Request $request, $id)
    {
        $pack = FlashcardPack::findOrFail($id);

        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string|max:1000',
            'color' => 'nullable|string|max:7',
            'display_mode' => 'nullable|in:flash_card,one_line,qa,mcq',
            'category' => 'nullable|string|max:255',
            'parent_pack_id' => 'nullable|integer',
            'smart_review_enabled' => 'boolean',
            'daily_card_limit' => 'integer|min:1|max:100',
            'schedule_mode' => 'nullable|in:daily,weekdays,weekly,monthly,manual',
            'pack_priority' => 'nullable|in:high,medium,low',
            'smart_review_frequency_minutes' => 'integer|min:1|max:1440',
            'restart_mode' => 'nullable|in:none,all,hard_only,wrong_only',
        ]);

        $parentPack = $this->resolveAdminParentPack($validated['parent_pack_id'] ?? null, $request->user()->id, $pack);

        $pack->update([
            'title' => $validated['title'],
            'description' => $validated['description'] ?? null,
            'color' => $validated['color'] ?? '#4f46e5',
            'display_mode' => $validated['display_mode'] ?? $pack->display_mode,
            'is_active' => $request->boolean('is_active', $pack->is_active),
            'parent_pack_id' => $parentPack?->id,
            'notifications_enabled' => array_key_exists('smart_review_enabled', $validated)
                ? (bool) $validated['smart_review_enabled']
                : $pack->notifications_enabled,
            'smart_review_enabled' => array_key_exists('smart_review_enabled', $validated)
                ? (bool) $validated['smart_review_enabled']
                : $pack->smart_review_enabled,
            'daily_notification_count' => $validated['daily_card_limit'] ?? $pack->daily_notification_count,
            'daily_card_limit' => $validated['daily_card_limit'] ?? $pack->daily_card_limit,
            'schedule_mode' => $validated['schedule_mode'] ?? $pack->schedule_mode,
            'pack_priority' => $validated['pack_priority'] ?? $pack->pack_priority,
            'smart_review_frequency_minutes' => $validated['smart_review_frequency_minutes'] ?? $pack->smart_review_frequency_minutes,
            'restart_mode' => $validated['restart_mode'] ?? $pack->restart_mode,
        ]);

        if ($pack->storeEntry) {
            $pack->storeEntry->update(['category' => $validated['category'] ?? null]);
        }

        return $this->success(['pack' => $pack], 'تم تحديث الحزمة بنجاح.');
    }

    public function destroy($id)
    {
        $pack = FlashcardPack::findOrFail($id);
        $this->deletePackTree($pack);

        return $this->success(null, 'تم حذف الحزمة بنجاح.');
    }

    public function publishToStore(Request $request, $id)
    {
        $pack = FlashcardPack::findOrFail($id);

        if ($pack->storeEntry) {
            $pack->storeEntry->update(['is_active' => true, 'category' => $request->input('category', $pack->storeEntry->category)]);
        } else {
            PublicPackStore::create([
                'pack_id' => $pack->id,
                'published_by' => $request->user()->id,
                'category' => $request->input('category'),
            ]);
        }

        $pack->update(['is_public' => true]);

        return $this->success(null, 'تم نشر الحزمة في المتجر.');
    }

    public function toggleFeatured($id)
    {
        $storeEntry = PublicPackStore::where('pack_id', $id)->firstOrFail();
        $storeEntry->update(['is_featured' => !$storeEntry->is_featured]);

        return $this->success([
            'is_featured' => $storeEntry->is_featured,
        ], $storeEntry->is_featured ? 'تم تمييز الحزمة في المتجر.' : 'تم إلغاء تمييز الحزمة من المتجر.');
    }

    public function assignToUser(Request $request, $id)
    {
        $pack = FlashcardPack::findOrFail($id);

        $request->validate([
            'user_id' => 'required|exists:users,id',
        ]);

        $targetUser = User::findOrFail($request->user_id);

        $existing = FlashcardPack::where('user_id', $targetUser->id)
            ->where('source_pack_id', $pack->id)
            ->whereNull('parent_pack_id')
            ->first();

        if ($existing) {
            return $this->error('الطالب لديه هذه الحزمة بالفعل.', 409);
        }

        DB::transaction(function () use ($pack, $targetUser) {
            $this->cloneAssignedTree($pack, $targetUser->id);
        });

        $this->notifyFlashcardAssigned($pack, $targetUser, $request->user()->id);

        return $this->success(null, 'تم تعيين الحزمة للطالب وإرسال إشعار له.');
    }

    public function import(Request $request, $id)
    {
        $pack = FlashcardPack::findOrFail($id);

        if ($pack->is_assigned) {
            return $this->error('الحزم المعيّنة لا تقبل تعديل العناصر مباشرة.', 422);
        }

        $request->validate([
            'file' => 'required|file|mimes:xlsx,csv,xls',
        ]);

        $file = $request->file('file');
        $extension = $file->getClientOriginalExtension();

        try {
            $rows = $this->parseSpreadsheet($file->getPathname(), $extension);
            $itemsCountBefore = $pack->items()->count();
            $items = [];

            foreach ($rows as $row) {
                $itemData = $this->mapImportedRow($row, $pack, $itemsCountBefore + count($items));

                if ($itemData) {
                    $items[] = $itemData;
                }
            }

            if (empty($items)) {
                return $this->error('الملف لا يحتوي على بيانات صالحة.', 422);
            }

            FlashcardItem::insert($items);

            return $this->success(['imported_count' => count($items)], 'تم استيراد العناصر بنجاح.');
        } catch (\Exception $e) {
            return $this->error('حدث خطأ أثناء قراءة الملف: ' . $e->getMessage(), 500);
        }
    }

    public function storeItem(Request $request, $id)
    {
        $pack = FlashcardPack::findOrFail($id);

        if ($pack->is_assigned) {
            return $this->error('الحزم المعيّنة لا تقبل تعديل العناصر مباشرة.', 422);
        }

        $itemType = $request->input('item_type', $pack->display_mode);
        $validated = $this->validateItemPayload($request, $itemType);
        $item = $pack->items()->create($this->mapItemData($validated, $pack, $itemType));

        return $this->success(['item' => $item], 'تم إنشاء العنصر بنجاح.', 201);
    }

    public function updateItem(Request $request, $itemId)
    {
        $item = FlashcardItem::with('pack')->findOrFail($itemId);

        if ($item->pack->is_assigned) {
            return $this->error('الحزم المعيّنة لا تقبل تعديل العناصر مباشرة.', 422);
        }

        $itemType = $request->input('item_type', $item->resolved_item_type);
        $validated = $this->validateItemPayload($request, $itemType);
        $item->update($this->mapItemData($validated, $item->pack, $itemType, false));

        return $this->success(['item' => $item->fresh()], 'تم تحديث العنصر بنجاح.');
    }

    public function destroyItem($itemId)
    {
        $item = FlashcardItem::with('pack')->findOrFail($itemId);

        if ($item->pack->is_assigned) {
            return $this->error('الحزم المعيّنة لا تقبل تعديل العناصر مباشرة.', 422);
        }

        $item->delete();

        return $this->success(null, 'تم حذف العنصر بنجاح.');
    }

    private function resolveAdminParentPack(?int $parentPackId, int $userId, ?FlashcardPack $currentPack = null): ?FlashcardPack
    {
        if (!$parentPackId) {
            return null;
        }

        $parentPack = FlashcardPack::where('id', $parentPackId)
            ->where('user_id', $userId)
            ->whereNull('source_pack_id')
            ->firstOrFail();

        if ($currentPack && in_array($parentPack->id, $currentPack->descendantPackIds(), true)) {
            abort(422, 'لا يمكن نقل الحزمة داخل أحد تفرعاتها.');
        }

        return $parentPack;
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

    private function itemTypeSummary(FlashcardPack $pack): array
    {
        return $pack->effectiveItems()
            ->get(['item_type'])
            ->map(fn (FlashcardItem $item) => $item->item_type ?: $pack->display_mode)
            ->filter()
            ->unique()
            ->values()
            ->all();
    }

    private function notifyFlashcardAssigned(FlashcardPack $pack, User $targetUser, int $senderId): void
    {
        StudentNotification::create([
            'user_id' => $targetUser->id,
            'college_id' => $targetUser->college_id,
            'sender_id' => $senderId,
            'type' => 'flashcard_assignment',
            'title' => 'تمت إضافة حزمة One Line Shot',
            'message' => "تم تعيين حزمة «{$pack->title}» لك. يمكنك مراجعتها من One Line Shot.",
            'data' => [
                'screen' => 'flashcards',
                'target_screen' => 'flashcards',
                'pack_id' => (string) $pack->id,
            ],
        ]);

    }

    private function deletePackTree(FlashcardPack $pack): void
    {
        $pack->load('childPacks');

        foreach ($pack->childPacks as $childPack) {
            $this->deletePackTree($childPack);
        }

        $pack->delete();
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
            if (!class_exists('\PhpOffice\PhpSpreadsheet\IOFactory')) {
                throw new \RuntimeException('PhpSpreadsheet is required to read Excel files.');
            }

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
        }

        return $rows;
    }

    private function looksLikeHeader(array $row): bool
    {
        $headerKeywords = ['front', 'back', 'question', 'answer', 'column', 'type', 'item_type', 'نوع', 'السؤال', 'الإجابة', 'الاجابة', 'النص'];

        foreach ($row as $cell) {
            $cellStr = strtolower(trim((string) ($cell ?? '')));
            if ($cellStr === '') {
                continue;
            }

            if ($cellStr === 'a' || $cellStr === 'b') {
                return true;
            }

            foreach ($headerKeywords as $keyword) {
                if (str_contains($cellStr, $keyword)) {
                    return true;
                }
            }
        }

        return false;
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

    private function mapImportedRow(array $row, FlashcardPack $pack, int $sortOrder): ?array
    {
        $row = array_map(fn ($value) => is_string($value) ? trim($value) : $value, $row);
        $firstCellType = $this->normalizeItemType((string) ($row[0] ?? ''));
        $hasExplicitType = $firstCellType !== null;
        $itemType = $firstCellType ?? ($pack->display_mode ?: 'one_line');
        $offset = $hasExplicitType ? 1 : 0;
        $front = trim((string) ($row[$offset] ?? ''));

        if ($front === '') {
            return null;
        }

        $data = [
            'pack_id' => $pack->id,
            'item_type' => $itemType,
            'front_content' => $front,
            'item_color' => $this->validHexColor((string) ($row[$offset + 9] ?? '')) ?: null,
            'priority' => $this->normalizePriority((string) ($row[$offset + 8] ?? 'normal')),
            'sort_order' => $sortOrder,
            'created_at' => now(),
            'updated_at' => now(),
        ];

        if ($itemType === 'mcq') {
            $options = [];
            foreach (range($offset + 1, $offset + 6) as $columnIndex) {
                if (!empty($row[$columnIndex])) {
                    $options[] = trim((string) $row[$columnIndex]);
                }
            }

            if (count($options) < 2) {
                return null;
            }

            $correct = is_numeric($row[$offset + 7] ?? null) ? (int) $row[$offset + 7] : 1;
            $data['options'] = json_encode($options, JSON_UNESCAPED_UNICODE);
            $data['correct_option'] = max(0, min(count($options) - 1, $correct > 0 ? $correct - 1 : $correct));
            $data['back_content'] = null;

            return $data;
        }

        $back = trim((string) ($row[$offset + 1] ?? ''));
        if (!in_array($itemType, ['one_line'], true) && $back === '') {
            return null;
        }

        $data['back_content'] = $itemType === 'one_line' ? null : $back;
        $data['options'] = null;
        $data['correct_option'] = null;

        return $data;
    }

    private function normalizeItemType(string $value): ?string
    {
        $normalized = strtolower(trim($value));

        return match ($normalized) {
            'flash_card', 'flash card', 'card', 'بطاقة', 'بطاقة تعليمية' => 'flash_card',
            'one_line', 'one line', 'line', 'نص', 'نص واحد' => 'one_line',
            'qa', 'q&a', 'question_answer', 'سؤال', 'سؤال وجواب' => 'qa',
            'mcq', 'multiple_choice', 'choice', 'اختيارات', 'اختيار من متعدد' => 'mcq',
            default => null,
        };
    }

    private function normalizePriority(string $value): string
    {
        $normalized = strtolower(trim($value));

        return match ($normalized) {
            'critical', 'حرجة' => 'critical',
            'high', 'عالية' => 'high',
            default => 'normal',
        };
    }

    private function validHexColor(string $value): ?string
    {
        $value = trim($value);

        return preg_match('/^#[0-9a-fA-F]{6}$/', $value) ? $value : null;
    }
}
