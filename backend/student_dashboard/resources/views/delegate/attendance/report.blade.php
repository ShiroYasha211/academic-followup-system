@extends('layouts.delegate')

@section('title', $subject ? ('تقرير حضور: ' . $subject->name) : 'تقرير حضور غير رسمي')

@section('content')

<style>
    @if($pdfMode ?? false)
    body,
    .report-container,
    .report-container * {
        font-family: 'DejaVu Sans', sans-serif !important;
        direction: rtl;
        unicode-bidi: embed;
    }
    @endif

    @media print {
        @page {
            size: A4;
            margin: 0.5cm;
        }

        body {
            background: white;
            font-family: {{ ($pdfMode ?? false) ? "'DejaVu Sans', sans-serif" : "'Tajawal', sans-serif" }};
            -webkit-print-color-adjust: exact;
            print-color-adjust: exact;
        }

        /* Hide UI Elements explicitly */
        .sidebar,
        .top-header,
        .btn,
        footer,
        .no-print,
        .mobile-toggle,
        .desktop-toggle,
        .user-menu {
            display: none !important;
        }

        .main-content {
            margin: 0 !important;
            padding: 0 !important;
            width: 100% !important;
            background: white !important;
        }

        .container {
            max-width: 100% !important;
            margin: 0 !important;
            padding: 0 !important;
            box-shadow: none !important;
        }

        .card {
            box-shadow: none !important;
            border: none !important;
            padding: 0 !important;
        }

        /* Official Report Styling */
        .report-container {
            border: 2px solid #000;
            padding: 1rem;
            min-height: 28cm;
            position: relative;
        }

        .report-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 2px solid #000;
            padding-bottom: 1rem;
            margin-bottom: 1.5rem;
        }

        .header-right,
        .header-left {
            text-align: center;
            width: 30%;
        }

        .header-right h3,
        .header-left h3 {
            font-size: 1rem;
            margin: 2px 0;
            font-weight: bold;
        }

        .header-center {
            text-align: center;
            width: 30%;
        }

        .university-logo-placeholder {
            width: 80px;
            height: 80px;
            border: 1px dashed #999;
            margin: 0 auto;
            display: flex;
            align-items: center;
            justify-content: center;
            border-radius: 50%;
            background: #f9f9f9;
        }

        .report-title {
            text-align: center;
            margin: 1.5rem 0;
            font-size: 1.4rem;
            font-weight: 900;
            text-decoration: underline;
        }

        .meta-grid {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 1rem;
            margin-bottom: 1.5rem;
            border: 1px solid #000;
            padding: 0.5rem;
            background: #f8f9fa;
        }

        .meta-item {
            display: flex;
            flex-direction: column;
            gap: 0.2rem;
            font-size: 0.9rem;
        }

        .meta-label {
            font-weight: bold;
            color: #555;
        }

        table {
            width: 100% !important;
            border-collapse: collapse !important;
            font-size: 10pt;
            margin-bottom: 2rem;
        }

        th,
        td {
            border: 1px solid #000 !important;
            padding: 6px !important;
            text-align: center;
        }

        th {
            background-color: #e5e7eb !important;
            font-weight: bold;
        }

        .report-footer {
            margin-top: 3rem;
            display: flex;
            justify-content: space-between;
            page-break-inside: avoid;
        }

        .footer-sign {
            text-align: center;
            width: 30%;
        }

        .footer-sign p {
            margin-bottom: 3rem;
            font-weight: bold;
        }
    }
</style>

@php
    $reportUniversity = $subject?->major?->college?->university ?? $delegate?->major?->college?->university;
    $reportCollege = $subject?->major?->college ?? $delegate?->major?->college;
    $reportMajor = $subject?->major ?? $delegate?->major;
    $reportLevel = $subject?->level?->name ?? $delegate?->level?->name ?? '-';
    $reportSubjectLine = $subject ? "{$subject->name} ({$subject->code})" : 'محاضرة غير رسمية غير مرتبطة بمادة';
    $reportLectureType = ($isUnofficial ?? false)
        ? 'محاضرة غير رسمية مستقلة'
        : (($lecture?->lecture_type ?? 'official') === 'special' ? 'محاضرة خاصة' : 'محاضرة رسمية');
    $reportDoctorName = $subject?->doctor?->name ?? 'غير مرتبطة بدكتور مادة';
@endphp

