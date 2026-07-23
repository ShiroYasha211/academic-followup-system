@extends('layouts.doctor')

@section('title', 'تقرير الدرجات - ' . $subject->name)

@section('content')

<style>
    .back-link {
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
        color: var(--text-secondary);
        text-decoration: none;
        font-weight: 600;
        margin-bottom: 1.5rem;
    }

    .back-link:hover {
        color: var(--primary-color);
    }

    .report-header {
        background: linear-gradient(135deg, #4f46e5 0%, #6366f1 100%);
        border-radius: 20px;
        padding: 2rem;
        color: white;
        margin-bottom: 2rem;
    }

    .report-title {
        font-size: 1.75rem;
        font-weight: 800;
        margin-bottom: 0.5rem;
    }

    .report-meta {
        opacity: 0.9;
        font-size: 0.9rem;
    }

    .stats-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
        gap: 1rem;
        margin-bottom: 2rem;
    }

    .stat-card {
        background: white;
        border-radius: 16px;
        border: 1px solid #e2e8f0;
        padding: 1.25rem;
        text-align: center;
    }

    .stat-value {
        font-size: 2rem;
        font-weight: 800;
        margin-bottom: 0.25rem;
    }

    .stat-label {
        font-size: 0.85rem;
        color: var(--text-secondary);
    }

    .report-card {
        background: white;
        border-radius: 20px;
        border: 1px solid #e2e8f0;
        overflow: hidden;
    }

    .report-card-header {
        padding: 1.25rem 1.5rem;
        border-bottom: 1px solid #e2e8f0;
        display: flex;
        justify-content: space-between;
        align-items: center;
    }

    .report-table {
        width: 100%;
        border-collapse: collapse;
    }

    .report-table th {
        padding: 1rem 1.25rem;
        background: #f8fafc;
        font-weight: 700;
        color: var(--text-primary);
        text-align: right;
        font-size: 0.85rem;
        border-bottom: 1px solid #e2e8f0;
    }

    .report-table td {
        padding: 0.875rem 1.25rem;
        border-bottom: 1px solid #f1f5f9;
        vertical-align: middle;
    }

    .report-table tr:hover {
        background: #f8fafc;
    }

    .rank-badge {
        width: 32px;
        height: 32px;
        border-radius: 8px;
        font-weight: 700;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 0.85rem;
    }

    .rank-1 {
        background: linear-gradient(135deg, #fef3c7 0%, #fcd34d 100%);
        color: #92400e;
    }

    .rank-2 {
        background: linear-gradient(135deg, #e5e7eb 0%, #9ca3af 100%);
        color: #374151;
    }

    .rank-3 {
        background: linear-gradient(135deg, #fed7aa 0%, #fb923c 100%);
        color: #7c2d12;
    }

    .rank-normal {
        background: #f1f5f9;
        color: var(--text-secondary);
    }

    .student-cell {
        display: flex;
        align-items: center;
        gap: 0.75rem;
    }

    .student-avatar {
        width: 36px;
        height: 36px;
        border-radius: 10px;
        background: linear-gradient(135deg, #e0e7ff 0%, #c7d2fe 100%);
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: 700;
        color: #4f46e5;
        font-size: 0.85rem;
    }

    .student-name {
        font-weight: 600;
        color: var(--text-primary);
    }

    .student-number {
        font-size: 0.8rem;
        color: var(--text-secondary);
    }

    .grade-cell {
        font-weight: 600;
        text-align: center;
    }

    .total-badge {
        display: inline-block;
        padding: 0.35rem 0.75rem;
        border-radius: 8px;
        font-weight: 700;
    }

    .total-pass {
        background: #d1fae5;
        color: #065f46;
    }

    .total-fail {
        background: #fee2e2;
        color: #991b1b;
    }

    .status-badge {
        font-size: 0.8rem;
        padding: 0.25rem 0.6rem;
        border-radius: 6px;
        font-weight: 600;
    }

    .status-pass {
        background: #d1fae5;
        color: #065f46;
    }

    .status-fail {
        background: #fee2e2;
        color: #991b1b;
    }

    .chart-section {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
        gap: 1.5rem;
        margin-bottom: 2rem;
    }

    .chart-card {
        background: white;
        border-radius: 16px;
        border: 1px solid #e2e8f0;
        padding: 1.5rem;
    }

    .chart-title {
        font-weight: 700;
        margin-bottom: 1rem;
        display: flex;
        align-items: center;
        gap: 0.5rem;
    }

    .grade-dist {
        display: flex;
        flex-direction: column;
        gap: 0.75rem;
    }

    .grade-bar {
        display: flex;
        align-items: center;
        gap: 0.75rem;
    }

    .grade-label {
        width: 80px;
        font-weight: 600;
        font-size: 0.85rem;
    }

    .bar-track {
        flex: 1;
        height: 24px;
        background: #f1f5f9;
        border-radius: 6px;
        overflow: hidden;
        position: relative;
    }

    .bar-fill {
        height: 100%;
        border-radius: 6px;
        display: flex;
        align-items: center;
        justify-content: flex-end;
        padding-right: 0.5rem;
        color: white;
        font-weight: 600;
        font-size: 0.8rem;
        min-width: 30px;
    }

    .bar-excellent {
        background: linear-gradient(90deg, #10b981, #059669);
    }

    .bar-good {
        background: linear-gradient(90deg, #3b82f6, #2563eb);
    }

    .bar-pass {
        background: linear-gradient(90deg, #f59e0b, #d97706);
    }

    .bar-fail {
        background: linear-gradient(90deg, #ef4444, #dc2626);
    }
</style>

<a href="{{ route('doctor.grades.show', $subject->id) }}" class="back-link">
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <polyline points="15 18 9 12 15 6"></polyline>
    </svg>
    العودة لإدخال الدرجات
</a>

<!-- Report Header -->
<div class="report-header" style="display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 1rem;">
    <div>
        <h1 class="report-title">📊 التقرير الشامل</h1>
        <div class="report-meta">
            {{ $subject->name }} • {{ $subject->major->name ?? '' }} • {{ $subject->level->name ?? '' }}
        </div>
    </div>
    <div>
        <a href="{{ route('doctor.grades.report', ['subject' => $subject->id, 'format' => 'excel']) }}" style="display: inline-flex; align-items: center; gap: 0.5rem; border: 1px solid #e2e8f0; border-radius: 10px; padding: 0.6rem 1.25rem; font-weight: 600; color: #10b981; background: #10b98110; text-decoration: none; transition: all 0.2s;" onmouseover="this.style.background='#10b981'; this.style.color='white';" onmouseout="this.style.background='#10b98110'; this.style.color='#10b981';">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                <polyline points="7 10 12 15 17 10"></polyline>
                <line x1="12" y1="15" x2="12" y2="3"></line>
            </svg>
            تصدير Excel
        </a>
    </div>
</div>

<!-- Stats Grid -->
<div class="stats-grid">
    <div class="stat-card">
        <div class="stat-value" style="color: #3b82f6;">{{ $stats['students_count'] }}</div>
        <div class="stat-label">عدد الطلاب</div>
    </div>
    <div class="stat-card">
        <div class="stat-value" style="color: #8b5cf6;">{{ $stats['average'] }}</div>
        <div class="stat-label">المعدل العام</div>
    </div>
    <div class="stat-card">
        <div class="stat-value" style="color: #10b981;">{{ $stats['highest'] }}</div>
        <div class="stat-label">أعلى درجة</div>
    </div>
    <div class="stat-card">
        <div class="stat-value" style="color: #ef4444;">{{ $stats['lowest'] }}</div>
        <div class="stat-label">أقل درجة</div>
    </div>
    <div class="stat-card">
        <div class="stat-value" style="color: #10b981;">{{ $stats['passed'] }}</div>
        <div class="stat-label">ناجح</div>
    </div>
    <div class="stat-card">
        <div class="stat-value" style="color: #ef4444;">{{ $stats['failed'] }}</div>
        <div class="stat-label">راسب</div>
    </div>
</div>

<!-- Grade Distribution Chart -->
<div class="chart-section">
    <div class="chart-card">
        <h3 class="chart-title">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="color: var(--primary-color);">
                <line x1="18" y1="20" x2="18" y2="10"></line>
                <line x1="12" y1="20" x2="12" y2="4"></line>
                <line x1="6" y1="20" x2="6" y2="14"></line>
            </svg>
            توزيع الدرجات
        </h3>
        @php
        $excellent = $students->filter(fn($s) => $s->total >= 85)->count();
        $good = $students->filter(fn($s) => $s->total >= 70 && $s->total < 85)->count();
            $pass = $students->filter(fn($s) => $s->total >= 60 && $s->total < 70)->count();
                $fail = $students->filter(fn($s) => $s->total < 60)->count();
                    $maxCount = max($excellent, $good, $pass, $fail, 1);
                    @endphp
                    <div class="grade-dist">
                        <div class="grade-bar">
                            <div class="grade-label">ممتاز (85+)</div>
                            <div class="bar-track">
                                <div class="bar-fill bar-excellent" style="width: {{ round(($excellent / $maxCount) * 100) }}%;">{{ $excellent }}</div>
                            </div>
                        </div>
                        <div class="grade-bar">
                            <div class="grade-label">جيد (70-84)</div>
                            <div class="bar-track">
                                <div class="bar-fill bar-good" style="width: {{ round(($good / $maxCount) * 100) }}%;">{{ $good }}</div>
                            </div>
                        </div>
                        <div class="grade-bar">
                            <div class="grade-label">مقبول (60-69)</div>
                            <div class="bar-track">
                                <div class="bar-fill bar-pass" style="width: {{ round(($pass / $maxCount) * 100) }}%;">{{ $pass }}</div>
                            </div>
                        </div>
                        <div class="grade-bar">
                            <div class="grade-label">راسب (-60)</div>
                            <div class="bar-track">
                                <div class="bar-fill bar-fail" style="width: {{ round(($fail / $maxCount) * 100) }}%;">{{ $fail }}</div>
                            </div>
                        </div>
                    </div>
    </div>

    <div class="chart-card">
        <h3 class="chart-title">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="color: #10b981;">
                <polyline points="20 6 9 17 4 12"></polyline>
            </svg>
            نسبة النجاح
        </h3>
        <div style="text-align: center; padding: 1rem;">
            <div style="font-size: 4rem; font-weight: 800; color: {{ $stats['pass_rate'] >= 60 ? '#10b981' : '#ef4444' }};">{{ $stats['pass_rate'] }}%</div>
            <div style="font-size: 1.1rem; color: var(--text-secondary);">
                {{ $stats['passed'] }} من {{ $stats['students_count'] }} طالب
            </div>
            <div style="margin-top: 1rem; height: 12px; background: #f1f5f9; border-radius: 6px; overflow: hidden;">
                <div style="height: 100%; width: {{ $stats['pass_rate'] }}%; background: {{ $stats['pass_rate'] >= 60 ? 'linear-gradient(90deg, #10b981, #059669)' : 'linear-gradient(90deg, #ef4444, #dc2626)' }}; border-radius: 6px;"></div>
            </div>
        </div>
    </div>
</div>

<!-- Students Table (Ranked) -->
<div class="report-card">
    <div class="report-card-header">
        <h3 style="font-weight: 700; display: flex; align-items: center; gap: 0.5rem;">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="color: var(--primary-color);">
                <path d="M8 6L21 6"></path>
                <path d="M8 12L21 12"></path>
                <path d="M8 18L21 18"></path>
                <path d="M3 6L3.01 6"></path>
                <path d="M3 12L3.01 12"></path>
                <path d="M3 18L3.01 18"></path>
            </svg>
            ترتيب الطلاب
        </h3>
    </div>

    <div class="table-responsive">
<table class="report-table">
        <thead>
            <tr>
                <th style="width: 60px;">الترتيب</th>
                <th>الطالب</th>
                <th style="width: 100px;">أعمال السنة</th>
                <th style="width: 100px;">النهائي</th>
                <th style="width: 100px;">المجموع</th>
                <th style="width: 100px;">التقدير</th>
                <th style="width: 100px;">الحالة</th>
            </tr>
        </thead>
        <tbody>
            @foreach($students as $index => $student)
            <tr>
                <td>
                    <div class="rank-badge {{ $index < 3 ? 'rank-' . ($index + 1) : 'rank-normal' }}">
                        {{ $index + 1 }}
                    </div>
                </td>
                <td>
                    <div class="student-cell">
                        <div class="student-avatar">{{ mb_substr($student->name, 0, 1) }}</div>
                        <div>
                            <div class="student-name">{{ $student->name }}</div>
                            <div class="student-number">{{ $student->student_number ?? '-' }}</div>
                        </div>
                    </div>
                </td>
                <td class="grade-cell">{{ $student->continuous_grade_score ?? 0 }}/40</td>
                <td class="grade-cell">{{ $student->final_grade->score ?? 0 }}/60</td>
                <td>
                    <span class="total-badge {{ $student->total >= 60 ? 'total-pass' : 'total-fail' }}">
                        {{ $student->total }}/100
                    </span>
                </td>
                <td>
                    @php
                    $letterGrade = 'F';
                    $letterColor = '#ef4444'; // Red
                    $letterLabel = 'راسب';
                    if ($student->total >= 90) {
                    $letterGrade = 'A';
                    $letterColor = '#10b981'; // Green
                    $letterLabel = 'ممتاز';
                    } elseif ($student->total >= 80) {
                    $letterGrade = 'B';
                    $letterColor = '#3b82f6'; // Blue
                    $letterLabel = 'جيد جداً';
                    } elseif ($student->total >= 70) {
                    $letterGrade = 'C';
                    $letterColor = '#f59e0b'; // Amber
                    $letterLabel = 'جيد';
                    } elseif ($student->total >= 60) {
                    $letterGrade = 'D';
                    $letterColor = '#8b5cf6'; // Purple
                    $letterLabel = 'مقبول';
                    }
                    @endphp
                    <span style="font-weight: 700; color: {{ $letterColor }}; font-size: 0.9rem; padding: 0.2rem 0.5rem; background: {{ $letterColor }}20; border-radius: 6px;" title="{{ $letterGrade }}">
                        {{ $letterLabel }}
                    </span>
                </td>
                <td>
                    <span class="status-badge {{ $student->total >= 60 ? 'status-pass' : 'status-fail' }}">
                        {{ $student->total >= 60 ? 'ناجح' : 'راسب' }}
                    </span>
                </td>
            </tr>
            @endforeach
        </tbody>
    </table>
</div>
</div>

@endsection