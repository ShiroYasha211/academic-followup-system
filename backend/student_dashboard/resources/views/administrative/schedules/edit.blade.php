@extends('layouts.administrative')

@section('title', 'تعديل موعد محاضرة')

@section('content')
<style>
    .schedule-hero {
        background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
        border-radius: 24px;
        padding: 2.5rem;
        color: white;
        margin-bottom: 2rem;
    }
    .schedule-card {
        background: white;
        border-radius: 24px;
        border: 1px solid #e2e8f0;
        padding: 2rem;
        box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05);
    }
    .schedule-input {
        background: #f8fafc;
        border: 2px solid #e2e8f0;
        border-radius: 14px;
        padding: 0.85rem 1rem;
        font-weight: 700;
    }
    .schedule-input:focus {
        border-color: #0ea5e9;
        box-shadow: 0 0 0 4px rgba(14,165,233,0.1);
    }
    .schedule-side {
        background: white;
        border-radius: 24px;
        border: 1px solid #e2e8f0;
        padding: 2rem;
        position: sticky;
        top: 2rem;
    }
    .doctor-box {
        background: #f0f9ff;
        border: 1px solid #e0f2fe;
        padding: 1rem 1.25rem;
        border-radius: 16px;
        display: flex;
        justify-content: space-between;
        gap: 1rem;
        align-items: center;
        margin-top: 1rem;
    }
</style>

<div class="schedule-hero">
    <div style="display:flex; justify-content:space-between; align-items:flex-start; gap:1rem; flex-wrap:wrap;">
        <div>
            <h1 style="font-size:2rem; font-weight:900; margin-bottom:0.5rem;">تعديل موعد محاضرة</h1>
            <p style="margin:0; opacity:0.85;">تحديث بيانات الموعد الدراسي والقاعة واليوم بشكل مباشر.</p>
        </div>
        <a href="{{ route('administrative.schedules.index') }}" class="btn btn-light" style="font-weight:800;">العودة للجدول</a>
    </div>
</div>

