@extends('layouts.doctor')

@section('title', 'تعديل المصدر التعليمي')

@section('content')

<div style="max-width: 800px; margin: 0 auto;">

    <!-- Page Header -->
    <div style="margin-bottom: 2rem;">
        <a href="{{ route('doctor.resources.index') }}" style="display: inline-flex; align-items: center; gap: 0.5rem; color: var(--primary-color); text-decoration: none; font-weight: 600; margin-bottom: 1rem; transition: opacity 0.2s;" onmouseover="this.style.opacity='0.7'" onmouseout="this.style.opacity='1'">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <line x1="5" y1="12" x2="19" y2="12"></line>
                <polyline points="12 5 19 12 12 19"></polyline>
            </svg>
            العودة للمصادر
        </a>
        <h1 style="font-size: 2rem; font-weight: 800; color: var(--text-primary); margin: 0; letter-spacing: -0.5px;">📝 تعديل بيانات الملف</h1>
        <p style="color: var(--text-secondary); margin-top: 0.5rem; font-size: 1.05rem;">تحديث معلومات المصدر التعليمي في المكتبة المشتركة</p>
    </div>

    <form action="{{ route('doctor.resources.update', $resource) }}" method="POST">
        @csrf
        @method('PUT')

        <!-- File Info (Read Only) -->
        <div class="card" style="padding: 1.5rem; margin-bottom: 2rem; border-radius: 20px; border: none; box-shadow: var(--shadow-sm); background: #f8fafc; display: flex; align-items: center; gap: 1.5rem;">
            <div style="width: 60px; height: 60px; background: white; border-radius: 14px; display: flex; align-items: center; justify-content: center; color: var(--primary-color); box-shadow: 0 4px 10px rgba(0,0,0,0.05);">
                <svg xmlns="http://www.w3.org/2000/svg" width="30" height="30" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M13 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9z"></path>
                    <polyline points="13 2 13 9 20 9"></polyline>
                </svg>
            </div>
            <div>
                <div style="font-size: 0.85rem; color: var(--text-secondary); font-weight: 600; margin-bottom: 0.25rem;">الملف الحالي</div>
                <div style="font-size: 1.1rem; font-weight: 700; color: var(--text-primary);">{{ $resource->title }}</div>
                <div style="font-size: 0.85rem; color: var(--primary-color); font-weight: 700;">{{ strtoupper($resource->file_type) }}</div>
            </div>
            <div style="margin-right: auto;">
                <a href="{{ Storage::url($resource->file_path) }}" target="_blank" style="color: var(--primary-color); font-weight: 700; text-decoration: none; font-size: 0.9rem; border: 2px solid var(--primary-color); padding: 0.4rem 1rem; border-radius: 10px; transition: all 0.2s;" onmouseover="this.style.background='var(--primary-color)'; this.style.color='white'" onmouseout="this.style.background='none'; this.style.color='var(--primary-color)'">معاينة الملف</a>
            </div>
        </div>

        <!-- Step 1: Category Selection -->
        <div class="card" style="padding: 0; margin-bottom: 2rem; border-radius: 20px; overflow: hidden; border: none; box-shadow: var(--shadow-md);" x-data="{ category: '{{ $resource->category }}' }">
            <div style="background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%); padding: 1.25rem 1.5rem; display: flex; align-items: center; gap: 0.75rem;">
                <div style="width: 36px; height: 36px; background: rgba(255,255,255,0.2); border-radius: 10px; display: flex; align-items: center; justify-content: center;">
                    <span style="font-size: 1.2rem; color: white;">①</span>
                </div>
                <h3 style="color: white; font-weight: 700; margin: 0; font-size: 1.1rem;">تعديل تصنيف الملف</h3>
            </div>

            <div style="padding: 1.5rem; display: grid; grid-template-columns: repeat(auto-fit, minmax(120px, 1fr)); gap: 1rem;">
                @foreach(['lectures' => 'محاضرات', 'references' => 'مراجع', 'summaries' => 'ملخصات', 'exams' => 'اختبارات', 'other' => 'أخرى'] as $val => $label)
                <label class="category-card">
                    <input type="radio" name="category" value="{{ $val }}" x-model="category" {{ $resource->category == $val ? 'checked' : '' }}>
                    <div class="card-content" :class="{
                        'active-blue': category === 'lectures' && '{{ $val }}' === 'lectures',
                        'active-amber': category === 'references' && '{{ $val }}' === 'references',
                        'active-green': category === 'summaries' && '{{ $val }}' === 'summaries',
                        'active-red': category === 'exams' && '{{ $val }}' === 'exams',
                        'active-gray': category === 'other' && '{{ $val }}' === 'other'
                    }">
                        <div class="icon-box">
                            @if($val == 'lectures')
                            <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2z"/><path d="M22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z"/></svg>
                            @elseif($val == 'references')
                            <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"/><path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"/></svg>
                            @elseif($val == 'summaries')
                            <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/></svg>
                            @elseif($val == 'exams')
                            <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 11l3 3L22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/></svg>
                            @else
                            <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"/></svg>
                            @endif
                        </div>
                        <span class="label">{{ $label }}</span>
                    </div>
                </label>
                @endforeach
            </div>
        </div>

        <!-- Step 2: Details -->
        <div class="card" style="padding: 0; margin-bottom: 2rem; border-radius: 20px; overflow: hidden; border: none; box-shadow: var(--shadow-md);">
            <div style="background: linear-gradient(135deg, #10b981 0%, #059669 100%); padding: 1.25rem 1.5rem; display: flex; align-items: center; gap: 0.75rem;">
                <div style="width: 36px; height: 36px; background: rgba(255,255,255,0.2); border-radius: 10px; display: flex; align-items: center; justify-content: center;">
                    <span style="font-size: 1.2rem; color: white;">②</span>
                </div>
                <h3 style="color: white; font-weight: 700; margin: 0; font-size: 1.1rem;">تعديل معلومات الملف</h3>
            </div>

            <div style="padding: 1.5rem; display: grid; grid-template-columns: 1fr 1fr; gap: 1.25rem;">
                <!-- Subject -->
                <div style="grid-column: span 2;">
                    <label style="display: block; font-weight: 700; color: var(--text-primary); margin-bottom: 0.5rem;">المادة الدراسية</label>
                    <div style="position: relative;">
                        <select name="subject_id" required style="width: 100%; height: 52px; background: #f8fafc; border: 2px solid #e2e8f0; border-radius: 12px; padding: 0 2.5rem 0 1rem; font-weight: 600;">
                            @foreach($subjects as $subject)
                            <option value="{{ $subject->id }}" {{ $resource->subject_id == $subject->id ? 'selected' : '' }}>{{ $subject->name }}</option>
                            @endforeach
                        </select>
                        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#64748b" stroke-width="2" style="position: absolute; left: 14px; top: 50%; transform: translateY(-50%); pointer-events: none;">
                            <polyline points="6 9 12 15 18 9"></polyline>
                        </svg>
                    </div>
                </div>

                <!-- Title -->
                <div style="grid-column: span 2;">
                    <label style="display: block; font-weight: 700; color: var(--text-primary); margin-bottom: 0.5rem;">عنوان الملف</label>
                    <input type="text" name="title" value="{{ $resource->title }}" required style="width: 100%; height: 52px; background: #f8fafc; border: 2px solid #e2e8f0; border-radius: 12px; padding: 0 1rem; font-weight: 600;">
                </div>

                <!-- Description -->
                <div style="grid-column: span 2;">
                    <label style="display: block; font-weight: 700; color: var(--text-primary); margin-bottom: 0.5rem;">ملاحظات</label>
                    <textarea name="description" rows="3" style="width: 100%; background: #f8fafc; border: 2px solid #e2e8f0; border-radius: 12px; padding: 0.85rem 1rem; font-weight: 500;">{{ $resource->description }}</textarea>
                </div>
            </div>
        </div>

        <!-- Submit Button -->
        <button type="submit" style="width: 100%; height: 60px; background: linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%); color: white; border: none; border-radius: 16px; font-size: 1.2rem; font-weight: 800; cursor: pointer; display: flex; align-items: center; justify-content: center; gap: 0.75rem; box-shadow: 0 15px 35px -5px rgba(79, 70, 229, 0.4); transition: all 0.3s ease;">
            حفظ التعديلات
        </button>
    </form>
