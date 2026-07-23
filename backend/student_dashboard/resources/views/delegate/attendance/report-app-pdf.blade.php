<!doctype html>
<html lang="ar">
<head>
    <meta charset="utf-8">
    <title>تقرير الحضور والغياب</title>
    <style>
        @page {
            size: A4 portrait;
            margin: 18px 22px;
        }

        * {
            box-sizing: border-box;
        }

        body {
            margin: 0;
            direction: ltr;
            color: #111827;
            font-family: "DejaVu Sans", sans-serif;
            font-size: 11px;
            line-height: 1.45;
            text-align: right;
        }

        .sheet {
            border: 2px solid #111827;
            padding: 14px;
            min-height: 760px;
            direction: ltr;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            direction: ltr;
        }

        th,
        td,
        div,
        span {
            direction: ltr;
        }

        .header-table td {
            border-bottom: 2px solid #111827;
            padding-bottom: 10px;
            vertical-align: middle;
        }

        .header-side {
            width: 36%;
            font-size: 12px;
            font-weight: bold;
            line-height: 1.8;
        }

        .header-center {
            width: 28%;
            text-align: center;
            direction: ltr;
        }

        .logo-box {
            display: inline-block;
            width: 58px;
            height: 58px;
            border: 2px solid #111827;
            border-radius: 50%;
            text-align: center;
            line-height: 54px;
            font-weight: bold;
            font-size: 18px;
        }

        .logo {
            max-width: 64px;
            max-height: 64px;
        }

        .title {
            margin: 14px 0 12px;
            text-align: center;
            font-size: 18px;
            font-weight: bold;
            text-decoration: underline;
        }

        .meta-table {
            margin-bottom: 12px;
            border: 1px solid #111827;
        }

        .meta-table td {
            width: 33.333%;
            padding: 7px 8px;
            border: 1px solid #111827;
            vertical-align: top;
            text-align: right;
        }

        .meta-label {
            display: block;
            color: #374151;
            font-weight: bold;
            margin-bottom: 2px;
        }

        .students-table th,
        .students-table td {
            border: 1px solid #111827;
            padding: 5px 6px;
            text-align: center;
            vertical-align: middle;
            unicode-bidi: embed;
        }

        .students-table th {
            background: #e5e7eb;
            font-weight: bold;
        }

        .student-name {
            text-align: right;
            font-weight: bold;
        }

        .summary-table {
            margin-top: 12px;
            border: 1px solid #111827;
        }

        .summary-table td {
            width: 20%;
            padding: 8px;
            border: 1px solid #111827;
            text-align: center;
            background: #f9fafb;
            font-weight: bold;
        }

        .status-present {
            color: #15803d;
            font-weight: bold;
        }

        .status-absent {
            color: #b91c1c;
            font-weight: bold;
        }

        .status-late {
            color: #c2410c;
            font-weight: bold;
        }

        .status-excused {
            color: #1d4ed8;
            font-weight: bold;
        }

        .status-empty {
            color: #6b7280;
            font-weight: bold;
        }

        .footer-table {
            margin-top: 34px;
            page-break-inside: avoid;
        }

        .footer-table td {
            width: 50%;
            text-align: center;
            font-weight: bold;
            padding-top: 10px;
        }

        .signature-line {
            display: block;
            margin-top: 24px;
            font-weight: normal;
        }

        .ltr {
            direction: ltr;
            unicode-bidi: embed;
            display: inline-block;
        }

        .rtl-text { direction: ltr; }
    </style>
</head>
<body>
@php
    $ar = fn ($text) => \App\Helpers\ArabicHelper::fixArabic((string) $text, true);
    $reportUniversity = $subject?->major?->college?->university ?? $delegate?->major?->college?->university;
    $reportCollege = $subject?->major?->college ?? $delegate?->major?->college;
    $reportMajor = $subject?->major ?? $delegate?->major;
    $reportLevel = $subject?->level?->name ?? $delegate?->level?->name ?? '-';
    $reportSubjectLine = $subject ? "{$subject->name} ({$subject->code})" : 'محاضرة غير رسمية غير مرتبطة بمادة';
    $reportLectureType = ($isUnofficial ?? false)
        ? 'محاضرة غير رسمية مستقلة'
        : (($lecture?->lecture_type ?? 'official') === 'special' ? 'محاضرة خاصة' : 'محاضرة رسمية');
    $reportDoctorName = $subject?->doctor?->name ?? 'غير مرتبطة بدكتور مادة';
    $attendanceMethod = ($attendanceRecords->first()?->attendance_method ?? 'manual') === 'qr' ? 'باركود QR' : 'يدوي';
    $recordedBy = $attendanceRecords->first()?->recorder?->name ?? 'غير محدد';
    $genderLabel = ($genderFilter ?? 'all') === 'male' ? 'الأولاد فقط' : (($genderFilter ?? 'all') === 'female' ? 'البنات فقط' : 'الكل');
    $presentCount = $attendanceRecords->where('status', 'present')->count();
    $absentCount = $attendanceRecords->where('status', 'absent')->count();
    $lateCount = $attendanceRecords->where('status', 'late')->count();
    $excusedCount = $attendanceRecords->where('status', 'excused')->count();
    $reportDateDisplay = $dateDisplay ?? $date;
@endphp

