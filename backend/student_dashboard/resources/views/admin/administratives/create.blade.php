@extends('layouts.admin')

@section('title', 'إضافة مسؤول إداري جديد')

@section('content')

<div style="margin-bottom: 2rem;">
    <a href="{{ route('admin.administratives.index') }}" style="display: flex; align-items: center; gap: 0.5rem; color: var(--text-secondary); text-decoration: none; font-weight: 600; margin-bottom: 1rem;">
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <polyline points="9 18 15 12 9 6"></polyline>
        </svg>
        العودة للقائمة
    </a>
    <h1 style="font-size: 1.5rem; font-weight: 700; color: var(--text-primary);">إضافة مسؤول إداري جديد</h1>
</div>

<div class="card" style="max-width: 800px; margin: 0 auto;">
    <form action="{{ route('admin.administratives.store') }}" method="POST">
        @csrf

        <div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 1.5rem; margin-bottom: 1.5rem;">
            <div class="form-group">
                <label style="display: block; margin-bottom: 0.5rem; font-weight: 600; color: var(--text-primary);">الاسم الكامل</label>
                <input type="text" name="name" class="form-control" value="{{ old('name') }}" required placeholder="أدخل اسم المسؤول">
                @error('name') <span style="color: var(--danger-color); font-size: 0.85rem;">{{ $message }}</span> @enderror
            </div>

            <div class="form-group">
                <label style="display: block; margin-bottom: 0.5rem; font-weight: 600; color: var(--text-primary);">البريد الإلكتروني</label>
                <input type="email" name="email" class="form-control" value="{{ old('email') }}" required placeholder="email@example.com">
                @error('email') <span style="color: var(--danger-color); font-size: 0.85rem;">{{ $message }}</span> @enderror
            </div>
        </div>

        <div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 1.5rem; margin-bottom: 1.5rem;">
            <div class="form-group">
                <label style="display: block; margin-bottom: 0.5rem; font-weight: 600; color: var(--text-primary);">كلمة المرور</label>
                <input type="password" name="password" class="form-control" required placeholder="********">
                @error('password') <span style="color: var(--danger-color); font-size: 0.85rem;">{{ $message }}</span> @enderror
            </div>

            <div class="form-group">
                <label style="display: block; margin-bottom: 0.5rem; font-weight: 600; color: var(--text-primary);">تأكيد كلمة المرور</label>
                <input type="password" name="password_confirmation" class="form-control" required placeholder="********">
            </div>
        </div>

        <div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 1.5rem; margin-bottom: 2rem;">
            <div class="form-group">
                <label style="display: block; margin-bottom: 0.5rem; font-weight: 600; color: var(--text-primary);">الكلية المسؤولة</label>
                <select name="college_id" class="form-control" required>
                    <option value="">اختر الكلية...</option>
                    @foreach($colleges as $college)
                        <option value="{{ $college->id }}" {{ old('college_id') == $college->id ? 'selected' : '' }}>
                            {{ $college->name }}
                        </option>
                    @endforeach
                </select>
                @error('college_id') <span style="color: var(--danger-color); font-size: 0.85rem;">{{ $message }}</span> @enderror
            </div>

            <div class="form-group">
                <label style="display: block; margin-bottom: 0.5rem; font-weight: 600; color: var(--text-primary);">حالة الحساب</label>
                <select name="status" class="form-control" required>
                    <option value="active" {{ old('status', 'active') == 'active' ? 'selected' : '' }}>نشط</option>
                    <option value="inactive" {{ old('status') == 'inactive' ? 'selected' : '' }}>معطل</option>
                </select>
                @error('status') <span style="color: var(--danger-color); font-size: 0.85rem;">{{ $message }}</span> @enderror
            </div>
        </div>

        <div style="display: flex; justify-content: flex-end; gap: 1rem; border-top: 1px solid var(--border-color); padding-top: 1.5rem;">
            <a href="{{ route('admin.administratives.index') }}" class="btn btn-secondary" style="padding: 0.75rem 2rem;">إلغاء</a>
            <button type="submit" class="btn btn-primary" style="padding: 0.75rem 2rem; background: var(--primary-color);">حفظ المسؤول</button>
        </div>
    </form>
</div>

@endsection
