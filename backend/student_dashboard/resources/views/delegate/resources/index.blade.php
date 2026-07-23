@extends('layouts.delegate')

@section('title', 'مصادر المقرر')

@section('content')

<!-- Page Header -->
<div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 2rem;">
    <div>
        <h1 style="font-size: 1.8rem; font-weight: 800; color: var(--text-primary); margin-bottom: 0.5rem;">إدارة المصادر</h1>
        <p style="color: var(--text-secondary); margin: 0; font-size: 1rem;">لوحة التحكم في كافة الملفات والمستندات الدراسية</p>
    </div>
    <div style="display: flex; gap: 1rem;">
        <button x-data @click="$dispatch('open-import-modal')" class="btn shadow-sm" style="padding: 0.75rem 1.5rem; font-weight: 700; border-radius: 50px; background: white; color: #4f46e5; border: 2px solid #4f46e5; display: inline-flex; align-items: center; gap: 0.5rem; transition: all 0.2s;">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                <polyline points="7 10 12 15 17 10"></polyline>
                <line x1="12" y1="15" x2="12" y2="3"></line>
            </svg>
            <span>استيراد من المكتبة</span>
        </button>
        <a href="{{ route('delegate.resources.create') }}" class="btn btn-primary shadow-lg" style="padding: 0.75rem 2rem; font-weight: 700; border-radius: 50px; background: linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%); border: none; box-shadow: 0 10px 25px -5px rgba(124, 58, 237, 0.4); text-decoration: none; display: inline-flex; align-items: center; gap: 0.5rem; transition: transform 0.2s;">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                <line x1="12" y1="5" x2="12" y2="19"></line>
                <line x1="5" y1="12" x2="19" y2="12"></line>
            </svg>
            <span>رفع ملف جديد</span>
        </a>
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

    <!-- My Uploads -->
    <div class="card border-0 shadow-sm" style="padding: 1.5rem; display: flex; align-items: center; gap: 1.5rem; background: white; border-radius: 20px; transition: transform 0.2s;">
        <div style="width: 64px; height: 64px; border-radius: 16px; background: rgba(16, 185, 129, 0.1); display: flex; align-items: center; justify-content: center; color: #10b981;">
            <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
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
</div>

