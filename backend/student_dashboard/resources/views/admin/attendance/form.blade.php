@extends('layouts.admin')

@section('title', 'قائمة التحضير')

@section('content')
<div class="container" style="padding: 2rem;">
    <div style="margin-bottom: 2rem;">
        <h1>تسجيل الحضور: {{ $subject->name }}</h1>
        <p style="color: #666;">
            التاريخ: {{ $date }} |
            المستوى: {{ $subject->level->name }} |
            التخصص: {{ $subject->major->name }}
        </p>
    </div>

    @if(session('success'))
    <div style="background: #d4edda; color: #155724; padding: 1rem; border-radius: 5px; margin-bottom: 1rem;">
        {{ session('success') }}
    </div>
    @endif

    <form action="{{ route('admin.attendance.store') }}" method="POST">
        @csrf
        <input type="hidden" name="subject_id" value="{{ $subject->id }}">
        <input type="hidden" name="date" value="{{ $date }}">

        <div class="card">
            <div class="table-responsive">
<table style="width: 100%; border-collapse: collapse;">
                <thead>
                    <tr style="background: #f8f9fa; text-align: right;">
                        <th style="padding: 1rem; border-bottom: 2px solid #dee2e6;">الرقم الجامعي</th>
                        <th style="padding: 1rem; border-bottom: 2px solid #dee2e6;">اسم الطالب</th>
                        <th style="padding: 1rem; border-bottom: 2px solid #dee2e6; text-align: center;">حاضر</th>
                        <th style="padding: 1rem; border-bottom: 2px solid #dee2e6; text-align: center;">غائب</th>
                        <th style="padding: 1rem; border-bottom: 2px solid #dee2e6; text-align: center;">متأخر</th>
                        <th style="padding: 1rem; border-bottom: 2px solid #dee2e6; text-align: center;">معذور</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($students as $student)
                    @php
                    // الحالة الافتراضية 'absent' إذا لم يتم التحضير مسبقاً، وإلا الحالة المسجلة
                    $currentStatus = $attendanceRecords[$student->id]->status ?? 'absent';
                    @endphp
                    <tr>
                        <td style="padding: 1rem; border-bottom: 1px solid #dee2e6;">{{ $student->student_number }}</td>
                        <td style="padding: 1rem; border-bottom: 1px solid #dee2e6;">{{ $student->name }}</td>

                        {{-- خيارات التحضير --}}
                        <td style="padding: 1rem; border-bottom: 1px solid #dee2e6; text-align: center;">
                            <input type="radio" name="attendances[{{ $student->id }}]" value="present"
                                {{ $currentStatus == 'present' ? 'checked' : '' }}
                                style="transform: scale(1.5); cursor: pointer;">
                        </td>
                        <td style="padding: 1rem; border-bottom: 1px solid #dee2e6; text-align: center;">
                            <input type="radio" name="attendances[{{ $student->id }}]" value="absent"
                                {{ $currentStatus == 'absent' ? 'checked' : '' }}
                                style="transform: scale(1.5); cursor: pointer;">
                        </td>
                        <td style="padding: 1rem; border-bottom: 1px solid #dee2e6; text-align: center;">
                            <input type="radio" name="attendances[{{ $student->id }}]" value="late"
                                {{ $currentStatus == 'late' ? 'checked' : '' }}
                                style="transform: scale(1.5); cursor: pointer;">
                        </td>
                        <td style="padding: 1rem; border-bottom: 1px solid #dee2e6; text-align: center;">
                            <input type="radio" name="attendances[{{ $student->id }}]" value="excused"
                                {{ $currentStatus == 'excused' ? 'checked' : '' }}
                                style="transform: scale(1.5); cursor: pointer;">
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="6" style="padding: 1rem; text-align: center; color: #6c757d;">
                            لا يوجد طلاب مسجلين في هذا التخصص والمستوى ({{ $subject->major->name }} - {{ $subject->level->name }}).
                        </td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
</div>
        </div>

        @if($students->count() > 0)
        <div style="margin-top: 1rem; text-align: left;">
            <button type="submit" style="background: #28a745; color: white; border: none; padding: 0.75rem 2rem; border-radius: 4px; cursor: pointer; font-size: 1.1rem; font-weight: bold;">
                حفظ الحضور
            </button>
        </div>
        @endif
    </form>
</div>
@endsection