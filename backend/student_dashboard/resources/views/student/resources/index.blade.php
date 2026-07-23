@extends('layouts.student')

@section('title', 'مصادر المقرر')

@section('content')

<!-- Page Header -->
<div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 2rem;">
    <div>
        <h1 style="font-size: 1.8rem; font-weight: 800; color: var(--text-primary); margin-bottom: 0.5rem; display: flex; align-items: center; gap: 0.75rem;">
            <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="color: var(--primary-color);">
                <path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"></path>
            </svg>
            مصادر المقرر
        </h1>
        <p style="color: var(--text-secondary); margin: 0; font-size: 1rem;">تصفح وحمل كافة المحاضرات والمراجع والمستندات الدراسية</p>
    </div>
</div>

<!-- Stats Overview -->
<div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 1.5rem; margin-bottom: 2.5rem;">
    <!-- Total Files -->
    <div class="card border-0 shadow-sm" style="padding: 1.5rem; display: flex; align-items: center; gap: 1.5rem; background: white; border-radius: 20px; transition: transform 0.2s;">
        <div style="width: 64px; height: 64px; border-radius: 16px; background: rgba(59, 130, 246, 0.1); display: flex; align-items: center; justify-content: center; color: #3b82f6;">
            <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"></path>
            </svg>
        </div>
        <div>
            <div style="font-size: 0.9rem; color: var(--text-secondary); font-weight: 600; margin-bottom: 0.25rem;">إجمالي الملفات</div>
            <div style="font-size: 1.75rem; font-weight: 800; color: var(--text-primary); line-height: 1;">{{ $stats['total_files'] }}</div>
        </div>
    </div>

    <!-- Recent Activity -->
    <div class="card border-0 shadow-sm" style="padding: 1.5rem; display: flex; align-items: center; gap: 1.5rem; background: white; border-radius: 20px; transition: transform 0.2s;">
        <div style="width: 64px; height: 64px; border-radius: 16px; background: rgba(245, 158, 11, 0.1); display: flex; align-items: center; justify-content: center; color: #f59e0b;">
            <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <circle cx="12" cy="12" r="10"></circle>
                <polyline points="12 6 12 12 16 14"></polyline>
            </svg>
        </div>
        <div>
            <div style="font-size: 0.9rem; color: var(--text-secondary); font-weight: 600; margin-bottom: 0.25rem;">إضافات الأسبوع</div>
            <div style="font-size: 1.75rem; font-weight: 800; color: var(--text-primary); line-height: 1;">{{ $stats['recent_week'] }}</div>
        </div>
    </div>

    <!-- Subjects Count -->
    <div class="card border-0 shadow-sm" style="padding: 1.5rem; display: flex; align-items: center; gap: 1.5rem; background: white; border-radius: 20px; transition: transform 0.2s;">
        <div style="width: 64px; height: 64px; border-radius: 16px; background: rgba(16, 185, 129, 0.1); display: flex; align-items: center; justify-content: center; color: #10b981;">
            <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
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

