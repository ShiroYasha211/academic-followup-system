@extends('layouts.doctor')

@section('title', 'تعديل الكويز')

@section('content')
<style>
    .qbuilder-container { max-width: 900px; margin: 0 auto; }

    .qbuilder-header {
        background: linear-gradient(135deg, #0369a1 0%, #0ea5e9 100%);
        border-radius: 24px;
        padding: 2.5rem 2rem;
        color: white;
        margin-bottom: 2rem;
        position: relative;
        overflow: hidden;
    }

    .qbuilder-header::before {
        content: '';
        position: absolute;
        top: -50%;
        right: -10%;
        width: 300px;
        height: 300px;
        background: rgba(255,255,255,0.08);
        border-radius: 50%;
    }

    .qbuilder-header-content { position: relative; z-index: 1; }
    .qbuilder-header h1 { font-size: 2rem; font-weight: 800; margin-bottom: 0.25rem; }
    .qbuilder-header p { opacity: 0.85; }

    .section-card {
        background: white;
        border-radius: 20px;
        border: 1px solid #e2e8f0;
        padding: 2rem;
        margin-bottom: 1.5rem;
        box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05);
    }

    .section-title {
        font-size: 1.1rem;
        font-weight: 800;
        color: #1e293b;
        margin-bottom: 1.25rem;
        display: flex;
        align-items: center;
        gap: 0.5rem;
    }

    .section-title i { color: #0ea5e9; }

    .form-label-q {
        font-weight: 700;
        color: #334155;
        margin-bottom: 0.5rem;
        font-size: 0.9rem;
    }

    .form-control-q, .form-select-q {
        border: 2px solid #e2e8f0;
        border-radius: 14px;
        padding: 0.7rem 1rem;
        font-size: 0.9rem;
        transition: border-color 0.2s;
    }

    .form-control-q:focus, .form-select-q:focus {
        border-color: #0ea5e9;
        box-shadow: 0 0 0 4px rgba(14,165,233,0.1);
    }

    /* Model Card */
    .model-card {
        border: 2px solid #e2e8f0;
        border-radius: 18px;
        padding: 1.5rem;
        margin-bottom: 1.5rem;
        position: relative;
        background: #fafafa;
    }

    .model-card-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 1.25rem;
        padding-bottom: 0.75rem;
        border-bottom: 1px solid #e2e8f0;
    }

    .model-card-title {
        font-weight: 800;
        font-size: 1rem;
        color: #0369a1;
        display: flex;
        align-items: center;
        gap: 0.5rem;
    }

    /* Question Card */
    .question-card {
        border: 1px solid #e2e8f0;
        border-radius: 14px;
        padding: 1.25rem;
        margin-bottom: 1rem;
        background: white;
        position: relative;
    }

    .question-card-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 1rem;
    }

    .question-number {
        font-weight: 800;
        font-size: 0.85rem;
        color: #0369a1;
        background: #e0f2fe;
        padding: 0.25rem 0.75rem;
        border-radius: 99px;
    }

    /* Option Row */
    .option-row {
        display: flex;
        align-items: center;
        gap: 0.5rem;
        margin-bottom: 0.5rem;
    }

    .option-row input[type="text"] { flex: 1; }

    .correct-radio {
        width: 20px;
        height: 20px;
        accent-color: #0ea5e9;
        cursor: pointer;
    }

    /* Buttons */
    .btn-add {
        background: #e0f2fe;
        color: #0369a1;
        border: 2px dashed #7dd3fc;
        padding: 0.6rem 1.2rem;
        border-radius: 12px;
        font-weight: 700;
        font-size: 0.85rem;
        cursor: pointer;
        transition: all 0.2s;
        display: inline-flex;
        align-items: center;
        gap: 0.35rem;
    }

    .btn-add:hover { background: #bae6fd; border-color: #0ea5e9; }

    .btn-remove {
        background: none;
        border: none;
        color: #94a3b8;
        cursor: pointer;
        padding: 0.3rem;
        border-radius: 6px;
        transition: all 0.2s;
    }

    .btn-remove:hover { color: #ef4444; background: #fee2e2; }

    .btn-submit-quiz {
        background: linear-gradient(135deg, #0369a1, #0ea5e9);
        color: white;
        border: none;
        padding: 0.85rem 2rem;
        border-radius: 14px;
        font-weight: 700;
        font-size: 1rem;
        transition: all 0.2s;
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
    }

    .btn-submit-quiz:hover { transform: translateY(-2px); box-shadow: 0 10px 25px rgba(14,165,233,0.3); color: white; }

    .btn-back {
        background: #f1f5f9;
        color: #475569;
        border: none;
        padding: 0.85rem 1.5rem;
        border-radius: 14px;
        font-weight: 600;
        text-decoration: none;
        transition: all 0.2s;
    }

    .btn-back:hover { background: #e2e8f0; color: #334155; }

    /* Toggle Switches */
    .toggle-group {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
        gap: 0.75rem;
    }

    .toggle-item {
        display: flex;
        align-items: center;
        gap: 0.75rem;
        padding: 0.75rem 1rem;
        background: #f8fafc;
        border-radius: 12px;
        border: 1px solid #e2e8f0;
    }

    .toggle-item label { font-size: 0.85rem; font-weight: 600; color: #475569; cursor: pointer; }

    /* Warning Card */
    .warning-card {
        background: #fffbeb;
        border: 1px solid #fde68a;
        color: #92400e;
        padding: 1rem;
        border-radius: 14px;
        margin-bottom: 1.5rem;
        display: flex;
        align-items: flex-start;
        gap: 0.75rem;
    }
    .warning-icon { font-size: 1.25rem; margin-top: 0.1rem; }
</style>

<div class="qbuilder-container" x-data="quizBuilder()">
    <div class="qbuilder-header">
        <div class="qbuilder-header-content">
            <h1><i class="fa-solid fa-edit me-2"></i>تعديل الكويز</h1>
            <p>تعديل إعدادات أو مادة الكويز الحالية</p>
        </div>
    </div>

    @if(!$canEditContent)
    <div class="warning-card">
        <i class="fa-solid fa-triangle-exclamation warning-icon"></i>
        <div>
            <div class="fw-bold mb-1">وضع الحماية نشط</div>
            <div class="small">بدأ الطلاب بالفعل في حل هذا الكويز. يمكنك تعديل الإعدادات العامة فقغ تعديل الأسئلة أو النماذج معطل حالياً لضمان دقة النتائج.</div>
        </div>
    </div>
    @endif

    <form action="{{ route('doctor.quizzes.update', $quiz) }}" method="POST" @submit="handleSubmit($event)">
        @csrf
        @method('PUT')

        {{-- Basic Info --}}
        <div class="section-card">
            <h3 class="section-title"><i class="fa-solid fa-info-circle"></i> معلومات الكويز</h3>

            <div class="row g-3">
                <div class="col-md-6">
                    <label class="form-label-q">المادة *</label>
                    <select name="subject_id" class="form-select form-select-q" required>
                        @foreach($subjects as $subject)
                        <option value="{{ $subject->id }}" {{ $quiz->subject_id == $subject->id ? 'selected' : '' }}>
                            {{ $subject->name }} — {{ $subject->level->name ?? '' }}
                        </option>
                        @endforeach
                    </select>
                </div>
                <div class="col-md-6">
                    <label class="form-label-q">عنوان الكويز *</label>
                    <input type="text" name="title" class="form-control form-control-q" value="{{ $quiz->title }}" required>
                </div>
                <div class="col-12">
                    <label class="form-label-q">وصف (اختياري)</label>
                    <textarea name="description" class="form-control form-control-q" rows="2">{{ $quiz->description }}</textarea>
                </div>
            </div>
        </div>

        {{-- Settings --}}
        <div class="section-card">
            <h3 class="section-title"><i class="fa-solid fa-gear"></i> إعدادات الكويز</h3>

            <div class="row g-3 mb-3">
                <div class="col-md-4">
                    <label class="form-label-q">نوع التوقيت *</label>
                    @if(!$canEditContent)
                        <input type="hidden" name="timer_mode" value="{{ $quiz->timer_mode ?? 'quiz' }}">
                    @endif
                    <select name="timer_mode" class="form-select form-select-q" x-model="timerMode" required {{ !$canEditContent ? 'disabled' : '' }}>
                        <option value="quiz">وقت عام للاختبار بالكامل</option>
                        <option value="per_question">وقت مستقل لكل سؤال</option>
                    </select>
                </div>
                <div class="col-md-4" x-show="timerMode === 'quiz'">
                    <label class="form-label-q">مدة الكويز (دقائق)</label>
                    <input type="number" name="time_limit_minutes" class="form-control form-control-q" value="{{ $quiz->time_limit_minutes }}" min="1" max="300" :required="timerMode === 'quiz'">
                </div>
                <div class="col-md-4">
                    <label class="form-label-q">وقت النشر</label>
                    <input type="datetime-local" name="scheduled_at" class="form-control form-control-q" value="{{ $quiz->scheduled_at ? $quiz->scheduled_at->format('Y-m-d\TH:i') : '' }}">
                </div>
                <div class="col-md-4">
                    <label class="form-label-q">وقت الإغلاق</label>
                    <input type="datetime-local" name="closes_at" class="form-control form-control-q" value="{{ $quiz->closes_at ? $quiz->closes_at->format('Y-m-d\TH:i') : '' }}">
                </div>
            </div>

            <div class="row g-3 mb-3">
                <div class="col-md-6">
                    <label class="form-label-q">مشاركة النتائج</label>
                    <select name="results_visibility" class="form-select form-select-q" required>
                        <option value="hidden" {{ $quiz->results_visibility == 'hidden' ? 'selected' : '' }}>مخفية (لن تظهر للطلاب)</option>
                        <option value="individual" {{ $quiz->results_visibility == 'individual' ? 'selected' : '' }}>للطالب فقط (كل طالب يرى نتيجته)</option>
                        <option value="public" {{ $quiz->results_visibility == 'public' ? 'selected' : '' }}>عامة (تظهر لكل الدفعة)</option>
                    </select>
                </div>
            </div>

            <div class="toggle-group">
                <div class="toggle-item">
                    <input type="checkbox" name="shuffle_questions" value="1" id="shuffle_q" class="form-check-input" {{ $quiz->shuffle_questions ? 'checked' : '' }}>
                    <label for="shuffle_q">خلط ترتيب الأسئلة</label>
                </div>
                <div class="toggle-item">
                    <input type="checkbox" name="shuffle_options" value="1" id="shuffle_o" class="form-check-input" {{ $quiz->shuffle_options ? 'checked' : '' }}>
                    <label for="shuffle_o">خلط ترتيب الاختيارات</label>
                </div>
                <div class="toggle-item">
                    <input type="checkbox" name="show_correct_answers" value="1" id="show_answers" class="form-check-input" {{ $quiz->show_correct_answers ? 'checked' : '' }}>
                    <label for="show_answers">إظهار الإجابات الصحيحة</label>
                </div>
                <div class="toggle-item">
                    <input type="checkbox" name="show_correction_notes" value="1" id="show_notes" class="form-check-input" {{ $quiz->show_correction_notes ? 'checked' : '' }}>
                    <label for="show_notes">إظهار ملاحظات التصحيح</label>
                </div>
                <div class="toggle-item">
                    <input type="checkbox" name="notify_students" value="1" id="notify_s" class="form-check-input" {{ $quiz->notify_students ? 'checked' : '' }}>
                    <label for="notify_s">تنبيه الطلاب قبل النشر</label>
                </div>
                <div class="toggle-item">
                    <input type="checkbox" name="show_countdown" value="1" id="show_cd" class="form-check-input" {{ $quiz->show_countdown ? 'checked' : '' }}>
                    <label for="show_cd">إظهار عد تنازلي</label>
                </div>
                <div class="toggle-item">
                    <input type="checkbox" name="use_access_code" value="1" id="use_access_code" class="form-check-input" {{ $quiz->models->whereNotNull('access_code')->count() > 0 ? 'checked' : '' }} {{ !$canEditContent ? 'disabled' : '' }}>
                    <label for="use_access_code">يتطلب رمز دخول</label>
                </div>
            </div>
        </div>

        {{-- Models & Questions (Only if canEditContent) --}}
        <div class="section-card" x-show="canEditContent">
            <h3 class="section-title"><i class="fa-solid fa-layer-group"></i> النماذج والأسئلة</h3>

            <template x-for="(model, modelIndex) in models" :key="modelIndex">
                <div class="model-card">
                    <div class="model-card-header">
                        <span class="model-card-title">
                            <i class="fa-solid fa-file-alt"></i>
                            <span x-text="'نموذج ' + (modelIndex + 1)"></span>
                        </span>
                        <div style="display: flex; gap: 0.5rem; align-items: center;">
                            <input type="text" :name="'models[' + modelIndex + '][name]'" class="form-control form-control-q" style="width: 150px;" x-model="model.name" placeholder="اسم النموذج" required>
                            <button type="button" class="btn-remove" @click="removeModel(modelIndex)" x-show="models.length > 1" title="حذف النموذج">
                                <i class="fa-solid fa-times"></i>
                            </button>
                        </div>
                    </div>

                    <template x-for="(question, qIndex) in model.questions" :key="qIndex">
                        <div class="question-card">
                            <div class="question-card-header">
                                <span class="question-number" x-text="'السؤال ' + (qIndex + 1)"></span>
                                <div style="display: flex; gap: 0.5rem; align-items: center;">
                                    <input type="hidden" :name="'models[' + modelIndex + '][questions][' + qIndex + '][question_type]'" value="multiple_choice">
                                    <input type="number" :name="'models[' + modelIndex + '][questions][' + qIndex + '][score]'" class="form-control form-control-q" style="width: 80px;" x-model="question.score" step="0.5">
                                    <input type="number" :name="'models[' + modelIndex + '][questions][' + qIndex + '][time_limit_seconds]'" class="form-control form-control-q" style="width: 120px;" x-model="question.time_limit_seconds" min="1" placeholder="ثواني/سؤال" x-show="timerMode === 'per_question'" :required="timerMode === 'per_question'">
                                    <button type="button" class="btn-remove" @click="removeQuestion(modelIndex, qIndex)" x-show="model.questions.length > 1">
                                        <i class="fa-solid fa-trash-can"></i>
                                    </button>
                                </div>
                            </div>

                            <textarea :name="'models[' + modelIndex + '][questions][' + qIndex + '][question_text]'" class="form-control form-control-q mb-3" rows="2" x-model="question.text" required></textarea>

                            <template x-for="(option, oIndex) in question.options" :key="oIndex">
                                <div class="option-row">
                                    <input type="radio" :name="'models[' + modelIndex + '][questions][' + qIndex + '][correct_option]'" :value="oIndex" class="correct-radio" :checked="option.is_correct" @change="setCorrectOption(modelIndex, qIndex, oIndex)">
                                    <input type="text" :name="'models[' + modelIndex + '][questions][' + qIndex + '][options][' + oIndex + '][option_text]'" class="form-control form-control-q" x-model="option.text" required>
                                    <input type="hidden" :name="'models[' + modelIndex + '][questions][' + qIndex + '][options][' + oIndex + '][is_correct]'" :value="option.is_correct ? '1' : '0'">
                                    <button type="button" class="btn-remove" @click="removeOption(modelIndex, qIndex, oIndex)" x-show="question.options.length > 2">
                                        <i class="fa-solid fa-times"></i>
                                    </button>
                                </div>
                            </template>
                            <button type="button" class="btn-add mt-2" @click="addOption(modelIndex, qIndex)"><i class="fa-solid fa-plus"></i> اختيار جديد</button>

                            <div class="row g-2 mt-2">
                                <div class="col-md-6"><input type="text" :name="'models[' + modelIndex + '][questions][' + qIndex + '][correction_note]'" class="form-control form-control-q" placeholder="ملاحظة التصحيح" x-model="question.correction_note"></div>
                                <div class="col-md-6"><input type="text" :name="'models[' + modelIndex + '][questions][' + qIndex + '][info_source]'" class="form-control form-control-q" placeholder="مصدر المعلومة" x-model="question.info_source"></div>
                            </div>
                        </div>
                    </template>
                    <button type="button" class="btn-add" @click="addQuestion(modelIndex)"><i class="fa-solid fa-plus"></i> سؤال جديد</button>
                </div>
            </template>
            <button type="button" class="btn-add w-100 justify-content-center p-3" @click="addModel()"><i class="fa-solid fa-layer-group"></i> نموذج جديد</button>
        </div>

        {{-- Actions --}}
        <div class="section-card">
            <div class="d-flex justify-content-between align-items-center">
                <a href="{{ route('doctor.quizzes.show', $quiz) }}" class="btn-back"><i class="fa-solid fa-arrow-right me-1"></i> إلغاء</a>
                <div style="display: flex; gap: 0.75rem;">
                    <button type="submit" class="btn-submit-quiz"><i class="fa-solid fa-save"></i> حفظ التعديلات</button>
                </div>
            </div>
        </div>
    </form>
</div>

@push('scripts')
<script>
function quizBuilder() {
    // Initial data from server (prepared in controller)
    const initialModels = @json($initialModels);

    return {
        timerMode: @json($quiz->timer_mode ?? 'quiz'),
        models: initialModels || [],
        canEditContent: @json($canEditContent),

        addModel() {
            if (!this.canEditContent) return;
            const names = ['أ', 'ب', 'ج', 'د', 'هـ', 'و', 'ز'];
            const idx = this.models.length;
            this.models.push({
                name: 'نموذج ' + (names[idx] || (idx + 1)),
                questions: [{ text: '', score: 1, time_limit_seconds: '', options: [ { text: '', is_correct: true }, { text: '', is_correct: false } ] }]
            });
        },
        removeModel(index) { if (this.canEditContent && this.models.length > 1) this.models.splice(index, 1); },
        addQuestion(mIdx) { if (this.canEditContent) this.models[mIdx].questions.push({ text: '', score: 1, time_limit_seconds: '', options: [ { text: '', is_correct: true }, { text: '', is_correct: false } ] }); },
        removeQuestion(mIdx, qIdx) { if (this.canEditContent && this.models[mIdx].questions.length > 1) this.models[mIdx].questions.splice(qIdx, 1); },
        addOption(mIdx, qIdx) { if (this.canEditContent) this.models[mIdx].questions[qIdx].options.push({ text: '', is_correct: false }); },
        removeOption(mIdx, qIdx, oIdx) {
            if (!this.canEditContent) return;
            const opts = this.models[mIdx].questions[qIdx].options;
            if (opts.length > 2) {
                const wasCorrect = opts[oIdx].is_correct;
                opts.splice(oIdx, 1);
                if (wasCorrect) opts[0].is_correct = true;
            }
        },
        setCorrectOption(mIdx, qIdx, oIdx) {
            if (!this.canEditContent) return;
            this.models[mIdx].questions[qIdx].options.forEach((opt, i) => opt.is_correct = (i === oIdx));
        },
        handleSubmit(event) {
            if (!this.canEditContent) return true;
            // validation logic similar to create...
            return true;
        }
    };
}
</script>
@endpush
@endsection
