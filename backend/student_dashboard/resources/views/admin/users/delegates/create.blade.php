@extends('layouts.admin')

@section('title', 'إضافة مندوب جديد')

@section('content')
<div class="container" style="padding: 2rem;">
    <div style="margin-bottom: 2rem;">
        <h1>إضافة مندوب جديد</h1>
    </div>

    <div class="card" style="max-width: 600px; margin: 0 auto;">

        @if ($errors->any())
        <div style="color: #721c24; background-color: #f8d7da; padding: 0.75rem; border-radius: 4px; margin-bottom: 1rem;">
            <ul style="margin: 0; padding-right: 1.5rem;">
                @foreach ($errors->all() as $error)
                <li>{{ $error }}</li>
                @endforeach
            </ul>
        </div>
        @endif

        <form action="{{ route('admin.delegates.store') }}" method="POST">
            @csrf

            <div style="margin-bottom: 1rem;">
                <label style="display: block; margin-bottom: 0.5rem; font-weight: bold;">الاسم الكامل <span style="color: red">*</span></label>
                <input type="text" name="name" required value="{{ old('name') }}" style="width: 100%; padding: 0.5rem; border: 1px solid #ced4da; border-radius: 4px;">
            </div>

            <div style="margin-bottom: 1rem;">
                <label style="display: block; margin-bottom: 0.5rem; font-weight: bold;">البريد الإلكتروني <span style="color: red">*</span></label>
                <input type="email" name="email" required value="{{ old('email') }}" style="width: 100%; padding: 0.5rem; border: 1px solid #ced4da; border-radius: 4px;">
            </div>

            <div style="margin-bottom: 1rem;">
                <label style="display: block; margin-bottom: 0.5rem; font-weight: bold;">كلمة المرور <span style="color: red">*</span></label>
                <input type="password" name="password" required style="width: 100%; padding: 0.5rem; border: 1px solid #ced4da; border-radius: 4px;">
            </div>

            <div style="margin-bottom: 1.5rem;">
                <label style="display: block; margin-bottom: 0.5rem; font-weight: bold;">المستوى المسؤول عنه <span style="color: red">*</span></label>
                <select name="level_id" required style="width: 100%; padding: 0.5rem; border: 1px solid #ced4da; border-radius: 4px; background: white;">
                    <option value="">-- اختر المستوى --</option>
                    @foreach($majors as $major)
                    <optgroup label="{{ $major->name }} ({{ $major->college->name }})">
                        @foreach($major->levels as $level)
                        <option value="{{ $level->id }}" {{ old('level_id') == $level->id ? 'selected' : '' }}>
                            {{ $level->name }}
                        </option>
                        @endforeach
                    </optgroup>
                    @endforeach
                </select>
                <small style="color: #666; display: block; margin-top: 0.25rem;">اختيار المستوى سيقوم تلقائياً بربط المندوب بالجامعة والكلية والتخصص التابعين لهذا المستوى.</small>
            </div>

            <div style="display: flex; gap: 1rem;">
                <button type="submit" style="flex: 1; background: #007bff; color: white; border: none; padding: 0.75rem; border-radius: 4px; cursor: pointer; font-size: 1rem;">
                    حفظ المندوب
                </button>
                <a href="{{ route('admin.delegates.index') }}" style="flex: 1; text-align: center; background: #e2e6ea; color: #495057; text-decoration: none; padding: 0.75rem; border-radius: 4px; font-size: 1rem;">
                    إلغاء
                </a>
            </div>
        </form>
    </div>
</div>
@endsection