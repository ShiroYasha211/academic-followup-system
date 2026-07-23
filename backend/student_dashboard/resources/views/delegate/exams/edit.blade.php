@extends('layouts.delegate')

@section('title', 'تعديل جدول اختبارات')

@section('content')
<div x-data="{
    items: {{ $exam->items->map(function($item) {
        return [
            'id' => $item->id,
            'subject_id' => $item->subject_id,
            'exam_date' => $item->exam_date->format('Y-m-d'),
            'start_time' => \Carbon\Carbon::parse($item->start_time)->format('H:i'),
            'end_time' => \Carbon\Carbon::parse($item->end_time)->format('H:i'),
            'location' => $item->location
        ];
    }) }},
    addItem() {
        this.items.push({
            id: 'new_' + Date.now(),
            subject_id: '',
            exam_date: '',
            start_time: '',
            end_time: '',
            location: ''
        });
    },
    removeItem(index) {
        if (this.items.length > 1) {
            this.items.splice(index, 1);
        } else {
            alert('يجب أن يحتوي الجدول على مادة واحدة على الأقل.');
        }
    }
}">

    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 2rem;">
        <div>
            <h1 style="font-size: 1.5rem; font-weight: 700; color: var(--text-primary);">تعديل جدول: {{ $exam->title }}</h1>
        </div>
        <a href="{{ route('delegate.exams.index') }}" class="btn btn-secondary">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <line x1="19" y1="12" x2="5" y2="12"></line>
                <polyline points="12 19 5 12 12 5"></polyline>
            </svg>
            عودة
        </a>
    </div>

    <div class="card">
        <form action="{{ route('delegate.exams.update', $exam->id) }}" method="POST">
            @csrf
            @method('PUT')

            <!-- Basic Info -->
            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 1.5rem; margin-bottom: 2rem;">
                <div class="form-group" style="margin-bottom: 0; grid-column: span 2;">
                    <label class="form-label">عنوان الجدول <span style="color: var(--danger-color)">*</span></label>
                    <input type="text" name="title" class="form-control" value="{{ old('title', $exam->title) }}" required>
                </div>

                <div class="form-group" style="margin-bottom: 0;">
                    <label class="form-label">الفصل الدراسي <span style="color: var(--danger-color)">*</span></label>
                    <select name="term_id" class="form-control" required>
                        <option value="">اختر الفصل...</option>
                        @foreach($terms as $term)
                        <option value="{{ $term->id }}" {{ $exam->term_id == $term->id ? 'selected' : '' }}>{{ $term->name }}</option>
                        @endforeach
                    </select>
                </div>

                <div class="form-group" style="margin-bottom: 0; display: flex; align-items: flex-end;">
                    <label style="display: flex; align-items: center; gap: 0.5rem; cursor: pointer; user-select: none;">
                        <input type="checkbox" name="is_published" value="1" style="width: 18px; height: 18px;" {{ $exam->is_published ? 'checked' : '' }}>
                        <span style="font-weight: 600;">نشر الجدول للطلاب فوراً</span>
                    </label>
                </div>

                <div class="form-group" style="margin-bottom: 0; grid-column: span 2;">
                    <label class="form-label">ملاحظات إضافية</label>
                    <textarea name="description" class="form-control" rows="2">{{ old('description', $exam->description) }}</textarea>
                </div>
            </div>

            <hr style="border: 0; border-top: 1px solid var(--border-color); margin: 2rem 0;">

            <!-- Schedule Items -->
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 1rem;">
                <h3 style="font-size: 1.1rem; font-weight: 700; color: var(--primary-color);">مواعيد الاختبارات</h3>
                <button type="button" @click="addItem()" class="btn btn-sm btn-outline-primary" style="border: 1px solid var(--primary-color); color: var(--primary-color); background: none;">
                    + إضافة مادة
                </button>
            </div>

            <div style="display: flex; flex-direction: column; gap: 1rem;">
                <template x-for="(item, index) in items" :key="item.id">
                    <div class="card" style="padding: 1.5rem; border: 1px solid #e2e8f0; position: relative; box-shadow: none; background: #f8fafc;">
                        <button type="button" @click="removeItem(index)" style="position: absolute; top: 1rem; left: 1rem; background: none; border: none; color: var(--danger-color); cursor: pointer;" title="حذف المادة">
                            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <line x1="18" y1="6" x2="6" y2="18"></line>
                                <line x1="6" y1="6" x2="18" y2="18"></line>
                            </svg>
                        </button>

                        <div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 1rem; padding-left: 2rem;">
                            <div style="grid-column: span 2;">
                                <label class="form-label" style="font-size: 0.9rem;">المادة <span style="color: var(--danger-color)">*</span></label>
                                <select :name="'items[' + index + '][subject_id]'" class="form-control" required x-model="item.subject_id">
                                    <option value="">اختر المادة...</option>
                                    @foreach($subjects as $subject)
                                    <option value="{{ $subject->id }}">{{ $subject->name }}</option>
                                    @endforeach
                                </select>
                            </div>

                            <div>
                                <label class="form-label" style="font-size: 0.9rem;">التاريخ <span style="color: var(--danger-color)">*</span></label>
                                <input type="date" :name="'items[' + index + '][exam_date]'" class="form-control" required x-model="item.exam_date">
                            </div>

                            <div>
                                <label class="form-label" style="font-size: 0.9rem;">القاعة / المكان</label>
                                <input type="text" :name="'items[' + index + '][location]'" class="form-control" x-model="item.location">
                            </div>

                            <div>
                                <label class="form-label" style="font-size: 0.9rem;">وقت البدء <span style="color: var(--danger-color)">*</span></label>
                                <input type="time" :name="'items[' + index + '][start_time]'" class="form-control" required x-model="item.start_time">
                            </div>

                            <div>
                                <label class="form-label" style="font-size: 0.9rem;">وقت الانتهاء <span style="color: var(--danger-color)">*</span></label>
                                <input type="time" :name="'items[' + index + '][end_time]'" class="form-control" required x-model="item.end_time">
                            </div>
                        </div>
                    </div>
                </template>
            </div>

            <div style="margin-top: 2rem; display: flex; justify-content: flex-end;">
                <button type="submit" class="btn btn-primary" style="padding-left: 2rem; padding-right: 2rem;">حفظ التعديلات</button>
            </div>
        </form>
    </div>
</div>
@endsection