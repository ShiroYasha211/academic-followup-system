@extends('layouts.admin')

@section('title', 'إدارة المكتبة المشتركة')

@section('content')
<div x-data="{ 
    showDetails: false, 
    resDetail: {},
    selectedIds: [],
    selectAll: false,
    toggleAll() {
        this.selectAll = !this.selectAll;
        if (this.selectAll) {
            this.selectedIds = Array.from(document.querySelectorAll('input[name=\'ids[]\']')).map(el => el.value);
        } else {
            this.selectedIds = [];
        }
    },
    updateSelectAll() {
        const total = document.querySelectorAll('input[name=\'ids[]\']').length;
        this.selectAll = this.selectedIds.length === total && total > 0;
    }
}">
    <!-- Bulk Actions Floating Bar -->
    <template x-if="selectedIds.length > 0">
        <div style="position: fixed; bottom: 2rem; left: 50%; transform: translateX(-50%); z-index: 1000; background: #1e293b; color: white; padding: 1rem 2rem; border-radius: 20px; box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.3); display: flex; align-items: center; gap: 2rem; border: 1px solid rgba(255,255,255,0.1); animation: slideUp 0.3s ease-out;">
            <div>
                <span x-text="selectedIds.length" style="font-weight: 800; color: #38bdf8; font-size: 1.2rem;"></span>
                <span style="margin-right: 0.5rem; font-weight: 600;">ملفات مختارة</span>
            </div>
            <div style="height: 24px; width: 1px; background: rgba(255,255,255,0.2);"></div>
            <div style="display: flex; gap: 1rem;">
                <form action="{{ route('admin.library.bulk-destroy') }}" method="POST" onsubmit="return confirm('هل أنت متأكد من حذف الملفات المختارة نهائياً؟')">
                    @csrf
                    <template x-for="id in selectedIds">
                        <input type="hidden" name="ids[]" :value="id">
                    </template>
                    <button type="submit" style="background: #ef4444; color: white; border: none; padding: 0.6rem 1.25rem; border-radius: 12px; font-weight: 700; display: flex; align-items: center; gap: 0.5rem; cursor: pointer; transition: all 0.2s;">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M3 6h18"></path><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"></path><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"></path></svg>
                        حذف المحدد
                    </button>
                </form>
                <button type="button" @click="selectedIds = []; selectAll = false" style="background: transparent; color: #94a3b8; border: 1px solid #475569; padding: 0.6rem 1.25rem; border-radius: 12px; font-weight: 700; cursor: pointer;">إلغاء</button>
            </div>
        </div>
    </template>

    <!-- Page Header -->
    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 2rem;">
        <div>
            <h1 style="font-size: 1.8rem; font-weight: 800; color: var(--text-primary); margin-bottom: 0.5rem; display: flex; align-items: center; gap: 0.75rem;">
                <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="color: var(--primary-color);">
                    <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5"></path>
                </svg>
                إدارة المكتبة المشتركة
            </h1>
            <p style="color: var(--text-secondary); margin: 0; font-size: 1rem;">التحكم الكامل ومراقبة جميع الملفات التعليمية المرفوعة في النظام</p>
        </div>
        <a href="{{ route('admin.library.create') }}" 
           style="background: var(--primary-color); color: white; text-decoration: none; padding: 0.85rem 1.75rem; border-radius: 15px; font-weight: 800; display: flex; align-items: center; gap: 0.75rem; transition: all 0.3s; box-shadow: 0 10px 15px -3px rgba(79, 70, 229, 0.3);">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3">
                <line x1="12" y1="5" x2="12" y2="19"></line>
                <line x1="5" y1="12" x2="19" y2="12"></line>
            </svg>
            رفع ملف جديد
        </a>
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
                <div style="font-size: 0.9rem; color: var(--text-secondary); font-weight: 600; margin-bottom: 0.25rem;">إجمالي الملفات</div>
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
                <div style="font-size: 0.9rem; color: var(--text-secondary); font-weight: 600; margin-bottom: 0.25rem;">الفصول الدراسية</div>
                <div style="font-size: 1.75rem; font-weight: 800; color: var(--text-primary); line-height: 1;">{{ $semesters->count() }}</div>
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
                <div style="font-size: 0.9rem; color: var(--text-secondary); font-weight: 600; margin-bottom: 0.25rem;">المواد الموثقة</div>
                <div style="font-size: 1.75rem; font-weight: 800; color: var(--text-primary); line-height: 1;">{{ $subjects->count() }}</div>
            </div>
        </div>
    </div>

    @if(session('success'))
        <div class="alert alert-success" style="border-radius: 12px; margin-bottom: 1.5rem;">{{ session('success') }}</div>
    @endif

    <!-- Search & Filters -->
    <div class="card border-0 shadow-sm" style="background: white; border-radius: 20px; padding: 1.5rem; margin-bottom: 2rem;" x-data="{ showAdvanced: {{ request()->hasAny(['semester_info', 'lecturer_name', 'sub_category', 'file_type', 'uploader_role']) ? 'true' : 'false' }} }">
        <form action="{{ route('admin.library.index') }}" method="GET" style="width: 100%;">
            <div style="display: flex; gap: 1rem; flex-wrap: wrap; align-items: center;">
                <div style="flex: 1; position: relative; min-width: 300px;">
                    <input type="text" name="search" value="{{ request('search') }}" 
                           placeholder="بحث بالاسم، المحاضر، أو المادة..." 
                           style="width: 100%; padding: 0.85rem 1rem 0.85rem 3rem; border: 2px solid #f1f5f9; border-radius: 15px; background: #f8fafc; font-size: 1rem; transition: all 0.2s;">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" 
                         style="position: absolute; left: 1rem; top: 50%; transform: translateY(-50%); color: var(--text-secondary);">
                        <circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line>
                    </svg>
                </div>

                <div style="display: flex; gap: 0.75rem; align-items: center;">
                    <select name="subject_id" onchange="this.form.submit()" 
                            style="padding: 0.85rem 1rem; border: 2px solid #f1f5f9; border-radius: 15px; background: #f8fafc; color: var(--text-primary); cursor: pointer; min-width: 160px;">
                        <option value="">كل المواد</option>
                        @foreach($subjects as $subject)
                            <option value="{{ $subject->id }}" {{ request('subject_id') == $subject->id ? 'selected' : '' }}>{{ $subject->name }}</option>
                        @endforeach
                    </select>

                    <select name="category" onchange="this.form.submit()"
                            style="padding: 0.85rem 1rem; border: 2px solid #f1f5f9; border-radius: 15px; background: #f8fafc; color: var(--text-primary); cursor: pointer; min-width: 140px;">
                        @foreach([
                            'lectures' => 'محاضرات',
                            'summaries' => 'ملخصات',
                            'quizzes' => 'كويزات',
                            'exams' => 'نماذج اختبارات',
                            'references' => 'مراجع',
                            'other' => 'أخرى'
                        ] as $val => $label)
                            <option value="{{ $val }}" {{ request('category') == $val ? 'selected' : '' }}>{{ $label }}</option>
                        @endforeach
                    </select>

                    <button type="button" @click="showAdvanced = !showAdvanced" 
                            class="filter-toggle-btn"
                            :class="{ 'active': showAdvanced }">
                        <div class="icon-toggle" :class="{ 'rotated': showAdvanced }">
                            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                                <path d="M6 9l6 6 6-6"></path>
                            </svg>
                        </div>
                        <span>خيارات متقدمة</span>
                    </button>

                    @if(request()->anyFilled(['search', 'subject_id', 'category', 'semester_info', 'lecturer_name', 'sub_category', 'file_type', 'uploader_role']))
                        <a href="{{ route('admin.library.index') }}" 
                           style="color: var(--danger-color); text-decoration: none; font-weight: 700; font-size: 0.9rem; padding: 0.5rem; white-space: nowrap;">
                           مسح الكل
                        </a>
                    @endif
                </div>
            </div>

            <!-- Advanced Filters Grid -->
            <div x-show="showAdvanced" x-transition:enter="transition ease-out duration-200" 
                 x-transition:enter-start="opacity-0 transform -translate-y-2" 
                 x-transition:enter-end="opacity-100 transform translate-y-0"
                 style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1.5rem; margin-top: 1.5rem; padding-top: 1.5rem; border-top: 1px solid #f1f5f9;">
                
                <div>
                    <label style="display: block; font-size: 0.85rem; font-weight: 700; color: var(--text-secondary); margin-bottom: 0.5rem;">رتبة الناشر</label>
                    <select name="uploader_role" onchange="this.form.submit()" style="width: 100%; padding: 0.75rem; border: 2px solid #f1f5f9; border-radius: 12px; background: white; color: var(--text-primary);">
                        <option value="">الجميع</option>
                        <option value="doctor" {{ request('uploader_role') == 'doctor' ? 'selected' : '' }}>دكتور</option>
                        <option value="delegate" {{ request('uploader_role') == 'delegate' ? 'selected' : '' }}>مندوب</option>
                        <option value="student" {{ request('uploader_role') == 'student' ? 'selected' : '' }}>طالب</option>
                    </select>
                </div>

                <div>
                    <label style="display: block; font-size: 0.85rem; font-weight: 700; color: var(--text-secondary); margin-bottom: 0.5rem;">الفصل الدراسي / السستم</label>
                    <select name="semester_info" onchange="this.form.submit()" style="width: 100%; padding: 0.75rem; border: 2px solid #f1f5f9; border-radius: 12px; background: white; color: var(--text-primary);">
                        <option value="">الكل</option>
                        @foreach($semesters as $sem)
                            <option value="{{ $sem }}" {{ request('semester_info') == $sem ? 'selected' : '' }}>{{ $sem }}</option>
                        @endforeach
                    </select>
                </div>

                <div>
                    <label style="display: block; font-size: 0.85rem; font-weight: 700; color: var(--text-secondary); margin-bottom: 0.5rem;">اسم المحاضر</label>
                    <select name="lecturer_name" onchange="this.form.submit()" style="width: 100%; padding: 0.75rem; border: 2px solid #f1f5f9; border-radius: 12px; background: white; color: var(--text-primary);">
                        <option value="">الكل</option>
                        @foreach($lecturers as $lec)
                            <option value="{{ $lec }}" {{ request('lecturer_name') == $lec ? 'selected' : '' }}>{{ $lec }}</option>
                        @endforeach
                    </select>
                </div>

                <div>
                    <label style="display: block; font-size: 0.85rem; font-weight: 700; color: var(--text-secondary); margin-bottom: 0.5rem;">نوع الملف</label>
                    <select name="file_type" onchange="this.form.submit()" style="width: 100%; padding: 0.75rem; border: 2px solid #f1f5f9; border-radius: 12px; background: white; color: var(--text-primary);">
                        <option value="">الكل</option>
                        <option value="pdf" {{ request('file_type') == 'pdf' ? 'selected' : '' }}>PDF Document</option>
                        <option value="presentation" {{ request('file_type') == 'presentation' ? 'selected' : '' }}>PowerPoint</option>
                        <option value="document" {{ request('file_type') == 'document' ? 'selected' : '' }}>Word Document</option>
                        <option value="image" {{ request('file_type') == 'image' ? 'selected' : '' }}>Images</option>
                    </select>
                </div>
            </div>
        </form>
    </div>

    <!-- Resources Table -->
    <div class="card border-0 shadow-sm" style="background: white; border-radius: 20px; padding: 0; overflow: hidden;">
        <div style="overflow-x: auto;">
            <table style="width: 100%; border-collapse: collapse; min-width: 1000px;">
                <thead>
                    <tr style="background: #f8fafc; border-bottom: 2px solid #f1f5f9;">
                        <th style="padding: 1.25rem 1.5rem; text-align: center; width: 50px;">
                            <input type="checkbox" @click="toggleAll()" :checked="selectAll" style="width: 18px; height: 18px; cursor: pointer; border-radius: 4px;">
                        </th>
                        <th style="padding: 1.25rem 1.5rem; text-align: right; color: var(--text-secondary); font-weight: 700; font-size: 0.9rem;">الملف</th>
                        <th style="padding: 1.25rem 1.5rem; text-align: right; color: var(--text-secondary); font-weight: 700; font-size: 0.9rem;">المادة والنوع</th>
                        <th style="padding: 1.25rem 1.5rem; text-align: right; color: var(--text-secondary); font-weight: 700; font-size: 0.9rem;">الناشر</th>
                        <th style="padding: 1.25rem 1.5rem; text-align: right; color: var(--text-secondary); font-weight: 700; font-size: 0.9rem;">التاريخ</th>
                        <th style="padding: 1.25rem 1.5rem; text-align: right; color: var(--text-secondary); font-weight: 700; font-size: 0.9rem;">الخصوصية</th>
                        <th style="padding: 1.25rem 1.5rem; text-align: center; color: var(--text-secondary); font-weight: 700; font-size: 0.9rem;">الإجراءات</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($resources as $resource)
                    <tr style="border-bottom: 1px solid #f8fafc; transition: background 0.2s;" :class="{'bg-primary-soft': selectedIds.includes('{{ $resource->id }}')}" onmouseover="this.style.background='#fcfdff'" onmouseout="this.style.background='white'">
                        <td style="padding: 1.25rem 1.5rem; text-align: center;">
                            <input type="checkbox" name="ids[]" value="{{ $resource->id }}" x-model="selectedIds" @change="updateSelectAll()" style="width: 18px; height: 18px; cursor: pointer; border-radius: 4px;">
                        </td>
                        <td style="padding: 1.25rem 1.5rem;">
                            <div style="display: flex; align-items: center; gap: 1rem;">
                                <div style="width: 48px; height: 48px; border-radius: 12px; background: {{ in_array($resource->file_type, ['pdf']) ? 'rgba(239, 68, 68, 0.1)' : (in_array($resource->file_type, ['ppt', 'pptx']) ? 'rgba(245, 158, 11, 0.1)' : 'rgba(79, 70, 229, 0.1)') }}; display: flex; align-items: center; justify-content: center; color: {{ in_array($resource->file_type, ['pdf']) ? '#ef4444' : (in_array($resource->file_type, ['ppt', 'pptx']) ? '#f59e0b' : 'var(--primary-color)') }};">
                                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                                        <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                                        <polyline points="14 2 14 8 20 8"></polyline>
                                    </svg>
                                </div>
                                <div>
                                    <div style="font-weight: 700; color: var(--text-primary); margin-bottom: 0.25rem;">{{ Str::limit($resource->title, 40) }}</div>
                                    <div style="font-size: 0.85rem; color: var(--text-secondary);">{{ $resource->lecturer_name ?: 'محاضر غير محدد' }}</div>
                                </div>
                            </div>
                        </td>
                        <td style="padding: 1.25rem 1.5rem;">
                            <div style="font-weight: 600; color: var(--text-primary); margin-bottom: 0.25rem;">{{ $resource->subject?->name ?? 'مادة محذوفة' }}</div>
                            <span style="font-size: 0.75rem; padding: 0.25rem 0.6rem; background: #f1f5f9; color: var(--text-secondary); border-radius: 6px; font-weight: 700;">{{ $resource->full_category_text }}</span>
                        </td>
                        <td style="padding: 1.25rem 1.5rem;">
                            @php
                                $uploader = $resource->uploader;
                                $uploaderRole = $uploader?->role;
                                $uploaderRole = $uploaderRole instanceof \App\Enums\UserRole
                                    ? $uploaderRole->value
                                    : (string) $uploaderRole;
                            @endphp
                            <div style="display: flex; align-items: center; gap: 0.5rem; margin-bottom: 0.25rem;">
                                @if($uploaderRole === 'doctor')
                                    <span style="font-size: 0.7rem; padding: 0.15rem 0.4rem; background: rgba(79, 70, 229, 0.1); color: var(--primary-color); border-radius: 6px; font-weight: 800;">دكتور</span>
                                @elseif(in_array($uploaderRole, ['delegate', 'practical_delegate'], true))
                                    <span style="font-size: 0.7rem; padding: 0.15rem 0.4rem; background: rgba(20, 184, 166, 0.1); color: #14b8a6; border-radius: 6px; font-weight: 800;">مندوب</span>
                                @elseif($uploaderRole === 'student')
                                    <span style="font-size: 0.7rem; padding: 0.15rem 0.4rem; background: rgba(100, 116, 139, 0.1); color: #64748b; border-radius: 6px; font-weight: 800;">طالب</span>
                                @else
                                    <span style="font-size: 0.7rem; padding: 0.15rem 0.4rem; background: rgba(100, 116, 139, 0.1); color: #64748b; border-radius: 6px; font-weight: 800;">غير معروف</span>
                                @endif
                                <div style="font-weight: 600; font-size: 0.9rem;">{{ $uploader?->name ?? 'مستخدم محذوف' }}</div>
                            </div>
                            <div style="font-size: 0.8rem; color: var(--text-secondary);">{{ $uploader?->batch ? 'دفعة ' . $uploader->batch : '' }}</div>
                        </td>
                        <td style="padding: 1.25rem 1.5rem;">
                            <div style="font-weight: 600; font-size: 0.9rem;">{{ $resource->created_at->format('Y/m/d') }}</div>
                            <div style="font-size: 0.8rem; color: var(--text-secondary);">{{ $resource->created_at->format('h:i A') }}</div>
                        </td>
                        <td style="padding: 1.25rem 1.5rem;">
                            @if($resource->visibility == 'everyone')
                                <span style="font-size: 0.8rem; padding: 0.35rem 0.75rem; background: rgba(16, 185, 129, 0.1); color: #10b981; border-radius: 10px; font-weight: 700;">عام للجميع</span>
                            @elseif($resource->visibility == 'college')
                                <span style="font-size: 0.8rem; padding: 0.35rem 0.75rem; background: rgba(59, 130, 246, 0.1); color: #3b82f6; border-radius: 10px; font-weight: 700;">الكلية فقط</span>
                            @else
                                <span style="font-size: 0.8rem; padding: 0.35rem 0.75rem; background: rgba(245, 158, 11, 0.1); color: #f59e0b; border-radius: 10px; font-weight: 700;">الدفعة: {{ $resource->batch }}</span>
                            @endif
                        </td>
                        <td style="padding: 1.25rem 1.5rem; text-align: center;">
                            <div style="display: flex; gap: 0.5rem; justify-content: center;">
                                <a href="{{ route('admin.library.download', $resource) }}" 
                                   style="width: 38px; height: 38px; border-radius: 10px; background: #eff6ff; color: #3b82f6; display: flex; align-items: center; justify-content: center; transition: all 0.2s;" title="تحميل">
                                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path><polyline points="7 10 12 15 17 10"></polyline><line x1="12" y1="15" x2="12" y2="3"></line></svg>
                                </a>
                                <a href="{{ route('admin.library.edit', $resource) }}" 
                                   style="width: 38px; height: 38px; border-radius: 10px; background: #f0f9ff; color: #0ea5e9; display: flex; align-items: center; justify-content: center; transition: all 0.2s;" title="تعديل">
                                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path></svg>
                                </a>
                                <form action="{{ route('admin.library.destroy', $resource) }}" method="POST" onsubmit="return confirm('هل أنت متأكد من حذف هذا الملف نهائياً؟')">
                                    @csrf
                                    @method('DELETE')
                                    <button type="submit" 
                                            style="width: 38px; height: 38px; border-radius: 10px; background: #fff1f2; color: #ef4444; border: none; display: flex; align-items: center; justify-content: center; cursor: pointer; transition: all 0.2s;" title="حذف">
                                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="3 6 5 6 21 6"></polyline><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path><line x1="10" y1="11" x2="10" y2="17"></line><line x1="14" y1="11" x2="14" y2="17"></line></svg>
                                    </button>
                                </form>
                            </div>
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="6" style="padding: 5rem 2rem; text-align: center;">
                            <div style="color: var(--text-secondary);">
                                <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="margin-bottom: 1.5rem; opacity: 0.3;">
                                    <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline><line x1="9" y1="15" x2="15" y2="15"></line>
                                </svg>
                                <div style="font-size: 1.25rem; font-weight: 700; color: var(--text-primary); margin-bottom: 0.5rem;">لا توجد ملفات حالياً</div>
                                <p>جرب تغيير معايير البحث أو الفلترة</p>
                            </div>
                        </td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
        
        @if($resources->hasPages())
        <div style="padding: 1.5rem; background: #f8fafc; border-top: 1px solid #f1f5f9;">
            {{ $resources->links() }}
        </div>
        @endif
    </div>
