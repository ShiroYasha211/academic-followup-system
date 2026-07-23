@extends('layouts.admin')

@section('title', 'تعديل بيانات المسؤول الإداري')

@section('content')

<div style="margin-bottom: 2rem;">
    <a href="{{ route('admin.administratives.index') }}" style="display: flex; align-items: center; gap: 0.5rem; color: var(--text-secondary); text-decoration: none; font-weight: 600; margin-bottom: 1rem;">
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <polyline points="9 18 15 12 9 6"></polyline>
        </svg>
        العودة للقائمة
    </a>
    <h1 style="font-size: 1.5rem; font-weight: 700; color: var(--text-primary);">تعديل بيانات المسؤول: {{ $administrative->name }}</h1>
</div>

<div class="card" style="max-width: 800px; margin: 0 auto;">
    <form action="{{ route('admin.administratives.update', $administrative->id) }}" method="POST">
        @csrf
        @method('PUT')

        <div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 1.5rem; margin-bottom: 1.5rem;">
            <div class="form-group">
                <label style="display: block; margin-bottom: 0.5rem; font-weight: 600; color: var(--text-primary);">الاسم الكامل</label>
                <input type="text" name="name" class="form-control" value="{{ old('name', $administrative->name) }}" required>
                @error('name') <span style="color: var(--danger-color); font-size: 0.85rem;">{{ $message }}</span> @enderror
            </div>

            <div class="form-group">
                <label style="display: block; margin-bottom: 0.5rem; font-weight: 600; color: var(--text-primary);">البريد الإلكتروني</label>
                <input type="email" name="email" class="form-control" value="{{ old('email', $administrative->email) }}" required>
                @error('email') <span style="color: var(--danger-color); font-size: 0.85rem;">{{ $message }}</span> @enderror
            </div>
        </div>

        <div style="background: #f8fafc; border-radius: 8px; padding: 1.5rem; margin-bottom: 1.5rem; border: 1px dashed var(--border-color);">
            <p style="font-size: 0.9rem; color: var(--text-secondary); margin-bottom: 1rem;">اترك حقول كلمة المرور فارغة إذا كنت لا ترغب في تغييرها.</p>
            <div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 1.5rem;">
                <div class="form-group">
                    <label style="display: block; margin-bottom: 0.5rem; font-weight: 600; color: var(--text-primary);">كلمة المرور الجديدة</label>
                    <input type="password" name="password" class="form-control" placeholder="********">
                    @error('password') <span style="color: var(--danger-color); font-size: 0.85rem;">{{ $message }}</span> @enderror
                </div>

                <div class="form-group">
                    <label style="display: block; margin-bottom: 0.5rem; font-weight: 600; color: var(--text-primary);">تأكيد كلمة المرور</label>
                    <input type="password" name="password_confirmation" class="form-control" placeholder="********">
                </div>
            </div>
        </div>

        <div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 1.5rem; margin-bottom: 2rem;">
            <div class="form-group">
                <label style="display: block; margin-bottom: 0.5rem; font-weight: 600; color: var(--text-primary);">الكلية المسؤولة</label>
                <select name="college_id" class="form-control" required>
                    <option value="">اختر الكلية...</option>
                    @foreach($colleges as $college)
                        <option value="{{ $college->id }}" {{ old('college_id', $administrative->college_id) == $college->id ? 'selected' : '' }}>
                            {{ $college->name }}
                        </option>
                    @endforeach
                </select>
                @error('college_id') <span style="color: var(--danger-color); font-size: 0.85rem;">{{ $message }}</span> @enderror
            </div>

            <div class="form-group">
                <label style="display: block; margin-bottom: 0.5rem; font-weight: 600; color: var(--text-primary);">حالة الحساب</label>
                <select name="status" class="form-control" required>
                    <option value="active" {{ old('status', $administrative->status) == 'active' ? 'selected' : '' }}>نشط</option>
                    <option value="inactive" {{ old('status', $administrative->status) == 'inactive' ? 'selected' : '' }}>معطل</option>
                </select>
                @error('status') <span style="color: var(--danger-color); font-size: 0.85rem;">{{ $message }}</span> @enderror
            </div>
        </div>

        <div style="display: flex; justify-content: flex-end; gap: 1rem; border-top: 1px solid var(--border-color); padding-top: 1.5rem;">
            <a href="{{ route('admin.administratives.index') }}" class="btn btn-secondary" style="padding: 0.75rem 2rem;">إلغاء</a>
            <button type="submit" class="btn btn-primary" style="padding: 0.75rem 2rem; background: var(--primary-color);">تحديث البيانات</button>
        </div>
    </form>
</div>

@endsection
