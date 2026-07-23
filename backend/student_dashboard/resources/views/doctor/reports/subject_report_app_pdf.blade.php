<!DOCTYPE html>
<html lang="ar">
<head>
    <meta charset="UTF-8">
    <style>
        @page {
            margin: 35px 40px;
        }
        body {
            font-family: "DejaVu Sans", sans-serif;
            direction: ltr;
            color: #0f172a;
            font-size: 11px;
            line-height: 1.5;
            text-align: right;
        }
        .header {
            border-bottom: 2px double #0f766e;
            padding-bottom: 12px;
            margin-bottom: 20px;
        }
        .header-table {
            width: 100%;
            border-collapse: collapse;
        }
        .header-table td {
            border: none;
            padding: 0;
            vertical-align: top;
        }
        .header-right {
            text-align: right;
        }
        .header-left {
            text-align: left;
            color: #475569;
            font-size: 10.5px;
            line-height: 1.6;
        }
        h1 {
            margin: 0 0 6px;
            font-size: 20px;
            color: #0f766e;
        }
        .subtitle {
            font-size: 12px;
            color: #334155;
        }
        
        /* Bento statistics container */
        .stats {
            width: 100%;
            border-collapse: separate;
            border-spacing: 10px;
            margin-bottom: 25px;
        }
        .stats td {
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            border-radius: 12px;
            padding: 12px;
            text-align: center;
            width: 33.33%;
        }
        .stats .label {
            color: #64748b;
            font-size: 10px;
            font-weight: bold;
            margin-bottom: 4px;
        }
        .stats .value {
            font-size: 16px;
            font-weight: 800;
            color: #0f172a;
        }
        .stats .value-highlight {
            color: #0f766e;
        }

        /* Students table */
        table.data {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 35px;
        }
        table.data th {
            background: #f1f5f9;
            color: #1e293b;
            padding: 10px 8px;
            font-weight: bold;
            border-bottom: 2px solid #cbd5e1;
            font-size: 11px;
        }
        table.data td {
            border-bottom: 1px solid #e2e8f0;
            padding: 9px 8px;
            vertical-align: middle;
        }
        table.data tr:nth-child(even) td {
            background: #f8fafc;
        }
        
        /* Footer and signatures */
        .footer {
            margin-top: 45px;
            padding-top: 15px;
        }
        .signature-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 25px;
        }
        .signature-table td {
            border: none;
            width: 50%;
            color: #334155;
            font-size: 11px;
        }
    </style>
