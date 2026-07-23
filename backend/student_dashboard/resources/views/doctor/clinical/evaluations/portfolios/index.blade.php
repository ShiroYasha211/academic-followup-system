@extends('layouts.doctor')

@section('title', 'كشوف التقييمات السريرية')

@section('content')
<style>
    .evaluation-hero {
        background: linear-gradient(135deg, #102a43 0%, #2563a8 58%, #0f766e 100%);
        border-radius: 24px;
        padding: 1.75rem;
        color: #fff;
        box-shadow: 0 20px 48px rgba(15, 42, 67, .16);
    }
    .evaluation-filter, .student-report-card {
        background: #fff;
        border: 1px solid #e2e8f0;
        border-radius: 18px;
        box-shadow: 0 10px 28px rgba(15, 23, 42, .05);
    }
    .evaluation-filter { padding: 1rem; }
    .student-report-card {
        display: block;
        height: 100%;
        padding: 1.1rem;
        color: inherit;
        text-decoration: none;
        transition: transform .18s ease, box-shadow .18s ease, border-color .18s ease;
    }
    .student-report-card:hover {
        transform: translateY(-2px);
        border-color: #bfdbfe;
        box-shadow: 0 16px 38px rgba(37, 99, 168, .1);
        color: inherit;
    }
    .student-avatar {
        width: 48px;
        height: 48px;
        display: grid;
        place-items: center;
        border-radius: 15px;
        background: #e8f1fb;
        color: #1d4f91;
        font-size: 1.1rem;
        font-weight: 900;
        flex: 0 0 auto;
    }
    .metric-chip {
        display: inline-flex;
        padding: .35rem .6rem;
        border-radius: 9px;
        background: #f8fafc;
        border: 1px solid #e2e8f0;
        color: #334155;
        font-size: .76rem;
        font-weight: 800;
    }
</style>

<div class="evaluation-hero mb-4">
    <div class="d-flex justify-content-between align-items-start gap-3 flex-wrap">
        <div>
            <div class="small fw-bold opacity-75 mb-2">Student OSCE portfolios</div>
            <h1 class="h3 fw-bold mb-2">كشوف التقييمات السريرية للطلاب</h1>
            <p class="mb-0 opacity-75">كشف تراكمي لكل طالب يوضح القوائم التي اختبرها، عدد المحاولات، الدكاترة، والنتائج.</p>
        </div>
        <a href="{{ route('doctor.clinical.evaluations.results') }}" class="btn btn-outline-light rounded-3 fw-bold">جميع المحاولات</a>
    </div>
</div>

<form method="GET" class="evaluation-filter mb-4">
    <div class="row g-3 align-items-end">
        <div class="col-xl-4 col-lg-6">
            <label class="form-label fw-bold">بحث عن طالب</label>
            <input type="search" name="search" value="{{ request('search') }}" class="form-control rounded-3" placeholder="الاسم أو الرقم الجامعي أو البريد">
        </div>
        <div class="col-xl-2 col-md-6">
            <label class="form-label fw-bold">التخصص</label>
            <select name="major_id" class="form-select rounded-3">
                <option value="">الكل</option>
                @foreach($filters['majors'] as $major)
                    <option value="{{ $major['id'] }}" @selected((string) request('major_id') === (string) $major['id'])>{{ $major['name'] }}</option>
                @endforeach
            </select>
        </div>
        <div class="col-xl-2 col-md-6">
            <label class="form-label fw-bold">المستوى</label>
            <select name="level_id" class="form-select rounded-3">
                <option value="">الكل</option>
                @foreach($filters['levels'] as $level)
                    <option value="{{ $level['id'] }}" @selected((string) request('level_id') === (string) $level['id'])>{{ $level['name'] }}</option>
                @endforeach
            </select>
        </div>
        <div class="col-xl-2 col-md-6">
            <label class="form-label fw-bold">الترتيب</label>
            <select name="sort" class="form-select rounded-3">
                <option value="latest" @selected(request('sort', 'latest') === 'latest')>آخر تقييم</option>
                <option value="attempts" @selected(request('sort') === 'attempts')>عدد المحاولات</option>
                <option value="average" @selected(request('sort') === 'average')>أعلى متوسط</option>
                <option value="name" @selected(request('sort') === 'name')>اسم الطالب</option>
            </select>
        </div>
        <div class="col-xl-2 col-md-6 d-flex gap-2">
            <button class="btn btn-primary rounded-3 fw-bold flex-grow-1">تطبيق</button>
            <a href="{{ route('doctor.clinical.evaluations.portfolios.index') }}" class="btn btn-outline-secondary rounded-3">مسح</a>
        </div>
    </div>
</form>

<div class="row g-3">
    @forelse($students as $student)
        @php($summary = $student['summary'])
        <div class="col-xl-4 col-md-6">
            <a class="student-report-card" href="{{ route('doctor.clinical.evaluations.portfolios.show', $student['id']) }}">
                <div class="d-flex gap-3 align-items-start mb-3">
                    <div class="student-avatar">{{ mb_substr($student['name'], 0, 1) }}</div>
                    <div class="min-w-0 flex-grow-1">
                        <h2 class="h6 fw-bold mb-1 text-dark">{{ $student['name'] }}</h2>
                        <div class="small text-muted">{{ $student['student_number'] ?: '-' }}</div>
                        <div class="small text-muted text-truncate mt-1">
                            {{ data_get($student, 'major.name', '-') }} · {{ data_get($student, 'level.name', '-') }}
                        </div>
                    </div>
                    <div class="text-primary fw-bold">{{ number_format($summary['average_percentage'], 1) }}%</div>
                </div>
                <div class="d-flex flex-wrap gap-2">
                    <span class="metric-chip">المحاولات {{ $summary['attempts_count'] }}</span>
                    <span class="metric-chip">القوائم {{ $summary['checklists_count'] }}</span>
                    <span class="metric-chip">الدكاترة {{ $summary['doctors_count'] }}</span>
                    <span class="metric-chip">النجاح {{ number_format($summary['pass_rate'], 1) }}%</span>
                </div>
            </a>
        </div>
    @empty
        <div class="col-12">
            <div class="student-report-card text-center text-muted py-5">لا توجد تقييمات سريرية مطابقة للفلاتر الحالية.</div>
        </div>
    @endforelse
</div>

@if($students->hasPages())
    <div class="mt-4">{{ $students->links() }}</div>
@endif
@endsection
