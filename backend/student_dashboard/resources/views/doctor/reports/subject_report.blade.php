@extends('layouts.doctor')

@section('title', 'تقرير حضور: ' . $subject->name)

@section('content')

<style>
    @media print {
        @page {
            size: A4;
            margin: 0;
        }

        body {
            background: white;
            font-family: 'Times New Roman', serif;
            /* More formal font for English, Cairo is good for Arabic */
            -webkit-print-color-adjust: exact;
            print-color-adjust: exact;
        }

        .no-print,
        .sidebar,
        .top-header,
        .mobile-toggle,
        .desktop-toggle,
        .btn,
        footer {
            display: none !important;
        }

        .main-content {
            margin: 0 !important;
            padding: 0 !important;
            width: 100% !important;
            height: auto !important;
        }

        .admin-wrapper {
            display: block !important;
            height: auto !important;
        }

        .report-page-container {
            width: 100%;
            /* Fill full width */
            height: 28.5cm;
            /* Fill full height */
            padding: 1cm;
            margin: 0;
            border: none;
            background: white;
            position: relative;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
        }

        .card {
            border: none !important;
            box-shadow: none !important;
            padding: 0 !important;
            margin: 0 !important;
        }

        table {
            border-collapse: collapse !important;
            width: 100% !important;
            font-size: 11pt;
            margin-bottom: 1cm;
        }

        th,
        td {
            border: 1px solid #000 !important;
            padding: 8px !important;
            text-align: center;
        }

        th {
            background-color: #f0f0f0 !important;
            font-weight: bold;
        }

        .badge {
            border: 1px solid #000;
            background: transparent !important;
            color: black !important;
            padding: 2px 5px;
            font-weight: normal;
        }

        .badge-danger {
            border-color: red !important;
            color: red !important;
        }

        .badge-warning {
            border-color: orange !important;
            color: orange !important;
        }

        /* Report Header */
        .header-section {
            display: flex;
            justify-content: space-between;
            align-items: center;
            /* Use start if multi-line differences are huge */
            border-bottom: 2px solid #000;
            padding-bottom: 10px;
            margin-bottom: 20px;
            text-align: center;
        }

        .header-right,
        .header-left {
            width: 30%;
            font-size: 12pt;
            line-height: 1.4;
            font-weight: bold;
        }

        .header-center {
            width: 30%;
            display: flex;
            justify-content: center;
        }

        .report-title {
            text-align: center;
            font-size: 16pt;
            font-weight: bold;
            margin: 20px 0;
            text-decoration: underline;
        }

        /* Signatures */
        .signatures-section {
            display: flex;
            justify-content: space-between;
            /* Arrange horizontally */
            margin-top: 50px;
            page-break-inside: avoid;
            padding-top: 20px;
        }

        .signature-box {
            text-align: center;
            width: 30%;
        }

        .signature-line {
            margin-top: 50px;
            border-top: 1px dotted #000;
            width: 80%;
            margin-left: auto;
            margin-right: auto;
        }
    }

    /* Screen Enhancements */
    @media screen {
        .report-page-container {
            background: white;
            padding: 2rem;
            border: 1px solid #ddd;
            box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1);
            max-width: 21cm;
            margin: 0 auto;
            min-height: 29.7cm;
            display: flex;
            flex-direction: column;
        }

        .header-section {
            display: flex;
            justify-content: space-between;
            border-bottom: 2px solid #eee;
            padding-bottom: 1rem;
            margin-bottom: 1rem;
            text-align: center;
        }
    }
</style>

