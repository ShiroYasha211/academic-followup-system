@extends('layouts.student')

@section('title', 'الكويزات')

@section('content')
<style>
    .sqz-header {
        background: linear-gradient(135deg, #059669 0%, #10b981 50%, #34d399 100%);
        border-radius: 24px;
        padding: 2.5rem 2rem;
        color: white;
        margin-bottom: 2rem;
        position: relative;
        overflow: hidden;
        box-shadow: 0 10px 15px -3px rgba(0,0,0,0.1);
    }

    .sqz-header::before { content: ''; position: absolute; top: -50%; right: -10%; width: 350px; height: 350px; background: rgba(255,255,255,0.08); border-radius: 50%; }
    .sqz-header-content { position: relative; z-index: 1; }
    .sqz-header h1 { font-size: 2rem; font-weight: 800; margin-bottom: 0.25rem; }
    .sqz-header p { opacity: 0.85; }

    .sqz-section-title {
        font-size: 1.15rem;
        font-weight: 800;
        color: #1e293b;
        margin-bottom: 1.25rem;
        display: flex;
        align-items: center;
        gap: 0.5rem;
    }

    .sqz-section-title i { color: #059669; }

    .sqz-grid {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
        gap: 1.25rem;
        margin-bottom: 2.5rem;
    }

    .sqz-card {
        background: white;
        border-radius: 20px;
        border: 1px solid #e2e8f0;
        overflow: hidden;
        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    }

    .sqz-card:hover { transform: translateY(-5px); box-shadow: 0 20px 25px -5px rgba(0,0,0,0.1); }

    .sqz-card-banner { height: 5px; width: 100%; background: #10b981; }
    .sqz-card-banner.competition { background: linear-gradient(90deg, #f59e0b, #ef4444); }
    .sqz-card-banner.admin { background: linear-gradient(90deg, #3b82f6, #6366f1); }

    .sqz-card.is-admin {
        border-color: #bae6fd;
        background: #f0f9ff;
    }

    .sqz-card.is-admin:hover {
        box-shadow: 0 20px 25px -5px rgba(59, 130, 246, 0.15);
        border-color: #7dd3fc;
    }

    .sqz-card-body { padding: 1.5rem; }

    .sqz-card-meta {
        display: flex;
        align-items: center;
        gap: 0.5rem;
        margin-bottom: 0.75rem;
        flex-wrap: wrap;
    }

    .sqz-badge {
        padding: 0.25rem 0.65rem;
        border-radius: 99px;
        font-size: 0.7rem;
        font-weight: 700;
    }

    .sqz-badge-quiz { background: #d1fae5; color: #065f46; }
    .sqz-badge-competition { background: #fef3c7; color: #92400e; }
    .sqz-badge-done { background: #e0e7ff; color: #3730a3; }

    .sqz-card-title { font-size: 1.05rem; font-weight: 800; color: #1e293b; margin-bottom: 0.35rem; }
    .sqz-card-doctor { font-size: 0.85rem; color: #64748b; margin-bottom: 0.75rem; }

    .sqz-card-info {
        display: flex;
        gap: 1rem;
        flex-wrap: wrap;
    }

    .sqz-info-item {
        display: flex;
        align-items: center;
        gap: 0.3rem;
        font-size: 0.8rem;
        color: #64748b;
        font-weight: 600;
    }

    .sqz-card-footer {
        padding: 0.85rem 1.5rem;
        border-top: 1px solid #f1f5f9;
        background: #f8fafc;
        display: flex;
        justify-content: space-between;
        align-items: center;
    }

    .sqz-take-btn {
        background: linear-gradient(135deg, #059669, #10b981);
        color: white;
        border: none;
        padding: 0.5rem 1.25rem;
        border-radius: 12px;
        font-weight: 700;
        font-size: 0.85rem;
        text-decoration: none;
        display: inline-flex;
        align-items: center;
        gap: 0.35rem;
        transition: all 0.2s;
    }

    .sqz-take-btn:hover { transform: translateY(-2px); box-shadow: 0 6px 15px rgba(5,150,105,0.3); color: white; }

    .sqz-view-btn {
        background: #e0e7ff;
        color: #4338ca;
        border: none;
        padding: 0.5rem 1.25rem;
        border-radius: 12px;
        font-weight: 700;
        font-size: 0.85rem;
        text-decoration: none;
        display: inline-flex;
        align-items: center;
        gap: 0.35rem;
        transition: all 0.2s;
    }

    .sqz-view-btn:hover { background: #c7d2fe; color: #3730a3; }

    /* My Attempts Table */
    .attempts-card {
        background: white;
        border-radius: 20px;
        border: 1px solid #e2e8f0;
        overflow: hidden;
    }

    .attempts-table { width: 100%; border-collapse: collapse; }
    .attempts-table thead th { background: #f8fafc; padding: 0.85rem 1.25rem; font-weight: 700; font-size: 0.85rem; color: #475569; text-align: right; border-bottom: 2px solid #e2e8f0; }
    .attempts-table tbody td { padding: 0.75rem 1.25rem; font-size: 0.85rem; color: #334155; border-bottom: 1px solid #f1f5f9; }
    .attempts-table tbody tr:hover { background: #f8fafc; }

    .pct-bar { width: 80px; height: 6px; background: #e2e8f0; border-radius: 99px; overflow: hidden; display: inline-block; vertical-align: middle; margin-left: 0.5rem; }
    .pct-fill { height: 100%; border-radius: 99px; }

    .empty-state { text-align: center; padding: 4rem 2rem; background: white; border-radius: 24px; border: 2px dashed #e2e8f0; }
    .empty-icon { font-size: 3.5rem; color: #cbd5e1; margin-bottom: 1rem; }
    .empty-title { font-size: 1.3rem; font-weight: 700; color: #475569; }

    @media (max-width: 768px) {
        .sqz-header { padding: 1.5rem; }
        .sqz-header h1 { font-size: 1.5rem; }
        .sqz-grid { grid-template-columns: 1fr; }
    }
</style>

<div class="sqz-header">
    <div class="sqz-header-content">
        <h1><i class="fa-solid fa-clipboard-question me-2"></i>الكويزات</h1>
        <p>اختبارات قصيرة من الدكاترة ومسابقات عامة</p>
    </div>
</div>

{{-- Doctor Quizzes --}}
@if($doctorQuizzes->count() > 0)
<h3 class="sqz-section-title"><i class="fa-solid fa-chalkboard-user"></i> كويزات الدكاترة</h3>
<div class="sqz-grid">
    @foreach($doctorQuizzes as $quiz)
    @php $attempted = $quiz->hasAttemptBy(auth()->user()); @endphp
    <div class="sqz-card">
        <div class="sqz-card-banner"></div>
        <div class="sqz-card-body">
            <div class="sqz-card-meta">
                @if($quiz->isUpcoming())
                <span class="sqz-badge" style="background: #fffbeb; color: #92400e; border: 1px solid #fde68a;"><i class="fa-solid fa-clock me-1"></i>قادماً</span>
                @else
                <span class="sqz-badge sqz-badge-quiz" style="background: {{ $quiz->status_color }}20; color: {{ $quiz->status_color }};"><i class="fa-solid fa-clipboard-question me-1"></i>{{ $quiz->status_label }}</span>
                @endif

                @if($attempted)
                <span class="sqz-badge sqz-badge-done"><i class="fa-solid fa-check me-1"></i>مكتمل</span>
                @endif
                @if($quiz->time_limit_minutes)
                <span style="font-size: 0.75rem; color: #94a3b8;"><i class="fa-regular fa-clock me-1"></i>{{ $quiz->time_limit_minutes }} د</span>
                @endif
            </div>
            <h3 class="sqz-card-title">{{ $quiz->title }}</h3>
            <p class="sqz-card-doctor"><i class="fa-solid fa-user-tie me-1"></i>{{ $quiz->creator->name ?? 'دكتور' }} — {{ $quiz->subject->name ?? '' }}</p>

            @if($quiz->isUpcoming() && $quiz->show_countdown)
            <div class="mb-3 p-2 rounded-3 text-center" style="background: #fff7ed; border: 1px solid #ffedd5;" x-data="countdown('{{ $quiz->scheduled_at->toIso8601String() }}')">
                <div class="small text-secondary mb-1">يبدأ خلال:</div>
                <div class="fw-bold text-warning fs-5" x-text="displayText">--:--:--</div>
            </div>
            @elseif($quiz->status === 'published' && $quiz->closes_at && $quiz->show_countdown && !$attempted)
            <div class="mb-3 p-2 rounded-3 text-center" style="background: #fdf2f2; border: 1px solid #fee2e2;" x-data="countdown('{{ $quiz->closes_at->toIso8601String() }}')">
                <div class="small text-danger mb-1"><i class="fa-solid fa-hourglass-end me-1"></i>ينتهي خلال:</div>
                <div class="fw-bold text-danger fs-5" x-text="displayText">--:--:--</div>
            </div>
            @endif

            <div class="sqz-card-info">
                <span class="sqz-info-item"><i class="fa-solid fa-layer-group"></i> {{ $quiz->models_count }} نموذج</span>
                @if($quiz->closes_at)
                <span class="sqz-info-item"><i class="fa-solid fa-calendar-times"></i> ينتهي {{ $quiz->closes_at->format('Y/m/d h:i A') }}</span>
                @endif
            </div>
        </div>
        <div class="sqz-card-footer">
            <span style="font-size: 0.75rem; color: #94a3b8;">{{ $quiz->isUpcoming() ? 'يبدأ في ' . $quiz->scheduled_at->format('H:i') : $quiz->created_at->diffForHumans() }}</span>
            @if($attempted)
                <a href="{{ route('student.quizzes.result', $quiz->attemptBy(auth()->user())) }}" class="sqz-view-btn"><i class="fa-solid fa-eye"></i> النتيجة</a>
            @elseif($quiz->isUpcoming())
                <button class="btn btn-sm btn-light disabled fw-bold" style="border-radius: 10px; font-size: 0.8rem;"><i class="fa-solid fa-lock me-1"></i>غير متاح</button>
            @elseif($quiz->isEffectivelyPublished())
                <a href="{{ route('student.quizzes.take', $quiz) }}" class="sqz-take-btn"><i class="fa-solid fa-play"></i> ابدأ الكويز</a>
            @else
                <span class="badge bg-secondary">غير نشط</span>
            @endif
        </div>
    </div>
    @endforeach
</div>
@endif

{{-- Competitions --}}
@if($competitions->count() > 0)
<h3 class="sqz-section-title"><i class="fa-solid fa-trophy"></i> مسابقات عامة</h3>
<div class="sqz-grid">
    @foreach($competitions as $quiz)
    @php 
        $attempted = $quiz->hasAttemptBy(auth()->user()); 
        $isAdmin = $quiz->creator_type === 'admin';
    @endphp
    <div class="sqz-card {{ $isAdmin ? 'is-admin' : '' }}">
        <div class="sqz-card-banner {{ $isAdmin ? 'admin' : 'competition' }}"></div>
        <div class="sqz-card-body">
            <div class="sqz-card-meta">
                @if($quiz->is_competition)
                    <span class="sqz-badge sqz-badge-competition"><i class="fa-solid fa-trophy me-1"></i>مسابقة</span>
                @endif
                
                @if($isAdmin)
                    <span class="sqz-badge" style="background: #0369a1; color: white; border: 1px solid #0369a1;"><i class="fa-solid fa-shield-halved me-1"></i>إدارة النظام</span>
                @endif

                @if($attempted)
                <span class="sqz-badge sqz-badge-done"><i class="fa-solid fa-check me-1"></i>مكتمل</span>
                @endif
            </div>
            <h3 class="sqz-card-title">
                {{ $quiz->title }}
                @if($isAdmin)
                <i class="fa-solid fa-circle-check text-primary ms-1" style="font-size: 0.9rem;" title="موثق من الإدارة"></i>
                @endif
            </h3>
            <p class="sqz-card-doctor">
                <i class="fa-solid fa-building-columns me-1"></i>
                {{ $isAdmin ? 'الإدارة المركزية' : ($quiz->creator->name ?? 'الإدارة') }}
            </p>
        </div>
        <div class="sqz-card-footer">
            <span style="font-size: 0.75rem; color: #94a3b8;">{{ $quiz->created_at->diffForHumans() }}</span>
            @if($attempted)
                <a href="{{ route('student.quizzes.result', $quiz->attemptBy(auth()->user())) }}" class="sqz-view-btn"><i class="fa-solid fa-eye"></i> النتيجة</a>
            @else
                <a href="{{ route('student.quizzes.take', $quiz) }}" class="sqz-take-btn" style="{{ $isAdmin ? 'background: linear-gradient(135deg, #2563eb, #4f46e5);' : '' }}">
                    <i class="fa-solid fa-play"></i> ابدأ
                </a>
            @endif
        </div>
    </div>
    @endforeach
</div>
@endif

{{-- No quizzes --}}
@if($doctorQuizzes->count() === 0 && $competitions->count() === 0)
<div class="empty-state mb-4">
    <div class="empty-icon"><i class="fa-solid fa-clipboard-question"></i></div>
    <h2 class="empty-title">لا توجد كويزات متاحة حالياً</h2>
    <p class="text-secondary">ستظهر هنا الكويزات عند نشرها من الدكاترة</p>
</div>
@endif

{{-- My Attempts --}}
@if($myAttempts->count() > 0)
<h3 class="sqz-section-title"><i class="fa-solid fa-history"></i> محاولاتي السابقة</h3>
<div class="attempts-card">
    <table class="attempts-table">
        <thead>
            <tr>
                <th>الكويز</th>
                <th>المادة</th>
                <th>النموذج</th>
                <th>الدرجة</th>
                <th>النسبة</th>
                <th>التاريخ</th>
                <th></th>
            </tr>
        </thead>
        <tbody>
            @foreach($myAttempts as $attempt)
            @php
                $pct = $attempt->percentage;
                $barColor = $pct >= 70 ? '#10b981' : ($pct >= 50 ? '#f59e0b' : '#ef4444');
            @endphp
            <tr>
                <td style="font-weight: 700;">{{ $attempt->quiz->title ?? '—' }}</td>
                <td>{{ $attempt->quiz->subject->name ?? '—' }}</td>
                <td><span style="background: #f1f5f9; padding: 0.15rem 0.4rem; border-radius: 6px; font-size: 0.75rem; font-weight: 600;">{{ $attempt->quizModel->name ?? '—' }}</span></td>
                <td style="font-weight: 700;">{{ $attempt->score ?? 0 }} / {{ $attempt->max_score ?? 0 }}</td>
                <td>
                    <div class="pct-bar"><div class="pct-fill" style="width:{{ $pct }}%; background:{{ $barColor }};"></div></div>
                    <span style="font-weight:700; color:{{ $barColor }}; font-size:0.85rem;">{{ $pct }}%</span>
                </td>
                <td style="font-size: 0.8rem; color: #64748b;">{{ $attempt->submitted_at?->diffForHumans() ?? '—' }}</td>
                <td>
                    <a href="{{ route('student.quizzes.result', $attempt) }}" class="sqz-view-btn" style="font-size:0.75rem; padding:0.35rem 0.8rem;"><i class="fa-solid fa-eye"></i></a>
                </td>
            </tr>
            @endforeach
        </tbody>
    </table>
</div>
@endif
@push('scripts')
<script>
function countdown(targetDate) {
    return {
        target: new Date(targetDate).getTime(),
        displayText: '',
        timer: null,

        init() {
            this.updateCounter();
            this.timer = setInterval(() => {
                this.updateCounter();
            }, 1000);
        },

        updateCounter() {
            const now = new Date().getTime();
            const distance = this.target - now;

            if (distance < 0) {
                this.displayText = "00:00:00";
                if (this.timer) {
                    clearInterval(this.timer);
                    this.timer = null;
                    setTimeout(() => window.location.reload(), 2000);
                }
                return;
            }

            const days = Math.floor(distance / (1000 * 60 * 60 * 24));
            const hours = Math.floor((distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
            const minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
            const seconds = Math.floor((distance % (1000 * 60)) / 1000);

            let res = "";
            if (days > 0) res += days + "ي ";
            res += String(hours).padStart(2, '0') + ":" + String(minutes).padStart(2, '0') + ":" + String(seconds).padStart(2, '0');
            this.displayText = res;
        }
    }
}
</script>
@endpush
@endsection
