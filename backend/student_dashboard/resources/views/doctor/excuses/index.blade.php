@extends('layouts.doctor')

@section('title', 'أعذار الغياب')

@section('content')

<style>
    .page-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 2rem;
    }

    .page-title {
        font-size: 1.75rem;
        font-weight: 800;
        color: var(--text-primary);
        display: flex;
        align-items: center;
        gap: 0.75rem;
    }

    .stats-row {
        display: flex;
        gap: 1rem;
        margin-bottom: 2rem;
        flex-wrap: wrap;
    }

    .stat-badge {
        padding: 0.6rem 1.25rem;
        border-radius: 12px;
        font-weight: 700;
        font-size: 0.9rem;
        display: flex;
        align-items: center;
        gap: 0.5rem;
        text-decoration: none;
        transition: all 0.2s;
    }

    .stat-badge.all {
        background: #f1f5f9;
        color: var(--text-primary);
    }

    .stat-badge.all.active {
        background: var(--text-primary);
        color: white;
    }

    .stat-badge.pending {
        background: #fef3c7;
        color: #92400e;
    }

    .stat-badge.accepted {
        background: #d1fae5;
        color: #065f46;
    }

    .stat-badge.rejected {
        background: #fee2e2;
        color: #991b1b;
    }

    .stat-badge:hover,
    .stat-badge.active:not(.all):not(.pending):not(.accepted):not(.rejected) {
        transform: scale(1.05);
        box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
    }

    .stat-badge.pending.active {
        background: #d97706;
        color: white;
    }

    .stat-badge.accepted.active {
        background: #059669;
        color: white;
    }

    .stat-badge.rejected.active {
        background: #dc2626;
        color: white;
    }

    .excuses-list {
        display: flex;
        flex-direction: column;
        gap: 1rem;
    }

    .excuse-card {
        background: white;
        border-radius: 16px;
        border: 1px solid #e2e8f0;
        padding: 1.5rem;
        transition: all 0.2s;
    }

    .excuse-card:hover {
        border-color: var(--primary-color);
        box-shadow: 0 4px 12px -4px rgba(79, 70, 229, 0.15);
    }

    .excuse-header {
        display: flex;
        justify-content: space-between;
        align-items: flex-start;
        margin-bottom: 1rem;
    }

    .student-info {
        display: flex;
        align-items: center;
        gap: 0.75rem;
    }

    .student-avatar {
        width: 44px;
        height: 44px;
        border-radius: 12px;
        background: linear-gradient(135deg, #e0e7ff 0%, #c7d2fe 100%);
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: 700;
        color: #4f46e5;
    }

    .student-name {
        font-weight: 700;
        color: var(--text-primary);
    }

    .student-meta {
        font-size: 0.85rem;
        color: var(--text-secondary);
    }

    .excuse-status {
        font-size: 0.8rem;
        padding: 0.35rem 0.75rem;
        border-radius: 8px;
        font-weight: 700;
    }

    .excuse-status.pending {
        background: #fef3c7;
        color: #92400e;
    }

    .excuse-status.accepted {
        background: #d1fae5;
        color: #065f46;
    }

    .excuse-status.rejected {
        background: #fee2e2;
        color: #991b1b;
    }

    .excuse-content {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
        gap: 1rem;
        margin-bottom: 1rem;
        padding: 1rem;
        background: #f8fafc;
        border-radius: 12px;
    }

    .excuse-field {
        display: flex;
        flex-direction: column;
        gap: 0.25rem;
    }

    .field-label {
        font-size: 0.75rem;
        font-weight: 600;
        color: var(--text-secondary);
        text-transform: uppercase;
        letter-spacing: 0.05em;
    }

    .field-value {
        font-weight: 600;
        color: var(--text-primary);
    }

    .excuse-reason {
        padding: 1rem;
        background: #fffbeb;
        border-radius: 12px;
        border-right: 4px solid #f59e0b;
        margin-bottom: 1rem;
    }

    .reason-label {
        font-size: 0.75rem;
        font-weight: 600;
        color: #92400e;
        margin-bottom: 0.5rem;
        display: flex;
        align-items: center;
        gap: 0.35rem;
    }

    .excuse-actions {
        display: flex;
        gap: 0.75rem;
        align-items: center;
    }

    .btn-accept {
        padding: 0.6rem 1.25rem;
        background: linear-gradient(135deg, #10b981 0%, #059669 100%);
        color: white;
        border: none;
        border-radius: 10px;
        font-weight: 600;
        cursor: pointer;
        display: flex;
        align-items: center;
        gap: 0.35rem;
    }

    .btn-accept:hover {
        box-shadow: 0 4px 12px -2px rgba(16, 185, 129, 0.4);
    }

    .btn-reject {
        padding: 0.6rem 1.25rem;
        background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%);
        color: white;
        border: none;
        border-radius: 10px;
        font-weight: 600;
        cursor: pointer;
        display: flex;
        align-items: center;
        gap: 0.35rem;
    }

    .btn-reject:hover {
        box-shadow: 0 4px 12px -2px rgba(239, 68, 68, 0.4);
    }

    .btn-attachment {
        padding: 0.6rem 1.25rem;
        background: #e0e7ff;
        color: #4f46e5;
        border: none;
        border-radius: 10px;
        font-weight: 600;
        text-decoration: none;
        display: flex;
        align-items: center;
        gap: 0.35rem;
    }

    .empty-state {
        text-align: center;
        padding: 4rem 2rem;
        background: white;
        border-radius: 20px;
        border: 1px solid #e2e8f0;
    }
</style>

<div class="page-header">
    <h1 class="page-title">
        <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="color: var(--warning-color);">
            <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
            <polyline points="14 2 14 8 20 8"></polyline>
        </svg>
        أعذار الغياب
    </h1>
</div>

<!-- Filters -->
<div style="background: white; padding: 1.25rem; border-radius: 16px; border: 1px solid #e2e8f0; margin-bottom: 2rem; display: flex; flex-wrap: wrap; gap: 1rem; align-items: center; justify-content: space-between;">
    <div class="stats-row" style="margin-bottom: 0;">
        <a href="{{ route('doctor.excuses.index', ['status' => 'all', 'subject' => $subjectId, 'search' => $search]) }}" class="stat-badge all {{ $status == 'all' ? 'active' : '' }}">
            <span>الكل</span>
            <strong>{{ $stats['all'] }}</strong>
        </a>
        <a href="{{ route('doctor.excuses.index', ['status' => 'pending', 'subject' => $subjectId, 'search' => $search]) }}" class="stat-badge pending {{ $status == 'pending' ? 'active' : '' }}">
            <span>معلق</span>
            <strong>{{ $stats['pending'] }}</strong>
        </a>
        <a href="{{ route('doctor.excuses.index', ['status' => 'accepted', 'subject' => $subjectId, 'search' => $search]) }}" class="stat-badge accepted {{ $status == 'accepted' ? 'active' : '' }}">
            <span>مقبول</span>
            <strong>{{ $stats['accepted'] }}</strong>
        </a>
        <a href="{{ route('doctor.excuses.index', ['status' => 'rejected', 'subject' => $subjectId, 'search' => $search]) }}" class="stat-badge rejected {{ $status == 'rejected' ? 'active' : '' }}">
            <span>مرفوض</span>
            <strong>{{ $stats['rejected'] }}</strong>
        </a>
    </div>

    <form method="GET" style="display: flex; gap: 0.75rem; flex-wrap: wrap;">
        <input type="hidden" name="status" value="{{ $status }}">
        <select name="subject" onchange="this.form.submit()" style="padding: 0.6rem 1rem; border: 1px solid #e2e8f0; border-radius: 10px; background: white; font-weight: 600; outline: none;">
            <option value="all">جميع المقررات</option>
            @foreach($doctorSubjects as $subject)
            <option value="{{ $subject->id }}" {{ $subjectId == $subject->id ? 'selected' : '' }}>{{ $subject->name }}</option>
            @endforeach
        </select>

        <div style="position: relative; display: flex; align-items: center;">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="position: absolute; right: 10px; color: var(--text-secondary);">
                <circle cx="11" cy="11" r="8"></circle>
                <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
            </svg>
            <input type="text" name="search" value="{{ $search }}" placeholder="اكتب اسم الطالب أو رقمه..." style="padding: 0.6rem 1rem 0.6rem 2.5rem; border: 1px solid #e2e8f0; border-radius: 10px; font-size: 0.9rem; outline: none; width: 200px;">
            @if($search)
            <a href="{{ route('doctor.excuses.index', ['status' => $status, 'subject' => $subjectId]) }}" style="position: absolute; left: 10px; display: flex; align-items: center; justify-content: center; background: none; border: none; cursor: pointer; color: var(--text-secondary); text-decoration: none;">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <line x1="18" y1="6" x2="6" y2="18"></line>
                    <line x1="6" y1="6" x2="18" y2="18"></line>
                </svg>
            </a>
            @endif
        </div>
        <button type="submit" style="display: none;">بحث</button>
    </form>
</div>

@if(session('success'))
<div class="alert alert-success mb-4">{{ session('success') }}</div>
@endif

<!-- Excuses List -->
<div class="excuses-list">
    @forelse($excuses as $excuse)
    <div class="excuse-card">
        <div class="excuse-header">
            <div class="student-info">
                <div class="student-avatar">{{ mb_substr($excuse->student->name ?? '?', 0, 1) }}</div>
                <div>
                    <div class="student-name">{{ $excuse->student->name ?? 'طالب' }}</div>
                    <div class="student-meta">{{ $excuse->student->student_number ?? '' }} • {{ $excuse->created_at->diffForHumans() }}</div>
                </div>
            </div>
            <span class="excuse-status {{ $excuse->status }}">
                @switch($excuse->status)
                @case('pending') معلق @break
                @case('accepted') مقبول @break
                @case('rejected') مرفوض @break
                @endswitch
            </span>
        </div>

        <div class="excuse-content">
            <div class="excuse-field">
                <span class="field-label">المقرر</span>
                <span class="field-value">{{ $excuse->attendance->subject->name ?? '-' }}</span>
            </div>
            <div class="excuse-field">
                <span class="field-label">تاريخ الغياب</span>
                <span class="field-value">{{ $excuse->attendance ? \Carbon\Carbon::parse($excuse->attendance->date)->format('Y-m-d') : '-' }}</span>
            </div>
            <div class="excuse-field">
                <span class="field-label">تاريخ التقديم</span>
                <span class="field-value">{{ $excuse->created_at->format('Y-m-d') }}</span>
            </div>
        </div>

        <div class="excuse-reason">
            <div class="reason-label">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"></path>
                </svg>
                سبب العذر
            </div>
            <p style="margin: 0; color: var(--text-primary);">{{ $excuse->reason }}</p>
        </div>

        @if($excuse->doctor_comment)
        <div style="background: #f8fafc; border-radius: 12px; padding: 1.25rem; border-right: 4px solid var(--primary-color); margin-bottom: 1rem;">
            <div style="font-size: 0.75rem; font-weight: 700; color: var(--primary-color); margin-bottom: 0.5rem; display: flex; align-items: center; gap: 0.35rem;">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z"></path>
                </svg>
                ملاحظتك السابقة
            </div>
            <p style="margin: 0; color: var(--text-secondary); font-size: 0.95rem; line-height: 1.5;">{{ $excuse->doctor_comment }}</p>
        </div>
        @endif

        <div class="excuse-actions">
            @if($excuse->status == 'pending')
            <form action="{{ route('doctor.excuses.update', $excuse->id) }}" method="POST" style="width: 100%;">
                @csrf
                @method('PUT')
                <div style="margin-bottom: 1rem;">
                    <textarea name="comment" placeholder="ملاحظات الطبيب (اختياري)... الإشعار سيصل للطالب" style="width: 100%; border: 1px solid #e2e8f0; border-radius: 8px; padding: 0.5rem; resize: vertical; min-height: 60px;"></textarea>
                </div>
                <div style="display: flex; gap: 0.5rem;">
                    <button type="submit" name="status" value="accepted" class="btn-accept" onclick="return confirm('هل أنت متأكد من قبول العذر؟')" style="flex: 1; justify-content: center;">
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <polyline points="20 6 9 17 4 12"></polyline>
                        </svg>
                        قبول
                    </button>

                    <button type="submit" name="status" value="rejected" class="btn-reject" onclick="return confirm('هل أنت متأكد من رفض العذر؟')" style="flex: 1; justify-content: center;">
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <line x1="18" y1="6" x2="6" y2="18"></line>
                            <line x1="6" y1="6" x2="18" y2="18"></line>
                        </svg>
                        رفض
                    </button>
                </div>
            </form>
            @endif

            @if($excuse->attachment)
            <a href="{{ asset('storage/' . $excuse->attachment) }}" target="_blank" class="btn-attachment">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M21.44 11.05l-9.19 9.19a6 6 0 0 1-8.49-8.49l9.19-9.19a4 4 0 0 1 5.66 5.66l-9.2 9.19a2 2 0 0 1-2.83-2.83l8.49-8.48"></path>
                </svg>
                المرفق
            </a>
            @endif
        </div>
    </div>
    @empty
    <div class="empty-state">
        <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="color: #cbd5e1; margin-bottom: 1rem;">
            <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
            <polyline points="14 2 14 8 20 8"></polyline>
        </svg>
        <h3 style="font-size: 1.25rem; font-weight: 700; margin-bottom: 0.5rem;">لا توجد أعذار</h3>
        <p style="color: var(--text-secondary);">
            @if($status == 'pending')
            لا توجد أعذار معلقة للمراجعة
            @else
            لا توجد أعذار بهذا الفلتر
            @endif
        </p>
    </div>
    @endforelse
</div>

<!-- Pagination -->
@if($excuses->hasPages())
<div style="margin-top: 2rem;">
    {{ $excuses->appends(['status' => $status])->links() }}
</div>
@endif

@endsection