</div>
@endsection

<style>
    .filter-toggle-btn {
        padding: 0.85rem 1.25rem;
        border: 2px solid #f1f5f9;
        border-radius: 15px;
        background: #f8fafc;
        color: var(--text-secondary);
        display: flex;
        align-items: center;
        gap: 0.5rem;
        cursor: pointer;
        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        font-weight: 700;
    }
    .filter-toggle-btn:hover {
        border-color: var(--primary-color);
        background: white;
        color: var(--primary-color);
    }
    .filter-toggle-btn.active {
        background: var(--primary-color);
        border-color: var(--primary-color);
        color: white;
        box-shadow: 0 4px 12px rgba(79, 70, 229, 0.2);
    }
    .icon-toggle {
        transition: transform 0.3s ease;
        display: flex;
        align-items: center;
    }
    .icon-toggle.rotated {
        transform: rotate(180deg);
    }
    
    .bg-indigo-soft { background-color: rgba(79, 70, 229, 0.1); }
    .text-indigo { color: #4f46e5; }
    .bg-teal-soft { background-color: rgba(20, 184, 166, 0.1); }
    .text-teal { color: #14b8a6; }
    .bg-gray-soft { background-color: rgba(107, 114, 128, 0.1); }
    .text-gray { color: #6b7280; }
    .bg-success-soft { background-color: rgba(16, 185, 129, 0.1); }
    .text-success { color: #10b981; }
    .bg-primary-soft { background-color: rgba(59, 130, 246, 0.1); }
    .text-primary { color: #3b82f6; }
    .bg-warning-soft { background-color: rgba(245, 158, 11, 0.1); }
    .text-warning { color: #f59e0b; }
</style>
