<!doctype html>
<html lang="ar">
<head>
    <meta charset="utf-8">
    <title>تقرير إنجازات الطالب العملية</title>
    <style>
        @page {
            size: A4 portrait;
            margin: 20px 24px;
        }

        * {
            box-sizing: border-box;
        }

        body {
            margin: 0;
            direction: ltr;
            font-family: "DejaVu Sans", sans-serif;
            font-size: 11px;
            color: #111827;
            line-height: 1.5;
            text-align: right;
        }

        /* ── Header ─────────────────────────────────────── */

        .header-table {
            width: 100%;
            border-collapse: collapse;
            border-bottom: 2.5px solid #0f1b35;
            margin-bottom: 10px;
            direction: ltr;
        }

        .header-table td {
            vertical-align: middle;
            padding-bottom: 10px;
        }

        .header-logo-cell {
            width: 70px;
            text-align: center;
        }

        .logo-circle {
            display: inline-block;
            width: 56px;
            height: 56px;
            border: 2px solid #0f1b35;
            border-radius: 50%;
            line-height: 52px;
            text-align: center;
            font-size: 16px;
            font-weight: bold;
            color: #0f1b35;
        }

        .header-left {
            width: 38%;
            text-align: right;
            font-size: 11px;
            line-height: 1.8;
            font-weight: bold;
            color: #374151;
        }

        .header-right {
            width: 38%;
            text-align: right;
            font-size: 11px;
            line-height: 1.8;
            color: #6b7280;
        }

        .header-right .label {
            font-weight: bold;
            color: #374151;
        }

        /* ── Page title ─────────────────────────────────── */

        .page-title {
            text-align: center;
            font-size: 17px;
            font-weight: bold;
            color: #0f1b35;
            margin: 6px 0 14px;
            padding-bottom: 6px;
            border-bottom: 1px solid #e5e7eb;
            direction: ltr;
        }

        /* ── Student info band ──────────────────────────── */

        .student-band {
            background: #0f1b35;
            color: #ffffff;
            padding: 9px 14px;
            border-radius: 4px;
            margin-bottom: 12px;
            direction: ltr;
        }

        .student-band table {
            width: 100%;
            border-collapse: collapse;
            direction: ltr;
        }

        .student-band td {
            color: #ffffff;
            font-size: 11px;
            text-align: right;
            padding: 0 4px;
        }

        .student-band .s-label {
            color: #93c5fd;
            font-size: 9.5px;
            display: block;
        }

        .student-band .s-value {
            font-weight: bold;
            font-size: 11.5px;
        }

        /* ── Summary cards row ──────────────────────────── */

        .summary-row {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 14px;
            direction: ltr;
        }

        .summary-row td {
            width: 25%;
            padding: 3px;
            vertical-align: top;
        }

        .summary-card {
            border: 1.5px solid #e5e7eb;
            border-radius: 6px;
            padding: 9px 10px;
            text-align: center;
            background: #f9fafb;
        }

        .summary-card .sc-value {
            font-size: 22px;
            font-weight: bold;
            color: #0f1b35;
            display: block;
            direction: ltr;
        }

        .summary-card .sc-label {
            font-size: 9.5px;
            color: #6b7280;
            margin-top: 2px;
            display: block;
            direction: ltr;
        }

        .summary-card.card-total { border-color: #2563eb; background: #eff6ff; }
        .summary-card.card-total .sc-value { color: #1d4ed8; }
        .summary-card.card-hist { border-color: #0d9488; }
        .summary-card.card-hist .sc-value { color: #0f766e; }
        .summary-card.card-exam { border-color: #d97706; }
        .summary-card.card-exam .sc-value { color: #b45309; }
        .summary-card.card-round { border-color: #16a34a; }
        .summary-card.card-round .sc-value { color: #15803d; }

        /* ── Section header ─────────────────────────────── */

        .section-header {
            font-size: 13px;
            font-weight: bold;
            color: #0f1b35;
            border-right: 3.5px solid #2563eb;
            padding-right: 8px;
            margin: 14px 0 8px;
            direction: ltr;
            text-align: right;
        }

        /* ── Matrix table ───────────────────────────────── */

        .matrix-table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 4px;
            direction: ltr;
        }

        .matrix-table th {
            background: #0f1b35;
            color: #ffffff;
            padding: 8px 10px;
            font-size: 10.5px;
            font-weight: bold;
            text-align: center;
            border: 1px solid #1e3a5f;
        }

        .matrix-table th.col-name {
            text-align: right;
        }

        .matrix-table td {
            border: 1px solid #e5e7eb;
            padding: 7px 10px;
            font-size: 10.5px;
            text-align: center;
            vertical-align: middle;
        }

        .matrix-table td.col-name {
            text-align: right;
            font-weight: bold;
            color: #1f2937;
        }

        .matrix-table tr:nth-child(even) td {
            background: #f9fafb;
        }

        .matrix-table .totals-row td {
            background: #f0f4ff;
            font-weight: bold;
            color: #1d4ed8;
            border-top: 2px solid #bfdbfe;
        }

        .num-teal { color: #0f766e; font-weight: bold; }
        .num-gold { color: #b45309; font-weight: bold; }
        .num-green { color: #15803d; font-weight: bold; }
        .num-blue { color: #1d4ed8; font-weight: bold; }

        /* ── Sessions log table ─────────────────────────── */

        .log-table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 8px;
            direction: ltr;
            font-size: 10px;
        }

        .log-table th {
            background: #374151;
            color: #f3f4f6;
            padding: 7px 8px;
            font-size: 10px;
            font-weight: bold;
            text-align: center;
            border: 1px solid #4b5563;
        }

        .log-table td {
            border: 1px solid #e5e7eb;
            padding: 6px 8px;
            vertical-align: middle;
            text-align: center;
        }

        .log-table td.td-date { width: 78px; direction: ltr; text-align: center; font-size: 9.5px; color: #374151; }
        .log-table td.td-center { text-align: right; }
        .log-table td.td-dept { text-align: right; color: #6b7280; font-size: 9.5px; }

        .log-table tr:nth-child(odd) td { background: #fafafa; }

        .badge-confirmed { color: #15803d; font-weight: bold; }
        .badge-partial   { color: #b45309; font-weight: bold; }
        .badge-rejected  { color: #b91c1c; font-weight: bold; }

        /* ── Footer ─────────────────────────────────────── */

        .footer-band {
            margin-top: 20px;
            border-top: 1px solid #e5e7eb;
            padding-top: 8px;
            direction: ltr;
        }

        .footer-table {
            width: 100%;
            border-collapse: collapse;
        }

        .footer-table td {
            width: 50%;
            text-align: center;
            font-size: 10.5px;
            color: #374151;
            padding-top: 6px;
        }

        .sig-line {
            display: block;
            margin-top: 22px;
            border-top: 1px solid #9ca3af;
            width: 65%;
            margin-left: auto;
            margin-right: auto;
        }

        .generated-at {
            text-align: center;
            font-size: 9px;
            color: #9ca3af;
            margin-top: 8px;
            direction: ltr;
        }
    </style>
</head>
<body>
@php
    use App\Helpers\ArabicHelper;
    $ar  = fn ($text) => ArabicHelper::fixArabic((string) $text, true);
    $arN = fn ($text) => ArabicHelper::fixArabic((string) $text, false); // no reverse (numbers / LTR segments)

    $student = $portfolio['student'];
    $summary = $portfolio['summary'];
    $matrix  = $portfolio['matrix'] ?? [];
    $logs    = $portfolio['logs']   ?? [];

    $universityName = data_get($student, 'major.college.university.name', '');
    $collegeName    = data_get($student, 'major.college.name', '');
    $majorName      = data_get($student, 'major.name', '');
    $levelName      = data_get($student, 'level.name', '');

    $totalHist  = $summary['history_taking']       ?? 0;
    $totalExam  = $summary['clinical_examination']  ?? 0;
    $totalRound = $summary['round']                 ?? 0;
    $totalAll   = $summary['approved_activities']   ?? 0;

    $statusLabel = fn ($status) => match ($status) {
        'confirmed'           => ['text' => 'معتمدة',   'class' => 'badge-confirmed'],
        'partially_confirmed' => ['text' => 'جزئياً',   'class' => 'badge-partial'],
        'rejected'            => ['text' => 'مرفوضة',   'class' => 'badge-rejected'],
        default               => ['text' => 'قيد المراجعة', 'class' => ''],
    };
@endphp

{{-- ═══════════ HEADER ═══════════ --}}
<table class="header-table">
    <tr>
        <td class="header-left">
            @if($universityName)
                <div>{{ $ar($universityName) }}</div>
            @endif
            @if($collegeName)
                <div>{{ $ar($collegeName) }}</div>
            @endif
            @if($majorName)
                <div>{{ $ar($majorName) }}</div>
            @endif
        </td>
        <td class="header-logo-cell">
            @php
                $uniLogoRel = data_get($student, 'major.college.university.logo');
                $logoPath = $uniLogoRel ? public_path('storage/' . $uniLogoRel) : null;
            @endphp
            @if($logoPath && file_exists($logoPath))
                <img src="{{ $logoPath }}" alt="Logo" style="max-width:58px;max-height:58px;">
            @else
                <div class="logo-circle">M</div>
            @endif
        </td>
        <td class="header-right">
            <div><span class="label">{{ $ar('تاريخ التقرير') }}:</span> {{ now()->format('Y/m/d') }}</div>
            @if($levelName)
                <div><span class="label">{{ $ar('المستوى') }}:</span> {{ $ar($levelName) }}</div>
            @endif
            <div><span class="label">{{ $ar('رقم القيد') }}:</span> {{ $student['student_number'] ?: '-' }}</div>
        </td>
    </tr>
</table>

{{-- ═══════════ PAGE TITLE ═══════════ --}}
<div class="page-title">{{ $ar('تقرير إنجازات الطالب العملية والسريرية') }}</div>

{{-- ═══════════ STUDENT BAND ═══════════ --}}
<div class="student-band">
    <table>
        <tr>
            <td style="width:50%">
                <span class="s-label">{{ $ar('اسم الطالب') }}</span>
                <span class="s-value">{{ $ar($student['name'] ?? '-') }}</span>
            </td>
            <td style="width:25%">
                <span class="s-label">{{ $ar('رقم القيد') }}</span>
                <span class="s-value" style="direction:ltr;display:block;text-align:right;">{{ $student['student_number'] ?? '-' }}</span>
            </td>
            <td style="width:25%">
                <span class="s-label">{{ $ar('المستوى') }}</span>
                <span class="s-value">{{ $ar($levelName ?: '-') }}</span>
            </td>
        </tr>
    </table>
</div>

{{-- ═══════════ SUMMARY CARDS ═══════════ --}}
<table class="summary-row">
    <tr>
        <td>
            <div class="summary-card card-total">
                <span class="sc-value">{{ $totalAll }}</span>
                <span class="sc-label">{{ $ar('إجمالي الأنشطة المعتمدة') }}</span>
            </div>
        </td>
        <td>
            <div class="summary-card card-hist">
                <span class="sc-value">{{ $totalHist }}</span>
                <span class="sc-label">{{ $ar('قصص مرضية') }}</span>
            </div>
        </td>
        <td>
            <div class="summary-card card-exam">
                <span class="sc-value">{{ $totalExam }}</span>
                <span class="sc-label">{{ $ar('فحوصات سريرية') }}</span>
            </div>
        </td>
        <td>
            <div class="summary-card card-round">
                <span class="sc-value">{{ $totalRound }}</span>
                <span class="sc-label">{{ $ar('مرور') }}</span>
            </div>
        </td>
    </tr>
</table>

{{-- ═══════════ MATRIX TABLE ═══════════ --}}
<div class="section-header">{{ $ar('الجدول التراكمي للإنجازات') }}</div>

@if(count($matrix) > 0)
@php
    $mHist  = 0; $mExam = 0; $mRound = 0; $mTotal = 0;
    foreach ($matrix as $row) {
        $mHist  += (int)($row['history_taking'] ?? 0);
        $mExam  += (int)($row['clinical_examination'] ?? 0);
        $mRound += (int)($row['round'] ?? 0);
        $mTotal += (int)($row['total'] ?? 0);
    }
@endphp
<table class="matrix-table">
    <thead>
        <tr>
            <th class="col-name" style="width:42%">{{ $ar('نظام الجسم / المهارة') }}</th>
            <th style="width:15%">{{ $ar('قصص') }}</th>
            <th style="width:15%">{{ $ar('فحوصات') }}</th>
            <th style="width:13%">{{ $ar('مرور') }}</th>
            <th style="width:15%">{{ $ar('الإجمالي') }}</th>
        </tr>
    </thead>
    <tbody>
        @foreach($matrix as $row)
            <tr>
                <td class="col-name">{{ $ar($row['body_system'] ?? '-') }}</td>
                <td class="num-teal">{{ $row['history_taking'] ?? 0 }}</td>
                <td class="num-gold">{{ $row['clinical_examination'] ?? 0 }}</td>
                <td class="num-green">{{ $row['round'] ?? 0 }}</td>
                <td class="num-blue">{{ $row['total'] ?? 0 }}</td>
            </tr>
        @endforeach
        <tr class="totals-row">
            <td class="col-name">{{ $ar('الإجمالي الكلي') }}</td>
            <td>{{ $mHist }}</td>
            <td>{{ $mExam }}</td>
            <td>{{ $mRound }}</td>
            <td>{{ $mTotal }}</td>
        </tr>
    </tbody>
</table>
@else
    <p style="color:#6b7280;text-align:right;direction:ltr;">{{ $ar('لا توجد بيانات في الجدول التراكمي.') }}</p>
@endif

{{-- ═══════════ SESSIONS LOG ═══════════ --}}
<div class="section-header">{{ $ar('تفاصيل الجلسات السريرية') }}</div>

@if(count($logs) > 0)
<table class="log-table">
    <thead>
        <tr>
            <th style="width:14%">{{ $ar('التاريخ') }}</th>
            <th style="width:20%;text-align:right;">{{ $ar('المركز التدريبي') }}</th>
            <th style="width:18%;text-align:right;">{{ $ar('القسم') }}</th>
            <th style="width:16%;text-align:right;">{{ $ar('النوع') }}</th>
            <th style="width:22%;text-align:right;">{{ $ar('النظام / الحالة') }}</th>
            <th style="width:10%">{{ $ar('الحالة') }}</th>
        </tr>
    </thead>
    <tbody>
        @foreach($logs as $log)
            @php
                $sl   = $statusLabel($log['status'] ?? '');
                $date = $log['date'] ?? '-';
                $center = $ar($log['training_center'] ?? '-');
                $dept   = $ar($log['department'] ?? '-');
                $activities = $log['activities'] ?? [];
                $rowSpan = max(1, count($activities));
            @endphp
            @if(count($activities) === 0)
                <tr>
                    <td class="td-date">{{ $date }}</td>
                    <td class="td-center">{{ $center }}</td>
                    <td class="td-dept">{{ $dept }}</td>
                    <td>-</td>
                    <td>-</td>
                    <td class="{{ $sl['class'] }}">{{ $ar($sl['text']) }}</td>
                </tr>
            @else
                @foreach($activities as $actIndex => $activity)
                    <tr>
                        @if($actIndex === 0)
                            <td class="td-date" rowspan="{{ $rowSpan }}">{{ $date }}</td>
                            <td class="td-center" rowspan="{{ $rowSpan }}">{{ $center }}</td>
                            <td class="td-dept" rowspan="{{ $rowSpan }}">{{ $dept }}</td>
                        @endif
                        <td style="text-align:right;">{{ $ar($activity['type_label'] ?? '-') }}</td>
                        <td style="text-align:right;">{{ $ar($activity['body_system'] ?? '-') }}</td>
                        @if($actIndex === 0)
                            <td class="{{ $sl['class'] }}" rowspan="{{ $rowSpan }}">{{ $ar($sl['text']) }}</td>
                        @endif
                    </tr>
                @endforeach
            @endif
        @endforeach
    </tbody>
</table>
@else
    <p style="color:#6b7280;text-align:right;direction:ltr;">{{ $ar('لا توجد جلسات مسجلة.') }}</p>
@endif

{{-- ═══════════ FOOTER ═══════════ --}}
<div class="footer-band">
    <table class="footer-table">
        <tr>
            <td>
                {{ $ar('توقيع الدكتور المشرف') }}
                <span class="sig-line"></span>
            </td>
            <td>
                {{ $ar('ختم القسم / الكلية') }}
                <span class="sig-line"></span>
            </td>
        </tr>
    </table>
</div>

<div class="generated-at">
    {{ $ar('تم إنشاء هذا التقرير بتاريخ') }}: {{ now()->format('Y/m/d H:i') }}
    &nbsp;|&nbsp;
    {{ $ar('نظام معين الطبي') }}
</div>

</body>
</html>
