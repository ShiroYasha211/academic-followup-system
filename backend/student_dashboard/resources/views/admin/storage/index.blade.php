@extends('layouts.admin')

@section('title', 'إدارة المساحة والتخزين')

@section('content')

<style>
    .storage-card {
        background: white;
        border-radius: 20px;
        padding: 1.5rem;
        box-shadow: var(--shadow-sm);
        border: 1px solid #f1f5f9;
        transition: transform 0.2s, box-shadow 0.2s;
    }
    .storage-card:hover {
        transform: translateY(-2px);
        box-shadow: var(--shadow-md);
    }
    .file-icon {
        width: 44px;
        height: 44px;
        border-radius: 12px;
        display: flex;
        align-items: center;
        justify-content: center;
    }
    .badge-role {
        font-size: 0.75rem;
        padding: 0.15rem 0.6rem;
        border-radius: 50px;
        font-weight: 700;
    }
    .role-doctor { background: #fef3c7; color: #92400e; }
    .role-delegate { background: #dcfce7; color: #166534; }
    .role-student { background: #f1f5f9; color: #475569; }
    .role-admin { background: #fee2e2; color: #991b1b; }
</style>

<!-- Page Header -->
<div class="d-flex align-items-center gap-3 mb-4">
    <div style="width: 56px; height: 56px; background: linear-gradient(135deg, #0ea5e9 0%, #2563eb 100%); border-radius: 16px; display: flex; align-items: center; justify-content: center; color: white; box-shadow: 0 4px 12px rgba(37, 99, 235, 0.2);">
        <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
            <polyline points="7 10 12 15 17 10"></polyline>
            <line x1="12" y1="15" x2="12" y2="3"></line>
        </svg>
    </div>
    <div>
        <h1 style="font-size: 1.5rem; font-weight: 800; color: var(--text-primary); margin: 0;">إدارة مساحة التخزين</h1>
        <p style="color: var(--text-secondary); margin: 0; font-size: 0.9rem;">مراقبة وتحليل استخدام الملفات في النظام بالكامل</p>
    </div>
</div>

<!-- Stats Row -->
<div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 1.5rem; margin-bottom: 2rem;">
    <!-- Total Usage -->
    <div class="storage-card" style="border-right: 4px solid #2563eb; background: linear-gradient(to left, #f8fafc, white);">
        <div style="color: #64748b; font-size: 0.85rem; font-weight: 600; margin-bottom: 0.5rem;">إجمالي المساحة المستهلكة</div>
        <div style="font-size: 2.2rem; font-weight: 800; color: #1e3a8a;">{{ $stats['total_size'] }}</div>
        <div style="color: #94a3b8; font-size: 0.8rem; margin-top: 0.25rem;">إجمالي {{ $stats['total_count'] }} ملف في النظام</div>
    </div>

    @foreach($stats['by_type'] as $type => $count)
    <div class="storage-card">
        <div style="display: flex; justify-content: space-between; align-items: flex-start;">
            <div>
                <div style="color: #64748b; font-size: 0.85rem; font-weight: 600;">
                    @if($type == 'resource') مصادر تعليمية
                    @elseif($type == 'submission') تسليمات الطلاب
                    @elseif($type == 'excuse') أعذار طبية
                    @else إعلانات ومرفقات @endif
                </div>
                <div style="font-size: 1.8rem; font-weight: 800; color: var(--text-primary); margin-top: 0.25rem;">{{ $count }}</div>
            </div>
            <div style="width: 40px; height: 40px; background: #f8fafc; border-radius: 10px; display: flex; align-items: center; justify-content: center; color: #94a3b8;">
                @if($type == 'resource') <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"/><path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"/></svg>
                @elseif($type == 'submission') <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 10v6M2 10v6M12 15a4 4 0 1 0 0-8 4 4 0 0 0 0 8z"/><path d="M6 15v-2a6 6 0 1 1 12 0v2"/></svg>
                @elseif($type == 'excuse') <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/></svg>
                @else <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="18" height="18" rx="2" ry="2"/><line x1="15" y1="3" x2="15" y2="21"/></svg> @endif
            </div>
        </div>
    </div>
    @endforeach
</div>

<!-- Main Content Area -->
<div class="card shadow-sm border-0" style="border-radius: 20px; overflow: hidden;">
    <div class="card-header bg-white border-bottom py-3 px-4">
        <div class="d-flex justify-content-between align-items-center flex-wrap gap-3">
            <h5 class="fw-bold m-0" style="color: var(--text-primary);">مستكشف الملفات التقني</h5>
            
            <form action="{{ route('admin.storage.index') }}" method="GET" class="d-flex gap-2">
                <div style="position: relative;">
                    <input type="text" name="search" value="{{ request('search') }}" placeholder="ابحث باسم الملف أو الناشر..." style="height: 40px; border-radius: 10px; border: 1px solid #e2e8f0; padding: 0 1rem 0 2.5rem; font-size: 0.9rem; width: 250px;">
                    <svg style="position: absolute; left: 12px; top: 10px; color: #94a3b8;" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg>
                </div>
                <select name="type" style="height: 40px; border-radius: 10px; border: 1px solid #e2e8f0; padding: 0 0.75rem; font-size: 0.85rem; font-weight: 600;">
                    <option value="">كل الأنواع</option>
                    <option value="resource" {{ request('type') == 'resource' ? 'selected' : '' }}>مصادر تعليمية</option>
                    <option value="submission" {{ request('type') == 'submission' ? 'selected' : '' }}>تسليمات طلاب</option>
                    <option value="excuse" {{ request('type') == 'excuse' ? 'selected' : '' }}>أعذار طبية</option>
                    <option value="announcement" {{ request('type') == 'announcement' ? 'selected' : '' }}>إعلانات</option>
                </select>
                <button type="submit" class="btn btn-primary px-4" style="border-radius: 10px;">فلترة</button>
            </form>
        </div>
    </div>

    <div class="table-responsive">
        <table class="table table-hover align-middle mb-0" style="min-width: 1000px;">
            <thead class="bg-light">
                <tr>
                    <th style="padding: 1rem 1.5rem; border: none; font-size: 0.85rem; color: #64748b;">الملف</th>
                    <th style="padding: 1rem 1.5rem; border: none; font-size: 0.85rem; color: #64748b;">الناشر</th>
                    <th style="padding: 1rem 1.5rem; border: none; font-size: 0.85rem; color: #64748b;">التصنيف</th>
                    <th style="padding: 1rem 1.5rem; border: none; font-size: 0.85rem; color: #64748b;">المساحة</th>
                    <th style="padding: 1rem 1.5rem; border: none; font-size: 0.85rem; color: #64748b;">تاريخ الرفع</th>
                    <th style="padding: 1rem 1.5rem; border: none; font-size: 0.85rem; color: #64748b; text-align: left;">الإجراءات</th>
                </tr>
            </thead>
            <tbody>
                @forelse($paginatedItems as $item)
                <tr>
                    <td style="padding: 1rem 1.5rem;">
                        <div class="d-flex align-items: center; gap: 0.75rem;">
                            @php
                                $ext = strtolower($item['file_ext']);
                                $color = '#64748b';
                                if($ext == 'pdf') $color = '#ef4444';
                                elseif(in_array($ext, ['pptx','ppt'])) $color = '#f59e0b';
                                elseif(in_array($ext, ['docx','doc'])) $color = '#3b82f6';
                                elseif(in_array($ext, ['xlsx','xls'])) $color = '#10b981';
                            @endphp
                            <div class="file-icon" style="background: {{ $color }}15; color: {{ $color }};">
                                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M13 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9z"/><polyline points="13 2 13 9 20 9"/></svg>
                            </div>
                            <div>
                                <div class="fw-bold text-dark" style="font-size: 0.95rem;">{{ $item['title'] }}</div>
                                <div class="small text-muted">{{ strtoupper($item['file_ext']) ?: 'FILE' }}</div>
                            </div>
                        </div>
                    </td>
                    <td style="padding: 1rem 1.5rem;">
                        <div class="fw-semibold text-dark">{{ $item['uploader_name'] }}</div>
                        <span class="badge-role role-{{ $item['uploader_role'] }}">
                            @if($item['uploader_role'] == 'doctor') دكتور
                            @elseif($item['uploader_role'] == 'delegate' || $item['uploader_role'] == 'practical_delegate') مندوب
                            @elseif($item['uploader_role'] == 'admin') مسؤول
                            @else طالب @endif
                        </span>
                    </td>
                    <td style="padding: 1rem 1.5rem;">
                        <span class="badge bg-light text-dark fw-bold px-3 py-2 rounded-pill border">
                            {{ $item['type_label'] }}
                        </span>
                    </td>
                    <td style="padding: 1rem 1.5rem;">
                        <div class="fw-bold" style="color: {{ $item['size_bytes'] > 5000000 ? '#dc2626' : '#1e293b' }};">
                            {{ $item['size_formatted'] }}
                        </div>
                    </td>
                    <td style="padding: 1rem 1.5rem;" class="small text-muted fw-semibold">
                        {{ $item['date']->format('Y/m/d H:i') }}
                    </td>
                    <td style="padding: 1rem 1.5rem; text-align: left;">
                        <div class="d-flex justify-content-end gap-2">
                            <a href="{{ $item['url'] }}" target="_blank" class="btn btn-sm btn-light p-2" style="border-radius: 8px; border: 1px solid #e2e8f0;" title="معاينة الملف">
                                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#64748b" stroke-width="2.5"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                            </a>
                            <form action="{{ route('admin.storage.destroy', ['type' => $item['type'], 'id' => $item['id']]) }}" method="POST" onsubmit="return confirm('هل أنت متأكد من حذف هذا الملف نهائياً؟ سيؤدي ذلك لتوفير مساحة على الخادم.')">
                                @csrf @method('DELETE')
                                <button type="submit" class="btn btn-sm btn-light p-2 text-danger" style="border-radius: 8px; border: 1px solid #fee2e2; background: #fff1f2;" title="حذف الملف">
                                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M3 6h18m-2 0v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2M10 11v6m4-6v6"/></svg>
                                </button>
                            </form>
                        </div>
                    </td>
                </tr>
                @empty
                <tr>
                    <td colspan="6" class="text-center py-5">
                        <div style="color: #94a3b8; font-size: 1.1rem; font-weight: 600;">لا توجد ملفات حالياً مطابق للبحث</div>
                    </td>
                </tr>
                @endforelse
            </tbody>
        </table>
    </div>

    @if($paginatedItems->hasPages())
    <div class="card-footer bg-white border-top py-3">
        {{ $paginatedItems->links() }}
    </div>
    @endif
</div>

@endsection
