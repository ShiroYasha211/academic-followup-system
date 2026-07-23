@extends('layouts.doctor')

@section('title', 'مركز تفويض الطلاب - ' . $subject->name)

@push('styles')
<style>
    :root {
        --glass-bg: rgba(255, 255, 255, 0.72);
        --glass-border: rgba(255, 255, 255, 0.32);
    }

    .premium-header {
        background: linear-gradient(135deg, #0ea5e9 0%, #2563eb 100%);
        border-radius: 24px;
        padding: 2.5rem;
        color: white;
        position: relative;
        overflow: hidden;
        margin-bottom: 2rem;
        box-shadow: 0 20px 40px -15px rgba(37, 99, 235, 0.3);
    }

    .premium-header::after {
        content: '';
        position: absolute;
        top: -50%;
        left: -10%;
        width: 400px;
        height: 400px;
        background: rgba(255, 255, 255, 0.1);
        border-radius: 50%;
        filter: blur(60px);
    }

    .glass-card {
        background: var(--glass-bg);
        backdrop-filter: blur(12px);
        -webkit-backdrop-filter: blur(12px);
        border: 1px solid var(--glass-border);
        border-radius: 24px;
        box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.07);
    }

    .assigned-badge {
        background: #f0fdf4;
        color: #16a34a;
        border: 1px solid #bbf7d0;
        padding: 0.4rem 1rem;
        border-radius: 10px;
        font-weight: 700;
        font-size: 0.85rem;
    }

    .btn-delegate {
        background: linear-gradient(135deg, #0ea5e9 0%, #2563eb 100%);
        color: white;
        border: none;
        padding: 0.75rem 1.5rem;
        border-radius: 14px;
        font-weight: 800;
        transition: all 0.3s ease;
    }

    .btn-delegate:hover {
        transform: scale(1.03);
        box-shadow: 0 8px 15px -3px rgba(37, 99, 235, 0.35);
        color: white;
    }

    .avatar-circle {
        width: 45px;
        height: 45px;
        background: #e0f2fe;
        color: #0369a1;
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: 900;
        border-radius: 12px;
        flex-shrink: 0;
    }

    .category-sidebar-item {
        padding: 1rem;
        border-radius: 16px;
        margin-bottom: 0.5rem;
        cursor: pointer;
        transition: all 0.2s ease;
        border: 1px solid transparent;
        border-right: 4px solid transparent;
    }

    .category-sidebar-item.active {
        background: white;
        border-color: #e2e8f0;
        border-right-color: #0284c7;
        box-shadow: 0 4px 12px rgba(0,0,0,0.05);
    }

    .category-sidebar-item:hover:not(.active) {
        background: rgba(255,255,255,0.4);
    }

    .delegate-pill {
        display: inline-flex;
        align-items: center;
        gap: 0.4rem;
        padding: 0.38rem 0.8rem;
        background: #eff6ff;
        color: #1d4ed8;
        border-radius: 999px;
        font-size: 0.78rem;
        font-weight: 800;
    }

    .candidate-wrapper {
        border: 1px solid #dbeafe;
        border-radius: 18px;
        overflow: hidden;
        background: white;
    }

    .candidate-table {
        margin-bottom: 0;
    }

    .candidate-table thead th {
        background: #eff6ff;
        color: #1e3a8a;
        font-size: 0.85rem;
        font-weight: 900;
        border: none;
        padding: 1rem;
    }

    .candidate-table tbody td {
        padding: 1rem;
        vertical-align: middle;
        border-color: #eef2ff;
    }

    .candidate-row {
        transition: background 0.2s ease;
    }

    .candidate-row:hover {
        background: #f8fbff;
    }

    .candidate-row.selected {
        background: #eff6ff;
    }

    .candidate-radio {
        width: 1.1rem;
        height: 1.1rem;
        accent-color: #2563eb;
        cursor: pointer;
    }

    .section-title {
        font-weight: 900;
        color: #0f172a;
        margin-bottom: 0.35rem;
    }

    .section-hint {
        color: #64748b;
        font-weight: 700;
        font-size: 0.85rem;
        margin-bottom: 1.25rem;
    }
</style>
@endpush

@section('content')
@php
    $roleLabels = [
        'student' => 'طالب',
        'delegate' => 'مندوب',
        'practical_delegate' => 'مندوب عملي',
    ];
@endphp

<div class="premium-header">
    <div class="d-flex flex-column flex-md-row justify-content-between align-items-md-center gap-4 position-relative" style="z-index: 2;">
        <div>
            <span class="badge px-3 py-2 rounded-pill mb-3 fw-700" style="background: rgba(255,255,255,0.2); color: white;">التحكم في صلاحيات الرصد</span>
            <h1 class="fw-900 mb-2" style="font-size: 2.5rem;">مركز تفويض الطلاب</h1>
            <p class="text-white text-opacity-80 fw-700 m-0">
                <i class="fa-solid fa-users-gear me-2"></i>{{ $subject->name }} | تفويض مهام رصد الدرجات داخل نفس التخصص والمستوى
            </p>
        </div>
        <div class="d-flex gap-3">
            <a href="{{ route('doctor.grades.categories.index', $subject->id) }}" class="btn px-4 rounded-4 fw-800 border-0" style="background: rgba(255,255,255,0.2); color: white;">توزيع الدرجات <i class="fa-solid fa-layer-group ms-2"></i></a>
            <a href="{{ route('doctor.grades.show', $subject->id) }}" class="btn bg-white px-4 rounded-4 fw-800 border-0 shadow-lg" style="color: #0ea5e9;">العودة للدرجات</a>
        </div>
    </div>
</div>

@if(session('success'))
    <div class="alert alert-success border-0 shadow-sm rounded-4 mb-4 fw-700">{{ session('success') }}</div>
@endif

@if(session('error'))
    <div class="alert alert-danger border-0 shadow-sm rounded-4 mb-4 fw-700">{{ session('error') }}</div>
@endif

<div class="row g-4">
    <div class="col-lg-8">
        @forelse($categories as $category)
            @php
                $availableStudents = $students->reject(fn ($student) => $category->permissions->contains('authorized_user_id', $student->id));
            @endphp

            <div class="delegation-content glass-card p-4 h-100 {{ $loop->first ? '' : 'd-none' }}" id="cat-{{ $category->id }}">
                <div class="d-flex justify-content-between align-items-start mb-4">
                    <div>
                        <h4 class="fw-900 text-dark mb-1">المفوضون لفئة: {{ $category->name }}</h4>
                        <p class="text-secondary fw-700 small mb-0">الصلاحيات الحالية لمن يملكون حق إدخال درجات هذه الفئة. الاعتماد النهائي يبقى للدكتور فقط.</p>
                    </div>
                    <div class="assigned-badge">الحد الأعلى: {{ $category->max_score }} درجة</div>
                </div>

                <div class="current-delegates mb-5">
                    <div class="section-title">الصلاحيات النشطة</div>
                    <div class="section-hint">المستخدمون التاليون يستطيعون إدخال درجات هذه الفئة حاليًا.</div>

                    <div class="row g-3">
                        @forelse($category->permissions as $permission)
                            @php
                                $user = $permission->authorizedUser;
                                $roleKey = $user->role->value ?? $user->role;
                            @endphp
                            <div class="col-md-6">
                                <div class="p-3 rounded-4 border bg-white d-flex justify-content-between align-items-center gap-3 h-100">
                                    <div class="d-flex align-items-center gap-3">
                                        <div class="avatar-circle">{{ mb_substr($user->name, 0, 1) }}</div>
                                        <div>
                                            <div class="fw-900 text-dark small">{{ $user->name }}</div>
                                            <div class="text-secondary fw-700" style="font-size: 11px;">رقم القيد: {{ $user->student_number ?? '-' }}</div>
                                            <div class="delegate-pill mt-2">{{ $roleLabels[$roleKey] ?? $roleKey }}</div>
                                        </div>
                                    </div>
                                    <form action="{{ route('doctor.grades.categories.revoke', $category->id) }}" method="POST">
                                        @csrf
                                        <input type="hidden" name="authorized_user_id" value="{{ $permission->authorized_user_id }}">
                                        <button type="submit" class="btn btn-link text-danger p-2 rounded-3">
                                            <i class="fa-solid fa-user-minus"></i>
                                        </button>
                                    </form>
                                </div>
                            </div>
                        @empty
                            <div class="col-12">
                                <div class="p-4 rounded-4 border border-dashed text-center bg-light bg-opacity-50">
                                    <i class="fa-solid fa-user-lock fa-2x text-light-emphasis mb-2"></i>
                                    <p class="text-secondary fw-700 m-0">لا يوجد مفوضون لهذه الفئة حاليًا.</p>
                                </div>
                            </div>
                        @endforelse
                    </div>
                </div>

                <div class="new-delegation pt-4 border-top">
                    <div class="section-title">إضافة مفوض جديد</div>
                    <div class="section-hint">
                        اختر من القائمة الكاملة في الأسفل. كل صف يوضح الاسم الكامل، رقم القيد، والدور الحالي للمستخدم بشكل منفصل وواضح.
                    </div>

                    <form action="{{ route('doctor.grades.categories.delegate', $category->id) }}" method="POST">
                        @csrf

                        <div class="candidate-wrapper mb-4">
                            <div class="table-responsive">
                                <table class="table candidate-table">
                                    <thead>
                                        <tr>
                                            <th style="width: 70px;" class="text-center">اختيار</th>
                                            <th>الاسم</th>
                                            <th>رقم القيد</th>
                                            <th>الدور</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        @forelse($availableStudents as $student)
                                            @php $roleKey = $student->role->value ?? $student->role; @endphp
                                            <tr class="candidate-row">
                                                <td class="text-center">
                                                    <input
                                                        class="candidate-radio"
                                                        type="radio"
                                                        name="authorized_user_id"
                                                        value="{{ $student->id }}"
                                                        onchange="highlightCandidate(this)"
                                                        required
                                                    >
                                                </td>
                                                <td class="fw-800">{{ $student->name }}</td>
                                                <td class="text-secondary fw-700">{{ $student->student_number ?? '-' }}</td>
                                                <td>
                                                    <span class="delegate-pill">{{ $roleLabels[$roleKey] ?? $roleKey }}</span>
                                                </td>
                                            </tr>
                                        @empty
                                            <tr>
                                                <td colspan="4" class="text-center py-4 text-secondary fw-700">
                                                    لا يوجد مستخدمون متاحون للتفويض في هذه الفئة حاليًا.
                                                </td>
                                            </tr>
                                        @endforelse
                                    </tbody>
                                </table>
                            </div>
                        </div>

                        @if($students->isEmpty())
                            <div class="text-secondary small fw-700 mb-3">لا يوجد طلاب أو مندوبيـن مطابقون لتخصص ومستوى هذه المادة.</div>
                        @elseif($availableStudents->isEmpty())
                            <div class="text-secondary small fw-700 mb-3">كل المستخدمين المؤهلين تم تفويضهم بالفعل في هذه الفئة.</div>
                        @endif

                        <div class="d-flex justify-content-end">
                            <button type="submit" class="btn btn-delegate" @disabled($availableStudents->isEmpty())>
                                منح الصلاحية
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        @empty
            <div class="glass-card p-5 text-center">
                <i class="fa-solid fa-layer-group fa-4x text-light-emphasis opacity-25 mb-4"></i>
                <h5 class="fw-900 text-secondary">لا توجد تصنيفات للدرجات بعد</h5>
                <p class="text-secondary">يجب عليك تحديد توزيع الدرجات أولًا حتى تتمكن من تفويض الطلاب.</p>
                <a href="{{ route('doctor.grades.categories.index', $subject->id) }}" class="btn btn-primary px-4 py-2 rounded-4 fw-800 mt-2">انتقل لتوزيع الدرجات</a>
            </div>
        @endforelse
    </div>

    <div class="col-lg-4">
        <div class="glass-card p-4 h-100">
            <h5 class="fw-900 mb-4 d-flex align-items-center gap-2">
                <i class="fa-solid fa-tags text-primary"></i>
                اختر الفئة للتفويض
            </h5>

            <div class="category-menu">
                @foreach($categories as $category)
                    <div class="category-sidebar-item {{ $loop->first ? 'active' : '' }}" onclick="switchCategory('cat-{{ $category->id }}', this)">
                        <div class="d-flex justify-content-between align-items-center">
                            <div>
                                <div class="fw-900 text-dark mb-0">{{ $category->name }}</div>
                                <small class="text-secondary fw-700">الدرجة: {{ $category->max_score }}</small>
                            </div>
                            <span class="badge rounded-pill bg-light text-dark border fw-800">{{ $category->permissions->count() }}</span>
                        </div>
                    </div>
                @endforeach
            </div>

            @if(count($categories) > 0)
                <div class="mt-5 p-3 rounded-4 bg-info bg-opacity-10 border border-info border-opacity-20">
                    <h6 class="fw-900 text-info mb-1 small">
                        <i class="fa-solid fa-circle-info me-1"></i> ملاحظة
                    </h6>
                    <p class="text-info-emphasis fw-700 m-0" style="font-size: 11px;">
                        تعرض القائمة في الأسفل كل المرشحين المؤهلين داخل نفس التخصص والمستوى، مع توضيح نوع الدور لكل مستخدم.
                    </p>
                </div>
            @endif
        </div>
    </div>
</div>

<script>
    function switchCategory(id, el) {
        document.querySelectorAll('.delegation-content').forEach(c => c.classList.add('d-none'));
        document.getElementById(id).classList.remove('d-none');

        document.querySelectorAll('.category-sidebar-item').forEach(i => i.classList.remove('active'));
        el.classList.add('active');
    }

    function highlightCandidate(input) {
        const table = input.closest('tbody');
        if (!table) return;

        table.querySelectorAll('.candidate-row').forEach((row) => row.classList.remove('selected'));
        input.closest('.candidate-row')?.classList.add('selected');
    }
</script>
@endsection
