@extends('layouts.delegate')

@section('title', 'درجات ' . $subject->name)

@section('content')

<style>
    .grades-table {
        width: 100%;
        border-collapse: separate;
        border-spacing: 0;
    }

    .grades-table thead th {
        background: #f8fafc;
        padding: 1rem;
        text-align: right;
        font-weight: 700;
        color: var(--text-secondary);
        font-size: 0.85rem;
        border-bottom: 2px solid #e2e8f0;
        position: sticky;
        top: 0;
    }

    .grades-table tbody td {
        padding: 1rem;
        border-bottom: 1px solid #f1f5f9;
        vertical-align: middle;
    }

    .grades-table tbody tr:hover {
        background: #f8fafc;
    }

    .student-info {
        display: flex;
        align-items: center;
        gap: 0.75rem;
    }

    .student-avatar {
        width: 40px;
        height: 40px;
        background: linear-gradient(135deg, #f1f5f9 0%, #e2e8f0 100%);
        border-radius: 12px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: 700;
        color: var(--text-secondary);
    }

    .grade-badge {
        display: inline-block;
        padding: 0.4rem 0.75rem;
        border-radius: 8px;
        font-weight: 700;
        font-size: 0.9rem;
        min-width: 60px;
        text-align: center;
    }

    .grade-badge.excellent {
        background: #ecfdf5;
        color: #10b981;
    }

    .grade-badge.good {
        background: #eff6ff;
        color: #3b82f6;
    }

    .grade-badge.average {
        background: #fffbeb;
        color: #f59e0b;
    }

    .grade-badge.fail {
        background: #fef2f2;
        color: #ef4444;
    }

    .type-badge {
        padding: 0.3rem 0.75rem;
        border-radius: 6px;
        font-size: 0.8rem;
        font-weight: 700;
    }

    .type-badge.continuous {
        background: #fef3c7;
        color: #d97706;
    }

    .type-badge.final {
        background: #dbeafe;
        color: #2563eb;
    }

    .table-wrapper {
        background: white;
        border-radius: 20px;
        overflow: hidden;
        border: 1px solid #e2e8f0;
    }
</style>

<div class="container">

    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 2rem;">
        <div>
            <h1 style="font-size: 1.75rem; font-weight: 800; color: var(--text-primary);">{{ $subject->name }}</h1>
            <p style="color: var(--text-secondary);">عرض وإدارة درجات الطلاب لهذه المادة.</p>
        </div>
        <div style="display: flex; gap: 0.75rem;">
            <a href="{{ route('delegate.grades.create', ['subject_id' => $subject->id]) }}" class="btn btn-primary" style="display: flex; align-items: center; gap: 0.5rem; border-radius: 12px;">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <line x1="12" y1="5" x2="12" y2="19"></line>
                    <line x1="5" y1="12" x2="19" y2="12"></line>
                </svg>
                إضافة درجات
            </a>
            <a href="{{ route('delegate.grades.index') }}" class="btn btn-secondary" style="display: flex; align-items: center; gap: 0.5rem; border-radius: 12px;">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <line x1="19" y1="12" x2="5" y2="12"></line>
                    <polyline points="12 19 5 12 12 5"></polyline>
                </svg>
                العودة
            </a>
        </div>
    </div>

    @if(session('success'))
    <div class="alert alert-success d-flex align-items-center gap-2 mb-4" style="border-radius: 12px;">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <polyline points="20 6 9 17 4 12"></polyline>
        </svg>
        {{ session('success') }}
    </div>
    @endif

    <div class="table-wrapper">
        @if($students->count() == 0)
        <div style="text-align: center; padding: 4rem;">
            <div style="color: var(--text-secondary);">
                <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
                    <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
                    <circle cx="9" cy="7" r="4"></circle>
                </svg>
            </div>
            <p style="color: var(--text-secondary); margin-top: 1rem;">لا يوجد طلاب في هذه الدفعة.</p>
        </div>
        @else
        <div class="table-responsive">
<table class="grades-table">
            <thead>
                <tr>
                    <th style="width: 50px;">#</th>
                    <th>الطالب</th>
                    <th>رقم القيد</th>
                    <th style="text-align: center;">محصلة (40%)</th>
                    <th style="text-align: center;">نهائي (60%)</th>
                    <th style="text-align: center;">المجموع</th>
                </tr>
            </thead>
            <tbody>
                @foreach($students as $index => $student)
                @php
                $studentGrades = $grades->get($student->id, collect());
                $continuous = $studentGrades->where('type', 'continuous')->first();
                $final = $studentGrades->where('type', 'final')->first();

                $continuousScore = $continuous ? $continuous->score : null;
                $finalScore = $final ? $final->score : null;

                // Calculate weighted total
                $total = null;
                if ($continuousScore !== null || $finalScore !== null) {
                $cWeight = $continuous ? ($continuousScore / $continuous->max_score) * 40 : 0;
                $fWeight = $final ? ($finalScore / $final->max_score) * 60 : 0;
                $total = $cWeight + $fWeight;
                }

                // Grade class
                $gradeClass = 'fail';
                if ($total !== null) {
                if ($total >= 85) $gradeClass = 'excellent';
                elseif ($total >= 70) $gradeClass = 'good';
                elseif ($total >= 50) $gradeClass = 'average';
                }
                @endphp
                <tr>
                    <td style="color: var(--text-secondary);">{{ $index + 1 }}</td>
                    <td>
                        <div class="student-info">
                            <div class="student-avatar">
                                {{ mb_substr($student->name, 0, 1) }}
                            </div>
                            <span style="font-weight: 700;">{{ $student->name }}</span>
                        </div>
                    </td>
                    <td style="font-family: monospace; color: var(--text-secondary);">{{ $student->student_number }}</td>
                    <td style="text-align: center;">
                        @if($continuousScore !== null)
                        <span class="grade-badge {{ $continuousScore >= 32 ? 'excellent' : ($continuousScore >= 24 ? 'good' : ($continuousScore >= 16 ? 'average' : 'fail')) }}">
                            {{ number_format($continuousScore, 1) }}
                        </span>
                        @else
                        <span style="color: var(--text-secondary);">-</span>
                        @endif
                    </td>
                    <td style="text-align: center;">
                        @if($finalScore !== null)
                        <span class="grade-badge {{ $finalScore >= 48 ? 'excellent' : ($finalScore >= 36 ? 'good' : ($finalScore >= 24 ? 'average' : 'fail')) }}">
                            {{ number_format($finalScore, 1) }}
                        </span>
                        @else
                        <span style="color: var(--text-secondary);">-</span>
                        @endif
                    </td>
                    <td style="text-align: center;">
                        @if($total !== null)
                        <span class="grade-badge {{ $gradeClass }}" style="font-size: 1rem;">
                            {{ number_format($total, 1) }}%
                        </span>
                        @else
                        <span style="color: var(--text-secondary);">-</span>
                        @endif
                    </td>
                </tr>
                @endforeach
            </tbody>
        </table>
</div>
        @endif
    </div>

</div>

@endsection