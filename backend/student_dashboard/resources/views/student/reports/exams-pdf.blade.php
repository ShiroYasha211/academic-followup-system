<!DOCTYPE html>
<html dir="rtl" lang="ar">

<head>
    <meta charset="UTF-8">
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <title>جدول الاختبارات</title>
    <style>
        body {
            font-family: 'DejaVu Sans', sans-serif;
            direction: rtl;
            text-align: right;
            padding: 20px;
            color: #1e293b;
        }

        .header {
            text-align: center;
            margin-bottom: 30px;
            border-bottom: 2px solid #ef4444;
            padding-bottom: 20px;
        }

        .header h1 {
            color: #ef4444;
            margin: 0 0 10px 0;
            font-size: 24px;
        }

        .header p {
            color: #64748b;
            margin: 5px 0;
        }

        .student-info {
            background: #f8fafc;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 20px;
        }

        .student-info table {
            width: 100%;
        }

        .student-info td {
            padding: 5px 10px;
        }

        .student-info .label {
            color: #64748b;
            width: 100px;
        }

        .student-info .value {
            font-weight: bold;
        }

        table.main {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }

        table.main th {
            background: #ef4444;
            color: white;
            padding: 12px;
            text-align: right;
        }

        table.main td {
            padding: 10px;
            border-bottom: 1px solid #e2e8f0;
        }

        table.main tr:nth-child(even) {
            background: #f8fafc;
        }

        .date-col {
            font-weight: bold;
            color: #1e293b;
        }

        .time-col {
            color: #4f46e5;
        }

        .location-col {
            color: #64748b;
        }

        .footer {
            margin-top: 30px;
            text-align: center;
            color: #94a3b8;
            font-size: 11px;
            border-top: 1px solid #e2e8f0;
            padding-top: 15px;
        }
    </style>
</head>

<body>
    <div class="header">
        <h1>جدول الاختبارات النهائية</h1>
        <p>{{ $user->university->name ?? 'الجامعة' }}</p>
    </div>

    <div class="student-info">
        <table>
            <tr>
                <td class="label">اسم الطالب:</td>
                <td class="value">{{ $user->name }}</td>
                <td class="label">الرقم الجامعي:</td>
                <td class="value">{{ $user->student_number ?? '-' }}</td>
            </tr>
            <tr>
                <td class="label">التخصص:</td>
                <td class="value">{{ $user->major->name ?? '-' }}</td>
                <td class="label">المستوى:</td>
                <td class="value">{{ $user->level->name ?? '-' }}</td>
            </tr>
        </table>
    </div>

    <table class="main">
        <thead>
            <tr>
                <th>#</th>
                <th>المادة</th>
                <th>اليوم</th>
                <th>التاريخ</th>
                <th>الوقت</th>
                <th>القاعة</th>
            </tr>
        </thead>
        <tbody>
            @forelse($exams as $index => $exam)
            @php
            $days = ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
            $dayName = $days[$exam->exam_date->dayOfWeek] ?? '';
            @endphp
            <tr>
                <td>{{ $index + 1 }}</td>
                <td>{{ $exam->subject->name ?? '-' }}</td>
                <td>{{ $dayName }}</td>
                <td class="date-col">{{ $exam->exam_date->format('Y/m/d') }}</td>
                <td class="time-col">
                    {{ \Carbon\Carbon::parse($exam->start_time)->format('h:i A') }}
                    -
                    {{ \Carbon\Carbon::parse($exam->end_time)->format('h:i A') }}
                </td>
                <td class="location-col">{{ $exam->location ?? '-' }}</td>
            </tr>
            @empty
            <tr>
                <td colspan="6" style="text-align: center; padding: 20px; color: #94a3b8;">
                    لا توجد اختبارات مجدولة
                </td>
            </tr>
            @endforelse
        </tbody>
    </table>

    <div class="footer">
        تم إنشاء هذا الجدول بتاريخ {{ $generated_at->format('Y/m/d h:i A') }}
    </div>
</body>

</html>