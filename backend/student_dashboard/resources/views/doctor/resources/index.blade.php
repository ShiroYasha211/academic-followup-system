@extends('layouts.doctor')

@section('title', 'المصادر التعليمية')

@section('content')

<!-- Page Header -->
<div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 2rem; flex-wrap: wrap; gap: 1rem;">
    <div>
        <h1 style="font-size: 1.8rem; font-weight: 800; color: var(--text-primary); margin-bottom: 0.5rem; display: flex; align-items: center; gap: 0.75rem;">
            <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="color: var(--primary-color);">
                <path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"></path>
            </svg>
            إدارة المصادر التعليمية
        </h1>
        <p style="color: var(--text-secondary); margin: 0; font-size: 1rem;">أضف وادر ملفات المحاضرات والمراجع لموادك الدراسية</p>
    </div>
    
    <a href="{{ route('doctor.resources.create') }}" class="btn" style="background: linear-gradient(135deg, var(--primary-color) 0%, #4338ca 100%); color: white; padding: 0.75rem 1.5rem; border-radius: 12px; font-weight: 700; display: flex; align-items: center; gap: 0.6rem; text-decoration: none; box-shadow: 0 4px 12px rgba(79, 70, 229, 0.3); transition: transform 0.2s;">
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
            <line x1="12" y1="5" x2="12" y2="19"></line>
            <line x1="5" y1="12" x2="19" y2="12"></line>
        </svg>
        رفع ملف جديد
    </a>
</div>

<!-- Stats Overview -->
<div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 1.5rem; margin-bottom: 2.5rem;">
    <!-- My Uploads -->
    <div class="card border-0 shadow-sm" style="padding: 1.5rem; display: flex; align-items: center; gap: 1.5rem; background: white; border-radius: 20px;">
        <div style="width: 64px; height: 64px; border-radius: 16px; background: rgba(59, 130, 246, 0.1); display: flex; align-items: center; justify-content: center; color: #3b82f6;">
            <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                <polyline points="17 8 12 3 7 8"></polyline>
                <line x1="12" y1="3" x2="12" y2="15"></line>
            </svg>
        </div>
        <div>
            <div style="font-size: 0.9rem; color: var(--text-secondary); font-weight: 600; margin-bottom: 0.25rem;">ملفاتي المرفوعة</div>
            <div style="font-size: 1.75rem; font-weight: 800; color: var(--text-primary); line-height: 1;">{{ $stats['my_uploads'] }}</div>
        </div>
    </div>

    <!-- Recent Uploads -->
    <div class="card border-0 shadow-sm" style="padding: 1.5rem; display: flex; align-items: center; gap: 1.5rem; background: white; border-radius: 20px;">
        <div style="width: 64px; height: 64px; border-radius: 16px; background: rgba(16, 185, 129, 0.1); display: flex; align-items: center; justify-content: center; color: #10b981;">
            <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <circle cx="12" cy="12" r="10"></circle>
                <polyline points="12 6 12 12 16 14"></polyline>
            </svg>
        </div>
        <div>
            <div style="font-size: 0.9rem; color: var(--text-secondary); font-weight: 600; margin-bottom: 0.25rem;">إضافات الأسبوع</div>
            <div style="font-size: 1.75rem; font-weight: 800; color: var(--text-primary); line-height: 1;">{{ $stats['recent_week'] }}</div>
        </div>
    </div>

    <!-- Assigned Subjects -->
    <div class="card border-0 shadow-sm" style="padding: 1.5rem; display: flex; align-items: center; gap: 1.5rem; background: white; border-radius: 20px;">
        <div style="width: 64px; height: 64px; border-radius: 16px; background: rgba(245, 158, 11, 0.1); display: flex; align-items: center; justify-content: center; color: #f59e0b;">
            <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path>
                <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path>
            </svg>
        </div>
        <div>
            <div style="font-size: 0.9rem; color: var(--text-secondary); font-weight: 600; margin-bottom: 0.25rem;">المواد المسندة</div>
            <div style="font-size: 1.75rem; font-weight: 800; color: var(--text-primary); line-height: 1;">{{ $subjects->count() }}</div>
        </div>
    </div>
</div>

