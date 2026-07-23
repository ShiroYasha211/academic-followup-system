@extends('layouts.delegate')

@section('title', 'تعديل المصدر')

@section('content')

<!-- Page Header -->
<div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 2rem;">
    <div>
        <h1 style="font-size: 1.8rem; font-weight: 800; color: var(--text-primary); margin-bottom: 0.5rem; display: flex; align-items: center; gap: 0.75rem;">
            <div style="width: 48px; height: 48px; background: white; border-radius: 12px; display: flex; align-items: center; justify-content: center; box-shadow: var(--shadow-sm); color: #f59e0b;">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                    <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                </svg>
            </div>
            تعديل المصدر
        </h1>
        <p style="color: var(--text-secondary); margin: 0; font-size: 1rem;">تحديث بيانات الملف أو نقله لمادة أخرى</p>
    </div>
    <a href="{{ route('delegate.library.index') }}" class="btn btn-light" style="height: 46px; padding: 0 1.5rem; border-radius: 12px; font-weight: 700; display: flex; align-items: center; gap: 0.5rem; background: white; color: var(--text-secondary); border: 1px solid #e2e8f0; box-shadow: var(--shadow-sm);">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <polyline points="9 18 15 12 9 6"></polyline>
        </svg>
        <span>عودة للمكتبة</span>
    </a>
</div>

