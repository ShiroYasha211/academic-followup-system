@extends('layouts.admin')

@section('title', 'رفع ملف جديد للمكتبة المشتركة')

@section('content')
<div class="dashboard-container" style="max-width: 1000px; margin: 0 auto;" x-data="libraryUploader()">
    <!-- Header -->
    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 2.5rem;">
        <div>
            <h1 style="font-size: 1.8rem; font-weight: 800; color: var(--text-primary); margin-bottom: 0.5rem; display: flex; align-items: center; gap: 0.75rem;">
                <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" style="color: var(--primary-color);">
                    <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                    <polyline points="17 8 12 3 7 8"></polyline>
                    <line x1="12" y1="3" x2="12" y2="15"></line>
                </svg>
                رفع مورد تعليمي جديد
            </h1>
            <p style="color: var(--text-secondary); margin: 0; font-size: 1rem;">إضافة ملفات جديدة للمكتبة المشتركة لخدمة الطلاب والزملاء</p>
        </div>
        <a href="{{ route('admin.library.index') }}" 
           style="background: #f1f5f9; color: var(--text-primary); text-decoration: none; padding: 0.75rem 1.5rem; border-radius: 12px; font-weight: 700; display: flex; align-items: center; gap: 0.5rem; transition: all 0.2s;">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                <polyline points="15 18 9 12 15 6"></polyline>
            </svg>
            العودة للمكتبة
        </a>
    </div>

    @if($errors->any())
        <div class="alert alert-danger" style="border-radius: 15px; margin-bottom: 2rem;">
            <ul style="margin: 0; padding-right: 1.5rem;">
                @foreach($errors->all() as $error)
                    <li>{{ $error }}</li>
                @endforeach
            </ul>
        </div>
    @endif

    <form action="{{ route('admin.library.store') }}" method="POST" enctype="multipart/form-data">
        @csrf
        
        <div style="display: grid; grid-template-columns: 1fr 340px; gap: 2rem;">
            <!-- Main Content Card -->
            <div class="card border-0 shadow-sm" style="background: white; border-radius: 25px; padding: 2.5rem;">
                <!-- Academic Hierarchy Selection -->
                <div style="margin-bottom: 2.5rem; padding: 1.5rem; background: #f8fafc; border-radius: 20px; border: 1px solid #f1f5f9;">
                    <h3 style="font-size: 1rem; font-weight: 800; color: var(--primary-color); margin-bottom: 1.5rem; display: flex; align-items: center; gap: 0.5rem;">
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M22 10v6M2 10l10-5 10 5-10 5z"></path><path d="M6 12v5c3 3 9 3 12 0v-5"></path></svg>
                        التبعية الأكاديمية للمورد
                    </h3>

                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 1.25rem; margin-bottom: 1.25rem;">
                        <div>
                            <label class="form-label-custom">الجامعة</label>
                            <select x-model="selectedUniversity" @change="fetchColleges()" class="form-select-custom">
                                <option value="">اختر الجامعة...</option>
                                @foreach($universities as $uni)
                                    <option value="{{ $uni->id }}">{{ $uni->name }}</option>
                                @endforeach
                            </select>
                        </div>
                        <div>
                            <label class="form-label-custom">الكلية</label>
                            <select x-model="selectedCollege" @change="fetchMajors()" :disabled="!selectedUniversity" class="form-select-custom">
                                <option value="">اختر الكلية...</option>
                                <template x-for="college in colleges" :key="college.id">
                                    <option :value="college.id" x-text="college.name"></option>
                                </template>
                            </select>
                        </div>
                    </div>

                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 1.25rem; margin-bottom: 1.25rem;">
                        <div>
                            <label class="form-label-custom">التخصص</label>
                            <select x-model="selectedMajor" @change="fetchLevels()" :disabled="!selectedCollege" class="form-select-custom">
                                <option value="">اختر التخصص...</option>
                                <template x-for="major in majors" :key="major.id">
                                    <option :value="major.id" x-text="major.name"></option>
                                </template>
                            </select>
                        </div>
                        <div>
                            <label class="form-label-custom">المستوى الدراسي</label>
                            <select x-model="selectedLevel" @change="fetchSubjects()" :disabled="!selectedMajor" class="form-select-custom">
                                <option value="">اختر المستوى...</option>
                                <template x-for="level in levels" :key="level.id">
                                    <option :value="level.id" x-text="level.name"></option>
                                </template>
                            </select>
                        </div>
                    </div>

                    <div>
                        <label class="form-label-custom">المادة الدراسية <span style="color:red">*</span></label>
                        <select name="subject_id" x-model="selectedSubject" :disabled="!selectedLevel" class="form-select-custom" required>
                            <option value="">اختر المادة...</option>
                            <template x-for="subject in subjects" :key="subject.id">
                                <option :value="subject.id" x-text="subject.name + (subject.code ? ' ('+subject.code+')' : '')"></option>
                            </template>
                        </select>
                    </div>
                </div>

                <!-- Basic Meta Info -->
                <div style="margin-bottom: 1.5rem;">
                    <label class="form-label-custom">عنوان المورد التعليمي <span style="color:red">*</span></label>
                    <input type="text" name="title" value="{{ old('title') }}" 
                           placeholder="مثال: ملخص محاضرات القلب - الجزء الأول" 
                           class="form-input-custom" required>
                </div>

                <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 1.5rem; margin-bottom: 1.5rem;">
                    <div>
                        <label class="form-label-custom">نوع المحتوى <span style="color:red">*</span></label>
                        <select name="category" class="form-select-custom" required>
                            <option value="lectures">محاضرات</option>
                            <option value="summaries">ملخصات</option>
                            <option value="quizzes">كويزات</option>
                            <option value="exams">نماذج اختبارات</option>
                            <option value="references">مراجع</option>
                            <option value="other">أخرى</option>
                        </select>
                    </div>
                    <div>
                        <label class="form-label-custom">التفصيل (اختياري)</label>
                        <select name="sub_category" class="form-select-custom">
                            <option value="">غير محدد</option>
                            <option value="theoretical">نظري</option>
                            <option value="practical">عملي</option>
                            <option value="seminar">سمنار</option>
                        </select>
                    </div>
                </div>

                <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 1.5rem; margin-bottom: 1.5rem;">
                    <div>
                        <label class="form-label-custom">اسم المحاضر / الدكتور</label>
                        <input type="text" name="lecturer_name" value="{{ old('lecturer_name') }}" class="form-input-custom" placeholder="د. مثال">
                    </div>
                    <div>
                        <label class="form-label-custom">السستم / الفصل <span style="color:red">*</span></label>
                        <input type="text" name="semester_info" value="{{ old('semester_info') }}" class="form-input-custom" placeholder="مثال: CVS, Year 3, Semester 1" required>
                    </div>
                </div>

                <div style="margin-bottom: 1.5rem;">
                    <label class="form-label-custom">وصف إضافي</label>
                    <textarea name="description" rows="3" class="form-input-custom" style="resize: none;" placeholder="أية تفاصيل إضافية حول محتوى الملف..."></textarea>
                </div>
            </div>

            <!-- Sidebar -->
            <div style="display: flex; flex-direction: column; gap: 1.5rem;">
                <!-- File Upload Box -->
                <div class="card border-0 shadow-sm" style="background: white; border-radius: 22px; padding: 1.75rem; border: 2px dashed #e2e8f0; position: relative;">
                    <h3 style="font-size: 0.95rem; font-weight: 800; color: var(--text-primary); margin-bottom: 1.25rem;">ارفق الملف التعليمي <span style="color:red">*</span></h3>
                    
                    <div style="display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 1rem; text-align: center;">
                        <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="1.5" style="margin-bottom: 1rem;">
                            <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                            <polyline points="14 2 14 8 20 8"></polyline>
                            <line x1="12" y1="18" x2="12" y2="12"></line>
                            <line x1="9" y1="15" x2="15" y2="15"></line>
                        </svg>
                        <input type="file" name="file" id="fileInput" class="form-control" style="font-size: 0.85rem;" required>
                        <p style="margin-top: 0.75rem; font-size: 0.75rem; color: var(--text-secondary);">مدعوم: PDF, PPTX, DOCX, ZIP<br>الحد الأقصى: 50MB</p>
                    </div>
                </div>

                <!-- Visibility -->
                <div class="card border-0 shadow-sm" style="background: #f8fafc; border-radius: 20px; padding: 1.5rem;">
                    <h3 style="font-size: 0.95rem; font-weight: 800; color: var(--text-primary); margin-bottom: 1.25rem;">من يستطيع رؤية الملف؟</h3>
                    
                    <div style="display: flex; flex-direction: column; gap: 0.75rem;">
                        <label class="visibility-option">
                            <input type="radio" name="visibility" value="everyone" checked>
                            <span>عام (للجميع بالجامعة)</span>
                        </label>
                        <label class="visibility-option">
                            <input type="radio" name="visibility" value="college">
                            <span>للكلية فقط</span>
                        </label>
                        <label class="visibility-option">
                            <input type="radio" name="visibility" value="batch">
                            <span>لطلاب التخصص والمستوى فقط</span>
                        </label>
                    </div>
                </div>

                <!-- Submit Button -->
                <button type="submit" 
                        class="submit-btn"
                        :disabled="!selectedSubject">
                    نشر المورد الآن
                </button>
            </div>
        </div>
    </form>
