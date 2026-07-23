<div class="row g-4">
    <div class="col-lg-8">
        <div class="premium-card p-4 p-md-5">
            <h5 class="fw-black mb-4 d-flex align-items-center gap-2">
                <i class="fa-solid fa-circle-info text-primary"></i>
                معلومات الحزمة
            </h5>

            <div class="mb-4">
                <label class="form-label fw-black text-secondary small mb-2">عنوان الحزمة <span class="text-danger">*</span></label>
                <input type="text" name="title" value="{{ old('title', $flashcard->title ?? '') }}" required class="form-control form-control-lg border-2 bg-light rounded-4 fw-bold shadow-none p-3">
            </div>

            <div class="mb-4">
                <label class="form-label fw-black text-secondary small mb-2">وصف مختصر</label>
                <textarea name="description" rows="3" class="form-control border-2 bg-light rounded-4 fw-bold shadow-none p-3">{{ old('description', $flashcard->description ?? '') }}</textarea>
            </div>

            <div class="row g-3 mb-4">
                <div class="col-md-6">
                    <label class="form-label fw-black text-secondary small mb-2">الحزمة الأب</label>
                    <select name="parent_pack_id" class="form-select border-2 bg-light rounded-4 fw-bold shadow-none p-3">
                        <option value="">بدون حزمة أب</option>
                        @foreach(($parentPacks ?? collect()) as $parentPack)
                            <option value="{{ $parentPack->id }}" {{ (string) old('parent_pack_id', $flashcard->parent_pack_id ?? request('parent_pack_id')) === (string) $parentPack->id ? 'selected' : '' }}>
                                {{ $parentPack->title }}
                            </option>
                        @endforeach
                    </select>
                </div>
                <div class="col-md-6">
                    <label class="form-label fw-black text-secondary small mb-2">تصنيف المتجر</label>
                    <input type="text" name="category" value="{{ old('category', $flashcard->storeEntry->category ?? '') }}" class="form-control border-2 bg-light rounded-4 fw-bold shadow-none p-3">
                </div>
            </div>

            <div class="mb-0">
                <label class="form-label fw-black text-secondary small mb-2">لون الحزمة</label>
                <div class="d-flex align-items-center gap-3 bg-light border-2 border rounded-4 p-2 px-3">
                    <input type="color" name="color" value="{{ old('color', $flashcard->color ?? '#4f46e5') }}" class="form-control form-control-color border-0 rounded-3 shadow-none p-0 bg-transparent" style="width: 50px; height: 40px;">
                    <span class="text-secondary small fw-bold">يستخدم كلون افتراضي للعناصر إذا لم يحدد لها لون خاص.</span>
                </div>
            </div>
        </div>
    </div>

    <div class="col-lg-4">
        <div class="d-flex flex-column gap-4 h-100">
            <div class="premium-card p-4">
                <h4 class="h6 fw-black text-dark mb-2">نظام العرض الحالي</h4>
                <p class="text-secondary small fw-bold mb-0">
                    الحزمة تحتوي كروتًا متعددة الأنواع. إعدادات وقت الظهور، حد المراجعة اليومي، وفترة الهدوء يديرها الطالب من التطبيق على مستوى One Line Shot بالكامل.
                </p>
            </div>

            <div class="premium-card p-4">
                <div class="form-check form-switch p-0 d-flex align-items-center justify-content-between">
                    <label class="form-check-label fw-black text-dark" for="activeSwitch">الحزمة نشطة</label>
                    <input type="hidden" name="is_active" value="0">
                    <input class="form-check-input ms-0 border-0 shadow-none bg-secondary" type="checkbox" role="switch" id="activeSwitch" name="is_active" value="1" {{ old('is_active', $flashcard->is_active ?? 1) ? 'checked' : '' }} style="width: 45px; height: 24px;">
                </div>
            </div>

            <div class="mt-auto">
                <button type="submit" class="btn btn-primary w-100 rounded-4 py-3 fw-black fs-5 shadow-lg border-0 d-flex align-items-center justify-content-center gap-2 text-white" style="background: linear-gradient(135deg, #4f46e5, #7c3aed);">
                    {{ isset($flashcard) ? 'حفظ التعديلات' : 'إنشاء الحزمة' }}
                    <i class="fa-solid fa-check-circle"></i>
                </button>
            </div>
        </div>
    </div>
</div>

<style>
    .form-switch .form-check-input:checked { background-color: #10b981 !important; }
</style>
