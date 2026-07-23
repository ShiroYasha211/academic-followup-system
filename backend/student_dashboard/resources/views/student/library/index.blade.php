@extends(request()->routeIs('delegate.*') ? 'layouts.delegate' : (request()->routeIs('doctor.*') ? 'layouts.doctor' : 'layouts.student'))

@section('title', 'المكتبة المشتركة')

@section('content')
<div x-data="{ 
    showDetails: false, 
    resDetail: {},
    openDetails(res) {
        this.resDetail = res;
        this.showDetails = true;
    },
    closeDetails() {
        this.showDetails = false;
    },
    formatDate(dateStr) {
        if(!dateStr) return '-';
        const date = new Date(dateStr);
        return date.toLocaleDateString('ar-EG');
    }
}">
<!-- Page Header -->
<div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 2rem;">
    <div>
        <h1 style="font-size: 1.8rem; font-weight: 800; color: var(--text-primary); margin-bottom: 0.5rem; display: flex; align-items: center; gap: 0.75rem;">
            <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="color: var(--primary-color);">
                <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5"></path>
            </svg>
            المكتبة المشتركة
        </h1>
        <p style="color: var(--text-secondary); margin: 0; font-size: 1rem;">أرشيف شامل لجميع الملفات والملخصات والمحاضرات عبر السنوات الدراسية</p>
    </div>
    @php
        $createRoute = 'student.library.create';
        if(request()->routeIs('delegate.*')) $createRoute = 'delegate.library.create';
        if(request()->routeIs('doctor.*')) $createRoute = 'doctor.library.create';
        
        $canUpload = auth()->user()->hasRole('doctor') || auth()->user()->hasPermission('upload_shared_library');
    @endphp

    @if($canUpload)
     <a href="{{ route($createRoute) }}" 
       style="background: var(--primary-color); color: white; text-decoration: none; padding: 0.75rem 1.5rem; border-radius: 12px; font-weight: 700; display: flex; align-items: center; gap: 0.5rem; cursor: pointer; box-shadow: 0 4px 6px -1px rgba(79, 70, 229, 0.2); transition: all 0.2s;">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
            <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
            <polyline points="17 8 12 3 7 8"></polyline>
            <line x1="12" y1="3" x2="12" y2="15"></line>
        </svg>
        رفع ملف جديد
    </a>
    @endif

</div>

<!-- Stats Overview -->
<div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 1.5rem; margin-bottom: 2.5rem;">
    <div class="card border-0 shadow-sm" style="padding: 1.5rem; display: flex; align-items: center; gap: 1.5rem; background: white; border-radius: 20px;">
        <div style="width: 64px; height: 64px; border-radius: 16px; background: rgba(67, 56, 202, 0.1); display: flex; align-items: center; justify-content: center; color: var(--primary-color);">
            <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5"></path>
            </svg>
        </div>
        <div>
            <div style="font-size: 0.9rem; color: var(--text-secondary); font-weight: 600; margin-bottom: 0.25rem;">{{ auth()->user()->hasRole('doctor') ? 'ملفاتي ومواد القسم' : 'إجمالي المصادر' }}</div>
            <div style="font-size: 1.75rem; font-weight: 800; color: var(--text-primary); line-height: 1;">{{ $totalCount }}</div>
        </div>
    </div>
    <div class="card border-0 shadow-sm" style="padding: 1.5rem; display: flex; align-items: center; gap: 1.5rem; background: white; border-radius: 20px;">
        <div style="width: 64px; height: 64px; border-radius: 16px; background: rgba(245, 158, 11, 0.1); display: flex; align-items: center; justify-content: center; color: #f59e0b;">
            <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect>
                <line x1="16" y1="2" x2="16" y2="6"></line>
                <line x1="8" y1="2" x2="8" y2="6"></line>
                <line x1="3" y1="10" x2="21" y2="10"></line>
            </svg>
        </div>
        <div>
            <div style="font-size: 0.9rem; color: var(--text-secondary); font-weight: 600; margin-bottom: 0.25rem;">السنوات المتاحة</div>
            <div style="font-size: 1.75rem; font-weight: 800; color: var(--text-primary); line-height: 1;">{{ $years->count() }}</div>
        </div>
    </div>
    <div class="card border-0 shadow-sm" style="padding: 1.5rem; display: flex; align-items: center; gap: 1.5rem; background: white; border-radius: 20px;">
        <div style="width: 64px; height: 64px; border-radius: 16px; background: rgba(16, 185, 129, 0.1); display: flex; align-items: center; justify-content: center; color: #10b981;">
            <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path>
                <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path>
            </svg>
        </div>
        <div>
            <div style="font-size: 0.9rem; color: var(--text-secondary); font-weight: 600; margin-bottom: 0.25rem;">مادة متاحة</div>
            <div style="font-size: 1.75rem; font-weight: 800; color: var(--text-primary); line-height: 1;">{{ $subjects->count() }}</div>
        </div>
    </div>
</div>