<div class="row justify-content-center">
    <div class="col-lg-8">
        <div class="card border-0 shadow-sm" style="background: white; border-radius: 20px; overflow: hidden;">
            <div style="background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%); padding: 1.5rem 2rem; border-bottom: 1px solid #e2e8f0;">
                <h5 style="font-weight: 800; color: var(--text-primary); margin: 0; font-size: 1.1rem; display: flex; align-items: center; gap: 0.5rem;">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="var(--primary-color)" stroke-width="2">
                        <path d="M13 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9z"></path>
                        <polyline points="13 2 13 9 20 9"></polyline>
                    </svg>
                    بيانات الملف
                </h5>
            </div>

            <div class="card-body" style="padding: 2rem;">
                <form action="{{ route('delegate.resources.update', $resource->id) }}" method="POST">
                    @csrf
                    @method('PUT')

                    <!-- Title -->
                    <div class="mb-4">
                        <label class="form-label" style="font-weight: 700; color: var(--text-secondary); margin-bottom: 0.75rem;">عنوان الملف <span style="color: #ef4444;">*</span></label>
                        <div style="position: relative;">
                            <div style="position: absolute; right: 1rem; top: 50%; transform: translateY(-50%); color: #94a3b8; pointer-events: none;">
                                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                                    <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                                </svg>
                            </div>
                            <input type="text" name="title" value="{{ old('title', $resource->title) }}" class="form-control"
                                style="height: 54px; background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 12px; padding-right: 3rem; font-weight: 600; font-size: 0.95rem; transition: all 0.2s;"
                                placeholder="مثال: ملخص المحاضرة الأولى" required
                                onfocus="this.style.background='white'; this.style.borderColor='var(--primary-color)';"
                                onblur="this.style.background='#f8fafc'; this.style.borderColor='#e2e8f0';">
                        </div>
                        @error('title')
                        <div style="color: #ef4444; font-size: 0.85rem; font-weight: 600; margin-top: 0.5rem;">{{ $message }}</div>
                        @enderror
                    </div>

                    <div class="row">
                        <!-- Subject -->
                        <div class="col-md-6 mb-4">
                            <label class="form-label" style="font-weight: 700; color: var(--text-secondary); margin-bottom: 0.75rem;">المادة الدراسية <span style="color: #ef4444;">*</span></label>
                            <div style="position: relative;">
                                <div style="position: absolute; right: 1rem; top: 50%; transform: translateY(-50%); color: #94a3b8; pointer-events: none;">
                                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path>
                                        <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path>
                                    </svg>
                                </div>
                                <select name="subject_id" class="form-select" style="height: 54px; background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 12px; padding-right: 3rem; font-weight: 600; font-size: 0.95rem; cursor: pointer; appearance: none;" required
                                    onfocus="this.style.background='white'; this.style.borderColor='var(--primary-color)';"
                                    onblur="this.style.background='#f8fafc'; this.style.borderColor='#e2e8f0';">
                                    @foreach($subjects as $subject)
                                    <option value="{{ $subject->id }}" {{ old('subject_id', $resource->subject_id) == $subject->id ? 'selected' : '' }}>{{ $subject->name }}</option>
                                    @endforeach
                                </select>
                                <div style="position: absolute; left: 1rem; top: 50%; transform: translateY(-50%); color: #94a3b8; pointer-events: none;">
                                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <polyline points="6 9 12 15 18 9"></polyline>
                                    </svg>
                                </div>
                            </div>
                        </div>

                        <!-- Category -->
                        <div class="col-md-6 mb-4">
                            <label class="form-label" style="font-weight: 700; color: var(--text-secondary); margin-bottom: 0.75rem;">نوع الملف <span style="color: #ef4444;">*</span></label>
                            <div style="position: relative;">
                                <div style="position: absolute; right: 1rem; top: 50%; transform: translateY(-50%); color: #94a3b8; pointer-events: none;">
                                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <line x1="8" y1="6" x2="21" y2="6"></line>
                                        <line x1="8" y1="12" x2="21" y2="12"></line>
                                        <line x1="8" y1="18" x2="21" y2="18"></line>
                                        <line x1="3" y1="6" x2="3.01" y2="6"></line>
                                        <line x1="3" y1="12" x2="3.01" y2="12"></line>
                                        <line x1="3" y1="18" x2="3.01" y2="18"></line>
                                    </svg>
                                </div>
                                <select name="category" class="form-select" style="height: 54px; background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 12px; padding-right: 3rem; font-weight: 600; font-size: 0.95rem; cursor: pointer; appearance: none;" required
                                    onfocus="this.style.background='white'; this.style.borderColor='var(--primary-color)';"
                                    onblur="this.style.background='#f8fafc'; this.style.borderColor='#e2e8f0';">
                                    <option value="lectures" {{ old('category', $resource->category) == 'lectures' ? 'selected' : '' }}>محاضرات</option>
                                    <option value="summaries" {{ old('category', $resource->category) == 'summaries' ? 'selected' : '' }}>ملخصات</option>
                                    <option value="exams" {{ old('category', $resource->category) == 'exams' ? 'selected' : '' }}>نماذج اختبارات</option>
                                    <option value="references" {{ old('category', $resource->category) == 'references' ? 'selected' : '' }}>مراجع وكتب</option>
                                    <option value="other" {{ old('category', $resource->category) == 'other' ? 'selected' : '' }}>أخرى</option>
                                </select>
                                <div style="position: absolute; left: 1rem; top: 50%; transform: translateY(-50%); color: #94a3b8; pointer-events: none;">
                                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <polyline points="6 9 12 15 18 9"></polyline>
                                    </svg>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Description -->
                    <div class="mb-4">
                        <label class="form-label" style="font-weight: 700; color: var(--text-secondary); margin-bottom: 0.75rem;">وصف إضافي (اختياري)</label>
                        <div style="position: relative;">
                            <textarea name="description" rows="4" class="form-control"
                                style="background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 12px; padding: 1rem; font-weight: 500; font-size: 0.95rem; resize: none; transition: all 0.2s;"
                                placeholder="أضف أي تفاصيل أخرى مفيدة للطلاب..."
                                onfocus="this.style.background='white'; this.style.borderColor='var(--primary-color)';"
                                onblur="this.style.background='#f8fafc'; this.style.borderColor='#e2e8f0';">{{ old('description', $resource->description) }}</textarea>
                        </div>
                    </div>

                    <!-- File Info (Read Only) -->
                    <div class="mb-5" style="background: #eff6ff; border: 1px dashed #bfdbfe; border-radius: 12px; padding: 1rem;">
                        <div style="display: flex; align-items: center; gap: 1rem;">
                            <div style="width: 48px; height: 48px; background: white; border-radius: 10px; display: flex; align-items: center; justify-content: center; color: var(--primary-color);">
                                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <path d="M13 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9z"></path>
                                    <polyline points="13 2 13 9 20 9"></polyline>
                                </svg>
                            </div>
                            <div>
                                <div style="font-weight: 700; color: #1e40af; margin-bottom: 0.2rem;">ملف مرفق</div>
                                <div style="font-size: 0.85rem; color: #3b82f6;">يتم الاحتفاظ بالملف الأصلي، يمكنك تحديث البيانات فقط.</div>
                            </div>
                            <a href="{{ Storage::url($resource->file_path) }}" target="_blank" class="ms-auto btn btn-sm btn-white" style="background: white; color: var(--primary-color); border: 1px solid #bfdbfe; font-weight: 700; padding: 0.4rem 1rem; border-radius: 8px;">
                                معاينة الملف
                            </a>
                        </div>
                    </div>

                    <!-- Actions -->
                    <div style="display: flex; gap: 1rem; justify-content: flex-end; padding-top: 1rem; border-top: 1px solid #f1f5f9;">
                        <a href="{{ route('delegate.library.index') }}" class="btn"
                            style="height: 54px; padding: 0 2rem; border-radius: 12px; font-weight: 700; display: flex; align-items: center; justify-content: center; background: white; color: var(--text-secondary); border: 1px solid #e2e8f0; transition: all 0.2s;"
                            onmouseover="this.style.background='#f8fafc'" onmouseout="this.style.background='white'">
                            إلغاء
                        </a>
                        <button type="submit" class="btn"
                            style="height: 54px; padding: 0 2.5rem; border-radius: 12px; font-weight: 700; display: flex; align-items: center; justify-content: center; gap: 0.5rem; background: var(--primary-color); color: white; border: none; box-shadow: 0 4px 6px -1px rgba(79, 70, 229, 0.2); transition: all 0.2s;"
                            onmouseover="this.style.transform='translateY(-1px)'; this.style.boxShadow='0 10px 15px -3px rgba(79, 70, 229, 0.3)';"
                            onmouseout="this.style.transform='translateY(0)'; this.style.boxShadow='0 4px 6px -1px rgba(79, 70, 229, 0.2)';">
                            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"></path>
                                <polyline points="17 21 17 13 7 13 7 21"></polyline>
                                <polyline points="7 3 7 8 15 8"></polyline>
                            </svg>
                            حفظ التعديلات
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>

@endsection