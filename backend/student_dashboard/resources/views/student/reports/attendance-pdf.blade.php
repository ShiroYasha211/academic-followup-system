<!DOCTYPE html>
<html dir="rtl" lang="ar">

<head>
    <meta charset="UTF-8">
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <title>تقرير الحضور</title>
    <style>
        @font-face {
            font-family: 'Cairo';
            src: url('{{ storage_path(' fonts/Cairo-Regular.ttf') }}') format('truetype');
        }

        body {
            font-family: 'Cairo', 'DejaVu Sans', sans-serif;
            direction: rtl;
            text-align: right;
            padding: 20px;
            color: #1e293b;
        }

        .header {
            text-align: center;
            margin-bottom: 30px;
            border-bottom: 2px solid #4f46e5;
            padding-bottom: 20px;
        }

        .header h1 {
            color: #4f46e5;
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

        .stats-grid {
            display: flex;
            justify-content: space-between;
            margin-bottom: 20px;
        }

        .stat-box {
            background: #f1f5f9;
            padding: 15px;
            border-radius: 8px;
            text-align: center;
            width: 22%;
            display: inline-block;
        }

        .stat-number {
            font-size: 24px;
            font-weight: bold;
            color: #1e293b;
        }

        .stat-label {
            color: #64748b;
            font-size: 12px;
        }

        table.main {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }

        table.main th {
            background: #4f46e5;
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

        .status-present {
            color: #10b981;
        }

        .status-absent {
            color: #ef4444;
        }

        .status-late {
            color: #f59e0b;
        }

        .status-excused {
            color: #6366f1;
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
        <h1>تقرير الحضور والغياب</h1>
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

    <div style="margin-bottom: 20px;">
        <div class="stat-box">
            <div class="stat-number">{{ $stats['total_lectures'] }}</div>
            <div class="stat-label">إجمالي المحاضرات</div>
        </div>
        <div class="stat-box">
            <div class="stat-number" style="color: #10b981;">{{ $stats['present'] }}</div>
            <div class="stat-label">حضور</div>
        </div>
        <div class="stat-box">
            <div class="stat-number" style="color: #ef4444;">{{ $stats['absent'] }}</div>
            <div class="stat-label">غياب</div>
        </div>
        <div class="stat-box">
            <div class="stat-number" style="color: #6366f1;">{{ $stats['excused'] }}</div>
            <div class="stat-label">عذر</div>
        </div>
    </div>

    <table class="main">
        <thead>
            <tr>
                <th>المادة</th>
                <th>إجمالي</th>
                <th>حضور</th>
                <th>غياب</th>
                <th>عذر</th>
                <th>النسبة</th>
            </tr>
        </thead>
        <tbody>
            @foreach($subjects as $subject)
            @php
            $total = $subject->attendances->count();
            $present = $subject->attendances->where('status', 'present')->count();
            $absent = $subject->attendances->where('status', 'absent')->count();
            $excused = $subject->attendances->where('status', 'excused')->count();
            $percentage = $total > 0 ? round(($present + $excused) / $total * 100) : 0;
            @endphp
            <tr>
                <td>{{ $subject->name }}</td>
                <td>{{ $total }}</td>
                <td class="status-present">{{ $present }}</td>
                <td class="status-absent">{{ $absent }}</td>
                <td class="status-excused">{{ $excused }}</td>
                <td>{{ $percentage }}%</td>
            </tr>
            @endforeach
        </tbody>
    </table>

    <div class="footer">
        تم إنشاء هذا التقرير بتاريخ {{ $generated_at->format('Y/m/d h:i A') }}
    </div>
</body>

</html>