@extends('layouts.administrative')

@section('title', 'إضافة جدول اختبارات جديد')

@section('content')

<style>
    .form-hero {
        background: linear-gradient(135deg, #1e1b4b 0%, #312e81 100%);
        border-radius: 24px;
        padding: 2.5rem;
        color: white;
        margin-bottom: 2.5rem;
        box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
        position: relative;
        overflow: hidden;
    }

    .form-hero::after {
        content: '';
        position: absolute;
        top: -50%;
        left: -10%;
        width: 80%;
        height: 200%;
        background: radial-gradient(circle, rgba(255,255,255,0.05) 0%, transparent 70%);
        transform: rotate(-15deg);
    }

    .premium-card {
        background: white;
        border-radius: 24px;
        border: 1px solid #e2e8f0;
        padding: 2.5rem;
        box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);
    }

    .premium-input {
        background-color: #f8fafc;
        border: 2px solid #f1f5f9;
        border-radius: 14px;
        padding: 0.85rem 1.25rem;
        font-weight: 700;
        color: #1e293b;
        transition: all 0.2s;
        text-align: right;
    }

    .premium-input:focus {
        border-color: #6366f1;
        background: white;
        box-shadow: 0 0 0 4px rgba(99, 102, 241, 0.1);
        outline: none;
    }

    .sidebar-actions {
        background: white;
        border-radius: 24px;
        border: 1px solid #e2e8f0;
        padding: 2rem;
        position: sticky;
        top: 2rem;
    }

    .item-input {
        background-color: #f8fafc;
        border: 2px solid #f1f5f9;
        border-radius: 12px;
        padding: 0.75rem 1rem;
        font-weight: 600;
        transition: all 0.2s;
        text-align: right;
    }

    .custom-pill-radio {
        background: #f1f5f9;
        border: 2px solid transparent;
        padding: 0.75rem 1.5rem;
        border-radius: 14px;
        font-weight: 800;
        cursor: pointer;
        transition: all 0.3s;
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
        color: #64748b;
    }

    input[type="radio"]:checked + .custom-pill-radio {
        background: #eef2ff;
        border-color: #6366f1;
        color: #6366f1;
    }

    .invalid-feedback {
        font-weight: 700;
        font-size: 0.8rem;
        margin-top: 0.5rem;
    }
</style>

<div class="form-hero">
    <div style="display: flex; gap: 1.5rem; align-items: center; position: relative; z-index: 2;">
        <a href="{{ route('administrative.exams.index') }}" style="width: 50px; height: 50px; background: rgba(255,255,255,0.2); border-radius: 16px; display: flex; align-items: center; justify-content: center; color: white; text-decoration: none; backdrop-filter: blur(10px); transition: all 0.3s;">
            <i class="fa-solid fa-arrow-right"></i>
        </a>
        <div>
            <span style="font-size: 0.85rem; font-weight: 800; opacity: 0.8; text-transform: uppercase; letter-spacing: 1px;">جدولة الامتحانات</span>
            <h1 style="font-size: 2rem; font-weight: 900; margin: 0;">{{ isset($exam) ? 'تعديل جدول الاختبارات' : 'إضافة جدول اختبارات جديد' }}</h1>
        </div>
    </div>
</div>

