@extends('layouts.admin')

@section('title', 'تفاصيل الكويز الإداري')

@section('content')
<style>
    .detail-card {
        background: white;
        border-radius: 20px;
        padding: 2rem;
        border: 1px solid #e2e8f0;
        margin-bottom: 1.5rem;
    }

    .badge-status {
        padding: 0.5rem 1rem;
        border-radius: 99px;
        font-weight: 700;
        font-size: 0.8rem;
        color: white;
    }

    .stat-box {
        background: #f8fafc;
        border-radius: 16px;
        padding: 1.5rem;
        text-align: center;
        border: 1px solid #e2e8f0;
    }

    .stat-value { font-size: 1.5rem; font-weight: 800; color: #1e293b; }
    .stat-label { font-size: 0.8rem; color: #64748b; font-weight: 600; }

    .target-item {
        background: #f1f5f9;
        padding: 0.4rem 0.8rem;
        border-radius: 8px;
        font-size: 0.8rem;
        font-weight: 600;
        color: #475569;
        display: inline-flex;
        align-items: center;
        gap: 0.35rem;
        margin: 0.25rem;
    }
    .countdown-box {
        background: #fff7ed;
        border: 2px solid #fdba74;
        border-radius: 16px;
        padding: 1.5rem;
        text-align: center;
        margin-bottom: 1.5rem;
    }
    .countdown-timer {
        font-size: 2rem;
        font-weight: 900;
        color: #9a3412;
        font-family: monospace;
    }
    .settings-list i { width: 20px; text-align: center; margin-right: 8px; }
    .settings-list .setting-item {
        display: flex;
        align-items: center;
        padding: 0.5rem 0;
        border-bottom: 1px solid #f1f5f9;
        font-size: 0.9rem;
    }
    .settings-list .setting-item:last-child { border-bottom: none; }
</style>

<div class="d-flex justify-content-between align-items-center mb-4">
    <div>
        <h2 class="fw-bold mb-1">{{ $quiz->title }}</h2>
        <div class="text-muted small">أنشئ بواسطة: {{ $quiz->creator->name }} • {{ $quiz->created_at->format('Y/m/d') }}</div>
    </div>
    <div style="display: flex; gap: 0.75rem;">
        <a href="{{ route('admin.quizzes.edit', $quiz) }}" class="btn btn-outline-primary" style="border-radius: 12px;">
            <i class="fa-solid fa-edit me-1"></i> تعديل
        </a>
        <a href="{{ route('admin.quizzes.results', $quiz) }}" class="btn btn-primary" style="border-radius: 12px;">
            <i class="fa-solid fa-chart-bar me-1"></i> عرض النتائج
        </a>
        <a href="{{ route('admin.quizzes.results.export', $quiz) }}" class="btn btn-success" style="border-radius: 12px;">
            <i class="fa-solid fa-file-excel me-1"></i> تصدير النتائج
        </a>
    </div>
</div>

<div class="row">
    <div class="col-lg-8">
        {{-- Overview --}}
        <div class="detail-card">
            <h5 class="fw-bold mb-3">نظرة عامة</h5>
            <div class="row g-4">
                <div class="col-md-3"><div class="stat-box"><div class="stat-value">{{ $stats['total_attempts'] }}</div><div class="stat-label">محاولة</div></div></div>
                <div class="col-md-3"><div class="stat-box"><div class="stat-value text-success">{{ round($stats['avg_score'], 1) }}%</div><div class="stat-label">متوسط الدرجات</div></div></div>
                <div class="col-md-3"><div class="stat-box"><div class="stat-value text-primary">{{ round($stats['highest_score'], 1) }}%</div><div class="stat-label">أعلى درجة</div></div></div>
                <div class="col-md-3"><div class="stat-box"><div class="stat-value text-danger">{{ round($stats['lowest_score'], 1) }}%</div><div class="stat-label">أقل درجة</div></div></div>
            </div>

            <div class="mt-4 pt-4 border-top">
                <h6 class="fw-bold mb-2">الوصف:</h6>
                <p class="text-secondary small">{{ $quiz->description ?: 'لا يوجد وصف.' }}</p>
            </div>
        </div>

        {{-- Configuration & Settings --}}
        <div class="detail-card">
            <h5 class="fw-bold mb-3">الإعدادات والتوقيت</h5>
            <div class="row g-3 mb-4">
                <div class="col-md-6">
                    <div class="small text-muted mb-1">الحالة</div>
                    <span class="badge-status" style="background: {{ $quiz->status_color }}">{{ $quiz->status_label }}</span>
                </div>
                <div class="col-md-6">
                    <div class="small text-muted mb-1">المادة</div>
                    <div class="fw-bold">{{ $quiz->subject->name ?? 'مسابقة عامة / إدارية' }}</div>
                </div>
                <div class="col-md-6">
                    <div class="small text-muted mb-1">وقت النشر</div>
                    <div class="fw-bold text-primary">{{ $quiz->scheduled_at ? $quiz->scheduled_at->format('Y-m-d h:i A') : 'فوري' }}</div>
                </div>
                <div class="col-md-6">
                    <div class="small text-muted mb-1">وقت الإغلاق</div>
                    <div class="fw-bold text-danger">{{ $quiz->closes_at ? $quiz->closes_at->format('Y-m-d h:i A') : 'غير محدد' }}</div>
                </div>
            </div>

            <div class="settings-list pt-3 border-top">
                <div class="setting-item">
                    <i class="fa-solid fa-clock text-primary"></i>
                    <span>مدة الحل: <strong>{{ $quiz->time_limit_minutes ? $quiz->time_limit_minutes . ' دقيقة' : 'بدون وقت محدد' }}</strong></span>
                </div>
                <div class="setting-item">
                    <i class="fa-solid fa-shuffle {{ $quiz->shuffle_questions ? 'text-success' : 'text-muted' }}"></i>
                    <span>خلط الأسئلة: <strong>{{ $quiz->shuffle_questions ? 'مفعل' : 'معطل' }}</strong></span>
                </div>
                <div class="setting-item">
                    <i class="fa-solid fa-list-ol {{ $quiz->shuffle_options ? 'text-success' : 'text-muted' }}"></i>
                    <span>خلط الاختيارات: <strong>{{ $quiz->shuffle_options ? 'مفعل' : 'معطل' }}</strong></span>
                </div>
                <div class="setting-item">
                    <i class="fa-solid fa-check-double {{ $quiz->show_correct_answers ? 'text-success' : 'text-muted' }}"></i>
                    <span>إظهار الإجابات الصحيحة: <strong>{{ $quiz->show_correct_answers ? 'مفعل' : 'معطل' }}</strong></span>
                </div>
                <div class="setting-item">
                    <i class="fa-solid fa-comment-dots {{ $quiz->show_correction_notes ? 'text-success' : 'text-muted' }}"></i>
                    <span>إظهار ملاحظات التصحيح: <strong>{{ $quiz->show_correction_notes ? 'مفعل' : 'معطل' }}</strong></span>
                </div>
                <div class="setting-item">
                    <i class="fa-solid fa-bell {{ $quiz->notify_students ? 'text-success' : 'text-muted' }}"></i>
                    <span>تنبيه الطلاب: <strong>{{ $quiz->notify_students ? 'مفعل' : 'معطل' }}</strong></span>
                </div>
                <div class="setting-item">
                    <i class="fa-solid fa-hourglass-half {{ $quiz->show_countdown ? 'text-success' : 'text-muted' }}"></i>
                    <span>عداد تنازلي للطلاب: <strong>{{ $quiz->show_countdown ? 'مفعل' : 'معطل' }}</strong></span>
                </div>
                <div class="setting-item">
                    <i class="fa-solid fa-eye text-primary"></i>
                    <span>ظهور النتائج: <strong>{{ $quiz->results_visibility_label }}</strong></span>
                </div>
                <div class="setting-item">
                    <i class="fa-solid fa-rotate-left {{ $quiz->allow_question_backtracking ? 'text-success' : 'text-muted' }}"></i>
                    <span>رجوع الطالب للأسئلة السابقة: <strong>{{ $quiz->allow_question_backtracking ? 'مسموح' : 'غير مسموح' }}</strong></span>
                </div>
            </div>
        </div>

        {{-- Targets --}}
        <div class="detail-card">
            <h5 class="fw-bold mb-3">الفئات المستهدفة</h5>
            @if($quiz->targets->count() > 0)
                <div class="d-flex flex-wrap">
                    @foreach($quiz->targets as $target)
                        <div class="target-item">
                            <i class="fa-solid fa-bullseye"></i>
                            @if($target->university) {{ $target->university->name }} @endif
                            @if($target->college) / {{ $target->college->name }} @endif
                            @if($target->major) / {{ $target->major->name }} @endif
                            @if($target->level) / {{ $target->level->name }} @endif
                        </div>
                    @endforeach
                </div>
            @else
                <div class="text-muted small">كويز عام (لطلاب المادة المحددة فقط)</div>
            @endif
        </div>
    </div>

    <div class="col-lg-4">
        {{-- Countdown Timer --}}
        @php
            $targetDate = null;
            $labelText = '';
            
            if ($quiz->status === 'scheduled' && $quiz->scheduled_at) {
                $targetDate = $quiz->scheduled_at;
                $labelText = 'المتبقي على النشر';
            } elseif ($quiz->status !== 'closed' && $quiz->closes_at) {
                $targetDate = $quiz->closes_at;
                $labelText = 'المتبقي على إغلاق الكويز';
            }
        @endphp

        @if($targetDate)
        <div class="countdown-box" id="quiz-countdown-container" x-data="countdown('{{ $targetDate->toIso8601String() }}')">
            <div class="stat-label mb-2">{{ $labelText }}</div>
            <div class="countdown-timer" x-text="displayText">--:--:--</div>
            <div class="text-muted mt-2 x-small">الوقت الحالي للسيرفر: {{ now()->format('h:i A') }}</div>
        </div>
        @endif

        {{-- Structure Info --}}
        <div class="detail-card">
            <h5 class="fw-bold mb-3">هيكل الكويز</h5>
            <div class="mb-3">
                <div class="small text-muted">عدد النماذج</div>
                <div class="fw-bold">{{ $quiz->models->count() }} نموذج</div>
                <div class="mt-2">
                    @foreach($quiz->models as $model)
                        <div class="d-flex justify-content-between align-items-center bg-light p-2 rounded mb-1">
                            <span class="small font-bold">{{ $model->name }}</span>
                            <span class="badge bg-dark font-monospace" title="رمز الدخول">{{ $model->access_code }}</span>
                        </div>
                    @endforeach
                </div>
            </div>
            <div class="mb-3">
                <div class="small text-muted">إجمالي الأسئلة</div>
                <div class="fw-bold text-primary">{{ $quiz->total_questions }} سؤال</div>
            </div>
            <div class="mb-3">
                <div class="small text-muted">نوع الكويز</div>
                <span class="badge {{ $quiz->is_competition ? 'bg-warning text-dark' : 'bg-light text-dark' }}" style="font-size: 0.7rem; font-weight: 700;">
                    {{ $quiz->is_competition ? 'مسابقة / منافسة' : 'كويز اعتيادي' }}
                </span>
            </div>
        </div>

        {{-- Actions --}}
        <div class="detail-card">
            <h5 class="fw-bold mb-3">إجراءات إضافية</h5>
            <form action="{{ route('admin.quizzes.share-results', $quiz) }}" method="POST" class="mb-3">
                @csrf
                <label class="small text-muted mb-1">إعداد ظهور النتائج للطلاب</label>
                <div class="d-flex gap-2">
                    <select name="visibility" class="form-select form-select-sm">
                        <option value="hidden" {{ $quiz->results_visibility === 'hidden' ? 'selected' : '' }}>مخفية</option>
                        <option value="individual" {{ $quiz->results_visibility === 'individual' ? 'selected' : '' }}>فردية للطالب</option>
                        <option value="public" {{ $quiz->results_visibility === 'public' ? 'selected' : '' }}>عامة للجميع</option>
                    </select>
                    <button class="btn btn-outline-primary btn-sm" style="border-radius: 10px; font-weight: 700;">حفظ</button>
                </div>
            </form>
            @if($quiz->status === 'draft')
                <form action="{{ route('admin.quizzes.publish', $quiz) }}" method="POST" class="mb-2">
                    @csrf @method('PATCH')
                    <button class="btn btn-success w-100" style="border-radius: 12px;"><i class="fa-solid fa-paper-plane me-1"></i> نشر الآن</button>
                </form>
            @endif
            @if($quiz->status === 'published')
                <form action="{{ route('admin.quizzes.close', $quiz) }}" method="POST" class="mb-2">
                    @csrf @method('PATCH')
                    <button class="btn btn-danger w-100" style="border-radius: 12px;"><i class="fa-solid fa-lock me-1"></i> إغلاق الكويز</button>
                </form>
            @endif
            <a href="{{ route('admin.quizzes.index') }}" class="btn btn-light w-100" style="border-radius: 12px;">رجوع للقائمة</a>
        </div>
    </div>
</div>
@endsection

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
                    // Small delay to let the server update the status
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
