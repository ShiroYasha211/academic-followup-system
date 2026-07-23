<!doctype html>
<html lang="ar">
<head>
    <meta charset="utf-8">
    <style>
        @page {
            margin: 40px 30px;
        }
        body {
            font-family: DejaVu Sans, sans-serif;
            direction: ltr;
            color: #1e293b;
            font-size: 11px;
            line-height: 1.6;
            background-color: #ffffff;
            text-align: right;
        }
        
        /* Top Header Styling */
        .header-table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 5px;
        }
        .header-table td {
            border: none;
            padding: 0;
            vertical-align: middle;
        }
        .header-right {
            width: 38%;
            text-align: right;
        }
        .header-center {
            width: 24%;
            text-align: center;
        }
        .header-left {
            width: 38%;
            text-align: left;
        }
        .header-logo-text {
            font-size: 13px;
            font-weight: bold;
            color: #0f172a;
        }
        .header-sub-text {
            font-size: 11px;
            color: #64748b;
            margin-top: 1px;
        }

        /* Report Header Title */
        h1 {
            text-align: center;
            font-size: 17px;
            font-weight: bold;
            color: #0f172a;
            margin: 0 0 15px 0;
        }

        /* Card Container & Styling */
        .card {
            border: 1px solid #e2e8f0;
            border-radius: 6px;
            padding: 12px 14px;
            margin-bottom: 12px;
            background-color: #f8fafc;
        }
        .card-title {
            font-weight: bold;
            font-size: 10px;
            color: #475569;
            margin-bottom: 6px;
            border-bottom: 1px solid #e2e8f0;
            padding-bottom: 4px;
            text-align: right;
        }
        .card-content {
            font-size: 10.5px;
            color: #334155;
            text-align: right;
        }
        
        /* Card Types styling */
        .card-blue {
            border-right: 4px solid #2563eb;
            background-color: #f0f9ff;
        }
        .card-emerald {
            border-right: 4px solid #059669;
            background-color: #f0fdf4;
        }
        .card-rose {
            border-right: 4px solid #e11d48;
            background-color: #fff1f2;
        }
        .card-teal {
            border-right: 4px solid #0d9488;
            background-color: #f0fdfa;
        }
        .card-violet {
            border-right: 4px solid #7c3aed;
            background-color: #faf5ff;
        }
        .card-amber {
            border-right: 4px solid #d97706;
            background-color: #fffbeb;
        }

        /* Premium Table Styles */
        .report-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 15px;
            border: 1px solid #cbd5e1;
        }
        .report-table th {
            background-color: #0f172a;
            color: #ffffff;
            font-weight: bold;
            font-size: 10px;
            padding: 8px 6px;
            text-align: center;
            border: 1px solid #334155;
        }
        .report-table td {
            padding: 7px 5px;
            font-size: 9.5px;
            color: #334155;
            text-align: center;
            border: 1px solid #cbd5e1;
        }
        .report-table tr:nth-child(even) {
            background-color: #f8fafc;
        }
        
        /* Alignments */
        .text-right {
            text-align: right !important;
        }
        .text-left {
            text-align: left !important;
        }
        .font-bold {
            font-weight: bold;
        }

        /* Status Badges */
        .badge {
            display: inline-block;
            padding: 1px 6px;
            border-radius: 4px;
            font-size: 8.5px;
            font-weight: bold;
            text-align: center;
        }
        .badge-success {
            background-color: #dcfce7;
            color: #166534;
        }
        .badge-warning {
            background-color: #fef3c7;
            color: #92400e;
        }
        .badge-danger {
            background-color: #fee2e2;
            color: #991b1b;
        }
        .badge-info {
            background-color: #dbeafe;
            color: #1e40af;
        }

        /* Signature block */
        .signatures {
            margin-top: 40px;
            width: 100%;
            border-collapse: collapse;
        }
        .signatures td {
            border: none;
        }
        .signature-cell {
            width: 33.33%;
            text-align: center;
            padding: 0 15px;
            vertical-align: top;
        }
        .signature-title {
            font-weight: bold;
            color: #475569;
            font-size: 10.5px;
            margin-bottom: 40px;
        }
        .signature-line {
            border-top: 1px solid #94a3b8;
            width: 80%;
            margin: 0 auto;
        }
    </style>
