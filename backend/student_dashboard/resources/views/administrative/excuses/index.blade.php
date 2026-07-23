@extends('layouts.administrative')

@section('title', 'معالجة الأعذار')

@section('content')

<div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 2rem;">
    <div>
        <h1 style="font-size: 1.5rem; font-weight: 700; color: var(--text-primary);">معالجة أعذار الطلاب</h1>
        <p style="color: var(--text-secondary); margin-top: 0.5rem;">مراجعة وقبول أو رفض الأعذار المقدمة من طلاب الكلية</p>
    </div>
</div>

<!-- Quick Stats -->
<div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1.5rem; margin-bottom: 2rem;">
    <div class="card" style="display: flex; align-items: center; gap: 1rem; padding: 1.5rem;">
        <div style="width: 50px; height: 50px; border-radius: 12px; background: rgba(59, 130, 246, 0.1); color: #3b82f6; display: flex; justify-content: center; align-items: center; font-size: 1.5rem;">
            <i class="fa-solid fa-clock-rotate-left"></i>
        </div>
        <div>
            <div style="font-size: 0.85rem; color: var(--text-secondary); font-weight: 600;">بانتظار المراجعة</div>
            <div style="font-size: 1.5rem; font-weight: 800; color: var(--text-primary);">{{ $stats['pending'] }}</div>
        </div>
    </div>
    <div class="card" style="display: flex; align-items: center; gap: 1rem; padding: 1.5rem;">
        <div style="width: 50px; height: 50px; border-radius: 12px; background: #dcfce7; color: #16a34a; display: flex; justify-content: center; align-items: center; font-size: 1.5rem;">
            <i class="fa-solid fa-check"></i>
        </div>
        <div>
            <div style="font-size: 0.85rem; color: var(--text-secondary); font-weight: 600;">تم قبولها</div>
            <div style="font-size: 1.5rem; font-weight: 800; color: var(--text-primary);">{{ $stats['accepted'] }}</div>
        </div>
    </div>
    <div class="card" style="display: flex; align-items: center; gap: 1rem; padding: 1.5rem;">
        <div style="width: 50px; height: 50px; border-radius: 12px; background: #fef2f2; color: #dc2626; display: flex; justify-content: center; align-items: center; font-size: 1.5rem;">
            <i class="fa-solid fa-xmark"></i>
        </div>
        <div>
            <div style="font-size: 0.85rem; color: var(--text-secondary); font-weight: 600;">مرفوضة</div>
            <div style="font-size: 1.5rem; font-weight: 800; color: var(--text-primary);">{{ $stats['rejected'] }}</div>
        </div>
    </div>
</div>

@if($college->excuse_receiver !== 'administrative')
<div class="alert" style="background: #fffbeb; color: #b45309; border: 1px solid #fcd34d; padding: 1.5rem; border-radius: 12px; margin-bottom: 2rem; display: flex; gap: 1rem; align-items: flex-start;">
    <i class="fa-solid fa-circle-exclamation" style="font-size: 1.5rem; margin-top: 0.2rem;"></i>
    <div>
        <h4 style="font-weight: 700; margin-bottom: 0.5rem;">إعدادات الدائرة الحالية</h4>
        <p style="font-size: 0.9rem; margin-bottom: 0;">يتم حالياً توجيه الأعذار إلى ({{ $college->excuse_receiver == 'doctor' ? 'دكتور المادة' : 'المرشد الأكاديمي' }}) بناءً على إعداداتك. يمكنك عرض هذه الطلبات من هنا ولكن يُفضّل ترك قرار الموافقة للمسؤول المحدد.</p>
    </div>
</div>
@endif

<div class="card" style="margin-bottom: 2rem;">
    <form action="{{ route('administrative.excuses.index') }}" method="GET" style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1rem; align-items: flex-end;">
        <div class="form-group">
            <label style="display: block; margin-bottom: 0.5rem; font-size: 0.85rem; font-weight: 600;">الحالة</label>
            <select name="status" class="form-control" onchange="this.form.submit()">
                <option value="all" {{ request('status') == 'all' ? 'selected' : '' }}>كافة الأعذار</option>
                <option value="pending" {{ request('status') == 'pending' ? 'selected' : '' }}>قيد المراجعة</option>
                <option value="accepted" {{ request('status') == 'accepted' ? 'selected' : '' }}>تم القبول</option>
                <option value="rejected" {{ request('status') == 'rejected' ? 'selected' : '' }}>مرفوضة</option>
            </select>
        </div>
        <div class="form-group">
            <label style="display: block; margin-bottom: 0.5rem; font-size: 0.85rem; font-weight: 600;">بحث سريع</label>
            <input type="text" name="search" class="form-control" placeholder="اسم الطالب أو رقم القيد..." value="{{ request('search') }}">
        </div>
        <div>
            <button type="submit" class="btn btn-primary" style="width: 100%; background: var(--primary-color);">تصفية</button>
        </div>
    </form>
</div>

