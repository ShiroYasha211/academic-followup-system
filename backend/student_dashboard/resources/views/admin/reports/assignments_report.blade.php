@extends('layouts.admin')

@section('title', 'تقرير التكاليف والواجبات')

@section('content')

<style>
    .page-header {
        display: flex;
        align-items: center;
        gap: 1rem;
        margin-bottom: 2rem;
    }

    .page-header-icon {
        width: 56px;
        height: 56px;
        background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
        border-radius: 16px;
        display: flex;
        align-items: center;
        justify-content: center;
        color: white;
    }

    .page-header-text h1 {
        font-size: 1.5rem;
        font-weight: 700;
        margin-bottom: 0.25rem;
    }

    .page-header-text p {
        color: var(--text-secondary);
        font-size: 0.9rem;
    }

    .stats-grid {
        display: grid;
        grid-template-columns: repeat(4, 1fr);
        gap: 1rem;
        margin-bottom: 2rem;
    }

    .stat-card {
        background: white;
        border-radius: 16px;
        padding: 1.25rem;
        border: 1px solid var(--border-color);
        text-align: center;
    }

    .stat-card .value {
        font-size: 2rem;
        font-weight: 700;
        margin-bottom: 0.25rem;
    }

    .stat-card .label {
        color: var(--text-secondary);
        font-size: 0.85rem;
    }

    .table-card {
        background: white;
        border-radius: 20px;
        border: 1px solid var(--border-color);
        padding: 1.5rem;
    }

    .table-card h3 {
        font-size: 1.1rem;
        font-weight: 700;
        margin-bottom: 1rem;
        display: flex;
        align-items: center;
        gap: 0.5rem;
    }

    .modern-table {
        width: 100%;
        border-collapse: separate;
        border-spacing: 0;
    }

    .modern-table thead th {
        background: #f8fafc;
        padding: 1rem;
        text-align: right;
        font-weight: 600;
        color: var(--text-secondary);
        font-size: 0.85rem;
        border-bottom: 1px solid var(--border-color);
    }

    .modern-table tbody td {
        padding: 1rem;
        border-bottom: 1px solid #f1f5f9;
        vertical-align: middle;
    }

    .modern-table tbody tr:hover {
        background: #fafafa;
    }

    .status-badge {
        padding: 0.35rem 0.75rem;
        border-radius: 20px;
        font-size: 0.75rem;
        font-weight: 600;
    }

    .status-badge.active {
        background: #d1fae5;
        color: #059669;
    }

    .status-badge.expired {
        background: #fee2e2;
        color: #dc2626;
    }

    .back-btn {
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
        padding: 0.75rem 1.25rem;
        background: #f3f4f6;
        border-radius: 10px;
        color: var(--text-primary);
        text-decoration: none;
        font-weight: 600;
        transition: all 0.2s;
    }

    .back-btn:hover {
        background: #e5e7eb;
    }
</style>

<!-- Page Header -->
<div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 2rem;">
    <div class="page-header" style="margin: 0;">
        <div class="page-header-icon">
            <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                <polyline points="14 2 14 8 20 8"></polyline>
                <line x1="12" y1="18" x2="12" y2="12"></line>
                <line x1="9" y1="15" x2="15" y2="15"></line>
            </svg>
        </div>
        <div class="page-header-text">
            <h1>تقرير التكاليف والواجبات</h1>
            <p>نظرة شاملة على التكاليف المنشأة وحالة التسليمات</p>
        </div>
    </div>
    <a href="{{ route('admin.reports.index') }}" class="back-btn">
        <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <line x1="19" y1="12" x2="5" y2="12"></line>
            <polyline points="12 19 5 12 12 5"></polyline>
        </svg>
        رجوع للتقارير
    </a>
</div>

<!-- Stats Grid -->
<div class="stats-grid">
    <div class="stat-card">
        <div class="value" style="color: #f59e0b;">{{ $stats['total'] }}</div>
        <div class="label">إجمالي التكاليف</div>
    </div>
    <div class="stat-card">
        <div class="value" style="color: #10b981;">{{ $stats['active'] }}</div>
        <div class="label">تكاليف جارية</div>
    </div>
    <div class="stat-card">
        <div class="value" style="color: #ef4444;">{{ $stats['expired'] }}</div>
        <div class="label">تكاليف منتهية</div>
    </div>
    <div class="stat-card">
        <div class="value" style="color: #3b82f6;">{{ $stats['with_submissions'] }}</div>
        <div class="label">بها تسليمات</div>
    </div>
</div>

<!-- Table Card -->
<div class="table-card">
    <h3>
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
            <polyline points="14 2 14 8 20 8"></polyline>
        </svg>
        قائمة التكاليف
    </h3>

    <div class="table-responsive">
<table class="modern-table">
        <thead>
            <tr>
                <th>#</th>
                <th>عنوان التكليف</th>
                <th>المادة</th>
                <th>الدكتور</th>
                <th>موعد التسليم</th>
                <th>عدد التسليمات</th>
                <th>الحالة</th>
            </tr>
        </thead>
        <tbody>
            @forelse($assignments as $assignment)
            <tr>
                <td style="color: var(--text-secondary); font-weight: 600;">{{ $loop->iteration }}</td>
                <td style="font-weight: 600;">{{ $assignment->title }}</td>
                <td>{{ $assignment->subject->name ?? '-' }}</td>
                <td>{{ $assignment->subject->doctor->name ?? 'غير محدد' }}</td>
                <td>{{ $assignment->due_date ? $assignment->due_date->format('Y/m/d') : '-' }}</td>
                <td>
                    <span style="background: #eff6ff; color: #3b82f6; padding: 0.25rem 0.5rem; border-radius: 6px; font-weight: 600;">
                        {{ $assignment->submissions->count() }}
                    </span>
                </td>
                <td>
                    @if($assignment->due_date && $assignment->due_date >= now())
                    <span class="status-badge active">جاري</span>
                    @else
                    <span class="status-badge expired">منتهي</span>
                    @endif
                </td>
            </tr>
            @empty
            <tr>
                <td colspan="7" style="text-align: center; padding: 3rem; color: var(--text-secondary);">
                    <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="#e2e8f0" stroke-width="1.5" style="margin-bottom: 1rem;">
                        <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                        <polyline points="14 2 14 8 20 8"></polyline>
                    </svg>
                    <div>لا توجد تكاليف مسجلة</div>
                </td>
            </tr>
            @endforelse
        </tbody>
    </table>
</div>
</div>

@endsection