</div>

<style>
    .form-label-custom {
        display: block; font-weight: 700; color: var(--text-primary); margin-bottom: 0.6rem; font-size: 0.9rem;
    }
    .form-select-custom, .form-input-custom {
        width: 100%; padding: 0.85rem 1.15rem; border: 2px solid #f1f5f9; border-radius: 12px; font-size: 0.95rem; transition: all 0.2s; background: white;
    }
    .form-select-custom:focus, .form-input-custom:focus {
        border-color: var(--primary-color); outline: none; box-shadow: 0 0 0 4px rgba(79, 70, 229, 0.1);
    }
    .form-select-custom:disabled {
        background: #f1f5f9; cursor: not-allowed; opacity: 0.6;
    }
    .visibility-option {
        display: flex; align-items: center; gap: 0.75rem; padding: 1rem; background: white; border: 2px solid #f1f5f9; border-radius: 12px; cursor: pointer; transition: all 0.2s; font-size: 0.9rem; font-weight: 700;
    }
    .visibility-option:hover { border-color: var(--primary-color); background: #fcfdff; }
    .submit-btn {
        width: 100%; background: var(--primary-color); color: white; border: none; padding: 1.15rem; border-radius: 18px; font-size: 1.1rem; font-weight: 800; cursor: pointer; transition: all 0.3s; box-shadow: 0 10px 15px -3px rgba(79, 70, 229, 0.3);
    }
    .submit-btn:hover:not(:disabled) { transform: translateY(-2px); box-shadow: 0 20px 25px -5px rgba(79, 70, 229, 0.4); }
    .submit-btn:disabled { opacity: 0.5; cursor: not-allowed; transform: none; box-shadow: none; }
</style>

<script>
    function libraryUploader() {
        return {
            selectedUniversity: '',
            selectedCollege: '',
            selectedMajor: '',
            selectedLevel: '',
            selectedSubject: '',
            colleges: [],
            majors: [],
            levels: [],
            subjects: [],

            async fetchColleges() {
                this.selectedCollege = ''; this.selectedMajor = ''; this.selectedLevel = ''; this.selectedSubject = '';
                this.majors = []; this.levels = []; this.subjects = [];
                if (!this.selectedUniversity) { this.colleges = []; return; }
                const response = await fetch(`/api/public/colleges/${this.selectedUniversity}`);
                const data = await response.json();
                this.colleges = data.data;
            },

            async fetchMajors() {
                this.selectedMajor = ''; this.selectedLevel = ''; this.selectedSubject = '';
                this.levels = []; this.subjects = [];
                if (!this.selectedCollege) { this.majors = []; return; }
                const response = await fetch(`/api/public/majors/${this.selectedCollege}`);
                const data = await response.json();
                this.majors = data.data;
            },

            async fetchLevels() {
                this.selectedLevel = ''; this.selectedSubject = '';
                this.subjects = [];
                if (!this.selectedMajor) { this.levels = []; return; }
                const response = await fetch(`/api/public/levels/${this.selectedMajor}`);
                const data = await response.json();
                this.levels = data.data;
            },

            async fetchSubjects() {
                this.selectedSubject = '';
                if (!this.selectedLevel) { this.subjects = []; return; }
                const response = await fetch(`/api/public/subjects/${this.selectedLevel}`);
                const data = await response.json();
                this.subjects = data.data;
            }
        }
    }
</script>
@endsection
