@extends('layouts.admin')

@section('title', 'كويز إداري جديد')

@section('content')
<style>
    .qbuilder-container { max-width: 1000px; margin: 0 auto; }
    .qbuilder-header {
        background: linear-gradient(135deg, #0369a1 0%, #0ea5e9 100%);
        border-radius: 20px; padding: 2rem; color: white; margin-bottom: 2rem;
    }
    .section-card {
        background: white; border-radius: 16px; border: 1px solid #e2e8f0;
        padding: 1.5rem; margin-bottom: 1.5rem; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05);
    }
    .section-title { font-size: 1.1rem; font-weight: 800; color: #1e293b; margin-bottom: 1.25rem; display: flex; align-items: center; gap: 0.5rem; }
    .section-title i { color: #0ea5e9; }
    .form-label-q { font-weight: 700; color: #334155; margin-bottom: 0.4rem; font-size: 0.85rem; }
    .form-control-q, .form-select-q { border: 2px solid #e2e8f0; border-radius: 12px; padding: 0.6rem 0.8rem; font-size: 0.85rem; }
    .model-card { border: 2px solid #e2e8f0; border-radius: 16px; padding: 1.25rem; margin-bottom: 1rem; background: #fafafa; }
    .question-card { border: 1px solid #e2e8f0; border-radius: 12px; padding: 1rem; margin-bottom: 0.75rem; background: white; }
    .btn-add { background: #e0f2fe; color: #0369a1; border: 2px dashed #7dd3fc; padding: 0.5rem 1rem; border-radius: 10px; font-weight: 700; font-size: 0.8rem; cursor: pointer; }
    .btn-remove { background: none; border: none; color: #94a3b8; cursor: pointer; }
    .btn-remove:hover { color: #ef4444; }
    .target-row { background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 12px; padding: 1rem; margin-bottom: 0.5rem; display: flex; gap: 0.5rem; align-items: flex-end; }
</style>

<div class="qbuilder-container" x-data="adminQuizBuilder()">
    <div class="qbuilder-header">
        <h1 class="fw-bold mb-1"><i class="fa-solid fa-plus-circle me-2"></i>كويز إداري جديد</h1>
        <p class="mb-0 opacity-75">أنشئ اختباراً عاماً أو مسابقة لقطاع أكاديمي محدد</p>
    </div>

    <form action="{{ route('admin.quizzes.store') }}" method="POST">
        @csrf

        {{-- Basic Settings --}}
        <div class="section-card">
            <h3 class="section-title"><i class="fa-solid fa-gear"></i> الإعدادات الأساسية</h3>
            <div class="row g-3">
                <div class="col-md-6">
                    <label class="form-label-q">العنوان *</label>
                    <input type="text" name="title" class="form-control-q w-100" placeholder="مثال: مسابقة البرمجة الكبرى" required>
                </div>
                <div class="col-md-6">
                    <label class="form-label-q">المادة المرتبطة (اختياري)</label>
                    <select name="subject_id" class="form-select-q w-100">
                        <option value="">— ليست مرتبطة بمادة محددة —</option>
                        @foreach($subjects as $subject)
                            <option value="{{ $subject->id }}">{{ $subject->name }} ({{ $subject->level->name ?? '' }})</option>
                        @endforeach
                    </select>
                </div>
                <div class="col-12">
                    <label class="form-label-q">الوصف</label>
                    <textarea name="description" class="form-control-q w-100" rows="2"></textarea>
                </div>
                <div class="col-md-3">
                    <label class="form-label-q">نوع التوقيت *</label>
                    <select name="timer_mode" class="form-select-q w-100" x-model="timerMode" required>
                        <option value="quiz">وقت عام للاختبار</option>
                        <option value="per_question">وقت لكل سؤال</option>
                    </select>
                </div>
                <div class="col-md-3" x-show="timerMode === 'quiz'">
                    <label class="form-label-q">مدة الكويز (دقائق)</label>
                    <input type="number" name="time_limit_minutes" class="form-control-q w-100" min="1" max="300" :required="timerMode === 'quiz'">
                </div>
                <div class="col-md-3">
                    <label class="form-label-q">وقت النشر</label>
                    <input type="datetime-local" name="scheduled_at" class="form-control-q w-100">
                </div>
                <div class="col-md-3">
                    <label class="form-label-q">وقت الإغلاق</label>
                    <input type="datetime-local" name="closes_at" class="form-control-q w-100">
                </div>
                <div class="col-md-3">
                    <label class="form-label-q">مشاركة النتائج</label>
                    <select name="results_visibility" class="form-select-q w-100">
                        <option value="hidden">مخفية</option>
                        <option value="individual" selected>فردية</option>
                        <option value="public">عامة</option>
                    </select>
                </div>
            </div>
        </div>

        {{-- Quiz Options Toggles --}}
        <div class="section-card">
            <h3 class="section-title"><i class="fa-solid fa-toggle-on"></i> خيارات الكويز</h3>
            <div class="row g-3">
                <div class="col-md-4">
                    <div class="form-check form-switch m-0">
                        <input class="form-check-input" type="checkbox" name="shuffle_questions" value="1" id="shuffle_questions">
                        <label class="form-check-label fw-bold small" for="shuffle_questions">خلط ترتيب الأسئلة</label>
                    </div>
                </div>
                <div class="col-md-4">
                    <div class="form-check form-switch m-0">
                        <input class="form-check-input" type="checkbox" name="shuffle_options" value="1" id="shuffle_options" checked>
                        <label class="form-check-label fw-bold small" for="shuffle_options">خلط ترتيب الاختيارات</label>
                    </div>
                </div>
                <div class="col-md-4">
                    <div class="form-check form-switch m-0">
                        <input class="form-check-input" type="checkbox" name="show_correct_answers" value="1" id="show_correct_answers">
                        <label class="form-check-label fw-bold small" for="show_correct_answers">إظهار الإجابات الصحيحة</label>
                    </div>
                </div>
                <div class="col-md-4">
                    <div class="form-check form-switch m-0">
                        <input class="form-check-input" type="checkbox" name="show_correction_notes" value="1" id="show_correction_notes" checked>
                        <label class="form-check-label fw-bold small" for="show_correction_notes">إظهار ملاحظات التصحيح</label>
                    </div>
                </div>
                <div class="col-md-4">
                    <div class="form-check form-switch m-0">
                        <input class="form-check-input" type="checkbox" name="notify_students" value="1" id="notify_students">
                        <label class="form-check-label fw-bold small" for="notify_students">تنبيه الطلاب بالكويز</label>
                    </div>
                </div>
                <div class="col-md-4">
                    <div class="form-check form-switch m-0">
                        <input class="form-check-input" type="checkbox" name="show_countdown" value="1" id="show_countdown" checked>
                        <label class="form-check-label fw-bold small" for="show_countdown">إظهار عد تنازلي للطلاب</label>
                    </div>
                </div>
                <div class="col-md-4" x-show="timerMode === 'quiz'">
                    <div class="form-check form-switch m-0">
                        <input class="form-check-input" type="checkbox" name="allow_question_backtracking" value="1" id="allow_question_backtracking" checked>
                        <label class="form-check-label fw-bold small" for="allow_question_backtracking">السماح بالرجوع للأسئلة</label>
                    </div>
                </div>
                <div class="col-md-4">
                    <div class="form-check form-switch m-0">
                        <input class="form-check-input" type="checkbox" name="use_access_code" value="1" id="use_access_code" x-model="use_access_code">
                        <label class="form-check-label fw-bold small" for="use_access_code">كويز برمز دخول (خاص)</label>
                    </div>
                </div>
                <div class="col-md-8" x-show="use_access_code">
                    <div class="alert alert-info py-2 px-3 m-0 small">
                        <i class="fa-solid fa-info-circle me-1"></i> كويز برمز دخول: يرجى كتابة رمز دخول مخصص لكل نموذج أدناه.
                    </div>
                </div>
            </div>
        </div>

        {{-- Targeting Section --}}
        <div class="section-card">
            <h3 class="section-title"><i class="fa-solid fa-bullseye"></i> استهداف الطلاب</h3>
            <p class="text-muted small mb-3">حدد الفئات التي سيظهر لها هذا الكويز. اترك الخيارات فارغة لجعل الاستهداف عاماً.</p>
            
            <template x-for="(target, tIdx) in targets" :key="tIdx">
                <div class="target-row">
                    <div class="flex-fill">
                        <label class="form-label-q">الجامعة</label>
                        <select :name="'targets['+tIdx+'][university_id]'" class="form-select-q w-100" x-model="target.university_id">
                            <option value="">كل الجامعات</option>
                            @foreach($universities as $uni) <option value="{{ $uni->id }}">{{ $uni->name }}</option> @endforeach
                        </select>
                    </div>
                    <div class="flex-fill">
                        <label class="form-label-q">الكلية</label>
                        <select :name="'targets['+tIdx+'][college_id]'" class="form-select-q w-100" x-model="target.college_id">
                            <option value="">كل الكليات</option>
                            @foreach($colleges as $col) <option value="{{ $col->id }}">{{ $col->name }}</option> @endforeach
                        </select>
                    </div>
                    <div class="flex-fill">
                        <label class="form-label-q">التخصص</label>
                        <select :name="'targets['+tIdx+'][major_id]'" class="form-select-q w-100" x-model="target.major_id">
                            <option value="">كل التخصصات</option>
                            @foreach($majors as $maj) <option value="{{ $maj->id }}">{{ $maj->name }}</option> @endforeach
                        </select>
                    </div>
                    <div class="flex-fill">
                        <label class="form-label-q">المستوى</label>
                        <select :name="'targets['+tIdx+'][level_id]'" class="form-select-q w-100" x-model="target.level_id">
                            <option value="">كل المستويات</option>
                            @foreach($levels as $lev) <option value="{{ $lev->id }}">{{ $lev->name }}</option> @endforeach
                        </select>
                    </div>
                    <button type="button" class="btn-remove mb-2" @click="removeTarget(tIdx)" x-show="targets.length > 1"><i class="fa-solid fa-times"></i></button>
                </div>
            </template>
            <button type="button" class="btn-add mt-2" @click="addTarget()"><i class="fa-solid fa-plus"></i> إضافة فئة مستهدفة أخرى</button>
        </div>

        {{-- Quiz Builder Component (Same as Doctor but reusable style) --}}
        <div class="section-card">
            <h3 class="section-title"><i class="fa-solid fa-layer-group"></i> النماذج والأسئلة</h3>
            <template x-for="(model, mIdx) in models" :key="mIdx">
                <div class="model-card">
                    <div class="d-flex justify-content-between align-items-center mb-3 border-bottom pb-2 flex-wrap gap-2">
                        <div class="d-flex align-items-center gap-2 flex-wrap">
                            <span class="badge bg-primary">نموذج <span x-text="mIdx+1"></span></span>
                            <input type="text" :name="'models['+mIdx+'][name]'" class="form-control-q" x-model="model.name" required placeholder="اسم النموذج">
                            
                            <div class="d-flex align-items-center gap-1" x-show="use_access_code">
                                <label class="form-label-q mb-0 ms-2 small">رمز الدخول:</label>
                                <input type="text" :name="'models['+mIdx+'][access_code]'" class="form-control-q text-uppercase" style="width: 120px;" x-model="model.access_code" :required="use_access_code" placeholder="مثال: A123">
                            </div>
                        </div>
                        <button type="button" class="btn-remove" @click="removeModel(mIdx)" x-show="models.length > 1"><i class="fa-solid fa-trash"></i></button>
                    </div>

                    <template x-for="(q, qIdx) in model.questions" :key="qIdx">
                        <div class="question-card">
                            <div class="d-flex justify-content-between mb-2">
                                <span class="fw-bold small text-primary" x-text="'سؤال ' + (qIdx+1)"></span>
                                <div class="d-flex gap-2 align-items-center">
                                    <div class="d-flex align-items-center gap-1">
                                        <label class="form-label-q mb-0 small text-muted">النوع:</label>
                                        <select :name="'models['+mIdx+'][questions]['+qIdx+'][question_type]'" class="form-select-q py-1 px-2" style="font-size: 0.75rem; border-radius: 8px;" x-model="q.question_type" @change="handleTypeChange(mIdx, qIdx)">
                                            <option value="multiple_choice">اختيار من متعدد</option>
                                            <option value="true_false">صح / خطأ</option>
                                        </select>
                                    </div>
                                    <input type="number" :name="'models['+mIdx+'][questions]['+qIdx+'][score]'" class="form-control-q" style="width: 70px;" x-model="q.score" step="0.5">
                                    <input type="number" :name="'models['+mIdx+'][questions]['+qIdx+'][time_limit_seconds]'" class="form-control-q" style="width: 115px;" x-model="q.time_limit_seconds" min="1" placeholder="ثواني" x-show="timerMode === 'per_question'" :required="timerMode === 'per_question'">
                                    <button type="button" class="btn-remove" @click="removeQuestion(mIdx, qIdx)" x-show="model.questions.length > 1"><i class="fa-solid fa-times"></i></button>
                                </div>
                            </div>
                            <textarea :name="'models['+mIdx+'][questions]['+qIdx+'][question_text]'" class="form-control-q w-100 mb-2" placeholder="نص السؤال..." x-model="q.text" required></textarea>
                            <div class="row g-2 mb-2">
                                <div class="col-md-6">
                                    <input type="text" :name="'models['+mIdx+'][questions]['+qIdx+'][correction_note]'" class="form-control-q w-100" placeholder="شرح الإجابة (ملاحظات التصحيح)" x-model="q.correction_note">
                                </div>
                                <div class="col-md-6">
                                    <input type="text" :name="'models['+mIdx+'][questions]['+qIdx+'][info_source]'" class="form-control-q w-100" placeholder="المصدر العلمي (اختياري)" x-model="q.info_source">
                                </div>
                            </div>
                            
                            <template x-for="(opt, oIdx) in q.options" :key="oIdx">
                                <div class="d-flex gap-2 align-items-center mb-1">
                                    <input type="radio" :name="'models['+mIdx+'][questions]['+qIdx+'][correct_radio]'" :checked="opt.is_correct" @change="setCorrect(mIdx, qIdx, oIdx)">
                                    <input type="text" :name="'models['+mIdx+'][questions]['+qIdx+'][options]['+oIdx+'][option_text]'" class="form-control-q flex-fill" x-model="opt.text" required :readonly="q.question_type === 'true_false'">
                                    <input type="hidden" :name="'models['+mIdx+'][questions]['+qIdx+'][options]['+oIdx+'][is_correct]'" :value="opt.is_correct ? '1' : '0'">
                                    <button type="button" class="btn-remove" @click="removeOption(mIdx, qIdx, oIdx)" x-show="q.options.length > 2 && q.question_type !== 'true_false'"><i class="fa-solid fa-times"></i></button>
                                </div>
                            </template>
                            <button type="button" class="btn-add mt-1 py-1 px-2" style="font-size: 0.7rem;" @click="addOption(mIdx, qIdx)" x-show="q.question_type !== 'true_false'"><i class="fa-solid fa-plus"></i> إضافة خيار</button>
                        </div>
                    </template>
                    <button type="button" class="btn-add mt-2" @click="addQuestion(mIdx)"><i class="fa-solid fa-plus"></i> سؤال جديد</button>
                </div>
            </template>
            <button type="button" class="btn-add w-100 justify-content-center p-3" @click="addModel()"><i class="fa-solid fa-layer-group"></i> إضافة نموذج كويز جديد</button>
        </div>

        <div class="section-card text-center d-flex justify-content-between">
            <a href="{{ route('admin.quizzes.index') }}" class="btn btn-light px-4" style="border-radius: 12px;">إلغاء</a>
            <button type="submit" class="btn btn-primary px-5" style="border-radius: 12px; font-weight: 800;">حفظ وإنشاء الكويز</button>
        </div>
    </form>
</div>

@push('scripts')
<script>
function adminQuizBuilder() {
    return {
        timerMode: 'quiz',
        use_access_code: false,
        targets: [{ university_id: '', college_id: '', major_id: '', level_id: '' }],
        models: [{ name: 'نموذج أ', access_code: '', questions: [{ text: '', question_type: 'multiple_choice', score: 1, time_limit_seconds: '', correction_note: '', info_source: '', options: [{ text: '', is_correct: true }, { text: '', is_correct: false }] }] }],
        
        addTarget() { this.targets.push({ university_id: '', college_id: '', major_id: '', level_id: '' }); },
        removeTarget(idx) { this.targets.splice(idx, 1); },
        addModel() { this.models.push({ name: 'نموذج جديد', access_code: '', questions: [{ text: '', question_type: 'multiple_choice', score: 1, time_limit_seconds: '', correction_note: '', info_source: '', options: [{ text: '', is_correct: true }, { text: '', is_correct: false }] }] }); },
        removeModel(idx) { this.models.splice(idx, 1); },
        addQuestion(mIdx) { this.models[mIdx].questions.push({ text: '', question_type: 'multiple_choice', score: 1, time_limit_seconds: '', correction_note: '', info_source: '', options: [{ text: '', is_correct: true }, { text: '', is_correct: false }] }); },
        removeQuestion(mIdx, qIdx) { this.models[mIdx].questions.splice(qIdx, 1); },
        addOption(mIdx, qIdx) { this.models[mIdx].questions[qIdx].options.push({ text: '', is_correct: false }); },
        removeOption(mIdx, qIdx, oIdx) {
            const opts = this.models[mIdx].questions[qIdx].options;
            const wasCorrect = opts[oIdx].is_correct;
            opts.splice(oIdx, 1);
            if (wasCorrect) opts[0].is_correct = true;
        },
        setCorrect(mIdx, qIdx, oIdx) {
            this.models[mIdx].questions[qIdx].options.forEach((opt, i) => opt.is_correct = (i === oIdx));
        },
        handleTypeChange(mIdx, qIdx) {
            const q = this.models[mIdx].questions[qIdx];
            if (q.question_type === 'true_false') {
                q.options = [
                    { text: 'صح', is_correct: true },
                    { text: 'خطأ', is_correct: false }
                ];
            } else {
                q.options = [
                    { text: '', is_correct: true },
                    { text: '', is_correct: false }
                ];
            }
        }
    };
}
</script>
@endpush
@endsection