<!-- Filters -->
<div class="card border-0 shadow-sm mb-4" style="background: white; border-radius: 20px; padding: 1rem;">
    <form action="{{ route('doctor.resources.index') }}" method="GET" style="display: flex; gap: 1rem; align-items: center; flex-wrap: wrap;">
        <!-- Preserve View Mode -->
        @if(request('view'))
        <input type="hidden" name="view" value="{{ request('view') }}">
        @endif

        <div style="flex: 1; min-width: 250px; position: relative;">
            <input type="text" name="search" value="{{ request('search') }}" placeholder="ابحث باسم الملف..." 
                style="width: 100%; height: 50px; background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 12px; padding: 0 1rem 0 3rem; font-weight: 600;">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2" style="position: absolute; left: 1rem; top: 50%; transform: translateY(-50%);">
                <circle cx="11" cy="11" r="8"></circle>
                <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
            </svg>
        </div>

        <select name="subject_id" style="flex: 0.8; height: 50px; background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 12px; padding: 0 1rem; font-weight: 600; cursor: pointer;">
            <option value="">جميع المواد</option>
            @foreach($subjects as $subject)
            <option value="{{ $subject->id }}" {{ request('subject_id') == $subject->id ? 'selected' : '' }}>{{ $subject->name }}</option>
            @endforeach
        </select>

        <select name="category" style="flex: 0.6; height: 50px; background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 12px; padding: 0 1rem; font-weight: 600; cursor: pointer;">
            <option value="">جميع الأنواع</option>
            <option value="lectures" {{ request('category') == 'lectures' ? 'selected' : '' }}>محاضرات</option>
            <option value="references" {{ request('category') == 'references' ? 'selected' : '' }}>مراجع</option>
            <option value="summaries" {{ request('category') == 'summaries' ? 'selected' : '' }}>ملخصات</option>
            <option value="exams" {{ request('category') == 'exams' ? 'selected' : '' }}>اختبارات</option>
        </select>

        <button type="submit" class="btn" style="height: 50px; padding: 0 1.5rem; background: var(--primary-color); color: white; border-radius: 12px; font-weight: 700; border: none;">
            تصفية
        </button>

        @if(request()->anyFilled(['search', 'subject_id', 'category']))
        <a href="{{ route('doctor.resources.index') }}" class="btn" style="height: 50px; width: 50px; display: flex; align-items: center; justify-content: center; background: #fee2e2; color: #ef4444; border-radius: 12px; text-decoration: none;">
            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                <line x1="18" y1="6" x2="6" y2="18"></line>
                <line x1="6" y1="6" x2="18" y2="18"></line>
            </svg>
        </a>
        @endif
    </form>
</div>

