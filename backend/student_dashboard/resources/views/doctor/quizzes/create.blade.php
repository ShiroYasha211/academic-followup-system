@extends('layouts.doctor')

@section('title', 'كويز جديد')

@section('content')
<style>
    .qbuilder-container { max-width: 900px; margin: 0 auto; }

    .qbuilder-header {
        background: linear-gradient(135deg, #059669 0%, #10b981 100%);
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

    .section-title i { color: #059669; }

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
        border-color: #059669;
        box-shadow: 0 0 0 4px rgba(5,150,105,0.1);
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
        color: #059669;
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
        color: #059669;
        background: #d1fae5;
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
        accent-color: #059669;
        cursor: pointer;
    }

    .option-label-correct {
        font-size: 0.75rem;
        color: #64748b;
        font-weight: 600;
    }

    /* Buttons */
    .btn-add {
        background: #d1fae5;
        color: #059669;
        border: 2px dashed #6ee7b7;
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

    .btn-add:hover { background: #a7f3d0; border-color: #059669; }

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
        background: linear-gradient(135deg, #059669, #10b981);
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

    .btn-submit-quiz:hover { transform: translateY(-2px); box-shadow: 0 10px 25px rgba(5,150,105,0.3); color: white; }

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

    @media (max-width: 768px) {
        .qbuilder-header { padding: 1.5rem; }
        .qbuilder-header h1 { font-size: 1.5rem; }
        .toggle-group { grid-template-columns: 1fr; }
    }
</style>

<div class="qbuilder-container" x-data="quizBuilder()">
    <div class="qbuilder-header">
        <div class="qbuilder-header-content">
            <h1><i class="fa-solid fa-plus-circle me-2"></i>كويز جديد</h1>
            <p>أنشئ كويز جديد مع نماذج وأسئلة متعددة</p>
        </div>
    </div>

    <form action="{{ route('doctor.quizzes.store') }}" method="POST" @submit="handleSubmit($event)">
        @csrf

        {{-- Basic Info --}}
        <div class="section-card">
            <h3 class="section-title"><i class="fa-solid fa-info-circle"></i> معلومات الكويز</h3>

            <div class="row g-3">
                <div class="col-md-6">
                    <label class="form-label-q">المادة *</label>
                    <select name="subject_id" class="form-select form-select-q" required>
                        <option value="">— اختر المادة —</option>
                        @foreach($subjects as $subject)
                        <option value="{{ $subject->id }}">{{ $subject->name }} — {{ $subject->level->name ?? '' }}</option>
                        @endforeach
                    </select>
                </div>
                <div class="col-md-6">
                    <label class="form-label-q">عنوان الكويز *</label>
                    <input type="text" name="title" class="form-control form-control-q" placeholder="مثال: كويز الوحدة الأولى..." required>
                </div>
                <div class="col-12">
                    <label class="form-label-q">وصف (اختياري)</label>
                    <textarea name="description" class="form-control form-control-q" rows="2" placeholder="وصف مختصر للكويز..."></textarea>
                </div>
            </div>
        </div>

        {{-- Settings --}}
        <div class="section-card">
            <h3 class="section-title"><i class="fa-solid fa-gear"></i> إعدادات الكويز</h3>

            <div class="row g-3 mb-3">
                <div class="col-md-4">
                    <label class="form-label-q">نوع التوقيت *</label>
                    <select name="timer_mode" class="form-select form-select-q" x-model="timerMode" required>
                        <option value="quiz">وقت عام للاختبار بالكامل</option>
                        <option value="per_question">وقت مستقل لكل سؤال</option>
                    </select>
                </div>
                <div class="col-md-4" x-show="timerMode === 'quiz'">
                    <label class="form-label-q">مدة الكويز (دقائق)</label>
                    <input type="number" name="time_limit_minutes" class="form-control form-control-q" placeholder="مثال: 30" min="1" max="300" :required="timerMode === 'quiz'">
                </div>
                <div class="col-md-4">
                    <label class="form-label-q">وقت النشر</label>
                    <input type="datetime-local" name="scheduled_at" class="form-control form-control-q">
                </div>
                <div class="col-md-4">
                    <label class="form-label-q">وقت الإغلاق</label>
                    <input type="datetime-local" name="closes_at" class="form-control form-control-q">
                </div>
            </div>

            <div class="row g-3 mb-3">
                <div class="col-md-6">
                    <label class="form-label-q">مشاركة النتائج</label>
                    <select name="results_visibility" class="form-select form-select-q" required>
                        <option value="hidden">مخفية (لن تظهر للطلاب)</option>
                        <option value="individual">للطالب فقط (كل طالب يرى نتيجته)</option>
                        <option value="public">عامة (تظهر لكل الدفعة)</option>
                    </select>
                </div>
            </div>

            <div class="toggle-group">
                <div class="toggle-item">
                    <input type="checkbox" name="shuffle_questions" value="1" id="shuffle_q" class="form-check-input">
                    <label for="shuffle_q">خلط ترتيب الأسئلة</label>
                </div>
                <div class="toggle-item">
                    <input type="checkbox" name="shuffle_options" value="1" id="shuffle_o" class="form-check-input" checked>
                    <label for="shuffle_o">خلط ترتيب الاختيارات</label>
                </div>
                <div class="toggle-item">
                    <input type="checkbox" name="show_correct_answers" value="1" id="show_answers" class="form-check-input">
                    <label for="show_answers">إظهار الإجابات الصحيحة</label>
                </div>
                <div class="toggle-item">
                    <input type="checkbox" name="show_correction_notes" value="1" id="show_notes" class="form-check-input" checked>
                    <label for="show_notes">إظهار ملاحظات التصحيح</label>
                </div>
                <div class="toggle-item">
                    <input type="checkbox" name="notify_students" value="1" id="notify_s" class="form-check-input">
                    <label for="notify_s">تنبيه الطلاب بالكويز قبل نشره</label>
                </div>
                <div class="toggle-item">
                    <input type="checkbox" name="show_countdown" value="1" id="show_cd" class="form-check-input" checked>
                    <label for="show_cd">إظهار عد تنازلي للطلاب</label>
                </div>
                <div class="toggle-item">
                    <input type="checkbox" name="use_access_code" value="1" id="use_access_code" class="form-check-input">
                    <label for="use_access_code">يتطلب رمز دخول</label>
                </div>
            </div>
        </div>

        {{-- Models & Questions --}}
        <div class="section-card">
            <h3 class="section-title"><i class="fa-solid fa-layer-group"></i> النماذج والأسئلة</h3>

            <template x-for="(model, modelIndex) in models" :key="modelIndex">
                <div class="model-card">
                    <div class="model-card-header">
                        <span class="model-card-title">
                            <i class="fa-solid fa-file-alt"></i>
                            <span x-text="'نموذج ' + (modelIndex + 1)"></span>
                        </span>
                        <div style="display: flex; gap: 0.5rem; align-items: center;">
                            <input type="text" :name="'models[' + modelIndex + '][name]'" class="form-control form-control-q" style="width: 150px; padding: 0.4rem 0.75rem; font-size: 0.85rem;" x-model="model.name" placeholder="اسم النموذج" required>
                            <button type="button" class="btn-remove" @click="removeModel(modelIndex)" x-show="models.length > 1" title="حذف النموذج">
                                <i class="fa-solid fa-times" style="font-size: 1.1rem;"></i>
                            </button>
                        </div>
                    </div>

                    {{-- Questions --}}
                    <template x-for="(question, qIndex) in model.questions" :key="qIndex">
                        <div class="question-card">
                            <div class="question-card-header">
                                <span class="question-number" x-text="'السؤال ' + (qIndex + 1)"></span>
                                <div style="display: flex; gap: 0.5rem; align-items: center;">
                                    <input type="hidden" :name="'models[' + modelIndex + '][questions][' + qIndex + '][question_type]'" value="multiple_choice">
                                    <input type="number" :name="'models[' + modelIndex + '][questions][' + qIndex + '][score]'" class="form-control form-control-q" style="width: 80px; padding: 0.3rem 0.5rem; font-size: 0.8rem;" placeholder="الدرجة" x-model="question.score" min="0" step="0.5">
                                    <input type="number" :name="'models[' + modelIndex + '][questions][' + qIndex + '][time_limit_seconds]'" class="form-control form-control-q" style="width: 120px; padding: 0.3rem 0.5rem; font-size: 0.8rem;" placeholder="ثواني/سؤال" x-model="question.time_limit_seconds" min="1" x-show="timerMode === 'per_question'" :required="timerMode === 'per_question'">
                                    <button type="button" class="btn-remove" @click="removeQuestion(modelIndex, qIndex)" x-show="model.questions.length > 1" title="حذف السؤال">
                                        <i class="fa-solid fa-trash-can"></i>
                                    </button>
                                </div>
                            </div>

                            <div class="mb-3">
                                <textarea :name="'models[' + modelIndex + '][questions][' + qIndex + '][question_text]'" class="form-control form-control-q" rows="2" placeholder="اكتب نص السؤال هنا..." x-model="question.text" required></textarea>
                            </div>

                            <div class="mb-2">
                                <label class="form-label-q" style="font-size: 0.8rem;">الاختيارات <small class="text-muted">(حدد الإجابة الصحيحة)</small></label>
                                <template x-for="(option, oIndex) in question.options" :key="oIndex">
                                    <div class="option-row">
                                        <input type="radio"
                                            :name="'models[' + modelIndex + '][questions][' + qIndex + '][correct_option]'"
                                            :value="oIndex"
                                            class="correct-radio"
                                            :checked="option.is_correct"
                                            @change="setCorrectOption(modelIndex, qIndex, oIndex)">
                                        <input type="text"
                                            :name="'models[' + modelIndex + '][questions][' + qIndex + '][options][' + oIndex + '][option_text]'"
                                            class="form-control form-control-q"
                                            style="padding: 0.5rem 0.75rem; font-size: 0.85rem;"
                                            x-model="option.text"
                                            :placeholder="'الاختيار ' + (oIndex + 1)"
                                            required>
                                        <input type="hidden"
                                            :name="'models[' + modelIndex + '][questions][' + qIndex + '][options][' + oIndex + '][is_correct]'"
                                            :value="option.is_correct ? '1' : '0'">
                                        <button type="button" class="btn-remove" @click="removeOption(modelIndex, qIndex, oIndex)" x-show="question.options.length > 2" title="حذف">
                                            <i class="fa-solid fa-times"></i>
                                        </button>
                                    </div>
                                </template>
                                <button type="button" class="btn-add mt-2" style="font-size: 0.75rem; padding: 0.4rem 0.8rem;" @click="addOption(modelIndex, qIndex)">
                                    <i class="fa-solid fa-plus"></i> اختيار جديد
                                </button>
                            </div>

                            <div class="row g-2 mt-2">
                                <div class="col-md-6">
                                    <input type="text" :name="'models[' + modelIndex + '][questions][' + qIndex + '][correction_note]'" class="form-control form-control-q" style="padding: 0.4rem 0.75rem; font-size: 0.8rem;" placeholder="ملاحظة التصحيح (اختياري)">
                                </div>
                                <div class="col-md-6">
                                    <input type="text" :name="'models[' + modelIndex + '][questions][' + qIndex + '][info_source]'" class="form-control form-control-q" style="padding: 0.4rem 0.75rem; font-size: 0.8rem;" placeholder="مصدر المعلومة (اختياري)">
                                </div>
                            </div>
                        </div>
                    </template>

                    <button type="button" class="btn-add" @click="addQuestion(modelIndex)">
                        <i class="fa-solid fa-plus"></i> سؤال جديد
                    </button>
                </div>
            </template>

            <button type="button" class="btn-add" @click="addModel()" style="width: 100%; justify-content: center; padding: 1rem;">
                <i class="fa-solid fa-layer-group"></i> إضافة نموذج جديد
            </button>
        </div>

        {{-- Actions --}}
        <div class="section-card">
            <div class="d-flex justify-content-between align-items-center">
                <a href="{{ route('doctor.quizzes.index') }}" class="btn-back">
                    <i class="fa-solid fa-arrow-right me-1"></i> رجوع
                </a>
                <div style="display: flex; gap: 0.75rem;">
                    <span class="text-muted" style="align-self: center; font-size: 0.85rem;" x-text="totalQuestionsText"></span>
                    <button type="submit" class="btn-submit-quiz">
                        <i class="fa-solid fa-paper-plane"></i> إنشاء الكويز
                    </button>
                </div>
            </div>
        </div>
    </form>
</div>

@push('scripts')
<script>
function quizBuilder() {
    return {
        timerMode: 'quiz',
        models: [
            {
                name: 'نموذج أ',
                questions: [
                    {
                        text: '',
                        score: 1,
                        time_limit_seconds: '',
                        options: [
                            { text: '', is_correct: true },
                            { text: '', is_correct: false },
                            { text: '', is_correct: false },
                            { text: '', is_correct: false },
                        ]
                    }
                ]
            }
        ],

        get totalQuestionsText() {
            let total = 0;
            this.models.forEach(m => total += m.questions.length);
            return `${total} سؤال في ${this.models.length} نموذج`;
        },

        addModel() {
            const names = ['أ', 'ب', 'ج', 'د', 'هـ', 'و', 'ز'];
            const idx = this.models.length;
            this.models.push({
                name: 'نموذج ' + (names[idx] || (idx + 1)),
                questions: [
                    {
                        text: '',
                        score: 1,
                        time_limit_seconds: '',
                        options: [
                            { text: '', is_correct: true },
                            { text: '', is_correct: false },
                            { text: '', is_correct: false },
                            { text: '', is_correct: false },
                        ]
                    }
                ]
            });
        },

        removeModel(modelIndex) {
            if (this.models.length > 1) {
                this.models.splice(modelIndex, 1);
            }
        },

        addQuestion(modelIndex) {
            this.models[modelIndex].questions.push({
                text: '',
                score: 1,
                time_limit_seconds: '',
                options: [
                    { text: '', is_correct: true },
                    { text: '', is_correct: false },
                    { text: '', is_correct: false },
                    { text: '', is_correct: false },
                ]
            });
        },

        removeQuestion(modelIndex, qIndex) {
            if (this.models[modelIndex].questions.length > 1) {
                this.models[modelIndex].questions.splice(qIndex, 1);
            }
        },

        addOption(modelIndex, qIndex) {
            this.models[modelIndex].questions[qIndex].options.push({
                text: '',
                is_correct: false,
            });
        },

        removeOption(modelIndex, qIndex, oIndex) {
            const opts = this.models[modelIndex].questions[qIndex].options;
            if (opts.length > 2) {
                const wasCorrect = opts[oIndex].is_correct;
                opts.splice(oIndex, 1);
                if (wasCorrect && opts.length > 0) {
                    opts[0].is_correct = true;
                }
            }
        },

        setCorrectOption(modelIndex, qIndex, oIndex) {
            this.models[modelIndex].questions[qIndex].options.forEach((opt, i) => {
                opt.is_correct = (i === oIndex);
            });
        },

        handleSubmit(event) {
            // Validate at least one correct option per question
            for (let m = 0; m < this.models.length; m++) {
                for (let q = 0; q < this.models[m].questions.length; q++) {
                    const question = this.models[m].questions[q];
                    if (!question.text.trim()) {
                        alert(`الرجاء كتابة نص السؤال ${q + 1} في النموذج ${m + 1}`);
                        event.preventDefault();
                        return;
                    }
                    const hasCorrect = question.options.some(o => o.is_correct);
                    if (!hasCorrect) {
                        alert(`الرجاء تحديد الإجابة الصحيحة للسؤال ${q + 1} في النموذج ${m + 1}`);
                        event.preventDefault();
                        return;
                    }
                    const emptyOptions = question.options.filter(o => !o.text.trim());
                    if (emptyOptions.length > 0) {
                        alert(`الرجاء كتابة جميع الاختيارات للسؤال ${q + 1} في النموذج ${m + 1}`);
                        event.preventDefault();
                        return;
                    }
                }
            }
        }
    };
}
</script>
@endpush
@endsection