<!-- Filters & Search (Single Line - Split Buttons) - Same as Delegate -->
<div class="card border-0 shadow-sm mb-4" style="background: white; border-radius: 20px; padding: 0.75rem;">
    <form action="{{ route('student.resources.index') }}" method="GET" style="display: flex; align-items: center; gap: 0.75rem; width: 100%;">
        <!-- View Mode Preservation -->
        @if(request('view'))
        <input type="hidden" name="view" value="{{ request('view') }}">
        @endif

        <!-- Search Input -->
        <div style="flex: 2; position: relative;">
            <div style="position: absolute; right: 1.2rem; top: 50%; transform: translateY(-50%); color: #94a3b8; pointer-events: none;">
                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <circle cx="11" cy="11" r="8"></circle>
                    <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
                </svg>
            </div>
            <input type="text" name="search" value="{{ request('search') }}"
                placeholder="ابحث باسم الملف..."
                style="width: 100%; height: 50px; background: #f8fafc; border: 1px solid #f1f5f9; border-radius: 12px; padding-right: 3rem; padding-left: 1rem; font-size: 0.95rem; font-weight: 600; outline: none; transition: all 0.2s;"
                onfocus="this.style.background='white'; this.style.borderColor='var(--primary-color)';"
                onblur="if(!this.value) { this.style.background='#f8fafc'; this.style.borderColor='#f1f5f9'; }">
        </div>

        <!-- Subject Filter -->
        <div style="flex: 1.5; min-width: 200px;">
            <div style="position: relative;">
                <div style="position: absolute; right: 1rem; top: 50%; transform: translateY(-50%); color: #94a3b8; pointer-events: none;">
                    <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path>
                        <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path>
                    </svg>
                </div>
                <select name="subject_id"
                    style="width: 100%; height: 50px; background: #f8fafc; border: 1px solid #f1f5f9; border-radius: 12px; padding-right: 3rem; padding-left: 1rem; font-size: 0.95rem; font-weight: 600; cursor: pointer; appearance: none; -webkit-appearance: none; outline: none; transition: all 0.2s;"
                    onfocus="this.style.background='white'; this.style.borderColor='var(--primary-color)';"
                    onblur="this.style.background='#f8fafc'; this.style.borderColor='#f1f5f9';">
                    <option value="">جميع المواد</option>
                    @foreach($subjects as $subject)
                    <option value="{{ $subject->id }}" {{ request('subject_id') == $subject->id ? 'selected' : '' }}>{{ $subject->name }}</option>
                    @endforeach
                </select>
                <!-- Custom Arrow -->
                <div style="position: absolute; left: 1rem; top: 50%; transform: translateY(-50%); color: #94a3b8; pointer-events: none;">
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <polyline points="6 9 12 15 18 9"></polyline>
                    </svg>
                </div>
            </div>
        </div>

        <!-- Category Filter -->
        <div style="flex: 1.5; min-width: 180px;">
            <div style="position: relative;">
                <div style="position: absolute; right: 1rem; top: 50%; transform: translateY(-50%); color: #94a3b8; pointer-events: none;">
                    <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <line x1="8" y1="6" x2="21" y2="6"></line>
                        <line x1="8" y1="12" x2="21" y2="12"></line>
                        <line x1="8" y1="18" x2="21" y2="18"></line>
                        <line x1="3" y1="6" x2="3.01" y2="6"></line>
                        <line x1="3" y1="12" x2="3.01" y2="12"></line>
                        <line x1="3" y1="18" x2="3.01" y2="18"></line>
                    </svg>
                </div>
                <select name="category"
                    style="width: 100%; height: 50px; background: #f8fafc; border: 1px solid #f1f5f9; border-radius: 12px; padding-right: 3rem; padding-left: 1rem; font-size: 0.95rem; font-weight: 600; cursor: pointer; appearance: none; -webkit-appearance: none; outline: none; transition: all 0.2s;"
                    onfocus="this.style.background='white'; this.style.borderColor='var(--primary-color)';"
                    onblur="this.style.background='#f8fafc'; this.style.borderColor='#f1f5f9';">
                    <option value="">جميع الأنواع</option>
                    <option value="lectures" {{ request('category') == 'lectures' ? 'selected' : '' }}>محاضرات</option>
                    <option value="references" {{ request('category') == 'references' ? 'selected' : '' }}>مراجع</option>
                    <option value="summaries" {{ request('category') == 'summaries' ? 'selected' : '' }}>ملخصات</option>
                    <option value="exams" {{ request('category') == 'exams' ? 'selected' : '' }}>اختبارات</option>
                </select>
                <!-- Custom Arrow -->
                <div style="position: absolute; left: 1rem; top: 50%; transform: translateY(-50%); color: #94a3b8; pointer-events: none;">
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <polyline points="6 9 12 15 18 9"></polyline>
                    </svg>
                </div>
            </div>
        </div>


        <!-- Scheduled Filter using a toggle-like checkbox -->
        <div style="flex: 0 0 auto;">
            <div style="display: flex; align-items: center; justify-content: center; height: 50px; background: #f8fafc; border: 1px solid #f1f5f9; border-radius: 12px; padding: 0 1rem;">
                <label style="display: flex; align-items: center; gap: 0.5rem; cursor: pointer; color: var(--text-secondary); white-space: nowrap;">
                    <input type="checkbox" name="scheduled" value="1" {{ request('scheduled') ? 'checked' : '' }} onchange="this.form.submit()" style="cursor: pointer; width: 1.1rem; height: 1.1rem;">
                    <span>المجدولة فقط</span>
                </label>
            </div>
        </div>

        <!-- Search Button -->
        <button type="submit" class="btn shadow-sm" style="height: 50px; padding: 0 1.5rem; border-radius: 12px; font-weight: 700; display: flex; align-items: center; justify-content: center; gap: 0.5rem; background: var(--primary-color); border: none; flex-shrink: 0; color: white;">
            <svg style="width: 20px; height: 20px; stroke: white; stroke-width: 2.5; fill: none;" viewBox="0 0 24 24">
                <circle cx="11" cy="11" r="7" />
                <path d="M21 21l-4.35-4.35" />
            </svg>
            <span>بحث</span>
        </button>

        @if(request()->hasAny(['search', 'subject_id', 'category']))
        <a href="{{ route('student.resources.index') }}"
            style="width: 50px; height: 50px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; text-decoration: none; border-radius: 12px; background: #fef2f2; border: 1px solid #fee2e2;"
            title="إلغاء التصفية">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
                <path d="M18 6L6 18M6 6l12 12" stroke="#ef4444" stroke-width="2.5" stroke-linecap="round" />
            </svg>
        </a>
        @endif
    </form>