<!-- Filters & Search (Single Line - Split Buttons) -->
<div class="card border-0 shadow-sm mb-4" style="background: white; border-radius: 20px; padding: 0.75rem;">
    <form action="{{ route('delegate.resources.index') }}" method="GET" style="display: flex; align-items: center; gap: 0.75rem; width: 100%;">

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

        <!-- Search/Filter Button -->
        <button type="submit"
            class="btn btn-dark shadow-sm"
            title="بحث وتصفية"
            style="height: 50px; padding: 0 1.5rem; border-radius: 12px; font-weight: 700; display: flex; align-items: center; justify-content: center; gap: 0.5rem; background: var(--primary-color); border: none; flex-shrink: 0; color: white;">
            <svg style="width: 20px; height: 20px; stroke: white; stroke-width: 2.5; fill: none;" viewBox="0 0 24 24">
                <circle cx="11" cy="11" r="7" />
                <path d="M21 21l-4.35-4.35" />
            </svg>
            <span>بحث</span>
        </button>

        <!-- Clear Button (if searching) -->
        @if(request()->hasAny(['search', 'subject_id', 'category']))
        <a href="{{ route('delegate.resources.index') }}"
            style="width: 50px; height: 50px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; text-decoration: none;"
            title="إلغاء التصفية">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
                <path d="M18 6L6 18M6 6l12 12" stroke="#ef4444" stroke-width="3" stroke-linecap="round" />
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
                <a href="{{ route('delegate.resources.index', array_merge(request()->except('view'), ['view' => 'table'])) }}"
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
                <a href="{{ route('delegate.resources.index', array_merge(request()->except('view'), ['view' => 'grouped'])) }}"
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
                    <option value="{{ route('delegate.resources.index', array_merge(request()->except('sort'), ['sort' => 'newest'])) }}" {{ ($sort ?? 'newest') == 'newest' ? 'selected' : '' }}>الأحدث</option>
                    <option value="{{ route('delegate.resources.index', array_merge(request()->except('sort'), ['sort' => 'oldest'])) }}" {{ ($sort ?? 'newest') == 'oldest' ? 'selected' : '' }}>الأقدم</option>
                    <option value="{{ route('delegate.resources.index', array_merge(request()->except('sort'), ['sort' => 'subject'])) }}" {{ ($sort ?? 'newest') == 'subject' ? 'selected' : '' }}>حسب المادة</option>
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
                    <th style="padding: 1.25rem 1.5rem; text-align: left;">إجراءات</th>
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
                        @if($resource->created_by == auth()->id())
                        <span class="badge bg-success-light text-success px-2 py-1" style="background: #dcfce7; color: #15803d;">أنت</span>
                        @else
                        <div class="d-flex align-items-center gap-2">
                            <div style="width: 24px; height: 24px; background: #e2e8f0; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 0.7rem; font-weight: bold; color: #64748b;">
                                {{ mb_substr($resource->uploader->name ?? '?', 0, 1) }}
                            </div>
                            <span class="text-dark small fw-bold">{{ $resource->uploader->name ?? '-' }}</span>
                        </div>
                        @endif
                    </td>
                    <td style="padding: 1rem 1.5rem;" class="text-muted small fw-bold">
                        {{ $resource->created_at->format('Y/m/d') }}
                    </td>
                    <!-- Direct Action Icons -->
                    <td style="padding: 1rem 1.5rem; text-align: left;">
                        <div style="display: flex; gap: 0.5rem; justify-content: flex-end;">

                            <!-- Download Button -->
                            <a href="{{ Storage::url($resource->file_path) }}" target="_blank"
                                style="width: 36px; height: 36px; display: flex; align-items: center; justify-content: center; text-decoration: none;"
                                title="تحميل الملف">
                                <svg width="22" height="22" viewBox="0 0 24 24" fill="none">
                                    <path d="M12 3v12m0 0l-4-4m4 4l4-4M4 17v2a2 2 0 002 2h12a2 2 0 002-2v-2" stroke="#4f46e5" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" />
                                </svg>
                            </a>

                            @if($resource->created_by == auth()->id())
                            <form action="{{ route('delegate.resources.destroy', $resource->id) }}" method="POST" onsubmit="return confirm('هل أنت متأكد من حذف هذا الملف؟');" style="margin: 0;">
                                @csrf
                                @method('DELETE')
                                <button type="submit"
                                    style="width: 36px; height: 36px; display: flex; align-items: center; justify-content: center; background: transparent; border: none; cursor: pointer; padding: 0;"
                                    title="حذف الملف">
                                    <svg width="22" height="22" viewBox="0 0 24 24" fill="none">
                                        <path d="M3 6h18M8 6V4a2 2 0 012-2h4a2 2 0 012 2v2m3 0v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6h14zM10 11v6M14 11v6" stroke="#ef4444" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
                                    </svg>
                                </button>
                            </form>
                            @endif
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
                        <h5 class="fw-bold text-dark">لا توجد ملفات مطابقة</h5>
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
                <div style="display: flex; align-items: center; justify-content: space-between; padding: 0.75rem 1rem; border-radius: 8px;">
                    <div style="display: flex; align-items: center; gap: 0.75rem; flex: 1; min-width: 0;">
                        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#64748b" stroke-width="2">
                            <path d="M13 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9z"></path>
                            <polyline points="13 2 13 9 20 9"></polyline>
                        </svg>
                        <div style="flex: 1; min-width: 0;">
                            <div style="font-weight: 600; color: var(--text-primary); font-size: 0.9rem;">{{ $resource->title }}</div>
                            <div style="font-size: 0.75rem; color: var(--text-secondary);">{{ strtoupper($resource->file_type) }} • {{ $resource->created_at->format('Y/m/d') }}</div>
                        </div>
                    </div>
                    <a href="{{ Storage::url($resource->file_path) }}" target="_blank" style="width: 32px; height: 32px; display: flex; align-items: center; justify-content: center; background: #eff6ff; color: var(--primary-color); border-radius: 8px;">
                        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                            <polyline points="7 10 12 15 17 10"></polyline>
                            <line x1="12" y1="15" x2="12" y2="3"></line>
                        </svg>
                    </a>
                </div>
                @endforeach
            </div>
        </div>
        @empty
        <div style="text-align: center; padding: 3rem;">
            <h5 style="font-weight: 700; color: var(--text-primary);">لا توجد ملفات</h5>
        </div>
        @endforelse
    </div>
    @endif
</div>