</head>
<body>
    @php
        // تعريف دالة معالجة وتشكيل النصوص العربية للـ PDF
        $ar = fn($text) => \App\Helpers\ArabicHelper::fixArabic((string) $text, true);
        
        $period = $data['date_range']['label'] ?? 'كل الفترات';
    @endphp

    <table class="header-table">
        <tr>
            <!-- Visually Left: Export Date -->
            <td class="header-left">
                <div style="font-size: 9px; color: #64748b;">{{ $ar('تاريخ الإصدار') }}</div>
                <div style="font-size: 11px; font-weight: bold; color: #0f172a; margin-top: 2px;">{{ $generatedAt }}</div>
            </td>
            <!-- Visually Center: Report Title -->
            <td class="header-center">
                <div style="font-size: 12px; font-weight: bold; color: #1e293b; background: #f1f5f9; padding: 6px 12px; border-radius: 6px; display: inline-block;">
                    {{ $ar($title) }}
                </div>
            </td>
            <!-- Visually Right: University & College -->
            <td class="header-right">
                <div class="header-logo-text">{{ $ar('جامعة ' . ($college->university->name ?? '-')) }}</div>
                <div class="header-sub-text">{{ $ar('كلية ' . ($college->name ?? '-')) }}</div>
            </td>
        </tr>
    </table>
    <div style="height: 1px; background-color: #e2e8f0; margin-top: 10px; margin-bottom: 20px;"></div>

    @if($type === 'subject')
        @php
            $subject = $data['subject'] ?? [];
            $summary = $data['summary'] ?? [];
            $report = $data['report'] ?? [];
            $maxAbsences = (int)($subject['max_absences'] ?? 4);
        @endphp
        <h1>{{ $ar('كشف حضور وغياب الطلاب') }}</h1>
        
        <table style="width: 100%; border: none; margin-bottom: 15px; border-collapse: collapse;">
            <tr>
                <!-- Visually Left Card -->
                <td style="width: 48%; border: none; padding: 0; vertical-align: top;">
                    <div class="card card-blue">
                        <div class="card-title">{{ $ar('الشعبة والتخصص') }}</div>
                        <div class="card-content" style="line-height: 1.8;">
                            <strong>{{ $ar('التخصص:') }}</strong> {{ $ar($subject['major']['name'] ?? '-') }}<br>
                            <strong>{{ $ar('المستوى:') }}</strong> {{ $ar($subject['level']['name'] ?? '-') }}<br>
                            <strong>{{ $ar('حد الغياب المسموح:') }}</strong> <span class="badge badge-danger" style="font-size: 10px; padding: 1px 6px;">{{ $maxAbsences }} {{ $ar('محاضرات') }}</span>
                        </div>
                    </div>
                </td>
                <td style="width: 4%; border: none; padding: 0;"></td>
                <!-- Visually Right Card -->
                <td style="width: 48%; border: none; padding: 0; vertical-align: top;">
                    <div class="card card-blue">
                        <div class="card-title">{{ $ar('معلومات المساق والتعليم') }}</div>
                        <div class="card-content" style="line-height: 1.8;">
                            <strong>{{ $ar('المادة:') }}</strong> {{ $ar($subject['name'] ?? '-') }}<br>
                            <strong>{{ $ar('الدكتور:') }}</strong> {{ $ar($subject['doctor']['name'] ?? 'غير محدد') }}<br>
                            <strong>{{ $ar('الفترة الدراسية:') }}</strong> {{ $ar($period) }}
                        </div>
                    </div>
                </td>
            </tr>
        </table>

        <div class="card card-emerald" style="margin-bottom: 20px;">
            <div class="card-title">{{ $ar('الملخص التنفيذي للشعبة') }}</div>
            <div class="card-content">
                <table style="width: 100%; border: none; border-collapse: collapse; text-align: center;">
                    <tr>
                        <td style="border: none; padding: 4px; width: 25%;">
                            <span style="font-size: 10px; color: #475569; display: block; margin-bottom: 2px;">{{ $ar('متوسط غياب الشعبة') }}</span>
                            <strong style="font-size: 14px; color: #2563eb;">{{ $summary['average_absence_percentage'] ?? 0 }}%</strong>
                        </td>
                        <td style="border: none; padding: 4px; width: 25%; border-right: 1px solid #e2e8f0;">
                            <span style="font-size: 10px; color: #475569; display: block; margin-bottom: 2px;">{{ $ar('حالات الحرمان') }}</span>
                            <strong style="font-size: 14px; color: #e11d48;">{{ $summary['deprived_count'] ?? 0 }}</strong>
                        </td>
                        <td style="border: none; padding: 4px; width: 25%; border-right: 1px solid #e2e8f0;">
                            <span style="font-size: 10px; color: #475569; display: block; margin-bottom: 2px;">{{ $ar('الإنذارات الصادرة') }}</span>
                            <strong style="font-size: 14px; color: #d97706;">{{ $summary['warning_count'] ?? 0 }}</strong>
                        </td>
                        <td style="border: none; padding: 4px; width: 25%; border-right: 1px solid #e2e8f0;">
                            <span style="font-size: 10px; color: #475569; display: block; margin-bottom: 2px;">{{ $ar('إجمالي الطلاب') }}</span>
                            <strong style="font-size: 14px; color: #0f172a;">{{ $summary['students_count'] ?? count($report) }}</strong>
                        </td>
                    </tr>
                </table>
            </div>
        </div>

        <table class="report-table">
            <thead>
                <tr>
                    <th style="width: 10%;">{{ $ar('الموقف') }}</th>
                    <th style="width: 10%;">{{ $ar('النسبة') }}</th>
                    <th style="width: 8%;">{{ $ar('أعذار') }}</th>
                    <th style="width: 8%;">{{ $ar('متأخر') }}</th>
                    <th style="width: 8%;">{{ $ar('غائب') }}</th>
                    <th style="width: 8%;">{{ $ar('حاضر') }}</th>
                    <th class="text-right" style="width: 29%;">{{ $ar('اسم الطالب') }}</th>
                    <th style="width: 14%;">{{ $ar('الرقم الجامعي') }}</th>
                    <th style="width: 5%;">{{ $ar('#') }}</th>
                </tr>
            </thead>
            <tbody>
                @foreach($report as $row)
                    @php
                        $decision = $row['decision'] ?? '-';
                    @endphp
                    <tr>
                        <td>
                            @if($decision === 'محروم')
                                <span class="badge badge-danger">{{ $ar('محروم') }}</span>
                            @elseif($decision === 'إنذار')
                                <span class="badge badge-warning">{{ $ar('إنذار') }}</span>
                            @elseif($decision === '-')
                                <span class="badge badge-success">{{ $ar('سليم') }}</span>
                            @else
                                <span class="badge badge-info">{{ $ar($decision) }}</span>
                            @endif
                        </td>
                        <td class="font-bold">{{ $row['absence_percentage'] ?? 0 }}%</td>
                        <td>{{ $row['excused'] ?? 0 }}</td>
                        <td>{{ $row['late'] ?? 0 }}</td>
                        <td>{{ $row['absent'] ?? 0 }}</td>
                        <td>{{ $row['present'] ?? 0 }}</td>
                        <td class="text-right font-bold" style="color: #0f172a;">{{ $ar($row['student']['name'] ?? '-') }}</td>
                        <td class="font-bold">{{ $row['student']['student_number'] ?? '-' }}</td>
                        <td>{{ $loop->iteration }}</td>
                    </tr>
                @endforeach
            </tbody>
        </table>
    @elseif($type === 'threshold')
        @php
            $level = $data['level'] ?? [];
            $summary = $data['summary'] ?? [];
            $alerts = $data['alerts'] ?? [];
        @endphp
        <h1>{{ $ar('كشف الطلاب المتجاوزين لنسبة الغياب') }}</h1>
        
        <table style="width: 100%; border: none; margin-bottom: 15px; border-collapse: collapse;">
            <tr>
                <!-- Visually Left Card -->
                <td style="width: 48%; border: none; padding: 0; vertical-align: top;">
                    <div class="card card-rose">
                        <div class="card-title">{{ $ar('معلومات التقرير') }}</div>
                        <div class="card-content" style="line-height: 1.8;">
                            <strong>{{ $ar('التخصص:') }}</strong> {{ $ar($level['major']['name'] ?? '-') }}<br>
                            <strong>{{ $ar('المستوى:') }}</strong> {{ $ar($level['name'] ?? '-') }}
                        </div>
                    </div>
                </td>
                <td style="width: 4%; border: none; padding: 0;"></td>
                <!-- Visually Right Card -->
                <td style="width: 48%; border: none; padding: 0; vertical-align: top;">
                    <div class="card card-rose">
                        <div class="card-title">{{ $ar('الضوابط والفترة') }}</div>
                        <div class="card-content" style="line-height: 1.8;">
                            <strong>{{ $ar('عتبة الغياب المرصودة:') }}</strong> <span class="badge badge-danger" style="font-size: 10px; padding: 1px 6px;">&ge; {{ $data['threshold'] ?? 0 }}%</span><br>
                            <strong>{{ $ar('الفترة الدراسية:') }}</strong> {{ $ar($period) }}
                        </div>
                    </div>
                </td>
            </tr>
        </table>

        <div class="card card-amber" style="margin-bottom: 20px;">
            <div class="card-title">{{ $ar('الملخص التنفيذي للإنذارات') }}</div>
            <div class="card-content">
                <table style="width: 100%; border: none; border-collapse: collapse; text-align: center;">
                    <tr>
                        <td style="border: none; padding: 4px; width: 25%;">
                            <span style="font-size: 10px; color: #475569; display: block; margin-bottom: 2px;">{{ $ar('أعلى نسبة غياب مسجلة') }}</span>
                            <strong style="font-size: 14px; color: #b91c1c;">{{ $summary['highest_percentage'] ?? 0 }}%</strong>
                        </td>
                        <td style="border: none; padding: 4px; width: 25%; border-right: 1px solid #e2e8f0;">
                            <span style="font-size: 10px; color: #475569; display: block; margin-bottom: 2px;">{{ $ar('حالات الحرمان الكلي') }}</span>
                            <strong style="font-size: 14px; color: #e11d48;">{{ $summary['critical_count'] ?? 0 }}</strong>
                        </td>
                        <td style="border: none; padding: 4px; width: 25%; border-right: 1px solid #e2e8f0;">
                            <span style="font-size: 10px; color: #475569; display: block; margin-bottom: 2px;">{{ $ar('حالات الإنذار') }}</span>
                            <strong style="font-size: 14px; color: #d97706;">{{ $summary['warning_count'] ?? 0 }}</strong>
                        </td>
                        <td style="border: none; padding: 4px; width: 25%; border-right: 1px solid #e2e8f0;">
                            <span style="font-size: 10px; color: #475569; display: block; margin-bottom: 2px;">{{ $ar('إجمالي الحالات') }}</span>
                            <strong style="font-size: 14px; color: #0f172a;">{{ $summary['alerts_count'] ?? count($alerts) }}</strong>
                        </td>
                    </tr>
                </table>
            </div>
        </div>

        <table class="report-table">
            <thead>
                <tr>
                    <th style="width: 12%;">{{ $ar('الإجراء') }}</th>
                    <th style="width: 11%;">{{ $ar('النسبة') }}</th>
                    <th style="width: 11%;">{{ $ar('الجلسات') }}</th>
                    <th style="width: 11%;">{{ $ar('الغيابات') }}</th>
                    <th class="text-right" style="width: 25%;">{{ $ar('المادة') }}</th>
                    <th class="text-right" style="width: 25%;">{{ $ar('اسم الطالب') }}</th>
                    <th style="width: 5%;">{{ $ar('#') }}</th>
                </tr>
            </thead>
            <tbody>
                @forelse($alerts as $row)
                    @php
                        $percentage = (float)($row['absence_percentage'] ?? 0);
                        $action = $row['action_label'] ?? ($percentage >= 25 ? 'حرمان' : 'إنذار');
                    @endphp
                    <tr>
                        <td>
                            @if($action === 'حرمان')
                                <span class="badge badge-danger">{{ $ar('حرمان') }}</span>
                            @else
                                <span class="badge badge-warning">{{ $ar('إنذار') }}</span>
                            @endif
                        </td>
                        <td class="font-bold" style="color: #b91c1c;">{{ $percentage }}%</td>
                        <td>{{ $row['total_sessions'] ?? 0 }}</td>
                        <td>{{ $row['absent_count'] ?? 0 }}</td>
                        <td class="text-right">{{ $ar($row['subject']['name'] ?? '-') }}</td>
                        <td class="text-right font-bold" style="color: #0f172a;">{{ $ar($row['student']['name'] ?? '-') }}</td>
                        <td>{{ $loop->iteration }}</td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="7" style="padding: 15px; color: #64748b;">{{ $ar('لا توجد حالات تجاوزت الحد المحدد.') }}</td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    @elseif($type === 'level_summary')
        @php
            $level = $data['level'] ?? [];
            $summary = $data['summary'] ?? [];
            $stats = $data['subject_stats'] ?? [];
        @endphp
        <h1>{{ $ar('ملخص الدفعة الدراسية') }}</h1>
        
        <table style="width: 100%; border: none; margin-bottom: 15px; border-collapse: collapse;">
            <tr>
                <!-- Visually Left Card -->
                <td style="width: 48%; border: none; padding: 0; vertical-align: top;">
                    <div class="card card-teal">
                        <div class="card-title">{{ $ar('معلومات الدفعة') }}</div>
                        <div class="card-content" style="line-height: 1.8;">
                            <strong>{{ $ar('التخصص:') }}</strong> {{ $ar($level['major']['name'] ?? '-') }}<br>
                            <strong>{{ $ar('المستوى:') }}</strong> {{ $ar($level['name'] ?? '-') }}
                        </div>
                    </div>
                </td>
                <td style="width: 4%; border: none; padding: 0;"></td>
                <!-- Visually Right Card -->
                <td style="width: 48%; border: none; padding: 0; vertical-align: top;">
                    <div class="card card-teal">
                        <div class="card-title">{{ $ar('المندوب والفترة') }}</div>
                        <div class="card-content" style="line-height: 1.8;">
                            <strong>{{ $ar('مندوب الدفعة:') }}</strong> {{ $ar($data['delegate']['name'] ?? 'غير معين') }}<br>
                            <strong>{{ $ar('الفترة الدراسية:') }}</strong> {{ $ar($period) }}
                        </div>
                    </div>
                </td>
            </tr>
        </table>

        <div class="card card-emerald" style="margin-bottom: 20px;">
            <div class="card-title">{{ $ar('البيانات الإجمالية للدفعة') }}</div>
            <div class="card-content">
                <table style="width: 100%; border: none; border-collapse: collapse; text-align: center;">
                    <tr>
                        <td style="border: none; padding: 4px; width: 33.33%;">
                            <span style="font-size: 10px; color: #475569; display: block; margin-bottom: 2px;">{{ $ar('متوسط حضور الدفعة العام') }}</span>
                            <strong style="font-size: 14px; color: #2563eb;">{{ $summary['average_attendance_rate'] ?? 0 }}%</strong>
                        </td>
                        <td style="border: none; padding: 4px; width: 33.33%; border-right: 1px solid #e2e8f0;">
                            <span style="font-size: 10px; color: #475569; display: block; margin-bottom: 2px;">{{ $ar('عدد المساقات النشطة') }}</span>
                            <strong style="font-size: 14px; color: #0d9488;">{{ $summary['subjects_count'] ?? count($stats) }}</strong>
                        </td>
                        <td style="border: none; padding: 4px; width: 33.33%; border-right: 1px solid #e2e8f0;">
                            <span style="font-size: 10px; color: #475569; display: block; margin-bottom: 2px;">{{ $ar('إجمالي الطلاب المقيدين') }}</span>
                            <strong style="font-size: 14px; color: #0f172a;">{{ $summary['students_count'] ?? count($data['students'] ?? []) }}</strong>
                        </td>
                    </tr>
                </table>
            </div>
        </div>

        <table class="report-table">
            <thead>
                <tr>
                    <th style="width: 15%;">{{ $ar('نسبة الحضور') }}</th>
                    <th style="width: 15%;">{{ $ar('سجلات الرصد') }}</th>
                    <th class="text-right" style="width: 30%;">{{ $ar('الدكتور') }}</th>
                    <th class="text-right" style="width: 35%;">{{ $ar('المادة') }}</th>
                    <th style="width: 5%;">{{ $ar('#') }}</th>
                </tr>
            </thead>
            <tbody>
                @foreach($stats as $row)
                    <tr>
                        <td class="font-bold" style="color: #2563eb;">{{ $row['attendance_rate'] ?? 0 }}%</td>
                        <td>{{ $row['total_records'] ?? 0 }}</td>
                        <td class="text-right">{{ $ar($row['subject']['doctor']['name'] ?? '-') }}</td>
                        <td class="text-right font-bold" style="color: #0f172a;">{{ $ar($row['subject']['name'] ?? '-') }}</td>
                        <td>{{ $loop->iteration }}</td>
                    </tr>
                @endforeach
            </tbody>
        </table>
    @else
        @php
            $summary = $data['summary'] ?? [];
            $doctors = $data['doctors'] ?? $data;
        @endphp
        <h1>{{ $ar('أداء الكادر التعليمي') }}</h1>
        
        <table style="width: 100%; border: none; margin-bottom: 15px; border-collapse: collapse;">
            <tr>
                <!-- Visually Left Card -->
                <td style="width: 48%; border: none; padding: 0; vertical-align: top;">
                    <div class="card card-violet">
                        <div class="card-title">{{ $ar('معلومات التقرير') }}</div>
                        <div class="card-content" style="line-height: 1.8;">
                            <strong>{{ $ar('نوع التقرير:') }}</strong> {{ $ar('تقرير أداء الكادر التعليمي العام') }}<br>
                            <strong>{{ $ar('الفترة الدراسية:') }}</strong> {{ $ar($period) }}
                        </div>
                    </div>
                </td>
                <td style="width: 4%; border: none; padding: 0;"></td>
                <!-- Visually Right Card -->
                <td style="width: 48%; border: none; padding: 0; vertical-align: top;">
                    <div class="card card-violet">
                        <div class="card-title">{{ $ar('الهيئة المصدرة للتقرير') }}</div>
                        <div class="card-content" style="line-height: 1.8;">
                            <strong>{{ $ar('المصدر:') }}</strong> {{ $ar('عمادة شؤون الطلاب والتعليم') }}<br>
                            <strong>{{ $ar('الكلية:') }}</strong> {{ $ar('كلية ' . ($college->name ?? '-')) }}
                        </div>
                    </div>
                </td>
            </tr>
        </table>

        <div class="card card-emerald" style="margin-bottom: 20px;">
            <div class="card-title">{{ $ar('ملخص أداء الكادر') }}</div>
            <div class="card-content">
                <table style="width: 100%; border: none; border-collapse: collapse; text-align: center;">
                    <tr>
                        <td style="border: none; padding: 4px; width: 33.33%;">
                            <span style="font-size: 10px; color: #475569; display: block; margin-bottom: 2px;">{{ $ar('متوسط حضور الطلاب العام') }}</span>
                            <strong style="font-size: 14px; color: #2563eb;">{{ $summary['average_attendance_rate'] ?? 0 }}%</strong>
                        </td>
                        <td style="border: none; padding: 4px; width: 33.33%; border-right: 1px solid #e2e8f0;">
                            <span style="font-size: 10px; color: #475569; display: block; margin-bottom: 2px;">{{ $ar('الأعضاء النشطين') }}</span>
                            <strong style="font-size: 14px; color: #7c3aed;">{{ $summary['active_doctors_count'] ?? 0 }}</strong>
                        </td>
                        <td style="border: none; padding: 4px; width: 33.33%; border-right: 1px solid #e2e8f0;">
                            <span style="font-size: 10px; color: #475569; display: block; margin-bottom: 2px;">{{ $ar('إجمالي الكادر المقيد') }}</span>
                            <strong style="font-size: 14px; color: #0f172a;">{{ $summary['doctors_count'] ?? count($doctors) }}</strong>
                        </td>
                    </tr>
                </table>
            </div>
        </div>

        <table class="report-table">
            <thead>
                <tr>
                    <th style="width: 15%;">{{ $ar('متوسط الحضور') }}</th>
                    <th style="width: 11%;">{{ $ar('المساقات') }}</th>
                    <th style="width: 14%;">{{ $ar('جلسات QR') }}</th>
                    <th class="text-right" style="width: 30%;">{{ $ar('البريد الإلكتروني') }}</th>
                    <th class="text-right" style="width: 25%;">{{ $ar('الدكتور') }}</th>
                    <th style="width: 5%;">{{ $ar('#') }}</th>
                </tr>
            </thead>
            <tbody>
                @foreach($doctors as $doctor)
                    <tr>
                        <td class="font-bold" style="color: #2563eb;">{{ $doctor['attendance_rate'] ?? 0 }}%</td>
                        <td>{{ $doctor['subjects_count'] ?? 0 }}</td>
                        <td>{{ $doctor['qr_sessions_count'] ?? 0 }}</td>
                        <td class="text-right" style="color: #475569; font-family: 'DejaVu Sans', sans-serif;">{{ $doctor['email'] ?? '-' }}</td>
                        <td class="text-right font-bold" style="color: #0f172a;">{{ $ar($doctor['name'] ?? '-') }}</td>
                        <td>{{ $loop->iteration }}</td>
                    </tr>
                @endforeach
            </tbody>
        </table>
    @endif

    <table class="signatures">
        <tr>
            <td class="signature-cell">
                <div class="signature-title">{{ $ar('عميد الكلية المصدّقة') }}</div>
                <div class="signature-line"></div>
                <div style="font-size: 9px; color: #94a3b8; margin-top: 6px;">{{ $ar('التوقيع / الختم') }}</div>
            </td>
            <td class="signature-cell">
                <div class="signature-title">{{ $ar('رئيس القسم المصدّر') }}</div>
                <div class="signature-line"></div>
                <div style="font-size: 9px; color: #94a3b8; margin-top: 6px;">{{ $ar('التوقيع / الختم') }}</div>
            </td>
            <td class="signature-cell">
                <div class="signature-title">{{ $ar('مسؤول شؤون الطلاب') }}</div>
                <div class="signature-line"></div>
                <div style="font-size: 9px; color: #94a3b8; margin-top: 6px;">{{ $ar('التوقيع / الختم') }}</div>
            </td>
        </tr>
    </table>
</body>
</html>