</div>

<!-- View Toggle & Main Content -->
<div class="card border-0 shadow-sm" style="background: white; border-radius: 20px; overflow: hidden;">
    <div class="card-header bg-white border-bottom py-3 px-4 d-flex justify-content-between align-items-center flex-wrap gap-2">
        <h5 class="fw-bold m-0 d-flex align-items-center gap-2" style="color: var(--text-primary);">
            <svg xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="text-primary">
                <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                <polyline points="14 2 14 8 20 8"></polyline>
                <line x1="16" y1="13" x2="8" y2="13"></line>
                <line x1="16" y1="17" x2="8" y2="17"></line>
                <polyline points="10 9 9 9 8 9"></polyline>
            </svg>
            قائمة الملفات
        </h5>

        <div style="display: flex; align-items: center; gap: 0.5rem;">
            <!-- View Toggle Buttons -->
            <div style="display: flex; background: #f1f5f9; border-radius: 10px; padding: 3px;">
                <a href="{{ route('student.resources.index', array_merge(request()->except('view'), ['view' => 'table'])) }}"
                    style="padding: 0.4rem 0.75rem; border-radius: 8px; font-size: 0.85rem; font-weight: 600; text-decoration: none; display: flex; align-items: center; gap: 0.3rem; {{ ($viewMode ?? 'table') == 'table' ? 'background: white; color: var(--primary-color); box-shadow: 0 1px 3px rgba(0,0,0,0.1);' : 'color: #64748b;' }}">
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <line x1="8" y1="6" x2="21" y2="6"></line>
                        <line x1="8" y1="12" x2="21" y2="12"></line>
                        <line x1="8" y1="18" x2="21" y2="18"></line>
                        <line x1="3" y1="6" x2="3.01" y2="6"></line>
                        <line x1="3" y1="12" x2="3.01" y2="12"></line>
                        <line x1="3" y1="18" x2="3.01" y2="18"></line>
                    </svg>
                    جدول
                </a>
                <a href="{{ route('student.resources.index', array_merge(request()->except('view'), ['view' => 'grouped'])) }}"
                    style="padding: 0.4rem 0.75rem; border-radius: 8px; font-size: 0.85rem; font-weight: 600; text-decoration: none; display: flex; align-items: center; gap: 0.3rem; {{ ($viewMode ?? 'table') == 'grouped' ? 'background: white; color: var(--primary-color); box-shadow: 0 1px 3px rgba(0,0,0,0.1);' : 'color: #64748b;' }}">
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"></path>
                    </svg>
                    حسب المادة
                </a>
            </div>

            <!-- Sort Dropdown -->
            <div style="position: relative;">
                <select onchange="window.location.href=this.value"
                    style="padding: 0.4rem 2rem 0.4rem 0.75rem; border-radius: 8px; font-size: 0.85rem; font-weight: 600; border: 1px solid #e2e8f0; background: white; cursor: pointer; appearance: none; color: #64748b;">
                    <option value="{{ route('student.resources.index', array_merge(request()->except('sort'), ['sort' => 'newest'])) }}" {{ ($sort ?? 'newest') == 'newest' ? 'selected' : '' }}>الأحدث</option>
                    <option value="{{ route('student.resources.index', array_merge(request()->except('sort'), ['sort' => 'oldest'])) }}" {{ ($sort ?? 'newest') == 'oldest' ? 'selected' : '' }}>الأقدم</option>
                    <option value="{{ route('student.resources.index', array_merge(request()->except('sort'), ['sort' => 'subject'])) }}" {{ ($sort ?? 'newest') == 'subject' ? 'selected' : '' }}>حسب المادة</option>
                </select>
                <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#64748b" stroke-width="2" style="position: absolute; left: 8px; top: 50%; transform: translateY(-50%); pointer-events: none;">
                    <polyline points="6 9 12 15 18 9"></polyline>
                </svg>
            </div>

            <span class="badge bg-light text-dark border px-3 py-2 rounded-pill font-weight-bold">{{ $resources->total() }} ملف</span>
        </div>
    </div>

    @if(($viewMode ?? 'table') == 'table')
    <!-- Table View -->
    <div class="table-responsive">
        <div class="table-responsive">
