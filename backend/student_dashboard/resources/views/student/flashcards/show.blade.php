@extends('layouts.student')

@section('title', $flashcard->title . ' - Oneline Shot')

@section('content')
<div class="container-fluid py-4">
    <div class="d-flex justify-content-between align-items-center mb-4 flex-wrap gap-3">
        <div class="d-flex align-items-center gap-3">
            <span class="rounded-circle d-inline-flex align-items-center justify-content-center text-white fw-black" style="width:56px;height:56px;background:{{ $flashcard->color }};">
                {{ mb_substr($flashcard->title, 0, 1) }}
            </span>
            <div>
                <h1 class="h3 fw-black text-dark mb-1">{{ $flashcard->title }}</h1>
                <div class="text-secondary">
                    {{ $items->count() }} عنصر مباشر
                    <span class="mx-2">•</span>
                    {{ $flashcard->items_count }} عنصر داخل الشجرة
                    <span class="mx-2">•</span>
                    {{ $childPacks->count() }} حزمة فرعية
                </div>
            </div>
        </div>
        <div class="d-flex gap-2 flex-wrap">
            <a href="{{ route('student.flashcards.review', $flashcard) }}" class="btn btn-primary rounded-3 px-4 fw-bold">بدء المراجعة</a>
            <a href="{{ route('student.flashcards.edit', $flashcard) }}" class="btn btn-light border rounded-3 px-3 fw-bold">تعديل الحزمة</a>
            <a href="{{ route('student.flashcards.create', ['parent_pack_id' => $flashcard->id]) }}" class="btn btn-outline-primary rounded-3 px-3 fw-bold">حزمة فرعية</a>
            <a href="{{ route('student.flashcards.index') }}" class="btn btn-light border rounded-3 px-3 fw-bold">العودة</a>
        </div>
    </div>

    @if(session('success'))
        <div class="alert alert-success border-0 shadow-sm rounded-4 mb-4">{{ session('success') }}</div>
    @endif
    @if(session('error'))
        <div class="alert alert-danger border-0 shadow-sm rounded-4 mb-4">{{ session('error') }}</div>
    @endif

    @if($flashcard->is_assigned)
        <div class="alert alert-warning border-0 shadow-sm rounded-4">
            هذه الحزمة مرتبطة بمصدر خارجي، لذلك يمكن مراجعتها وتخصيص إعداداتها فقط. تعديل العناصر يتم من الحزمة الأصلية.
        </div>
    @endif

    @if($childPacks->isNotEmpty())
        <div class="card border-0 shadow-sm rounded-4 mb-4">
            <div class="card-body p-4">
                <div class="d-flex justify-content-between align-items-center mb-3">
                    <h4 class="fw-black mb-0">الحزم الفرعية</h4>
                    <a href="{{ route('student.flashcards.create', ['parent_pack_id' => $flashcard->id]) }}" class="btn btn-sm btn-outline-primary rounded-3 fw-bold">إضافة حزمة فرعية</a>
                </div>
                <div class="row g-3">
                    @foreach($childPacks as $childPack)
                        <div class="col-md-6 col-xl-4">
                            <a href="{{ route('student.flashcards.show', $childPack) }}" class="text-decoration-none">
                                <div class="border rounded-4 p-3 h-100 bg-white shadow-sm">
                                    <div class="d-flex justify-content-between align-items-start mb-2">
                                        <span class="badge text-white" style="background:{{ $childPack->color }};">{{ $childPack->display_mode_text }}</span>
                                        <span class="small text-secondary">{{ $childPack->items_count }} عنصر</span>
                                    </div>
                                    <div class="fw-black text-dark mb-1">{{ $childPack->title }}</div>
                                    <div class="small text-secondary">{{ $childPack->description ?: 'بدون وصف' }}</div>
                                </div>
                            </a>
                        </div>
                    @endforeach
                </div>
            </div>
        </div>
    @endif

    @unless($flashcard->is_assigned)
        <div class="row g-4 mb-4">
            <div class="col-lg-7">
                <div class="card border-0 shadow-sm rounded-4 h-100">
                    <div class="card-body p-4">
                        <h4 class="fw-black mb-3">إضافة عنصر جديد</h4>
                        <form action="{{ route('student.flashcards.items.store', $flashcard) }}" method="POST">
                            @csrf
                            <div class="row g-3">
                                <div class="col-md-6">
                                    <label class="form-label fw-bold">نوع العنصر</label>
                                    <select class="form-select" name="item_type" required>
                                        <option value="{{ $flashcard->display_mode }}">النوع الافتراضي للحزمة ({{ \App\Models\FlashcardPack::itemTypeLabel($flashcard->display_mode) }})</option>
                                        <option value="flash_card">بطاقة تعليمية</option>
                                        <option value="one_line">نص واحد</option>
                                        <option value="qa">سؤال وجواب</option>
                                        <option value="mcq">اختيارات</option>
                                    </select>
                                </div>
                                <div class="col-md-3">
                                    <label class="form-label fw-bold">لون العنصر</label>
                                    <input type="color" class="form-control form-control-color" name="item_color" value="{{ $flashcard->color }}">
                                </div>
                                <div class="col-md-3">
                                    <label class="form-label fw-bold">الأولوية</label>
                                    <select class="form-select" name="priority" required>
                                        <option value="normal">عادية</option>
                                        <option value="high">عالية</option>
                                        <option value="critical">حرجة</option>
                                    </select>
                                </div>
                                <div class="col-12">
                                    <label class="form-label fw-bold">المحتوى الأمامي / السؤال / النص</label>
                                    <textarea class="form-control" name="front_content" rows="2" required></textarea>
                                </div>
                                <div class="col-12">
                                    <label class="form-label fw-bold">المحتوى الخلفي / الإجابة</label>
                                    <textarea class="form-control" name="back_content" rows="2"></textarea>
                                    <div class="form-text">يُترك فارغًا إذا كان النوع نصًا واحدًا أو اختيارًا متعددًا.</div>
                                </div>
                                <div class="col-12">
                                    <label class="form-label fw-bold">خيارات الاختيارات المتعددة</label>
                                    <div class="row g-2">
                                        @for($i = 0; $i < 4; $i++)
                                            <div class="col-md-6">
                                                <input type="text" class="form-control" name="options[]" placeholder="الخيار {{ $i + 1 }}">
                                            </div>
                                        @endfor
                                    </div>
                                </div>
                                <div class="col-md-4">
                                    <label class="form-label fw-bold">رقم الإجابة الصحيحة</label>
                                    <input type="number" min="0" max="5" class="form-control" name="correct_option" value="0">
                                </div>
                                <div class="col-md-8 d-flex align-items-end">
                                    <button type="submit" class="btn btn-primary w-100 rounded-3 fw-bold py-2">حفظ العنصر</button>
                                </div>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
            <div class="col-lg-5">
                <div class="card border-0 shadow-sm rounded-4 h-100">
                    <div class="card-body p-4">
                        <h4 class="fw-black mb-3">استيراد سريع</h4>
                        <form action="{{ route('student.flashcards.import', $flashcard) }}" method="POST" enctype="multipart/form-data">
                            @csrf
                            <div class="mb-3">
                                <label class="form-label fw-bold">ملف Excel / CSV</label>
                                <input type="file" name="file" class="form-control" accept=".xlsx,.xls,.csv" required>
                            </div>
                            <div class="small text-secondary mb-3">
                                الاستيراد يستخدم النوع الافتراضي للحزمة الحالية: <strong>{{ $flashcard->display_mode_text }}</strong>.
                            </div>
                            <button type="submit" class="btn btn-success w-100 rounded-3 fw-bold">بدء الاستيراد</button>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    @endunless

    <div class="card border-0 shadow-sm rounded-4">
        <div class="card-body p-4">
            <div class="d-flex justify-content-between align-items-center mb-3">
                <h4 class="fw-black mb-0">العناصر المباشرة داخل هذه الحزمة</h4>
                <span class="text-secondary small">مرتبة حسب ترتيب الإدخال</span>
            </div>

            @if($items->isEmpty())
                <div class="text-center py-5 text-secondary">
                    لا توجد عناصر مباشرة في هذه الحزمة حتى الآن.
                </div>
            @else
                <div class="row g-3">
                    @foreach($items as $item)
                        <div class="col-12">
                            <div class="border rounded-4 p-3 h-100 bg-white">
                                <div class="d-flex justify-content-between align-items-start gap-3">
                                    <div class="flex-grow-1">
                                        <div class="d-flex flex-wrap gap-2 mb-2">
                                            <span class="badge text-white" style="background:{{ $item->resolved_color }};">{{ $item->item_type_label }}</span>
                                            <span class="badge bg-light text-dark">{{ $item->priority_text }}</span>
                                            <span class="badge bg-light text-secondary">{{ $item->pack->title }}</span>
                                        </div>
                                        <div class="fw-black text-dark mb-2">{{ $item->front_content }}</div>
                                        @if($item->back_content)
                                            <div class="text-secondary mb-2">{{ $item->back_content }}</div>
                                        @endif
                                        @if($item->resolved_item_type === 'mcq' && is_array($item->options))
                                            <div class="small text-secondary">
                                                الخيارات:
                                                {{ implode(' | ', $item->options) }}
                                                <span class="text-success fw-bold ms-2">الصحيح: {{ ($item->correct_option ?? 0) + 1 }}</span>
                                            </div>
                                        @endif
                                    </div>
                                    @unless($flashcard->is_assigned)
                                        <form action="{{ route('student.flashcards.items.destroy', $item) }}" method="POST" onsubmit="return confirm('حذف هذا العنصر؟');">
                                            @csrf
                                            @method('DELETE')
                                            <button type="submit" class="btn btn-sm btn-outline-danger rounded-3">حذف</button>
                                        </form>
                                    @endunless
                                </div>
                            </div>
                        </div>
                    @endforeach
                </div>
            @endif
        </div>
    </div>
</div>
@endsection
