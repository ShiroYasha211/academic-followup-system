@extends('layouts.administrative')

@section('title', 'تقارير الحضور')

@section('content')
<div class="container-fluid py-4">
    <div class="mb-4">
        <h1 class="h4 mb-1">تقارير الحضور</h1>
        <p class="text-muted mb-0">متابعة حالات الحضور مع تعديل مباشر لسجلات الكلية.</p>
    </div>

    <div class="row g-3 mb-4">
        <div class="col-md-2"><div class="card border-0 shadow-sm"><div class="card-body"><div class="small text-muted">حاضر اليوم</div><div class="fs-4 fw-bold text-success">{{ $stats['present'] }}</div></div></div></div>
        <div class="col-md-2"><div class="card border-0 shadow-sm"><div class="card-body"><div class="small text-muted">غائب اليوم</div><div class="fs-4 fw-bold text-danger">{{ $stats['absent'] }}</div></div></div></div>
        <div class="col-md-2"><div class="card border-0 shadow-sm"><div class="card-body"><div class="small text-muted">بعذر/مقبول</div><div class="fs-4 fw-bold text-info">{{ $stats['excused'] }}</div></div></div></div>
        <div class="col-md-2"><div class="card border-0 shadow-sm"><div class="card-body"><div class="small text-muted">مستأذن</div><div class="fs-4 fw-bold">{{ $stats['permitted'] ?? 0 }}</div></div></div></div>
        <div class="col-md-2"><div class="card border-0 shadow-sm"><div class="card-body"><div class="small text-muted">إعفاء</div><div class="fs-4 fw-bold">{{ $stats['exempted'] ?? 0 }}</div></div></div></div>
        <div class="col-md-2"><div class="card border-0 shadow-sm"><div class="card-body"><div class="small text-muted">جلسات QR النشطة</div><div class="fs-4 fw-bold">{{ $stats['active_sessions'] }}</div></div></div></div>
    </div>

    <div class="card border-0 shadow-sm mb-4">
        <div class="card-body">
            <form method="GET" class="row g-3">
                <div class="col-md-3">
                    <label class="form-label">التخصص</label>
                    <select name="major_id" class="form-select">
                        <option value="">كل التخصصات</option>
                        @foreach($majors as $major)
                            <option value="{{ $major->id }}" @selected(request('major_id') == $major->id)>{{ $major->name }}</option>
                        @endforeach
                    </select>
                </div>
                <div class="col-md-3">
                    <label class="form-label">من تاريخ</label>
                    <input type="date" name="date_start" class="form-control" value="{{ request('date_start') }}">
                </div>
                <div class="col-md-3">
                    <label class="form-label">إلى تاريخ</label>
                    <input type="date" name="date_end" class="form-control" value="{{ request('date_end') }}">
                </div>
                <div class="col-md-3">
                    <label class="form-label">بحث</label>
                    <input type="text" name="search" class="form-control" value="{{ request('search') }}" placeholder="اسم الطالب أو المادة">
                </div>
                <div class="col-12 d-flex gap-2">
                    <button class="btn btn-primary">تطبيق</button>
                    <a href="{{ route('administrative.reports.attendance') }}" class="btn btn-light">إعادة ضبط</a>
                </div>
            </form>
        </div>
    </div>

    <div class="card border-0 shadow-sm">
        <div class="table-responsive">
            <table class="table table-hover align-middle mb-0">
                <thead class="table-light">
                    <tr>
                        <th>الطالب</th>
                        <th>المادة</th>
                        <th>التاريخ</th>
                        <th>الحالة</th>
                        <th>تعديل مباشر</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($auditLogs as $log)
                        <tr>
                            <td>
                                <div class="fw-semibold">{{ $log->student->name }}</div>
                                <div class="small text-muted">{{ $log->student->student_number }}</div>
                            </td>
                            <td>{{ $log->subject->name }}</td>
                            <td>{{ optional($log->date)->format('Y-m-d') }}</td>
                            <td>
                                <span class="badge text-bg-secondary">{{ \App\Support\ExcuseWorkflow::attendanceStatusLabel($log->status) }}</span>
                                @if($log->excuse && $log->excuse->resolution)
                                    <div class="small text-muted mt-1">{{ \App\Support\ExcuseWorkflow::resolutionLabel($log->excuse->resolution) }}</div>
                                @endif
                            </td>
                            <td style="min-width:260px">
                                <form action="{{ route('administrative.attendance.update', $log) }}" method="POST" class="d-flex gap-2">
                                    @csrf
                                    @method('PATCH')
                                    <select name="status" class="form-select form-select-sm">
                                        @foreach(\App\Support\ExcuseWorkflow::editableAttendanceStatuses() as $status)
                                            <option value="{{ $status }}" @selected($log->status === $status)>{{ \App\Support\ExcuseWorkflow::attendanceStatusLabel($status) }}</option>
                                        @endforeach
                                    </select>
                                    <button class="btn btn-sm btn-primary">حفظ</button>
                                </form>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="5" class="text-center py-5 text-muted">لا توجد سجلات حضور مطابقة للفلاتر الحالية.</td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
        <div class="card-body border-top">
            {{ $auditLogs->links() }}
        </div>
    </div>
</div>
@endsection