<div class="container-fluid" x-data="examForm()">
    <form action="{{ isset($exam) ? route('administrative.exams.update', $exam) : route('administrative.exams.store') }}" method="POST">
        @csrf
        @if(isset($exam)) @method('PUT') @endif
        
        <div class="row g-4 text-end">
            <div class="col-lg-8">
                <div class="premium-card mb-4 text-end">
                    <h5 style="font-size: 1.25rem; font-weight: 900; color: #1e293b; margin-bottom: 2rem; border-right: 4px solid #6366f1; padding-right: 1rem;">البيانات الأساسية</h5>
                    
                    <div class="row g-4">
                        <div class="col-12 mb-2">
                            <label style="display: block; font-weight: 800; color: #64748b; font-size: 0.85rem; margin-bottom: 0.75rem;">عنوان الجدول</label>
                            <input type="text" name="title" class="form-control premium-input @error('title') is-invalid @enderror" value="{{ old('title', $exam->title ?? '') }}" placeholder="مثلاً: جدول اختبارات نهاية الفصل الأول" required>
                            @error('title') <div class="invalid-feedback">{{ $message }}</div> @enderror
                        </div>

                        <div class="col-md-6 mb-2">
                            <label style="display: block; font-weight: 800; color: #64748b; font-size: 0.85rem; margin-bottom: 0.75rem;">التخصص الدراسي</label>
                            <select name="major_id" class="form-select premium-input @error('major_id') is-invalid @enderror" x-model="majorId" @change="loadLevels()" required>
                                <option value="">-- اختر التخصص --</option>
                                @foreach($majors as $major)
                                    <option value="{{ $major->id }}">{{ $major->name }}</option>
                                @endforeach
                            </select>
                            @error('major_id') <div class="invalid-feedback">{{ $message }}</div> @enderror
                        </div>

                        <div class="col-md-6 mb-2">
                            <label style="display: block; font-weight: 800; color: #64748b; font-size: 0.85rem; margin-bottom: 0.75rem;">المستوى الدراسي</label>
                            <select name="level_id" class="form-select premium-input @error('level_id') is-invalid @enderror" x-model="levelId" @change="loadSubjects()" :disabled="!majorId" required>
                                <option value="">-- اختر المستوى --</option>
                                <template x-for="level in levels" :key="level.id">
                                    <option :value="level.id" x-text="level.name" :selected="level.id == levelId"></option>
                                </template>
                            </select>
                            @error('level_id') <div class="invalid-feedback">{{ $message }}</div> @enderror
                        </div>

                        <div class="col-md-6 mb-2">
                            <label style="display: block; font-weight: 800; color: #64748b; font-size: 0.85rem; margin-bottom: 0.75rem;">الفصل الدراسي</label>
                            <select name="term_id" class="form-select premium-input @error('term_id') is-invalid @enderror" x-model="termId" :disabled="!levelId" required>
                                <option value="">-- اختر الفصل --</option>
                                <template x-for="term in terms" :key="term.id">
                                    <option :value="term.id" x-text="term.name" :selected="term.id == termId"></option>
                                </template>
                            </select>
                            @error('term_id') <div class="invalid-feedback">{{ $message }}</div> @enderror
                        </div>

                        <div class="col-md-6 mb-2">
                            <label style="display: block; font-weight: 800; color: #64748b; font-size: 0.85rem; margin-bottom: 0.75rem;">حالة الجدول</label>
                            <div class="d-flex gap-3 mt-1">
                                <label>
                                    <input type="radio" name="is_published" value="1" class="d-none" {{ old('is_published', $exam->is_published ?? '1') == '1' ? 'checked' : '' }}>
                                    <span class="custom-pill-radio"><i class="fa-solid fa-eye"></i> منشور</span>
                                </label>
                                <label>
                                    <input type="radio" name="is_published" value="0" class="d-none" {{ old('is_published', $exam->is_published ?? '1') == '0' ? 'checked' : '' }}>
                                    <span class="custom-pill-radio"><i class="fa-solid fa-lock"></i> مسودة</span>
                                </label>
                            </div>
                        </div>

                        <div class="col-12 mt-2">
                            <label style="display: block; font-weight: 800; color: #64748b; font-size: 0.85rem; margin-bottom: 0.75rem;">ملاحظات إضافية (اختياري)</label>
                            <textarea name="description" class="form-control premium-input" rows="3" placeholder="أدخل أي ملاحظات تود إرفاقها بالجدول...">{{ old('description', $exam->description ?? '') }}</textarea>
                        </div>
                    </div>
                </div>

                <div class="premium-card text-end">
                    <div class="d-flex justify-content-between align-items-center mb-4">
                        <button type="button" @click="addItem()" class="btn btn-outline-primary fw-bold" style="border-radius: 12px; padding: 0.6rem 1.5rem;" :disabled="subjects.length === 0">
                            <i class="fa-solid fa-plus me-1"></i> إضافة مادة للجدول
                        </button>
                        <h5 style="font-size: 1.25rem; font-weight: 900; color: #1e293b; border-right: 4px solid #6366f1; padding-right: 1rem; margin: 0;">تفاصيل المواد والمواعيد</h5>
                    </div>

                    <div class="table-responsive" style="overflow-x: auto;">
                        <table class="table align-middle text-end" style="min-width: 900px;">
                            <thead>
                                <tr style="background: #f8fafc;">
                                    <th style="padding: 1.25rem; border: none; border-radius: 0 16px 16px 0; color: #64748b; font-weight: 800; font-size: 0.8rem;">المادة الدراسية</th>
                                    <th style="padding: 1.25rem; border: none; color: #64748b; font-weight: 800; font-size: 0.8rem;">تاريخ الاختبار</th>
                                    <th style="padding: 1.25rem; border: none; color: #64748b; font-weight: 800; font-size: 0.8rem;">الوقت (من - إلى)</th>
                                    <th style="padding: 1.25rem; border: none; color: #64748b; font-weight: 800; font-size: 0.8rem;">موقع القاعة</th>
                                    <th style="padding: 1.25rem; border: none; border-radius: 16px 0 0 16px; color: #64748b; font-weight: 800; font-size: 0.8rem; width: 50px;"></th>
                                </tr>
                            </thead>
                            <tbody>
                                <template x-for="(item, index) in items" :key="index">
                                    <tr>
                                        <td class="py-3">
                                            <select :name="'items['+index+'][subject_id]'" class="form-select item-input" x-model="item.subject_id" required>
                                                <option value="">-- اختر المادة --</option>
                                                <template x-for="sub in subjects" :key="sub.id">
                                                    <option :value="sub.id" x-text="sub.name" :selected="sub.id == item.subject_id"></option>
                                                </template>
                                            </select>
                                        </td>
                                        <td class="py-3">
                                            <input type="date" :name="'items['+index+'][exam_date]'" class="form-control item-input" x-model="item.exam_date" required>
                                        </td>
                                        <td class="py-3">
                                            <div class="d-flex gap-2">
                                                <input type="time" :name="'items['+index+'][start_time]'" class="form-control item-input" x-model="item.start_time" required>
                                                <input type="time" :name="'items['+index+'][end_time]'" class="form-control item-input" x-model="item.end_time" required>
                                            </div>
                                        </td>
                                        <td class="py-3">
                                            <input type="text" :name="'items['+index+'][location]'" class="form-control item-input" placeholder="القاعة / المدرج" x-model="item.location">
                                        </td>
                                        <td class="py-3 text-center">
                                            <button type="button" @click="removeItem(index)" class="btn btn-link text-danger p-0" style="font-size: 1.2rem;">
                                                <i class="fa-solid fa-circle-minus"></i>
                                            </button>
                                        </td>
                                    </tr>
                                </template>
                                <template x-if="items.length === 0">
                                    <tr>
                                        <td colspan="5" class="py-5 text-center text-muted fw-bold">
                                            <i class="fa-solid fa-inbox d-block mb-3" style="font-size: 3rem; opacity: 0.2;"></i>
                                            لم يتم إضافة أي مواد حتى الآن
                                        </td>
                                    </tr>
                                </template>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>

            <div class="col-lg-4">
                <div class="sidebar-actions shadow-sm text-center">
                    <div style="margin-bottom: 2.5rem;">
                        <div style="width: 70px; height: 70px; background: #eef2ff; color: #6366f1; border-radius: 20px; display: flex; align-items: center; justify-content: center; margin: 0 auto 1.5rem; font-size: 2rem; transform: rotate(5deg); box-shadow: 0 10px 15px -3px rgba(99, 102, 241, 0.1);">
                            <i class="fa-solid fa-calendar-check"></i>
                        </div>
                        <h5 style="font-weight: 900; color: #1e293b;">إجراء الحفظ</h5>
                        <p style="color: #64748b; font-size: 0.9rem; font-weight: 500;">عند حفظ هذا الجدول، سيتم تعميمه على جميع الطلاب حسب التخصص والمستوى المختار.</p>
                    </div>

                    <div style="display: flex; flex-direction: column; gap: 1rem;">
                        <button type="submit" style="width: 100%; padding: 1rem; background: #6366f1; color: white; border: none; border-radius: 14px; font-weight: 800; font-size: 1.1rem; box-shadow: 0 10px 15px -3px rgba(99, 102, 241, 0.3); transition: all 0.3s;" onmouseover="this.style.background='#4f46e5'; this.style.transform='translateY(-2px)'" onmouseout="this.style.background='#6366f1'; this.style.transform='none'" :disabled="items.length === 0">
                            <i class="fa-solid fa-cloud-arrow-up me-2"></i> {{ isset($exam) ? 'تحديث الجدول' : 'حفظ الجدول' }}
                        </button>
                        
                        <a href="{{ route('administrative.exams.index') }}" style="display: block; padding: 1rem; background: #f8fafc; color: #64748b; border: 1px solid #e2e8f0; border-radius: 14px; text-decoration: none; font-weight: 800; font-size: 0.95rem; transition: all 0.2s;" onmouseover="this.style.background='#f1f5f9'" onmouseout="this.style.background='#f8fafc'">إلغاء وتراجع</a>
                    </div>
                    
                    <div style="margin-top: 2rem; padding: 1rem; background: #f0f9ff; border-radius: 14px; text-align: right;">
                        <h6 style="font-weight: 900; color: #0369a1; font-size: 0.85rem; margin-bottom: 0.5rem;"><i class="fa-solid fa-info-circle ms-1"></i> ملاحظة هامة:</h6>
                        <p style="font-size: 0.75rem; color: #0c4a6e; font-weight: 600; margin: 0; line-height: 1.6;">تأكد من اختيار التخصص والمستوى قبل إضافة المواد لضمان تحميل قائمة المواد الدراسية الصحيحة.</p>
                    </div>
                </div>
            </div>
        </div>
    </form>
