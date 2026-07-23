@extends('layouts.admin')

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
            -webkit-print-color-adjust: exact;
            print-color-adjust: exact;
        }

        .no-print,
        .sidebar,
        .top-header,
        .mobile-toggle,
        .desktop-toggle,
        .btn,
        footer,
        .user-menu {
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

        /* Hide Admin Breadcrumbs or other elements if any */

        .report-page-container {
            width: 100%;
            height: 28.7cm;
            /* A4 Height */
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
            padding: 6px !important;
            text-align: center;
        }

        th {
            background-color: #f0f0f0 !important;
            font-weight: bold;
        }

        /* Formal Header */
        .header-section {
            display: flex;
            justify-content: space-between;
            align-items: center;
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

        /* Status Badges for Print */
        .badge {
            border: 1px solid #000;
            background: transparent !important;
            color: black !important;
            padding: 2px 5px;
            font-weight: normal;
        }
    }

    /* Screen Styles */
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
        <h1 class="h4 fw-bold mb-0">معاينة التقرير (مسؤوون)</h1>
        <div class="d-flex gap-2">
            <button onclick="window.print()" class="btn btn-primary d-flex align-items-center gap-2">
                <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <polyline points="6 9 6 2 18 2 18 9"></polyline>
                    <path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"></path>
                    <rect x="6" y="14" width="12" height="8"></rect>
                </svg>
                يعتمد ويطبع
            </button>
            <a href="{{ route('admin.reports.index') }}" class="btn btn-outline-secondary">رجوع</a>
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
                <!-- Use subject doctor name since Admin is viewing -->
                <td>{{ $subject->doctor->name ?? 'غير محدد' }}</td>
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
                    <!-- Loop over reportData instead of students -->
                    @forelse($reportData as $data)
                    @php
                    $student = $data['student'];
                    $isDeprived = $data['absent'] >= $subject->max_absences;
                    $isWarning = !$isDeprived && ($data['absent'] >= ($subject->max_absences - 2));
                    @endphp
                    <tr>
                        <td>{{ $loop->iteration }}</td>
                        <td style="text-align: right; font-weight: bold;">{{ $student->name }}</td>
                        <td style="font-family: monospace;">{{ $student->student_number }}</td>
                        <td>{{ $data['present'] }}</td>
                        <td>{{ $data['late'] }}</td>
                        <td>{{ $data['absent'] }}</td>
                        <td>{{ $data['excused'] }}</td>
                        <td>
                            @if($isDeprived)
                            <span style="color: red; font-weight: bold; border: 1px solid red; padding: 2px 5px;">محروم</span>
                            @elseif($isWarning)
                            <span style="color: orange; font-weight: bold; border: 1px solid orange; padding: 2px 5px;">إنذار</span>
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
                <p>{{ $subject->doctor->name ?? 'غير محدد' }}</p>
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