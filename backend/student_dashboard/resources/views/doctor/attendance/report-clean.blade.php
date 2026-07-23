@extends('layouts.doctor')

@section('title', 'تقرير الحضور')

@section('content')
<div class="container-fluid py-4">
    <div class="d-flex justify-content-between align-items-center mb-4 gap-2 flex-wrap">
        <div>
            <h1 class="h4 mb-1">تقرير الحضور</h1>
            <p class="text-muted mb-0">{{ $subject->name }} | {{ $date }}</p>
        </div>
        <div class="d-flex gap-2">
            <a href="{{ route('doctor.attendance.create', ['subject' => $subject->id, 'date' => $date, 'lecture_id' => $lecture?->id, 'gender_filter' => $genderFilter]) }}" class="btn btn-outline-primary">فتح صفحة الرصد الكاملة</a>
            <button type="button" class="btn btn-primary" onclick="window.print()">طباعة</button>
        </div>
    </div>

    <div class="row g-3 mb-4">
        <div class="col-md-4"><div class="card border-0 shadow-sm"><div class="card-body"><div class="small text-muted">نوع المحاضرة</div><div class="fw-bold">{{ ($lecture?->lecture_type ?? 'official') === 'special' ? 'محاضرة خاصة' : 'محاضرة رسمية' }}</div></div></div></div>
        <div class="col-md-4"><div class="card border-0 shadow-sm"><div class="card-body"><div class="small text-muted">طريقة التحضير</div><div class="fw-bold">{{ ($attendanceRecords->first()?->attendance_method ?? 'manual') === 'qr' ? 'باركود QR' : 'يدوي' }}</div></div></div></div>
        <div class="col-md-4"><div class="card border-0 shadow-sm"><div class="card-body"><div class="small text-muted">تم الرصد بواسطة</div><div class="fw-bold">{{ $attendanceRecords->first()?->recorder?->name ?? 'غير محدد' }}</div></div></div></div>
    </div>

    <div class="row g-3 mb-4">
        <div class="col-md-2"><div class="card border-0 shadow-sm"><div class="card-body"><div class="small text-muted">حاضر</div><div class="fs-4 fw-bold text-success">{{ $attendanceRecords->where('status', 'present')->count() }}</div></div></div></div>
        <div class="col-md-2"><div class="card border-0 shadow-sm"><div class="card-body"><div class="small text-muted">غائب</div><div class="fs-4 fw-bold text-danger">{{ $attendanceRecords->where('status', 'absent')->count() }}</div></div></div></div>
        <div class="col-md-2"><div class="card border-0 shadow-sm"><div class="card-body"><div class="small text-muted">متأخر</div><div class="fs-4 fw-bold text-warning">{{ $attendanceRecords->where('status', 'late')->count() }}</div></div></div></div>
        <div class="col-md-2"><div class="card border-0 shadow-sm"><div class="card-body"><div class="small text-muted">بعذر</div><div class="fs-4 fw-bold text-info">{{ $attendanceRecords->where('status', 'excused')->count() }}</div></div></div></div>
        <div class="col-md-2"><div class="card border-0 shadow-sm"><div class="card-body"><div class="small text-muted">مستأذن</div><div class="fs-4 fw-bold text-primary">{{ $attendanceRecords->where('status', 'permitted')->count() }}</div></div></div></div>
        <div class="col-md-2"><div class="card border-0 shadow-sm"><div class="card-body"><div class="small text-muted">إعفاء</div><div class="fs-4 fw-bold">{{ $attendanceRecords->where('status', 'exempted')->count() }}</div></div></div></div>
    </div>

    <div class="card border-0 shadow-sm mb-4">
        <div class="card-body">
            <div class="row g-3">
                <div class="col-md-4"><div class="small text-muted">المادة</div><div class="fw-semibold">{{ $subject->name }} ({{ $subject->code }})</div></div>
                <div class="col-md-4"><div class="small text-muted">الفلتر</div><div class="fw-semibold">{{ ($genderFilter ?? 'all') === 'male' ? 'الأولاد فقط' : (($genderFilter ?? 'all') === 'female' ? 'البنات فقط' : 'الكل') }}</div></div>
                <div class="col-md-4"><div class="small text-muted">دكتور المادة</div><div class="fw-semibold">{{ $subject->doctor->name ?? 'غير محدد' }}</div></div>
            </div>
        </div>
    </div>

    <div class="card border-0 shadow-sm">
        <div class="table-responsive">
            <table class="table table-hover align-middle mb-0">
                <thead class="table-light">
                    <tr>
                        <th>#</th>
                        <th>الطالب</th>
                        <th>الجنس</th>
                        <th>الحالة الحالية</th>
                        <th>تعديل مباشر</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach($students as $index => $student)
                        @php
                            $record = $attendanceRecords->get($student->id);
                            $labels = [
                                'present' => 'حاضر',
                                'absent' => 'غائب',
                                'late' => 'متأخر',
                                'excused' => 'بعذر',
                                'permitted' => 'مستأذن',
                                'exempted' => 'إعفاء',
                            ];
                        @endphp
                        <tr>
                            <td>{{ $index + 1 }}</td>
                            <td>
                                <div class="fw-semibold">{{ $student->name }}</div>
                                <div class="small text-muted">{{ $student->student_number }}</div>
                            </td>
                            <td>{{ ($student->gender ?? 'male') === 'female' ? 'أنثى' : 'ذكر' }}</td>
                            <td>
                                @if($record)
                                    <span class="badge text-bg-secondary">{{ $labels[$record->status] ?? $record->status }}</span>
                                @else
                                    <span class="text-muted small">لا يوجد سجل</span>
                                @endif
                            </td>
                            <td style="min-width: 260px;">
                                @if($record)
                                    <form action="{{ route('doctor.attendance.records.update', $record) }}" method="POST" class="d-flex gap-2">
                                        @csrf
                                        @method('PATCH')
                                        <select name="status" class="form-select form-select-sm">
                                            @foreach(\App\Support\ExcuseWorkflow::editableAttendanceStatuses() as $status)
                                                <option value="{{ $status }}" @selected($record->status === $status)>{{ $labels[$status] ?? $status }}</option>
                                            @endforeach
                                        </select>
                                        <button class="btn btn-sm btn-primary">حفظ</button>
                                    </form>
                                @else
                                    <span class="text-muted small">يُعدل من صفحة الرصد الكاملة</span>
                                @endif
                            </td>
                        </tr>
                    @endforeach
                </tbody>
            </table>
        </div>
    </div>
</div>
@endsection