<!-- Filters & Search -->
<div class="card border-0 shadow-sm" style="background: white; border-radius: 20px; padding: 1rem; margin-bottom: 1.5rem;" x-data="{ showAdvanced: {{ request()->hasAny(['semester_info', 'lecturer_name', 'sub_category', 'file_type', 'uploader_role']) ? 'true' : 'false' }} }">
    <form action="{{ route(Route::currentRouteName()) }}" method="GET" style="width: 100%;">
        @if(request('view'))
        <input type="hidden" name="view" value="{{ request('view') }}">
        @endif
        @if(request('my_uploads'))
        <input type="hidden" name="my_uploads" value="1">
        @endif

        <!-- Main Filter Row -->
        <div style="display: flex; align-items: center; gap: 0.75rem; width: 100%; flex-wrap: wrap; margin-bottom: 0.75rem;">
            <!-- Search -->
            <div style="flex: 2; min-width: 200px; position: relative;">
                <div style="position: absolute; right: 1.2rem; top: 50%; transform: translateY(-50%); color: #94a3b8; pointer-events: none;">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <circle cx="11" cy="11" r="8"></circle>
                        <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
                    </svg>
                </div>
                <input type="text" name="search" value="{{ request('search') }}" placeholder="ابحث باسم الملف أو المادة..."
                    style="width: 100%; height: 50px; background: #f8fafc; border: 1px solid #f1f5f9; border-radius: 12px; padding-right: 3rem; padding-left: 1rem; font-size: 0.95rem; font-weight: 600; outline: none; transition: all 0.2s; font-family: inherit;">
            </div>

            <!-- Subject -->
            <div style="flex: 1.5; min-width: 150px;">
                <div style="position: relative;">
                    <div style="position: absolute; right: 1rem; top: 50%; transform: translateY(-50%); color: #94a3b8; pointer-events: none;">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path><path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path></svg>
                    </div>
                    <select name="subject_id" style="width: 100%; height: 50px; background: #f8fafc; border: 1px solid #f1f5f9; border-radius: 12px; padding-right: 3rem; padding-left: 2rem; font-size: 0.95rem; font-weight: 600; cursor: pointer; appearance: none; outline: none; font-family: inherit;">
                        <option value="">جميع المواد</option>
                        @foreach($subjects as $subject)
                        <option value="{{ $subject->id }}" {{ request('subject_id') == $subject->id ? 'selected' : '' }}>{{ $subject->name }}</option>
                        @endforeach
                    </select>
                </div>
            </div>

            <!-- Category -->
            <div style="flex: 1; min-width: 130px;">
                <div style="position: relative;">
                    <div style="position: absolute; right: 1rem; top: 50%; transform: translateY(-50%); color: #94a3b8; pointer-events: none;">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="8" y1="6" x2="21" y2="6"></line><line x1="8" y1="12" x2="21" y2="12"></line><line x1="8" y1="18" x2="21" y2="18"></line><line x1="3" y1="6" x2="3.01" y2="6"></line><line x1="3" y1="12" x2="3.01" y2="12"></line><line x1="3" y1="18" x2="3.01" y2="18"></line></svg>
                    </div>
                    <select name="category" style="width: 100%; height: 50px; background: #f8fafc; border: 1px solid #f1f5f9; border-radius: 12px; padding-right: 3rem; padding-left: 2rem; font-size: 0.95rem; font-weight: 600; cursor: pointer; appearance: none; outline: none; font-family: inherit;">
                        <option value="">جميع الأنواع</option>
                        <option value="lectures" {{ request('category') == 'lectures' ? 'selected' : '' }}>محاضرات</option>
                        <option value="summaries" {{ request('category') == 'summaries' ? 'selected' : '' }}>ملخصات</option>
                        <option value="quizzes" {{ request('category') == 'quizzes' ? 'selected' : '' }}>كويزات</option>
                        <option value="exams" {{ request('category') == 'exams' ? 'selected' : '' }}>اختبارات</option>
                        <option value="references" {{ request('category') == 'references' ? 'selected' : '' }}>مراجع</option>
                    </select>
                </div>
            </div>

            <!-- Advanced Toggle -->
            <button type="button" @click="showAdvanced = !showAdvanced" 
                style="height: 50px; padding: 0 1rem; border-radius: 12px; font-weight: 600; display: flex; align-items: center; gap: 0.5rem; background: #f1f5f9; border: 1px solid #e2e8f0; color: #475569; cursor: pointer; transition: all 0.2s;">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M4 21v-7M4 10V3M12 21v-9M12 8V3M20 21v-5M20 12V3M1 14h6M9 8h6M17 16h6"></path>
                </svg>
                <span>خيارات متقدمة</span>
            </button>

            <!-- Search Button -->
            <button type="submit" class="btn" style="height: 50px; padding: 0 1.5rem; border-radius: 12px; font-weight: 700; display: flex; align-items: center; gap: 0.5rem; background: var(--primary-color); border: none; color: white; font-family: inherit; flex-shrink: 0; cursor: pointer;">
                <svg style="width: 20px; height: 20px; stroke: white; stroke-width: 2.5; fill: none;" viewBox="0 0 24 24">
                    <circle cx="11" cy="11" r="7" /><path d="M21 21l-4.35-4.35" />
                </svg>
                <span>بحث</span>
            </button>

            @if(request()->hasAny(['search', 'subject_id', 'category', 'year', 'my_uploads', 'semester_info', 'lecturer_name', 'sub_category', 'file_type', 'uploader_role']))
            <a href="{{ route(Route::currentRouteName(), ['view' => request('view')]) }}"
                style="width: 50px; height: 50px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; border-radius: 12px; background: #fef2f2; border: 1px solid #fee2e2;" title="إلغاء التصفية">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none"><path d="M18 6L6 18M6 6l12 12" stroke="#ef4444" stroke-width="2.5" stroke-linecap="round" /></svg>
            </a>
            @endif
        </div>

        <!-- Advanced Filter Row -->
        <div x-show="showAdvanced" x-cloak x-transition style="display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 0.75rem; padding-top: 1rem; border-top: 1px dashed #e2e8f0;">
            
            <!-- Uploader Role -->
            <div style="position: relative;">
                <div style="position: absolute; right: 1rem; top: 50%; transform: translateY(-50%); color: #94a3b8; pointer-events: none;">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path><circle cx="12" cy="7" r="4"></circle></svg>
                </div>
                <select name="uploader_role" style="width: 100%; height: 48px; background: #f8fafc; border: 1px solid #f1f5f9; border-radius: 12px; padding-right: 2.8rem; padding-left: 1rem; font-size: 0.9rem; font-weight: 600; cursor: pointer; appearance: none; outline: none;">
                    <option value="">أي رتبة</option>
                    <option value="doctor" {{ request('uploader_role') == 'doctor' ? 'selected' : '' }}>دكتور</option>
                    <option value="delegate" {{ request('uploader_role') == 'delegate' ? 'selected' : '' }}>مندوب</option>
                    <option value="student" {{ request('uploader_role') == 'student' ? 'selected' : '' }}>طالب</option>
                </select>
            </div>

            <!-- Semester -->
            <div style="position: relative;">
                <div style="position: absolute; right: 1rem; top: 50%; transform: translateY(-50%); color: #94a3b8; pointer-events: none;">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect><line x1="16" y1="2" x2="16" y2="6"></line><line x1="8" y1="2" x2="8" y2="6"></line><line x1="3" y1="10" x2="21" y2="10"></line></svg>
                </div>
                <select name="semester_info" style="width: 100%; height: 48px; background: #f8fafc; border: 1px solid #f1f5f9; border-radius: 12px; padding-right: 2.8rem; padding-left: 1rem; font-size: 0.9rem; font-weight: 600; cursor: pointer; appearance: none; outline: none;">
                    <option value="">أي فصل/سستم</option>
                    @foreach($semesters as $sem)
                    <option value="{{ $sem }}" {{ request('semester_info') == $sem ? 'selected' : '' }}>{{ $sem }}</option>
                    @endforeach
                </select>
            </div>

            <!-- Lecturer -->
            <div style="position: relative;">
                <div style="position: absolute; right: 1rem; top: 50%; transform: translateY(-50%); color: #94a3b8; pointer-events: none;">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path></svg>
                </div>
                <select name="lecturer_name" style="width: 100%; height: 48px; background: #f8fafc; border: 1px solid #f1f5f9; border-radius: 12px; padding-right: 2.8rem; padding-left: 1rem; font-size: 0.9rem; font-weight: 600; cursor: pointer; appearance: none; outline: none;">
                    <option value="">أي دكتور</option>
                    @foreach($lecturers as $lec)
                    <option value="{{ $lec }}" {{ request('lecturer_name') == $lec ? 'selected' : '' }}>{{ $lec }}</option>
                    @endforeach
                </select>
            </div>

            <!-- Sub-category -->
            <div style="position: relative;">
                <div style="position: absolute; right: 1rem; top: 50%; transform: translateY(-50%); color: #94a3b8; pointer-events: none;">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="8" x2="12" y2="16"></line><line x1="8" y1="12" x2="16" y2="12"></line></svg>
                </div>
                <select name="sub_category" style="width: 100%; height: 48px; background: #f8fafc; border: 1px solid #f1f5f9; border-radius: 12px; padding-right: 2.8rem; padding-left: 1rem; font-size: 0.9rem; font-weight: 600; cursor: pointer; appearance: none; outline: none;">
                    <option value="">أي نوع (نظري/عملي..)</option>
                    <option value="theoretical" {{ request('sub_category') == 'theoretical' ? 'selected' : '' }}>نظري</option>
                    <option value="practical" {{ request('sub_category') == 'practical' ? 'selected' : '' }}>عملي</option>
                    <option value="seminar" {{ request('sub_category') == 'seminar' ? 'selected' : '' }}>سمنار</option>
                    <option value="other" {{ request('sub_category') == 'other' ? 'selected' : '' }}>أخرى</option>
                </select>
            </div>

            <!-- File Type -->
            <div style="position: relative;">
                <div style="position: absolute; right: 1rem; top: 50%; transform: translateY(-50%); color: #94a3b8; pointer-events: none;">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M13 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9z"></path><polyline points="13 2 13 9 20 9"></polyline></svg>
                </div>
                <select name="file_type" style="width: 100%; height: 48px; background: #f8fafc; border: 1px solid #f1f5f9; border-radius: 12px; padding-right: 2.8rem; padding-left: 1rem; font-size: 0.9rem; font-weight: 600; cursor: pointer; appearance: none; outline: none;">
                    <option value="">أي تنسيق</option>
                    <option value="pdf" {{ request('file_type') == 'pdf' ? 'selected' : '' }}>PDF</option>
                    <option value="powerpoint" {{ request('file_type') == 'powerpoint' ? 'selected' : '' }}>بوربوينت</option>
                    <option value="word" {{ request('file_type') == 'word' ? 'selected' : '' }}>وورد</option>
                    <option value="excel" {{ request('file_type') == 'excel' ? 'selected' : '' }}>اكسل</option>
                    <option value="images" {{ request('file_type') == 'images' ? 'selected' : '' }}>صور</option>
                    <option value="compressed" {{ request('file_type') == 'compressed' ? 'selected' : '' }}>ملفات مضغوطة</option>
                </select>
            </div>

            <!-- Year -->
            <div style="position: relative;">
                <div style="position: absolute; right: 1rem; top: 50%; transform: translateY(-50%); color: #94a3b8; pointer-events: none;">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"></circle><polyline points="12 6 12 12 16 14"></polyline></svg>
                </div>
                <select name="year" style="width: 100%; height: 48px; background: #f8fafc; border: 1px solid #f1f5f9; border-radius: 12px; padding-right: 2.8rem; padding-left: 1rem; font-size: 0.9rem; font-weight: 600; cursor: pointer; appearance: none; outline: none;">
                    <option value="">كل السنوات</option>
                    @foreach($years as $year)
                    <option value="{{ $year }}" {{ request('year') == $year ? 'selected' : '' }}>{{ $year }}</option>
                    @endforeach
                </select>
            </div>

        </div>
    </form>
