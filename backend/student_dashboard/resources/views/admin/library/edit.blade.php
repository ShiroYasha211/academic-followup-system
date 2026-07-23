@extends('layouts.admin')

@section('title', 'تعديل بيانات الملف - ' . $resource->title)

@section('content')
<div class="dashboard-container" style="max-width: 1000px; margin: 0 auto;">
    <!-- Header -->
    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 2.5rem;">
        <div>
            <h1 style="font-size: 1.8rem; font-weight: 800; color: var(--text-primary); margin-bottom: 0.5rem; display: flex; align-items: center; gap: 0.75rem;">
                <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="color: var(--primary-color);">
                    <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                    <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                </svg>
                تعديل بيانات الملف
            </h1>
            <p style="color: var(--text-secondary); margin: 0; font-size: 1rem;">تحديث البيانات الوصفية وإعدادات الخصوصية بدقة</p>
        </div>
        <a href="{{ route('admin.library.index') }}" 
           style="background: #f1f5f9; color: var(--text-primary); text-decoration: none; padding: 0.75rem 1.5rem; border-radius: 12px; font-weight: 700; display: flex; align-items: center; gap: 0.5rem; transition: all 0.2s;">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                <polyline points="15 18 9 12 15 6"></polyline>
            </svg>
            العودة للمكتبة
        </a>
    </div>

    <div style="display: grid; grid-template-columns: 1fr 320px; gap: 2rem;">
        <!-- Main Form Column -->
        <div class="card border-0 shadow-sm" style="background: white; border-radius: 25px; padding: 2.5rem;">
            <form action="{{ route('admin.library.update', $resource) }}" method="POST">
                @csrf
                @method('PUT')

                <div style="margin-bottom: 2rem;">
                    <label style="display: block; font-weight: 700; color: var(--text-primary); margin-bottom: 0.75rem; font-size: 0.95rem;">عنوان الملف / العنوان التعليمي</label>
                    <input type="text" name="title" value="{{ old('title', $resource->title) }}" 
                           style="width: 100%; padding: 0.85rem 1.25rem; border: 2px solid #f1f5f9; border-radius: 12px; font-size: 1rem; transition: all 0.2s;" required>
                </div>

                <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 1.5rem; margin-bottom: 2rem;">
                    <div>
                        <label style="display: block; font-weight: 700; color: var(--text-primary); margin-bottom: 0.75rem; font-size: 0.95rem;">المادة الدراسية</label>
                        <select name="subject_id" style="width: 100%; padding: 0.85rem 1.25rem; border: 2px solid #f1f5f9; border-radius: 12px; font-size: 1rem; cursor: pointer;" required>
                            @foreach($subjects as $subject)
                                <option value="{{ $subject->id }}" {{ old('subject_id', $resource->subject_id) == $subject->id ? 'selected' : '' }}>{{ $subject->name }}</option>
                            @endforeach
                        </select>
                    </div>
                    <div>
                        <label style="display: block; font-weight: 700; color: var(--text-primary); margin-bottom: 0.75rem; font-size: 0.95rem;">القسم الرئيسي</label>
                        <select name="category" style="width: 100%; padding: 0.85rem 1.25rem; border: 2px solid #f1f5f9; border-radius: 12px; font-size: 1rem; cursor: pointer;" required>
                            @foreach([
                                'lectures' => 'محاضرات',
                                'summaries' => 'ملخصات',
                                'quizzes' => 'كويزات',
                                'exams' => 'نماذج اختبارات',
                                'references' => 'مراجع',
                                'other' => 'أخرى'
                            ] as $val => $label)
                                <option value="{{ $val }}" {{ old('category', $resource->category) == $val ? 'selected' : '' }}>{{ $label }}</option>
                            @endforeach
                        </select>
                    </div>
                </div>

                <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 1.5rem; margin-bottom: 2rem;">
                    <div>
                        <label style="display: block; font-weight: 700; color: var(--text-primary); margin-bottom: 0.75rem; font-size: 0.95rem;">نوع المحاضرة</label>
                        <select name="sub_category" style="width: 100%; padding: 0.85rem 1.25rem; border: 2px solid #f1f5f9; border-radius: 12px; font-size: 1rem; cursor: pointer;">
                            <option value="">غير محدد</option>
                            <option value="theoretical" {{ old('sub_category', $resource->sub_category) == 'theoretical' ? 'selected' : '' }}>نظري</option>
                            <option value="practical" {{ old('sub_category', $resource->sub_category) == 'practical' ? 'selected' : '' }}>عملي</option>
                            <option value="seminar" {{ old('sub_category', $resource->sub_category) == 'seminar' ? 'selected' : '' }}>سمنار</option>
                        </select>
                    </div>
                    <div>
                        <label style="display: block; font-weight: 700; color: var(--text-primary); margin-bottom: 0.75rem; font-size: 0.95rem;">اسم الدكتور / المحاضر</label>
                        <input type="text" name="lecturer_name" value="{{ old('lecturer_name', $resource->lecturer_name) }}" 
                               style="width: 100%; padding: 0.85rem 1.25rem; border: 2px solid #f1f5f9; border-radius: 12px; font-size: 1rem;" placeholder="د. مثال">
                    </div>
                </div>

                <div style="margin-bottom: 2.5rem;">
                    <label style="display: block; font-weight: 700; color: var(--text-primary); margin-bottom: 0.75rem; font-size: 0.95rem;">وصف إضافي</label>
                    <textarea name="description" rows="3" 
                              style="width: 100%; padding: 0.85rem 1.25rem; border: 2px solid #f1f5f9; border-radius: 12px; font-size: 1rem; resize: none;">{{ old('description', $resource->description) }}</textarea>
                </div>

                <button type="submit" 
                        style="width: 100%; background: var(--primary-color); color: white; border: none; padding: 1rem; border-radius: 15px; font-size: 1.1rem; font-weight: 800; cursor: pointer; display: flex; align-items: center; justify-content: center; gap: 0.75rem; transition: all 0.2s; box-shadow: 0 10px 15px -3px rgba(79, 70, 229, 0.25);">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                        <path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"></path>
                        <polyline points="17 21 17 13 7 13 7 21"></polyline>
                        <polyline points="7 3 7 8 15 8"></polyline>
                    </svg>
                    حفظ كافة التعديلات
                </button>
            </form>
        </div>

        <!-- Sidebar Info Column -->
        <div style="display: flex; flex-direction: column; gap: 1.5rem;">
            <!-- Visibility Settings -->
            <div class="card border-0 shadow-sm" style="background: #f8fafc; border-radius: 20px; padding: 1.5rem;">
                <h3 style="font-size: 1rem; font-weight: 800; color: var(--text-primary); margin-bottom: 1.25rem; display: flex; align-items: center; gap: 0.5rem;">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" style="color: var(--primary-color);">
                        <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path>
                        <circle cx="12" cy="12" r="3"></circle>
                    </svg>
                    إعدادات الخصوصية
                </h3>
                
                <form action="{{ route('admin.library.update', $resource) }}" method="POST" id="visibilityForm">
                    @csrf
                    @method('PUT')
                    <!-- Hidden fields to preserve other data -->
                    <input type="hidden" name="title" value="{{ $resource->title }}">
                    <input type="hidden" name="subject_id" value="{{ $resource->subject_id }}">
                    <input type="hidden" name="category" value="{{ $resource->category }}">

                    <div style="display: flex; flex-direction: column; gap: 0.75rem;">
                        <label style="display: flex; align-items: center; gap: 0.75rem; padding: 0.85rem; background: white; border: 2px solid #f1f5f9; border-radius: 12px; cursor: pointer; transition: all 0.2s;" onmouseover="this.style.borderColor='var(--primary-color)'" onmouseout="this.style.borderColor='#f1f5f9'">
                            <input type="radio" name="visibility" value="everyone" {{ $resource->visibility == 'everyone' ? 'checked' : '' }} onchange="this.form.submit()">
                            <span style="font-weight: 700; font-size: 0.9rem;">عام للجميع</span>
                        </label>
                        <label style="display: flex; align-items: center; gap: 0.75rem; padding: 0.85rem; background: white; border: 2px solid #f1f5f9; border-radius: 12px; cursor: pointer; transition: all 0.2s;" onmouseover="this.style.borderColor='var(--primary-color)'" onmouseout="this.style.borderColor='#f1f5f9'">
                            <input type="radio" name="visibility" value="college" {{ $resource->visibility == 'college' ? 'checked' : '' }} onchange="this.form.submit()">
                            <span style="font-weight: 700; font-size: 0.9rem;">الكلية فقط</span>
                        </label>
                        <label style="display: flex; align-items: center; gap: 0.75rem; padding: 0.85rem; background: white; border: 2px solid #f1f5f9; border-radius: 12px; cursor: pointer; transition: all 0.2s;" onmouseover="this.style.borderColor='var(--primary-color)'" onmouseout="this.style.borderColor='#f1f5f9'">
                            <input type="radio" name="visibility" value="batch" {{ $resource->visibility == 'batch' ? 'checked' : '' }} onchange="this.form.submit()">
                            <span style="font-weight: 700; font-size: 0.9rem;">الدفعة: {{ $resource->batch }}</span>
                        </label>
                    </div>
                </form>
            </div>

            <!-- Resource File Info -->
            <div class="card border-0 shadow-sm" style="background: white; border-radius: 20px; padding: 1.5rem;">
                <h3 style="font-size: 0.9rem; font-weight: 800; color: var(--text-secondary); margin-bottom: 1.25rem; text-transform: uppercase; letter-spacing: 0.05em;">بيانات الملف الفنية</h3>
                
                <div style="display: flex; flex-direction: column; gap: 1rem;">
                    <div style="display: flex; justify-content: space-between; align-items: center;">
                        <span style="color: var(--text-secondary); font-size: 0.85rem;">الناشر:</span>
                        <span style="font-weight: 700; color: var(--text-primary);">{{ $resource->uploader->name }}</span>
                    </div>
                    <div style="display: flex; justify-content: space-between; align-items: center;">
                        <span style="color: var(--text-secondary); font-size: 0.85rem;">نوع الملف:</span>
                        <span style="font-weight: 700; font-size: 0.8rem; padding: 0.2rem 0.5rem; background: #fef2f2; color: #ef4444; border-radius: 6px;">{{ strtoupper($resource->file_type) }}</span>
                    </div>
                    <div style="display: flex; justify-content: space-between; align-items: center;">
                        <span style="color: var(--text-secondary); font-size: 0.85rem;">تاريخ الرفع:</span>
                        <span style="font-weight: 700; color: var(--text-primary);">{{ $resource->created_at->format('Y/m/d') }}</span>
                    </div>
                    <div style="display: flex; justify-content: space-between; align-items: center;">
                        <span style="color: var(--text-secondary); font-size: 0.85rem;">إجمالي التحميلات:</span>
                        <span style="font-weight: 700; color: var(--primary-color); font-size: 1.1rem;">{{ $resource->downloads_count ?? 0 }}</span>
                    </div>
                </div>

                <a href="{{ route('admin.library.download', $resource) }}" 
                   style="margin-top: 1.5rem; display: flex; align-items: center; justify-content: center; gap: 0.5rem; padding: 0.75rem; background: #eff6ff; color: #3b82f6; border-radius: 12px; font-weight: 700; transition: all 0.2s;">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="7 10 12 15 17 10"></polyline><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path><line x1="12" y1="15" x2="12" y2="3"></line></svg>
                    تحميل لمراجعة المحتوى
                </a>
            </div>
        </div>
    </div>
</div>
@endsection
