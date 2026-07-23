@extends('layouts.admin')

@section('title', $flashcard->title . ' - تفاصيل الحزمة')

@section('content')
<div class="container-fluid py-4">
    <div class="d-flex justify-content-between align-items-center mb-4 flex-wrap gap-3">
        <div>
            <h1 class="h3 fw-black text-dark mb-1">{{ $flashcard->title }}</h1>
            <p class="text-secondary mb-0">
                {{ $items->count() }} عنصر مباشر
                <span class="mx-2">•</span>
                {{ $flashcard->items_count }} عنصر داخل الشجرة
                <span class="mx-2">•</span>
                {{ $childPacks->count() }} حزمة فرعية
            </p>
        </div>
        <div class="d-flex gap-2 flex-wrap">
            <a href="{{ route('admin.flashcards.preview', $flashcard) }}" class="btn btn-outline-primary rounded-3 fw-bold">معاينة</a>
            <a href="{{ route('admin.flashcards.edit', $flashcard) }}" class="btn btn-light border rounded-3 fw-bold">تعديل</a>
            <a href="{{ route('admin.flashcards.create', ['parent_pack_id' => $flashcard->id]) }}" class="btn btn-outline-secondary rounded-3 fw-bold">حزمة فرعية</a>
            <a href="{{ route('admin.flashcards.index') }}" class="btn btn-light border rounded-3 fw-bold">العودة</a>
        </div>
    </div>

    @if(session('success'))
        <div class="alert alert-success border-0 shadow-sm rounded-4 mb-4">{{ session('success') }}</div>
    @endif
    @if(session('error'))
        <div class="alert alert-danger border-0 shadow-sm rounded-4 mb-4">{{ session('error') }}</div>
    @endif

    @if(session('import_report'))
        @php $report = session('import_report'); @endphp
        <div class="card border-0 shadow-sm rounded-4 mb-4 bg-light border-start border-4 border-success">
            <div class="card-body p-4">
                <h4 class="fw-black text-dark mb-3">تقرير استيراد البطاقات الأخير</h4>
                <div class="row g-3 text-center mb-3">
                    <div class="col-6 col-md-3">
                        <div class="border rounded-3 p-2 bg-white">
                            <div class="small text-secondary fw-semibold">مدرجة جديدة</div>
                            <div class="fs-4 fw-black text-success">{{ $report['success_count'] }}</div>
                        </div>
                    </div>
                    <div class="col-6 col-md-3">
                        <div class="border rounded-3 p-2 bg-white">
                            <div class="small text-secondary fw-semibold">محدثة</div>
                            <div class="fs-4 fw-black text-primary">{{ $report['updated_count'] }}</div>
                        </div>
                    </div>
                    <div class="col-6 col-md-3">
                        <div class="border rounded-3 p-2 bg-white">
                            <div class="small text-secondary fw-semibold">متجاهلة للتكرار</div>
                            <div class="fs-4 fw-black text-warning">{{ $report['ignored_count'] }}</div>
                        </div>
                    </div>
                    <div class="col-6 col-md-3">
                        <div class="border rounded-3 p-2 bg-white">
                            <div class="small text-secondary fw-semibold">صفوف فاشلة</div>
                            <div class="fs-4 fw-black text-danger">{{ $report['failed_count'] }}</div>
                        </div>
                    </div>
                </div>

                @if(!empty($report['errors']))
                    <div class="alert alert-danger border-0 rounded-3 mb-0">
                        <h5 class="fw-bold mb-2">تفاصيل أخطاء الاستيراد:</h5>
                        <div class="overflow-auto" style="max-height: 200px;">
                            <ul class="mb-0 ps-3">
                                @foreach($report['errors'] as $err)
                                    <li class="small mb-1">
                                        <strong>السطر {{ $err['row'] }}:</strong> {{ $err['reason'] }}
                                    </li>
                                @endforeach
                            </ul>
                        </div>
                    </div>
                @endif
            </div>
        </div>
    @endif

    @if($childPacks->isNotEmpty())
        <div class="card border-0 shadow-sm rounded-4 mb-4">
            <div class="card-body p-4">
                <div class="d-flex justify-content-between align-items-center mb-3">
                    <h4 class="fw-black mb-0">الحزم الفرعية</h4>
                    <a href="{{ route('admin.flashcards.create', ['parent_pack_id' => $flashcard->id]) }}" class="btn btn-sm btn-outline-primary rounded-3 fw-bold">إضافة حزمة فرعية</a>
                </div>
                <div class="row g-3">
                    @foreach($childPacks as $childPack)
                        <div class="col-md-6 col-xl-4">
                            <a href="{{ route('admin.flashcards.show', $childPack) }}" class="text-decoration-none">
                                <div class="border rounded-4 p-3 bg-white shadow-sm h-100">
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

    <div class="row g-4 mb-4">
        <div class="col-lg-7">
            <div class="card border-0 shadow-sm rounded-4 h-100">
                <div class="card-body p-4">
                    <h4 class="fw-black mb-3">إضافة عنصر جديد</h4>
                    <form action="{{ route('admin.flashcards.items.store', $flashcard) }}" method="POST" data-flashcard-item-form>
                        @csrf
                        <div class="row g-3">
                            <div class="col-md-6">
                                <label class="form-label fw-bold">نوع العنصر</label>
                                <select class="form-select" name="item_type" required data-item-type>
                                    <option value="one_line">نص واحد</option>
                                    <option value="flash_card">بطاقة تعليمية</option>
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
                            <div class="col-12" data-back-field>
                                <label class="form-label fw-bold">المحتوى الخلفي / الإجابة</label>
                                <textarea class="form-control" name="back_content" rows="2"></textarea>
                            </div>
                            <div class="col-12 d-none" data-options-field>
                                <label class="form-label fw-bold">خيارات الاختيارات المتعددة</label>
                                <div class="row g-2">
                                    @for($i = 0; $i < 4; $i++)
                                        <div class="col-md-6">
                                            <input type="text" class="form-control" name="options[]" placeholder="الخيار {{ $i + 1 }}">
                                        </div>
                                    @endfor
                                </div>
                            </div>
                            <div class="col-md-4 d-none" data-correct-field>
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
                    <h4 class="fw-black mb-3 d-flex justify-content-between align-items-center flex-wrap gap-2">
                        <span>استيراد سريع</span>
                        <a href="{{ route('admin.flashcards.import-template') }}" class="btn btn-sm btn-link text-decoration-none fw-bold p-0">تحميل القالب التجريبي</a>
                    </h4>
                    <form action="{{ route('admin.flashcards.import.preview', $flashcard) }}" method="POST" enctype="multipart/form-data">
                        @csrf
                        <div class="mb-3">
                            <label class="form-label fw-bold">ملف Excel / CSV</label>
                            <input type="file" name="file" class="form-control" accept=".xlsx,.xls,.csv" required>
                        </div>
                        <div class="small text-secondary mb-3">
                            قم برفع ملف الاستيراد للانتقال للخطوة التالية لتحديد خريطة الأعمدة، إستراتيجية معالجة التكرارات، ومعاينة البيانات قبل الحفظ.
                        </div>
                        <button type="submit" class="btn btn-success w-100 rounded-3 fw-bold">رفع ومعاينة البيانات</button>
                    </form>
                </div>
            </div>
        </div>
    </div>

    <div class="card border-0 shadow-sm rounded-4">
        <div class="card-body p-4">
            <div class="d-flex justify-content-between align-items-center mb-3">
                <h4 class="fw-black mb-0">العناصر المباشرة داخل هذه الحزمة</h4>
                <span class="text-secondary small">يمكن أن يختلف نوع كل عنصر عن الآخر</span>
            </div>

            @if($items->isEmpty())
                <div class="text-center py-5 text-secondary">لا توجد عناصر مباشرة داخل هذه الحزمة.</div>
            @else
                <div class="row g-3">
                    @foreach($items as $item)
                        <div class="col-12">
                            <div class="border rounded-4 p-3 bg-white">
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
                                    <form action="{{ route('admin.flashcards.items.destroy', $item) }}" method="POST" onsubmit="return confirm('حذف هذا العنصر؟');">
                                        @csrf
                                        @method('DELETE')
                                        <button type="submit" class="btn btn-sm btn-outline-danger rounded-3">حذف</button>
                                    </form>
                                </div>
                            </div>
                        </div>
                    @endforeach
                </div>
            @endif
        </div>
    </div>
</div>
<script>
    document.querySelectorAll('[data-flashcard-item-form]').forEach((form) => {
        const typeInput = form.querySelector('[data-item-type]');
        const backField = form.querySelector('[data-back-field]');
        const optionsField = form.querySelector('[data-options-field]');
        const correctField = form.querySelector('[data-correct-field]');

        const syncFields = () => {
            const type = typeInput.value;
            backField.classList.toggle('d-none', type === 'one_line' || type === 'mcq');
            optionsField.classList.toggle('d-none', type !== 'mcq');
            correctField.classList.toggle('d-none', type !== 'mcq');
        };

        typeInput.addEventListener('change', syncFields);
        syncFields();
    });
</script>
@endsection