<table class="table table-hover align-middle mb-0">
            <thead class="bg-light text-muted small text-uppercase" style="border-top: 1px solid #f1f5f9;">
                <tr>
                    <th style="padding: 1.25rem 1.5rem; width: 40%;">اسم الملف</th>
                    <th style="padding: 1.25rem 1.5rem;">المادة الدراسية</th>
                    <th style="padding: 1.25rem 1.5rem;">النوع</th>
                    <th style="padding: 1.25rem 1.5rem;">بواسطة</th>
                    <th style="padding: 1.25rem 1.5rem;">تاريخ الرفع</th>
                    <th style="padding: 1.25rem 1.5rem; text-align: left;">تحميل</th>
                </tr>
            </thead>
            <tbody>
                @forelse($resources as $resource)
                <tr>
                    <td style="padding: 1rem 1.5rem;">
                        <div class="d-flex align-items-center">
                            @php
                            $ext = strtolower($resource->file_type);
                            $iconColor = '#64748b';
                            $bgIcon = '#f1f5f9';
                            if(in_array($ext, ['pdf'])) { $iconColor = '#ef4444'; $bgIcon = '#fef2f2'; }
                            elseif(in_array($ext, ['ppt','pptx'])) { $iconColor = '#f59e0b'; $bgIcon = '#fffbeb'; }
                            elseif(in_array($ext, ['doc','docx'])) { $iconColor = '#3b82f6'; $bgIcon = '#eff6ff'; }
                            elseif(in_array($ext, ['xls','xlsx'])) { $iconColor = '#10b981'; $bgIcon = '#ecfdf5'; }
                            elseif(in_array($ext, ['jpg','jpeg','png'])) { $iconColor = '#06b6d4'; $bgIcon = '#ecfeff'; }
                            elseif(in_array($ext, ['zip','rar'])) { $iconColor = '#4b5563'; $bgIcon = '#f3f4f6'; }
                            @endphp
                            <div style="width: 46px; height: 46px; background: {{ $bgIcon }}; border-radius: 12px; display: flex; align-items: center; justify-content: center; margin-left: 1rem; flex-shrink: 0; color: {{ $iconColor }}; border: 1px solid rgba(0,0,0,0.03);">
                                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
                                    <path d="M13 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9z"></path>
                                    <polyline points="13 2 13 9 20 9"></polyline>
                                </svg>
                            </div>
                            <div>
                                <div class="fw-bold text-dark" style="font-size: 0.95rem;">{{ $resource->title }}</div>
                                <div class="small text-muted fw-bold" style="font-size: 0.75rem;">{{ strtoupper($resource->file_type) }}</div>
                            </div>
                        </div>
                    </td>
                    <td style="padding: 1rem 1.5rem;">
                        <span class="badge bg-white text-dark border font-weight-bold py-2 px-3 rounded-pill shadow-sm">
                            {{ $resource->subject->name }}
                        </span>
                        @if(in_array($resource->id, $scheduledResourceIds))
                        <span class="badge" style="background-color: #dbeafe; color: #1e40af; margin-right: 0.25rem;">مجدول</span>
                        @endif
                    </td>
                    <td style="padding: 1rem 1.5rem;">
                        @switch($resource->category)
                        @case('lectures')
                        <span class="badge d-inline-flex align-items-center gap-2 px-3 py-2" style="background: rgba(59, 130, 246, 0.1); color: #3b82f6;">
                            <span style="width: 6px; height: 6px; border-radius: 50%; background: currentColor;"></span> محاضرات
                        </span>
                        @break
                        @case('references')
                        <span class="badge d-inline-flex align-items-center gap-2 px-3 py-2" style="background: rgba(245, 158, 11, 0.1); color: #f59e0b;">
                            <span style="width: 6px; height: 6px; border-radius: 50%; background: currentColor;"></span> مراجع
                        </span>
                        @break
                        @case('summaries')
                        <span class="badge d-inline-flex align-items-center gap-2 px-3 py-2" style="background: rgba(16, 185, 129, 0.1); color: #10b981;">
                            <span style="width: 6px; height: 6px; border-radius: 50%; background: currentColor;"></span> ملخصات
                        </span>
                        @break
                        @case('exams')
                        <span class="badge d-inline-flex align-items-center gap-2 px-3 py-2" style="background: rgba(239, 68, 68, 0.1); color: #ef4444;">
                            <span style="width: 6px; height: 6px; border-radius: 50%; background: currentColor;"></span> اختبارات
                        </span>
                        @break
                        @default
                        <span class="badge d-inline-flex align-items-center gap-2 px-3 py-2 bg-light text-muted">
                            <span style="width: 6px; height: 6px; border-radius: 50%; background: currentColor;"></span> أخرى
                        </span>
                        @endswitch
                    </td>
                    <td style="padding: 1rem 1.5rem;">
                        <div class="d-flex align-items-center gap-2">
                            <div style="width: 24px; height: 24px; background: #e2e8f0; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 0.7rem; font-weight: bold; color: #64748b;">
                                {{ mb_substr($resource->uploader->name ?? '?', 0, 1) }}
                            </div>
                            <span class="text-dark small fw-bold">{{ $resource->uploader->name ?? '-' }}</span>
                        </div>
                    </td>
                    <td style="padding: 1rem 1.5rem;" class="text-muted small fw-bold">
                        {{ $resource->created_at->format('Y/m/d') }}
                    </td>
                    <td style="padding: 1rem 1.5rem; text-align: left;">
                        <div style="display: flex; gap: 0.5rem; justify-content: flex-end;">
                            @php $isScheduled = in_array($resource->id, $scheduledResourceIds); @endphp
                            <button onclick="openScheduleModal('App\\Models\\CourseResource', {{ $resource->id }}, '{{ $resource->title }}')"
                                style="width: 36px; height: 36px; display: inline-flex; align-items: center; justify-content: center; {{ $isScheduled ? 'background: var(--primary-color); color: white;' : 'background: white; color: var(--primary-color);' }} border: 1px solid #e2e8f0; border-radius: 10px; transition: all 0.2s; cursor: pointer;"
                                title="{{ $isScheduled ? 'مجدول' : 'إضافة لجدولي' }}">
                                <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                    <rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect>
                                    <line x1="16" y1="2" x2="16" y2="6"></line>
                                    <line x1="8" y1="2" x2="8" y2="6"></line>
                                    <line x1="3" y1="10" x2="21" y2="10"></line>
                                    <line x1="12" y1="15" x2="12" y2="15"></line>
                                </svg>
                            </button>
                            <a href="{{ Storage::url($resource->file_path) }}" target="_blank"
                                style="width: 36px; height: 36px; display: inline-flex; align-items: center; justify-content: center; background: #eff6ff; color: var(--primary-color); border-radius: 10px; transition: all 0.2s;"
                                title="تحميل الملف">
                                <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
                                    <path d="M12 3v12m0 0l-4-4m4 4l4-4M4 17v2a2 2 0 002 2h12a2 2 0 002-2v-2" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" />
                                </svg>
                            </a>
                        </div>
                    </td>
                </tr>
                @empty
                <tr>
                    <td colspan="6" class="text-center py-5">
                        <div class="mb-4">
                            <div style="width: 80px; height: 80px; background: #f8fafc; border-radius: 50%; display: flex; align-items: center; justify-content: center; margin: 0 auto;">
                                <svg xmlns="http://www.w3.org/2000/svg" width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#cbd5e1" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
                                    <path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"></path>
                                </svg>
                            </div>
                        </div>
                        <h5 class="fw-bold text-dark">لا توجد ملفات</h5>
                        <p class="text-muted mb-0">جرب البحث بكلمات مختلفة أو تغيير التصفية</p>
                    </td>
                </tr>
                @endforelse
            </tbody>
        </table>