</head>
<body>
    @php
        // تعريف دالة معالجة وتشكيل النصوص العربية للـ PDF
        $ar = fn($text) => \App\Helpers\ArabicHelper::fixArabic((string) $text, true);

        // حساب إحصائيات المقاييس العامة للمقرر
        $totalStudents = count($students);
        $totalLectures = \App\Models\Attendance::where('subject_id', $subject->id)->distinct('date')->count('date');
        
        // في حال عدم وجود أي تحضير مسجل بعد في جدول التحضيرات، نعتمد الحد الأقصى لمحاضرات الطلاب
        if ($totalLectures === 0 && $totalStudents > 0) {
            $totalLectures = collect($students)->max('total') ?? 0;
        }
        
        $avgAttendanceRate = $totalStudents > 0 ? round(collect($students)->avg('attendance_rate')) : 0;
    @endphp

    <div class="header">
        <table class="header-table">
            <tr>
                <!-- معلومات الكلية والجامعة تظهر لليسار بصرياً فتوضع أولاً في كود الـ LTR -->
                <td class="header-left">
                    <div><strong>{{ $ar('الجامعة:') }}</strong> {{ $ar($subject->major?->college?->university?->name ?? '-') }}</div>
                    <div style="margin-top: 4px;"><strong>{{ $ar('الكلية / القسم:') }}</strong> {{ $ar($subject->major?->college?->name ?? '-') }} / {{ $ar($subject->major?->name ?? '-') }}</div>
                    <div style="margin-top: 4px;"><strong>{{ $ar('المستوى:') }}</strong> {{ $ar($subject->level?->name ?? '-') }}</div>
                    <div style="margin-top: 4px;"><strong>{{ $ar('تاريخ التصدير:') }}</strong> {{ $generatedAt }}</div>
                </td>
                <!-- عنوان التقرير والمادة يظهر لليمين بصرياً فيوضع ثانياً في كود الـ LTR -->
                <td class="header-right">
                    <h1>{{ $ar('تقرير حضور وغياب الطلاب') }}</h1>
                    <div class="subtitle" style="margin-top: 6px;">
                        <strong>{{ $ar('المادة:') }}</strong> {{ $ar($subject->name) }}
                    </div>
                    <div class="subtitle" style="margin-top: 4px;">
                        <strong>{{ $ar('الفصل الدراسي:') }}</strong> {{ $ar($subject->term?->name ?? '-') }}
                    </div>
                </td>
            </tr>
        </table>
    </div>

    <!-- كروت إحصائيات Bento -->
    <table class="stats">
        <tr>
            <td>
                <div class="label">{{ $ar('متوسط الحضور العام') }}</div>
                <div class="value value-highlight">{{ $avgAttendanceRate }}%</div>
            </td>
            <td>
                <div class="label">{{ $ar('إجمالي المحاضرات') }}</div>
                <div class="value">{{ $totalLectures }}</div>
            </td>
            <td>
                <div class="label">{{ $ar('إجمالي الطلاب') }}</div>
                <div class="value">{{ $totalStudents }}</div>
            </td>
        </tr>
    </table>

    <!-- جدول بيانات الطلاب -->
    <table class="data">
        <thead>
            <!-- ترتيب الأعمدة معكوس برمجياً لتظهر من اليمين لليسار بصرياً -->
            <tr>
                <th style="width: 12%; text-align: center;">{{ $ar('النسبة') }}</th>
                <th style="width: 10%; text-align: center;">{{ $ar('بعذر') }}</th>
                <th style="width: 10%; text-align: center;">{{ $ar('غياب') }}</th>
                <th style="width: 10%; text-align: center;">{{ $ar('حضور') }}</th>
                <th style="width: 10%; text-align: center;">{{ $ar('الإجمالي') }}</th>
                <th style="width: 15%; text-align: center;">{{ $ar('رقم القيد') }}</th>
                <th style="width: 27%; text-align: right;">{{ $ar('اسم الطالب') }}</th>
                <th style="width: 6%; text-align: center;">{{ $ar('#') }}</th>
            </tr>
        </thead>
        <tbody>
            @forelse($students as $index => $student)
                @php
                    $rate = $student['attendance_rate'];
                    $rateBg = $rate >= 75 ? '#e6f4ea' : ($rate >= 50 ? '#fef7e0' : '#fce8e6');
                    $rateColor = $rate >= 75 ? '#137333' : ($rate >= 50 ? '#b06000' : '#c5221f');
                @endphp
                <tr>
                    <!-- خلية النسبة المئوية -->
                    <td style="text-align: center;">
                        <span style="background-color: {{ $rateBg }}; color: {{ $rateColor }}; padding: 3px 8px; border-radius: 6px; font-weight: 700; font-size: 10px; display: inline-block;">
                            {{ $rate }}%
                        </span>
                    </td>
                    <!-- غياب بعذر -->
                    <td style="text-align: center;">{{ $student['excused'] }}</td>
                    <!-- غياب بدون عذر -->
                    <td style="text-align: center; color: #c5221f;">{{ $student['absent'] }}</td>
                    <!-- حضور -->
                    <td style="text-align: center; color: #137333;">{{ $student['present'] }}</td>
                    <!-- إجمالي المحاضرات المسجلة للطالب -->
                    <td style="text-align: center;">{{ $student['total'] }}</td>
                    <!-- رقم القيد الأكاديمي -->
                    <td style="text-align: center; color: #475569;">{{ $student['student_number'] ?? '-' }}</td>
                    <!-- اسم الطالب -->
                    <td style="text-align: right; font-weight: bold;">{{ $ar($student['name']) }}</td>
                    <!-- الرقم التسلسلي -->
                    <td style="text-align: center;">{{ $index + 1 }}</td>
                </tr>
            @empty
                <tr>
                    <td colspan="8" style="text-align: center; color: #64748b; padding: 20px;">
                        {{ $ar('لا توجد بيانات طلاب لهذا التقرير.') }}
                    </td>
                </tr>
            @endforelse
        </tbody>
    </table>

    <!-- ذيل الصفحة والتواقيع الرسمية -->
    <div class="footer">
        <table class="signature-table">
            <tr>
                <!-- توقيع رئيس القسم يظهر يساراً فيوضع أولاً في كود الـ LTR -->
                <td class="header-left" style="text-align: left;">
                    <strong>{{ $ar('اعتماد رئيس القسم:') }}</strong> _______________________
                </td>
                <!-- توقيع أستاذ المادة يظهر يميناً فيوضع ثانياً في كود الـ LTR -->
                <td class="header-right" style="text-align: right;">
                    <strong>{{ $ar('توقيع أستاذ المادة:') }}</strong> _______________________
                </td>
            </tr>
        </table>
        <div style="text-align: center; margin-top: 35px; color: #94a3b8; font-size: 9px;">
            {{ $ar('تم توليد هذا التقرير آلياً بواسطة نظام معين لإدارة الكليات والدرجات') }}
        </div>
    </div>
</body>
</html>