<div class="container-fluid" x-data="scheduleForm()" x-init="init()">
    <form action="{{ route('administrative.schedules.update', $schedule) }}" method="POST">
        @csrf
        @method('PUT')

        <div class="row g-4">
            <div class="col-lg-8">
                <div class="schedule-card">
                    <h5 style="font-weight:900; color:#1e293b; margin-bottom:1.5rem;">تفاصيل الموعد الدراسي</h5>

                    <div class="row g-4">
                        <div class="col-md-6">
                            <label class="form-label fw-bold text-secondary">التخصص الدراسي</label>
                            <select name="major_id" class="form-select schedule-input @error('major_id') is-invalid @enderror" x-model="majorId" @change="loadLevels()" required>
                                <option value="">اختر التخصص</option>
                                @foreach($majors as $major)
                                    <option value="{{ $major->id }}">{{ $major->name }}</option>
                                @endforeach
                            </select>
                            @error('major_id') <div class="invalid-feedback">{{ $message }}</div> @enderror
                        </div>

                        <div class="col-md-6">
                            <label class="form-label fw-bold text-secondary">المستوى الدراسي</label>
                            <select name="level_id" class="form-select schedule-input @error('level_id') is-invalid @enderror" x-model="levelId" @change="loadSubjects()" :disabled="!majorId" required>
                                <option value="">اختر المستوى</option>
                                <template x-for="level in levels" :key="level.id">
                                    <option :value="level.id" x-text="level.name"></option>
                                </template>
                            </select>
                            @error('level_id') <div class="invalid-feedback">{{ $message }}</div> @enderror
                        </div>

                        <div class="col-12">
                            <label class="form-label fw-bold text-secondary">المادة الدراسية</label>
                            <select name="subject_id" class="form-select schedule-input @error('subject_id') is-invalid @enderror" x-model="subjectId" @change="updateDoctor()" :disabled="!levelId" required>
                                <option value="">اختر المادة</option>
                                <template x-for="sub in subjects" :key="sub.id">
                                    <option :value="sub.id" x-text="sub.name"></option>
                                </template>
                            </select>
                            <div class="doctor-box" x-show="doctorName">
                                <span class="fw-bold text-dark">أستاذ المقرر:</span>
                                <span class="fw-bold text-primary" x-text="doctorName"></span>
                            </div>
                            @error('subject_id') <div class="invalid-feedback">{{ $message }}</div> @enderror
                        </div>

                        <div class="col-12"><hr></div>

                        <div class="col-md-4">
                            <label class="form-label fw-bold text-secondary">اليوم الأسبوعي</label>
                            <select name="day_of_week" class="form-select schedule-input @error('day_of_week') is-invalid @enderror" required>
                                @php
                                    $days = [6 => 'السبت', 7 => 'الأحد', 1 => 'الاثنين', 2 => 'الثلاثاء', 3 => 'الأربعاء', 4 => 'الخميس', 5 => 'الجمعة'];
                                @endphp
                                @foreach($days as $id => $name)
                                    <option value="{{ $id }}" @selected(old('day_of_week', $schedule->day_of_week) == $id)>{{ $name }}</option>
                                @endforeach
                            </select>
                            @error('day_of_week') <div class="invalid-feedback">{{ $message }}</div> @enderror
                        </div>

                        <div class="col-md-4">
                            <label class="form-label fw-bold text-secondary">وقت البداية</label>
                            <input type="time" name="start_time" class="form-control schedule-input @error('start_time') is-invalid @enderror" value="{{ old('start_time', substr($schedule->start_time, 0, 5)) }}" required>
                            @error('start_time') <div class="invalid-feedback">{{ $message }}</div> @enderror
                        </div>

                        <div class="col-md-4">
                            <label class="form-label fw-bold text-secondary">وقت النهاية</label>
                            <input type="time" name="end_time" class="form-control schedule-input @error('end_time') is-invalid @enderror" value="{{ old('end_time', substr($schedule->end_time, 0, 5)) }}" required>
                            @error('end_time') <div class="invalid-feedback">{{ $message }}</div> @enderror
                        </div>

                        <div class="col-12">
                            <label class="form-label fw-bold text-secondary">اسم القاعة أو المختبر</label>
                            <input type="text" name="hall_name" class="form-control schedule-input @error('hall_name') is-invalid @enderror" value="{{ old('hall_name', $schedule->hall_name) }}" placeholder="مثال: قاعة 204، بنك المعلومات">
                            @error('hall_name') <div class="invalid-feedback">{{ $message }}</div> @enderror
                        </div>
                    </div>
                </div>
            </div>

            <div class="col-lg-4">
                <div class="schedule-side shadow-sm text-center">
                    <div style="margin-bottom: 2rem;">
                        <div style="width:72px; height:72px; background:#e0f2fe; color:#0284c7; border-radius:20px; display:flex; align-items:center; justify-content:center; margin:0 auto 1rem; font-size:1.8rem;">
                            <i class="fa-solid fa-pen-to-square"></i>
                        </div>
                        <h5 style="font-weight:900; color:#1e293b;">حفظ التعديلات</h5>
                        <p style="color:#64748b; font-size:0.92rem; margin:0;">عند الحفظ سيتم تحديث الجدول الدراسي لدى جميع الطلاب المشمولين.</p>
                    </div>

                    <div style="display:flex; flex-direction:column; gap:1rem;">
                        <button type="submit" class="btn btn-primary" style="width:100%; font-weight:800; padding:1rem;">
                            <i class="fa-solid fa-check-double me-2"></i>
                            تطبيق التحديثات
                        </button>
                        <a href="{{ route('administrative.schedules.index') }}" class="btn btn-outline-secondary" style="width:100%; font-weight:800; padding:1rem;">إلغاء والعودة</a>
                    </div>
                </div>
            </div>
        </div>
    </form>
</div>

@push('scripts')
<script>
function scheduleForm() {
    return {
        majorId: '{{ old('major_id', $schedule->subject->major_id) }}',
        levelId: '{{ old('level_id', $schedule->subject->level_id) }}',
        subjectId: '{{ old('subject_id', $schedule->subject_id) }}',
        levels: [],
        subjects: @json($subjects),
        doctorName: '{{ $schedule->subject->doctor->name ?? "غير محدد" }}',

        async loadLevels() {
            if (!this.majorId) {
                this.levels = [];
                this.levelId = '';
                this.subjects = [];
                this.subjectId = '';
                this.doctorName = '';
                return;
            }

            const response = await fetch(`/administrative/exams/helper/levels/${this.majorId}`);
            this.levels = await response.json();
            this.levelId = '';
            this.subjects = [];
            this.subjectId = '';
            this.doctorName = '';
        },

        async loadSubjects() {
            if (!this.levelId) {
                this.subjects = [];
                this.subjectId = '';
                this.doctorName = '';
                return;
            }

            const response = await fetch(`/administrative/schedules/helper/subjects/${this.levelId}`);
            this.subjects = await response.json();
            this.subjectId = '';
            this.doctorName = '';
        },

        updateDoctor() {
            const subject = this.subjects.find(s => s.id == this.subjectId);
            this.doctorName = subject && subject.doctor ? subject.doctor.name : 'غير محدد';
        },

        async init() {
            if (this.majorId) {
                const response = await fetch(`/administrative/exams/helper/levels/${this.majorId}`);
                this.levels = await response.json();
            }

            if (this.levelId) {
                const response = await fetch(`/administrative/schedules/helper/subjects/${this.levelId}`);
                this.subjects = await response.json();
            }

            if (this.subjectId) {
                this.updateDoctor();
            }
        }
    }
}
</script>
@endpush
@endsection
