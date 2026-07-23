@extends('layouts.admin')

@section('title', 'تفاصيل نقل المندوبية')

@section('content')
<div style="margin-bottom: 2rem; display: flex; align-items: center; justify-content: space-between;">
    <div>
        <h1 style="font-size: 1.5rem; font-weight: 700; color: var(--text-primary);">نقل المندوبية</h1>
        <p style="color: var(--text-secondary); margin-top: 0.5rem;">
            {{ $major->name }} - {{ $level->name }}
        </p>
    </div>
    <a href="{{ route('admin.delegates.transfer.index') }}" class="btn" style="background: #f1f5f9; color: #64748b; padding: 0.75rem 1.25rem; border-radius: 10px; text-decoration: none; font-weight: 600; display: flex; align-items: center; gap: 0.5rem;">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <line x1="19" y1="12" x2="5" y2="12"></line>
            <polyline points="12 19 5 12 12 5"></polyline>
        </svg>
        رجوع للكل
    </a>
</div>

<form action="{{ route('admin.delegates.transfer.perform') }}" method="POST" onsubmit="return confirm('هل أنت متأكد من إتمام عملية النقل؟ سيتم تبديل كافة الصلاحيات فوراً.')">
    @csrf
    <input type="hidden" name="old_delegate_id" value="{{ $currentDelegate->id }}">
    <input type="hidden" name="major_id" value="{{ $major->id }}">
    <input type="hidden" name="level_id" value="{{ $level->id }}">

    <div style="display: grid; grid-template-columns: 1fr 80px 1fr; gap: 2rem; align-items: center;">
        
        <!-- Current Delegate (Right) -->
        <div class="card" style="padding: 2rem; border-radius: 24px; text-align: center; border: 2px solid #f1f5f9; background: #fff;">
            <div style="font-size: 0.85rem; color: #ef4444; font-weight: 800; background: #fef2f2; padding: 0.35rem 0.75rem; border-radius: 20px; display: inline-block; margin-bottom: 1.5rem;">المندوب الحالي</div>
            
            <div style="width: 100px; height: 100px; border-radius: 50%; background: var(--primary-color); color: white; display: flex; align-items: center; justify-content: center; font-weight: 800; font-size: 2.5rem; margin: 0 auto 1.5rem;">
                {{ mb_substr($currentDelegate->name, 0, 1) }}
            </div>
            
            <h3 style="font-size: 1.35rem; font-weight: 800; color: var(--text-primary); margin-bottom: 0.5rem;">{{ $currentDelegate->name }}</h3>
            <p style="color: var(--text-secondary); margin-bottom: 1.5rem;">{{ $currentDelegate->email }}</p>
            
            <div style="padding: 1rem; background: #f8fafc; border-radius: 15px; font-size: 0.9rem; color: var(--text-secondary);">
                سيتحول هذا الحساب إلى **طالب** بعد إتمام العملية
            </div>
        </div>

        <!-- Arrow / Transfer Icon -->
        <div style="text-align: center;">
            <div style="width: 60px; height: 60px; border-radius: 50%; background: #f0fdf4; color: #22c55e; display: flex; align-items: center; justify-content: center; margin: 0 auto; box-shadow: 0 4px 12px rgba(34, 197, 94, 0.1);">
                <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                    <polyline points="7 13 12 18 17 13"></polyline>
                    <polyline points="7 6 12 11 17 6"></polyline>
                </svg>
            </div>
        </div>

        <!-- New Delegate Selection (Left) -->
        <div class="card" style="padding: 2rem; border-radius: 24px; text-align: center; border: 2px dashed var(--primary-color); background: #f5f3ff;">
            <div style="font-size: 0.85rem; color: var(--primary-color); font-weight: 800; background: rgba(79, 70, 229, 0.1); padding: 0.35rem 0.75rem; border-radius: 20px; display: inline-block; margin-bottom: 1.5rem;">اختيار المندوب الجديد</div>
            
            <div x-data="{ selectedUser: '' }">
                <div style="margin-bottom: 2rem;">
                    <select name="new_delegate_id" required x-model="selectedUser" style="width: 100%; padding: 1rem; border: 1.5px solid #ddd; border-radius: 15px; font-size: 1rem; background: white; outline: none; cursor: pointer;">
                        <option value="">-- اختر طالباً من الدفعة --</option>
                        @foreach($eligibleStudents as $student)
                            <option value="{{ $student->id }}">{{ $student->name }} ({{ $student->student_number ?? 'بدون رقم' }})</option>
                        @endforeach
                    </select>
                </div>

                <div x-show="selectedUser" style="padding: 1rem; background: #fff; border-radius: 15px; border: 1px solid rgba(79, 70, 229, 0.2); transition: all 0.3s ease;">
                    <div style="font-size: 0.9rem; color: var(--primary-color); font-weight: 700;">
                        سيتم منح صلاحيات المندوب لهذا الطالب ونقل "عهدة" الملفات إليه.
                    </div>
                </div>
                
                <div x-show="!selectedUser" style="color: var(--text-secondary); font-size: 0.9rem;">
                    اختر طالباً من القائمة أعلاه للمتابعة
                </div>
            </div>
        </div>
    </div>

    <!-- Final Action -->
    <div style="margin-top: 3rem; text-align: center;">
        <button type="submit" class="btn" style="background: linear-gradient(135deg, var(--primary-color), #4338ca); color: white; padding: 1.25rem 3rem; border-radius: 18px; font-size: 1.15rem; font-weight: 700; border: none; cursor: pointer; display: inline-flex; align-items: center; gap: 0.75rem; box-shadow: 0 10px 20px rgba(67, 56, 202, 0.2);">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
                <polyline points="22 4 12 14.01 9 11.01"></polyline>
            </svg>
            تأكيد ونقل العهدة فوراً
        </button>
        <p style="margin-top: 1rem; color: var(--text-secondary); font-size: 0.9rem;">بمجرد الضغء ستحدث التغييرات في قاعدة البيانات ولن يمكن التراجع عنها تلقائياً.</p>
    </div>
</form>
@endsection
