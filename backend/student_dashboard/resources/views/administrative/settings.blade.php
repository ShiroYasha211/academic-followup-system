@extends('layouts.administrative')

@section('title', 'إعدادات الكلية')

@section('content')

<div style="margin-bottom: 2rem;">
    <h1 style="font-size: 1.5rem; font-weight: 700; color: var(--text-primary);">إعدادات الكلية المتغيرة</h1>
    <p style="color: var(--text-secondary); margin-top: 0.5rem;">تحديد القواعد التنظيمية الخاصة بكلية {{ $college->name }}</p>
</div>

<div class="card" style="max-width: 800px;">
    <form action="{{ route('administrative.settings.update') }}" method="POST">
        @csrf
        @method('PUT')

        <div style="display: grid; gap: 2rem;">
            
            <div class="form-group">
                <label style="display: block; margin-bottom: 0.5rem; font-weight: 700; color: var(--text-primary);">نسبة الحرمان من المادة (%)</label>
                <div style="display: flex; align-items: center; gap: 1rem;">
                    <input type="number" name="absence_deprivation_percentage" 
                           class="form-control" 
                           value="{{ old('absence_deprivation_percentage', $college->absence_deprivation_percentage) }}" 
                           min="1" max="100" required
                           style="width: 120px;">
                    <span style="color: var(--text-secondary); font-size: 0.9rem;">النسبة المئوية للغياب التي يتم بعدها حرمان الطالب تلقائياً من المادة.</span>
                </div>
                @error('absence_deprivation_percentage') <span style="color: var(--danger-color); font-size: 0.85rem;">{{ $message }}</span> @enderror
            </div>

            <div style="height: 1px; background: var(--border-color);"></div>

            <div class="form-group">
                <label style="display: block; margin-bottom: 0.5rem; font-weight: 700; color: var(--text-primary);">أخر موعد لتقديم العذر (بالأيام)</label>
                <div style="display: flex; align-items: center; gap: 1rem;">
                    <input type="number" name="excuses_deadline_days" 
                           class="form-control" 
                           value="{{ old('excuses_deadline_days', $college->excuses_deadline_days) }}" 
                           min="1" max="30" required
                           style="width: 120px;">
                    <span style="color: var(--text-secondary); font-size: 0.9rem;">الحد الأقصى المسموح به لتقديم العذر بعد تار�ondary); margin-top: 0.25rem;">استقبال الأعذار ورقياً وإلكترونياً</div>
                        </div>
                    </label>
                </div>
                @error('excuse_receiver') <span style="color: var(--danger-color); font-size: 0.85rem;">{{ $message }}</span> @enderror
            </div>

            <div style="display: flex; justify-content: flex-end; padding-top: 1rem;">
                <button type="submit" class="btn btn-primary" style="padding: 0.85rem 3rem; background: var(--primary-color); font-weight: 700; font-size: 1rem; border-radius: 10px; box-shadow: 0 4px 6px rgba(67, 56, 202, 0.2);">
                    حفظ وإقرار الإعدادات
                </button>
            </div>

        </div>
    </form>
</div>

@endsection