</div>

<!-- Main Content Card -->
<div class="card border-0 shadow-sm" style="background: white; border-radius: 20px; overflow: hidden;">
    <!-- Header with View Toggle -->
    <div style="display: flex; justify-content: space-between; align-items: center; padding: 1.25rem 1.5rem; border-bottom: 1px solid #f1f5f9; flex-wrap: wrap; gap: 0.75rem;">
        <h5 style="font-weight: 700; margin: 0; display: flex; align-items: center; gap: 0.75rem; color: var(--text-primary);">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="var(--primary-color)" stroke-width="2">
                <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5"></path>
            </svg>
            أرشيف المصادر
        </h5>
        <div style="display: flex; align-items: center; gap: 0.75rem;">
            <!-- View Toggle -->
            <div style="display: flex; background: #f1f5f9; border-radius: 10px; padding: 3px;">
                <a href="{{ route(Route::currentRouteName(), array_merge(request()->except('view'), ['view' => 'by_subject'])) }}"
                    style="padding: 0.4rem 0.75rem; border-radius: 8px; font-size: 0.85rem; font-weight: 600; text-decoration: none; display: flex; align-items: center; gap: 0.3rem; {{ ($viewMode ?? 'by_subject') == 'by_subject' ? 'background: white; color: var(--primary-color); box-shadow: 0 1px 3px rgba(0,0,0,0.1);' : 'color: #64748b;' }}">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path>
                        <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path>
                    </svg>
                    حسب المادة
                </a>
                <a href="{{ route(Route::currentRouteName(), array_merge(request()->except('view'), ['view' => 'by_year'])) }}"
                    style="padding: 0.4rem 0.75rem; border-radius: 8px; font-size: 0.85rem; font-weight: 600; text-decoration: none; display: flex; align-items: center; gap: 0.3rem; {{ ($viewMode ?? 'by_subject') == 'by_year' ? 'background: white; color: var(--primary-color); box-shadow: 0 1px 3px rgba(0,0,0,0.1);' : 'color: #64748b;' }}">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect>
                        <line x1="16" y1="2" x2="16" y2="6"></line>
                        <line x1="8" y1="2" x2="8" y2="6"></line>
                        <line x1="3" y1="10" x2="21" y2="10"></line>
                    </svg>
                    حسب السنة
                </a>
                <a href="{{ route(Route::currentRouteName(), array_merge(request()->except('view'), ['view' => 'table'])) }}"
                    style="padding: 0.4rem 0.75rem; border-radius: 8px; font-size: 0.85rem; font-weight: 600; text-decoration: none; display: flex; align-items: center; gap: 0.3rem; {{ ($viewMode ?? 'by_subject') == 'table' ? 'background: white; color: var(--primary-color); box-shadow: 0 1px 3px rgba(0,0,0,0.1);' : 'color: #64748b;' }}">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <line x1="8" y1="6" x2="21" y2="6"></line>
                        <line x1="8" y1="12" x2="21" y2="12"></line>
                        <line x1="8" y1="18" x2="21" y2="18"></line>
                        <line x1="3" y1="6" x2="3.01" y2="6"></line>
                        <line x1="3" y1="12" x2="3.01" y2="12"></line>
                        <line x1="3" y1="18" x2="3.01" y2="18"></line>
                    </svg>
                    جدول
                </a>
            </div>

            <!-- My Uploads Toggle -->
            @if(auth()->user()->hasRole(\App\Enums\UserRole::DELEGATE))
            <a href="{{ route(Route::currentRouteName(), array_merge(request()->except('my_uploads'), request('my_uploads') ? [] : ['my_uploads' => 1])) }}"
                style="padding: 0.4rem 0.8rem; border-radius: 10px; font-size: 0.85rem; font-weight: 700; text-decoration: none; display: flex; align-items: center; gap: 0.5rem; transition: all 0.2s; {{ request('my_uploads') ? 'background: #eff6ff; color: var(--primary-color); border: 1px solid #dbeafe;' : 'background: white; color: var(--text-secondary); border: 1px solid #e2e8f0;' }}">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path>
                    <circle cx="12" cy="7" r="4"></circle>
                </svg>
                مساهماتي
            </a>
            @endif

            <span style="background: #f8fafc; color: var(--text-primary); padding: 0.4rem 1rem; border-radius: 20px; font-size: 0.85rem; font-weight: 700; border: 1px solid #e2e8f0;">{{ $totalCount }} مصدر</span>
        </div>
    </div>

    {{-- ═══════════════════ GROUPED VIEWS (by_subject / by_year) ═══════════════════ --}}
    @if($viewMode !== 'table')
    <div style="padding: 1.5rem;">
        @if($groupedResources && $groupedResources->count() > 0)
        @foreach($groupedResources as $groupKey => $groupItems)
        @php
        $groupColors = ['#4338ca','#0891b2','#059669','#d97706','#dc2626','#7c3aed','#0d9488','#ea580c'];
        $colorIndex = $loop->index % count($groupColors);
        $groupColor = $groupColors[$colorIndex];
        @endphp
        <div style="margin-bottom: 1.5rem; border: 1px solid #e2e8f0; border-radius: 16px; overflow: hidden;">
            <!-- Group Header -->
            <div style="background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%); padding: 1rem 1.5rem; display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid #e2e8f0;">
                <div style="display: flex; align-items: center; gap: 0.75rem;">
                    <div style="width: 42px; height: 42px; background: {{ $groupColor }}; border-radius: 12px; display: flex; align-items: center; justify-content: center;">
                        @if($viewMode === 'by_year')
                        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2">
                            <rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect>
                            <line x1="16" y1="2" x2="16" y2="6"></line>
                            <line x1="8" y1="2" x2="8" y2="6"></line>
                            <line x1="3" y1="10" x2="21" y2="10"></line>
                        </svg>
                        @else
                        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2">
                            <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path>
                            <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path>
                        </svg>
                        @endif
                    </div>
                    <div>
                        <h4 style="font-weight: 700; color: var(--text-primary); margin: 0; font-size: 1.1rem;">
                            @if($viewMode === 'by_year')
                            العام الدراسي {{ $groupKey }}
                            @else
                            {{ $groupKey }}
                            @endif
                        </h4>
                    </div>
                </div>
                <span style="background: {{ $groupColor }}; color: white; padding: 0.35rem 0.85rem; border-radius: 20px; font-size: 0.8rem; font-weight: 700;">{{ $groupItems->count() }} ملف</span>
            </div>
            <!-- Files List -->
            <div style="padding: 0.5rem;">
                @foreach($groupItems as $resource)
                @php
                $ext = strtolower($resource->file_type ?? '');
                $iconColor = '#64748b';
                if(in_array($ext, ['pdf'])) { $iconColor = '#ef4444'; }
                elseif(in_array($ext, ['ppt','pptx'])) { $iconColor = '#f59e0b'; }
                elseif(in_array($ext, ['doc','docx'])) { $iconColor = '#3b82f6'; }
                elseif(in_array($ext, ['xls','xlsx'])) { $iconColor = '#10b981'; }
                elseif(in_array($ext, ['jpg','jpeg','png'])) { $iconColor = '#06b6d4'; }
                elseif(in_array($ext, ['zip','rar'])) { $iconColor = '#4b5563'; }
                @endphp
                <div class="lib-row-hover" style="display: flex; align-items: center; justify-content: space-between; padding: 0.75rem 1rem; border-radius: 10px; transition: background 0.15s;">
                    <div style="display: flex; align-items: center; gap: 0.75rem; flex: 1; min-width: 0;">
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="{{ $iconColor }}" stroke-width="2">
                            <path d="M13 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9z"></path>
                            <polyline points="13 2 13 9 20 9"></polyline>
                        </svg>
                        <div style="flex: 1; min-width: 0;">
                            <div style="font-weight: 700; color: var(--text-primary); font-size: 0.9rem; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">{{ $resource->title }}</div>
                            <div style="font-size: 0.75rem; color: var(--text-secondary); display: flex; align-items: center; gap: 0.5rem; flex-wrap: wrap;">
                                <span>{{ strtoupper($resource->file_type ?? '-') }}</span>
                                <span>•</span>
                                <span>{{ $resource->created_at->format('Y/m/d') }}</span>
                                @if($viewMode === 'by_subject')
                                <span>•</span>
                                <span style="background: #eff6ff; color: #1d4ed8; padding: 0.1rem 0.5rem; border-radius: 8px; font-weight: 700;">{{ $resource->full_category_text }}</span>
                                @endif
                            </div>
                        </div>
                    </div>
                    <!-- Actions -->
                    <div style="display: flex; gap: 0.4rem; flex-shrink: 0;">
                        <!-- View Details -->
                        <button @click='openDetails(@json($resource->load("subject", "uploader")))'
                            style="width: 32px; height: 32px; display: flex; align-items: center; justify-content: center; background: white; color: var(--primary-color); border: 1px solid #e2e8f0; border-radius: 8px; cursor: pointer; transition: all 0.2s;"
                            title="عرض التفاصيل">
                            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path>
                                <circle cx="12" cy="12" r="3"></circle>
                            </svg>
                        </button>
                        @if(auth()->id() == $resource->created_by && auth()->user()->hasRole(\App\Enums\UserRole::DELEGATE))
                        <a href="{{ route('delegate.resources.edit', $resource->id) }}"
                            style="width: 32px; height: 32px; display: flex; align-items: center; justify-content: center; background: white; color: #f59e0b; border: 1px solid #e2e8f0; border-radius: 8px; transition: all 0.2s;"
                            title="تعديل">
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                                <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                            </svg>
                        </a>
                        @endif
                        @if(auth()->user()->hasRole(\App\Enums\UserRole::STUDENT))
                        <button onclick="addToHub({{ $resource->id }}, '{{ addslashes($resource->title) }}')"
                            style="width: 32px; height: 32px; display: flex; align-items: center; justify-content: center; background: white; color: var(--primary-color); border: 1px solid #e2e8f0; border-radius: 8px; cursor: pointer; transition: all 0.2s;"
                            title="إضافة لمركزي">
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <line x1="12" y1="5" x2="12" y2="19"></line>
                                <line x1="5" y1="12" x2="19" y2="12"></line>
                            </svg>
                        </button>
                        @endif
                        @if(auth()->user()->hasRole(\App\Enums\UserRole::DELEGATE))
                        <button onclick="openImportModal({{ $resource->id }}, '{{ addslashes($resource->title) }}')"
                            style="width: 32px; height: 32px; display: flex; align-items: center; justify-content: center; background: white; color: #06b6d4; border: 1px solid #e2e8f0; border-radius: 8px; cursor: pointer; transition: all 0.2s;"
                            title="إدراج للمقرر">
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M4 12v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8"></path>
                                <polyline points="16 6 12 2 8 6"></polyline>
                                <line x1="12" y1="2" x2="12" y2="15"></line>
                            </svg>
                        </button>
                        @endif
                        <a href="{{ route('student.library.download', $resource->id) }}"
                            style="width: 32px; height: 32px; display: flex; align-items: center; justify-content: center; background: #eff6ff; color: var(--primary-color); border-radius: 8px; text-decoration: none;"
                            title="تحميل">
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
                                <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" stroke="currentColor" stroke-width="2"></path>
                                <polyline points="7 10 12 15 17 10" stroke="currentColor" stroke-width="2"></polyline>
                                <line x1="12" y1="15" x2="12" y2="3" stroke="currentColor" stroke-width="2"></line>
                            </svg>
                        </a>
                    </div>
                </div>
                @endforeach
            </div>
        </div>
        @endforeach
        @else
        @include('student.library._empty_state')
        @endif
    </div>

    {{-- ═══════════════════ TABLE VIEW ═══════════════════ --}}
    @else
    <div style="overflow-x: auto;">
        <div class="table-responsive">
