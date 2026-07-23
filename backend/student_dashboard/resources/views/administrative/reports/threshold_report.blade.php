@extends('layouts.administrative')

@section('title', 'تقرير الحرمان والإنذار')

@section('content')

<style>
    @media screen {
        .report-premium {
            background: white;
            border-radius: 24px;
            padding: 2.5rem;
            box-shadow: 0 10px 30px rgba(0,0,0,0.05);
            max-width: 1000px;
            margin: 0 auto;
            border: 1px solid #e2e8f0;
        }
        .report-header-flex {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            margin-bottom: 2.5rem;
            padding-bottom: 1.5rem;
            border-bottom: 1px solid #f1f5f9;
        }
    }

    @media print {
        @page { size: A4; margin: 1.5cm; }
        body { background: white !important; font-family: 'Times New Roman', serif; }
        .no-print { display: none !important; }
        .report-premium { border: none !important; box-shadow: none !important; padding: 0 !important; max-width: 100% !important; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { border: 1px solid black !important; padding: 8px !important; text-align: center; }
        th { background: #f0f0f0 !important; font-weight: bold; }
    }
</style>

<div class="no-print" style="max-width: 1000px; margin: 0 auto 2rem; display: flex; justify-content: space-between; align-items: center;">
    <div>
        <h1 style="font-size: 1.5rem; font-weight: 900; color: #1e293b;">كشف حالات تجاوز الغياب</h1>
        <p style="color: #64748b; font-weight: 500;">المستوى: {{ $level->name }} | العتبة: {{ $threshold }}%</p>
    </div>
    <div style="display: flex; gap: 1rem;">
        <button onclick="window.print()" style="padding: 0.75rem 1.5rem; background: #ef4444; color: white; border: none; border-radius: 12px; font-weight: 800; cursor: pointer;">
            <i class="fa-solid fa-print"></i> طباعة القائمة
        </button>
        <a href="{{ route('administrative.reports.index') }}" style="padding: 0.75rem 1.5rem; background: #f1f5f9; color: #64748b; text-decoration: none; border-radius: 12px; font-weight: 800;">رجوع</a>
    </div>
</div>

<div class="report-premium">
    <div class="report-header-flex">
        <div style="text-align: right;">
            <h2 style="font-size: 1.1rem; font-weight: 900; margin: 0;">كشف الطلاب المتجاوزين لنسبة الغياب</h2>
            <p style="margin: 0.25rem 0; color: #64748b; font-weight: 700;">القسم: {{ $level->major->name }}</p>
            <p style="margin: 0; color: #64748b; font-weight: 700;">المستوى: {{ $level->name }}</p>
        </div>
        <div style="text-align: left;">
            <p style="margin: 0; font-weight: 700;">عدد الحالات: {{ count($alertData) }}</p>
            <p style="margin: 0.25rem 0; font-weight: 700;">التاريخ: {{ now()->format('Y/m/d') }}</p>
        </div>
    </div>

    <table style="width: 100%; border-collapse: collapse;">
        <thead>
            <tr style="background: #f8fafc;">
                <th style="padding: 1rem; border: 1px solid #e2e8f0; width: 50px;">#</th>
                <th style="padding: 1rem; border: 1px solid #e2e8f0; text-align: right;">اسم الطالب</th>
                <th style="padding: 1rem; border: 1px solid #e2e8f0; text-align: right;">المادة</th>
                <th style="padding: 1rem; border: 1px solid #e2e8f0; text-align: center;">الغيابات</th>
                <th style="padding: 1rem; border: 1px solid #e2e8f0; text-align: center;">النسبة</th>
                <th style="padding: 1rem; border: 1px solid #e2e8f0; text-align: center;">الإجراء</th>
            </tr>
        </thead>
        <tbody>
            @forelse($alertData as $data)
            <tr>
                <td style="padding: 0.8rem; border: 1px solid #e2e8f0; text-align: center;">{{ $loop->iteration }}</td>
                <td style="padding: 0.8rem; border: 1px solid #e2e8f0; text-align: right; font-weight: 800;">{{ $data['student']->name }}</td>
                <td style="padding: 0.8rem; border: 1px solid #e2e8f0; text-align: right;">{{ $data['subject']->name }}</td>
                <td style="padding: 0.8rem; border: 1px solid #e2e8f0; text-align: center; font-weight: 900; color: #e11d48;">{{ $data['absent_count'] }}</td>
                <td style="padding: 0.8rem; border: 1px solid #e2e8f0; text-align: center; font-weight: 900; color: #e11d48;">{{ $data['absence_percentage'] }}%</td>
                <td style="padding: 0.8rem; border: 1px solid #e2e8f0; text-align: center;">
                    @if($data['absence_percentage'] >= 25)
                        <span style="color: #991b1b; font-weight: 900; background: #fef2f2; padding: 0.2rem 0.6rem; border-radius: 6px;">حرمان</span>
                    @else
                        <span style="color: #92400e; font-weight: 900; background: #fffbeb; padding: 0.2rem 0.6rem; border-radius: 6px;">إنذار</span>
                    @endif
                </td>
            </tr>
            @empty
            <tr>
                <td colspan="6" style="padding: 3rem; text-align: center; color: #94a3b8; font-weight: 700;">لا توجد حالات تجاوزت الحد المسموح به في هذا القسم.</td>
            </tr>
            @endforelse
        </tbody>
    </table>

    <div style="margin-top: 4rem; display: grid; grid-template-columns: 1fr 1fr; gap: 4rem; text-align: center;">
        <div>
            <p style="font-weight: 800; margin-bottom: 3rem;">مسؤول شئون الطلاب</p>
            <div style="border-top: 1px solid #000; width: 150px; margin: 0 auto;"></div>
        </div>
        <div>
            <p style="font-weight: 800; margin-bottom: 3rem;">رئيس القسم / العميد</p>
            <div style="border-top: 1px solid #000; width: 150px; margin: 0 auto;"></div>
        </div>
    </div>
</div>

@endsection