<div class="container-fluid py-4" style="background: #f3f4f6; min-height: 100vh;">

    <!-- Toolbar -->
    <div class="d-flex justify-content-between align-items-center mb-4 container no-print" style="max-width: 21cm;">
        <h1 class="h4 fw-bold mb-0">معاينة التقرير</h1>
        <div class="d-flex flex-wrap gap-2">

            <button onclick="window.print()" class="btn btn-primary d-flex align-items-center gap-2">
                <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <polyline points="6 9 6 2 18 2 18 9"></polyline>
                    <path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"></path>
                    <rect x="6" y="14" width="12" height="8"></rect>
                </svg>
                طباعة
            </button>
            <a href="{{ route('doctor.dashboard') }}" class="btn btn-outline-secondary">رجوع</a>
        </div>
    </div>

    <!-- A4 Container -->
    <div class="report-page-container">

        <!-- Header -->
        <div class="header-section">
            <div class="header-right">
                <div>الجمهورية اليمنية</div>
                <div>وزارة التعليم العالي والبحث العلمي</div>
                <div>{{ $subject->major->college->university->name ?? 'اسم الجامعة' }}</div>
                <div>كلية {{ $subject->major->college->name ?? '-' }}</div>
            </div>

            <div class="header-center">
                @if($subject->major->college->university->logo)
                <img src="{{ asset('storage/' . $subject->major->college->university->logo) }}" style="width: 100px; height: 100px; object-fit: contain;" alt="Logo">
                @else
                <svg xmlns="http://www.w3.org/2000/svg" width="80" height="80" viewBox="0 0 24 24" fill="none" stroke="#ccc" stroke-width="1" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5"></path>
                </svg>
                @endif
            </div>

            <div class="header-left">
                <div>التاريخ: {{ date('Y/m/d') }}</div>
                <div>الفصل: {{ $subject->term->name ?? '-' }}</div>
            </div>
        </div>

        <!-- Title -->
        <h2 class="report-title">تقرير الحضور والغياب والحرمان</h2>

        <!-- Subject Meta -->
        <div class="table-responsive">
<table class="table" style="margin-bottom: 20px;">
            <tr>
                <th width="15%">المقرر</th>
                <td width="35%">{{ $subject->name }} ({{ $subject->code }})</td>
                <th width="15%">القسم</th>
                <td width="35%">{{ $subject->major->name ?? '-' }}</td>
            </tr>
            <tr>
                <th>أستاذ المقرر</th>
                <td>{{ Auth::user()->name }}</td>
                <th>الحد الأعلى</th>
                <td>{{ $subject->max_absences }} محاضرات</td>
            </tr>
        </table>
</div>

        <!-- Students Table -->
        <div style="flex-grow: 1;">
            <div class="table-responsive">
<table class="table">
                <thead>
                    <tr>
                        <th width="5%">#</th>
                        <th>اسم الطالب</th>
                        <th width="15%">الرقم الجامعي</th>
                        <th width="8%">حضور</th>
                        <th width="8%">تأخير</th>
                        <th width="8%">غياب</th>
                        <th width="8%">عذر</th>
                        <th width="15%">الحالة</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($students as $student)
                    @php
                    $present = $student->attendances->where('status', 'present')->count();
                    $late = $student->attendances->where('status', 'late')->count();
                    $absent = $student->attendances->where('status', 'absent')->count();
                    $excused = $student->attendances->where('status', 'excused')->count();

                    $isDeprived = $absent >= $subject->max_absences;
                    $isWarning = !$isDeprived && ($absent >= ($subject->max_absences - 2));
                    @endphp
                    <tr>
                        <td>{{ $loop->iteration }}</td>
                        <td style="text-align: right; font-weight: bold;">{{ $student->name }}</td>
                        <td class="font-monospace">{{ $student->student_number }}</td>
                        <td>{{ $present }}</td>
                        <td>{{ $late }}</td>
                        <td>{{ $absent }}</td>
                        <td>{{ $excused }}</td>
                        <td>
                            @if($isDeprived)
                            <span class="badge badge-danger">محروم</span>
                            @elseif($isWarning)
                            <span class="badge badge-warning">إنذار</span>
                            @else
                            <span>-</span>
                            @endif
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="8">لا يوجد طلاب مسجلين.</td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
</div>
        </div>

        <!-- Signatures (Pinned to Bottom) -->
        <div class="signatures-section">
            <div class="signature-box">
                <p>أستاذ المقرر</p>
                <p>{{ Auth::user()->name }}</p>
                <div class="signature-line"></div>
            </div>
            <div class="signature-box">
                <p>رئيس القسم</p>
                <p>&nbsp;</p>
                <div class="signature-line"></div>
            </div>
            <div class="signature-box">
                <p>عميد الكلية</p>
                <p>&nbsp;</p>
                <div class="signature-line"></div>
            </div>
        </div>

    </div>
</div>

@endsection