<div class="container" style="max-width: 100%;">

    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 2rem;" class="no-print">
        <h1 style="font-size: 1.5rem; font-weight: 700; color: var(--text-primary);">تقرير الحضور والغياب</h1>
        <div style="display: flex; gap: 0.5rem;">
            <button onclick="window.print()" class="btn btn-primary" style="display: flex; align-items: center; gap: 0.5rem;">
                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <polyline points="6 9 6 2 18 2 18 9"></polyline>
                    <path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"></path>
                    <rect x="6" y="14" width="12" height="8"></rect>
                </svg>
                طباعة التقرير
            </button>
            <a href="{{ route('delegate.attendance.index') }}" class="btn btn-secondary">عودة</a>
        </div>
    </div>

    <div class="card bg-white" style="padding: 0;">

        <!-- Printable Area -->
        <div class="report-container">

            <!-- Header -->
            <div class="report-header">
                <div class="header-right">
                    <h3>{{ $reportUniversity->name ?? 'اسم الجامعة' }}</h3>
                    <h3>كلية {{ $reportCollege->name ?? 'اسم الكلية' }}</h3>
                    <h3>قسم {{ $reportMajor->name ?? 'اسم القسم' }}</h3>
                </div>

                <div class="header-center">
                    <div class="university-logo-placeholder" style="border: none; background: transparent;">
                        @if($reportUniversity?->logo)
                        <img src="{{ asset('storage/' . $reportUniversity->logo) }}" alt="Logo" style="width: 100%; height: 100%; object-fit: contain;">
                        @else
                        <!-- Fallback Icon if no logo -->
                        <div style="width: 60px; height: 60px; border: 2px solid #000; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 1.2rem;">
                            U
                        </div>
                        @endif
                    </div>
                </div>

                <div class="header-left">
                    <h3>تاريخ التقرير: {{ now()->format('Y/m/d') }}</h3>
                    <h3>تاريخ المحاضرة: {{ $date }}</h3>
                </div>
            </div>

            <div class="report-title">
                كشف حضور محاضرة ({{ $date }})
            </div>

            <!-- Meta Info -->
            <div class="meta-grid">
                <div class="meta-item">
                    <span class="meta-label">المقرر الدراسي:</span>
                    <span>{{ $reportSubjectLine }}</span>
                </div>
                <div class="meta-item">
                    <span class="meta-label">نوع المحاضرة:</span>
                    <span>{{ $reportLectureType }}</span>
                </div>
                <div class="meta-item">
                    <span class="meta-label">المستوى:</span>
                    <span>{{ $reportLevel }}</span>
                </div>
                <div class="meta-item">
                    <span class="meta-label">دكتور المادة:</span>
                    <span>{{ $reportDoctorName }}</span>
                </div>
                <div class="meta-item">
                    <span class="meta-label">طريقة التحضير:</span>
                    <span>{{ ($attendanceRecords->first()?->attendance_method ?? 'manual') === 'qr' ? 'باركود QR' : 'يدوي' }}</span>
                </div>
                <div class="meta-item">
                    <span class="meta-label">تم الرصد بواسطة:</span>
                    <span>{{ $attendanceRecords->first()?->recorder?->name ?? 'غير محدد' }}</span>
                </div>
                <div class="meta-item">
                    <span class="meta-label">فلتر العرض:</span>
                    <span>{{ ($genderFilter ?? 'all') === 'male' ? 'الأولاد فقط' : (($genderFilter ?? 'all') === 'female' ? 'البنات فقط' : 'الكل') }}</span>
                </div>
            </div>

            <!-- Students Table -->
            <div class="table-responsive">
<table class="table">
                <thead>
                    <tr>
                        <th style="width: 50px;">#</th>
                        <th style="text-align: right;">اسم الطالب</th>
                        <th style="width: 100px;">الجنس</th>
                        <th style="width: 150px;">حالة الحضور</th>
                        <th style="width: 130px;">طريقة التحضير</th>
                        <th style="width: 160px;">تم بواسطة</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach($students as $index => $student)
                    @php
                    $record = $attendanceRecords->get($student->id);
                    $status = $record ? $record->status : 'absent'; // Default to absent if no record found (or handle as unitialized)
                    // However, logic usually implies if record exists. If not, maybe show "Not Recorded"?
                    // For this specific report request "Attendance in that day exactly", we assume records exist or we show them as is.
                    // Let's refine: allow 'Not Recorded' if truly missing, but 'Absent' is safer default for printed reports of *taken* attendance.
                    @endphp
                    <tr>
                        <td>{{ $index + 1 }}</td>
                        <td style="text-align: right; font-weight: bold;">{{ $student->name }}</td>
                        <td>
                            <span style="display: inline-flex; align-items: center; gap: 0.35rem; padding: 0.3rem 0.7rem; border-radius: 999px; background: {{ $student->gender === 'female' ? '#fdf2f8' : '#eff6ff' }}; color: {{ $student->gender === 'female' ? '#db2777' : '#2563eb' }}; font-size: 0.78rem; font-weight: 700;">
                                {{ $student->gender === 'female' ? 'أنثى' : 'ذكر' }}
                            </span>
                        </td>
                        <td style="font-weight: bold;">
                            @if($record)
                            @if($record->status == 'present')
                            <span style="color: green;">حاضر</span>
                            @elseif($record->status == 'absent')
                            <span style="color: red;">غائب</span>
                            @elseif($record->status == 'late')
                            <span style="color: orange;">تأخر</span>
                            @elseif($record->status == 'excused')
                            <span style="color: blue;">بعذر</span>
                            @endif
                            @else
                            <span style="color: grey;">غير مرصود</span>
                            @endif
                        </td>
                        <td>{{ $record?->attendance_method === 'qr' ? 'QR' : ($record ? 'يدوي' : '-') }}</td>
                        <td>{{ $record?->recorder?->name ?? '-' }}</td>
                    </tr>
                    @endforeach
                </tbody>
            </table>
</div>

            <!-- Summary -->
            <div style="margin-top: 1rem; border: 1px solid #000; padding: 1rem; display: flex; justify-content: space-around; background: #f8f9fa;">
                <div><strong>إجمالي الطلاب:</strong> {{ $students->count() }}</div>
                <div><strong>حاضر:</strong> {{ $attendanceRecords->where('status', 'present')->count() }}</div>
                <div><strong>غائب:</strong> {{ $attendanceRecords->where('status', 'absent')->count() }}</div>
                <div><strong>تأخر/عذر:</strong> {{ $attendanceRecords->whereIn('status', ['late', 'excused'])->count() }}</div>
            </div>

            <!-- Footer -->
            <div class="report-footer">
                <div class="footer-sign">
                    <p>مندوب الدفعة</p>
                    <span>{{ $delegate?->name ?? Auth::user()?->name ?? '-' }}</span>
                </div>
                <div class="footer-sign">
                    <p>أستاذ المقرر</p>
                    <span>.................................</span>
                </div>
            </div>

        </div>
    </div>
</div>

@endsection
