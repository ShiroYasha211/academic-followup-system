<!DOCTYPE html>
<html lang="ar" dir="rtl">

<head>
    <meta charset="UTF-8">
    <title>السجل السريري - {{ $student->name }}</title>
    <style>
        body {
            font-family: 'XBRiyaz', 'DejaVu Sans', sans-serif;
            direction: rtl;
            text-align: right;
            color: #333;
            margin: 0;
            padding: 20px;
        }

        .header {
            text-align: center;
            border-bottom: 2px solid #1d4ed8;
            padding-bottom: 20px;
            margin-bottom: 30px;
        }

        .header h1 {
            color: #1d4ed8;
            margin: 0 0 10px 0;
            font-size: 24px;
        }

        .student-info {
            background: #f8fafc;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 30px;
            border: 1px solid #e2e8f0;
        }

        .student-info p {
            margin: 5px 0;
            font-size: 14px;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
            font-size: 12px;
        }

        th,
        td {
            border: 1px solid #cbd5e1;
            padding: 10px;
            text-align: right;
        }

        th {
            background-color: #f1f5f9;
            color: #1e293b;
            font-weight: bold;
        }

        .footer {
            margin-top: 50px;
            text-align: center;
            font-size: 12px;
            color: #64748b;
        }

        .page-break {
            page-break-after: always;
        }
    </style>
</head>

<body>

    <div class="header">
        <h1>سجل التدريب السريري الرسمي (Logbook)</h1>
        <p>كلية الطب - ملف متدرب معتمد</p>
    </div>

    <div class="student-info">
        <p><strong>اسم الطالب:</strong> {{ $student->name }}</p>
        <p><strong>الرقم الجامعي:</strong> {{ $student->university_id }}</p>
        <p><strong>تاريخ التصدير:</strong> {{ now()->format('Y-m-d') }}</p>
    </div>

    <table>
        <thead>
            <tr>
                <th>التاريخ</th>
                <th>المركز التدريبي</th>
                <th>القسم</th>
                <th>الدكتور المشرف</th>
                <th>الأنشطة المنجزة</th>
            </tr>
        </thead>
        <tbody>
            @foreach($entries as $e)
            <tr>
                <td>{{ $e->log_date->format('Y-m-d') }}</td>
                <td>{{ $e->trainingCenter->name ?? '-' }}</td>
                <td>{{ $e->department->name ?? '-' }}</td>
                <td>د. {{ $e->doctor->name ?? '-' }}</td>
                <td>
                    حضور: نعم<br>
                    م. مرضي: {{ $e->history_count }}<br>
                    فحص: {{ $e->exam_count }}<br>
                    جولة: {{ $e->did_round ? 'نعم' : 'لا' }}
                </td>
            </tr>
            @endforeach
        </tbody>
    </table>

    <div class="footer">
        <p>هذا السجل تم تصديره إلكترونياً ولا يحتاج إلى توقيع مادي إضافي بفضل نظام الاعتماد الرقمي من المشرفين.</p>
    </div>

</body>

</html>