<table style="width: 100%; border-collapse: separate; border-spacing: 0;">
            <thead>
                <tr style="background: #f8fafc;">
                    <th style="padding: 1.25rem 1.5rem; text-align: right; font-weight: 600; color: var(--text-secondary); font-size: 0.85rem; width: 35%;">اسم الملف</th>
                    <th style="padding: 1.25rem 1.5rem; text-align: right; font-weight: 600; color: var(--text-secondary); font-size: 0.85rem;">المادة</th>
                    <th style="padding: 1.25rem 1.5rem; text-align: right; font-weight: 600; color: var(--text-secondary); font-size: 0.85rem;">النوع</th>
                    <th style="padding: 1.25rem 1.5rem; text-align: right; font-weight: 600; color: var(--text-secondary); font-size: 0.85rem;">التاريخ</th>
                    <th style="padding: 1.25rem 1.5rem; text-align: left; font-weight: 600; color: var(--text-secondary); font-size: 0.85rem;">إجراءات</th>
                </tr>
            </thead>
            <tbody>
                @forelse($resources as $resource)
                <tr style="transition: background 0.15s;" onmouseover="this.style.background='#fafbfe'" onmouseout="this.style.background='white'">
                    <td style="padding: 1rem 1.5rem; border-bottom: 1px solid #f1f5f9;">
                        <div style="display: flex; align-items: center;">
                            @php
                            $ext = strtolower($resource->file_type ?? '');
                            $iconColor = '#64748b'; $bgIcon = '#f1f5f9';
                            if(in_array($ext, ['pdf'])) { $iconColor = '#ef4444'; $bgIcon = '#fef2f2'; }
                            elseif(in_array($ext, ['ppt','pptx'])) { $iconColor = '#f59e0b'; $bgIcon = '#fffbeb'; }
                            elseif(in_array($ext, ['doc','docx'])) { $iconColor = '#3b82f6'; $bgIcon = '#eff6ff'; }
                            elseif(in_array($ext, ['xls','xlsx'])) { $iconColor = '#10b981'; $bgIcon = '#ecfdf5'; }
                            @endphp
                            <div style="width: 46px; height: 46px; background: {{ $bgIcon }}; border-radius: 12px; display: flex; align-items: center; justify-content: center; margin-left: 1rem; flex-shrink: 0; color: {{ $iconColor }}; border: 1px solid rgba(0,0,0,0.03);">
                                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
                                    <path d="M13 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9z"></path>
                                    <polyline points="13 2 13 9 20 9"></polyline>
                                </svg>
                            </div>
                            <div>
                                <div style="font-weight: 700; color: var(--text-primary); font-size: 0.95rem;">{{ $resource->title }}</div>
                                <div style="font-size: 0.75rem; color: var(--text-secondary); font-weight: 600;">{{ strtoupper($resource->file_type ?? '-') }}</div>
                            </div>
                        </div>
                    </td>
                    <td style="padding: 1rem 1.5rem; border-bottom: 1px solid #f1f5f9;">
                        <span style="background: white; color: var(--text-primary); border: 1px solid #e2e8f0; font-weight: 700; padding: 0.35rem 0.75rem; border-radius: 20px; font-size: 0.8rem; display: inline-block; box-shadow: var(--shadow-sm);">
                            {{ $resource->subject->name ?? '-' }}
                        </span>
                    </td>
                    <td style="padding: 1rem 1.5rem; border-bottom: 1px solid #f1f5f9;">
                        <div style="display: flex; flex-direction: column; gap: 4px;">
                            <span style="background: #eff6ff; color: #1d4ed8; font-weight: 800; padding: 0.25rem 0.75rem; border-radius: 20px; font-size: 0.75rem; width: fit-content; border: 1px solid #dbeafe;">
                                {{ $resource->full_category_text }}
                            </span>
                            <span style="font-size: 0.75rem; color: var(--text-secondary); font-weight: 600; padding-right: 0.5rem;">{{ $resource->semester_info }}</span>
                        </div>
                    </td>
                    <td style="padding: 1rem 1.5rem; border-bottom: 1px solid #f1f5f9; color: var(--text-secondary); font-size: 0.85rem; font-weight: 600;">
                        {{ $resource->created_at->format('Y/m/d') }}
                    </td>
                    <td style="padding: 1rem 1.5rem; border-bottom: 1px solid #f1f5f9; text-align: left;">
                        <div style="display: flex; gap: 0.5rem; justify-content: flex-end;">
                            <!-- View Details -->
                            <button @click='openDetails(@json($resource->load("subject", "uploader")))'
                                style="width: 36px; height: 36px; display: inline-flex; align-items: center; justify-content: center; background: white; color: var(--primary-color); border: 1px solid #e2e8f0; border-radius: 10px; transition: all 0.2s; cursor: pointer;"
                                title="عرض التفاصيل">
                                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path>
                                    <circle cx="12" cy="12" r="3"></circle>
                                </svg>
                            </button>
                            @if(auth()->id() == $resource->created_by && auth()->user()->hasRole(\App\Enums\UserRole::DELEGATE))
                            <a href="{{ route('delegate.resources.edit', $resource->id) }}"
                                style="width: 36px; height: 36px; display: inline-flex; align-items: center; justify-content: center; background: white; color: #f59e0b; border: 1px solid #e2e8f0; border-radius: 10px; transition: all 0.2s;"
                                title="تعديل">
                                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                                    <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                                </svg>
                            </a>
                            @endif
                            @if(auth()->user()->hasRole(\App\Enums\UserRole::STUDENT))
                            <button onclick="addToHub({{ $resource->id }}, '{{ addslashes($resource->title) }}')"
                                style="width: 36px; height: 36px; display: inline-flex; align-items: center; justify-content: center; background: white; color: var(--primary-color); border: 1px solid #e2e8f0; border-radius: 10px; transition: all 0.2s; cursor: pointer;"
                                title="إضافة لمركزي"
                                onmouseover="this.style.background='var(--primary-color)'; this.style.color='white'; this.style.borderColor='var(--primary-color)';"
                                onmouseout="this.style.background='white'; this.style.color='var(--primary-color)'; this.style.borderColor='#e2e8f0';">
                                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <line x1="12" y1="5" x2="12" y2="19"></line>
                                    <line x1="5" y1="12" x2="19" y2="12"></line>
                                </svg>
                            </button>
                            @endif
                            @if(auth()->user()->hasRole(\App\Enums\UserRole::DELEGATE))
                            <button onclick="openImportModal({{ $resource->id }}, '{{ addslashes($resource->title) }}')"
                                style="width: 36px; height: 36px; display: inline-flex; align-items: center; justify-content: center; background: white; color: #06b6d4; border: 1px solid #e2e8f0; border-radius: 10px; transition: all 0.2s; cursor: pointer;"
                                title="إدراج للمقرر"
                                onmouseover="this.style.background='#06b6d4'; this.style.color='white'; this.style.borderColor='#06b6d4';"
                                onmouseout="this.style.background='white'; this.style.color='#06b6d4'; this.style.borderColor='#e2e8f0';">
                                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <path d="M4 12v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8"></path>
                                    <polyline points="16 6 12 2 8 6"></polyline>
                                    <line x1="12" y1="2" x2="12" y2="15"></line>
                                </svg>
                            </button>
                            @endif
                            <a href="{{ route('student.library.download', $resource->id) }}"
                                style="width: 36px; height: 36px; display: inline-flex; align-items: center; justify-content: center; background: #eff6ff; color: var(--primary-color); border-radius: 10px; text-decoration: none;"
                                title="تحميل"
                                onmouseover="this.style.background='var(--primary-color)'; this.style.color='white';"
                                onmouseout="this.style.background='#eff6ff'; this.style.color='var(--primary-color)';">
                                <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
                                    <path d="M12 3v12m0 0l-4-4m4 4l4-4M4 17v2a2 2 0 002 2h12a2 2 0 002-2v-2" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" />
                                </svg>
                            </a>
                        </div>
                    </td>
                </tr>
                @empty
                <tr>
                    <td colspan="6">@include('student.library._empty_state')</td>
                </tr>
                @endforelse
            </tbody>
        </table>