<!-- Main Content Card -->
<div class="card border-0 shadow-sm" style="background: white; border-radius: 20px; overflow: hidden;">
    <div class="card-header bg-white border-bottom py-3 px-4 d-flex justify-content-between align-items-center flex-wrap gap-2">
        <h5 class="fw-bold m-0 d-flex align-items-center gap-2" style="color: var(--text-primary);">
            <svg xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="text-primary">
                <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                <polyline points="14 2 14 8 20 8"></polyline>
            </svg>
            قائمة الملفات
        </h5>

        <div style="display: flex; align-items: center; gap: 0.75rem;">
            <!-- View Mode Switch -->
            <div style="display: flex; background: #f1f5f9; border-radius: 10px; padding: 3px;">
                <a href="{{ route('doctor.resources.index', array_merge(request()->query(), ['view' => 'table'])) }}" 
                   style="padding: 0.4rem 1rem; border-radius: 8px; text-decoration: none; font-size: 0.85rem; font-weight: 600; {{ ($viewMode ?? 'table') == 'table' ? 'background: white; color: var(--primary-color); box-shadow: 0 1px 3px rgba(0,0,0,0.1);' : 'color: #64748b;' }}">
                   جدول
                </a>
                <a href="{{ route('doctor.resources.index', array_merge(request()->query(), ['view' => 'grouped'])) }}" 
                   style="padding: 0.4rem 1rem; border-radius: 8px; text-decoration: none; font-size: 0.85rem; font-weight: 600; {{ ($viewMode ?? 'table') == 'grouped' ? 'background: white; color: var(--primary-color); box-shadow: 0 1px 3px rgba(0,0,0,0.1);' : 'color: #64748b;' }}">
                   بواسطة المادة
                </a>
            </div>
            
            <span class="badge bg-light text-dark border px-3 py-2 rounded-pill fw-bold">{{ $resources->total() }} ملف</span>
        </div>
    </div>

    @if(($viewMode ?? 'table') == 'table')
    <!-- Table View -->
    <div class="table-responsive">
        <table class="table table-hover align-middle mb-0">
            <thead class="bg-light text-muted small text-uppercase">
                <tr>
                    <th style="padding: 1.25rem 1.5rem; width: 40%;">اسم الملف</th>
                    <th style="padding: 1.25rem 1.5rem;">المادة الدراسية</th>
                    <th style="padding: 1.25rem 1.5rem;">التصنيف</th>
                    <th style="padding: 1.25rem 1.5rem;">تاريخ الرفع</th>
                    <th style="padding: 1.25rem 1.5rem; text-align: left;">العمليات</th>
                </tr>
            </thead>
            <tbody>
                @forelse($resources as $resource)
                <tr>
                    <td style="padding: 1rem 1.5rem;">
                        <div class="d-flex align-items-center">
                            @php
                            $ext = strtolower($resource->file_type);
                            $iconColor = '#64748b'; $bgColor = '#f1f5f9';
                            if($ext == 'pdf') { $iconColor = '#ef4444'; $bgColor = '#fef2f2'; }
                            elseif(in_array($ext, ['ppt','pptx'])) { $iconColor = '#f59e0b'; $bgColor = '#fffbeb'; }
                            elseif(in_array($ext, ['doc','docx'])) { $iconColor = '#3b82f6'; $bgColor = '#eff6ff'; }
                            @endphp
                            <div style="width: 44px; height: 44px; background: {{ $bgColor }}; color: {{ $iconColor }}; border-radius: 12px; display: flex; align-items: center; justify-content: center; margin-left: 1rem; flex-shrink: 0;">
                                <svg xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <path d="M13 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9z"></path>
                                    <polyline points="13 2 13 9 20 9"></polyline>
                                </svg>
                            </div>
                            <div>
                                <div class="fw-bold text-dark" style="font-size: 0.95rem;">{{ $resource->title }}</div>
                                <div style="display: flex; align-items: center; gap: 0.5rem; flex-wrap: wrap;">
                                    <span class="small text-muted fw-bold">{{ strtoupper($resource->file_type) }}</span>
                                    <span style="width: 4px; height: 4px; border-radius: 50%; background: #cbd5e1;"></span>
                                    <span class="small text-muted" style="font-weight: 600;">{{ $resource->uploader->name ?? 'غير معروف' }}</span>
                                    @if($resource->uploader && $resource->uploader->role->value === 'doctor')
                                    <span style="display: inline-flex; align-items: center; gap: 0.25rem; background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%); color: white; padding: 0.1rem 0.5rem; border-radius: 50px; font-size: 0.7rem; font-weight: 800; box-shadow: 0 2px 6px rgba(245, 158, 11, 0.2);">
                                        <svg xmlns="http://www.w3.org/2000/svg" width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M22 10v6M2 10v6M12 15a4 4 0 1 0 0-8 4 4 0 0 0 0 8z"/><path d="M6 15v-2a6 6 0 1 1 12 0v2"/></svg>
                                        عضو هيئة تدريس
                                    </span>
                                    @endif
                                </div>
                            </div>
                        </div>
                    </td>
                    <td style="padding: 1rem 1.5rem;">
                        <span class="badge bg-white text-dark border fw-bold py-2 px-3 rounded-pill">
                            {{ $resource->subject->name }}
                        </span>
                    </td>
                    <td style="padding: 1rem 1.5rem;">
                        @switch($resource->category)
                            @case('lectures') <span class="badge py-2 px-3" style="background: rgba(59,130,246,0.1); color: #3b82f6;">محاضرات</span> @break
                            @case('references') <span class="badge py-2 px-3" style="background: rgba(245,158,11,0.1); color: #f59e0b;">مراجع</span> @break
                            @case('summaries') <span class="badge py-2 px-3" style="background: rgba(16,185,129,0.1); color: #10b981;">ملخصات</span> @break
                            @case('exams') <span class="badge py-2 px-3" style="background: rgba(239,68,68,0.1); color: #ef4444;">اختبارات</span> @break
                            @default <span class="badge py-2 px-3 bg-light text-muted">أخرى</span>
                        @endswitch
                    </td>
                    <td style="padding: 1rem 1.5rem;" class="text-muted small fw-bold">
                        {{ $resource->created_at->format('Y/m/d') }}
                    </td>
                    <td style="padding: 1rem 1.5rem; text-align: left;">
                        <div style="display: flex; gap: 0.5rem; justify-content: flex-end;">
                            <a href="{{ Storage::url($resource->file_path) }}" target="_blank" class="btn-icon" title="تحميل">
                                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                                    <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4M7 10l5 5 5-5M12 15V3" stroke-linecap="round" stroke-linejoin="round"/>
                                </svg>
                            </a>
                            <a href="{{ route('doctor.resources.edit', $resource) }}" class="btn-icon" title="تعديل">
                                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                                    <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z" stroke-linecap="round" stroke-linejoin="round"/>
                                </svg>
                            </a>
                            <form action="{{ route('doctor.resources.destroy', $resource) }}" method="POST" onsubmit="return confirm('هل أنت متأكد من حذف هذا الملف؟')">
                                @csrf @method('DELETE')
                                <button type="submit" class="btn-icon btn-icon-danger" title="حذف">
                                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                                        <path d="M3 6h18M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2M10 11v6M14 11v6" stroke-linecap="round" stroke-linejoin="round"/>
                                    </svg>
                                </button>
                            </form>
                        </div>
                    </td>
                </tr>
                @empty
                <tr>
                    <td colspan="5" class="text-center py-5">
                        <div style="width: 80px; height: 80px; background: #f8fafc; border-radius: 50%; display: flex; align-items: center; justify-content: center; margin: 0 auto 1.5rem;">
                            <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#cbd5e1" stroke-width="1.5">
                                <path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"></path>
                            </svg>
                        </div>
                        <h5 class="fw-bold text-dark">لا توجد ملفات مرفوعة</h5>
                        <p class="text-muted">ابدأ برفع محاضراتك ومراجعك الآن</p>
                    </td>
                </tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <!-- Pagination -->
    @if($resources->hasPages())
    <div class="card-footer bg-white py-4 d-flex justify-content-center">
        {{ $resources->withQueryString()->links('pagination::bootstrap-5') }}
    </div>
    @endif

    @else
    <!-- Grouped View -->
    <div style="padding: 1.5rem;">
        @forelse($groupedResources as $subjectId => $subjectResources)
        @php $subject = $subjectResources->first()->subject; @endphp
        <div style="margin-bottom: 1.5rem; border: 1px solid #e2e8f0; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.02);">
            <div style="background: #f8fafc; padding: 1rem 1.5rem; display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid #e2e8f0;">
                <h6 class="m-0 fw-bold d-flex align-items-center gap-2">
                    <span style="width: 8px; height: 8px; border-radius: 50%; background: var(--primary-color);"></span>
                    {{ $subject->name }}
                </h6>
                <span class="badge bg-primary rounded-pill">{{ $subjectResources->count() }} ملف</span>
            </div>
            <div style="padding: 0.5rem;">
                @foreach($subjectResources as $resource)
                <div class="grouped-item" style="display: flex; align-items: center; justify-content: space-between; padding: 0.75rem 1rem; border-radius: 10px;">
                    <div style="display: flex; align-items: center; gap: 0.75rem;">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#64748b" stroke-width="2"><path d="M13 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9z"/><polyline points="13 2 13 9 20 9"/></svg>
                        <div>
                            <div style="font-weight: 600; font-size: 0.9rem; display: flex; align-items: center; gap: 0.5rem;">
                                {{ $resource->title }}
                                @if($resource->uploader && $resource->uploader->role->value === 'doctor')
                                <span title="عضو هيئة تدريس" style="color: #f59e0b; display: flex;">
                                    <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M22 10v6M2 10v6M12 15a4 4 0 1 0 0-8 4 4 0 0 0 0 8z"/><path d="M6 15v-2a6 6 0 1 1 12 0v2"/></svg>
                                </span>
                                @endif
                            </div>
                            <div style="font-size: 0.75rem; color: #94a3b8;">{{ strtoupper($resource->file_type) }} • {{ $resource->uploader->name ?? 'غير معروف' }} • {{ $resource->created_at->format('Y/m/d') }}</div>
                        </div>
                    </div>
                    <div style="display: flex; gap: 0.25rem;">
                        <a href="{{ route('doctor.resources.edit', $resource) }}" class="btn-icon btn-sm">
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
                        </a>
                        <form action="{{ route('doctor.resources.destroy', $resource) }}" method="POST" onsubmit="return confirm('هل أنت متأكد؟')">
                            @csrf @method('DELETE')
                            <button type="submit" class="btn-icon btn-sm btn-icon-danger">
                                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M3 6h18M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2M10 11v6M14 11v6"/></svg>
                            </button>
                        </form>
                    </div>
                </div>
                @endforeach
            </div>
        </div>
        @empty
        <div class="text-center py-5">
            <p class="text-muted">لا توجد ملفات مرفوعة حالياً.</p>
        </div>
        @endforelse
    </div>
    @endif
</div>

<style>
    .btn-icon {
        width: 36px;
        height: 36px;
        border-radius: 10px;
        display: flex;
        align-items: center;
        justify-content: center;
        background: #f1f5f9;
        color: #64748b;
        border: none;
        cursor: pointer;
        transition: all 0.2s;
        text-decoration: none;
    }
    .btn-icon:hover { background: #e2e8f0; color: #3b82f6; }
    .btn-icon-danger:hover { background: #fef2f2; color: #ef4444; }
    
    .btn-sm { width: 30px; height: 30px; }
    
    .grouped-item:hover { background: #f8fafc; }

    .pagination { justify-content: center; gap: 0.5rem; }
    .page-link { border-radius: 10px; padding: 0.5rem 1rem; color: #64748b; border: 1px solid #e2e8f0; }
    .page-item.active .page-link { background: var(--primary-color); border-color: var(--primary-color); }
</style>

@endsection