<style>
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

    /* Import Modal specific */
    .import-modal-overlay {
        position: fixed;
        inset: 0;
        background: rgba(15, 23, 42, 0.6);
        backdrop-filter: blur(4px);
        z-index: 1050;
        display: flex;
        align-items: center;
        justify-content: center;
        padding: 1rem;
    }

    .import-modal-container {
        background: white;
        border-radius: 20px;
        width: 100%;
        max-width: 600px;
        max-height: 90vh;
        display: flex;
        flex-direction: column;
        box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
        overflow: hidden;
    }

    .search-result-item {
        padding: 1rem;
        border-bottom: 1px solid #e2e8f0;
        cursor: pointer;
        transition: all 0.2s;
    }

    .search-result-item:hover {
        background: #f8fafc;
    }

    .search-result-item.selected {
        background: #eff6ff;
        border-left: 4px solid var(--primary-color);
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

    .btn-icon:hover {
        transform: translateY(-2px);
    }

    /* Specific hover colors for actions */
    a[href*="storage"]:hover {
        background: #dbeafe !important;
        color: #2563eb !important;
    }

    button[title="حذف الملف"]:hover {
        background: #fee2e2 !important;
        color: #dc2626 !important;
    }
</style>
</style>

<!-- Import Modal (Alpine.js) -->
<div x-data="importModalData()"
    @open-import-modal.window="openModal()"
    x-show="isOpen"
    class="import-modal-overlay"
    style="display: none;"
    x-transition.opacity>

    <div class="import-modal-container" @click.away="isOpen = false" x-transition.scale>

        <!-- Header -->
        <div style="padding: 1.5rem; border-bottom: 1px solid #e2e8f0; display: flex; justify-content: space-between; align-items: center; background: #f8fafc;">
            <div style="display: flex; align-items: center; gap: 0.75rem;">
                <div style="width: 40px; height: 40px; background: white; border-radius: 10px; display: flex; align-items: center; justify-content: center; color: var(--primary-color); box-shadow: 0 1px 3px rgba(0,0,0,0.1);">
                    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                        <polyline points="7 10 12 15 17 10"></polyline>
                        <line x1="12" y1="15" x2="12" y2="3"></line>
                    </svg>
                </div>
                <h3 style="margin: 0; font-size: 1.25rem; font-weight: 800; color: var(--text-primary);">استيراد من المكتبة العامة</h3>
            </div>
            <button @click="isOpen = false" style="background: none; border: none; color: #94a3b8; cursor: pointer; display: flex; align-items: center; justify-content: center;">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <line x1="18" y1="6" x2="6" y2="18"></line>
                    <line x1="6" y1="6" x2="18" y2="18"></line>
                </svg>
            </button>
        </div>

        <!-- Search Input -->
        <div style="padding: 1.5rem; border-bottom: 1px solid #e2e8f0;">
            <div style="position: relative;">
                <input type="text" x-model="searchQuery" @input.debounce.500ms="fetchResults()" placeholder="أدخل اسم المادة للبحث..." style="width: 100%; height: 50px; background: #f1f5f9; border: 2px solid transparent; border-radius: 12px; padding: 0 3rem 0 1rem; font-size: 1rem; font-weight: 600; outline: none; transition: 0.2s;" onfocus="this.style.background='white'; this.style.borderColor='var(--primary-color)';">
                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#64748b" stroke-width="2" style="position: absolute; right: 1rem; top: 15px;">
                    <circle cx="11" cy="11" r="8"></circle>
                    <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
                </svg>

                <!-- Loading indicator -->
                <div x-show="isLoading" style="position: absolute; left: 1rem; top: 15px;">
                    <div style="width: 20px; height: 20px; border: 2px solid #e2e8f0; border-top-color: var(--primary-color); border-radius: 50%; animation: spin 1s linear infinite;"></div>
                </div>
            </div>
        </div>

        <!-- Results Area -->
        <div style="flex: 1; overflow-y: auto; max-height: 400px; background: white; padding: 0.5rem 0;">

            <div x-show="results.length === 0 && !isLoading && searchQuery !== ''" style="padding: 2rem; text-align: center; color: #94a3b8;">
                <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="margin-bottom: 1rem; opacity: 0.5;">
                    <circle cx="11" cy="11" r="8"></circle>
                    <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
                </svg>
                <p style="font-weight: 600;">لا توجد نتائج مطابقة لبحثك</p>
            </div>

            <div x-show="results.length === 0 && searchQuery === ''" style="padding: 2rem; text-align: center; color: #94a3b8;">
                <p style="font-weight: 600;">اكتب كلمة مفتاحية للتبحث في أرشيف المكتبة</p>
            </div>

            <template x-for="item in results" :key="item.id">
                <div @click="selectedResourceId = item.id" class="search-result-item" :class="{'selected': selectedResourceId === item.id}" style="display: flex; gap: 1rem; align-items: center;">
                    <!-- Icon -->
                    <div style="width: 40px; height: 40px; border-radius: 10px; background: #f1f5f9; display: flex; align-items: center; justify-content: center; flex-shrink: 0; color: #64748b;">
                        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M13 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9z"></path>
                            <polyline points="13 2 13 9 20 9"></polyline>
                        </svg>
                    </div>
                    <!-- Details -->
                    <div style="flex: 1; min-width: 0;">
                        <h4 x-text="item.title" style="margin: 0 0 0.25rem 0; font-size: 0.95rem; font-weight: 700; color: var(--text-primary); white-space: nowrap; overflow: hidden; text-overflow: ellipsis;"></h4>
                        <div style="display: flex; gap: 0.5rem; font-size: 0.8rem; color: var(--text-secondary); align-items: center;">
                            <span x-text="item.subject_name" style="background: #e2e8f0; padding: 2px 6px; border-radius: 4px; font-weight: 600; color: #475569;"></span>
                            &bull;
                            <span x-text="item.uploader_name"></span>
                            &bull;
                            <span x-text="item.created_at"></span>
                        </div>
                    </div>
                    <!-- Radio Button equivalent visual -->
                    <div style="width: 20px; height: 20px; border-radius: 50%; border: 2px solid #cbd5e1; display: flex; align-items: center; justify-content: center;">
                        <div x-show="selectedResourceId === item.id" style="width: 10px; height: 10px; background: var(--primary-color); border-radius: 50%;"></div>
                    </div>
                </div>
            </template>
        </div>

        <!-- Footer / Submit Form -->
        <div style="padding: 1.5rem; background: #f8fafc; border-top: 1px solid #e2e8f0; display: flex; flex-direction: column; gap: 1rem;">

            <form action="{{ route('delegate.resources.import') }}" method="POST" id="importForm" x-show="selectedResourceId">
                @csrf
                <input type="hidden" name="resource_id" :value="selectedResourceId">

                <div style="margin-bottom: 1rem;">
                    <label style="display: block; font-weight: 700; margin-bottom: 0.5rem; font-size: 0.9rem; color: var(--text-primary);">استيراد الملف إلى المادة: <span style="color: #ef4444;">*</span></label>
                    <select name="subject_id" required style="width: 100%; height: 46px; background: white; border: 2px solid #e2e8f0; border-radius: 10px; padding: 0 1rem; font-weight: 600; outline: none;">
                        <option value="">اختر المادة الدراسية...</option>
                        @foreach($subjects as $subject)
                        <option value="{{ $subject->id }}">{{ $subject->name }}</option>
                        @endforeach
                    </select>
                </div>

                <button type="submit" class="btn btn-primary" style="width: 100%; height: 46px; border-radius: 10px; font-weight: 700; display: flex; align-items: center; justify-content: center; gap: 0.5rem;" :disabled="!selectedResourceId">
                    <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                        <polyline points="7 10 12 15 17 10"></polyline>
                        <line x1="12" y1="15" x2="12" y2="3"></line>
                    </svg>
                    تأكيد الاستيراد المباشر
                </button>
            </form>

            <div x-show="!selectedResourceId" style="text-align: center; color: #94a3b8; font-size: 0.9rem;">
                الرجاء البحث واختيار ملف من القائمة أولاً للمتابعة.
            </div>
        </div>

    </div>
</div>

<style>
    @keyframes spin {
        100% {
            transform: rotate(360deg);
        }
    }
</style>

<script>
    function importModalData() {
        return {
            isOpen: false,
            searchQuery: '',
            isLoading: false,
            results: [],
            selectedResourceId: null,

            openModal() {
                this.isOpen = true;
                this.selectedResourceId = null;
                // Don't auto-fetch empty if you don't want to load all
            },

            fetchResults() {
                if (this.searchQuery.length < 2) {
                    // Start searching from 2 chars
                    return;
                }

                this.isLoading = true;

                fetch(`{{ route('delegate.resources.search-library') }}?q=${encodeURIComponent(this.searchQuery)}`, {
                        headers: {
                            'Accept': 'application/json'
                        }
                    })
                    .then(res => res.json())
                    .then(data => {
                        this.results = data;
                        this.isLoading = false;

                        // Reset selection if not in new results
                        if (this.selectedResourceId && !this.results.find(r => r.id === this.selectedResourceId)) {
                            this.selectedResourceId = null;
                        }
                    })
                    .catch(err => {
                        console.error("Error fetching library:", err);
                        this.isLoading = false;
                    });
            }
        }
    }
</script>

@endsection