<!DOCTYPE html>
<html dir="rtl" lang="ar">

<head>
    <meta charset="UTF-8">
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <title>كشف الدرجات</title>
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
            border-bottom: 2px solid #10b981;
            padding-bottom: 20px;
        }

        .header h1 {
            color: #10b981;
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

        .average-box {
            background: linear-gradient(135deg, #10b981, #059669);
            color: white;
            padding: 20px;
            border-radius: 12px;
            text-align: center;
            margin-bottom: 25px;
        }

        .average-number {
            font-size: 36px;
            font-weight: bold;
        }

        .average-label {
            font-size: 14px;
            opacity: 0.9;
        }

        table.main {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }

        table.main th {
            background: #10b981;
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

        .grade-excellent {
            color: #10b981;
            font-weight: bold;
        }

        .grade-good {
            color: #3b82f6;
            font-weight: bold;
        }

        .grade-pass {
            color: #f59e0b;
            font-weight: bold;
        }

        .grade-fail {
            color: #ef4444;
            font-weight: bold;
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
        <h1>كشف الدرجات</h1>
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

    <div class="average-box">
        <div class="average-number">{{ $average }}%</div>
        <div class="average-label">المعدل العام</div>
    </div>

    <table class="main">
        <thead>
            <tr>
                <th>#</th>
                <th>المادة</th>
                <th>أعمال السنة (40)</th>
                <th>النهائي (60)</th>
                <th>المجموع</th>
                <th>التقدير</th>
            </tr>
        </thead>
        <tbody>
            @foreach($grades as $index => $grade)
            @php
            $total = ($grade->continuous_score ?? 0) + ($grade->final_score ?? 0);
            $total = min(100, $total);

            if ($total >= 90) {
            $gradeClass = 'grade-excellent';
            $gradeLetter = 'ممتاز';
            } elseif ($total >= 75) {
            $gradeClass = 'grade-good';
            $gradeLetter = 'جيد جداً';
            } elseif ($total >= 60) {
            $gradeClass = 'grade-pass';
            $gradeLetter = 'جيد';
            } elseif ($total >= 50) {
            $gradeClass = 'grade-pass';
            $gradeLetter = 'مقبول';
            } else {
            $gradeClass = 'grade-fail';
            $gradeLetter = 'راسب';
            }
            @endphp
            <tr>
                <td>{{ $index + 1 }}</td>
                <td>{{ $grade->subject->name ?? '-' }}</td>
                <td>{{ $grade->continuous_score ?? '-' }}</td>
                <td>{{ $grade->final_score ?? '-' }}</td>
                <td style="font-weight: bold;">{{ $total }}</td>
                <td class="{{ $gradeClass }}">{{ $gradeLetter }}</td>
            </tr>
            @endforeach
        </tbody>
    </table>

    <div class="footer">
        تم إنشاء هذا الكشف بتاريخ {{ $generated_at->format('Y/m/d h:i A') }}
    </div>
</body>

</html>