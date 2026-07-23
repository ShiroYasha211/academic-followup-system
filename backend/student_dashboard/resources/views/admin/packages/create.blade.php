@extends('layouts.admin')

@section('title', isset($package) ? 'تعديل الباقة' : 'باقة جديدة')

@section('content')
<div style="margin-bottom: 2rem;">
    <h1 style="font-size: 1.5rem; font-weight: 700; color: var(--text-primary);">{{ isset($package) ? 'تعديل باقة: ' . $package->name : 'إضافة باقة اشتراك جديدة' }}</h1>
    <p style="color: var(--text-secondary); margin-top: 0.5rem;">قم بضبط الأسعار والخصائص لهذه الباقة</p>
</div>

<div class="card" style="max-width: 800px; padding: 2.5rem; border-radius: 24px;">
    <form action="{{ isset($package) ? route('admin.packages.update', $package) : route('admin.packages.store') }}" method="POST">
        @csrf
        @if(isset($package)) @method('PUT') @endif

        <div style="display: grid; grid-template-columns: 1fr; gap: 1.5rem; margin-bottom: 2rem;">
            <div>
                <label style="display: block; margin-bottom: 0.5rem; font-weight: 700; color: var(--text-primary);">اسم الباقة</label>
                <input type="text" name="name" value="{{ old('name', $package->name ?? '') }}" required placeholder="مثلاً: الباقة الشهرية الأساسية" 
                       style="width: 100%; padding: 0.85rem 1.25rem; border: 1.5px solid {{ $errors->has('name') ? '#ef4444' : '#e2e8f0' }}; border-radius: 12px; font-size: 1rem; outline: none; transition: border-color 0.2s;">
                @error('name') <p style="color: #ef4444; font-size: 0.75rem; margin-top: 0.25rem;">{{ $message }}</p> @enderror
            </div>

            <div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 1rem;">
                <div>
                    <label style="display: block; margin-bottom: 0.5rem; font-weight: 700; color: var(--text-primary);">سعر الطالب (ريال)</label>
                    <input type="number" name="price_student" value="{{ old('price_student', $package->price_student ?? '') }}" required
                           style="width: 100%; padding: 0.85rem 1.25rem; border: 1.5px solid {{ $errors->has('price_student') ? '#ef4444' : '#e2e8f0' }}; border-radius: 12px; font-size: 1rem; outline: none;">
                    @error('price_student') <p style="color: #ef4444; font-size: 0.75rem; margin-top: 0.25rem;">{{ $message }}</p> @enderror
                </div>
                <div>
                    <label style="display: block; margin-bottom: 0.5rem; font-weight: 700; color: var(--text-primary);">سعر الدكتور (ريال)</label>
                    <input type="number" name="price_doctor" value="{{ old('price_doctor', $package->price_doctor ?? '') }}" required
                           style="width: 100%; padding: 0.85rem 1.25rem; border: 1.5px solid {{ $errors->has('price_doctor') ? '#ef4444' : '#e2e8f0' }}; border-radius: 12px; font-size: 1rem; outline: none;">
                    @error('price_doctor') <p style="color: #ef4444; font-size: 0.75rem; margin-top: 0.25rem;">{{ $message }}</p> @enderror
                </div>
                <div>
                    <label style="display: block; margin-bottom: 0.5rem; font-weight: 700; color: var(--text-primary);">سعر المندوب (ريال)</label>
                    <input type="number" name="price_delegate" value="{{ old('price_delegate', $package->price_delegate ?? '') }}" required
                           style="width: 100%; padding: 0.85rem 1.25rem; border: 1.5px solid {{ $errors->has('price_delegate') ? '#ef4444' : '#e2e8f0' }}; border-radius: 12px; font-size: 1rem; outline: none;">
                    @error('price_delegate') <p style="color: #ef4444; font-size: 0.75rem; margin-top: 0.25rem;">{{ $message }}</p> @enderror
                </div>
                <div>
                    <label style="display: block; margin-bottom: 0.5rem; font-weight: 700; color: var(--text-primary);">سعر المسؤول الإداري (ريال)</label>
                    <input type="number" name="price_administrative" value="{{ old('price_administrative', $package->price_administrative ?? '') }}" required
                           style="width: 100%; padding: 0.85rem 1.25rem; border: 1.5px solid {{ $errors->has('price_administrative') ? '#ef4444' : '#e2e8f0' }}; border-radius: 12px; font-size: 1rem; outline: none;">
                    @error('price_administrative') <p style="color: #ef4444; font-size: 0.75rem; margin-top: 0.25rem;">{{ $message }}</p> @enderror
                </div>
            </div>

            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 1rem;">
                <div>
                    <label style="display: block; margin-bottom: 0.5rem; font-weight: 700; color: var(--text-primary);">مدة الباقة بالعمر (أيام)</label>
                    <input type="number" name="duration_days" value="{{ old('duration_days', $package->duration_days ?? 30) }}" required
                           style="width: 100%; padding: 0.85rem 1.25rem; border: 1.5px solid {{ $errors->has('duration_days') ? '#ef4444' : '#e2e8f0' }}; border-radius: 12px; font-size: 1rem; outline: none;">
                    @error('duration_days') <p style="color: #ef4444; font-size: 0.75rem; margin-top: 0.25rem;">{{ $message }}</p> @enderror
                </div>
                <div style="display: flex; align-items: flex-end; padding-bottom: 0.5rem;">
                    <label style="display: flex; align-items: center; gap: 0.75rem; cursor: pointer; user-select: none;">
                        <input type="checkbox" name="is_active" {{ old('is_active', $package->is_active ?? true) ? 'checked' : '' }} style="width: 20px; height: 20px; accent-color: var(--primary-color);">
                        <span style="font-weight: 700; color: var(--text-primary);">تفعيل الباقة حالياً</span>
                    </label>
                </div>
            </div>

            <div>
                <label style="display: block; margin-bottom: 0.5rem; font-weight: 700; color: var(--text-primary);">وصف الباقة (اختياري)</label>
                <textarea name="description" rows="3" style="width: 100%; padding: 0.85rem 1.25rem; border: 1.5px solid #e2e8f0; border-radius: 12px; font-size: 1rem; outline: none; resize: none;">{{ old('description', $package->description ?? '') }}</textarea>
            </div>
        </div>

        <div style="display: flex; gap: 1rem; padding-top: 1rem; border-top: 1px solid #f1f5f9;">
            <button type="submit" class="btn" style="flex: 1; background: var(--primary-color); color: white; padding: 1rem; border-radius: 12px; font-weight: 700; border: none; cursor: pointer; transition: all 0.2s;">
                {{ isset($package) ? 'حفظ التعديلات' : 'إنشاء الباقة الآن' }}
            </button>
            <a href="{{ route('admin.packages.index') }}" class="btn" style="padding: 1rem 2rem; background: #f8fafc; color: var(--text-secondary); border-radius: 12px; font-weight: 600; text-decoration: none; border: 1px solid #e2e8f0;">إلغاء</a>
        </div>
    </form>
</div>
@endsection