</div>
    </div>

    <!-- Pagination -->
    @if($resources->hasPages())
    <div class="card-footer bg-white py-4 border-top-0 d-flex justify-content-center">
        {{ $resources->withQueryString()->links('pagination::bootstrap-5') }}
    </div>
    @endif

    @else
    <!-- Grouped View -->
    <div style="padding: 1.5rem;">
        @forelse($groupedResources as $subjectId => $subjectResources)
        @php $subject = $subjectResources->first()->subject; @endphp
        <div style="margin-bottom: 1.5rem; border: 1px solid #e2e8f0; border-radius: 12px; overflow: hidden;">
            <!-- Subject Header -->
            <div style="background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%); padding: 1rem 1.5rem; display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid #e2e8f0;">
                <div style="display: flex; align-items: center; gap: 0.75rem;">
                    <div style="width: 40px; height: 40px; background: var(--primary-color); border-radius: 10px; display: flex; align-items: center; justify-content: center;">
                        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2">
                            <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path>
                            <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path>
                        </svg>
                    </div>
                    <div>
                        <h4 style="font-weight: 700; color: var(--text-primary); margin: 0; font-size: 1.1rem;">{{ $subject->name }}</h4>
                        <span style="font-size: 0.8rem; color: var(--text-secondary);">{{ $subject->code }}</span>
                    </div>
                </div>
                <span style="background: var(--primary-color); color: white; padding: 0.35rem 0.75rem; border-radius: 20px; font-size: 0.8rem; font-weight: 700;">{{ $subjectResources->count() }} ملف</span>
            </div>
            <!-- Files List -->
            <div style="padding: 0.5rem;">
                @foreach($subjectResources as $resource)
                <div style="display: flex; align-items: center; justify-content: space-between; padding: 0.75rem 1rem; border-radius: 8px; transition: background 0.2s;" class="resource-item-hover">
                    <div style="display: flex; align-items: center; gap: 0.75rem; flex: 1; min-width: 0;">
                        @php
                        $ext = strtolower($resource->file_type);
                        $iconColor = '#64748b';
                        if(in_array($ext, ['pdf'])) { $iconColor = '#ef4444'; }
                        elseif(in_array($ext, ['ppt','pptx'])) { $iconColor = '#f59e0b'; }
                        elseif(in_array($ext, ['doc','docx'])) { $iconColor = '#3b82f6'; }
                        elseif(in_array($ext, ['xls','xlsx'])) { $iconColor = '#10b981'; }
                        elseif(in_array($ext, ['jpg','jpeg','png'])) { $iconColor = '#06b6d4'; }
                        elseif(in_array($ext, ['zip','rar'])) { $iconColor = '#4b5563'; }
                        @endphp
                        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="{{ $iconColor }}" stroke-width="2">
                            <path d="M13 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9z"></path>
                            <polyline points="13 2 13 9 20 9"></polyline>
                        </svg>
                        <div style="flex: 1; min-width: 0;">
                            <div style="font-weight: 600; color: var(--text-primary); font-size: 0.9rem; display: flex; align-items: center; gap: 0.5rem; flex-wrap: wrap;">
                                {{ $resource->title }}
                                @if($resource->uploader && $resource->uploader->role->value === 'doctor')
                                <span title="عضو هيئة تدريس" style="color: #f59e0b; display: flex;">
                                    <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M22 10v6M2 10v6M12 15a4 4 0 1 0 0-8 4 4 0 0 0 0 8z"/><path d="M6 15v-2a6 6 0 1 1 12 0v2"/></svg>
                                </span>
                                @endif
                            </div>
                            <div style="font-size: 0.75rem; color: var(--text-secondary);">
                                {{ strtoupper($resource->file_type) }} • {{ $resource->uploader->name ?? 'غير معروف' }} • {{ $resource->created_at->format('Y/m/d') }}
                                @if(in_array($resource->id, $scheduledResourceIds))
                                <span class="badge" style="background-color: #dbeafe; color: #1e40af; margin-right: 0.5rem; font-size: 0.7rem;">مجدول</span>
                                @endif
                                @if($resource->uploader && $resource->uploader->role->value === 'doctor')
                                <span style="color: #f59e0b; font-weight: 700; margin-right: 0.25rem;">(عضو هيئة تدريس)</span>
                                @endif
                            </div>
                        </div>
                    </div>
                    <div style="display: flex; gap: 0.5rem; margin-right: 1rem;">
                        @php $isScheduled = in_array($resource->id, $scheduledResourceIds); @endphp
                        <button onclick="openScheduleModal('App\\Models\\CourseResource', {{ $resource->id }}, '{{ $resource->title }}')"
                            style="width: 32px; height: 32px; display: flex; align-items: center; justify-content: center; {{ $isScheduled ? 'background: var(--primary-color); color: white;' : 'background: white; color: var(--text-secondary);' }} border: 1px solid #e2e8f0; border-radius: 8px; cursor: pointer; transition: all 0.2s;"
                            title="{{ $isScheduled ? 'مجدول' : 'إضافة لجدولي' }}">
                            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect>
                                <line x1="16" y1="2" x2="16" y2="6"></line>
                                <line x1="8" y1="2" x2="8" y2="6"></line>
                                <line x1="3" y1="10" x2="21" y2="10"></line>
                                <line x1="12" y1="15" x2="12" y2="15"></line>
                            </svg>
                        </button>
                        <a href="{{ Storage::url($resource->file_path) }}" target="_blank" style="width: 32px; height: 32px; display: flex; align-items: center; justify-content: center; background: #eff6ff; color: var(--primary-color); border-radius: 8px;">
                            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                                <polyline points="7 10 12 15 17 10"></polyline>
                                <line x1="12" y1="15" x2="12" y2="3"></line>
                            </svg>
                        </a>
                    </div>
                </div>
                @endforeach
            </div>
        </div>
        @empty
        <div style="text-align: center; padding: 3rem;">
            <div style="width: 60px; height: 60px; background: #f8fafc; border-radius: 50%; display: flex; align-items: center; justify-content: center; margin: 0 auto 1rem;">
                <svg xmlns="http://www.w3.org/2000/svg" width="30" height="30" viewBox="0 0 24 24" fill="none" stroke="#cbd5e1" stroke-width="2">
                    <path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"></path>
                </svg>
            </div>
            <h5 style="font-weight: 700; color: var(--text-primary);">لا توجد ملفات</h5>
        </div>
        @endforelse
    </div>
    @endif
