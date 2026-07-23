@extends('layouts.student')

@section('title', 'تعديل Oneline Shot')

@section('content')
<div class="container-fluid py-4">
    <div class="d-flex justify-content-between align-items-center mb-4 flex-wrap gap-3">
        <div>
            <h1 class="h3 fw-black text-dark mb-1">تعديل الحزمة</h1>
            <p class="text-secondary mb-0">{{ $flashcard->title }}</p>
        </div>
        <a href="{{ route('student.flashcards.show', $flashcard) }}" class="btn btn-light border rounded-3 px-3 py-2 fw-bold">
            العودة للحزمة
        </a>
    </div>

    @if($errors->any())
        <div class="alert alert-danger border-0 shadow-sm rounded-4 mb-4">
            <div class="fw-black mb-2">حدثت أخطاء في الإدخال</div>
            <ul class="mb-0 small">
                @foreach($errors->all() as $error)
                    <li>{{ $error }}</li>
                @endforeach
            </ul>
        </div>
    @endif

    <form action="{{ route('student.flashcards.update', $flashcard) }}" method="POST">
        @csrf
        @method('PUT')
        <div class="row g-4">
            <div class="col-lg-8">
                <div class="card border-0 shadow-sm rounded-4">
                    <div class="card-body p-4 p-md-5">
                        <div class="row g-3">
                            <div class="col-md-8">
                                <label class="form-label fw-bold">عنوان الحزمة</label>
                                <input type="text" name="title" value="{{ old('title', $flashcard->title) }}" class="form-control form-control-lg" required>
                            </div>
                            <div class="col-md-4">
                                <label class="form-label fw-bold">لون الحزمة</label>
                                <input type="color" name="color" value="{{ old('color', $flashcard->color) }}" class="form-control form-control-color">
                            </div>
                            <div class="col-12">
                                <label class="form-label fw-bold">وصف مختصر</label>
                                <textarea name="description" rows="3" class="form-control">{{ old('description', $flashcard->description) }}</textarea>
                            </div>
                            <div class="col-md-6">
                                <label class="form-label fw-bold">النوع الافتراضي للعناصر الجديدة</label>
                                <select name="display_mode" class="form-select" required>
                                    <option value="flash_card" @selected(old('display_mode', $flashcard->display_mode) === 'flash_card')>بطاقة تعليمية</option>
                                    <option value="one_line" @selected(old('display_mode', $flashcard->display_mode) === 'one_line')>نص واحد</option>
                                    <option value="qa" @selected(old('display_mode', $flashcard->display_mode) === 'qa')>سؤال وجواب</option>
                                    <option value="mcq" @selected(old('display_mode', $flashcard->display_mode) === 'mcq')>اختيارات</option>
                                </select>
                            </div>
                            <div class="col-md-6">
                                <label class="form-label fw-bold">الحزمة الأب</label>
                                <select name="parent_pack_id" class="form-select" @disabled($flashcard->is_assigned)>
                                    <option value="">بدون حزمة أب</option>
                                    @foreach($parentPacks as $parentPack)
                                        <option value="{{ $parentPack->id }}" @selected((string) old('parent_pack_id', $flashcard->parent_pack_id) === (string) $parentPack->id)>
                                            {{ $parentPack->title }}
                                        </option>
                                    @endforeach
                                </select>
                                @if($flashcard->is_assigned)
                                    <div class="form-text text-danger">الحزم المعيّنة لا يمكن نقلها داخل شجرة أخرى.</div>
                                @endif
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <div class="col-lg-4">
                <div class="card border-0 shadow-sm rounded-4 mb-4">
                    <div class="card-body p-4">
                        <h5 class="fw-black mb-3">إعدادات التكرار</h5>
                        <div class="mb-3">
                            <label class="form-label fw-bold">دورة التكرار</label>
                            <select name="repeat_cycle" class="form-select" required>
                                <option value="daily" @selected(old('repeat_cycle', $flashcard->repeat_cycle) === 'daily')>يومي</option>
                                <option value="weekly" @selected(old('repeat_cycle', $flashcard->repeat_cycle) === 'weekly')>أسبوعي</option>
                                <option value="monthly" @selected(old('repeat_cycle', $flashcard->repeat_cycle) === 'monthly')>شهري</option>
                            </select>
                        </div>
                        <div class="mb-3">
                            <label class="form-label fw-bold">عدد الإشعارات اليومية</label>
                            <input type="number" name="daily_notification_count" value="{{ old('daily_notification_count', $flashcard->daily_notification_count) }}" min="1" max="50" class="form-control">
                        </div>
                        <div class="row g-3">
                            <div class="col-6">
                                <label class="form-label fw-bold">من</label>
                                <input type="time" name="quiet_start" value="{{ old('quiet_start', $flashcard->quiet_start ? \Carbon\Carbon::parse($flashcard->quiet_start)->format('H:i') : '23:00') }}" class="form-control">
                            </div>
                            <div class="col-6">
                                <label class="form-label fw-bold">إلى</label>
                                <input type="time" name="quiet_end" value="{{ old('quiet_end', $flashcard->quiet_end ? \Carbon\Carbon::parse($flashcard->quiet_end)->format('H:i') : '07:00') }}" class="form-control">
                            </div>
                        </div>
                        <div class="form-check form-switch mt-3">
                            <input type="hidden" name="notifications_enabled" value="0">
                            <input class="form-check-input" type="checkbox" role="switch" id="notifications_enabled" name="notifications_enabled" value="1" @checked(old('notifications_enabled', $flashcard->notifications_enabled))>
                            <label class="form-check-label fw-bold" for="notifications_enabled">تفعيل الإشعارات</label>
                        </div>
                    </div>
                </div>

                <button type="submit" class="btn btn-primary w-100 py-3 fw-black rounded-4">حفظ التعديلات</button>
            </div>
        </div>
    </form>
</div>
@endsection