<div class="sheet">
    <table class="header-table">
        <tr>
            <td class="header-side rtl-text" style="text-align: right;">
                <div>{{ $ar($reportUniversity->name ?? 'اسم الجامعة') }}</div>
                <div>{{ $ar('كلية ' . ($reportCollege->name ?? 'اسم الكلية')) }}</div>
                <div>{{ $ar('قسم ' . ($reportMajor->name ?? 'اسم القسم')) }}</div>
            </td>
            <td class="header-center">
                @if($reportUniversity?->logo)
                    <img class="logo" src="{{ public_path('storage/' . $reportUniversity->logo) }}" alt="Logo">
                @else
                    <span class="logo-box">U</span>
                @endif
            </td>
            <td class="header-side rtl-text" style="text-align: right;">
                <div>{{ $ar('تاريخ التقرير') }}: <span class="ltr">{{ now()->format('Y/m/d') }}</span></div>
                <div>{{ $ar('تاريخ المحاضرة') }}: <span class="ltr">{{ $reportDateDisplay }}</span></div>
            </td>
        </tr>
    </table>

    <div class="title rtl-text">{{ $ar('كشف حضور محاضرة') }} (<span class="ltr">{{ $reportDateDisplay }}</span>)</div>

    <table class="meta-table">
        <tr>
            <td><span class="meta-label">{{ $ar('المقرر الدراسي') }}</span>{{ $ar($reportSubjectLine) }}</td>
            <td><span class="meta-label">{{ $ar('نوع المحاضرة') }}</span>{{ $ar($reportLectureType) }}</td>
            <td><span class="meta-label">{{ $ar('المستوى') }}</span>{{ $ar($reportLevel) }}</td>
        </tr>
        <tr>
            <td><span class="meta-label">{{ $ar('دكتور المادة') }}</span>{{ $ar($reportDoctorName) }}</td>
            <td><span class="meta-label">{{ $ar('طريقة التحضير') }}</span>{{ $ar($attendanceMethod) }}</td>
            <td><span class="meta-label">{{ $ar('تم الرصد بواسطة') }}</span>{{ $ar($recordedBy) }}</td>
        </tr>
        <tr>
            <td><span class="meta-label">{{ $ar('فلتر العرض') }}</span>{{ $ar($genderLabel) }}</td>
            <td><span class="meta-label">{{ $ar('عنوان المحاضرة') }}</span>{{ $lecture?->title ? $ar($lecture->title) : '-' }}</td>
            <td><span class="meta-label">{{ $ar('رقم المحاضرة') }}</span><span class="ltr">{{ $lecture?->lecture_number ?? '-' }}</span></td>
        </tr>
    </table>

    <table class="students-table">
        <thead>
            <tr>
                <th style="width: 34px;">#</th>
                <th>{{ $ar('اسم الطالب') }}</th>
                <th style="width: 88px;">{{ $ar('رقم القيد') }}</th>
                <th style="width: 60px;">{{ $ar('الجنس') }}</th>
                <th style="width: 90px;">{{ $ar('حالة الحضور') }}</th>
                <th style="width: 78px;">{{ $ar('الطريقة') }}</th>
                <th style="width: 110px;">{{ $ar('تم بواسطة') }}</th>
            </tr>
        </thead>
        <tbody>
            @foreach($students as $index => $student)
                @php
                    $record = $attendanceRecords->get($student->id);
                    $status = $record?->status;
                    $statusClass = match ($status) {
                        'present' => 'status-present',
                        'absent' => 'status-absent',
                        'late' => 'status-late',
                        'excused' => 'status-excused',
                        default => 'status-empty',
                    };
                    $statusLabel = match ($status) {
                        'present' => 'حاضر',
                        'absent' => 'غائب',
                        'late' => 'متأخر',
                        'excused' => 'بعذر',
                        default => 'غير مرصود',
                    };
                @endphp
                <tr>
                    <td>{{ $index + 1 }}</td>
                    <td class="student-name">{{ $ar($student->name) }}</td>
                    <td><span class="ltr">{{ $student->student_number ?? '-' }}</span></td>
                    <td>{{ $ar($student->gender === 'female' ? 'أنثى' : 'ذكر') }}</td>
                    <td class="{{ $statusClass }}">{{ $ar($statusLabel) }}</td>
                    <td>{{ $record?->attendance_method === 'qr' ? 'QR' : ($record ? $ar('يدوي') : '-') }}</td>
                    <td>{{ $record?->recorder?->name ? $ar($record->recorder->name) : '-' }}</td>
                </tr>
            @endforeach
        </tbody>
    </table>

    <table class="summary-table">
        <tr>
            <td>{{ $ar('إجمالي الطلاب') }}: {{ $students->count() }}</td>
            <td>{{ $ar('حاضر') }}: {{ $presentCount }}</td>
            <td>{{ $ar('غائب') }}: {{ $absentCount }}</td>
            <td>{{ $ar('متأخر') }}: {{ $lateCount }}</td>
            <td>{{ $ar('بعذر') }}: {{ $excusedCount }}</td>
        </tr>
    </table>

    <table class="footer-table">
        <tr>
            <td>
                {{ $ar('مندوب الدفعة') }}
                <span class="signature-line">{{ $delegate?->name ? $ar($delegate->name) : '-' }}</span>
            </td>
            <td>
                {{ $ar('أستاذ المقرر') }}
                <span class="signature-line">........................................</span>
            </td>
        </tr>
    </table>
</div>
</body>
</html>