</div>
    </div>
    @if($resources && $resources->hasPages())
    <div style="display: flex; justify-content: center; padding: 1.5rem; border-top: 1px solid #f1f5f9;">
        {{ $resources->withQueryString()->links('pagination::bootstrap-5') }}
    </div>
    @endif
    @endif
</div>

<!-- Import Modal (Delegate) -->
@if(auth()->user()->hasRole(\App\Enums\UserRole::DELEGATE))
<div id="importModal" style="display: none; position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.5); z-index: 1000; align-items: center; justify-content: center; backdrop-filter: blur(4px);">
    <div style="background: white; border-radius: 16px; width: 100%; max-width: 500px; padding: 2rem; box-shadow: 0 20px 25px -5px rgba(0,0,0,0.1); margin: 1rem; animation: slideUp 0.3s ease-out;">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 2rem;">
            <h3 style="font-size: 1.5rem; font-weight: 800; color: var(--text-primary); margin: 0;">إدراج للمقرر الحالي</h3>
            <button onclick="closeImportModal()" style="background: none; border: none; color: var(--text-secondary); cursor: pointer;"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <line x1="18" y1="6" x2="6" y2="18"></line>
                    <line x1="6" y1="6" x2="18" y2="18"></line>
                </svg></button>
        </div>
        <form action="{{ route('delegate.resources.import') }}" method="POST">
            @csrf
            <input type="hidden" name="resource_id" id="import_resource_id">
            <div style="margin-bottom: 1.5rem;">
                <label style="display: block; margin-bottom: 0.5rem; color: var(--text-secondary); font-weight: 600;">الملف المحدد</label>
                <div id="import_resource_title" style="font-weight: 700; color: var(--text-primary); font-size: 1.1rem; padding: 0.75rem; background: #f8fafc; border-radius: 8px;"></div>
            </div>
            <div style="margin-bottom: 1.5rem;">
                <label style="display: block; margin-bottom: 0.5rem; color: var(--text-secondary); font-weight: 600;">المقرر المستهدف</label>
                <select name="subject_id" required style="width: 100%; height: 50px; background: #f8fafc; border: 1px solid #f1f5f9; border-radius: 12px; padding: 0 1rem; font-size: 0.95rem; font-weight: 600; cursor: pointer; appearance: none; outline: none; font-family: inherit;">
                    @foreach($subjects->where('level_id', auth()->user()->level_id) as $subject)
                    <option value="{{ $subject->id }}">{{ $subject->name }}</option>
                    @endforeach
                </select>
            </div>
            <div style="background: #eff6ff; border-radius: 10px; padding: 1rem; margin-bottom: 1.5rem; display: flex; align-items: flex-start; gap: 0.75rem;">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#3b82f6" stroke-width="2" style="flex-shrink: 0; margin-top: 2px;">
                    <circle cx="12" cy="12" r="10"></circle>
                    <line x1="12" y1="16" x2="12" y2="12"></line>
                    <line x1="12" y1="8" x2="12.01" y2="8"></line>
                </svg>
                <span style="color: #1e40af; font-size: 0.85rem; font-weight: 600;">نسخة مرجعية بدون استهلاك مساحة إضافية.</span>
            </div>
            <div style="display: flex; gap: 1rem; justify-content: flex-end;">
                <button type="button" onclick="closeImportModal()" style="background: #f1f5f9; color: var(--text-secondary); border: none; padding: 0.75rem 1.5rem; border-radius: 8px; font-weight: 700; cursor: pointer; font-family: inherit;">إلغاء</button>
                <button type="submit" style="background: var(--primary-color); color: white; border: none; padding: 0.75rem 1.5rem; border-radius: 8px; font-weight: 700; cursor: pointer; font-family: inherit;">تأكيد الإدراج</button>
            </div>
        </form>
    </div>