</div>

@push('scripts')
<script>
function examForm() {
    return {
        majorId: '{{ old('major_id', $exam->major_id ?? '') }}',
        levelId: '{{ old('level_id', $exam->level_id ?? '') }}',
        termId: '{{ old('term_id', $exam->term_id ?? '') }}',
        levels: [],
        subjects: [],
        terms: [],
        items: @json(old('items', $initialItems ?? [])),
        
        async loadLevels() {
            if (!this.majorId) {
                this.levels = [];
                this.levelId = '';
                return;
            }
            try {
                const response = await fetch(`/administrative/exams/helper/levels/${this.majorId}`);
                this.levels = await response.json();
                this.levelId = '';
                this.subjects = [];
                this.terms = [];
                this.items = [];
            } catch (error) {
                console.error('Error fetching levels:', error);
            }
        },
        
        async loadSubjects() {
            if (!this.levelId) {
                this.subjects = [];
                this.terms = [];
                return;
            }
            try {
                const response = await fetch(`/administrative/exams/helper/subjects/${this.levelId}`);
                const data = await response.json();
                this.subjects = data.subjects;
                this.terms = data.terms;
                if (this.items.length === 0) {
                    this.addItem();
                }
            } catch (error) {
                console.error('Error fetching subjects:', error);
            }
        },
        
        addItem() {
            this.items.push({
                subject_id: '',
                exam_date: '',
                start_time: '',
                end_time: '',
                location: ''
            });
        },
        
        removeItem(index) {
            this.items.splice(index, 1);
        },
        
        async init() {
            if (this.majorId) {
                const response = await fetch(`/administrative/exams/helper/levels/${this.majorId}`);
                this.levels = await response.json();
                
                if (this.levelId) {
                    const subResponse = await fetch(`/administrative/exams/helper/subjects/${this.levelId}`);
                    const data = await subResponse.json();
                    this.subjects = data.subjects;
                    this.terms = data.terms;
                }
            }
        }
    }
}
</script>
@endpush

@endsection
