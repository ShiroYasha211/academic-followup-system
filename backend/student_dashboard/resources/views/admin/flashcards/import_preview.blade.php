@extends('layouts.admin')

@section('title', 'معاينة استيراد البطاقات - ' . $flashcard->title)

@section('content')
<div class="container-fluid py-4">
    <div class="d-flex justify-content-between align-items-center mb-4 flex-wrap gap-3">
        <div>
            <h1 class="h3 fw-black text-dark mb-1">معاينة استيراد البطاقات</h1>
            <p class="text-secondary mb-0">
                الحزمة: {{ $flashcard->title }} (نوع العرض الافتراضي: {{ $flashcard->display_mode_text }})
            </p>
        </div>
        <div>
            <a href="{{ route('admin.flashcards.show', $flashcard) }}" class="btn btn-light border rounded-3 fw-bold">إلغاء والتراجع</a>
        </div>
    </div>

    <form action="{{ route('admin.flashcards.import.confirm', $flashcard) }}" method="POST">
        @csrf
        <input type="hidden" name="temp_file" value="{{ $tempFilePath }}">

        <div class="row g-4">
            <!-- Settings Card -->
            <div class="col-lg-5">
                <div class="card border-0 shadow-sm rounded-4 mb-4">
                    <div class="card-body p-4">
                        <h4 class="fw-black mb-4">1. خيارات الاستيراد والتكرار</h4>

                        <!-- Duplicate Strategy -->
                        <div class="mb-4">
                            <label class="form-label fw-bold d-block mb-2">إستراتيجية معالجة التكرار (حسب نص السؤال)</label>
                            <div class="form-check mb-2">
                                <input class="form-check-input" type="radio" name="duplicate_strategy" id="dup_allow" value="allow" checked>
                                <label class="form-check-label fw-semibold" for="dup_allow">
                                    السماح بالتكرار (إدراج كل الصفوف كبطاقات جديدة)
                                </label>
                            </div>
                            <div class="form-check mb-2">
                                <input class="form-check-input" type="radio" name="duplicate_strategy" id="dup_ignore" value="ignore">
                                <label class="form-check-label fw-semibold" for="dup_ignore">
                                    تجاهل المكرر (عدم استيراد البطاقة إذا كانت موجودة مسبقاً)
                                </label>
                            </div>
                            <div class="form-check mb-2">
                                <input class="form-check-input" type="radio" name="duplicate_strategy" id="dup_update" value="update">
                                <label class="form-check-label fw-semibold" for="dup_update">
                                    تحديث المكرر (تحديث الإجابة والأولوية واللون للبطاقة الحالية)
                                </label>
                            </div>
                        </div>

                        <!-- Has Headers -->
                        <div class="form-check form-switch mb-4">
                            <input class="form-check-input" type="checkbox" name="has_headers" id="has_headers" value="1" {{ $isFirstRowHeader ? 'checked' : '' }}>
                            <label class="form-check-label fw-bold" for="has_headers">
                                يحتوي الملف على سطر عناوين (تخطي الصف الأول)
                            </label>
                            <div class="form-text">
                                تم ضبط هذا الخيار تلقائيًا حسب أول صف. إذا كان أول صف بطاقة فعلية، ألغِ التحديد حتى لا يتم تجاهله.
                            </div>
                        </div>

                        <h4 class="fw-black mb-4 pt-3 border-top">2. ربط أعمدة الملف بالحقول</h4>

                        <!-- Front Content (Required) -->
                        <div class="mb-3">
                            <label class="form-label fw-bold text-danger">السؤال / المحتوى الأمامي (إجباري)</label>
                            <select class="form-select" name="front_content_col" required>
                                @foreach($columns as $index => $name)
                                    <option value="{{ $index }}" {{ $guessedMapping['front_content_col'] == $index ? 'selected' : '' }}>
                                        العمود {{ $index + 1 }}: {{ $name }}
                                    </option>
                                @endforeach
                            </select>
                        </div>

                        <!-- Item Type -->
                        <div class="mb-3">
                            <label class="form-label fw-bold">نوع البطاقة</label>
                            <select class="form-select" name="item_type_col">
                                <option value="-1" {{ $guessedMapping['item_type_col'] == -1 ? 'selected' : '' }}>
                                    استخدام نوع الحزمة الافتراضي ({{ $flashcard->display_mode_text }})
                                </option>
                                @foreach($columns as $index => $name)
                                    <option value="{{ $index }}" {{ $guessedMapping['item_type_col'] == $index ? 'selected' : '' }}>
                                        العمود {{ $index + 1 }}: {{ $name }}
                                    </option>
                                @endforeach
                            </select>
                        </div>

                        <!-- Back Content -->
                        <div class="mb-3">
                            <label class="form-label fw-bold">الإجابة / المحتوى الخلفي</label>
                            <select class="form-select" name="back_content_col">
                                <option value="-1" {{ $guessedMapping['back_content_col'] == -1 ? 'selected' : '' }}>
                                    بدون (استيراد كنص واحد "One Line")
                                </option>
                                @foreach($columns as $index => $name)
                                    <option value="{{ $index }}" {{ $guessedMapping['back_content_col'] == $index ? 'selected' : '' }}>
                                        العمود {{ $index + 1 }}: {{ $name }}
                                    </option>
                                @endforeach
                            </select>
                        </div>

                        <!-- MCQ Options (Checkboxes) -->
                        <div class="mb-3">
                            <label class="form-label fw-bold d-block">أعمدة خيارات الاختيار من متعدد (لنوع MCQ)</label>
                            <div class="row g-2 border rounded p-3 bg-light">
                                @foreach($columns as $index => $name)
                                    <div class="col-md-6">
                                        <div class="form-check">
                                            <input class="form-check-input" type="checkbox" name="options_cols[]" value="{{ $index }}" id="opt_{{ $index }}"
                                                {{ in_array($index, $guessedMapping['options_cols']) ? 'checked' : '' }}>
                                            <label class="form-check-label small fw-semibold" for="opt_{{ $index }}">
                                                العمود {{ $index + 1 }}: {{ $name }}
                                            </label>
                                        </div>
                                    </div>
                                @endforeach
                            </div>
                        </div>

                        <!-- MCQ Correct Answer -->
                        <div class="mb-3">
                            <label class="form-label fw-bold">رقم الخيار الصحيح (لنوع MCQ)</label>
                            <select class="form-select" name="correct_option_col">
                                <option value="-1" {{ $guessedMapping['correct_option_col'] == -1 ? 'selected' : '' }}>
                                    افتراضي (الخيار الأول)
                                </option>
                                @foreach($columns as $index => $name)
                                    <option value="{{ $index }}" {{ $guessedMapping['correct_option_col'] == $index ? 'selected' : '' }}>
                                        العمود {{ $index + 1 }}: {{ $name }}
                                    </option>
                                @endforeach
                            </select>
                        </div>

                        <!-- Priority -->
                        <div class="mb-3">
                            <label class="form-label fw-bold">الأولوية</label>
                            <select class="form-select" name="priority_col">
                                <option value="-1" {{ $guessedMapping['priority_col'] == -1 ? 'selected' : '' }}>
                                    افتراضي (عادية)
                                </option>
                                @foreach($columns as $index => $name)
                                    <option value="{{ $index }}" {{ $guessedMapping['priority_col'] == $index ? 'selected' : '' }}>
                                        العمود {{ $index + 1 }}: {{ $name }}
                                    </option>
                                @endforeach
                            </select>
                        </div>

                        <!-- Color -->
                        <div class="mb-4">
                            <label class="form-label fw-bold">اللون</label>
                            <select class="form-select" name="color_col">
                                <option value="-1" {{ $guessedMapping['color_col'] == -1 ? 'selected' : '' }}>
                                    افتراضي (لون الحزمة)
                                </option>
                                @foreach($columns as $index => $name)
                                    <option value="{{ $index }}" {{ $guessedMapping['color_col'] == $index ? 'selected' : '' }}>
                                        العمود {{ $index + 1 }}: {{ $name }}
                                    </option>
                                @endforeach
                            </select>
                        </div>

                        <button type="submit" class="btn btn-primary w-100 rounded-3 fw-bold py-2 shadow-sm">تأكيد وبدء الاستيراد الفعلي</button>
                    </div>
                </div>
            </div>

            <!-- Preview Card -->
            <div class="col-lg-7">
                <div class="card border-0 shadow-sm rounded-4 h-100">
                    <div class="card-body p-4">
                        <h4 class="fw-black mb-3">3. معاينة أسطر الملف المرفوع</h4>
                        <p class="text-secondary small">نعرض هنا أول 5 أسطر من ملفك لتسهيل عملية مطابقة وفهم خريطة الأعمدة.</p>

                        <div class="table-responsive border rounded-4 bg-white mt-3 shadow-sm">
                            <table class="table table-bordered mb-0 align-middle">
                                <thead class="table-light">
                                    <tr>
                                        <th class="text-center" style="width: 70px;">السطر</th>
                                        @foreach($columns as $index => $name)
                                            <th>
                                                <div class="small fw-semibold text-secondary">العمود {{ $index + 1 }}</div>
                                                <div class="fw-bold text-dark">{{ $name }}</div>
                                            </th>
                                        @endforeach
                                    </tr>
                                </thead>
                                <tbody>
                                    @foreach($previewRows as $rowIndex => $row)
                                        <tr>
                                            <td class="text-center fw-bold bg-light">{{ $rowIndex + ($isFirstRowHeader ? 2 : 1) }}</td>
                                            @foreach($columns as $index => $name)
                                                <td class="small text-secondary text-truncate" style="max-width: 250px;">
                                                    {{ $row[$index] ?? '' }}
                                                </td>
                                            @endforeach
                                        </tr>
                                    @endforeach
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </form>
</div>
@endsection