<div class="card">
    <div class="table-container">
        <div class="table-responsive">
            <table>
                <thead>
                    <tr>
                        <th>الطالب</th>
                        <th>المادة وتاريخ الغياب</th>
                        <th>سبب الغياب والمرفق</th>
                        <th>الحالة</th>
                        <th style="width: 200px; text-align: center;">القرار والإجراء</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($excuses as $excuse)
                    <tr>
                        <td>
                            <div style="font-weight: 700; color: var(--text-primary);">{{ $excuse->student->name }}</div>
                            <div style="font-size: 0.8rem; color: var(--text-secondary);">{{ $excuse->student->student_number }}</div>
                        </td>
                        <td>
                            <div style="font-weight: 600;">{{ $excuse->attendance->subject->name ?? '-' }}</div>
                            <div style="font-size: 0.85rem; color: var(--text-secondary);">{{ $excuse->attendance->date->format('Y/m/d') }}</div>
                        </td>
                        <td>
                            <div style="font-size: 0.9rem; margin-bottom: 0.5rem; max-width: 250px;">{{ Str::limit($excuse->reason, 80) }}</div>
                            @if($excuse->attachment)
                                <a href="{{ asset('storage/' . $excuse->attachment) }}" target="_blank" style="font-size: 0.8rem; display: inline-flex; align-items: center; gap: 0.25rem; color: var(--primary-color); background: rgba(var(--primary-rgb), 0.1); padding: 0.2rem 0.5rem; border-radius: 4px; text-decoration: none;">
                                    <i class="fa-solid fa-paperclip"></i> عرض المرفق
                                </a>
                            @else
                                <span style="font-size: 0.8rem; color: var(--text-light);">لا يوجد مرفقات</span>
                            @endif
                        </td>
                        <td>
                            @if($excuse->status == 'pending')
                                <span class="badge badge-warning">بانتظار المراجعة</span>
                            @elseif($excuse->status == 'accepted')
                                <span class="badge badge-success">مقبول</span>
                            @else
                                <span class="badge badge-danger">مرفوض</span>
                            @endif
                            <div style="font-size: 0.75rem; color: var(--text-light); margin-top: 0.3rem;">منذ {{ $excuse->created_at->diffForHumans() }}</div>
                        </td>
                        <td>
                            <div style="display: flex; gap: 0.5rem; flex-direction: column;">
                                @if($excuse->status == 'pending')
                                    <!-- Action Buttons open a modal to ensure adding an optional comment -->
                                    <button type="button" class="btn btn-sm" style="background: #10b981; color: white;" onclick="openActionModal({{ $excuse->id }}, 'accepted')">
                                        <i class="fa-solid fa-check"></i> قبول العذر
                                    </button>
                                    <button type="button" class="btn btn-sm" style="background: #ef4444; color: white;" onclick="openActionModal({{ $excuse->id }}, 'rejected')">
                                        <i class="fa-solid fa-xmark"></i> رفض العذر
                                    </button>
                                @else
                                    <div style="text-align: center; color: var(--text-secondary); font-size: 0.85rem;">
                                        تمت معالجته
                                    </div>
                                @endif
                            </div>
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="5" style="text-align: center; padding: 4rem; color: var(--text-secondary);">
                            لا يوجد أعذار حالياً تطابق الفلتر المجود.
                        </td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
    <div style="padding: 1.5rem; border-top: 1px solid var(--border-color);">
        {{ $excuses->withQueryString()->links() }}
    </div>
</div>

<!-- Action Modal -->
<div id="actionModal" style="display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.5); z-index: 1000; align-items: center; justify-content: center;">
    <div class="card" style="width: 100%; max-width: 500px; padding: 2rem;">
        <h3 id="modalTitle" style="font-size: 1.2rem; font-weight: 700; margin-bottom: 1.5rem; color: var(--text-primary);">تحديد حالة العذر</h3>
        
        <form id="actionForm" method="POST" action="">
            @csrf
            @method('PATCH')
            <input type="hidden" name="status" id="actionStatus">
            
            <div class="form-group" style="margin-bottom: 1.5rem;">
                <label style="display: block; margin-bottom: 0.5rem; font-weight: 600;">رد / ملاحظة للطالب (اختياري)</label>
                <textarea name="comment" class="form-control" rows="3" placeholder="أرفق ملاحظة للمتعلم بخصوص هذا العذر..."></textarea>
            </div>
            
            <div style="display: flex; justify-content: flex-end; gap: 1rem;">
                <button type="button" onclick="closeActionModal()" class="btn btn-secondary">إلغاء</button>
                <button type="submit" id="submitBtn" class="btn btn-primary">تأكيد ومتابعة</button>
            </div>
        </form>
    </div>
</div>

<script>
    function openActionModal(excuseId, status) {
        document.getElementById('actionForm').action = `/administrative/excuses/${excuseId}`;
        document.getElementById('actionStatus').value = status;
        
        const isAccept = status === 'accepted';
        document.getElementById('modalTitle').innerText = isAccept ? 'تأكيد قبول العذر' : 'تأكيد رفض العذر';
        document.getElementById('modalTitle').style.color = isAccept ? '#16a34a' : '#dc2626';
        
        const submitBtn = document.getElementById('submitBtn');
        submitBtn.style.background = isAccept ? '#10b981' : '#ef4444';
        submitBtn.style.borderColor = isAccept ? '#10b981' : '#ef4444';
        
        document.getElementById('actionModal').style.display = 'flex';
    }
    
    function closeActionModal() {
        document.getElementById('actionModal').style.display = 'none';
    }
</script>

@endsection
