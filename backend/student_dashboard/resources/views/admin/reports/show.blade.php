@extends('layouts.admin')

@section('title', 'تقرير الحضور: ' . $subject->name)

@section('content')
<div class="container" style="padding: 2rem;">
    <div style="margin-bottom: 2rem; display: flex; justify-content: space-between; align-items: start;">
        <div>
            <h1>تقرير الحضور: {{ $subject->name }}</h1>
            <p style="color: #666; margin-top: 5px;">
                المستوى: {{ $subject->level->name }} |
                التخصص: {{ $subject->major->name }} |
                الدكتور: {{ $subject->doctor->name ?? 'غير محدد' }}
            </p>
        </div>
        <div>
            <a href="{{ route('admin.reports.index') }}" style="background: #6c757d; color: white; padding: 0.5rem 1rem; text-decoration: none; border-radius: 4px;">عودة</a>
        </div>
    </div>

    <div class="card">
        <div class="table-responsive">
<table style="width: 100%; border-collapse: collapse;">
            <thead>
                <tr style="background: #f8f9fa; text-align: right;">
                    <th style="padding: 1rem; border-bottom: 2px solid #dee2e6;">الرقم الجامعي</th>
                    <th style="padding: 1rem; border-bottom: 2px solid #dee2e6;">اسم الطالب</th>
                    <th style="padding: 1rem; border-bottom: 2px solid #dee2e6; text-align: center;">عدد الحضور</th>
                    <th style="padding: 1rem; border-bottom: 2px solid #dee2e6; text-align: center;">عدد الغياب</th>
                    <th style="padding: 1rem; border-bottom: 2px solid #dee2e6; text-align: center;">تأخير / عذر</th>
                    <th style="padding: 1rem; border-bottom: 2px solid #dee2e6; text-align: center;">نسبة الغياب</th>
                    <th style="padding: 1rem; border-bottom: 2px solid #dee2e6; text-align: center;">الحالة</th>
                </tr>
            </thead>
            <tbody>
                @forelse($reportData as $data)
                <tr>
                    <td style="padding: 1rem; border-bottom: 1px solid #dee2e6; font-family: monospace;">{{ $data['student']->student_number }}</td>
                    <td style="padding: 1rem; border-bottom: 1px solid #dee2e6;">{{ $data['student']->name }}</td>
                    <td style="padding: 1rem; border-bottom: 1px solid #dee2e6; text-align: center; color: #28a745; font-weight: bold;">
                        {{ $data['present'] }}
                    </td>
                    <td style="padding: 1rem; border-bottom: 1px solid #dee2e6; text-align: center; color: #dc3545; font-weight: bold;">
                        {{ $data['absent'] }}
                    </td>
                    <td style="padding: 1rem; border-bottom: 1px solid #dee2e6; text-align: center;">
                        <span style="color: #fd7e14;">{{ $data['late'] }}</span> / <span style="color: #17a2b8;">{{ $data['excused'] }}</span>
                    </td>
                    <td style="padding: 1rem; border-bottom: 1px solid #dee2e6; text-align: center;">
                        %{{ $data['absence_percentage'] }}
                    </td>
                    <td style="padding: 1rem; border-bottom: 1px solid #dee2e6; text-align: center;">
                        @if($data['absence_percentage'] >= 25)
                        <span style="background: #dc3545; color: white; padding: 2px 8px; border-radius: 10px; font-size: 0.8em;">محروم</span>
                        @elseif($data['absence_percentage'] >= 15)
                        <span style="background: #ffc107; color: black; padding: 2px 8px; border-radius: 10px; font-size: 0.8em;">إنذار</span>
                        @else
                        <span style="background: #28a745; color: white; padding: 2px 8px; border-radius: 10px; font-size: 0.8em;">منتظم</span>
                        @endif
                    </td>
                </tr>
                @empty
                <tr>
                    <td colspan="7" style="padding: 1rem; text-align: center; color: #6c757d;">لا يوجد بيانات لعرضها.</td>
                </tr>
                @endforelse
            </tbody>
        </table>
</div>

        <div style="padding: 1rem; color: #666; font-size: 0.9em;">
            * إجمالي عدد المحاضرات المسجلة لهذه المادة: {{ $reportData->first()['total_sessions'] ?? 0 }}
        </div>
    </div>
</div>
@endsection