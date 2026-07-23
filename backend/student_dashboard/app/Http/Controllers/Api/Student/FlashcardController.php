<?php

namespace App\Http\Controllers\Api\Student;

use App\Models\FlashcardItem;
use App\Models\FlashcardPack;
use App\Models\FlashcardProgress;
use App\Models\FlashcardUserSetting;
use App\Models\PublicPackStore;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class FlashcardController extends StudentApiController
{
    public function index(Request $request)
    {
        $user = $request->user();
        $settings = $this->flashcardSettings($user->id);

        $packs = FlashcardPack::forUser($user->id)
            ->whereNull('parent_pack_id')
            ->with('childPacks:id,parent_pack_id,title,color,display_mode,is_active,source_pack_id')
            ->latest()
            ->get();

        $packs->each(function (FlashcardPack $pack) {
            $pack->items_count = $pack->cardsCount();
            $pack->children_count = $pack->childPacks->count();
        });

        return $this->success([
            'packs' => $packs,
            'settings' => $settings,
            'stats' => [
                'total_packs' => $packs->count(),
                'active_packs' => $packs->where('is_active', true)->count(),
                'total_cards' => $packs->sum('items_count'),
            ],
        ]);
    }

    public function settings(Request $request)
    {
        return $this->success([
            'settings' => $this->flashcardSettings($request->user()->id),
        ]);
    }

    public function updateUserSettings(Request $request)
    {
        $validated = $request->validate([
            'smart_review_enabled' => 'boolean',
            'active_from_time' => 'nullable|date_format:H:i',
            'active_to_time' => 'nullable|date_format:H:i',
            'quiet_start' => 'nullable|date_format:H:i',
            'quiet_end' => 'nullable|date_format:H:i',
            'daily_card_limit' => 'integer|min:1|max:100',
            'smart_review_frequency_minutes' => 'integer|min:1|max:1440',
            'auto_restart_enabled' => 'boolean',
            'prompt_mode' => 'nullable|in:app_and_notification,app_only,notification_only',
            'one_line_notifications_enabled' => 'boolean',
            'one_line_daily_limit' => 'integer|min:1|max:100',
            'one_line_frequency_minutes' => 'integer|min:1|max:1440',
            'one_line_active_from_time' => 'nullable|date_format:H:i',
            'one_line_active_to_time' => 'nullable|date_format:H:i',
            'one_line_quiet_start' => 'nullable|date_format:H:i',
            'one_line_quiet_end' => 'nullable|date_format:H:i',
        ]);

        $settings = FlashcardUserSetting::firstOrNew(['user_id' => $request->user()->id]);
        if (!$settings->exists) {
            $settings->fill($this->defaultSettings());
        }
        $settings->fill($validated)->save();
        $settings = $settings->fresh();

        return $this->success(['settings' => $settings], 'Flashcard settings updated.');
    }

    public function store(Request $request)
    {
        $validated = $this->validatePackPayload($request, true);

        $parentPack = $this->resolveParentPack($validated['parent_pack_id'] ?? null, $request->user()->id);

        $pack = $request->user()->flashcardPacks()->create(array_merge([
            'title' => $validated['title'],
            'description' => $validated['description'] ?? null,
            'color' => $validated['color'] ?? '#4f46e5',
            'display_mode' => $validated['display_mode'] ?? 'one_line',
            'parent_pack_id' => $parentPack?->id,
        ], $this->packScheduleData($validated)));

        return $this->success(['pack' => $pack], 'Pack created successfully.', 201);
    }

    public function show(Request $request, $id)
    {
        $pack = FlashcardPack::where('id', $id)
            ->where(function ($query) use ($request) {
                $query->where('user_id', $request->user()->id)
                      ->orWhere('is_public', true);
            })
            ->with('childPacks:id,user_id,parent_pack_id,title,color,display_mode,is_active,source_pack_id')
            ->firstOrFail();

        $items = $this->displayItemsForPack($pack)->values();
        $pack->items_count = $pack->cardsCount();

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
        $pack = FlashcardPack::where('id', $id)
            ->where('user_id', $request->user()->id)
            ->firstOrFail();

        $validated = $this->validatePackPayload($request, true);

        $parentPack = $this->resolveParentPack($validated['parent_pack_id'] ?? null, $request->user()->id, $pack);

        $pack->update(array_merge([
            'title' => $validated['title'],
            'description' => $validated['description'] ?? null,
            'color' => $validated['color'] ?? '#4f46e5',
            'display_mode' => $validated['display_mode'] ?? $pack->display_mode,
            'parent_pack_id' => $pack->is_assigned ? $pack->parent_pack_id : $parentPack?->id,
        ], $this->packScheduleData($validated)));

        return $this->success(['pack' => $pack], 'Pack updated successfully.');
    }

    public function destroy(Request $request, $id)
    {
        $pack = FlashcardPack::where('id', $id)
            ->where('user_id', $request->user()->id)
            ->firstOrFail();

        $this->deletePackTree($pack);

        return $this->success(null, 'Pack deleted successfully.');
    }

    public function toggleActive(Request $request, $id)
    {
        $pack = FlashcardPack::where('id', $id)
            ->where('user_id', $request->user()->id)
            ->firstOrFail();

        $pack->update(['is_active' => !$pack->is_active]);

        return $this->success(['is_active' => $pack->is_active], 'Pack status updated.');
    }

    public function updateSettings(Request $request, $id)
    {
        $pack = FlashcardPack::where('id', $id)
            ->where('user_id', $request->user()->id)
            ->firstOrFail();

        $validated = $this->validatePackPayload($request, false);

        $pack->update(array_merge($this->packScheduleData($validated, $pack), [
            'display_mode' => $validated['display_mode'] ?? $pack->display_mode,
        ]));

        return $this->success(['pack' => $pack], 'Pack settings updated.');
    }

    private function validatePackPayload(Request $request, bool $withIdentity): array
    {
        $rules = [
            'display_mode' => 'nullable|in:flash_card,one_line,qa,mcq',
            'notifications_enabled' => 'boolean',
            'smart_review_enabled' => 'boolean',
            'daily_notification_count' => 'integer|min:1|max:50',
            'daily_card_limit' => 'integer|min:1|max:50',
            'repeat_cycle' => 'nullable|in:daily,weekly,monthly',
            'schedule_mode' => 'nullable|in:daily,weekdays,weekly,monthly,manual',
            'schedule_weekdays' => 'nullable|array',
            'schedule_weekdays.*' => 'integer|min:0|max:6',
            'active_from_time' => 'nullable|date_format:H:i',
            'active_to_time' => 'nullable|date_format:H:i',
            'quiet_start' => 'nullable|date_format:H:i',
            'quiet_end' => 'nullable|date_format:H:i',
            'pack_priority' => 'nullable|in:high,medium,low',
            'smart_review_frequency_minutes' => 'integer|min:1|max:1440',
            'restart_mode' => 'nullable|in:none,all,hard_only,wrong_only',
        ];

        if ($withIdentity) {
            $rules = array_merge([
                'title' => 'required|string|max:255',
                'description' => 'nullable|string|max:1000',
                'color' => 'nullable|string|max:7',
                'parent_pack_id' => 'nullable|integer',
            ], $rules);
        }

        return $request->validate($rules);
    }

    private function packScheduleData(array $validated, ?FlashcardPack $current = null): array
    {
        $dailyLimit = $validated['daily_card_limit']
            ?? $validated['daily_notification_count']
            ?? $current?->daily_card_limit
            ?? $current?->daily_notification_count
            ?? 5;

        $scheduleMode = $validated['schedule_mode']
            ?? $this->legacyScheduleMode($validated['repeat_cycle'] ?? $current?->repeat_cycle ?? 'daily');

        $smartReviewEnabled = array_key_exists('smart_review_enabled', $validated)
            ? (bool) $validated['smart_review_enabled']
            : (array_key_exists('notifications_enabled', $validated)
                ? (bool) $validated['notifications_enabled']
                : (bool) ($current?->smart_review_enabled ?? $current?->notifications_enabled ?? true));

        return [
            'notifications_enabled' => $smartReviewEnabled,
            'smart_review_enabled' => $smartReviewEnabled,
            'daily_notification_count' => $dailyLimit,
            'daily_card_limit' => $dailyLimit,
            'repeat_cycle' => $validated['repeat_cycle'] ?? $this->legacyRepeatCycle($scheduleMode),
            'schedule_mode' => $scheduleMode,
            'schedule_weekdays' => $validated['schedule_weekdays'] ?? $current?->schedule_weekdays,
            'active_from_time' => $validated['active_from_time'] ?? null,
            'active_to_time' => $validated['active_to_time'] ?? null,
            'quiet_start' => $validated['quiet_start'] ?? null,
            'quiet_end' => $validated['quiet_end'] ?? null,
            'pack_priority' => $validated['pack_priority'] ?? $current?->pack_priority ?? 'medium',
            'smart_review_frequency_minutes' => $validated['smart_review_frequency_minutes']
                ?? $current?->smart_review_frequency_minutes
                ?? 30,
            'restart_mode' => $validated['restart_mode'] ?? $current?->restart_mode ?? 'none',
        ];
    }

    private function legacyScheduleMode(string $repeatCycle): string
    {
        return match ($repeatCycle) {
            'weekly' => 'weekly',
            'monthly' => 'monthly',
            default => 'daily',
        };
    }

    private function legacyRepeatCycle(string $scheduleMode): string
    {
        return match ($scheduleMode) {
            'weekly' => 'weekly',
            'monthly' => 'monthly',
            default => 'daily',
        };
    }

    public function downloadImportTemplate()
    {
        $headers = [
            'Content-Type' => 'text/csv; charset=UTF-8',
            'Content-Disposition' => 'attachment; filename="one_line_shot_template.csv"',
        ];

        return response()->stream(function () {
            $file = fopen('php://output', 'w');
            fprintf($file, chr(0xEF) . chr(0xBB) . chr(0xBF));

            fputcsv($file, [
                'نوع البطاقة',
                'المحتوى الأمامي أو السؤال',
                'الإجابة أو الاختيار الأول',
                'الاختيار الثاني',
                'الاختيار الثالث',
                'الاختيار الرابع',
                'الاختيار الخامس',
                'الاختيار السادس',
                'رقم الاختيار الصحيح للمتعدد',
                'الأولوية',
                'اللون بصيغة Hex',
            ]);

            fputcsv($file, ['نص واحد', 'العلم نور والجهل ظلام.', '', '', '', '', '', '', '', 'normal', '#F59E0B']);
            fputcsv($file, ['بطاقة', 'ما هي عاصمة المملكة العربية السعودية؟', 'الرياض', '', '', '', '', '', '', 'عالية', '#4F46E5']);
            fputcsv($file, ['سؤال وجواب', 'كم عدد أركان الإسلام؟', 'خمسة أركان.', '', '', '', '', '', '', 'حرجة', '#EF4444']);
            fputcsv($file, ['اختيارات', 'أي مما يلي يعد من ألوان قوس قزح؟', 'الأحمر', 'الأسود', 'الأبيض', 'الرمادي', '', '', '1', 'normal', '#10B981']);

            fclose($file);
        }, 200, $headers);
    }

    public function import(Request $request, $id)
    {
        $pack = FlashcardPack::where('id', $id)
            ->where('user_id', $request->user()->id)
            ->firstOrFail();

        $this->assertCanManageItems($pack);

        $request->validate([
            'file' => 'required|file|mimes:xlsx,csv,xls',
        ]);

        $file = $request->file('file');
        $extension = $file->getClientOriginalExtension();

        try {
            $rows = $this->parseSpreadsheet($file->getPathname(), $extension);
            $itemsCountBefore = $pack->items()->count();
            $items = [];

            foreach ($rows as $index => $row) {
                if ($index === 0 && $this->looksLikeHeader($row)) {
                    continue;
                }
                if (empty($row[0])) {
                    continue;
                }

                $itemData = [
                    'pack_id' => $pack->id,
                    'item_type' => $pack->display_mode,
                    'front_content' => trim((string) $row[0]),
                    'priority' => 'normal',
                    'sort_order' => $itemsCountBefore + $index,
                    'created_at' => now(),
                    'updated_at' => now(),
                ];

                switch ($pack->display_mode) {
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
                return $this->error('No valid rows found in the file.', 422);
            }

            FlashcardItem::insert($items);

            return $this->success(['imported_count' => count($items)], 'Items imported successfully.');
        } catch (\Exception $e) {
            return $this->error('Failed to read spreadsheet: ' . $e->getMessage(), 500);
        }
    }

    public function importPreview(Request $request, $id)
    {
        $pack = FlashcardPack::where('id', $id)
            ->where('user_id', $request->user()->id)
            ->firstOrFail();

        $this->assertCanManageItems($pack);

        $request->validate([
            'file' => 'required|file|mimes:xlsx,csv,xls',
        ]);

        $file = $request->file('file');
        $extension = strtolower($file->getClientOriginalExtension());
        $tempDir = storage_path('app/temp_imports/student_flashcards');

        if (!file_exists($tempDir)) {
            mkdir($tempDir, 0755, true);
        }

        $tempFileName = 'student_' . $request->user()->id . '_' . time() . '_' . bin2hex(random_bytes(4)) . '.' . $extension;
        $file->move($tempDir, $tempFileName);
        $tempFilePath = 'temp_imports/student_flashcards/' . $tempFileName;

        try {
            $rows = $this->parseSpreadsheet(storage_path('app/' . $tempFilePath), $extension);
            if (empty($rows)) {
                @unlink(storage_path('app/' . $tempFilePath));
                return $this->error('الملف لا يحتوي على بيانات صالحة.', 422);
            }

            $firstRow = $rows[0];
            $columns = [];
            foreach ($firstRow as $index => $value) {
                $columns[$index] = trim((string) ($value ?? '')) ?: ('العمود ' . ($index + 1));
            }

            $isFirstRowHeader = $this->looksLikeHeader($firstRow);

            return $this->success([
                'temp_file' => $tempFilePath,
                'columns' => $columns,
                'preview_rows' => array_values(array_slice($rows, $isFirstRowHeader ? 1 : 0, 5)),
                'guessed_mapping' => $this->guessImportMapping($columns),
                'is_first_row_header' => $isFirstRowHeader,
                'pack' => [
                    'id' => $pack->id,
                    'title' => $pack->title,
                    'display_mode' => $pack->display_mode,
                    'display_mode_label' => FlashcardPack::itemTypeLabel($pack->display_mode),
                ],
            ], 'تمت قراءة الملف. راجع المعاينة قبل التأكيد.');
        } catch (\Exception $e) {
            @unlink(storage_path('app/' . $tempFilePath));
            return $this->error('حدث خطأ أثناء قراءة الملف للمعاينة: ' . $e->getMessage(), 500);
        }
    }

    public function importConfirm(Request $request, $id)
    {
        $pack = FlashcardPack::where('id', $id)
            ->where('user_id', $request->user()->id)
            ->firstOrFail();

        $this->assertCanManageItems($pack);

        $validated = $request->validate([
            'temp_file' => 'required|string',
            'duplicate_strategy' => 'required|in:allow,ignore,update',
            'has_headers' => 'boolean',
            'front_content_col' => 'required|integer|min:0',
            'item_type_col' => 'required|integer',
            'back_content_col' => 'required|integer',
            'options_cols' => 'nullable|array',
            'options_cols.*' => 'integer',
            'correct_option_col' => 'required|integer',
            'priority_col' => 'required|integer',
            'color_col' => 'required|integer',
        ]);

        $tempFile = (string) $validated['temp_file'];
        if (!str_starts_with($tempFile, 'temp_imports/student_flashcards/')) {
            return $this->error('مسار ملف الاستيراد المؤقت غير صالح، يرجى الرفع من جديد.', 422);
        }

        $tempFilePath = storage_path('app/' . $tempFile);
        if (!file_exists($tempFilePath)) {
            return $this->error('انتهت صلاحية الملف المؤقت أو الملف غير موجود، يرجى الرفع من جديد.', 422);
        }

        $extension = strtolower(pathinfo($tempFilePath, PATHINFO_EXTENSION));

        try {
            $rows = $this->parseSpreadsheet($tempFilePath, $extension);
            if (empty($rows)) {
                @unlink($tempFilePath);
                return $this->error('الملف لا يحتوي على بيانات صالحة.', 422);
            }

            $startRowIndex = $request->boolean('has_headers') ? 1 : 0;
            $itemsCountBefore = $pack->items()->count();
            $existingItems = $pack->items()
                ->select(['id', 'front_content'])
                ->get()
                ->keyBy(fn ($item) => mb_strtolower(trim($item->front_content)));

            $toInsert = [];
            $insertedCount = 0;
            $updatedCount = 0;
            $ignoredCount = 0;
            $failedRows = [];

            foreach ($rows as $index => $row) {
                if ($index < $startRowIndex) {
                    continue;
                }

                $rowNum = $index + 1;
                $row = array_map(fn ($value) => is_string($value) ? trim($value) : $value, $row);
                if (empty(array_filter($row, fn ($value) => $value !== null && $value !== ''))) {
                    continue;
                }

                $frontCol = (int) $validated['front_content_col'];
                $front = isset($row[$frontCol]) ? trim((string) $row[$frontCol]) : '';
                if ($front === '') {
                    $failedRows[] = ['row' => $rowNum, 'reason' => 'حقل المحتوى الأمامي أو السؤال فارغ.'];
                    continue;
                }

                $typeCol = (int) $validated['item_type_col'];
                $explicitType = ($typeCol >= 0 && isset($row[$typeCol]))
                    ? $this->normalizeImportItemType((string) $row[$typeCol])
                    : null;
                $itemType = $explicitType ?? ($pack->display_mode ?: 'one_line');

                $priority = 'normal';
                $priorityCol = (int) $validated['priority_col'];
                if ($priorityCol >= 0 && isset($row[$priorityCol])) {
                    $priority = $this->normalizeImportPriority((string) $row[$priorityCol]);
                }

                $color = null;
                $colorCol = (int) $validated['color_col'];
                if ($colorCol >= 0 && isset($row[$colorCol])) {
                    $color = $this->validImportHexColor((string) $row[$colorCol]);
                }

                $back = null;
                $options = null;
                $correctOption = null;

                if ($itemType === 'mcq') {
                    $options = [];
                    foreach (($validated['options_cols'] ?? []) as $colIndex) {
                        if (isset($row[$colIndex]) && trim((string) $row[$colIndex]) !== '') {
                            $options[] = trim((string) $row[$colIndex]);
                        }
                    }

                    if (count($options) < 2) {
                        $failedRows[] = ['row' => $rowNum, 'reason' => 'تم تحديد اختيار متعدد ولكن عدد الخيارات الصالحة أقل من خيارين.'];
                        continue;
                    }

                    $correctCol = (int) $validated['correct_option_col'];
                    $correctVal = ($correctCol >= 0 && isset($row[$correctCol])) ? $row[$correctCol] : null;
                    $correct = is_numeric($correctVal) ? (int) $correctVal : 1;
                    $correctOption = max(0, min(count($options) - 1, $correct > 0 ? $correct - 1 : $correct));
                } else {
                    $backCol = (int) $validated['back_content_col'];
                    $backVal = ($backCol >= 0 && isset($row[$backCol])) ? trim((string) $row[$backCol]) : '';
                    if ($itemType !== 'one_line' && $backVal === '') {
                        $failedRows[] = ['row' => $rowNum, 'reason' => 'هذا النوع يحتاج إلى إجابة أو محتوى خلفي.'];
                        continue;
                    }
                    $back = $itemType === 'one_line' ? null : $backVal;
                }

                $frontKey = mb_strtolower(trim($front));
                $duplicateExists = $existingItems->has($frontKey);

                if ($duplicateExists && $validated['duplicate_strategy'] === 'ignore') {
                    $ignoredCount++;
                    continue;
                }

                if ($duplicateExists && $validated['duplicate_strategy'] === 'update') {
                    $existingItem = $existingItems->get($frontKey);
                    FlashcardItem::where('id', $existingItem->id)->update([
                        'item_type' => $itemType,
                        'back_content' => $back,
                        'options' => $options,
                        'correct_option' => $correctOption,
                        'item_color' => $color,
                        'priority' => $priority,
                    ]);
                    $updatedCount++;
                    continue;
                }

                $toInsert[] = [
                    'pack_id' => $pack->id,
                    'item_type' => $itemType,
                    'front_content' => $front,
                    'back_content' => $back,
                    'options' => $options ? json_encode($options, JSON_UNESCAPED_UNICODE) : null,
                    'correct_option' => $correctOption,
                    'item_color' => $color,
                    'priority' => $priority,
                    'sort_order' => $itemsCountBefore + count($toInsert),
                    'created_at' => now(),
                    'updated_at' => now(),
                ];
            }

            if (!empty($toInsert)) {
                FlashcardItem::insert($toInsert);
                $insertedCount = count($toInsert);
            }

            @unlink($tempFilePath);

            $message = 'تمت معالجة ملف الاستيراد.';
            if ($insertedCount > 0) $message .= " تمت إضافة {$insertedCount} بطاقة.";
            if ($updatedCount > 0) $message .= " تم تحديث {$updatedCount} بطاقة.";
            if ($ignoredCount > 0) $message .= " تم تجاهل {$ignoredCount} بطاقة مكررة.";
            if (count($failedRows) > 0) $message .= ' توجد ' . count($failedRows) . ' صفوف لم تُستورد.';

            return $this->success([
                'report' => [
                    'success_count' => $insertedCount,
                    'updated_count' => $updatedCount,
                    'ignored_count' => $ignoredCount,
                    'failed_count' => count($failedRows),
                    'errors' => $failedRows,
                ],
            ], $message);
        } catch (\Exception $e) {
            @unlink($tempFilePath);
            return $this->error('حدث خطأ غير متوقع أثناء معالجة ملف الاستيراد: ' . $e->getMessage(), 500);
        }
    }

    public function storeItem(Request $request, $id)
    {
        $pack = FlashcardPack::where('id', $id)
            ->where('user_id', $request->user()->id)
            ->firstOrFail();

        $this->assertCanManageItems($pack);

        $itemType = $request->input('item_type', $pack->display_mode);
        $validated = $this->validateItemPayload($request, $itemType);
        $item = $pack->items()->create($this->mapItemData($validated, $pack, $itemType));

        return $this->success(['item' => $item], 'Item created successfully.', 201);
    }

    public function updateItem(Request $request, $itemId)
    {
        $item = FlashcardItem::with('pack')->findOrFail($itemId);

        if ($item->pack->user_id !== $request->user()->id) {
            return $this->error('Unauthorized.', 403);
        }

        $this->assertCanManageItems($item->pack);

        $itemType = $request->input('item_type', $item->resolved_item_type);
        $validated = $this->validateItemPayload($request, $itemType);

        $item->update($this->mapItemData($validated, $item->pack, $itemType, false));

        return $this->success(['item' => $item->fresh()], 'Item updated successfully.');
    }

    public function destroyItem(Request $request, $itemId)
    {
        $item = FlashcardItem::with('pack')->findOrFail($itemId);

        if ($item->pack->user_id !== $request->user()->id) {
            return $this->error('Unauthorized.', 403);
        }

        $this->assertCanManageItems($item->pack);
        $item->delete();

        return $this->success(null, 'Item deleted successfully.');
    }

    public function publicStore(Request $request)
    {
        $query = PublicPackStore::with(['pack' => function ($q) {
            $q->withCount('items')->select('id', 'title', 'description', 'color', 'icon', 'display_mode', 'user_id', 'is_public');
        }, 'pack.user:id,name'])
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

        $storeItems = $query->latest()->paginate(15);
        $storeItems->getCollection()->transform(function (PublicPackStore $storeItem) {
            $storeItem->pack->items_count = $storeItem->pack->cardsCount();

            return $storeItem;
        });

        return $this->success([
            'store_items' => $storeItems,
        ]);
    }

    public function clonePack(Request $request, $id)
    {
        $user = $request->user();
        $sourcePack = FlashcardPack::where('is_public', true)->findOrFail($id);

        $existing = FlashcardPack::where('user_id', $user->id)
            ->where('source_pack_id', $sourcePack->id)
            ->whereNull('parent_pack_id')
            ->first();

        if ($existing) {
            return $this->error('This pack is already in your account.', 409);
        }

        $newPack = DB::transaction(function () use ($sourcePack, $user) {
            $clone = $this->cloneAssignedTree($sourcePack, $user->id);
            $sourcePack->storeEntry?->increment('downloads_count');

            return $clone;
        });

        return $this->success(['pack' => $newPack], 'Pack cloned successfully.', 201);
    }

    public function review(Request $request, $id)
    {
        $pack = FlashcardPack::where('id', $id)
            ->where('user_id', $request->user()->id)
            ->firstOrFail();

        $items = $pack->effectiveItems()
            ->with('pack:id,title,color,display_mode')
            ->orderByRaw("FIELD(priority, 'critical', 'high', 'normal')")
            ->orderBy('sort_order')
            ->orderBy('id')
            ->get();

        $progressMap = FlashcardProgress::where('user_id', $request->user()->id)
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
                    $progress?->review_weight ? -1 * $progress->review_weight : -2,
                    $progress?->last_shown_at?->timestamp ?? 0,
                    match ($item->priority) {
                        'critical' => 0,
                        'high' => 1,
                        default => 2,
                    },
                    $item->sort_order,
                ];
            })
            ->values();

        return $this->success([
            'pack' => $pack->only(['id', 'title', 'display_mode', 'color', 'repeat_cycle']),
            'items' => $items,
        ]);
    }

    public function recordProgress(Request $request)
    {
        $validated = $request->validate([
            'item_id' => 'required|exists:flashcard_items,id',
            'response_level' => 'nullable|in:easy,medium,hard',
            'is_correct' => 'nullable|boolean',
        ]);

        $responseLevel = $validated['response_level'] ?? $this->mapLegacyResponse((bool) ($validated['is_correct'] ?? false));
        $user = $request->user();
        $item = FlashcardItem::with('pack')->findOrFail($validated['item_id']);

        if (!$this->userCanAccessItemPack($user->id, $item->pack_id)) {
            return $this->error('Unauthorized for this item.', 403);
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

        return $this->success(['progress' => $progress->fresh()], 'Progress recorded successfully.');
    }

    public function oneLineNotifications(Request $request)
    {
        $user = $request->user();
        $today = now()->toDateString();
        $settings = $this->flashcardSettings($user->id);

        if (!$settings->one_line_notifications_enabled) {
            return $this->success([
                'items' => [],
                'total' => 0,
                'date' => $today,
                'settings' => $settings,
                'summary' => [
                    'enabled' => false,
                    'message' => 'إشعارات One Line متوقفة.',
                ],
            ]);
        }

        $packs = FlashcardPack::forUser($user->id)
            ->whereNull('parent_pack_id')
            ->active()
            ->where('smart_review_enabled', true)
            ->get()
            ->sortBy(fn (FlashcardPack $pack) => $this->packPriorityWeight($pack));

        $candidates = collect();

        foreach ($packs as $pack) {
            if (!$this->packIsScheduledForDate($pack, now())) {
                continue;
            }

            $packItems = $pack->effectiveItems()
                ->with('pack:id,title,color,display_mode')
                ->orderBy('sort_order')
                ->orderBy('id')
                ->get()
                ->filter(fn (FlashcardItem $item) => $item->resolved_item_type === 'one_line')
                ->values();

            if ($packItems->isEmpty()) {
                continue;
            }

            $progressMap = FlashcardProgress::where('user_id', $user->id)
                ->whereIn('item_id', $packItems->pluck('id'))
                ->get()
                ->keyBy('item_id');

            foreach ($packItems as $item) {
                $item->user_progress = $progressMap->get($item->id);
                $candidates->push(['pack' => $pack, 'item' => $item]);
            }
        }

        $limit = max(1, (int) ($settings->one_line_daily_limit ?? $settings->daily_card_limit ?? 5));
        $selected = $candidates
            ->sortBy(function (array $entry) {
                /** @var FlashcardPack $pack */
                $pack = $entry['pack'];
                /** @var FlashcardItem $item */
                $item = $entry['item'];

                return [
                    $this->packPriorityWeight($pack),
                    $item->user_progress?->last_shown_at?->timestamp ?? 0,
                    match ($item->priority) {
                        'critical' => 0,
                        'high' => 1,
                        default => 2,
                    },
                    $item->sort_order,
                    $item->id,
                ];
            })
            ->take($limit)
            ->values();

        $scheduleSettings = $this->oneLineScheduleSettings($settings);
        $scheduleTimes = $this->resolveScheduledTimes($scheduleSettings, $selected->count(), 0);

        $items = $selected->map(function (array $entry, int $index) use ($scheduleTimes, $scheduleSettings) {
            /** @var FlashcardPack $pack */
            $pack = $entry['pack'];
            /** @var FlashcardItem $item */
            $item = $entry['item'];
            $scheduledAt = $scheduleTimes[$index] ?? now()->copy()->seconds(0)->microsecond(0);
            $title = trim((string) $pack->title);

            return array_merge(
                $this->dailyQueueItem($pack, $item, $scheduledAt, false, $scheduleSettings),
                [
                    'notification_title' => $title === '' || $title === 'جديد'
                        ? 'تذكير One Line'
                        : "تذكير One Line - {$title}",
                    'notification_body' => trim((string) $item->front_content),
                    'notification_subtitle' => $title === '' ? 'One Line Shot' : $title,
                    'requires_response' => false,
                ]
            );
        })->all();

        return $this->success([
            'items' => $items,
            'total' => count($items),
            'date' => $today,
            'settings' => $settings,
            'summary' => [
                'enabled' => true,
                'daily_limit' => $limit,
                'frequency_minutes' => $scheduleSettings->smart_review_frequency_minutes,
                'next_time_label' => $items[0]['scheduled_time_label'] ?? null,
            ],
        ]);
    }

    public function getDailyQueue(Request $request)
    {
        $user = $request->user();
        $today = now()->toDateString();
        $settings = $this->flashcardSettings($user->id);

        if (!$settings->smart_review_enabled) {
            return $this->success([
                'queue' => [],
                'pending' => [],
                'reviewed_today' => [],
                'total' => 0,
                'reviewed_total' => 0,
                'completed_today' => false,
                'date' => $today,
                'settings' => $settings,
            ]);
        }

        $packs = FlashcardPack::forUser($user->id)
            ->whereNull('parent_pack_id')
            ->active()
            ->where('smart_review_enabled', true)
            ->get()
            ->sortBy(fn (FlashcardPack $pack) => $this->packPriorityWeight($pack));

        $candidates = collect();
        $reviewedCandidates = collect();

        foreach ($packs as $pack) {
            if (!$this->packIsScheduledForDate($pack, now())) {
                continue;
            }

            $items = $pack->effectiveItems()
                ->with('pack:id,title,color,display_mode')
                ->get()
                ->filter(fn (FlashcardItem $item) => $item->resolved_item_type !== 'one_line')
                ->values();

            if ($items->isEmpty()) {
                continue;
            }

            $progressMap = FlashcardProgress::where('user_id', $user->id)
                ->whereIn('item_id', $items->pluck('id'))
                ->get()
                ->keyBy('item_id');

            $reviewedItems = $items
                ->map(function (FlashcardItem $item) use ($progressMap) {
                    $item->user_progress = $progressMap->get($item->id);

                    return $item;
                })
                ->filter(fn (FlashcardItem $item) => $item->user_progress?->last_shown_at?->toDateString() === now()->toDateString())
                ->values();

            foreach ($reviewedItems as $item) {
                $reviewedCandidates->push([
                    'pack' => $pack,
                    'item' => $item,
                    'last_shown_at' => $item->user_progress?->last_shown_at,
                ]);
            }

            $dueItems = $items
                ->map(function (FlashcardItem $item) use ($progressMap) {
                    $item->user_progress = $progressMap->get($item->id);

                    return $item;
                })
                ->filter(fn (FlashcardItem $item) => $item->user_progress?->last_shown_at?->toDateString() !== now()->toDateString())
                ->sortBy(function (FlashcardItem $item) {
                    return [
                        -1 * ($item->user_progress?->review_weight ?? 2),
                        $item->user_progress?->last_shown_at?->timestamp ?? 0,
                        match ($item->priority) {
                            'critical' => 0,
                            'high' => 1,
                            default => 2,
                        },
                        $item->sort_order,
                    ];
                })
                ->values();

            if ($dueItems->isEmpty() && $reviewedItems->isNotEmpty()) {
                $dueItems = $this->restartItemsForPack($pack, $reviewedItems);
            }

            $dueItems->each(function (FlashcardItem $item) use ($pack, $candidates) {
                $candidates->push(['pack' => $pack, 'item' => $item]);
            });
        }

        $selected = $candidates
            ->sortBy(function (array $entry) {
                /** @var FlashcardPack $pack */
                $pack = $entry['pack'];
                /** @var FlashcardItem $item */
                $item = $entry['item'];

                return [
                    $this->packPriorityWeight($pack),
                    -1 * ($item->user_progress?->review_weight ?? 2),
                    $item->user_progress?->last_shown_at?->timestamp ?? 0,
                    match ($item->priority) {
                        'critical' => 0,
                        'high' => 1,
                        default => 2,
                    },
                    $item->sort_order,
                ];
            })
            ->take((int) ($settings->daily_card_limit ?? 5))
            ->values();

        $reviewedSelected = $reviewedCandidates
            ->sortBy(function (array $entry) {
                return $entry['last_shown_at']?->timestamp ?? 0;
            })
            ->values();

        $reviewedCount = $reviewedSelected->count();
        $dueCount = $selected->count();
        $reviewedScheduleTimes = $this->resolveScheduledTimes($settings, $reviewedCount, 0);
        $queueScheduleTimes = $this->resolveScheduledTimes($settings, $dueCount, 0);

        $reviewedToday = [];
        foreach ($reviewedSelected as $index => $entry) {
            /** @var FlashcardPack $pack */
            $pack = $entry['pack'];
            /** @var FlashcardItem $item */
            $item = $entry['item'];
            $scheduledTime = $item->user_progress?->last_shown_at
                ?? $reviewedScheduleTimes[$index]
                ?? now();

            $reviewedToday[] = $this->dailyQueueItem(
                $pack,
                $item,
                $scheduledTime,
                true,
                $settings
            );
        }

        $queue = $selected->map(function (array $entry, int $index) use ($queueScheduleTimes, $settings) {
            /** @var FlashcardPack $pack */
            $pack = $entry['pack'];
            /** @var FlashcardItem $item */
            $item = $entry['item'];
            $scheduledTime = $queueScheduleTimes[$index] ?? now();

            return $this->dailyQueueItem($pack, $item, $scheduledTime, false, $settings);
        })->all();

        usort($queue, function ($a, $b) {
            return [
                $a['pack_priority_weight'] ?? 1,
                !($a['available_now'] ?? false),
                $a['scheduled_time'] ?? '',
            ] <=> [
                $b['pack_priority_weight'] ?? 1,
                !($b['available_now'] ?? false),
                $b['scheduled_time'] ?? '',
            ];
        });
        usort($reviewedToday, fn ($a, $b) => strcmp($b['reviewed_at'] ?? '', $a['reviewed_at'] ?? ''));

        return $this->success([
            'queue' => $queue,
            'pending' => $queue,
            'reviewed_today' => $reviewedToday,
            'total' => count($queue),
            'reviewed_total' => count($reviewedToday),
            'completed_today' => count($queue) === 0 && count($reviewedToday) > 0,
            'date' => $today,
            'settings' => $settings,
        ]);
    }

    private function dailyQueueItem(
        FlashcardPack $pack,
        FlashcardItem $item,
        Carbon|string $scheduledTime,
        bool $reviewed = false,
        ?FlashcardUserSetting $settings = null
    ): array {
        $progress = $item->user_progress ?? null;
        $settings ??= $this->defaultSettingsObject($pack->user_id);
        $scheduledAt = $scheduledTime instanceof Carbon
            ? $scheduledTime->copy()
            : now()->copy()->startOfDay()->addMinutes($this->timeToMinute($scheduledTime) ?? ((now()->hour * 60) + now()->minute));

        return [
            'item_id' => $item->id,
            'pack_id' => $pack->id,
            'pack_title' => $pack->title,
            'pack_color' => $pack->color,
            'pack_priority' => $pack->pack_priority ?? 'medium',
            'pack_priority_weight' => $this->packPriorityWeight($pack),
            'pack_frequency_minutes' => $settings->smart_review_frequency_minutes ?? 30,
            'schedule_mode' => $pack->schedule_mode ?? $this->legacyScheduleMode($pack->repeat_cycle ?? 'daily'),
            'item_type' => $item->resolved_item_type,
            'item_color' => $item->resolved_color,
            'front_content' => $item->front_content,
            'back_content' => $item->back_content,
            'options' => $item->options,
            'correct_option' => $item->correct_option,
            'priority' => $item->priority,
            'scheduled_at' => $this->isoWithAppTimezone($scheduledAt),
            'scheduled_time' => $scheduledAt->format('H:i'),
            'scheduled_time_label' => $this->formatAppTimeLabel($scheduledAt),
            'available_now' => $scheduledAt->lessThanOrEqualTo(now()) && $this->globalSettingsAllowNow($settings),
            'reviewed_today' => $reviewed,
            'reviewed_at' => $this->isoWithAppTimezone($progress?->last_shown_at),
            'reviewed_time' => $progress?->last_shown_at?->format('H:i'),
            'reviewed_time_label' => $this->formatAppTimeLabel($progress?->last_shown_at),
            'last_response' => $progress?->last_response,
            'last_response_label' => $this->responseLabel($progress?->last_response),
            'next_review_at' => $this->isoWithAppTimezone($progress?->next_review_at),
            'next_review_date' => $progress?->next_review_at?->toDateString(),
            'next_review_time' => $progress?->next_review_at?->format('H:i'),
            'next_review_time_label' => $this->formatAppTimeLabel($progress?->next_review_at),
            'times_shown' => $progress?->times_shown ?? 0,
            'times_correct' => $progress?->times_correct ?? 0,
            'accuracy' => $progress?->accuracy ?? 0,
            'response_actions' => [
                ['key' => 'easy', 'label' => 'سهل - تقليل الظهور', 'effect' => 'less_frequent'],
                ['key' => 'medium', 'label' => 'متوسط - عادي', 'effect' => 'balanced'],
                ['key' => 'hard', 'label' => 'صعب - زيادة الظهور', 'effect' => 'high_priority'],
            ],
        ];
    }

    public function upcoming(Request $request)
    {
        $user = $request->user();
        $packs = FlashcardPack::forUser($user->id)
            ->whereNull('parent_pack_id')
            ->active()
            ->get();

        $items = collect();

        foreach ($packs as $pack) {
            $packItems = $pack->effectiveItems()
                ->with('pack:id,title,color,display_mode')
                ->orderBy('sort_order')
                ->orderBy('id')
                ->get();

            if ($packItems->isEmpty()) {
                continue;
            }

            $progressMap = FlashcardProgress::where('user_id', $user->id)
                ->whereIn('item_id', $packItems->pluck('id'))
                ->get()
                ->keyBy('item_id');

            foreach ($packItems as $item) {
                $progress = $progressMap->get($item->id);
                $reviewedToday = $progress?->last_shown_at?->toDateString() === now()->toDateString();
                $nextReviewAt = $reviewedToday
                    ? ($this->nextPackScheduledAt($pack, now()->addDay()->startOfDay()) ?? now()->copy()->addDay())
                    : now();

                $items->push([
                    'item_id' => $item->id,
                    'pack_id' => $pack->id,
                    'pack_title' => $pack->title,
                    'pack_color' => $pack->color,
                    'item_type' => $item->resolved_item_type,
                    'item_color' => $item->resolved_color,
                    'front_content' => $item->front_content,
                    'back_content' => $item->back_content,
                    'options' => $item->options,
                    'correct_option' => $item->correct_option,
                    'priority' => $item->priority,
                    'next_review_at' => $nextReviewAt->toIso8601String(),
                    'next_review_date' => $reviewedToday ? $nextReviewAt->toDateString() : '',
                    'next_review_time' => $reviewedToday ? $nextReviewAt->format('H:i') : '',
                    'next_review_time_label' => $reviewedToday ? $this->formatTimeLabel($nextReviewAt) : 'الآن',
                    'last_response' => $progress?->last_response,
                    'times_shown' => $progress?->times_shown ?? 0,
                    'times_correct' => $progress?->times_correct ?? 0,
                    'accuracy' => $progress?->accuracy ?? 0,
                    'is_due' => !$reviewedToday,
                ]);
            }
        }

        $items = $items
            ->sortBy([
                ['next_review_at', 'asc'],
                ['priority', 'asc'],
            ])
            ->values();

        $groups = [
            'today' => [],
            'tomorrow' => [],
            'this_week' => [],
            'later' => [],
        ];

        $now = now();
        $endOfToday = $now->copy()->endOfDay();
        $endOfTomorrow = $now->copy()->addDay()->endOfDay();
        $endOfWeek = $now->copy()->endOfWeek();

        foreach ($items as $item) {
            $next = Carbon::parse($item['next_review_at']);
            $key = match (true) {
                $next->lessThanOrEqualTo($endOfToday) => 'today',
                $next->lessThanOrEqualTo($endOfTomorrow) => 'tomorrow',
                $next->lessThanOrEqualTo($endOfWeek) => 'this_week',
                default => 'later',
            };
            $groups[$key][] = $item;
        }

        return $this->success([
            'groups' => $groups,
            'summary' => [
                'total' => $items->count(),
                'today' => count($groups['today']),
                'tomorrow' => count($groups['tomorrow']),
                'this_week' => count($groups['this_week']),
                'later' => count($groups['later']),
            ],
            'generated_at' => now()->toIso8601String(),
        ]);
    }

    public function history(Request $request)
    {
        $user = $request->user();
        $limit = min(200, max(20, (int) $request->input('limit', 100)));

        $query = FlashcardProgress::where('user_id', $user->id)
            ->whereNotNull('last_shown_at')
            ->with('item.pack:id,title,color,display_mode')
            ->latest('last_shown_at')
            ->limit($limit);

        if ($request->filled('response_level') && in_array($request->response_level, ['easy', 'medium', 'hard'], true)) {
            $query->where('last_response', $request->response_level);
        }

        $records = $query->get()
            ->filter(fn (FlashcardProgress $progress) => $progress->item !== null)
            ->map(function (FlashcardProgress $progress) {
                $item = $progress->item;
                $pack = $item->pack;

                return [
                    'progress_id' => $progress->id,
                    'item_id' => $item->id,
                    'pack_id' => $pack?->id,
                    'pack_title' => $pack?->title ?? 'حزمة مراجعة',
                    'pack_color' => $pack?->color ?? '#4338ca',
                    'item_type' => $item->resolved_item_type,
                    'item_color' => $item->resolved_color,
                    'front_content' => $item->front_content,
                    'priority' => $item->priority,
                    'last_response' => $progress->last_response,
                    'last_response_label' => $this->responseLabel($progress->last_response),
                    'last_shown_at' => $progress->last_shown_at?->toIso8601String(),
                    'last_shown_date' => $progress->last_shown_at?->toDateString(),
                    'last_shown_time' => $progress->last_shown_at?->format('H:i'),
                    'last_shown_time_label' => $this->formatTimeLabel($progress->last_shown_at),
                    'next_review_at' => $progress->next_review_at?->toIso8601String(),
                    'next_review_date' => $progress->next_review_at?->toDateString(),
                    'next_review_time' => $progress->next_review_at?->format('H:i'),
                    'next_review_time_label' => $this->formatTimeLabel($progress->next_review_at),
                    'times_shown' => $progress->times_shown,
                    'times_correct' => $progress->times_correct,
                    'accuracy' => $progress->accuracy,
                ];
            })
            ->values();

        $groups = [
            'today' => [],
            'yesterday' => [],
            'this_week' => [],
            'older' => [],
        ];

        $today = now()->toDateString();
        $yesterday = now()->subDay()->toDateString();
        $startOfWeek = now()->startOfWeek();

        foreach ($records as $record) {
            $date = Carbon::parse($record['last_shown_at']);
            $key = match (true) {
                $record['last_shown_date'] === $today => 'today',
                $record['last_shown_date'] === $yesterday => 'yesterday',
                $date->greaterThanOrEqualTo($startOfWeek) => 'this_week',
                default => 'older',
            };
            $groups[$key][] = $record;
        }

        return $this->success([
            'records' => $records,
            'groups' => $groups,
            'summary' => [
                'total' => $records->count(),
                'easy' => $records->where('last_response', 'easy')->count(),
                'medium' => $records->where('last_response', 'medium')->count(),
                'hard' => $records->where('last_response', 'hard')->count(),
                'average_accuracy' => round($records->avg('accuracy') ?? 0, 1),
            ],
            'generated_at' => now()->toIso8601String(),
        ]);
    }

    public function difficulty(Request $request)
    {
        $user = $request->user();
        $packs = FlashcardPack::forUser($user->id)
            ->whereNull('parent_pack_id')
            ->active()
            ->get();

        $groups = [
            'hard' => [],
            'medium' => [],
            'easy' => [],
            'unreviewed' => [],
        ];

        foreach ($packs as $pack) {
            $items = $pack->effectiveItems()
                ->with('pack:id,title,color,display_mode')
                ->orderBy('sort_order')
                ->orderBy('id')
                ->get();

            if ($items->isEmpty()) {
                continue;
            }

            $progressMap = FlashcardProgress::where('user_id', $user->id)
                ->whereIn('item_id', $items->pluck('id'))
                ->get()
                ->keyBy('item_id');

            foreach ($items as $item) {
                $progress = $progressMap->get($item->id);
                $key = $progress?->last_response ?: 'unreviewed';
                if (!in_array($key, ['easy', 'medium', 'hard'], true)) {
                    $key = 'unreviewed';
                }

                $groups[$key][] = [
                    'item_id' => $item->id,
                    'pack_id' => $pack->id,
                    'pack_title' => $pack->title,
                    'pack_color' => $pack->color,
                    'item_type' => $item->resolved_item_type,
                    'item_color' => $item->resolved_color,
                    'front_content' => $item->front_content,
                    'priority' => $item->priority,
                    'last_response' => $progress?->last_response,
                    'last_response_label' => $this->responseLabel($progress?->last_response),
                    'last_shown_at' => $progress?->last_shown_at?->toIso8601String(),
                    'last_shown_date' => $progress?->last_shown_at?->toDateString(),
                    'next_review_at' => $progress?->next_review_at?->toIso8601String(),
                    'next_review_date' => $progress?->next_review_at?->toDateString(),
                    'times_shown' => $progress?->times_shown ?? 0,
                    'times_correct' => $progress?->times_correct ?? 0,
                    'accuracy' => $progress?->accuracy ?? 0,
                ];
            }
        }

        return $this->success([
            'groups' => $groups,
            'summary' => [
                'total' => collect($groups)->flatten(1)->count(),
                'hard' => count($groups['hard']),
                'medium' => count($groups['medium']),
                'easy' => count($groups['easy']),
                'unreviewed' => count($groups['unreviewed']),
            ],
            'generated_at' => now()->toIso8601String(),
        ]);
    }

    public function analytics(Request $request)
    {
        $user = $request->user();
        $packs = FlashcardPack::forUser($user->id)
            ->whereNull('parent_pack_id')
            ->active()
            ->get();

        $packRows = collect();
        $allProgress = collect();
        $totalCards = 0;

        foreach ($packs as $pack) {
            $items = $pack->effectiveItems()->with('pack:id,title,color,display_mode')->get();
            $itemIds = $items->pluck('id');
            $progress = FlashcardProgress::where('user_id', $user->id)
                ->whereIn('item_id', $itemIds)
                ->get();

            $cardsCount = $items->count();
            $reviewedCount = $progress->whereNotNull('last_shown_at')->count();
            $accuracy = round($progress->avg('accuracy') ?? 0, 1);
            $hardCount = $progress->where('last_response', 'hard')->count();
            $lastActivity = $progress->max('last_shown_at');
            $totalCards += $cardsCount;
            $allProgress = $allProgress->merge($progress);

            $packRows->push([
                'pack_id' => $pack->id,
                'pack_title' => $pack->title,
                'pack_color' => $pack->color,
                'display_mode' => $pack->display_mode,
                'cards_count' => $cardsCount,
                'reviewed_count' => $reviewedCount,
                'pending_count' => max(0, $cardsCount - $reviewedCount),
                'accuracy' => $accuracy,
                'hard_count' => $hardCount,
                'last_activity_at' => $lastActivity?->toIso8601String(),
                'last_activity_date' => $lastActivity?->toDateString(),
            ]);
        }

        $reviewed = $allProgress->whereNotNull('last_shown_at');
        $averageAccuracy = round($reviewed->avg('accuracy') ?? 0, 1);
        $responseDistribution = [
            'easy' => $reviewed->where('last_response', 'easy')->count(),
            'medium' => $reviewed->where('last_response', 'medium')->count(),
            'hard' => $reviewed->where('last_response', 'hard')->count(),
        ];

        $bestPack = $packRows
            ->where('reviewed_count', '>', 0)
            ->sortByDesc('accuracy')
            ->first();

        $focusPack = $packRows
            ->where('reviewed_count', '>', 0)
            ->sortByDesc('hard_count')
            ->first();

        $lastActivity = $reviewed->max('last_shown_at');

        return $this->success([
            'summary' => [
                'total_packs' => $packs->count(),
                'total_cards' => $totalCards,
                'reviewed_cards' => $reviewed->count(),
                'pending_cards' => max(0, $totalCards - $reviewed->count()),
                'average_accuracy' => $averageAccuracy,
                'completion_rate' => $totalCards > 0 ? round(($reviewed->count() / $totalCards) * 100, 1) : 0,
                'last_activity_at' => $lastActivity?->toIso8601String(),
                'last_activity_date' => $lastActivity?->toDateString(),
            ],
            'response_distribution' => $responseDistribution,
            'best_pack' => $bestPack,
            'focus_pack' => $focusPack,
            'packs' => $packRows->sortByDesc('reviewed_count')->values(),
            'generated_at' => now()->toIso8601String(),
        ]);
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
            abort(422, 'Cannot move a pack inside one of its descendants.');
        }

        return $parentPack;
    }

    private function assertCanManageItems(FlashcardPack $pack): void
    {
        if ($pack->is_assigned) {
            abort(422, 'Assigned packs cannot be edited directly.');
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
            return $pack->sourcePack->items()->with('pack:id,title,color,display_mode')->orderBy('sort_order')->orderBy('id')->get();
        }

        return $pack->items()->with('pack:id,title,color,display_mode')->orderBy('sort_order')->orderBy('id')->get();
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

    private function guessImportMapping(array $columns): array
    {
        $mapping = [
            'item_type_col' => 0,
            'front_content_col' => 1,
            'back_content_col' => 2,
            'options_cols' => [2, 3, 4],
            'correct_option_col' => -1,
            'priority_col' => 9,
            'color_col' => 10,
        ];

        $hasMatchedOptions = false;
        foreach ($columns as $index => $name) {
            $nameLower = mb_strtolower(trim((string) $name));

            if ($nameLower === 'type' || $nameLower === 'item_type' || str_contains($nameLower, 'نوع')) {
                $mapping['item_type_col'] = $index;
            } elseif ($nameLower === 'front' || $nameLower === 'question' || str_contains($nameLower, 'سؤال') || str_contains($nameLower, 'المحتوى الأمامي') || str_contains($nameLower, 'النص')) {
                $mapping['front_content_col'] = $index;
            } elseif ($nameLower === 'back' || $nameLower === 'answer' || str_contains($nameLower, 'إجابة') || str_contains($nameLower, 'الاجابة') || str_contains($nameLower, 'المحتوى الخلفي')) {
                $mapping['back_content_col'] = $index;
            } elseif (str_contains($nameLower, 'correct') || str_contains($nameLower, 'صحيح')) {
                $mapping['correct_option_col'] = $index;
            } elseif ($nameLower === 'priority' || str_contains($nameLower, 'أولوية') || str_contains($nameLower, 'الأولوية')) {
                $mapping['priority_col'] = $index;
            } elseif ($nameLower === 'color' || str_contains($nameLower, 'لون') || str_contains($nameLower, 'اللون')) {
                $mapping['color_col'] = $index;
            } elseif (preg_match('/(option|choice|خيار|إختيار|اختيار)\s*\d*/iu', $nameLower) || in_array($nameLower, ['a', 'b', 'c', 'd', 'e', 'f'], true)) {
                if (!$hasMatchedOptions) {
                    $mapping['options_cols'] = [];
                    $hasMatchedOptions = true;
                }
                $mapping['options_cols'][] = $index;
            }
        }

        foreach (['priority_col', 'color_col'] as $key) {
            if ($mapping[$key] >= count($columns)) {
                $mapping[$key] = -1;
            }
        }

        return $mapping;
    }

    private function normalizeImportItemType(string $value): ?string
    {
        $normalized = mb_strtolower(trim($value));

        return match ($normalized) {
            'flash_card', 'flash card', 'card', 'بطاقة', 'بطاقة تعليمية' => 'flash_card',
            'one_line', 'one line', 'line', 'نص', 'نص واحد' => 'one_line',
            'qa', 'q&a', 'question_answer', 'سؤال', 'سؤال وجواب' => 'qa',
            'mcq', 'multiple_choice', 'choice', 'اختيارات', 'اختيار من متعدد' => 'mcq',
            default => null,
        };
    }

    private function normalizeImportPriority(string $value): string
    {
        $normalized = mb_strtolower(trim($value));

        return match ($normalized) {
            'critical', 'حرجة', 'صعب', 'صعبة' => 'critical',
            'high', 'عالية', 'متوسط', 'متوسطة' => 'high',
            default => 'normal',
        };
    }

    private function validImportHexColor(string $value): ?string
    {
        $value = trim($value);

        return preg_match('/^#[0-9a-fA-F]{6}$/', $value) ? $value : null;
    }

    private function parseSpreadsheet(string $path, string $extension): array
    {
        $rows = [];

        if ($extension === 'csv') {
            $handle = fopen($path, 'r');
            while (($data = fgetcsv($handle)) !== false) {
                $rows[] = $data;
            }
            fclose($handle);
        } else {
            if (!class_exists('\PhpOffice\PhpSpreadsheet\IOFactory')) {
                throw new \RuntimeException('PhpSpreadsheet is required to read Excel files.');
            }

            $spreadsheet = \PhpOffice\PhpSpreadsheet\IOFactory::load($path);
            $worksheet = $spreadsheet->getActiveSheet();

            foreach ($worksheet->getRowIterator() as $row) {
                $cellIterator = $row->getCellIterator();
                $cellIterator->setIterateOnlyExistingCells(false);
                $data = [];

                foreach ($cellIterator as $cell) {
                    $data[] = $cell->getValue();
                }

                $rows[] = $data;
            }
        }

        return $rows;
    }

    private function looksLikeHeader(array $row): bool
    {
        $headerKeywords = ['front', 'back', 'question', 'answer', 'column', 'type', 'item_type', 'نوع', 'السؤال', 'إجابة', 'الاجابة', 'النص', 'المحتوى'];

        foreach ($row as $cell) {
            $cellStr = mb_strtolower(trim((string) ($cell ?? '')));
            if ($cellStr === '') {
                continue;
            }

            foreach ($headerKeywords as $keyword) {
                if (str_contains($cellStr, $keyword)) {
                    return true;
                }
            }
        }

        return false;
    }

    private function mapLegacyResponse(bool $isCorrect): string
    {
        return $isCorrect ? 'easy' : 'hard';
    }

    private function responseLabel(?string $response): string
    {
        return match ($response) {
            'easy' => 'سهل - تقليل الظهور',
            'medium' => 'متوسط - عادي',
            'hard' => 'صعب - زيادة الظهور',
            default => 'لم تُراجع',
        };
    }

    private function calculateNextReview(FlashcardPack $pack, FlashcardProgress $progress, string $responseLevel)
    {
        return $this->nextPackScheduledAt($pack, now()->addDay()->startOfDay());
    }

    private function nextPackScheduledAt(FlashcardPack $pack, Carbon $from): ?Carbon
    {
        $mode = $pack->schedule_mode ?? $this->legacyScheduleMode($pack->repeat_cycle ?? 'daily');
        if ($mode === 'manual') {
            return null;
        }

        $startMinute = $this->timeToMinute($pack->active_from_time) ?? (8 * 60);

        for ($offset = 0; $offset < 370; $offset++) {
            $date = $from->copy()->addDays($offset);
            if (!$this->packIsScheduledForDate($pack, $date)) {
                continue;
            }

            return $date
                ->startOfDay()
                ->addMinutes($startMinute)
                ->seconds(0)
                ->microsecond(0);
        }

        return null;
    }

    private function flashcardSettings(int $userId): FlashcardUserSetting
    {
        return FlashcardUserSetting::firstOrCreate(
            ['user_id' => $userId],
            $this->defaultSettings()
        );
    }

    private function defaultSettingsObject(int $userId): FlashcardUserSetting
    {
        $settings = new FlashcardUserSetting($this->defaultSettings());
        $settings->user_id = $userId;

        return $settings;
    }

    private function defaultSettings(): array
    {
        return [
            'smart_review_enabled' => true,
            'active_from_time' => null,
            'active_to_time' => null,
            'quiet_start' => null,
            'quiet_end' => null,
            'daily_card_limit' => 5,
            'smart_review_frequency_minutes' => 30,
            'auto_restart_enabled' => false,
            'prompt_mode' => 'app_and_notification',
            'one_line_notifications_enabled' => true,
            'one_line_daily_limit' => 5,
            'one_line_frequency_minutes' => 30,
            'one_line_active_from_time' => null,
            'one_line_active_to_time' => null,
            'one_line_quiet_start' => null,
            'one_line_quiet_end' => null,
        ];
    }

    private function oneLineScheduleSettings(FlashcardUserSetting $settings): FlashcardUserSetting
    {
        return new FlashcardUserSetting([
            'smart_review_enabled' => $settings->one_line_notifications_enabled,
            'active_from_time' => $settings->one_line_active_from_time ?? $settings->active_from_time,
            'active_to_time' => $settings->one_line_active_to_time ?? $settings->active_to_time,
            'quiet_start' => $settings->one_line_quiet_start ?? $settings->quiet_start,
            'quiet_end' => $settings->one_line_quiet_end ?? $settings->quiet_end,
            'daily_card_limit' => $settings->one_line_daily_limit ?? $settings->daily_card_limit ?? 5,
            'smart_review_frequency_minutes' => $settings->one_line_frequency_minutes
                ?? $settings->smart_review_frequency_minutes
                ?? 30,
            'auto_restart_enabled' => false,
            'prompt_mode' => 'notification_only',
        ]);
    }

    private function packPriorityWeight(FlashcardPack $pack): int
    {
        return match ($pack->pack_priority ?? 'medium') {
            'high' => 0,
            'low' => 2,
            default => 1,
        };
    }

    private function globalSettingsAllowNow(FlashcardUserSetting $settings): bool
    {
        $now = now();

        $currentMinute = ($now->hour * 60) + $now->minute;
        $activeStart = $this->timeToMinute($settings->active_from_time);
        $activeEnd = $this->timeToMinute($settings->active_to_time);

        if (($activeStart !== null || $activeEnd !== null)
            && !$this->minuteInWindow($currentMinute, $activeStart ?? 0, $activeEnd ?? 1439)) {
            return false;
        }

        $quietStart = $this->timeToMinute($settings->quiet_start);
        $quietEnd = $this->timeToMinute($settings->quiet_end);

        return !($quietStart !== null
            && $quietEnd !== null
            && $this->minuteInWindow($currentMinute, $quietStart, $quietEnd));
    }

    private function packIsScheduledForDate(FlashcardPack $pack, Carbon $date): bool
    {
        $mode = $pack->schedule_mode ?? $this->legacyScheduleMode($pack->repeat_cycle ?? 'daily');
        $weekdays = collect($pack->schedule_weekdays ?? [])
            ->map(fn ($day) => (int) $day)
            ->values();

        return match ($mode) {
            'manual' => false,
            'weekdays' => $weekdays->isEmpty() || $weekdays->contains($date->dayOfWeek),
            'weekly' => $weekdays->isNotEmpty()
                ? $weekdays->contains($date->dayOfWeek)
                : $date->dayOfWeek === $pack->created_at?->dayOfWeek,
            'monthly' => $date->day === min((int) ($pack->created_at?->day ?? 1), $date->daysInMonth),
            default => true,
        };
    }

    private function restartItemsForPack(FlashcardPack $pack, Collection $reviewedItems): Collection
    {
        return match ($pack->restart_mode ?? 'none') {
            'all' => $reviewedItems,
            'hard_only',
            'wrong_only' => $reviewedItems
                ->filter(fn (FlashcardItem $item) => $item->user_progress?->last_response === 'hard')
                ->values(),
            default => collect(),
        };
    }

    private function resolveScheduledTimes(FlashcardUserSetting $settings, int $count, int $reviewedCount = 0): array
    {
        $totalCount = $count + $reviewedCount;
        if ($totalCount <= 0) {
            return [];
        }

        $frequency = max(1, (int) ($settings->smart_review_frequency_minutes ?? 30));
        $now = now()->copy()->seconds(0)->microsecond(0);
        $cursor = $now->copy();
        if ($settings->active_from_time) {
            $parts = explode(':', $settings->active_from_time);
            if (count($parts) >= 2) {
                $activeStart = now()->startOfDay()
                    ->hour((int)$parts[0])
                    ->minute((int)$parts[1])
                    ->seconds(0)
                    ->microsecond(0);
                if ($activeStart->isAfter($now)) {
                    $cursor = $activeStart;
                }
            }
        } elseif ($now->hour < 8) {
            $cursor = now()->startOfDay();
            $cursor->hour(8)->minute(0);
        }
        $cursor->seconds(0)->microsecond(0);

        $selected = [];
        $guard = 0;

        while (count($selected) < $totalCount && $guard < 2880) {
            if ($this->settingsAllowDateTime($settings, $cursor)) {
                $selected[] = $cursor->copy();
                $cursor->addMinutes($frequency);
                continue;
            }

            $cursor->addMinute();
            $guard++;
        }

        if (empty($selected)) {
            $selected[] = now()->copy()->seconds(0);
        }

        while (count($selected) < $totalCount) {
            $selected[] = end($selected)->copy()->addMinutes($frequency);
        }

        return array_slice($selected, $reviewedCount);
    }

    private function settingsAllowDateTime(FlashcardUserSetting $settings, Carbon $dateTime): bool
    {
        $minute = ($dateTime->hour * 60) + $dateTime->minute;
        $activeStart = $this->timeToMinute($settings->active_from_time);
        $activeEnd = $this->timeToMinute($settings->active_to_time);

        if (($activeStart !== null || $activeEnd !== null)
            && !$this->minuteInWindow($minute, $activeStart ?? 0, $activeEnd ?? 1439)) {
            return false;
        }

        $quietStart = $this->timeToMinute($settings->quiet_start);
        $quietEnd = $this->timeToMinute($settings->quiet_end);

        return !($quietStart !== null
            && $quietEnd !== null
            && $this->minuteInWindow($minute, $quietStart, $quietEnd));
    }

    private function formatTimeLabel(?Carbon $dateTime): ?string
    {
        if (!$dateTime) {
            return null;
        }

        return str_replace(['AM', 'PM'], ['ص', 'م'], $dateTime->format('g:i A'));
    }

    private function isoWithAppTimezone(?Carbon $dateTime): ?string
    {
        if (!$dateTime) {
            return null;
        }

        return $dateTime
            ->copy()
            ->timezone(config('app.timezone'))
            ->format('Y-m-d\TH:i:sP');
    }

    private function formatAppTimeLabel(?Carbon $dateTime): ?string
    {
        if (!$dateTime) {
            return null;
        }

        return str_replace(
            ['AM', 'PM'],
            ['ص', 'م'],
            $dateTime->copy()->timezone(config('app.timezone'))->format('g:i A')
        );
    }

    private function timeStringIsNowOrPast(string $time): bool
    {
        $minute = $this->timeToMinute($time);
        if ($minute === null) {
            return true;
        }

        $nowMinute = (now()->hour * 60) + now()->minute;

        return $minute <= $nowMinute;
    }

    private function timeToMinute(mixed $time): ?int
    {
        if (!$time) {
            return null;
        }

        $value = (string) $time;
        if (!preg_match('/^(\d{1,2}):(\d{2})/', $value, $matches)) {
            return null;
        }

        $hour = max(0, min(23, (int) $matches[1]));
        $minute = max(0, min(59, (int) $matches[2]));

        return ($hour * 60) + $minute;
    }

    private function minuteInWindow(int $minute, int $start, int $end): bool
    {
        if ($start === $end) {
            return true;
        }

        if ($start < $end) {
            return $minute >= $start && $minute <= $end;
        }

        return $minute >= $start || $minute <= $end;
    }

    private function resolveQueueHours(FlashcardPack $pack): array
    {
        $startHour = 8;
        $endHour = 22;

        if ($pack->quiet_start && $pack->quiet_end) {
            $quietStartHour = (int) substr((string) $pack->quiet_start, 0, 2);
            $quietEndHour = (int) substr((string) $pack->quiet_end, 0, 2);

            if ($quietStartHour < $quietEndHour) {
                $startHour = $quietEndHour;
            } else {
                $endHour = $quietStartHour;
            }
        }

        if ($endHour <= $startHour) {
            $startHour = 8;
            $endHour = 22;
        }

        return [$startHour, $endHour];
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