</div>
@endif

<!-- Add to Hub Modal (Student Only) -->
@if(auth()->user()->hasRole(\App\Enums\UserRole::STUDENT))
<div id="addToHubModal" style="display: none; position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.5); z-index: 1000; align-items: center; justify-content: center; backdrop-filter: blur(4px);">
    <div style="background: white; border-radius: 16px; width: 100%; max-width: 500px; padding: 2rem; box-shadow: 0 20px 25px -5px rgba(0,0,0,0.1); margin: 1rem; animation: slideUp 0.3s ease-out;">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 2rem;">
            <h3 style="font-size: 1.5rem; font-weight: 800; color: var(--text-primary); margin: 0;">إضافة لمركزي الدراسي</h3>
            <button onclick="closeHubModal()" style="background: none; border: none; color: var(--text-secondary); cursor: pointer;">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <line x1="18" y1="6" x2="6" y2="18"></line>
                    <line x1="6" y1="6" x2="18" y2="18"></line>
                </svg>
            </button>
        </div>
        <div>
            <input type="hidden" id="hub_resource_id">
            <div style="margin-bottom: 1.5rem;">
                <label style="display: block; margin-bottom: 0.5rem; color: var(--text-secondary); font-weight: 600;">الملف المحدد</label>
                <div id="hub_resource_title" style="font-weight: 700; color: var(--text-primary); font-size: 1.1rem; padding: 0.75rem; background: #f8fafc; border-radius: 8px;"></div>
            </div>
            <div style="margin-bottom: 2rem;">
                <label style="display: block; margin-bottom: 0.5rem; color: var(--text-secondary); font-weight: 600;">ملاحظة (اختياري)</label>
                <textarea id="hub_note" rows="3" placeholder="أضف ملاحظة تذكيرية لهذا الملف..." 
                    style="width: 100%; border: 1px solid #f1f5f9; background: #f8fafc; border-radius: 12px; padding: 1rem; outline: none; font-family: inherit; font-size: 0.95rem;"></textarea>
            </div>
            <div style="display: flex; gap: 1rem; justify-content: flex-end;">
                <button type="button" onclick="closeHubModal()" style="background: #f1f5f9; color: var(--text-secondary); border: none; padding: 0.75rem 1.5rem; border-radius: 8px; font-weight: 700; cursor: pointer; font-family: inherit;">إلغاء</button>
                <button onclick="submitAddToHub()" style="background: var(--primary-color); color: white; border: none; padding: 0.75rem 1.5rem; border-radius: 8px; font-weight: 700; cursor: pointer; font-family: inherit;">تأكيد الإضافة</button>
            </div>
        </div>
    </div>
