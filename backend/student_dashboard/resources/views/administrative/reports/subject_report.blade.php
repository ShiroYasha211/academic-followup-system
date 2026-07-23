@extends('layouts.administrative')

@section('title', 'تقرير حضور: ' . $subject->name)

@section('content')

<style>
    /* Premium Screen Styles */
    @media screen {
        .report-card {
            background: white;
            border-radius: 24px;
            padding: 3rem;
            box-shadow: 0 10px 30px rgba(0,0,0,0.05);
            max-width: 1000px;
            margin: 0 auto;
            border: 1px solid #e2e8f0;
        }
        .report-header-premium {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 3rem;
            padding-bottom: 2rem;
            border-bottom: 2px solid #f1f5f9;
        }
        .info-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 1.5rem;
            margin-bottom: 3rem;
        }
        .info-item {
            background: #f8fafc;
            padding: 1.25rem;
            border-radius: 16px;
            border: 1px solid #f1f5f9;
        }
        .info-label {
            display: block;
            font-size: 0.75rem;
            font-weight: 800;
            color: #64748b;
            margin-bottom: 0.25rem;
        }
        .info-value {
            font-size: 1.1rem;
            font-weight: 900;
            color: #1e293b;
        }
    }

    /* Professional Print Styles */
    @media print {
        @page { size: A4; margin: 1.5cm; }
        body { background: white !important; color: black !important; font-family: 'Times New Roman', serif; }
        .no-print { display: none !important; }
        .report-card { border: none !important; box-shadow: none !important; padding: 0 !important; max-width: 100% !important; }
        .report-header-premium { border-bottom: 2px solid black !important; padding-bottom: 10px !important; margin-bottom: 20px !important; }
        .info-grid { grid-template-columns: repeat(2, 1fr) !important; gap: 0 !important; margin-bottom: 20px !important; border: 1px solid black !important; }
        .info-item { border: 1px solid black !important; border-radius: 0 !important; background: none !important; padding: 8px !important; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { border: 1px solid black !important; padding: 8px !important; text-align: center; }
        th { background: #f0f0f0 !important; font-weight: bold; }
        .status-badge { color: black !important; font-weight: bold !important; background: none !important; padding: 0 !important; }
    }
</style>

<div class="no-print" style="max-width: 1000px; margin: 0 auto 2rem; display: flex; justify-content: space-between; align-items: center;">
    <div>
        <h1 style="font-size: 1.5rem; font-weight: 900; color: #1e293b;">معاينة كشف الحضور</h1>
        <p style="color: #64748b; font-weight: 500;">مراجعة نهائية قبل الطباعة الرسمية</p>
    </div>
    <div style="display: flex; gap: 1rem;">
        <button onclick="window.print()" style="padding: 0.75rem 1.5rem; background: #6366f1; color: white; border: none; border-radius: 12px; font-weight: 800; cursor: pointer; display: flex; align-items: center; gap: 0.5rem;">
            <i class="fa-solid fa-print"></i> طباعة الكشف
        </button>
        <a href="{{ route('administrative.reports.index') }}" style="padding: 0.75rem 1.5rem; background: #f1f5f9; color: #64748b; text-decoration: none; border-radius: 12px; font-weight: 800;">إلغاء</a>
    </div>
</div>

<div class="report-card">
    <!-- Header -->
    <div class="report-header-premium">
        <div>
            <h2 style="font-size: 1.25rem; font-weight: 900; color: #1e293b; margin: 0;">الجمهورية اليمنية</h2>
            <p style="margin: 0.25rem 0; font-weight: 700;">جامعة {{ $subject->major->college->university->name ?? '...' }}</p>
            <p style="margin: 0; font-weight: 700;">كلية {{ $subject->major->college->name }}</p>
        </div>
        <div style="text-align: center;">
            @if(isset($subject->major->college->university->logo))
                <img src="{{ asset('storage/' . $subject->major->college->university->logo) }}" style="width: 80px; height: 80px; object-fit: contain;">
            @else
                <div style="width: 80px; height: 80px; background: #f1f5f9; border-radius: 50%; display: flex; align-items: center; justify-content: center; color: #cbd5e1; font-size: 2rem;">
                    <i class="fa-solid fa-university"></i>
                </div>
            @endif
        </div>
        <div style="text-align: left;">
            <p style="margin: 0; font-weight: 700;">التاريخ: {{ now()->format('Y/m/d') }}</p>
            <p style="margin: 0.25rem 0; font-weight: 700;">القسم: {{ $subject->major->name }}</p>
        </div>
    </div>

    <center><h1 style="font-size: 1.75rem; font-weight: 900; text-decoration: underline; margin-bottom: 2rem;">كشف حضور وغياب الطلاب</h1></center>

    <!-- Info Grid -->
    <div class="info-grid">
        <div class="info-item">
            <span class="info-label">المادة الدراسية</span>
            <span class="info-value">{{ $subject->name }}</span>
        </div>
        <div class="info-item">
            <span class="info-label">المستوى الأكاديمي</span>
            <span class="info-value">{{ $subject->level->name }}</span>
        </div>
        <div class="info-item">
            <span class="info-label">أستاذ المقرر</span>
            <span class="info-value">{{ $subject->doctor->name ?? 'غير محدد' }}</span>
        </div>
        <div class="info-item">
            <span class="info-label">الحد الأقصى للغياب</span>
            <span class="info-value" style="color: #e11d48;">{{ $subject->max_absences }} محاضرات</span>
        </div>
    </div>

    <!-- Table -->
    <table style="width: 100%; border-collapse: collapse;">
        <thead>
            <tr style="background: #f8fafc;">
                <th style="padding: 1rem; border: 1px solid #e2e8f0; text-align: center; width: 50px;">#</th>
                <th style="padding: 1rem; border: 1px solid #e2e8f0; text-align: center; width: 120px;">الرقم الجامعي</th>
                <th style="padding: 1rem; border: 1px solid #e2e8f0; text-align: right;">اسم الطالب</th>
                <th style="padding: 1rem; border: 1px solid #e2e8f0; text-align: center;">حاضر</th>
                <th style="padding: 1rem; border: 1px solid #e2e8f0; text-align: center;">غائب</th>
                <th style="padding: 1rem; border: 1px solid #e2e8f0; text-align: center;">النسبة</th>
                <th style="padding: 1rem; border: 1px solid #e2e8f0; text-align: center;">الموقف</th>
            </tr>
        </thead>
        <tbody>
            @foreach($reportData as $data)
            @php
                $isDeprived = $data['absent'] >= $subject->max_absences;
                $isWarning = !$isDeprived && ($data['absent'] >= ($subject->max_absences - 2) && $subject->max_absences > 2);
            @endphp
            <tr>
                <td style="padding: 0.75rem; border: 1px solid #e2e8f0; text-align: center;">{{ $loop->iteration }}</td>
                <td style="padding: 0.75rem; border: 1px solid #e2e8f0; text-align: center; font-family: monospace;">{{ $data['student']->student_number }}</td>
                <td style="padding: 0.75rem; border: 1px solid #e2e8f0; text-align: right;">{{ $data['student']->name }}</td>
                <td style="padding: 0.75rem; border: 1px solid #e2e8f0; text-align: center; font-weight: 700;">{{ $data['present'] }}</td>
                <td style="padding: 0.75rem; border: 1px solid #e2e8f0; text-align: center; font-weight: 700; color: {{ $data['absent'] > 0 ? '#e11d48' : '#64748b' }};">{{ $data['absent'] }}</td>
                <td style="padding: 0.75rem; border: 1px solid #e2e8f0; text-align: center;">{{ $data['absence_percentage'] }}%</td>
                <td style="padding: 0.75rem; border: 1px solid #e2e8f0; text-align: center;">
                    @if($isDeprived)
                        <span class="status-badge" style="color: #e11d48; font-weight: 900; padding: 0.25rem 0.5rem; background: #fff1f2; border-radius: 6px;">محروم</span>
                    @elseif($isWarning)
                        <span class="status-badge" style="color: #d97706; font-weight: 900; padding: 0.25rem 0.5rem; background: #fffbeb; border-radius: 6px;">إنذار</span>
                    @else
                        <span style="color: #94a3b8;">-</span>
                    @endif
                </td>
            </tr>
            @endforeach
        </tbody>
    </table>

    <!-- Signatures -->
    <div style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 2rem; margin-top: 5rem; text-align: center;">
        <div>
            <p style="font-weight: 800; margin-bottom: 3rem;">أستاذ المقرر</p>
            <div style="border-top: 1px dotted #94a3b8; width: 80%; margin: 0 auto;"></div>
        </div>
        <div>
            <p style="font-weight: 800; margin-bottom: 3rem;">رئيس القسم</p>
            <div style="border-top: 1px dotted #94a3b8; width: 80%; margin: 0 auto;"></div>
        </div>
        <div>
            <p style="font-weight: 800; margin-bottom: 3rem;">عميد الكلية / شؤون الطلاب</p>
            <div style="border-top: 1px dotted #94a3b8; width: 80%; margin: 0 auto;"></div>
        </div>
    </div>
</div>

@endsection
