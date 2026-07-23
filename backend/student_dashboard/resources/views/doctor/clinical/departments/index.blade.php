@extends('layouts.doctor')

@section('title', 'إدارة الأقسام الطبية')

@section('content')
<style>
    .clinical-page-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 1.75rem;
        flex-wrap: wrap;
        gap: 1rem;
    }

    .clinical-page-header .right-side h1 {
        font-size: 1.6rem;
        font-weight: 800;
        color: var(--text-primary);
        margin: 0 0 0.15rem 0;
    }

    .clinical-page-header .right-side p {
        color: var(--text-secondary);
        font-size: 0.9rem;
        margin: 0;
    }

    .clinical-page-header .left-side {
        display: flex;
        gap: 0.75rem;
        align-items: center;
    }

    .btn-back {
        background: white;
        color: var(--text-secondary);
        border: 1.5px solid #e2e8f0;
        padding: 0.55rem 1.1rem;
        border-radius: 10px;
        font-weight: 600;
        font-size: 0.88rem;
        cursor: pointer;
        transition: all 0.2s;
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
        text-decoration: none;
    }

    .btn-back:hover {
        border-color: #cbd5e1;
        background: #f8fafc;
        color: var(--text-primary);
        text-decoration: none;
    }

    .btn-primary-action {
        background: linear-gradient(135deg, #4f46e5, #6366f1);
        color: white;
        border: none;
        padding: 0.6rem 1.3rem;
        border-radius: 10px;
        font-weight: 600;
        font-size: 0.88rem;
        cursor: pointer;
        transition: all 0.25s;
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
        text-decoration: none;
        box-shadow: 0 2px 8px rgba(79, 70, 229, 0.25);
    }

    .btn-primary-action:hover {
        transform: translateY(-1px);
        box-shadow: 0 4px 14px rgba(79, 70, 229, 0.35);
        color: white;
        text-decoration: none;
    }

    .card-section {
        background: white;
        border-radius: 18px;
        border: 1px solid #e2e8f0;
        padding: 1.5rem;
    }

    .filter-bar {
        background: linear-gradient(135deg, #f8fafc, #f1f5f9);
        padding: 1rem 1.25rem;
        border-radius: 14px;
        border: 1px solid #e2e8f0;
        margin-bottom: 1.5rem;
        display: flex;
        gap: 0.85rem;
        align-items: center;
        flex-wrap: wrap;
    }

    .filter-bar input {
        flex: 1;
        min-width: 200px;
        padding: 0.55rem 0.75rem;
        font-size: 0.88rem;
        border: 1.5px solid #e2e8f0;
        border-radius: 9px;
        background: white;
        transition: all 0.2s;
        font-family: inherit;
    }

    .filter-bar input:focus {
        outline: none;
        border-color: var(--primary-color);
        box-shadow: 0 0 0 3px rgba(79, 70, 229, 0.08);
    }

    .btn-filter {
        background: var(--primary-color);
        color: white;
        border: none;
        padding: 0.55rem 1.25rem;
        border-radius: 9px;
        font-weight: 600;
        font-size: 0.85rem;
        cursor: pointer;
        transition: all 0.2s;
    }

    .btn-filter:hover {
        background: #4338ca;
    }

    .btn-filter-reset {
        background: white;
        color: #64748b;
        border: 1.5px solid #e2e8f0;
        padding: 0.55rem 1rem;
        border-radius: 9px;
        font-weight: 600;
        font-size: 0.85rem;
        text-decoration: none;
        transition: all 0.2s;
    }

    .btn-filter-reset:hover {
        background: #f8fafc;
        border-color: #cbd5e1;
        color: var(--text-primary);
        text-decoration: none;
    }

    .section-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 1.25rem;
        padding-bottom: 0.75rem;
        border-bottom: 1px solid #f1f5f9;
    }

    .section-title {
        font-size: 1rem;
        font-weight: 700;
        color: var(--text-primary);
        display: flex;
        align-items: center;
        gap: 0.5rem;
    }

    .table-modern {
        width: 100%;
        border-collapse: separate;
        border-spacing: 0;
    }

    .table-modern th {
        background: #f8fafc;
        font-weight: 600;
        color: var(--text-secondary);
        padding: 0.85rem 1rem;
        text-align: right;
        font-size: 0.82rem;
        border-bottom: 2px solid #e2e8f0;
    }

    .table-modern td {
        padding: 0.85rem 1rem;
        vertical-align: middle;
        border-bottom: 1px solid #f1f5f9;
        font-size: 0.9rem;
        color: var(--text-primary);
    }

    .table-modern tr:hover td {
        background: #fafbfe;
    }

    .table-modern tr:last-child td {
        border-bottom: none;
    }

    .name-text {
        font-weight: 700;
        color: var(--text-primary);
    }

    .action-btn {
        width: 32px;
        height: 32px;
        border-radius: 8px;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        border: none;
        cursor: pointer;
        transition: all 0.2s;
        margin-left: 0.2rem;
        text-decoration: none;
    }

    .action-btn.edit {
        background: #eff6ff;
        color: #3b82f6;
    }

    .action-btn.edit:hover {
        background: #dbeafe;
        color: #2563eb;
    }

    .action-btn.delete {
        background: #fef2f2;
        color: #ef4444;
    }

    .action-btn.delete:hover {
        background: #fee2e2;
        color: #dc2626;
    }

    .alert-banner {
        padding: 0.85rem 1.25rem;
        border-radius: 12px;
        margin-bottom: 1.5rem;
        font-weight: 600;
        font-size: 0.9rem;
    }

    .alert-banner.success {
        background: #d1fae5;
        color: #065f46;
        border: 1px solid #6ee7b7;
    }

    .alert-banner.danger {
        background: #fee2e2;
        color: #991b1b;
        border: 1px solid #fca5a5;
    }
</style>

<div class="clinical-page-header">
    <div class="right-side">
        <h1>إدارة الأقسام الطبية 🏥</h1>
        <p>إضافة وتعديل الأقسام الطبية السريرية (باطنة، جراحة، أطفال...)</p>
    </div>
    <div class="left-side">
        <form action="{{ route('doctor.clinical.departments.restore') }}" method="POST" style="display: inline;" onsubmit="return confirm('هل أنت متأكد من رغبتك في استرداد الأقسام الأساسية المخفية؟');">
            @csrf
            <button type="submit" class="btn-primary-action" style="background: linear-gradient(135deg, #10b981, #059669);">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                    <path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"></path>
                    <polyline points="3 3 3 8 8 8"></polyline>
                </svg>
                استرداد الثوابت
            </button>
        </form>
        <a href="{{ route('doctor.clinical.departments.create') }}" class="btn-primary-action">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                <line x1="12" y1="5" x2="12" y2="19"></line>
                <line x1="5" y1="12" x2="19" y2="12"></line>
            </svg>
            إضافة قسم طبي
        </a>
        <a href="{{ route('doctor.clinical.index') }}" class="btn-back">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <polyline points="15 18 9 12 15 6"></polyline>
            </svg>
            القسم العملي
        </a>
    </div>
</div>

@if(session('success'))<div class="alert-banner success">✅ {{ session('success') }}</div>@endif
@if(session('error'))<div class="alert-banner danger">⚠️ {{ session('error') }}</div>@endif

<form action="{{ route('doctor.clinical.departments.index') }}" method="GET" class="filter-bar">
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2">
        <circle cx="11" cy="11" r="8"></circle>
        <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
    </svg>
    <input type="text" name="search" value="{{ request('search') }}" placeholder="ابحث باسم القسم الطبي...">
    <button type="submit" class="btn-filter">بحث</button>
    @if(request('search'))<a href="{{ route('doctor.clinical.departments.index') }}" class="btn-filter-reset">إلغاء</a>@endif
</form>

<div class="card-section">
    <div class="section-header">
        <h3 class="section-title">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="color: var(--primary-color);">
                <path d="M22 12h-4l-3 9L9 3l-3 9H2"></path>
            </svg>
            قائمة الأقسام الطبية
        </h3>
    </div>
    <div style="overflow-x: auto;">
        <div class="table-responsive">
<table class="table-modern">
            <thead>
                <tr>
                    <th width="5%">#</th>
                    <th width="30%">اسم القسم الطبي</th>
                    <th width="45%">الوصف</th>
                    <th width="20%" style="text-align:center;">إجراءات</th>
                </tr>
            </thead>
            <tbody>
                @forelse($departments as $index => $department)
                <tr>
                    <td>{{ $index + 1 }}</td>
                    <td class="name-text">
                        {{ $department->name }}
                        @if(is_null($department->doctor_id))
                            <span style="background: #e0e7ff; color: #4338ca; padding: 0.2rem 0.5rem; border-radius: 6px; font-size: 0.75rem; margin-right: 0.5rem; font-weight: 700;">أساسي</span>
                        @endif
                    </td>
                    <td style="color: var(--text-secondary); font-size: 0.85rem;">{{ Str::limit($department->description, 60) ?? '-' }}</td>
                    <td style="text-align: center;">
                        <a href="{{ route('doctor.clinical.departments.edit', $department->id) }}" class="action-btn edit" title="تعديل">
                            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                                <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                            </svg>
                        </a>
                        <form action="{{ route('doctor.clinical.departments.destroy', $department->id) }}" method="POST" style="display:inline;" onsubmit="return confirm('هل أنت متأكد من مسح هذا القسم؟')">
                            @csrf @method('DELETE')
                            <button type="submit" class="action-btn delete" title="مسح"><svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <polyline points="3 6 5 6 21 6"></polyline>
                                    <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
                                </svg></button>
                        </form>
                    </td>
                </tr>
                @empty
                <tr>
                    <td colspan="4" style="text-align:center; color:var(--text-secondary); padding:3rem 1rem;">
                        <p>لا يوجد أقسام طبية مضافة حالياً.</p>
                    </td>
                </tr>
                @endforelse
            </tbody>
        </table>
</div>
    </div>
    @if($departments->hasPages())<div style="margin-top:1.5rem;">{{ $departments->links() }}</div>@endif
</div>
@endsection