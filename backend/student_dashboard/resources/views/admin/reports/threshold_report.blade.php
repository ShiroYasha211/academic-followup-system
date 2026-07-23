@extends('layouts.admin')

@section('title', 'تقرير الحرمان والإنذارات')

@section('content')

<style>
    @media print {
        @page {
            size: A4;
            margin: 0.5cm;
        }

        body {
            background: white;
            font-family: 'Tajawal', sans-serif;
            -webkit-print-color-adjust: exact;
            print-color-adjust: exact;
        }

        /* Hide Admin UI Elements explicitly */
        .sidebar,
        .top-header,
        .btn,
        footer,
        .no-print,
        .mobile-toggle,
        .desktop-toggle,
        .user-menu,
        form {
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
            /* Approximate A4 height minus margins */
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
            color: #dc2626;
        }

        .meta-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 1rem;
            margin-bottom: 1.5rem;
            border: 1px solid #000;
            padding: 0.5rem;
            background: #fef2f2;
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
            padding: 8px !important;
            text-align: center;
        }

        th {
            background-color: #fee2e2 !important;
            color: #991b1b !important;
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

<div class="container" style="max-width: 100%; padding: 2rem;">

    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 2rem;" class="no-print">
        <div>
            <h1 class="page-title" style="font-size: 1.5rem; margin: 0; color: #dc2626; display: flex; align-items: center; gap: 0.5rem;">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path>
                    <line x1="12" y1="9" x2="12" y2="13"></line>
                    <line x1="12" y1="17" x2="12.01" y2="17"></line>
                </svg>
                تقرير الحالات الحرجة
            </h1>
            <p style="color: var(--text-secondary); margin-top: 0.5rem; margin-left: 2rem;">الطلاب الذين تجاوزوا نسبة غياب <strong>{{ $threshold }}%</strong></p>
        </div>
        <div style="display: flex; gap: 0.5rem;">
            <button onclick="window.print()" class="btn btn-primary" style="display: flex; align-items: center; gap: 0.5rem;">
                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <polyline points="6 9 6 2 18 2 18 9"></polyline>
                    <path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"></path>
                    <rect x="6" y="14" width="12" height="8"></rect>
                </svg>
                طباعة القائمة
            </button>
            <a href="{{ route('admin.reports.index') }}" class="btn btn-secondary">عودة للمركز</a>
        </div>
    </div>

    <div class="card" style="padding: 2rem;">

        <!-- Official Report Container for Print -->
        <div class="report-container">

            <!-- Header -->
            <div class="report-header">
                <div class="header-right">
                    <h3>{{ $level->major->college->university->name ?? 'اسم الجامعة' }}</h3>
                    <h3>كلية {{ $level->major->college->name ?? 'اسم الكلية' }}</h3>
                    <h3>قسم {{ $level->major->name ?? 'اسم القسم' }}</h3>
                </div>

                <div class="header-center">
                    <div class="university-logo-placeholder" style="border: none; background: transparent;">
                        @if($level->major->college->university->logo)
                        <img src="{{ asset('storage/' . $level->major->college->university->logo) }}" alt="University Logo" style="width: 100%; height: 100%; object-fit: contain;">
                        @else
                        <svg xmlns="http://www.w3.org/2000/svg" width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#ccc" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
                            <path d="M22 10v6M2 10v6M12 15a4 4 0 1 0 0-8 4 4 0 0 0 0 8z"></path>
                            <path d="M6 15v-2a6 6 0 1 1 12 0v2"></path>
                            <path d="M2 10s2 6 10 6 10-6 10-6"></path>
                        </svg>
                        @endif
                    </div>
                </div>

                <div class="header-left">
                    <h3>التاريخ: {{ now()->format('Y/m/d') }}</h3>
                    <h3>السنة الدراسية: {{ date('Y') }}</h3>
                </div>
            </div>

            <div class="report-title">
                قائمة المحرومين والمنذرين
            </div>

            <!-- Meta Data Grid -->
            <div class="meta-grid">
                <div class="meta-item">
                    <span class="meta-label">المرحلة الدراسية:</span>
                    <span>{{ $level->name }} - {{ $level->major->name }}</span>
                </div>
                <div class="meta-item">
                    <span class="meta-label">حد الغياب (Threshold):</span>
                    <span>الطلاب المتجاوزين لـ <strong>{{ $threshold }}%</strong></span>
                </div>
            </div>

            @if(empty($alertData))
            <div style="text-align: center; padding: 3rem; background: #f0fdf4; border: 1px dashed #166534; border-radius: 8px; color: #166534; margin-top: 2rem;">
                <h3 style="margin:0;">ممتاز! لا توجد حالات تجاوزت حد الغياب المحدد.</h3>
            </div>
            @else
            <!-- Detailed Table -->
            <div class="table-responsive">
<table class="table">
                <thead>
                    <tr>
                        <th style="width: 15%;">الرقم الجامعي</th>
                        <th style="text-align: right;">اسم الطالب</th>
                        <th style="text-align: right;">المادة</th>
                        <th style="width: 12%;">عدد الغياب</th>
                        <th style="width: 12%;">النسبة %</th>
                        <th style="width: 15%;">الحالة</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach($alertData as $alert)
                    <tr>
                        <td style="font-family: monospace;">{{ $alert['student']->student_number }}</td>
                        <td style="text-align: right; font-weight: bold;">{{ $alert['student']->name }}</td>
                        <td style="text-align: right;">{{ $alert['subject']->name }}</td>
                        <td>{{ $alert['absent_count'] }} / {{ $alert['total_sessions'] }}</td>
                        <td style="color: #dc2626; font-weight: bold;">
                            {{ $alert['absence_percentage'] }}%
                        </td>
                        <td>
                            @if($alert['absence_percentage'] >= 25)
                            <span style="color: #dc2626; font-weight: bold;">حرمان 🚫</span>
                            @else
                            <span style="color: #f59e0b; font-weight: bold;">إنذار ⚠️</span>
                            @endif
                        </td>
                    </tr>
                    @endforeach
                </tbody>
            </table>
</div>
            @endif

            <!-- Footer Signatures -->
            <div class="report-footer">
                <div class="footer-sign">
                    <p>المرشد الأكاديمي</p>
                    <span>.................................</span>
                </div>
                <div class="footer-sign">
                    <p>رئيس القسم</p>
                    <span>.................................</span>
                </div>
                <div class="footer-sign">
                    <p>يعتمد، عميد الكلية</p>
                    <span>.................................</span>
                </div>
            </div>

        </div> <!-- End Report Container -->

    </div>

</div>

@endsection