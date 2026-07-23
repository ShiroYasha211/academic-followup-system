@extends('layouts.student')

@section('title', 'تنبيهات الحالات النادرة')

@section('content')
<style>
    .rare-cases-timeline {
        max-width: 900px;
        margin: 0 auto;
    }

    .case-announcement {
        background: white;
        border-radius: 20px;
        border: 1px solid #e2e8f0;
        margin-bottom: 2rem;
        overflow: hidden;
        transition: transform 0.3s cubic-bezier(0.175, 0.885, 0.32, 1.275);
        box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);
    }

    .case-announcement:hover {
        transform: translateY(-5px);
        box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
    }

    .announcement-header {
        padding: 1.5rem;
        border-bottom: 1px solid #f1f5f9;
        display: flex;
        justify-content: space-between;
        align-items: flex-start;
    }

    .doctor-badge {
        display: flex;
        align-items: center;
        gap: 0.75rem;
    }

    .doctor-avatar {
        width: 45px;
        height: 45px;
        background: var(--primary-color);
        color: white;
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: 800;
        font-size: 1.2rem;
    }

    .announcement-body {
        padding: 1.5rem;
    }

    .diagnosis-highlight {
        font-size: 1.4rem;
        font-weight: 800;
        color: var(--text-primary);
        margin-bottom: 1.5rem;
        display: block;
        line-height: 1.3;
    }

    .location-banner {
        background: #fcfaff;
        border: 1px solid #eef2ff;
        border-radius: 12px;
        padding: 1rem;
        display: flex;
        flex-wrap: wrap;
        gap: 1.5rem;
        margin-bottom: 1.5rem;
    }

    .loc-item {
        display: flex;
        align-items: center;
        gap: 0.5rem;
        font-weight: 700;
        color: var(--primary-color);
        font-size: 0.95rem;
    }

    .signs-box {
        background: #f8fafc;
        border-right: 4px solid var(--primary-color);
        padding: 1rem;
        border-radius: 0 8px 8px 0;
        color: #475569;
        line-height: 1.7;
        font-size: 1rem;
        margin-bottom: 1.5rem;
    }

    .case-media {
        width: 100%;
        max-height: 400px;
        object-fit: cover;
        border-radius: 12px;
    }

    .announcement-footer {
        padding: 1.25rem 1.5rem;
        background: #f8fafc;
        border-top: 1px solid #f1f5f9;
        display: flex;
        justify-content: space-between;
        align-items: center;
    }

    .time-ago {
        color: #94a3b8;
        font-size: 0.85rem;
        font-weight: 600;
    }

    .btn-view-details {
        background: white;
        border: 1.5px solid var(--primary-color);
        color: var(--primary-color);
        padding: 0.5rem 1.25rem;
        border-radius: 10px;
        font-weight: 700;
        font-size: 0.9rem;
        text-decoration: none;
        transition: all 0.2s;
    }

    .btn-view-details:hover {
        background: var(--primary-color);
        color: white;
    }

    .empty-state {
        text-align: center;
        padding: 5rem 2rem;
        background: white;
        border-radius: 20px;
        border: 2px dashed #e2e8f0;
    }
</style>

<div class="dashboard-header mb-4">
    <div class="welcome-text">
        <h1>تنبيهات الحالات السريرية النادرة</h1>
        <p>تابع الحالات النادرة والهامة في مراكز التدريب المختلفة المتاحة للعرض</p>
    </div>
</div>

<div class="rare-cases-timeline">
    @if($cases->count() > 0)
        @foreach($cases as $case)
        <div class="case-announcement">
            <div class="announcement-header">
                <div class="doctor-badge">
                    <div class="doctor-avatar">
                        {{ mb_substr($case->doctor->name, 0, 1) }}
                    </div>
                    <div>
                        <div class="fw-bold text-dark">{{ $case->doctor->name }}</div>
                        <div class="small text-muted">عضو هيئة تدريس</div>
                    </div>
                </div>
                <div class="badge bg-primary px-3 py-2 rounded-pill">
                    <i class="fa-solid fa-star me-1"></i> حالة نادرة
                </div>
            </div>

            <div class="announcement-body">
                <span class="diagnosis-highlight">
                    <i class="fa-solid fa-stethoscope me-1 text-primary"></i>
                    {{ $case->diagnosis }}
                </span>

                <div class="location-banner">
                    <div class="loc-item">
                        <i class="fa-solid fa-hospital"></i>
                        {{ $case->hospital }}
                    </div>
                    <div class="loc-item">
                        <i class="fa-solid fa-building-user"></i>
                        {{ $case->department }}
                    </div>
                    @if($case->room_number)
                    <div class="loc-item">
                        <i class="fa-solid fa-door-open"></i>
                        {{ $case->room_number }}
                    </div>
                    @endif
                </div>

                @if($case->clinical_signs)
                <div class="signs-box">
                    <strong>ماذا ستشاهد:</strong><br>
                    {{ Str::limit($case->clinical_signs, 200) }}
                </div>
                @endif

                @if($case->attachment_path)
                <img src="{{ asset('storage/' . $case->attachment_path) }}" class="case-media mb-3" alt="Case Media">
                @endif
            </div>

            <div class="announcement-footer">
                <span class="time-ago">
                    <i class="fa-regular fa-clock me-1"></i>
                    نُشر منذ {{ $case->created_at->diffForHumans() }}
                </span>
                
                <a href="{{ route('student.clinical.rare-cases.show', $case->id) }}" class="btn-view-details">
                    رؤية كامل التفاصيل <i class="fa-solid fa-chevron-left ms-1"></i>
                </a>
            </div>
        </div>
        @endforeach

        <div class="mt-4">
            {{ $cases->links() }}
        </div>
    @else
        <div class="empty-state">
            <i class="fa-solid fa-calendar-xmark mb-4" style="font-size: 4rem; color: #cbd5e1;"></i>
            <h3 class="fw-bold text-secondary">لا توجد إعلانات حالياً</h3>
            <p class="text-muted">أرشد الدكتور الطلاب حين تتوفر حالات سريرية نادرة وجديرة بالملاحظة.</p>
        </div>
    @endif
</div>
@endsection
