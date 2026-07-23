@extends('layouts.admin')

@section('title', 'تسجيل الحضور')

@section('content')
<div class="container" style="padding: 2rem;">
    <div style="margin-bottom: 2rem;">
        <h1>تسجيل الحضور</h1>
    </div>

    <div class="card" style="max-width: 600px; margin: 0 auto;">
        <form action="{{ route('admin.attendance.form') }}" method="GET">

            <div style="margin-bottom: 1rem;">
                <label style="display: block; margin-bottom: 0.5rem; font-weight: bold;">المادة الدراسية <span style="color: red">*</span></label>
                <select name="subject_id" required style="width: 100%; padding: 0.5rem; border: 1px solid #ced4da; border-radius: 4px; background: white;">
                    <option value="">-- اختر المادة --</option>
                    @foreach($subjects as $subject)
                    <option value="{{ $subject->id }}" {{ old('subject_id') == $subject->id ? 'selected' : '' }}>
                        {{ $subject->name }} ({{ $subject->major->name }} - {{ $subject->level->name }})
                    </option>
                    @endforeach
                </select>
            </div>

            <div style="margin-bottom: 1.5rem;">
                <label style="display: block; margin-bottom: 0.5rem; font-weight: bold;">التاريخ <span style="color: red">*</span></label>
                <input type="date" name="date" required value="{{ date('Y-m-d') }}" style="width: 100%; padding: 0.5rem; border: 1px solid #ced4da; border-radius: 4px;">
            </div>

            <button type="submit" style="width: 100%; background: #007bff; color: white; border: none; padding: 0.75rem; border-radius: 4px; cursor: pointer; font-size: 1rem;">
                متابعة لتسجيل الحضور
            </button>
        </form>
    </div>
</div>
@endsection