@extends('layouts.admin')

@section('title', 'سجل الأنشطة')

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
        background: linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%);
        border-radius: 16px;
        display: flex;
        align-items: center;
        justify-content: center;
        color: white;
        box-shadow: 0 4px 12px -2px rgba(99, 102, 241, 0.4);
    }

    .page-header-text h1 {
        font-size: 1.5rem;
        font-weight: 700;
        color: var(--text-primary);
        margin-bottom: 0.25rem;
    }

    .page-header-text p {
        color: var(--text-secondary);
        font-size: 0.9rem;
    }

    .stats-row {
        display: grid;
        grid-template-columns: repeat(4, 1fr);
        gap: 1rem;
        margin-bottom: 1.5rem;
    }

    .stat-mini {
        background: white;
        border-radius: 12px;
        padding: 1rem 1.25rem;
        border: 1px solid var(--border-color);
        display: flex;
        align-items: center;
        gap: 1rem;
    }

    .stat-mini .icon {
        width: 40px;
        height: 40px;
        border-radius: 10px;
        display: flex;
        align-items: center;
        justify-content: center;
    }

    .stat-mini .value {
        font-size: 1.5rem;
        font-weight: 700;
        line-height: 1;
    }

    .stat-mini .label {
        font-size: 0.8rem;
        color: var(--text-secondary);
    }

    .filter-card {
        background: white;
        border-radius: 16px;
        border: 1px solid var(--border-color);
        padding: 1.25rem;
        margin-bottom: 1.5rem;
    }

    .filter-grid {
        display: grid;
        grid-template-columns: repeat(5, 1fr) auto;
        gap: 1rem;
        align-items: end;
    }

    .filter-group label {
        display: block;
        font-size: 0.8rem;
        color: var(--text-secondary);
        margin-bottom: 0.35rem;
        font-weight: 500;
    }

    .filter-group select,
    .filter-group input {
        width: 100%;
        padding: 0.6rem 0.75rem;
        border: 1px solid var(--border-color);
        border-radius: 8px;
        font-size: 0.9rem;
        background: #fafafa;
    }

    .filter-group select:focus,
    .filter-group input:focus {
        border-color: var(--primary-color);
        outline: none;
        background: white;
    }

    .filter-actions {
        display: flex;
        gap: 0.5rem;
    }

    .btn-filter {
        padding: 0.6rem 1.25rem;
        border: none;
        border-radius: 8px;
        font-weight: 600;
        font-size: 0.9rem;
        cursor: pointer;
        transition: all 0.2s;
    }

    .btn-filter.primary {
        background: linear-gradient(135deg, #6366f1, #8b5cf6);
        color: white;
    }

    .btn-filter.primary:hover {
        box-shadow: 0 4px 12px -2px rgba(99, 102, 241, 0.4);
    }

    .btn-filter.secondary {
        background: #f1f5f9;
        color: var(--text-primary);
    }

    .activities-card {
        background: white;
        border-radius: 20px;
        border: 1px solid var(--border-color);
        overflow: hidden;
    }

    .card-header {
        padding: 1.25rem 1.5rem;
        border-bottom: 1px solid var(--border-color);
        display: flex;
        justify-content: space-between;
        align-items: center;
    }

    .card-header h3 {
        font-size: 1rem;
        font-weight: 700;
        display: flex;
        align-items: center;
        gap: 0.5rem;
    }

    .activity-list {
        max-height: 600px;
        overflow-y: auto;
    }

    .activity-item {
        display: flex;
        align-items: flex-start;
        gap: 1rem;
        padding: 1rem 1.5rem;
        border-bottom: 1px solid #f1f5f9;
        transition: background 0.2s;
    }

    .activity-item:hover {
        background: #fafafa;
    }

    .activity-avatar {
        width: 42px;
        height: 42px;
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: 700;
        font-size: 0.9rem;
        color: white;
        flex-shrink: 0;
    }

    .activity-content {
        flex: 1;
        min-width: 0;
    }

    .activity-header {
        display: flex;
        align-items: center;
        gap: 0.75rem;
        margin-bottom: 0.35rem;
        flex-wrap: wrap;
    }

    .activity-user {
        font-weight: 600;
        color: var(--text-primary);
    }

    .activity-badge {
        padding: 0.2rem 0.6rem;
        border-radius: 20px;
        font-size: 0.7rem;
        font-weight: 600;
    }

    .activity-model {
        padding: 0.2rem 0.5rem;
        background: #f1f5f9;
        border-radius: 6px;
        font-size: 0.75rem;
        font-weight: 500;
        color: var(--text-secondary);
    }

    .activity-desc {
        color: var(--text-secondary);
        font-size: 0.875rem;
        margin-bottom: 0.35rem;
    }

    .activity-meta {
        display: flex;
        align-items: center;
        gap: 0.5rem;
        font-size: 0.75rem;
        color: var(--text-light);
    }

    .activity-time {
        display: flex;
        align-items: center;
        gap: 0.25rem;
    }

    .empty-state {
        text-align: center;
        padding: 4rem 2rem;
        color: var(--text-secondary);
    }

    .empty-state svg {
        margin-bottom: 1rem;
        opacity: 0.5;
    }

    .pagination-wrapper {
        padding: 1rem 1.5rem;
        border-top: 1px solid var(--border-color);
    }
</style>

@php
$totalActivities = \App\Models\ActivityLog::count();
$todayActivities = \App\Models\ActivityLog::whereDate('created_at', today())->count();
$loginCount = \App\Models\ActivityLog::where('action', 'login')->count();
$changeCount = \App\Models\ActivityLog::whereIn('action', ['create', 'update', 'delete'])->count();
@endphp

<!-- Page Header -->
<div class="page-header">
    <div class="page-header-icon">
        <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <polyline points="22 12 18 12 15 21 9 3 6 12 2 12"></polyline>
        </svg>
    </div>
    <div class="page-header-text">
        <h1>سجل الأنشطة</h1>
        <p>تتبع جميع العمليات والإجراءات في النظام</p>
    </div>
</div>

<!-- Stats Row -->
<div class="stats-row">
    <div class="stat-mini">
        <div class="icon" style="background: rgba(99, 102, 241, 0.1); color: #6366f1;">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <polyline points="22 12 18 12 15 21 9 3 6 12 2 12"></polyline>
            </svg>
        </div>
        <div>
            <div class="value" style="color: #6366f1;">{{ number_format($totalActivities) }}</div>
            <div class="label">إجمالي الأنشطة</div>
        </div>
    </div>
    <div class="stat-mini">
        <div class="icon" style="background: rgba(16, 185, 129, 0.1); color: #10b981;">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect>
                <line x1="16" y1="2" x2="16" y2="6"></line>
                <line x1="8" y1="2" x2="8" y2="6"></line>
                <line x1="3" y1="10" x2="21" y2="10"></line>
            </svg>
        </div>
        <div>
            <div class="value" style="color: #10b981;">{{ $todayActivities }}</div>
            <div class="label">أنشطة اليوم</div>
        </div>
    </div>
    <div class="stat-mini">
        <div class="icon" style="background: rgba(139, 92, 246, 0.1); color: #8b5cf6;">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4"></path>
                <polyline points="10 17 15 12 10 7"></polyline>
                <line x1="15" y1="12" x2="3" y2="12"></line>
            </svg>
        </div>
        <div>
            <div class="value" style="color: #8b5cf6;">{{ $loginCount }}</div>
            <div class="label">تسجيلات الدخول</div>
        </div>
    </div>
    <div class="stat-mini">
        <div class="icon" style="background: rgba(245, 158, 11, 0.1); color: #f59e0b;">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
            </svg>
        </div>
        <div>
            <div class="value" style="color: #f59e0b;">{{ $changeCount }}</div>
            <div class="label">تغييرات البيانات</div>
        </div>
    </div>
</div>

<!-- Filters -->
<div class="filter-card">
    <form action="{{ route('admin.activities.index') }}" method="GET" class="filter-grid">
        <div class="filter-group">
            <label>المستخدم</label>
            <select name="user_id">
                <option value="">الكل</option>
                @foreach($users as $user)
                <option value="{{ $user->id }}" {{ request('user_id') == $user->id ? 'selected' : '' }}>{{ $user->name }}</option>
                @endforeach
            </select>
        </div>
        <div class="filter-group">
            <label>نوع العملية</label>
            <select name="action">
                <option value="">الكل</option>
                @foreach($actions as $action)
                <option value="{{ $action }}" {{ request('action') == $action ? 'selected' : '' }}>{{ $action }}</option>
                @endforeach
            </select>
        </div>
        <div class="filter-group">
            <label>نوع البيانات</label>
            <select name="model_type">
                <option value="">الكل</option>
                @foreach($modelTypes as $type)
                <option value="{{ $type }}" {{ request('model_type') == $type ? 'selected' : '' }}>{{ $type }}</option>
                @endforeach
            </select>
        </div>
        <div class="filter-group">
            <label>من تاريخ</label>
            <input type="date" name="date_from" value="{{ request('date_from') }}">
        </div>
        <div class="filter-group">
            <label>إلى تاريخ</label>
            <input type="date" name="date_to" value="{{ request('date_to') }}">
        </div>
        <div class="filter-actions">
            <button type="submit" class="btn-filter primary">تصفية</button>
            <a href="{{ route('admin.activities.index') }}" class="btn-filter secondary">مسح</a>
        </div>
    </form>
</div>

@if(session('success'))
<div class="alert alert-success" style="margin-bottom: 1rem;">
    {{ session('success') }}
</div>
@endif

<!-- Activities List -->
<div class="activities-card">
    <div class="card-header">
        <h3>
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                <polyline points="14 2 14 8 20 8"></polyline>
            </svg>
            السجلات ({{ $activities->total() }})
        </h3>
    </div>

    <div class="activity-list">
        @forelse($activities as $activity)
        @php
        $avatarColors = ['#6366f1', '#8b5cf6', '#10b981', '#f59e0b', '#ef4444', '#3b82f6', '#06b6d4'];
        $avatarColor = $avatarColors[($activity->user_id ?? 0) % count($avatarColors)];
        @endphp
        <div class="activity-item">
            <div class="activity-avatar" style="background: {{ $avatarColor }};">
                {{ mb_substr($activity->user_name, 0, 1) }}
            </div>
            <div class="activity-content">
                <div class="activity-header">
                    <span class="activity-user">{{ $activity->user_name }}</span>
                    <span class="activity-badge" style="background: {{ $activity->action_color }}20; color: {{ $activity->action_color }};">
                        {{ $activity->action_label }}
                    </span>
                    @if($activity->model_type)
                    <span class="activity-model">{{ $activity->model_type_label }}</span>
                    @endif
                </div>
                @if($activity->description)
                <div class="activity-desc">{{ $activity->description }}</div>
                @endif
                <div class="activity-meta">
                    <span class="activity-time">
                        <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <circle cx="12" cy="12" r="10"></circle>
                            <polyline points="12 6 12 12 16 14"></polyline>
                        </svg>
                        {{ $activity->created_at->diffForHumans() }}
                    </span>
                    @if($activity->model_name)
                    <span>•</span>
                    <span>{{ $activity->model_name }}</span>
                    @endif
                </div>
            </div>
        </div>
        @empty
        <div class="empty-state">
            <svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1">
                <polyline points="22 12 18 12 15 21 9 3 6 12 2 12"></polyline>
            </svg>
            <h3>لا توجد سجلات أنشطة</h3>
            <p>سيتم تسجيل الأنشطة تلقائياً عند إجراء أي عملية في النظام</p>
        </div>
        @endforelse
    </div>

    @if($activities->hasPages())
    <div class="pagination-wrapper">
        {{ $activities->withQueryString()->links('pagination::bootstrap-5') }}
    </div>
    @endif
</div>

@endsection