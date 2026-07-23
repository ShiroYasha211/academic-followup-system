@extends('layouts.doctor')

@section('title', 'رصد الحضور')

@section('content')
<div class="container" style="max-width: 100%;" x-data="{ activeTab: 'subjects' }">
    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 2rem; gap: 1rem; flex-wrap: wrap;">
        <div>
            <h1 style="font-size: 1.5rem; font-weight: 700; color: var(--text-primary); margin-bottom: 0.5rem;">رصد الحضور</h1>
            <p style="color: var(--text-secondary); margin: 0;">إدارة جلسات التحضير وفتح تقارير الحضور لكل مادة.</p>
        </div>
    </div>

    @if(session('success'))
        <div class="alert alert-success" style="margin-bottom: 1.5rem;">{{ session('success') }}</div>
    @endif

    <div style="display: flex; gap: 0; margin-bottom: 0; border-bottom: 2px solid #e2e8f0;">
        <button @click="activeTab = 'subjects'" :class="activeTab === 'subjects' ? 'tab-active' : 'tab-inactive'">رصد الحضور</button>
        <button @click="activeTab = 'reports'" :class="activeTab === 'reports' ? 'tab-active' : 'tab-inactive'">التقارير</button>
    </div>

    <div x-show="activeTab === 'subjects'" style="margin-top: 1.5rem;">
        @if($subjects->isEmpty())
            <div class="card" style="text-align: center; padding: 4rem 2rem;">
                <h3 style="font-size: 1.1rem; font-weight: 700; color: var(--text-primary);">لا توجد مواد مسندة لك</h3>
                <p style="color: var(--text-secondary); margin: 0;">ستظهر المواد هنا بعد ربطك بالمقررات الدراسية.</p>
            </div>
        @else
            <div class="card" style="padding: 0; overflow: hidden;">
                <div class="table-container">
                    <div class="table-responsive">
                        <table style="width: 100%; border-collapse: separate; border-spacing: 0;">
                            <thead>
                                <tr style="background: linear-gradient(135deg, #f8fafc, #f1f5f9); text-align: right;">
                                    <th style="padding: 1rem 1.25rem; border-bottom: 2px solid #e2e8f0;">#</th>
                                    <th style="padding: 1rem 1.25rem; border-bottom: 2px solid #e2e8f0;">المادة</th>
                                    <th style="padding: 1rem 1.25rem; border-bottom: 2px solid #e2e8f0;">التخصص / المستوى</th>
                                    <th style="padding: 1rem 1.25rem; border-bottom: 2px solid #e2e8f0;">صلاحية المندوب</th>
                                    <th style="padding: 1rem 1.25rem; border-bottom: 2px solid #e2e8f0; text-align: center;">الإجراءات</th>
                                </tr>
                            </thead>
                            <tbody>
                                @foreach($subjects as $index => $subject)
                                    <tr style="transition: background 0.15s;" onmouseover="this.style.background='#f8fafc'" onmouseout="this.style.background='white'">
                                        <td style="padding: 1rem 1.25rem; border-bottom: 1px solid #f1f5f9; color: #94a3b8;">{{ $index + 1 }}</td>
                                        <td style="padding: 1rem 1.25rem; border-bottom: 1px solid #f1f5f9;">
                                            <div style="font-weight: 700; color: var(--text-primary);">{{ $subject->name }}</div>
                                            <div style="font-size: 0.85rem; color: var(--text-secondary);">{{ $subject->code }}</div>
                                        </td>
                                        <td style="padding: 1rem 1.25rem; border-bottom: 1px solid #f1f5f9;">
                                            <div style="font-weight: 600; color: var(--text-primary);">{{ $subject->major->name ?? '-' }}</div>
                                            <div style="font-size: 0.85rem; color: var(--text-secondary);">{{ $subject->level->name ?? '-' }}</div>
                                        </td>
                                        <td style="padding: 1rem 1.25rem; border-bottom: 1px solid #f1f5f9;">
                                            @if($subject->allow_delegate_attendance)
                                                <span class="badge badge-success">مفعلة</span>
                                            @else
                                                <span class="badge badge-danger">موقفة</span>
                                            @endif
                                        </td>
                                        <td style="padding: 1rem 1.25rem; border-bottom: 1px solid #f1f5f9; text-align: center;">
                                            <div style="display: inline-flex; gap: 0.5rem; flex-wrap: wrap; justify-content: center;">
                                                <a href="{{ route('doctor.attendance.create', $subject->id) }}" class="btn btn-primary btn-sm">بدء الرصد</a>
                                                <form action="{{ route('doctor.attendance.toggle-delegate', $subject->id) }}" method="POST" style="display: inline;">
                                                    @csrf
                                                    <button type="submit" class="btn btn-secondary btn-sm">
                                                        {{ $subject->allow_delegate_attendance ? 'إيقاف المندوب' : 'تفعيل المندوب' }}
                                                    </button>
                                                </form>
                                            </div>
                                        </td>
                                    </tr>
                                @endforeach
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        @endif
    </div>

    <div x-show="activeTab === 'reports'" style="margin-top: 1.5rem;">
        <div class="card">
            @if($sessions->isEmpty())
                <div style="text-align: center; padding: 4rem 2rem;">
                    <h3 style="font-size: 1.1rem; font-weight: 700; color: var(--text-primary);">لا توجد تقارير حضور بعد</h3>
                    <p style="color: var(--text-secondary); margin: 0;">بعد حفظ أي جلسة حضور ستظهر التقارير هنا.</p>
                </div>
            @else
                <div class="table-container">
                    <div class="table-responsive">
                        <table style="width: 100%; border-collapse: separate; border-spacing: 0;">
                            <thead>
                                <tr style="background: linear-gradient(135deg, #f8fafc, #f1f5f9); text-align: right;">
                                    <th style="padding: 1rem; border-bottom: 2px solid #e2e8f0;">المادة</th>
                                    <th style="padding: 1rem; border-bottom: 2px solid #e2e8f0;">المحاضرة</th>
                                    <th style="padding: 1rem; border-bottom: 2px solid #e2e8f0;">التاريخ</th>
                                    <th style="padding: 1rem; border-bottom: 2px solid #e2e8f0;">الطريقة</th>
                                    <th style="padding: 1rem; border-bottom: 2px solid #e2e8f0;">الرصد بواسطة</th>
                                    <th style="padding: 1rem; border-bottom: 2px solid #e2e8f0;">عدد الطلاب</th>
                                    <th style="padding: 1rem; border-bottom: 2px solid #e2e8f0; text-align: center;">الإجراءات</th>
                                </tr>
                            </thead>
                            <tbody>
                                @foreach($sessions as $session)
                                    <tr style="transition: background 0.15s;" onmouseover="this.style.background='#f8fafc'" onmouseout="this.style.background='white'">
                                        <td style="padding: 1rem; border-bottom: 1px solid #f1f5f9;">
                                            <div style="font-weight: 700; color: var(--text-primary);">{{ $session->subject->name }}</div>
                                            <div style="font-size: 0.85rem; color: var(--text-secondary);">{{ $session->subject->code }}</div>
                                        </td>
                                        <td style="padding: 1rem; border-bottom: 1px solid #f1f5f9;">
                                            <div style="font-weight: 600; color: var(--text-primary);">{{ $session->lecture?->title ?? 'محاضرة غير محددة' }}</div>
                                            <div style="font-size: 0.85rem; color: var(--text-secondary);">{{ ($session->lecture?->lecture_type ?? 'official') === 'special' ? 'محاضرة خاصة' : 'محاضرة رسمية' }}</div>
                                        </td>
                                        <td style="padding: 1rem; border-bottom: 1px solid #f1f5f9;">{{ $session->date->format('Y-m-d') }}</td>
                                        <td style="padding: 1rem; border-bottom: 1px solid #f1f5f9;">{{ ($session->attendance_method ?? 'manual') === 'qr' ? 'باركود QR' : 'يدوي' }}</td>
                                        <td style="padding: 1rem; border-bottom: 1px solid #f1f5f9;">{{ $session->recorder?->name ?? 'غير محدد' }}</td>
                                        <td style="padding: 1rem; border-bottom: 1px solid #f1f5f9;"><span class="badge badge-info">{{ $session->total_records }} طالب</span></td>
                                        <td style="padding: 1rem; border-bottom: 1px solid #f1f5f9; text-align: center;">
                                            <div style="display: inline-flex; gap: 0.5rem; flex-wrap: wrap; justify-content: center;">
                                                <a href="{{ route('doctor.attendance.create', $session->subject_id) }}?date={{ $session->date->format('Y-m-d') }}&lecture_id={{ $session->lecture_id }}" class="btn btn-secondary btn-sm">تعديل</a>
                                                <a href="{{ route('doctor.attendance.report', ['subject' => $session->subject_id, 'date' => $session->date->format('Y-m-d'), 'lecture_id' => $session->lecture_id]) }}" class="btn btn-primary btn-sm" target="_blank">التقرير</a>
                                            </div>
                                        </td>
                                    </tr>
                                @endforeach
                            </tbody>
                        </table>
                    </div>
                </div>

                @if($sessions->hasPages())
                    <div style="border-top: 1px solid var(--border-color); padding: 1rem;">
                        {{ $sessions->links() }}
                    </div>
                @endif
            @endif
        </div>
    </div>
</div>
@endsection
