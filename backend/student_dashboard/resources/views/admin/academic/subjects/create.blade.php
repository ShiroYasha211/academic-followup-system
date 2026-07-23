@extends('layouts.admin')

@section('title', 'إضافة مادة جديدة')

@section('content')
<div class="container" style="padding: 2rem;">
    <div style="margin-bottom: 2rem;">
        <h1>إضافة مادة جديدة</h1>
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

        <form action="{{ route('admin.subjects.store') }}" method="POST">
            @csrf

            <div style="margin-bottom: 1rem;">
                <label style="display: block; margin-bottom: 0.5rem; font-weight: bold;">اسم المادة <span style="color: red">*</span></label>
                <input type="text" name="name" required value="{{ old('name') }}" style="width: 100%; padding: 0.5rem; border: 1px solid #ced4da; border-radius: 4px;">
            </div>

            <div style="margin-bottom: 1rem;">
                <label style="display: block; margin-bottom: 0.5rem; font-weight: bold;">كود المادة (اختياري)</label>
                <input type="text" name="code" value="{{ old('code') }}" style="width: 100%; padding: 0.5rem; border: 1px solid #ced4da; border-radius: 4px;">
            </div>

            <div style="margin-bottom: 1rem;">
                <label style="display: block; margin-bottom: 0.5rem; font-weight: bold;">الوصف (اختياري)</label>
                <textarea name="description" rows="3" style="width: 100%; padding: 0.5rem; border: 1px solid #ced4da; border-radius: 4px;">{{ old('description') }}</textarea>
            </div>

            <div style="margin-bottom: 1.5rem;">
                <label style="display: block; margin-bottom: 0.5rem; font-weight: bold;">الفصل الدراسي (الترم) <span style="color: red">*</span></label>
                <select name="term_id" required style="width: 100%; padding: 0.5rem; border: 1px solid #ced4da; border-radius: 4px; background: white;">
                    <option value="">-- اختر الترم --</option>
                    @foreach($terms as $term)
                    <option value="{{ $term->id }}" {{ old('term_id') == $term->id ? 'selected' : '' }}>
                        {{ $term->name }} - {{ $term->level->name }} ({{ $term->level->major->name }})
                    </option>
                    @endforeach
                </select>
                <small style="color: #666; display: block; margin-top: 0.25rem;">المادة سترتبط تلقائياً بالمستوى والتخصص التابعين لهذا الترم.</small>
            </div>

            <div style="margin-bottom: 1.5rem;">
                <label style="display: block; margin-bottom: 0.5rem; font-weight: bold;">الدكتور المسؤول</label>
                <select name="doctor_id" style="width: 100%; padding: 0.5rem; border: 1px solid #ced4da; border-radius: 4px; background: white;">
                    <option value="">-- بدون دكتور (يمكن تحديده لاحقاً) --</option>
                    @foreach($doctors as $doctor)
                    <option value="{{ $doctor->id }}" {{ old('doctor_id') == $doctor->id ? 'selected' : '' }}>
                        {{ $doctor->name }}
                        @if($doctor->college) ({{ $doctor->college->name }}) @endif
                    </option>
                    @endforeach
                </select>
            </div>

            <div style="display: flex; gap: 1rem;">
                <button type="submit" style="flex: 1; background: #007bff; color: white; border: none; padding: 0.75rem; border-radius: 4px; cursor: pointer; font-size: 1rem;">
                    حفظ المادة
                </button>
                <a href="{{ route('admin.subjects.index') }}" style="flex: 1; text-align: center; background: #e2e6ea; color: #495057; text-decoration: none; padding: 0.75rem; border-radius: 4px; font-size: 1rem;">
                    إلغاء
                </a>
            </div>
        </form>
    </div>
</div>
@endsection