</div>

<style>
    .resource-item-hover:hover {
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
</style>

<!-- Schedule Modal -->
<div id="scheduleModal" class="modal-overlay" style="display: none;">
    <div class="modal-container">
        <div class="modal-header">
            <h3 class="modal-title">إضافة إلى الجدول الدراسي</h3>
            <button type="button" class="close-btn" onclick="closeScheduleModal()">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <line x1="18" y1="6" x2="6" y2="18"></line>
                    <line x1="6" y1="6" x2="18" y2="18"></line>
                </svg>
            </button>
        </div>
        <div class="modal-body">
            <input type="hidden" id="schedule_type">
            <input type="hidden" id="schedule_id">

            <div style="margin-bottom: 1.5rem;">
                <label style="display: block; margin-bottom: 0.5rem; color: var(--text-secondary);">العنوان</label>
                <div id="schedule_title_display" style="font-weight: 700; color: var(--text-primary); font-size: 1.1rem; padding: 0.5rem; background: #f8fafc; border-radius: 8px;"></div>
            </div>

            <div style="margin-bottom: 1.5rem;">
                <label for="schedule_note" style="display: block; margin-bottom: 0.5rem; color: var(--text-secondary);">ملاحظات (اختياري)</label>
                <textarea id="schedule_note" class="form-control" rows="3" placeholder="أضف ملاحظاتك هنا..." style="width: 100%; padding: 0.75rem; border: 1px solid #e2e8f0; border-radius: 8px; resize: none;"></textarea>
            </div>
        </div>
        <div class="modal-footer" style="display: flex; gap: 1rem; justify-content: flex-end; margin-top: 1.5rem;">
            <button type="button" class="btn btn-secondary" onclick="closeScheduleModal()" style="background: #f1f5f9; color: var(--text-secondary); border: none; padding: 0.75rem 1.5rem; border-radius: 8px;">إلغاء</button>
            <button type="button" class="btn btn-primary" onclick="submitSchedule()" style="background: var(--primary-color); color: white; border: none; padding: 0.75rem 1.5rem; border-radius: 8px;">إضافة لمصادري</button>
        </div>
    </div>
</div>

<!-- Flatpickr CSS -->
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/flatpickr/dist/flatpickr.min.css">
<!-- Flatpickr JS -->
<script src="https://cdn.jsdelivr.net/npm/flatpickr"></script>

<style>
    /* Modal Styles */
    .modal-overlay {
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        background: rgba(0, 0, 0, 0.5);
        display: flex;
        align-items: center;
        justify-content: center;
        z-index: 1000;
        backdrop-filter: blur(4px);
    }

    .modal-container {
        background: white;
        border-radius: 16px;
        width: 100%;
        max-width: 500px;
        padding: 2rem;
        box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
        margin: 1rem;
    }

    .modal-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 2rem;
    }

    .modal-title {
        font-size: 1.5rem;
        font-weight: 800;
        color: var(--text-primary);
        margin: 0;
    }

    .close-btn {
        background: none;
        border: none;
        color: var(--text-secondary);
        cursor: pointer;
        padding: 0;
    }
