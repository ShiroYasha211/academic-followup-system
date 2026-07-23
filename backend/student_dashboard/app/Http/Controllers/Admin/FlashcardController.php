<?php

namespace App\Http\Controllers\Admin;

use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Models\FlashcardItem;
use App\Models\FlashcardPack;
use App\Models\PublicPackStore;
use App\Models\StudentNotification;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class FlashcardController extends Controller
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
                $query->where('is_public', true)
                    ->whereHas('user', fn ($q) => $q->where('role', 'admin'));
            } elseif ($request->type === 'private') {
                $query->where('is_public', false)
                    ->whereHas('user', fn ($q) => $q->where('role', 'admin'));
            }
        } else {
            $query->whereHas('user', fn ($q) => $q->where('role', 'admin'));
        }

        if ($request->filled('display_mode')) {
            $displayMode = $request->display_mode;
            $query->where(function ($q) use ($displayMode) {
                $q->where('display_mode', $displayMode)
                    ->orWhereHas('items', fn ($items) => $items->where('item_type', $displayMode));
            });
        }

        $packs = $query->latest()->paginate(20)->withQueryString();
        $packs->getCollection()->transform(function (FlashcardPack $pack) {
            $pack->items_count = $pack->cardsCount();
            $pack->children_count = $pack->childPacks()->count();
            $pack->item_type_summary = $this->itemTypeSummary($pack);

            return $pack;
        });

        $totalPacks = FlashcardPack::count();
        $publicPacks = FlashcardPack::where('is_public', true)
            ->whereHas('user', fn ($q) => $q->where('role', 'admin'))
            ->count();
        $totalCards = FlashcardItem::count();
        $totalUsers = FlashcardPack::distinct('user_id')->count('user_id');

        return view('admin.flashcards.index', compact('packs', 'totalPacks', 'publicPacks', 'totalCards', 'totalUsers'));
    }

    public function create()
    {
        $parentPacks = $this->availableAdminParentPacks();

        return view('admin.flashcards.create', compact('parentPacks'));
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string|max:1000',
            'color' => 'nullable|string|max:7',
            'display_mode' => 'nullable|in:flash_card,one_line,qa,mcq',
            'category' => 'nullable|string|max:255',
            'is_active' => 'nullable|boolean',
            'parent_pack_id' => 'nullable|integer',
        ]);

        $parentPack = $this->resolveAdminParentPack($validated['parent_pack_id'] ?? null);

        $pack = FlashcardPack::create([
            'user_id' => Auth::id(),
            'title' => $validated['title'],
            'description' => $validated['description'] ?? null,
            'color' => $validated['color'] ?? '#4f46e5',
            'display_mode' => $validated['display_mode'] ?? 'one_line',
            'daily_notification_count' => 5,
            'daily_card_limit' => 5,
            'repeat_cycle' => 'daily',
            'schedule_mode' => 'daily',
            'pack_priority' => 'medium',
            'smart_review_enabled' => true,
            'smart_review_frequency_minutes' => 30,
            'restart_mode' => 'none',
            'quiet_start' => null,
            'quiet_end' => null,
            'is_active' => $request->has('is_active'),
            'notifications_enabled' => true,
            'is_public' => true,
            'parent_pack_id' => $parentPack?->id,
        ]);

        if (!$parentPack) {
            PublicPackStore::create([
                'pack_id' => $pack->id,
                'published_by' => Auth::id(),
                'category' => $validated['category'] ?? null,
                'is_active' => true,
            ]);
        }

        return redirect()->route('admin.flashcards.show', $pack)
            ->with('success', 'تم إنشاء الحزمة العامة بنجاح.');
    }

    public function show(FlashcardPack $flashcard)
    {
        $flashcard->load(['user:id,name,role', 'storeEntry']);
        $flashcard->items_count = $flashcard->cardsCount();
        $items = $this->displayItemsForPack($flashcard)->values();
        $childPacks = $flashcard->childPacks()->latest()->get();
        foreach ($childPacks as $childPack) {
            $childPack->items_count = $childPack->cardsCount();
        }

        $parentPacks = $this->availableAdminParentPacks($flashcard);

        return view('admin.flashcards.show', compact('flashcard', 'items', 'childPacks', 'parentPacks'));
    }

    public function edit(FlashcardPack $flashcard)
    {
        $flashcard->load('storeEntry');
        $parentPacks = $this->availableAdminParentPacks($flashcard);

        return view('admin.flashcards.edit', compact('flashcard', 'parentPacks'));
    }

    public function update(Request $request, FlashcardPack $flashcard)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string|max:1000',
            'color' => 'nullable|string|max:7',
            'display_mode' => 'nullable|in:flash_card,one_line,qa,mcq',
            'category' => 'nullable|string|max:255',
            'is_active' => 'nullable|boolean',
            'parent_pack_id' => 'nullable|integer',
        ]);

        $parentPack = $this->resolveAdminParentPack($validated['parent_pack_id'] ?? null, $flashcard);

        $flashcard->update([
            'title' => $validated['title'],
            'description' => $validated['description'] ?? null,
            'color' => $validated['color'] ?? '#4f46e5',
            'display_mode' => $validated['display_mode'] ?? $flashcard->display_mode,
            'is_active' => $request->has('is_active'),
            'parent_pack_id' => $parentPack?->id,
        ]);

        if ($flashcard->storeEntry) {
            $flashcard->storeEntry->update(['category' => $validated['category'] ?? null]);
        }

        return redirect()->route('admin.flashcards.show', $flashcard)
            ->with('success', 'تم تحديث الحزمة بنجاح.');
    }

    public function destroy(FlashcardPack $flashcard)
    {
        $this->deletePackTree($flashcard);

        return redirect()->route('admin.flashcards.index')
            ->with('success', 'تم حذف الحزمة وكل التفرعات التابعة لها.');
    }

    public function publishToStore(Request $request, $id)
    {
        $pack = FlashcardPack::findOrFail($id);

        if (!$pack->user || !$pack->user->hasRole(UserRole::ADMIN)) {
            return back()->with('error', 'لا يمكن نشر هذه الحزمة في المتجر.');
        }

        $storeEntry = PublicPackStore::where('pack_id', $pack->id)->first();

        if ($storeEntry) {
            $storeEntry->update(['is_active' => true]);
        } else {
            PublicPackStore::create([
                'pack_id' => $pack->id,
                'published_by' => Auth::id(),
                'category' => $request->input('category', 'General'),
                'is_active' => true,
            ]);
        }

        $pack->update(['is_public' => true]);

        return back()->with('success', 'تم تفعيل ظهور الحزمة في المتجر.');
    }

    public function cloneAndReview(FlashcardPack $flashcard)
    {
        $newPack = DB::transaction(function () use ($flashcard) {
            return $this->cloneEditableTree($flashcard, Auth::id(), null, true);
        });

        return redirect()->route('admin.flashcards.show', $newPack)
            ->with('success', 'تم إنشاء نسخة مراجعة كاملة مع الحزم الفرعية والعناصر.');
    }

    public function searchStudent(Request $request)
    {
        $request->validate(['student_number' => 'required|string']);

        $user = User::with('college')->where('student_number', $request->student_number)->first();

        if ($user) {
            return response()->json([
                'success' => true,
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'student_number' => $user->student_number,
                    'college' => $user->college->name ?? 'غير محدد',
                ],
            ]);
        }

        return response()->json(['success' => false, 'message' => 'لم يتم العثور على طالب بهذا الرقم']);
    }

    public function assignToUser(Request $request, FlashcardPack $flashcard)
    {
        $request->validate([
            'user_id' => 'required|exists:users,id',
        ]);

        $targetUser = User::findOrFail($request->user_id);
        $existing = FlashcardPack::where('user_id', $targetUser->id)
            ->where('source_pack_id', $flashcard->id)
            ->whereNull('parent_pack_id')
            ->first();

        if ($existing) {
            return back()->with('info', "المستخدم «{$targetUser->name}» لديه هذه الحزمة بالفعل.");
        }

        DB::transaction(function () use ($flashcard, $targetUser) {
            $this->cloneAssignedTree($flashcard, $targetUser->id);
        });

        $this->notifyFlashcardAssigned($flashcard, $targetUser);

        return back()->with('success', "تم تعيين الحزمة للمستخدم «{$targetUser->name}» بكل تفرعاتها.");
    }

    public function storeManagement(Request $request)
    {
        $query = PublicPackStore::with(['pack.user', 'pack'])
            ->where('is_active', true)
            ->whereHas('pack', fn ($q) => $q->where('is_public', true));

        if ($request->filled('search')) {
            $search = $request->search;
            $query->whereHas('pack', function ($q) use ($search) {
                $q->where('title', 'like', "%{$search}%");
            });
        }

        if ($request->filled('display_mode')) {
            $query->whereHas('pack', function ($q) use ($request) {
                $displayMode = $request->display_mode;
                $q->where(function ($packQuery) use ($displayMode) {
                    $packQuery->where('display_mode', $displayMode)
                        ->orWhereHas('items', fn ($items) => $items->where('item_type', $displayMode));
                });
            });
        }

        $storeItems = $query->latest()->paginate(15);
        $storeItems->getCollection()->transform(function (PublicPackStore $storeItem) {
            $storeItem->pack->items_count = $storeItem->pack->cardsCount();
            $storeItem->pack->item_type_summary = $this->itemTypeSummary($storeItem->pack);

            return $storeItem;
        });

        return view('admin.flashcards.store', compact('storeItems'));
    }

    public function toggleVisibility(Request $request, FlashcardPack $flashcard)
    {
        if (!$flashcard->is_public && (!$flashcard->user || !$flashcard->user->hasRole(UserRole::ADMIN))) {
            $message = 'لا يمكن جعل حزمة غير إدارية عامة مباشرة. أنشئ نسخة مراجعة أولًا.';

            if ($request->wantsJson() || $request->isJson()) {
                return response()->json(['success' => false, 'message' => $message], 403);
            }

            return back()->with('error', $message);
        }

        $flashcard->is_public = !$flashcard->is_public;
        $flashcard->save();

        if ($flashcard->is_public) {
            PublicPackStore::updateOrCreate(
                ['pack_id' => $flashcard->id],
                [
                    'published_by' => Auth::id(),
                    'category' => $flashcard->storeEntry->category ?? 'General',
                    'is_active' => true,
                ]
            );
        } elseif ($flashcard->storeEntry) {
            $flashcard->storeEntry->update(['is_active' => false]);
        }

        $message = $flashcard->is_public ? 'الحزمة أصبحت عامة في المتجر.' : 'تم إخفاء الحزمة من المتجر.';

        if ($request->wantsJson() || $request->isJson()) {
            return response()->json(['success' => true, 'is_public' => $flashcard->is_public, 'message' => $message]);
        }

        return back()->with('success', $message);
    }

    public function toggleFeatured(FlashcardPack $flashcard)
    {
        $storeEntry = PublicPackStore::where('pack_id', $flashcard->id)->first();

        if (!$storeEntry) {
            return back()->with('error', 'هذه الحزمة غير موجودة في المتجر.');
        }

        $storeEntry->update(['is_featured' => !$storeEntry->is_featured]);

        return back()->with(
            'success',
            $storeEntry->is_featured ? 'تم تمييز الحزمة في المتجر.' : 'تم إلغاء تمييز الحزمة من المتجر.'
        );
    }

    public function downloadTemplate()
    {
        $headers = [
            'Content-Type' => 'text/csv; charset=UTF-8',
            'Content-Disposition' => 'attachment; filename="flashcards_template.csv"',
        ];

        $callback = function () {
            $file = fopen('php://output', 'w');
            // Add BOM for UTF-8 Arabic support in Excel
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
                'اللون بصيغة Hex'
            ]);

            fputcsv($file, ['بطاقة', 'ما هي عاصمة المملكة العربية السعودية؟', 'الرياض', '', '', '', '', '', '', 'عالية', '#4F46E5']);
            fputcsv($file, ['سؤال وجواب', 'كم عدد أركان الإسلام؟', 'خمسة أركان وهي الشهادتان، إقامة الصلاة، إيتاء الزكاة، صوم رمضان، وحج البيت.', '', '', '', '', '', '', 'حرجة', '#EF4444']);
            fputcsv($file, ['اختيارات', 'أي مما يلي يعد من ألوان قوس قزح؟', 'الأحمر', 'الأسود', 'الأبيض', 'الرمادي', '', '', '1', 'normal', '#10B981']);
            fputcsv($file, ['نص واحد', 'العلم نور والجهل ظلام.', '', '', '', '', '', '', '', 'normal', '#F59E0B']);

            fclose($file);
        };

        return response()->stream($callback, 200, $headers);
    }

    public function importPreview(Request $request, FlashcardPack $flashcard)
    {
        $request->validate([
            'file' => 'required|file|mimes:xlsx,csv,xls',
        ]);

        $this->assertCanManageItems($flashcard);

        $file = $request->file('file');
        $extension = $file->getClientOriginalExtension();

        $tempDir = storage_path('app/temp_imports');
        if (!file_exists($tempDir)) {
            mkdir($tempDir, 0755, true);
        }

        $tempFileName = 'import_' . Auth::id() . '_' . time() . '.' . $extension;
        $file->move($tempDir, $tempFileName);
        $tempFilePath = 'temp_imports/' . $tempFileName;

        try {
            $rows = $this->parseSpreadsheet(storage_path('app/' . $tempFilePath), $extension);
            if (empty($rows)) {
                @unlink(storage_path('app/' . $tempFilePath));
                return back()->with('error', 'الملف لا يحتوي على بيانات صالحة.');
            }

            $firstRow = $rows[0];
            $columns = [];
            foreach ($firstRow as $index => $value) {
                $columns[$index] = trim((string) ($value ?? '')) ?: ('العمود ' . ($index + 1));
            }

            $isFirstRowHeader = $this->looksLikeHeader($firstRow);
            $previewRows = array_slice($rows, $isFirstRowHeader ? 1 : 0, 5);

            $guessedMapping = $this->guessMapping($columns, $flashcard);

            return view('admin.flashcards.import_preview', compact(
                'flashcard',
                'tempFilePath',
                'columns',
                'previewRows',
                'guessedMapping',
                'isFirstRowHeader'
            ));
        } catch (\Exception $e) {
            @unlink(storage_path('app/' . $tempFilePath));
            return back()->with('error', 'حدث خطأ أثناء قراءة الملف للمعاينة: ' . $e->getMessage());
        }
    }

    public function import(Request $request, FlashcardPack $flashcard)
    {
        return $this->importPreview($request, $flashcard);
    }

    private function guessMapping(array $columns, FlashcardPack $pack): array
    {
        $mapping = [
            'item_type_col' => 0, // Default to Column 1 (index 0)
            'front_content_col' => 1, // Default to Column 2 (index 1)
            'back_content_col' => 2, // Default to Column 3 (index 2)
            'options_cols' => [2, 3, 4], // Default to Columns 3, 4, 5 (indices 2, 3, 4)
            'correct_option_col' => -1,
            'priority_col' => 9, // Default to Column 10 (index 9)
            'color_col' => 10, // Default to Column 11 (index 10)
        ];

        $hasMatchedOptions = false;
        foreach ($columns as $index => $name) {
            $nameLower = strtolower(trim($name));

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
            } elseif (preg_match('/(option|choice|خيار|إختيار|اختيار)\s*\d+/i', $nameLower) || in_array($nameLower, ['a', 'b', 'c', 'd', 'e', 'f'])) {
                if (!$hasMatchedOptions) {
                    $mapping['options_cols'] = [];
                    $hasMatchedOptions = true;
                }
                $mapping['options_cols'][] = $index;
            }
        }

        // Check bounds, fallback to -1 (default settings) if index is out of range
        if ($mapping['priority_col'] >= count($columns)) {
            $mapping['priority_col'] = -1;
        }
        if ($mapping['color_col'] >= count($columns)) {
            $mapping['color_col'] = -1;
        }

        return $mapping;
    }

    public function importConfirm(Request $request, FlashcardPack $flashcard)
    {
        $request->validate([
            'temp_file' => 'required|string',
            'duplicate_strategy' => 'required|in:allow,ignore,update',
            'front_content_col' => 'required|integer|min:0',
            'item_type_col' => 'required|integer',
            'back_content_col' => 'required|integer',
            'options_cols' => 'nullable|array',
            'options_cols.*' => 'integer',
            'correct_option_col' => 'required|integer',
            'priority_col' => 'required|integer',
            'color_col' => 'required|integer',
        ]);

        $this->assertCanManageItems($flashcard);

        $tempFile = (string) $request->temp_file;
        if (!str_starts_with($tempFile, 'temp_imports/')) {
            return redirect()->route('admin.flashcards.show', $flashcard)
                ->with('error', 'مسار ملف الاستيراد المؤقت غير صالح، يرجى الرفع من جديد.');
        }

        $tempFilePath = storage_path('app/' . $tempFile);
        if (!file_exists($tempFilePath)) {
            return redirect()->route('admin.flashcards.show', $flashcard)->with('error', 'انتهت صلاحية الملف المؤقت أو الملف غير موجود، يرجى الرفع من جديد.');
        }

        $extension = pathinfo($tempFilePath, PATHINFO_EXTENSION);
        $duplicateStrategy = $request->duplicate_strategy;

        try {
            $rows = $this->parseSpreadsheet($tempFilePath, $extension);
            if (empty($rows)) {
                @unlink($tempFilePath);
                return redirect()->route('admin.flashcards.show', $flashcard)->with('error', 'الملف لا يحتوي على بيانات صالحة.');
            }

            $isFirstRowHeader = $request->boolean('has_headers');
            $startRowIndex = $isFirstRowHeader ? 1 : 0;

            $insertedCount = 0;
            $updatedCount = 0;
            $ignoredCount = 0;
            $failedRows = [];

            $toInsert = [];
            $itemsCountBefore = $flashcard->items()->count();

            $existingItems = $flashcard->items()
                ->select(['id', 'front_content'])
                ->get()
                ->keyBy(fn ($item) => strtolower(trim($item->front_content)));

            foreach ($rows as $index => $row) {
                if ($index < $startRowIndex) {
                    continue;
                }

                $rowNum = $index + 1;
                $row = array_map(fn ($val) => is_string($val) ? trim($val) : $val, $row);

                if (empty(array_filter($row, fn ($val) => $val !== null && $val !== ''))) {
                    continue;
                }

                $frontCol = $request->front_content_col;
                $front = isset($row[$frontCol]) ? (string) $row[$frontCol] : '';
                if ($front === '') {
                    $failedRows[] = [
                        'row' => $rowNum,
                        'reason' => 'حقل المحتوى الأمامي (السؤال) فارغ.'
                    ];
                    continue;
                }

                $typeCol = $request->item_type_col;
                $firstCellType = ($typeCol >= 0 && isset($row[$typeCol])) ? $this->normalizeItemType((string) $row[$typeCol]) : null;
                $itemType = $firstCellType ?? ($flashcard->display_mode ?: 'one_line');

                $priorityCol = $request->priority_col;
                $priority = 'normal';
                if ($priorityCol >= 0 && isset($row[$priorityCol])) {
                    $priority = $this->normalizePriority((string) $row[$priorityCol]);
                }

                $colorCol = $request->color_col;
                $color = null;
                if ($colorCol >= 0 && isset($row[$colorCol])) {
                    $color = $this->validHexColor((string) $row[$colorCol]) ?: null;
                }

                $back = '';
                $options = null;
                $correctOption = null;

                if ($itemType === 'mcq') {
                    $options = [];
                    $optionsCols = $request->options_cols ?: [];
                    foreach ($optionsCols as $colIndex) {
                        if (isset($row[$colIndex]) && (string) $row[$colIndex] !== '') {
                            $options[] = (string) $row[$colIndex];
                        }
                    }

                    if (count($options) < 2) {
                        $failedRows[] = [
                            'row' => $rowNum,
                            'reason' => 'تم تحديد نوع خيار من متعدد ولكن عدد الاختيارات الصالحة أقل من خيارين.'
                        ];
                        continue;
                    }

                    $correctCol = $request->correct_option_col;
                    $correctVal = ($correctCol >= 0 && isset($row[$correctCol])) ? $row[$correctCol] : null;
                    $correct = is_numeric($correctVal) ? (int) $correctVal : 1;
                    $correctOption = max(0, min(count($options) - 1, $correct > 0 ? $correct - 1 : $correct));
                    $back = null;
                } else {
                    $backCol = $request->back_content_col;
                    $backVal = ($backCol >= 0 && isset($row[$backCol])) ? (string) $row[$backCol] : '';
                    if ($itemType !== 'one_line' && $backVal === '') {
                        $failedRows[] = [
                            'row' => $rowNum,
                            'reason' => 'تم تحديد نوع يتطلب إجابة خلفية ولكن حقل الإجابة فارغ.'
                        ];
                        continue;
                    }
                    $back = $itemType === 'one_line' ? null : $backVal;
                }

                $frontKey = strtolower(trim($front));
                $duplicateExists = $existingItems->has($frontKey);

                if ($duplicateExists && $duplicateStrategy === 'ignore') {
                    $ignoredCount++;
                    continue;
                }

                if ($duplicateExists && $duplicateStrategy === 'update') {
                    $existingItem = $existingItems->get($frontKey);
                    $updateData = [
                        'item_type' => $itemType,
                        'back_content' => $back,
                        'options' => $options,
                        'correct_option' => $correctOption,
                        'item_color' => $color,
                        'priority' => $priority,
                    ];

                    FlashcardItem::where('id', $existingItem->id)->update($updateData);
                    $updatedCount++;
                    continue;
                }

                $toInsert[] = [
                    'pack_id' => $flashcard->id,
                    'item_type' => $itemType,
                    'front_content' => $front,
                    'back_content' => $back,
                    'options' => $options ? json_encode($options, JSON_UNESCAPED_UNICODE) : null,
                    'correct_option' => $correctOption,
                    'item_color' => $color,
                    'priority' => $priority,
                    'sort_order' => $itemsCountBefore + $insertedCount + count($toInsert),
                    'created_at' => now(),
                    'updated_at' => now(),
                ];
            }

            if (!empty($toInsert)) {
                FlashcardItem::insert($toInsert);
                $insertedCount = count($toInsert);
            }

            @unlink($tempFilePath);

            $report = [
                'success_count' => $insertedCount,
                'updated_count' => $updatedCount,
                'ignored_count' => $ignoredCount,
                'failed_count' => count($failedRows),
                'errors' => $failedRows,
            ];

            session()->flash('import_report', $report);

            $message = 'تمت معالجة ملف الاستيراد بنجاح.';
            if ($insertedCount > 0) {
                $message .= ' تم استيراد ' . $insertedCount . ' بطاقة جديدة.';
            }
            if ($updatedCount > 0) {
                $message .= ' تم تحديث ' . $updatedCount . ' بطاقة.';
            }
            if ($ignoredCount > 0) {
                $message .= ' تم تجاهل ' . $ignoredCount . ' بطاقة لتفادي التكرار.';
            }

            return redirect()->route('admin.flashcards.show', $flashcard)->with('success', $message);

        } catch (\Exception $e) {
            @unlink($tempFilePath);
            return redirect()->route('admin.flashcards.show', $flashcard)->with('error', 'حدث خطأ غير متوقع أثناء معالجة ملف الاستيراد: ' . $e->getMessage());
        }
    }

    public function storeItem(Request $request, FlashcardPack $flashcard)
    {
        $this->assertCanManageItems($flashcard);
        $itemType = $request->input('item_type', $flashcard->display_mode);
        $validated = $this->validateItemPayload($request, $itemType);

        $flashcard->items()->create($this->mapItemData($validated, $flashcard, $itemType));

        return back()->with('success', 'تمت إضافة العنصر بنجاح.');
    }

    public function updateItem(Request $request, FlashcardItem $item)
    {
        $this->assertCanManageItems($item->pack);
        $itemType = $request->input('item_type', $item->resolved_item_type);
        $validated = $this->validateItemPayload($request, $itemType);

        $item->update($this->mapItemData($validated, $item->pack, $itemType, false));

        return back()->with('success', 'تم تحديث العنصر بنجاح.');
    }

    public function preview(FlashcardPack $flashcard)
    {
        $items = $flashcard->effectiveItems()
            ->with('pack:id,title,color,display_mode')
            ->orderByRaw("FIELD(priority, 'critical', 'high', 'normal')")
            ->orderBy('sort_order')
            ->get();

        return view('admin.flashcards.preview', compact('flashcard', 'items'));
    }

    public function destroyItem(FlashcardItem $item)
    {
        $this->assertCanManageItems($item->pack);
        $item->delete();

        return back()->with('success', 'تم حذف العنصر.');
    }

    public function assignmentsManagement(Request $request)
    {
        $query = FlashcardPack::with(['user', 'sourcePack' => function ($q) {
            $q->select('id', 'title', 'display_mode');
        }])
            ->whereNotNull('source_pack_id')
            ->whereNull('parent_pack_id');

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->whereHas('user', function ($userQuery) use ($search) {
                    $userQuery->where('name', 'like', "%{$search}%")
                        ->orWhere('student_number', 'like', "%{$search}%");
                })->orWhereHas('sourcePack', function ($sourceQuery) use ($search) {
                    $sourceQuery->where('title', 'like', "%{$search}%");
                });
            });
        }

        $assignments = $query->latest()->paginate(15)->withQueryString();

        return view('admin.flashcards.assignments', compact('assignments'));
    }

    public function cancelAssignment(FlashcardPack $pack)
    {
        if ($pack->source_pack_id !== null && $pack->parent_pack_id === null) {
            $this->deletePackTree($pack);

            return back()->with('success', 'تم إلغاء التعيين وحذف شجرة الحزمة من حساب الطالب.');
        }

        return back()->with('error', 'هذه ليست حزمة تعيين مباشرة قابلة للإلغاء من هنا.');
    }

    private function availableAdminParentPacks(?FlashcardPack $currentPack = null): Collection
    {
        $packs = FlashcardPack::where('user_id', Auth::id())
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

    private function resolveAdminParentPack(?int $parentPackId, ?FlashcardPack $currentPack = null): ?FlashcardPack
    {
        if (!$parentPackId) {
            return null;
        }

        $parentPack = FlashcardPack::where('id', $parentPackId)
            ->where('user_id', Auth::id())
            ->whereNull('source_pack_id')
            ->firstOrFail();

        if ($currentPack && in_array($parentPack->id, $currentPack->descendantPackIds(), true)) {
            abort(422, 'لا يمكن نقل الحزمة داخل أحد تفرعاتها.');
        }

        return $parentPack;
    }

    private function displayItemsForPack(FlashcardPack $pack): Collection
    {
        if ($pack->is_assigned && $pack->sourcePack) {
            return $pack->sourcePack->items()->with('pack:id,title,color,display_mode')->orderBy('sort_order')->orderBy('id')->get();
        }

        return $pack->items()->with('pack:id,title,color,display_mode')->orderBy('sort_order')->orderBy('id')->get();
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

    private function cloneEditableTree(FlashcardPack $sourcePack, int $userId, ?int $parentCloneId = null, bool $isRoot = false): FlashcardPack
    {
        $clone = $sourcePack->replicate(['user_id', 'is_public', 'parent_pack_id']);
        $clone->user_id = $userId;
        $clone->title = $isRoot ? 'نسخة المتجر: ' . $sourcePack->title : $sourcePack->title;
        $clone->is_public = false;
        $clone->source_pack_id = null;
        $clone->parent_pack_id = $parentCloneId;
        $clone->save();

        $sourcePack->loadMissing(['items', 'childPacks']);

        foreach ($sourcePack->items as $item) {
            $newItem = $item->replicate(['pack_id']);
            $newItem->pack_id = $clone->id;
            $newItem->save();
        }

        foreach ($sourcePack->childPacks as $childPack) {
            $this->cloneEditableTree($childPack, $userId, $clone->id);
        }

        return $clone;
    }

    private function notifyFlashcardAssigned(FlashcardPack $pack, User $targetUser): void
    {
        StudentNotification::create([
            'user_id' => $targetUser->id,
            'college_id' => $targetUser->college_id,
            'sender_id' => Auth::id(),
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

    private function assertCanManageItems(FlashcardPack $pack): void
    {
        if ($pack->is_assigned) {
            abort(422, 'الحزم المعيّنة لا تقبل تعديل العناصر مباشرة.');
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
                throw new \RuntimeException('يرجى تثبيت الحزمة phpoffice/phpspreadsheet لدعم ملفات Excel.');
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
}