</div>
@endif

    <!-- Details Modal -->
    <div x-show="showDetails" x-cloak x-transition.opacity 
        style="position: fixed; inset: 0; background: rgba(0,0,0,0.6); z-index: 2000; display: flex; align-items: center; justify-content: center; backdrop-filter: blur(8px); padding: 1.5rem; width: 100vw; height: 100vh;">
        
        <div @click.away='closeDetails()' 
            style="background: white; width: 100%; max-width: 700px; border-radius: 24px; overflow: hidden; box-shadow: 0 25px 50px -12px rgba(0,0,0,0.25); animation: zoomIn 0.3s ease-out; margin: auto;">
            
            <!-- Modal Header -->
            <div style="background: linear-gradient(135deg, #1e1b4b 0%, #1e40af 100%); padding: 1.5rem 2rem; display: flex; justify-content: space-between; align-items: center;">
                <div style="display: flex; align-items: center; gap: 1rem;">
                    <div style="width: 50px; height: 50px; background: rgba(255,255,255,0.15); border-radius: 14px; display: flex; align-items: center; justify-content: center; color: white;">
                        <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M13 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9z"></path>
                            <polyline points="13 2 13 9 20 9"></polyline>
                        </svg>
                    </div>
                    <div>
                        <h3 style="color: white; font-weight: 800; margin: 0; font-size: 1.25rem;" x-text="resDetail.title"></h3>
                        <div style="display: flex; align-items: center; gap: 0.5rem; margin-top: 0.25rem;">
                             <span style="background: rgba(255,255,255,0.2); color: white; padding: 0.1rem 0.6rem; border-radius: 6px; font-size: 0.75rem; font-weight: 700;" x-text="resDetail.file_type ? resDetail.file_type.toUpperCase() : '-'"></span>
                        </div>
                    </div>
                </div>
                <button @click="closeDetails()" style="background: rgba(255,255,255,0.1); border: none; color: white; width: 36px; height: 36px; border-radius: 10px; cursor: pointer; display: flex; align-items: center; justify-content: center; transition: background 0.2s;">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
                </button>
            </div>

            <!-- Modal Body -->
            <div style="padding: 2rem; max-height: 70vh; overflow-y: auto;">
                
                <!-- Metadata Grid -->
                <div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 1.5rem; margin-bottom: 2rem;">
                    <!-- Subject -->
                    <div style="background: #f8fafc; padding: 1rem; border-radius: 14px; border: 1px solid #f1f5f9;">
                        <label style="display: block; font-size: 0.75rem; color: #64748b; font-weight: 700; margin-bottom: 0.25rem;">المادة / المقرر</label>
                        <div style="font-weight: 800; color: #1e293b;" x-text="resDetail.subject ? resDetail.subject.name : '-'"></div>
                    </div>
                    
                    <!-- Semester Info -->
                    <div style="background: #f8fafc; padding: 1rem; border-radius: 14px; border: 1px solid #f1f5f9;">
                        <label style="display: block; font-size: 0.75rem; color: #64748b; font-weight: 700; margin-bottom: 0.25rem;">الفصل / السستم</label>
                        <div style="font-weight: 800; color: #1e293b;" x-text="resDetail.semester_info || 'غير مسجل'"></div>
                    </div>

                    <!-- Lecturer Name -->
                    <div style="background: #f8fafc; padding: 1rem; border-radius: 14px; border: 1px solid #f1f5f9;">
                        <label style="display: block; font-size: 0.75rem; color: #64748b; font-weight: 700; margin-bottom: 0.25rem;">الدكتور مقدم المحاضرة</label>
                        <div style="font-weight: 800; color: #1e293b;" x-text="resDetail.lecturer_name || 'غير مسجل'"></div>
                    </div>

                    <!-- Unit Coordinator -->
                    <div style="background: #f8fafc; padding: 1rem; border-radius: 14px; border: 1px solid #f1f5f9;">
                        <label style="display: block; font-size: 0.75rem; color: #64748b; font-weight: 700; margin-bottom: 0.25rem;">منسق الوحدة</label>
                        <div style="font-weight: 800; color: #1e293b;" x-text="resDetail.unit_coordinator || 'غير مسجل'"></div>
                    </div>

                    <!-- Clinical Unit -->
                    <div style="background: #f8fafc; padding: 1rem; border-radius: 14px; border: 1px solid #f1f5f9;">
                        <label style="display: block; font-size: 0.75rem; color: #64748b; font-weight: 700; margin-bottom: 0.25rem;">الوحدة السريرية</label>
                        <div style="font-weight: 800; color: #1e293b;" x-text="resDetail.clinical_unit || 'غير مسجل'"></div>
                    </div>

                    <!-- Upload Date -->
                    <div style="background: #f8fafc; padding: 1rem; border-radius: 14px; border: 1px solid #f1f5f9;">
                        <label style="display: block; font-size: 0.75rem; color: #64748b; font-weight: 700; margin-bottom: 0.25rem;">تاريخ الرفع</label>
                        <div style="font-weight: 800; color: #1e293b;" x-text="formatDate(resDetail.created_at)"></div>
                    </div>
                </div>

                <!-- Description Section -->
                <div style="margin-bottom: 2rem;">
                    <label style="display: block; font-size: 0.85rem; color: #64748b; font-weight: 700; margin-bottom: 0.75rem; display: flex; align-items: center; gap: 0.5rem;">
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"></path></svg>
                        ملاحظات إضافية
                    </label>
                    <div style="background: #fff; padding: 1.25rem; border-radius: 14px; border: 2px dashed #e2e8f0; color: #475569; font-weight: 500; font-size: 0.95rem; line-height: 1.6;" 
                        x-text="resDetail.description || 'لا توجد ملاحظات إضافية لهذا الملف.'"></div>
                </div>

                <!-- Uploader Info -->
                <div style="background: #f1f5f9; padding: 1.25rem; border-radius: 18px; display: flex; align-items: center; gap: 1rem;">
                    <div style="width: 50px; height: 50px; background: linear-gradient(135deg, #4f46e5, #7c3aed); border-radius: 50%; display: flex; align-items: center; justify-content: center; color: white; font-weight: 800; font-size: 1.25rem;">
                        <span x-text="resDetail.uploader ? resDetail.uploader.name.charAt(0) : '?'"></span>
                    </div>
                    <div>
                        <label style="display: block; font-size: 0.7rem; color: #64748b; font-weight: 700; margin-bottom: 0.1rem;">تم الرفع بواسطة</label>
                        <div style="display: flex; align-items: center; gap: 0.75rem;">
                            <span style="font-weight: 800; color: #1e293b;" x-text="resDetail.uploader ? resDetail.uploader.name : '-'"></span>
                            <div style="padding: 0.15rem 0.6rem; border-radius: 6px; font-size: 0.7rem; font-weight: 800; background: white; border: 1px solid #e2e8f0; color: #4f46e5;" 
                                x-text="resDetail.uploader ? (resDetail.uploader.role === 'doctor' ? 'دكتور' : (resDetail.uploader.role === 'delegate' ? 'مندوب' : 'طالب')) : '-'"></div>
                        </div>
                    </div>
                </div>

            </div>

            <!-- Modal Footer - Actions -->
            <div style="padding: 1.5rem 2rem; background: #fafbfc; border-top: 1px solid #f1f5f9; display: flex; gap: 1rem; justify-content: flex-end;">
                
                @if(auth()->user()->hasRole(\App\Enums\UserRole::STUDENT))
                <button @click="addToHub(resDetail.id, resDetail.title); closeDetails();"
                    style="padding: 0.75rem 1.5rem; background: white; border: 2px solid #e2e8f0; color: #1e293b; border-radius: 12px; font-weight: 700; cursor: pointer; display: flex; align-items: center; gap: 0.5rem; transition: all 0.2s;">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="5" x2="12" y2="19"></line><line x1="5" y1="12" x2="19" y2="12"></line></svg>
                    أضف لمركزي
                </button>
                @endif

                @if(auth()->user()->hasRole(\App\Enums\UserRole::DELEGATE))
                <button @click="openImportModal(resDetail.id, resDetail.title); closeDetails();"
                    style="padding: 0.75rem 1.5rem; background: #ecfeff; border: 2px solid #a5f3fc; color: #0891b2; border-radius: 12px; font-weight: 700; cursor: pointer; display: flex; align-items: center; gap: 0.5rem; transition: all 0.2s;">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 12v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8"></path><polyline points="16 6 12 2 8 6"></polyline><line x1="12" y1="2" x2="12" y2="15"></line></svg>
                    إدراج للمقرر
                </button>
                @endif

                <a :href="`/storage/${resDetail.file_path}`" target="_blank"
                    style="padding: 0.75rem 1.5rem; background: #4f46e5; color: white; border-radius: 12px; font-weight: 700; text-decoration: none; display: flex; align-items: center; gap: 0.5rem; box-shadow: 0 4px 12px rgba(79, 70, 229, 0.25);">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path><polyline points="7 10 12 15 17 10"></polyline><line x1="12" y1="15" x2="12" y2="3"></line></svg>
                    تحميل الآن
                </a>
            </div>
        </div>
    </div>
