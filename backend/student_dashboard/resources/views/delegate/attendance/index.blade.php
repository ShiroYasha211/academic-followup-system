@extends('layouts.delegate')

@section('title', 'رصد الحضور')

@section('content')
<style>
    .attendance-shell {
        display: flex;
        flex-direction: column;
        gap: 1.5rem;
    }

    .attendance-hero {
        background:
            radial-gradient(circle at top left, rgba(255, 255, 255, 0.14), transparent 30%),
            linear-gradient(135deg, #0f172a 0%, #1d4ed8 55%, #0ea5e9 100%);
        border-radius: 24px;
        padding: 2rem;
        color: white;
        display: flex;
        align-items: flex-end;
        justify-content: space-between;
        gap: 1rem;
        flex-wrap: wrap;
        box-shadow: 0 20px 40px -24px rgba(15, 23, 42, 0.55);
    }

    .hero-title {
        font-size: 1.9rem;
        font-weight: 800;
        margin: 0 0 .35rem;
        letter-spacing: -0.02em;
    }

    .hero-copy {
        margin: 0;
        max-width: 760px;
        color: rgba(255, 255, 255, 0.86);
        font-size: .98rem;
    }

    .hero-actions {
        display: flex;
        gap: .75rem;
        flex-wrap: wrap;
    }

    .hero-btn {
        border: 0;
        border-radius: 14px;
        padding: .85rem 1.1rem;
        display: inline-flex;
        align-items: center;
        gap: .55rem;
        font-weight: 700;
        text-decoration: none;
        cursor: pointer;
        transition: transform .18s ease, box-shadow .18s ease, background-color .18s ease;
    }

    .hero-btn:hover {
        transform: translateY(-1px);
    }

    .hero-btn.primary {
        background: white;
        color: #0f172a;
        box-shadow: 0 10px 25px -16px rgba(255, 255, 255, 0.9);
    }

    .hero-btn.secondary {
        background: rgba(255, 255, 255, 0.12);
        color: white;
        border: 1px solid rgba(255, 255, 255, 0.18);
    }

    .stats-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(170px, 1fr));
        gap: 1rem;
    }

    .stat-card {
        background: white;
        border: 1px solid #e2e8f0;
        border-radius: 20px;
        padding: 1.15rem 1.25rem;
        box-shadow: 0 12px 30px -24px rgba(15, 23, 42, 0.25);
    }

    .stat-label {
        color: #64748b;
        font-size: .82rem;
        font-weight: 700;
        margin-bottom: .45rem;
    }

    .stat-value {
        color: #0f172a;
        font-size: 1.7rem;
        font-weight: 800;
        line-height: 1;
    }

    .tab-strip {
        display: inline-flex;
        gap: .35rem;
        background: #e2e8f0;
        padding: .35rem;
        border-radius: 999px;
        width: fit-content;
    }

    .tab-pill {
        border: 0;
        border-radius: 999px;
        background: transparent;
        color: #475569;
        padding: .75rem 1.15rem;
        font-weight: 700;
        display: inline-flex;
        align-items: center;
        gap: .45rem;
        cursor: pointer;
    }

    .tab-pill.active {
        background: white;
        color: #0f172a;
        box-shadow: 0 8px 18px -16px rgba(15, 23, 42, .4);
    }

    .panel-card {
        background: white;
        border: 1px solid #e2e8f0;
        border-radius: 24px;
        overflow: hidden;
        box-shadow: 0 12px 30px -24px rgba(15, 23, 42, 0.28);
    }

    .panel-head {
        padding: 1.25rem 1.4rem;
        border-bottom: 1px solid #e2e8f0;
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 1rem;
        flex-wrap: wrap;
    }

    .panel-title {
        margin: 0;
        font-size: 1.05rem;
        font-weight: 800;
        color: #0f172a;
    }

    .panel-copy {
        margin: .25rem 0 0;
        color: #64748b;
        font-size: .88rem;
    }

    .table-wrap {
        overflow-x: auto;
    }

    .attendance-table {
        width: 100%;
        border-collapse: collapse;
    }

    .attendance-table th,
    .attendance-table td {
        padding: 1rem 1.15rem;
        border-bottom: 1px solid #f1f5f9;
        text-align: right;
        vertical-align: middle;
    }

    .attendance-table th {
        background: #f8fafc;
        color: #475569;
        font-size: .82rem;
        font-weight: 800;
        white-space: nowrap;
    }

    .attendance-table tr:hover td {
        background: #f8fbff;
    }

    .subject-cell {
        display: flex;
        align-items: center;
        gap: .8rem;
    }

    .subject-icon {
        width: 42px;
        height: 42px;
        border-radius: 12px;
        background: linear-gradient(135deg, #2563eb, #0ea5e9);
        color: white;
        display: flex;
        align-items: center;
        justify-content: center;
        flex-shrink: 0;
    }

    .subject-name {
        color: #0f172a;
        font-weight: 800;
        font-size: .95rem;
    }

    .subject-meta {
        color: #64748b;
        font-size: .82rem;
        margin-top: .12rem;
    }

    .status-chip {
        display: inline-flex;
        align-items: center;
        gap: .35rem;
        border-radius: 999px;
        padding: .42rem .75rem;
        font-size: .78rem;
        font-weight: 800;
        white-space: nowrap;
    }

    .status-chip.open {
        background: #ecfdf5;
        color: #047857;
        border: 1px solid #a7f3d0;
    }

    .status-chip.locked {
        background: #fef2f2;
        color: #b91c1c;
        border: 1px solid #fecaca;
    }

    .action-stack {
        display: flex;
        gap: .55rem;
        flex-wrap: wrap;
        justify-content: center;
    }

    .mini-btn {
        border: 0;
        border-radius: 12px;
        padding: .62rem .9rem;
        display: inline-flex;
        align-items: center;
        gap: .4rem;
        font-weight: 700;
        font-size: .84rem;
        text-decoration: none;
        cursor: pointer;
        transition: transform .18s ease, box-shadow .18s ease;
    }

    .mini-btn:hover {
        transform: translateY(-1px);
    }

    .mini-btn.primary {
        background: #2563eb;
        color: white;
    }

    .mini-btn.secondary {
        background: #eff6ff;
        color: #1d4ed8;
    }

    .mini-btn.special {
        background: #fff7ed;
        color: #c2410c;
    }

    .mini-btn.ghost {
        background: #f8fafc;
        color: #334155;
        border: 1px solid #e2e8f0;
    }

    .empty-state {
        padding: 3.5rem 2rem;
        text-align: center;
        color: #64748b;
    }

    .empty-title {
        color: #0f172a;
        font-size: 1.08rem;
        font-weight: 800;
        margin: 1rem 0 .35rem;
    }

    @media (max-width: 768px) {
        .attendance-hero {
            padding: 1.35rem;
        }

        .hero-title {
            font-size: 1.45rem;
        }

        .hero-actions {
            width: 100%;
        }

        .hero-btn {
            flex: 1 1 auto;
            justify-content: center;
        }
    }
</style>

@php
    $allowedSubjects = $subjects->filter(fn($subject) => $subject->allow_delegate_attendance);
    $reportCount = $sessions->total();
    $specialCount = $sessions->getCollection()->filter(fn($session) => ($session->lecture?->lecture_type ?? 'official') === 'special')->count();
@endphp

<div class="attendance-shell" x-data="{ activeTab: 'subjects' }">
    <div class="attendance-hero">
        <div>
            <h1 class="hero-title">رصد الحضور</h1>
            <p class="hero-copy">إدارة حضور الدفعة من مكان واحد: المواد الرسمية، والجلسات غير الرسمية المستقلة، وسجلات الحضور السابقة مع الوصول السريع للتعديل والطباعة.</p>
        </div>
        <div class="hero-actions">
            <a href="{{ route('delegate.attendance.unofficial.create') }}" class="hero-btn primary">
                <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                    <line x1="12" y1="5" x2="12" y2="19"></line>
                    <line x1="5" y1="12" x2="19" y2="12"></line>
                </svg>
                محاضرة غير رسمية
            </a>
            <a href="{{ route('delegate.subjects.index') }}" class="hero-btn secondary">
                <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                    <line x1="19" y1="12" x2="5" y2="12"></line>
                    <polyline points="12 19 5 12 12 5"></polyline>
                </svg>
                عودة للمواد
            </a>
        </div>
    </div>

    @if(session('success'))
        <div class="alert alert-success" style="margin-bottom: 0;">
            {{ session('success') }}
        </div>
    @endif

    <div class="stats-grid">
        <div class="stat-card">
            <div class="stat-label">مواد الدفعة</div>
            <div class="stat-value">{{ $subjects->count() }}</div>
        </div>
        <div class="stat-card">
            <div class="stat-label">مواد مفتوحة للتحضير</div>
            <div class="stat-value">{{ $allowedSubjects->count() }}</div>
        </div>
        <div class="stat-card">
            <div class="stat-label">جلسات مسجلة</div>
            <div class="stat-value">{{ $reportCount }}</div>
        </div>
        <div class="stat-card">
            <div class="stat-label">جلسات غير رسمية</div>
            <div class="stat-value">{{ $specialCount }}</div>
        </div>
    </div>

    <div class="tab-strip">
        <button type="button" class="tab-pill" :class="{ 'active': activeTab === 'subjects' }" @click="activeTab = 'subjects'">
            <svg xmlns="http://www.w3.org/2000/svg" width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                <polyline points="9 11 12 14 22 4"></polyline>
                <path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"></path>
            </svg>
            مواد التحضير
        </button>
        <button type="button" class="tab-pill" :class="{ 'active': activeTab === 'reports' }" @click="activeTab = 'reports'">
            <svg xmlns="http://www.w3.org/2000/svg" width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                <polyline points="14 2 14 8 20 8"></polyline>
                <line x1="16" y1="13" x2="8" y2="13"></line>
                <line x1="16" y1="17" x2="8" y2="17"></line>
            </svg>
            التقارير السابقة
        </button>
    </div>

    <section class="panel-card" x-show="activeTab === 'subjects'">
        <div class="panel-head">
            <div>
                <h2 class="panel-title">المواد المتاحة لرصد الحضور</h2>
                <p class="panel-copy">يمكنك فتح جلسة حضور مرتبطة بمادة، أو استخدام زر المحاضرة غير الرسمية بالأعلى لإنشاء جلسة مستقلة لا ترتبط بأي مادة مسجلة.</p>
            </div>
        </div>

        @if($subjects->isEmpty())
            <div class="empty-state">
                <svg xmlns="http://www.w3.org/2000/svg" width="62" height="62" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path>
                    <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path>
                </svg>
                <div class="empty-title">لا توجد مواد مرتبطة بهذه الدفعة</div>
                <div>لن تظهر أي جلسة حضور رسمية قبل إسناد مواد للمستوى الحالي، لكن يمكنك ما زلت إنشاء محاضرة غير رسمية مستقلة من الأعلى.</div>
            </div>
        @else
            <div class="table-wrap">
                <table class="attendance-table">
                    <thead>
                        <tr>
                            <th style="width: 62px;">#</th>
                            <th>المادة</th>
                            <th>دكتور المادة</th>
                            <th>الحالة</th>
                            <th style="text-align: center;">الإجراءات</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach($subjects as $index => $subject)
                            <tr>
                                <td>{{ $index + 1 }}</td>
                                <td>
                                    <div class="subject-cell">
                                        <div class="subject-icon">
                                            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.1" stroke-linecap="round" stroke-linejoin="round">
                                                <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path>
                                                <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path>
                                            </svg>
                                        </div>
                                        <div>
                                            <div class="subject-name">{{ $subject->name }}</div>
                                            <div class="subject-meta">{{ $subject->code }}</div>
                                        </div>
                                    </div>
                                </td>
                                <td>{{ $subject->doctor->name ?? 'غير محدد' }}</td>
                                <td>
                                    @if($subject->allow_delegate_attendance)
                                        <span class="status-chip open">
                                            <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                                                <polyline points="20 6 9 17 4 12"></polyline>
                                            </svg>
                                            التحضير متاح
                                        </span>
                                    @else
                                        <span class="status-chip locked">
                                            <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round">
                                                <rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect>
                                                <path d="M7 11V7a5 5 0 0 1 10 0v4"></path>
                                            </svg>
                                            مقفل من الدكتور
                                        </span>
                                    @endif
                                </td>
                                <td style="text-align: center;">
                                    @if($subject->allow_delegate_attendance)
                                        <div class="action-stack">
                                            <a href="{{ route('delegate.attendance.create', $subject->id) }}" class="mini-btn primary">
                                                رصد رسمي
                                            </a>
                                        </div>
                                    @else
                                        <span style="color: #94a3b8; font-size: .84rem;">غير متاح</span>
                                    @endif
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        @endif
    </section>

    <section class="panel-card" x-show="activeTab === 'reports'">
        <div class="panel-head">
            <div>
                <h2 class="panel-title">سجلات الحضور السابقة</h2>
                <p class="panel-copy">راجع جلسات الحضور المسجلة، وافتح التقرير، أو عد إلى شاشة الرصد لنفس الجلسة لتحديث البيانات.</p>
            </div>
        </div>

        @if($sessions->isEmpty())
            <div class="empty-state">
                <svg xmlns="http://www.w3.org/2000/svg" width="62" height="62" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round">
                    <rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect>
                    <line x1="16" y1="2" x2="16" y2="6"></line>
                    <line x1="8" y1="2" x2="8" y2="6"></line>
                    <line x1="3" y1="10" x2="21" y2="10"></line>
                </svg>
                <div class="empty-title">لا توجد جلسات حضور مسجلة بعد</div>
                <div>عند حفظ أول جلسة حضور ستظهر السجلات هنا مباشرة، سواء كانت مرتبطة بمادة أو جلسة غير رسمية مستقلة.</div>
            </div>
        @else
            <div class="table-wrap">
                <table class="attendance-table">
                    <thead>
                        <tr>
                            <th>المرجع</th>
                            <th>عنوان الجلسة</th>
                            <th>التاريخ</th>
                            <th>نوع الجلسة</th>
                            <th>عدد الطلاب</th>
                            <th style="text-align: center;">الإجراءات</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach($sessions as $session)
                            <tr>
                                <td>
                                    <div class="subject-name">{{ $session->display_subject_name }}</div>
                                    <div class="subject-meta">{{ $session->display_subject_code }}</div>
                                </td>
                                <td>
                                    <div class="subject-name">{{ $session->lecture?->title ?? '-' }}</div>
                                    <div class="subject-meta">
                                        @if($session->lecture?->lecture_number)
                                            #{{ $session->lecture->lecture_number }}
                                        @else
                                            بدون رقم
                                        @endif
                                    </div>
                                </td>
                                <td>{{ $session->date->format('Y-m-d') }}</td>
                                <td>
                                    @if($session->is_unofficial)
                                        <span class="status-chip" style="background:#fff7ed;color:#c2410c;border:1px solid #fdba74;">غير رسمية مستقلة</span>
                                    @elseif(($session->lecture?->lecture_type ?? 'official') === 'special')
                                        <span class="status-chip" style="background:#fef3c7;color:#b45309;border:1px solid #fcd34d;">خاصة</span>
                                    @else
                                        <span class="status-chip" style="background:#eff6ff;color:#1d4ed8;border:1px solid #bfdbfe;">رسمية</span>
                                    @endif
                                </td>
                                <td>{{ $session->total_records }} طالب</td>
                                <td style="text-align: center;">
                                    <div class="action-stack">
                                        @if($session->is_unofficial)
                                            <a href="{{ route('delegate.attendance.unofficial.create', ['date' => $session->date->format('Y-m-d'), 'lecture_id' => $session->lecture_id]) }}" class="mini-btn ghost">
                                                تعديل
                                            </a>
                                            <a href="{{ route('delegate.attendance.unofficial.report', $session->lecture_id) }}" class="mini-btn secondary" target="_blank">
                                                التقرير
                                            </a>
                                        @else
                                            <a href="{{ route('delegate.attendance.create', $session->subject_id) }}?date={{ $session->date->format('Y-m-d') }}&lecture_id={{ $session->lecture_id }}" class="mini-btn ghost">
                                                تعديل
                                            </a>
                                            <a href="{{ route('delegate.attendance.report', ['subject' => $session->subject_id, 'date' => $session->date->format('Y-m-d'), 'lecture_id' => $session->lecture_id]) }}" class="mini-btn secondary" target="_blank">
                                                التقرير
                                            </a>
                                        @endif
                                    </div>
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>

            @if($sessions->hasPages())
                <div style="padding: 1rem 1.25rem; border-top: 1px solid #e2e8f0;">
                    {{ $sessions->links() }}
                </div>
            @endif
        @endif
    </section>
</div>
@endsection