</div>

<style>
    .category-card { cursor: pointer; display: block; }
    .category-card input { display: none; }
    .category-card .card-content { padding: 1.5rem 0.5rem; border-radius: 16px; text-align: center; transition: all 0.3s ease; border: 2px solid #e2e8f0; background: #f8fafc; }
    .category-card .icon-box { width: 56px; height: 56px; margin: 0 auto 0.75rem; border-radius: 14px; display: flex; align-items: center; justify-content: center; background: #e2e8f0; color: #64748b; }
    .category-card .label { font-weight: 700; font-size: 0.95rem; color: #64748b; display: block; }

    .active-blue { background: linear-gradient(135deg, #eff6ff 0%, #dbeafe 100%) !important; border-color: #3b82f6 !important; }
    .active-blue .icon-box { background: #3b82f6 !important; color: white !important; }
    .active-blue .label { color: #1e40af !important; }

    .active-amber { background: linear-gradient(135deg, #fffbeb 0%, #fef3c7 100%) !important; border-color: #f59e0b !important; }
    .active-amber .icon-box { background: #f59e0b !important; color: white !important; }
    .active-amber .label { color: #92400e !important; }

    .active-green { background: linear-gradient(135deg, #ecfdf5 0%, #d1fae5 100%) !important; border-color: #10b981 !important; }
    .active-green .icon-box { background: #10b981 !important; color: white !important; }
    .active-green .label { color: #065f46 !important; }

    .active-red { background: linear-gradient(135deg, #fef2f2 0%, #fecaca 100%) !important; border-color: #ef4444 !important; }
    .active-red .icon-box { background: #ef4444 !important; color: white !important; }
    .active-red .label { color: #991b1b !important; }

    .active-gray { background: linear-gradient(135deg, #f8fafc 0%, #e2e8f0 100%) !important; border-color: #64748b !important; }
    .active-gray .icon-box { background: #64748b !important; color: white !important; }
    .active-gray .label { color: #334155 !important; }
</style>

@endsection