</div>

<style>
    .lib-row-hover:hover {
        background: #f8fafc;
    }

    .pagination {
        justify-content: center;
        gap: 6px;
    }

    .page-item.active .page-link {
        background-color: var(--primary-color);
        border-color: var(--primary-color);
        color: white;
        box-shadow: 0 4px 6px -1px rgba(79, 70, 229, 0.2);
    }

    .page-link {
        color: var(--text-primary);
        border-radius: 10px;
        border: 1px solid #e2e8f0;
        width: 40px;
        height: 40px;
        display: flex;
        align-items: center;
        justify-content: center;
        padding: 0;
        font-weight: 600;
        transition: all 0.2s;
    }

    .page-link:hover {
        background: #f8fafc;
        color: var(--primary-color);
        border-color: #cbd5e1;
    }

    @keyframes zoomIn {
        from {
            opacity: 0;
            transform: scale(0.95);
        }

        to {
            opacity: 1;
            transform: scale(1);
        }
    }

    @keyframes slideUp {
        from {
            opacity: 0;
            transform: translateY(20px);
        }

        to {
            opacity: 1;
            transform: translateY(0);
        }
    }
</style>

<script>
    function openImportModal(id, title) {
        document.getElementById('import_resource_id').value = id;
        document.getElementById('import_resource_title').textContent = title;
        document.getElementById('importModal').style.display = 'flex';
    }

    function closeImportModal() {
        document.getElementById('importModal').style.display = 'none';
    }

    function addToHub(id, title) {
        document.getElementById('hub_resource_id').value = id;
        document.getElementById('hub_resource_title').textContent = title;
        document.getElementById('hub_note').value = '';
        document.getElementById('addToHubModal').style.display = 'flex';
    }

    function closeHubModal() {
        document.getElementById('addToHubModal').style.display = 'none';
    }

    function submitAddToHub() {
        const id = document.getElementById('hub_resource_id').value;
        const title = document.getElementById('hub_resource_title').textContent;
        const note = document.getElementById('hub_note').value;
        fetch('{{ route("student.schedule.store") }}', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-TOKEN': '{{ csrf_token() }}',
                    'Accept': 'application/json'
                },
                body: JSON.stringify({
                    referenceable_type: 'resource',
                    referenceable_id: parseInt(id),
                    title: title,
                    note: note,
                    item_type: 'resource'
                })
            })
            .then(res => res.json())
            .then(data => {
                closeHubModal();
                showToast(data.success, data.message || 'حدث خطأ ما');
            })
            .catch(() => showToast(false, 'حدث خطأ أثناء الاتصال بالخادم'));
    }

    function showToast(success, message) {
        let t = document.createElement('div');
        t.innerHTML = '<div style="position:fixed;top:2rem;left:50%;transform:translateX(-50%);background:' + (success ? '#10b981' : '#ef4444') + ';color:white;padding:1rem 2rem;border-radius:12px;font-weight:700;z-index:9999;box-shadow:0 10px 15px -3px rgba(0,0,0,0.1);animation:slideUp 0.3s ease-out;">' + (success ? '✅ ' : '⚠️ ') + message + '</div>';
        document.body.appendChild(t);
        setTimeout(() => t.remove(), 3000);
    }

    document.querySelectorAll('#importModal, #addToHubModal, #uploadModal').forEach(m => {
        m.addEventListener('click', function(e) {
            if (e.target === this) this.style.display = 'none';
        });
    });
</script>
</div> <!-- Close root x-data container -->
@endsection
