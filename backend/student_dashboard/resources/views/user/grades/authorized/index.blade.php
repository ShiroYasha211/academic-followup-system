@extends(Auth::user()->role === \App\Enums\UserRole::DELEGATE ? 'layouts.delegate' : 'layouts.student')

@section('title', 'مهام الدرجات المفوضة')

@push('styles')
<style>
    .page-hero {
        background: linear-gradient(135deg, #0f172a 0%, #1d4ed8 100%);
        border-radius: 24px;
        padding: 2rem;
        color: #fff;
        margin-bottom: 1.5rem;
    }

    .task-card {
        border: 1px solid #e2e8f0;
        border-radius: 20px;
        background: #fff;
        box-shadow: 0 18px 45px -28px rgba(15, 23, 42, 0.25);
        height: 100%;
    }

    .task-card.helper {
        border-color: #fcd34d;
    }

    .task-badge {
        display: inline-flex;
        align-items: center;
        gap: 0.4rem;
        border-radius: 999px;
        padding: 0.45rem 0.9rem;
        font-size: 0.82rem;
        font-weight: 800;
    }

    .task-meta {
        display: flex;
        gap: 0.5rem;
        flex-wrap: wrap;
        margin-top: 1rem;
    }

    .task-meta span {
        background: #f8fafc;
        color: #475569;
        border-radius: 999px;
        padding: 0.4rem 0.8rem;
        font-size: 0.8rem;
        font-weight: 700;
    }
</style>
@endpush

@section('content')
@php
    $isDelegate = Auth::user()->role === \App\Enums\UserRole::DELEGATE;
    $directCount = $directDelegations->count();
    $helperCount = $helperTasks->count();
@endphp

<div class="page-hero">
    <div class="d-flex flex-column flex-lg-row justify-content-between gap-4 align-items-lg-center">
        <div>
            <div class="task-badge" style="background: rgba(255,255,255,.15); color: #fff;">بوابة رصد الدرجات</div>
            <h1 class="h3 fw-900 mt-3 mb-2">مهام الدرجات المفوضة</h1>
            <p class="mb-0 text-white-50">
                تعرض هذه الصفحة فئات الدرجات التي فوضها الدكتور لك مباشرة، والمهام المساعدة التي أسندها لك مندوب رئيسي.
            </p>
        </div>
        <div class="text-lg-end">
            <div class="fw-800">تفويض مباشر: {{ $directCount }}</div>
            <div class="fw-800">مهام مساعدة: {{ $helperCount }}</div>
        </div>
    </div>
</div>

@if(session('success'))
    <div class="alert alert-success border-0 rounded-4 shadow-sm">{{ session('success') }}</div>
@endif

@if($directCount === 0 && $helperCount === 0)
    <div class="card border-0 shadow-sm rounded-4">
        <div class="card-body text-center py-5">
            <h2 class="h5 fw-800 mb-2">لا توجد مهام درجات مفوضة حاليًا</h2>
            <p class="text-secondary mb-0">
                ستظهر هنا أي فئة درجات يفوضها لك الدكتور، أو أي مهمة مساعدة ينشئها لك مندوب رئيسي داخل نفس الفئة.
            </p>
        </div>
    </div>
@else
    <div class="row g-4">
        @foreach($directDelegations as $category)
            <div class="col-12 col-md-6 col-xl-4">
                <div class="task-card p-4">
                    <div class="d-flex justify-content-between align-items-start gap-3">
                        <div class="task-badge" style="background: #dbeafe; color: #1d4ed8;">
                            تفويض مباشر
                        </div>
                        <div class="task-badge" style="background: #eff6ff; color: #1e40af;">
                            {{ $category->max_score }} درجة
                        </div>
                    </div>

                    <h2 class="h5 fw-800 mt-4 mb-2">{{ $category->name }}</h2>
                    <div class="text-secondary fw-700">{{ $category->subject->name }}</div>

                    <div class="task-meta">
                        <span>التخصص: {{ $category->subject->major?->name ?? '-' }}</span>
                        <span>المستوى: {{ $category->subject->level?->name ?? '-' }}</span>
                    </div>

                    <div class="mt-3 text-secondary small">
                        الدكتور المعتمد: <strong class="text-dark">{{ $category->doctor?->name ?? '-' }}</strong>
                    </div>

                    <div class="mt-4">
                        <a href="{{ route($isDelegate ? 'delegate.authorized-grades.show' : 'student.authorized-grades.show', $category->id) }}"
                           class="btn btn-primary w-100 rounded-4 fw-800">
                            فتح المهمة
                        </a>
                    </div>
                </div>
            </div>
        @endforeach

        @foreach($helperTasks as $task)
            <div class="col-12 col-md-6 col-xl-4">
                <div class="task-card helper p-4">
                    <div class="d-flex justify-content-between align-items-start gap-3">
                        <div class="task-badge" style="background: #fef3c7; color: #b45309;">
                            مهمة مساعدة
                        </div>
                        <div class="task-badge" style="background: #fff7ed; color: #c2410c;">
                            {{ $task->delegation_type === 'partial' ? 'جزئي' : 'كامل' }}
                        </div>
                    </div>

                    <h2 class="h5 fw-800 mt-4 mb-2">{{ $task->title }}</h2>
                    <div class="text-secondary fw-700">{{ $task->category->name }} - {{ $task->category->subject->name }}</div>

                    <div class="task-meta">
                        <span>التخصص: {{ $task->category->subject->major?->name ?? '-' }}</span>
                        <span>المستوى: {{ $task->category->subject->level?->name ?? '-' }}</span>
                        @if($task->delegation_type === 'partial')
                            <span>{{ $task->students->count() }} طالبًا ضمن النطاق</span>
                        @endif
                    </div>

                    <div class="mt-3 small text-secondary">
                        أسندها لك: <strong class="text-dark">{{ $task->delegatedBy?->name ?? '-' }}</strong>
                    </div>
                    <div class="small text-secondary">
                        الدكتور المعتمد: <strong class="text-dark">{{ $task->category->doctor?->name ?? '-' }}</strong>
                    </div>
                    <div class="small text-secondary">
                        الموعد: <strong class="text-dark">{{ $task->due_at?->format('Y-m-d H:i') ?? 'غير محدد' }}</strong>
                    </div>

                    @if($task->notes)
                        <div class="mt-3 p-3 rounded-4 bg-light small text-secondary">{{ $task->notes }}</div>
                    @endif

                    <div class="mt-4">
                        <a href="{{ route($isDelegate ? 'delegate.authorized-grades.show' : 'student.authorized-grades.show', $task->category_id) }}"
                           class="btn btn-warning w-100 rounded-4 fw-800 text-dark">
                            فتح المهمة
                        </a>
                    </div>
                </div>
            </div>
        @endforeach
    </div>
@endif
@endsection
