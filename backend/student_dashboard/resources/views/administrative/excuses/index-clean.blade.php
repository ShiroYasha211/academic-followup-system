@extends('layouts.administrative')

@section('title', 'إدارة الأعذار')

@section('content')
@php
    $canReview = ($college->excuse_receiver ?? 'administrative') === 'administrative';
@endphp

<div class="container-fluid py-4">
    <div class="mb-4">
        <h1 class="h4 mb-1">إدارة الأعذار</h1>
        <p class="text-muted mb-0">متابعة أعذار الطلاب وقرار المعالجة النهائي لها.</p>
    </div>

    @if(!$canReview)
        <div class="alert alert-warning">
            الأعذار الجديدة موجهة إلى دكتور المادة. هذه الصفحة للمتابعة فقط إلى أن يعود المسار إلى المسؤول الإداري.
        </div>
    @endif

    <div class="row g-3 mb-4">
        <div class="col-md-3"><div class="card border-0 shadow-sm"><div class="card-body"><div class="small text-muted">قيد المراجعة</div><div class="fs-3 fw-bold">{{ $stats['pending'] }}</div></div></div></div>
        <div class="col-md-3"><div class="card border-0 shadow-sm"><div class="card-body"><div class="small text-muted">مقبول</div><div class="fs-3 fw-bold text-success">{{ $stats['accepted'] }}</div></div></div></div>
        <div class="col-md-3"><div class="card border-0 shadow-sm"><div class="card-body"><div class="small text-muted">مرفوض</div><div class="fs-3 fw-bold text-danger">{{ $stats['rejected'] }}</div></div></div></div>
        <div class="col-md-3"><div class="card border-0 shadow-sm"><div class="card-body"><div class="small text-muted">الإجمالي</div><div class="fs-3 fw-bold">{{ $stats['all'] }}</div></div></div></div>
    </div>

    <div class="card border-0 shadow-sm mb-4">
        <div class="card-body">
            <form method="GET" class="row g-3">
                <div class="col-md-3">
                    <label class="form-label">الحالة</label>
                    <select name="status" class="form-select">
                        <option value="pending" @selected(request('status', 'pending') === 'pending')>قيد المراجعة</option>
                        <option value="accepted" @selected(request('status') === 'accepted')>مقبول</option>
                        <option value="rejected" @selected(request('status') === 'rejected')>مرفوض</option>
                        <option value="all" @selected(request('status') === 'all')>الكل</option>
                    </select>
                </div>
                <div class="col-md-5">
                    <label class="form-label">بحث</label>
                    <input type="text" name="search" class="form-control" value="{{ request('search') }}" placeholder="اسم الطالب أو الرقم الجامعي">
                </div>
                <div class="col-md-4 d-flex align-items-end gap-2">
                    <button class="btn btn-primary">تطبيق</button>
                    <a href="{{ route('administrative.excuses.index') }}" class="btn btn-light">إعادة ضبط</a>
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
                        <th>المادة والتاريخ</th>
                        <th>العذر</th>
                        <th>المسار</th>
                        <th>القرار</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($excuses as $excuse)
                        <tr>
                            <td>
                                <div class="fw-semibold">{{ $excuse->student->name }}</div>
                                <div class="small text-muted">{{ $excuse->student->student_number }}</div>
                            </td>
                            <td>
                                <div class="fw-semibold">{{ $excuse->attendance->subject->name ?? '-' }}</div>
                                <div class="small text-muted">{{ optional($excuse->attendance->date)->format('Y-m-d') }}</div>
                            </td>
                            <td style="min-width:260px">
                                <div>{{ $excuse->reason }}</div>
                                @foreach($excuse->allAttachments() as $file)
                                    <div>
                                        <a href="{{ $file->file_url }}" target="_blank" class="small">عرض المرفق{{ $loop->count > 1 ? ' #' . $loop->iteration : '' }}</a>
                                    </div>
                                @endforeach
                            </td>
                            <td>
                                <span class="badge text-bg-secondary">{{ $excuse->receiver_type === 'doctor' ? 'دكتور المادة' : 'الإدارة' }}</span>
                                @if($excuse->reviewer)
                                    <div class="small text-muted mt-1">آخر معالج: {{ $excuse->reviewer->name }}</div>
                                @endif
                            </td>
                            <td style="min-width:320px">
                                @if($excuse->status !== 'pending')
                                    <div class="mb-2">
                                        <span class="badge {{ $excuse->status === 'accepted' ? 'text-bg-success' : 'text-bg-danger' }}">
                                            {{ $excuse->status === 'accepted' ? 'مقبول' : 'مرفوض' }}
                                        </span>
                                        @if($excuse->resolution)
                                            <span class="badge text-bg-info">{{ \App\Support\ExcuseWorkflow::resolutionLabel($excuse->resolution) }}</span>
                                        @endif
                                    </div>
                                    @if($excuse->doctor_comment)
                                        <div class="small text-muted">{{ $excuse->doctor_comment }}</div>
                                    @endif
                                @elseif($canReview)
                                    <form action="{{ route('administrative.excuses.update', $excuse) }}" method="POST" class="d-grid gap-2">
                                        @csrf
                                        @method('PATCH')
                                        <select name="status" class="form-select">
                                            <option value="accepted">قبول</option>
                                            <option value="rejected">رفض</option>
                                        </select>
                                        <select name="resolution" class="form-select">
                                            <option value="">اختر نتيجة المعالجة عند القبول</option>
                                            <option value="excused_permission">مستأذن</option>
                                            <option value="excused_exemption">إعفاء</option>
                                            <option value="keep_absent">يبقى غائب</option>
                                        </select>
                                        <textarea name="comment" class="form-control" rows="2" placeholder="ملاحظة للطالب"></textarea>
                                        <button class="btn btn-primary btn-sm">حفظ القرار</button>
                                    </form>
                                @else
                                    <span class="text-muted small">متابعة فقط. القرار النهائي عند الدكتور.</span>
                                @endif
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="5" class="text-center py-5 text-muted">لا توجد أعذار مطابقة للفلاتر الحالية.</td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
        <div class="card-body border-top">
            {{ $excuses->withQueryString()->links() }}
        </div>
    </div>
</div>
@endsection