</style>

<script>
    // Modal Functions
    function openScheduleModal(type, id, title) {
        document.getElementById('schedule_type').value = type;
        document.getElementById('schedule_id').value = id;
        document.getElementById('schedule_title_display').textContent = title;
        document.getElementById('schedule_note').value = ''; // Reset note

        document.getElementById('scheduleModal').style.display = 'flex';
    }

    function closeScheduleModal() {
        document.getElementById('scheduleModal').style.display = 'none';
    }

    function submitSchedule() {
        const type = document.getElementById('schedule_type').value;
        const id = document.getElementById('schedule_id').value;
        const title = document.getElementById('schedule_title_display').textContent;
        const note = document.getElementById('schedule_note').value;

        fetch('{{ route("student.schedule.store") }}', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-TOKEN': '{{ csrf_token() }}',
                    'Accept': 'application/json'
                },
                body: JSON.stringify({
                    referenceable_type: type,
                    referenceable_id: id,
                    title: title,
                    note: note,
                    item_type: 'resource' // Force item_type to resource since we are in resources page
                })
            })
            .then(res => res.json())
            .then(data => {
                if (data.success) {
                    alert(data.message);
                    closeScheduleModal();
                    // Since this view has pagination/HTML structure that's complex, a reload is easier to reflect changes
                    // Or we can try to update current item...
                    window.location.reload();
                } else {
                    alert(data.message || 'حدث خطأ ما');
                }
            })
            .catch(err => {
                console.error(err);
                alert('حدث خطأ أثناء الاتصال بالخادم');
            });
    }
</script>
@endsection