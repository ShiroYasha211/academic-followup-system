@extends('layouts.admin')

@section('title', 'إدارة النجوم والمكافآت')

@section('content')
<style>
/* ═══════════════════════════════════════════════════
   STARS MANAGEMENT — Design System
   Stack: Bootstrap 5 RTL + Alpine.js + Font Awesome
════════════════════════════════════════════════════ */

/* ── Page Header ── */
.stars-page-header {
    background: linear-gradient(135deg, #78350f 0%, #b45309 40%, #d97706 100%);
    border-radius: 24px;
    padding: 2rem 2.5rem;
    color: #fff;
    margin-bottom: 2rem;
    position: relative;
    overflow: hidden;
    box-shadow: 0 20px 40px -10px rgba(180, 83, 9, 0.35);
}
.stars-page-header::before {
    content: '';
    position: absolute;
    inset: 0;
    background: url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%23ffffff' fill-opacity='0.04'%3E%3Cpath d='M36 34v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6 34v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6 4V0H4v4H0v2h4v4h2V6h4V4H6z'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E");
}
.stars-page-header .header-icon {
    width: 64px; height: 64px;
    border-radius: 20px;
    background: rgba(255,255,255,0.15);
    backdrop-filter: blur(8px);
    border: 1px solid rgba(255,255,255,0.2);
    display: grid; place-items: center;
    font-size: 1.75rem;
    flex-shrink: 0;
}

/* ── Summary Cards ── */
.summary-cards-row { display: grid; grid-template-columns: repeat(4, 1fr); gap: 1rem; margin-bottom: 2rem; }
@media (max-width: 992px) { .summary-cards-row { grid-template-columns: repeat(2, 1fr); } }
@media (max-width: 576px) { .summary-cards-row { grid-template-columns: 1fr; } }

.summary-card {
    background: #fff;
    border: 1px solid #f1f5f9;
    border-radius: 20px;
    padding: 1.4rem 1.5rem;
    display: flex; align-items: center; gap: 1rem;
    box-shadow: 0 4px 16px rgba(15,23,42,0.06);
    transition: transform 0.2s, box-shadow 0.2s;
}
.summary-card:hover { transform: translateY(-2px); box-shadow: 0 8px 24px rgba(15,23,42,0.1); }
.summary-card .sc-icon {
    width: 50px; height: 50px; border-radius: 15px;
    display: grid; place-items: center; font-size: 1.3rem; flex-shrink: 0;
}
.summary-card .sc-value { font-size: 1.6rem; font-weight: 900; line-height: 1; color: #0f172a; font-variant-numeric: tabular-nums; }
.summary-card .sc-label { font-size: 0.78rem; color: #64748b; font-weight: 600; margin-top: 0.2rem; }

/* ── Tab Navigation ── */
.stars-tabs-nav {
    background: #f8fafc;
    border: 1px solid #e2e8f0;
    border-radius: 16px;
    padding: 6px;
    display: inline-flex; gap: 6px;
    margin-bottom: 1.5rem;
}
.stars-tab-btn {
    padding: 0.6rem 1.5rem;
    border-radius: 11px;
    border: none; background: transparent;
    font-weight: 700; font-size: 0.9rem; color: #64748b;
    cursor: pointer; display: flex; align-items: center; gap: 0.5rem;
    transition: all 0.2s; white-space: nowrap;
}
.stars-tab-btn.active {
    background: #fff;
    color: #b45309;
    box-shadow: 0 2px 8px rgba(15,23,42,0.1);
}
.stars-tab-btn .tab-badge {
    background: #fef3c7; color: #92400e;
    padding: 1px 7px; border-radius: 999px; font-size: 0.72rem; font-weight: 800;
}
.stars-tab-btn.active .tab-badge { background: #f59e0b; color: #fff; }

/* ── Filter Card ── */
.filter-panel {
    background: #fff;
    border: 1px solid #e2e8f0;
    border-radius: 20px;
    padding: 1.5rem 1.75rem;
    margin-bottom: 1.5rem;
    box-shadow: 0 4px 20px rgba(15, 23, 42, 0.04);
}
.filter-panel .filter-title {
    font-size: 0.95rem; font-weight: 800; color: #1e293b;
    margin-bottom: 0.5rem;
    display: flex; align-items: center; gap: 0.5rem;
}
.filter-section-title {
    font-size: 0.82rem;
    font-weight: 800;
    color: #475569;
    margin-bottom: 0.75rem;
    display: flex;
    align-items: center;
    gap: 0.5rem;
}
.filter-section-title i {
    color: #b45309;
}
.academic-group-box {
    background: #f8fafc;
    border: 1px solid #e2e8f0;
    border-radius: 14px;
    padding: 1.25rem 1.25rem;
    margin-bottom: 1.25rem;
}
.academic-group-box.honor-theme {
    background: #fffbeb;
    border-color: #fde68a;
}
.filter-btn-submit {
    background: #0f172a;
    color: #fff;
    border: none;
    border-radius: 10px;
    font-weight: 700;
    font-size: 0.88rem;
    padding: 0.55rem 1.75rem;
    transition: all 0.2s;
    display: inline-flex;
    align-items: center;
    gap: 0.4rem;
}
.filter-btn-submit:hover {
    background: #1e293b;
    transform: translateY(-1px);
}
.filter-btn-reset {
    background: #f1f5f9;
    color: #475569;
    border: 1px solid #e2e8f0;
    border-radius: 10px;
    font-weight: 700;
    font-size: 0.88rem;
    padding: 0.55rem 1.25rem;
    transition: all 0.2s;
    display: inline-flex;
    align-items: center;
    gap: 0.4rem;
    text-decoration: none;
}
.filter-btn-reset:hover {
    background: #e2e8f0;
    color: #0f172a;
    transform: translateY(-1px);
}
.filter-input {
    transition: all 0.2s;
}
.filter-input:focus {
    border-color: #f59e0b !important;
    box-shadow: 0 0 0 3px rgba(245, 158, 11, 0.15) !important;
}

/* ── Table Card ── */
.table-card {
    background: #fff;
    border: 1px solid #e2e8f0;
    border-radius: 20px;
    overflow: hidden;
    box-shadow: 0 4px 16px rgba(15,23,42,0.05);
}
.table-card .table th {
    background: #f8fafc;
    font-weight: 800; color: #475569;
    padding: 0.9rem 1rem; font-size: 0.8rem;
    border-bottom: 1px solid #e2e8f0;
    white-space: nowrap;
}
.table-card .table td {
    padding: 0.85rem 1rem;
    vertical-align: middle;
    border-bottom: 1px solid #f8fafc;
    font-size: 0.88rem;
}
.table-card .table tbody tr:hover { background: #fffbeb; }
.table-card .table tbody tr:last-child td { border-bottom: none; }

/* ── User info in table ── */
.user-avatar {
    width: 36px; height: 36px; border-radius: 11px;
    display: grid; place-items: center;
    font-weight: 900; font-size: 0.85rem;
    flex-shrink: 0;
}
.stars-chip {
    display: inline-flex; align-items: center; gap: 5px;
    background: #fffbeb; color: #92400e;
    border: 1px solid #fde68a;
    padding: 3px 10px; border-radius: 999px;
    font-weight: 800; font-size: 0.82rem;
    font-variant-numeric: tabular-nums;
}
.role-chip { font-size: 0.72rem; padding: 2px 8px; border-radius: 6px; font-weight: 700; }
.role-student  { background: #ede9fe; color: #6d28d9; }
.role-delegate { background: #fce7f3; color: #be185d; }
.role-prac     { background: #dcfce7; color: #15803d; }
.path-chips { display: flex; flex-wrap: wrap; gap: 4px; }
.path-chip {
    background: #f1f5f9; color: #475569;
    font-size: 0.72rem; padding: 2px 7px; border-radius: 5px; font-weight: 600;
}

/* ── Bulk Action Bar ── */
.bulk-action-bar {
    background: #0f172a;
    border-radius: 16px;
    padding: 1rem 1.5rem;
    display: flex; align-items: center; gap: 1rem;
    margin-top: 1rem;
    flex-wrap: wrap;
    box-shadow: 0 8px 24px rgba(15,23,42,0.25);
}

/* ── Podium (Honor Board) ── */
.podium-section { padding: 2rem 1.5rem 1rem; }
.podium-wrapper { display: flex; align-items: flex-end; justify-content: center; gap: 1rem; margin-bottom: 2rem; }
.podium-spot { display: flex; flex-direction: column; align-items: center; gap: 0.5rem; flex: 1; max-width: 220px; }
.podium-avatar-wrap { position: relative; }
.podium-avatar {
    width: 72px; height: 72px; border-radius: 22px;
    display: grid; place-items: center;
    font-weight: 900; font-size: 1.4rem;
}
.podium-spot.rank-1 .podium-avatar { width: 88px; height: 88px; font-size: 1.7rem; border-radius: 26px; }
.podium-crown {
    position: absolute; top: -16px; left: 50%; transform: translateX(-50%);
    font-size: 1.2rem; filter: drop-shadow(0 2px 4px rgba(0,0,0,0.2));
}
.podium-name { font-weight: 800; font-size: 0.88rem; color: #0f172a; text-align: center; }
.podium-meta { font-size: 0.72rem; color: #64748b; text-align: center; }
.podium-score {
    font-weight: 900; font-variant-numeric: tabular-nums;
    font-size: 1.05rem;
}
.podium-base {
    width: 100%; border-radius: 14px 14px 0 0;
    display: grid; place-items: center;
    font-weight: 900; font-size: 1.4rem; color: rgba(255,255,255,0.5);
    padding: 0.6rem;
}
.rank-1 .podium-base { height: 80px; background: linear-gradient(135deg, #f59e0b, #d97706); }
.rank-2 .podium-base { height: 55px; background: linear-gradient(135deg, #94a3b8, #64748b); }
.rank-3 .podium-base { height: 40px; background: linear-gradient(135deg, #b45309, #92400e); }

/* ── Honor List (after top 3) ── */
.honor-list-item {
    display: flex; align-items: center; gap: 0.85rem;
    padding: 0.75rem 1.25rem;
    border-bottom: 1px solid #f8fafc;
    transition: background 0.15s;
}
.honor-list-item:hover { background: #fffbeb; }
.honor-list-item:last-child { border-bottom: none; }
.honor-rank-badge {
    width: 32px; height: 32px; border-radius: 9px;
    display: grid; place-items: center;
    font-weight: 900; font-size: 0.78rem;
    background: #f1f5f9; color: #475569;
    flex-shrink: 0; font-variant-numeric: tabular-nums;
}

/* ── Quick Action Modal Trigger ── */
.btn-quick-grant {
    padding: 4px 10px; border-radius: 8px;
    font-size: 0.76rem; font-weight: 700;
    border: 1px solid transparent;
    cursor: pointer; transition: all 0.15s;
    display: inline-flex; align-items: center; gap: 4px;
}
.btn-quick-grant:hover { transform: scale(1.05); }
.btn-qa-grant { background: #fef3c7; color: #92400e; border-color: #fde68a; }
.btn-qa-grant:hover { background: #fde68a; }
.btn-qa-deduct { background: #fee2e2; color: #b91c1c; border-color: #fecaca; }
.btn-qa-deduct:hover { background: #fecaca; }

/* ── Quick Action Modal ── */
.qa-modal-overlay {
    position: fixed; inset: 0; background: rgba(0,0,0,0.5);
    backdrop-filter: blur(4px); z-index: 1050;
    display: flex; align-items: center; justify-content: center;
}
.qa-modal-box {
    background: #fff; border-radius: 24px;
    padding: 2rem; width: 100%; max-width: 460px;
    box-shadow: 0 25px 50px rgba(0,0,0,0.25);
    position: relative;
}

/* ── Honor Filter Panel ── */
.honor-filter-bar {
    background: linear-gradient(135deg, #fff7ed, #fff);
    border: 1px solid #fde68a;
    border-radius: 16px;
    padding: 1rem 1.5rem;
    margin-bottom: 1.5rem;
}

/* ── Empty State ── */
.empty-state { text-align: center; padding: 3rem 1rem; color: #94a3b8; }
.empty-state .empty-icon { font-size: 3rem; margin-bottom: 0.75rem; opacity: 0.35; }

/* ── Pagination ── */
.pagination-wrap { padding: 1rem 1.5rem; border-top: 1px solid #f1f5f9; background: #fafbfc; }
</style>

{{-- ░░░ PAGE HEADER ░░░ --}}
<div class="stars-page-header d-flex align-items-center gap-3">
    <div class="header-icon"><i class="fa-solid fa-star"></i></div>
    <div style="position:relative; z-index:1;">
        <h1 class="fw-black mb-1" style="font-size:1.55rem; letter-spacing:-0.03em;">إدارة النجوم والمكافآت</h1>
        <p class="mb-0 opacity-75" style="font-size:0.9rem;">منح وخصم النجوم بشكل فردي أو جماعي، ومتابعة لوحة شرف أفضل المستخدمين.</p>
    </div>
</div>

{{-- ░░░ SUMMARY CARDS ░░░ --}}
<div class="summary-cards-row">
    <div class="summary-card">
        <div class="sc-icon" style="background:#fef3c7; color:#d97706;"><i class="fa-solid fa-star"></i></div>
        <div>
            <div class="sc-value">{{ number_format($summaryStats['total_stars']) }}</div>
            <div class="sc-label">إجمالي النجوم في النظام</div>
        </div>
    </div>
    <div class="summary-card">
        <div class="sc-icon" style="background:#ede9fe; color:#7c3aed;"><i class="fa-solid fa-users"></i></div>
        <div>
            <div class="sc-value">{{ number_format($summaryStats['students_with_stars']) }}</div>
            <div class="sc-label">طالب لديه نجوم</div>
        </div>
    </div>
    <div class="summary-card">
        <div class="sc-icon" style="background:#dcfce7; color:#16a34a;"><i class="fa-solid fa-crown"></i></div>
        <div>
            <div class="sc-value">{{ number_format($summaryStats['top_balance']) }}</div>
            <div class="sc-label">أعلى رصيد لطالب واحد</div>
        </div>
    </div>
    <div class="summary-card">
        <div class="sc-icon" style="background:#fee2e2; color:#dc2626;"><i class="fa-solid fa-calendar-day"></i></div>
        <div>
            <div class="sc-value">{{ number_format($summaryStats['today_granted']) }}</div>
            <div class="sc-label">نجوم منحت اليوم</div>
        </div>
    </div>
</div>

{{-- ░░░ SUCCESS / ERROR ALERTS ░░░ --}}
@if(session('success'))
    <div class="alert d-flex align-items-center gap-2 mb-3" style="background:#f0fdf4; border:1px solid #bbf7d0; border-radius:14px; color:#15803d;">
        <i class="fa-solid fa-circle-check"></i> {{ session('success') }}
    </div>
@endif
@if(session('error'))
    <div class="alert d-flex align-items-center gap-2 mb-3" style="background:#fef2f2; border:1px solid #fecaca; border-radius:14px; color:#b91c1c;">
        <i class="fa-solid fa-triangle-exclamation"></i> {{ session('error') }}
    </div>
@endif

{{-- ░░░ ALPINE COMPONENT ░░░ --}}
<div x-data="starsManager()">

    {{-- ── Tab Navigation ── --}}
    <div class="stars-tabs-nav">
        <button class="stars-tab-btn" :class="{ active: tab === 'students' }" @click="tab = 'students'">
            <i class="fa-solid fa-users"></i>
            <span>إدارة الطلاب</span>
            <span class="tab-badge">{{ $students->total() }}</span>
        </button>
        <button class="stars-tab-btn" :class="{ active: tab === 'honor' }" @click="tab = 'honor'">
            <i class="fa-solid fa-crown"></i>
            <span>لوحة الشرف</span>
            <span class="tab-badge">{{ $honorStats['count'] }}</span>
        </button>
    </div>

    {{-- ══════════════════════════════════════════════════════════
         TAB 1 — STUDENTS MANAGEMENT
    ══════════════════════════════════════════════════════════ --}}
    <div x-show="tab === 'students'" x-transition:enter="transition ease-out duration-200"
         x-transition:enter-start="opacity-0 translate-y-2" x-transition:enter-end="opacity-100 translate-y-0">

        {{-- Students Filters --}}
        <div class="filter-panel">
            <div class="filter-title mb-3"><i class="fa-solid fa-sliders"></i> خيارات التصفية والبحث</div>
            <form action="{{ route('admin.stars.index') }}" method="GET" x-ref="studentsForm">
                <input type="hidden" name="_tab" value="students">
                
                {{-- Row 1: Basic Filters --}}
                <div class="row g-3 mb-3">
                    {{-- Search --}}
                    <div class="col-md-6">
                        <label class="form-label small fw-bold text-muted mb-1">البحث النصي</label>
                        <div class="input-group">
                            <span class="input-group-text bg-white border-end-0" style="border-radius:10px 0 0 10px; border: 1px solid #cbd5e1;"><i class="fa-solid fa-magnifying-glass text-muted fa-sm"></i></span>
                            <input type="text" name="search" class="form-control border-start-0 filter-input" placeholder="ابحث باسم الطالب، البريد الإلكتروني، أو رقم القيد..." value="{{ request('search') }}" style="border-radius:0 10px 10px 0; border: 1px solid #cbd5e1; font-size: 0.85rem;">
                        </div>
                    </div>
                    {{-- Role --}}
                    <div class="col-md-3">
                        <label class="form-label small fw-bold text-muted mb-1">دور المستخدم</label>
                        <select name="role_filter" class="form-select filter-input" style="border-radius:10px; border: 1px solid #cbd5e1; font-size: 0.85rem;">
                            <option value="">كل الأدوار</option>
                            <option value="student"           {{ request('role_filter') == 'student'            ? 'selected' : '' }}>طالب</option>
                            <option value="delegate"          {{ request('role_filter') == 'delegate'           ? 'selected' : '' }}>مندوب دفعة</option>
                            <option value="practical_delegate"{{ request('role_filter') == 'practical_delegate' ? 'selected' : '' }}>مندوب عملي</option>
                        </select>
                    </div>
                    {{-- Status --}}
                    <div class="col-md-3">
                        <label class="form-label small fw-bold text-muted mb-1">حالة الحساب</label>
                        <select name="status_filter" class="form-select filter-input" style="border-radius:10px; border: 1px solid #cbd5e1; font-size: 0.85rem;">
                            <option value="">كل الحالات</option>
                            <option value="active"   {{ request('status_filter') == 'active'   ? 'selected' : '' }}>نشط</option>
                            <option value="inactive" {{ request('status_filter') == 'inactive' ? 'selected' : '' }}>معطل</option>
                        </select>
                    </div>
                </div>

                {{-- Row 2: Academic Group Box --}}
                <div class="academic-group-box">
                    <div class="filter-section-title"><i class="fa-solid fa-graduation-cap"></i> التصفية حسب المسار الأكاديمي</div>
                    <div class="row g-3">
                        {{-- University --}}
                        <div class="col-md-3">
                            <label class="form-label small fw-bold text-muted mb-1">الجامعة</label>
                            <select name="university_id" class="form-select filter-input" style="border-radius:10px; border: 1px solid #cbd5e1; font-size: 0.85rem;" x-model="uniId" @change="loadColleges">
                                <option value="">كل الجامعات</option>
                                @foreach($universities as $uni)
                                    <option value="{{ $uni->id }}" {{ request('university_id') == $uni->id ? 'selected' : '' }}>{{ $uni->name }}</option>
                                @endforeach
                            </select>
                        </div>
                        {{-- College --}}
                        <div class="col-md-3">
                            <label class="form-label small fw-bold text-muted mb-1">الكلية</label>
                            <select name="college_id" class="form-select filter-input" style="border-radius:10px; border: 1px solid #cbd5e1; font-size: 0.85rem;" x-model="colId" @change="loadMajors" :disabled="!colleges.length">
                                <option value="">كل الكليات</option>
                                <template x-for="c in colleges" :key="c.id">
                                    <option :value="c.id" x-text="c.name" :selected="c.id == colId"></option>
                                </template>
                            </select>
                        </div>
                        {{-- Major --}}
                        <div class="col-md-3">
                            <label class="form-label small fw-bold text-muted mb-1">التخصص</label>
                            <select name="major_id" class="form-select filter-input" style="border-radius:10px; border: 1px solid #cbd5e1; font-size: 0.85rem;" x-model="majId" @change="loadLevels" :disabled="!majors.length">
                                <option value="">كل التخصصات</option>
                                <template x-for="m in majors" :key="m.id">
                                    <option :value="m.id" x-text="m.name" :selected="m.id == majId"></option>
                                </template>
                            </select>
                        </div>
                        {{-- Level --}}
                        <div class="col-md-3">
                            <label class="form-label small fw-bold text-muted mb-1">المستوى</label>
                            <select name="level_id" class="form-select filter-input" style="border-radius:10px; border: 1px solid #cbd5e1; font-size: 0.85rem;" :disabled="!levels.length">
                                <option value="">كل المستويات</option>
                                <template x-for="l in levels" :key="l.id">
                                    <option :value="l.id" x-text="l.name" :selected="l.id == {{ request('level_id', 0) }}"></option>
                                </template>
                            </select>
                        </div>
                    </div>
                </div>

                {{-- Row 3: Buttons --}}
                <div class="d-flex justify-content-start gap-2">
                    <button type="submit" class="filter-btn-submit">
                        <i class="fa-solid fa-filter me-1"></i> تطبيق الفلترة
                    </button>
                    <a href="{{ route('admin.stars.index') }}" class="filter-btn-reset" title="إعادة تعيين الفلاتر">
                        <i class="fa-solid fa-rotate-right me-1"></i> إعادة تعيين
                    </a>
                </div>
            </form>
        </div>

        {{-- Students Table --}}
        <form action="{{ route('admin.stars.grant') }}" method="POST">
            @csrf
            <div class="table-card">
                <div class="table-responsive">
                    <table class="table mb-0">
                        <thead>
                            <tr>
                                <th width="36">
                                    <input type="checkbox" class="form-check-input" x-model="selectAll" @change="toggleAll">
                                </th>
                                <th>المستخدم</th>
                                <th>المسار الأكاديمي</th>
                                <th>الرصيد الحالي</th>
                                <th>إجمالي مكتسب</th>
                                <th>الحالة</th>
                                <th>إجراء سريع</th>
                            </tr>
                        </thead>
                        <tbody>
                            @forelse($students as $student)
                            <tr>
                                <td>
                                    <input type="checkbox" name="student_ids[]" value="{{ $student->id }}"
                                           x-model="selected" class="form-check-input student-cb">
                                </td>
                                <td>
                                    <div class="d-flex align-items-center gap-2">
                                        <div class="user-avatar" style="background:#fef3c7; color:#d97706;">
                                            {{ mb_strtoupper(mb_substr($student->name, 0, 1)) }}
                                        </div>
                                        <div>
                                            <div class="fw-bold d-flex align-items-center gap-1" style="font-size:0.88rem; color:#0f172a;">
                                                {{ $student->name }}
                                                @if($student->role === \App\Enums\UserRole::DELEGATE)
                                                    <span class="role-chip role-delegate">مندوب</span>
                                                @elseif($student->role === \App\Enums\UserRole::PRACTICAL_DELEGATE)
                                                    <span class="role-chip role-prac">م.عملي</span>
                                                @else
                                                    <span class="role-chip role-student">طالب</span>
                                                @endif
                                            </div>
                                            <div class="text-muted" style="font-size:0.75rem; direction:ltr; text-align:start;">
                                                {{ $student->student_number ?? $student->email }}
                                            </div>
                                        </div>
                                    </div>
                                </td>
                                <td>
                                    <div class="path-chips">
                                        <span class="path-chip">{{ $student->university->name ?? '—' }}</span>
                                        <span class="path-chip">{{ $student->major->name ?? '—' }}</span>
                                        <span class="path-chip">{{ $student->level->name ?? '—' }}</span>
                                    </div>
                                </td>
                                <td>
                                    <span class="stars-chip">
                                        <i class="fa-solid fa-star fa-xs"></i>
                                        {{ number_format($student->stars_balance) }}
                                    </span>
                                </td>
                                <td>
                                    <span style="font-size:0.82rem; color:#64748b; font-variant-numeric:tabular-nums; font-weight:700;">
                                        {{ number_format($student->total_stars_earned ?? 0) }}
                                    </span>
                                </td>
                                <td>
                                    @if($student->status === 'active')
                                        <span style="background:#dcfce7; color:#15803d; padding:3px 10px; border-radius:999px; font-size:0.75rem; font-weight:700;">نشط</span>
                                    @else
                                        <span style="background:#fee2e2; color:#b91c1c; padding:3px 10px; border-radius:999px; font-size:0.75rem; font-weight:700;">معطل</span>
                                    @endif
                                </td>
                                <td>
                                    <div class="d-flex gap-1">
                                        <button type="button" class="btn-quick-grant btn-qa-grant"
                                            @click="openQA({{ $student->id }}, '{{ addslashes($student->name) }}', 'grant')">
                                            <i class="fa-solid fa-plus fa-xs"></i> منح
                                        </button>
                                        <button type="button" class="btn-quick-grant btn-qa-deduct"
                                            @click="openQA({{ $student->id }}, '{{ addslashes($student->name) }}', 'deduct')">
                                            <i class="fa-solid fa-minus fa-xs"></i> خصم
                                        </button>
                                    </div>
                                </td>
                            </tr>
                            @empty
                            <tr>
                                <td colspan="7">
                                    <div class="empty-state">
                                        <div class="empty-icon"><i class="fa-solid fa-users-slash"></i></div>
                                        <div class="fw-bold mb-1">لا يوجد طلاب مطابقون للفلاتر</div>
                                        <div class="small">جرب تغيير خيارات البحث أو مسح الفلاتر.</div>
                                    </div>
                                </td>
                            </tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>

                {{-- Pagination --}}
                @if($students->hasPages())
                <div class="pagination-wrap">{{ $students->links() }}</div>
                @endif
            </div>

            {{-- ── Bulk Action Bar ── --}}
            <div class="bulk-action-bar" x-show="selected.length > 0" x-transition style="display:none;">
                <div class="text-white fw-bold" style="white-space:nowrap;">
                    <i class="fa-solid fa-check-square me-1 text-yellow-400" style="color:#fbbf24;"></i>
                    <span x-text="selected.length"></span> محدد
                </div>
                <div class="input-group" style="width:140px;">
                    <span class="input-group-text" style="border-radius:10px 0 0 10px; background:#1e293b; border-color:#334155; color:#f59e0b;">
                        <i class="fa-solid fa-star fa-xs"></i>
                    </span>
                    <input type="number" name="amount" value="10" min="-1000" max="1000"
                           class="form-control fw-bold" style="border-radius:0 10px 10px 0; background:#1e293b; border-color:#334155; color:#fff;"
                           placeholder="المقدار" required>
                </div>
                <input type="text" name="description"
                       class="form-control" style="background:#1e293b; border-color:#334155; color:#fff; border-radius:10px; flex:1; min-width:200px;"
                       placeholder="سبب العملية (مثال: مشاركة متميزة)..." required>
                <div class="text-slate-400 small" style="color:#94a3b8; font-size:0.72rem; white-space:nowrap;">
                    موجب = منح<br>سالب = خصم
                </div>
                <button type="submit" class="btn btn-warning fw-bold px-4" style="border-radius:10px; white-space:nowrap;">
                    <i class="fa-solid fa-bolt me-1"></i> تنفيذ
                </button>
                <button type="button" class="btn btn-outline-secondary btn-sm" style="border-radius:10px; border-color:#475569; color:#94a3b8;"
                        @click="selected = []; selectAll = false;">
                    <i class="fa-solid fa-xmark"></i>
                </button>
            </div>
        </form>
    </div>{{-- /tab students --}}

    {{-- ══════════════════════════════════════════════════════════
         TAB 2 — HONOR BOARD
    ══════════════════════════════════════════════════════════ --}}
    <div x-show="tab === 'honor'" x-transition:enter="transition ease-out duration-200"
         x-transition:enter-start="opacity-0 translate-y-2" x-transition:enter-end="opacity-100 translate-y-0">

        {{-- Honor Board Filters --}}
        <div class="filter-panel">
            <div class="d-flex align-items-center justify-content-between mb-3 flex-wrap gap-2">
                <div class="filter-title m-0"><i class="fa-solid fa-crown text-warning"></i> تصفية لوحة الشرف</div>
                
                {{-- Stats pills --}}
                <div class="d-flex gap-2 flex-wrap">
                    <span style="background:#fffbeb; border:1px solid #fde68a; color:#92400e; border-radius:999px; padding:4px 12px; font-size:0.76rem; font-weight:800; font-variant-numeric:tabular-nums;">
                        {{ number_format($honorStats['count']) }} مستخدم
                    </span>
                    <span style="background:#fffbeb; border:1px solid #fde68a; color:#92400e; border-radius:999px; padding:4px 12px; font-size:0.76rem; font-weight:800; font-variant-numeric:tabular-nums;">
                        إجمالي: {{ number_format($honorStats['total_balance']) }} ⭐
                    </span>
                    <span style="background:#fffbeb; border:1px solid #fde68a; color:#92400e; border-radius:999px; padding:4px 12px; font-size:0.76rem; font-weight:800; font-variant-numeric:tabular-nums;">
                        أعلى: {{ number_format($honorStats['top_balance']) }} ⭐
                    </span>
                </div>
            </div>

            <form action="{{ route('admin.stars.index') }}" method="GET">
                <input type="hidden" name="_tab" value="honor">
                
                {{-- Row 1: Basic Filters --}}
                <div class="row g-3 mb-3">
                    {{-- Role --}}
                    <div class="col-md-6">
                        <label class="form-label small fw-bold text-muted mb-1">دور المستخدم</label>
                        <select name="h_role_filter" class="form-select filter-input" style="border-radius:10px; border: 1px solid #cbd5e1; font-size: 0.85rem;">
                            <option value="">كل الأدوار</option>
                            <option value="student"            {{ request('h_role_filter') == 'student'            ? 'selected' : '' }}>طالب</option>
                            <option value="delegate"           {{ request('h_role_filter') == 'delegate'           ? 'selected' : '' }}>مندوب دفعة</option>
                            <option value="practical_delegate" {{ request('h_role_filter') == 'practical_delegate' ? 'selected' : '' }}>مندوب عملي</option>
                        </select>
                    </div>
                    {{-- Min Stars --}}
                    <div class="col-md-6">
                        <label class="form-label small fw-bold text-muted mb-1">الحد الأدنى لرصيد النجوم</label>
                        <div class="input-group">
                            <span class="input-group-text bg-white border-end-0" style="border-radius:10px 0 0 10px; border: 1px solid #cbd5e1; color:#d97706;"><i class="fa-solid fa-star fa-sm"></i></span>
                            <input type="number" name="h_min_stars" class="form-control border-start-0 filter-input" placeholder="مثال: 50 نجمة..." value="{{ request('h_min_stars') }}" style="border-radius:0 10px 10px 0; border: 1px solid #cbd5e1; font-size: 0.85rem; font-variant-numeric:tabular-nums;">
                        </div>
                    </div>
                </div>

                {{-- Row 2: Academic Group Box --}}
                <div class="academic-group-box honor-theme">
                    <div class="filter-section-title"><i class="fa-solid fa-graduation-cap text-amber-700"></i> التصفية حسب المسار الأكاديمي</div>
                    <div class="row g-3">
                        {{-- University --}}
                        <div class="col-md-3">
                            <label class="form-label small fw-bold text-muted mb-1">الجامعة</label>
                            <select name="h_university_id" class="form-select filter-input" style="border-radius:10px; border: 1px solid #cbd5e1; font-size: 0.85rem;" x-model="hUniId" @change="loadHColleges">
                                <option value="">كل الجامعات</option>
                                @foreach($universities as $uni)
                                    <option value="{{ $uni->id }}" {{ request('h_university_id') == $uni->id ? 'selected' : '' }}>{{ $uni->name }}</option>
                                @endforeach
                            </select>
                        </div>
                        {{-- College --}}
                        <div class="col-md-3">
                            <label class="form-label small fw-bold text-muted mb-1">الكلية</label>
                            <select name="h_college_id" class="form-select filter-input" style="border-radius:10px; border: 1px solid #cbd5e1; font-size: 0.85rem;" x-model="hColId" @change="loadHMajors" :disabled="!hColleges.length">
                                <option value="">كل الكليات</option>
                                <template x-for="c in hColleges" :key="c.id">
                                    <option :value="c.id" x-text="c.name" :selected="c.id == hColId"></option>
                                </template>
                            </select>
                        </div>
                        {{-- Major --}}
                        <div class="col-md-3">
                            <label class="form-label small fw-bold text-muted mb-1">التخصص</label>
                            <select name="h_major_id" class="form-select filter-input" style="border-radius:10px; border: 1px solid #cbd5e1; font-size: 0.85rem;" x-model="hMajId" @change="loadHLevels" :disabled="!hMajors.length">
                                <option value="">كل التخصصات</option>
                                <template x-for="m in hMajors" :key="m.id">
                                    <option :value="m.id" x-text="m.name" :selected="m.id == hMajId"></option>
                                </template>
                            </select>
                        </div>
                        {{-- Level --}}
                        <div class="col-md-3">
                            <label class="form-label small fw-bold text-muted mb-1">المستوى</label>
                            <select name="h_level_id" class="form-select filter-input" style="border-radius:10px; border: 1px solid #cbd5e1; font-size: 0.85rem;" :disabled="!hLevels.length">
                                <option value="">كل المستويات</option>
                                <template x-for="l in hLevels" :key="l.id">
                                    <option :value="l.id" x-text="l.name" :selected="l.id == {{ request('h_level_id', 0) }}"></option>
                                </template>
                            </select>
                        </div>
                    </div>
                </div>

                {{-- Row 3: Buttons --}}
                <div class="d-flex justify-content-start gap-2">
                    <button type="submit" class="filter-btn-submit" style="background: #b45309;">
                        <i class="fa-solid fa-filter me-1"></i> تطبيق الفلترة
                    </button>
                    <a href="{{ route('admin.stars.index') }}?_tab=honor" class="filter-btn-reset" title="إعادة تعيين الفلاتر">
                        <i class="fa-solid fa-rotate-right me-1"></i> إعادة تعيين
                    </a>
                </div>
            </form>
        </div>

        {{-- Podium + List --}}
        @if($honorBoard->isNotEmpty())
            <div class="table-card">
                {{-- PODIUM for top 3 --}}
                @if($honorBoard->count() >= 1)
                <div class="podium-section">
                    <div class="text-center mb-3">
                        <span style="font-size:0.8rem; font-weight:800; color:#92400e; text-transform:uppercase; letter-spacing:0.08em;">
                            <i class="fa-solid fa-trophy me-1"></i> أفضل المتصدرين
                        </span>
                    </div>
                    <div class="podium-wrapper">
                        {{-- Rank 2 --}}
                        @if($honorBoard->count() >= 2)
                        @php $s2 = $honorBoard[1]; @endphp
                        <div class="podium-spot rank-2">
                            <div class="podium-avatar-wrap">
                                <div class="podium-avatar" style="background:#e2e8f0; color:#475569;">
                                    {{ mb_strtoupper(mb_substr($s2->name, 0, 1)) }}
                                </div>
                            </div>
                            <div class="podium-name">{{ $s2->name }}</div>
                            <div class="podium-meta">{{ $s2->major->name ?? '—' }}</div>
                            <div class="podium-score" style="color:#475569;">{{ number_format($s2->stars_balance) }} <span style="font-size:0.72rem;">⭐</span></div>
                            <div class="podium-base">2</div>
                        </div>
                        @endif

                        {{-- Rank 1 --}}
                        @php $s1 = $honorBoard[0]; @endphp
                        <div class="podium-spot rank-1">
                            <div class="podium-avatar-wrap">
                                <div class="podium-crown">👑</div>
                                <div class="podium-avatar" style="background:linear-gradient(135deg,#fef3c7,#fde68a); color:#d97706; box-shadow:0 8px 24px rgba(217,119,6,0.3);">
                                    {{ mb_strtoupper(mb_substr($s1->name, 0, 1)) }}
                                </div>
                            </div>
                            <div class="podium-name" style="font-size:1rem;">{{ $s1->name }}</div>
                            <div class="podium-meta">{{ $s1->major->name ?? '—' }}</div>
                            <div class="podium-score" style="color:#d97706; font-size:1.2rem;">{{ number_format($s1->stars_balance) }} <span style="font-size:0.78rem;">⭐</span></div>
                            <div class="podium-base">1</div>
                        </div>

                        {{-- Rank 3 --}}
                        @if($honorBoard->count() >= 3)
                        @php $s3 = $honorBoard[2]; @endphp
                        <div class="podium-spot rank-3">
                            <div class="podium-avatar-wrap">
                                <div class="podium-avatar" style="background:#fef3c7; color:#b45309;">
                                    {{ mb_strtoupper(mb_substr($s3->name, 0, 1)) }}
                                </div>
                            </div>
                            <div class="podium-name">{{ $s3->name }}</div>
                            <div class="podium-meta">{{ $s3->major->name ?? '—' }}</div>
                            <div class="podium-score" style="color:#b45309;">{{ number_format($s3->stars_balance) }} <span style="font-size:0.72rem;">⭐</span></div>
                            <div class="podium-base">3</div>
                        </div>
                        @endif
                    </div>

                    {{-- Separator --}}
                    @if($honorBoard->count() > 3)
                    <div class="text-center mb-2">
                        <span style="font-size:0.75rem; color:#94a3b8; font-weight:700; text-transform:uppercase; letter-spacing:0.06em;">
                            — بقية الترتيب —
                        </span>
                    </div>
                    @endif
                </div>
                @endif

                {{-- Rest of the list --}}
                @foreach($honorBoard->slice(3) as $idx => $hs)
                @php $rank = $idx + 4; @endphp
                <div class="honor-list-item">
                    <div class="honor-rank-badge">{{ $rank }}</div>
                    <div class="user-avatar" style="background:#f1f5f9; color:#475569; border-radius:11px;">
                        {{ mb_strtoupper(mb_substr($hs->name, 0, 1)) }}
                    </div>
                    <div style="flex:1; min-width:0;">
                        <div class="fw-bold" style="font-size:0.88rem; color:#0f172a; white-space:nowrap; overflow:hidden; text-overflow:ellipsis;">{{ $hs->name }}</div>
                        <div style="font-size:0.74rem; color:#64748b; white-space:nowrap; overflow:hidden; text-overflow:ellipsis;">
                            {{ $hs->student_number ?? $hs->email }} — {{ $hs->major->name ?? '—' }} / {{ $hs->level->name ?? '—' }}
                        </div>
                    </div>
                    <div class="stars-chip">
                        <i class="fa-solid fa-star fa-xs"></i> {{ number_format($hs->stars_balance) }}
                    </div>
                </div>
                @endforeach
            </div>

        @else
            <div class="table-card">
                <div class="empty-state">
                    <div class="empty-icon"><i class="fa-solid fa-crown"></i></div>
                    <div class="fw-bold mb-1">لا توجد نتائج في لوحة الشرف</div>
                    <div class="small">جرب توسيع الفلاتر أو التأكد من منح نجوم للطلاب أولاً.</div>
                </div>
            </div>
        @endif
    </div>{{-- /tab honor --}}

    {{-- ══════════════════════════════════════════════════════════
         QUICK ACTION MODAL (Single Student)
    ══════════════════════════════════════════════════════════ --}}
    <div class="qa-modal-overlay" x-show="qaOpen" @click.self="qaOpen = false" x-transition style="display:none;">
        <div class="qa-modal-box" @click.stop>
            <button type="button" @click="qaOpen = false"
                    style="position:absolute; top:1rem; left:1rem; background:none; border:none; font-size:1.2rem; color:#94a3b8; cursor:pointer;">
                <i class="fa-solid fa-xmark"></i>
            </button>

            <div class="d-flex align-items-center gap-3 mb-4">
                <div style="width:48px; height:48px; border-radius:15px; display:grid; place-items:center; font-size:1.3rem;"
                     :style="qaMode === 'grant' ? 'background:#fef3c7; color:#d97706;' : 'background:#fee2e2; color:#b91c1c;'">
                    <i :class="qaMode === 'grant' ? 'fa-solid fa-plus' : 'fa-solid fa-minus'"></i>
                </div>
                <div>
                    <div class="fw-black" style="font-size:1.1rem; color:#0f172a;" x-text="qaMode === 'grant' ? 'منح نجوم' : 'خصم نجوم'"></div>
                    <div style="font-size:0.82rem; color:#64748b;">المستخدم: <span class="fw-bold text-dark" x-text="qaStudentName"></span></div>
                </div>
            </div>

            <form :action="'{{ route('admin.stars.grant') }}'" method="POST">
                @csrf
                <input type="hidden" name="student_ids[]" :value="qaStudentId">

                <div class="mb-3">
                    <label class="form-label fw-bold mb-1" style="font-size:0.85rem;">عدد النجوم</label>
                    <input type="number" name="amount" class="form-control fw-bold" style="border-radius:12px; font-size:1.1rem;"
                           :value="qaMode === 'grant' ? 10 : -10"
                           :min="qaMode === 'grant' ? 1 : -1000"
                           :max="qaMode === 'grant' ? 1000 : -1"
                           required>
                    <div class="form-text" x-text="qaMode === 'grant' ? 'أدخل عدداً موجباً للمنح.' : 'أدخل عدداً سالباً للخصم (مثال: -10).'"></div>
                </div>

                <div class="mb-4">
                    <label class="form-label fw-bold mb-1" style="font-size:0.85rem;">سبب العملية</label>
                    <input type="text" name="description" class="form-control" style="border-radius:12px;"
                           :placeholder="qaMode === 'grant' ? 'مثال: مشاركة فعّالة في النقاش...' : 'مثال: سلوك غير لائق...'"
                           required maxlength="255">
                </div>

                <div class="d-flex gap-2">
                    <button type="submit" class="btn flex-grow-1 fw-bold" style="border-radius:12px;"
                            :style="qaMode === 'grant' ? 'background:#f59e0b; color:#fff;' : 'background:#dc2626; color:#fff;'">
                        <i :class="qaMode === 'grant' ? 'fa-solid fa-plus me-2' : 'fa-solid fa-minus me-2'"></i>
                        <span x-text="qaMode === 'grant' ? 'تأكيد المنح' : 'تأكيد الخصم'"></span>
                    </button>
                    <button type="button" @click="qaOpen = false" class="btn btn-light border" style="border-radius:12px; padding:0 1.5rem;">إلغاء</button>
                </div>
            </form>
        </div>
    </div>

</div>{{-- /x-data --}}

@push('scripts')
<script>
document.addEventListener('alpine:init', () => {
    Alpine.data('starsManager', () => ({

        // Tabs
        tab: '{{ request('_tab', 'students') }}',

        // Students table selection
        selected: [],
        selectAll: false,

        // Cascading Filters (Students tab)
        uniId: '{{ request('university_id', '') }}',
        colId: '{{ request('college_id', '') }}',
        majId: '{{ request('major_id', '') }}',
        colleges: [],
        majors: [],
        levels: [],

        // Cascading Filters (Honor Board tab)
        hUniId: '{{ request('h_university_id', '') }}',
        hColId: '{{ request('h_college_id', '') }}',
        hMajId: '{{ request('h_major_id', '') }}',
        hColleges: [],
        hMajors: [],
        hLevels: [],

        // Quick Action modal
        qaOpen: false,
        qaStudentId: null,
        qaStudentName: '',
        qaMode: 'grant', // 'grant' | 'deduct'

        async init() {
            if (this.uniId) {
                await this.loadColleges();
                if (this.colId) {
                    await this.loadMajors();
                    if (this.majId) await this.loadLevels();
                }
            }
            if (this.hUniId) {
                await this.loadHColleges();
                if (this.hColId) {
                    await this.loadHMajors();
                    if (this.hMajId) await this.loadHLevels();
                }
            }
        },

        toggleAll() {
            this.selected = this.selectAll
                ? Array.from(document.querySelectorAll('.student-cb')).map(c => c.value)
                : [];
        },

        openQA(id, name, mode) {
            this.qaStudentId   = id;
            this.qaStudentName = name;
            this.qaMode        = mode;
            this.qaOpen        = true;
        },

        async loadColleges() {
            this.colleges = []; this.majors = []; this.levels = [];
            if (!this.uniId) return;
            const res = await fetch(`/api/public/colleges/${this.uniId}`);
            const json = await res.json();
            this.colleges = json.data || [];
        },

        async loadMajors() {
            this.majors = []; this.levels = [];
            if (!this.colId) return;
            const res = await fetch(`/api/public/majors/${this.colId}`);
            const json = await res.json();
            this.majors = json.data || [];
        },

        async loadLevels() {
            this.levels = [];
            if (!this.majId) return;
            const res = await fetch(`/api/public/levels/${this.majId}`);
            const json = await res.json();
            this.levels = json.data || [];
        },

        async loadHColleges() {
            this.hColleges = []; this.hMajors = []; this.hLevels = [];
            if (!this.hUniId) return;
            const res = await fetch(`/api/public/colleges/${this.hUniId}`);
            const json = await res.json();
            this.hColleges = json.data || [];
        },

        async loadHMajors() {
            this.hMajors = []; this.hLevels = [];
            if (!this.hColId) return;
            const res = await fetch(`/api/public/majors/${this.hColId}`);
            const json = await res.json();
            this.hMajors = json.data || [];
        },

        async loadHLevels() {
            this.hLevels = [];
            if (!this.hMajId) return;
            const res = await fetch(`/api/public/levels/${this.hMajId}`);
            const json = await res.json();
            this.hLevels = json.data || [];
        },
    }));
});
</script>
@endpush
@endsection
