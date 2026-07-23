@php
    $role = auth()->user()->role ?? (request()->routeIs('doctor.*') ? 'doctor' : (request()->routeIs('delegate.*') ? 'delegate' : 'student'));
@endphp

<!-- Step 1: File Upload Zone -->
<div class="card" style="padding: 0; margin-bottom: 2rem; border-radius: 20px; overflow: hidden; border: none; box-shadow: var(--shadow-md);">
    <div style="background: linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%); padding: 1.25rem 1.5rem; display: flex; align-items: center; gap: 0.75rem;">
        <div style="width: 36px; height: 36px; background: rgba(255,255,255,0.2); border-radius: 10px; display: flex; align-items: center; justify-content: center;">
            <span style="font-size: 1.2rem; color: white;">①</span>
        </div>
        <h3 style="color: white; font-weight: 700; margin: 0; font-size: 1.1rem;">اختر الملف</h3>
    </div>

    <input type="file" name="file" id="file" style="display: none;"
        @change="handleFile($event.target.files[0])"
        accept=".pdf,.ppt,.pptx,.doc,.docx,.xls,.xlsx,.jpg,.jpeg,.png,.zip,.rar">

    <label for="file"
        style="display: block; padding: 3rem 2rem; cursor: pointer; transition: all 0.3s ease; text-align: center;"
        :style="fileError ? 'background: #fff1f2; border: 2px dashed #fb7185;' : (selectedFile ? 'background: linear-gradient(135deg, #ecfdf5 0%, #d1fae5 100%);' : (dragActive ? 'background: linear-gradient(135deg, #eff6ff 0%, #dbeafe 100%);' : 'background: #fafbfc;'))"
        @dragover.prevent="dragActive = true"
        @dragleave.prevent="dragActive = false"
        @drop.prevent="dragActive = false; handleFile($event.dataTransfer.files[0])">

        <!-- Animated Upload Icon -->
        <div style="margin-bottom: 1.5rem; display: flex; justify-content: center;">
            <template x-if="!selectedFile">
                <div style="width: 110px; height: 110px; background: linear-gradient(135deg, #e0e7ff 0%, #c7d2fe 100%); border-radius: 50%; display: flex; align-items: center; justify-content: center; animation: pulse 2s infinite;">
                    <svg xmlns="http://www.w3.org/2000/svg" width="50" height="50" viewBox="0 0 24 24" fill="none" stroke="#6366f1" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                        <polyline points="17 8 12 3 7 8"></polyline>
                        <line x1="12" y1="3" x2="12" y2="15"></line>
                    </svg>
                </div>
            </template>
            <template x-if="selectedFile">
                <div style="width: 110px; height: 110px; background: linear-gradient(135deg, #dcfce7 0%, #bbf7d0 100%); border-radius: 50%; display: flex; align-items: center; justify-content: center;">
                    <svg xmlns="http://www.w3.org/2000/svg" width="50" height="50" viewBox="0 0 24 24" fill="none" stroke="#10b981" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                        <polyline points="20 6 9 17 4 12"></polyline>
                    </svg>
                </div>
            </template>
        </div>

        <h4 x-show="!selectedFile && !fileError" style="font-size: 1.35rem; font-weight: 700; color: var(--text-primary); margin-bottom: 0.5rem; text-align: center;">اسحر الملفات هنا أو اضغط للاختيار</h4>
        <p x-show="!selectedFile && !fileError" style="color: var(--text-secondary); margin: 0; font-size: 0.95rem; text-align: center;">
            يدعم: PDF, PowerPoint, Word, Excel, صور, ملفات مضغوطة<br>
            <span style="color: #94a3b8;">(الحد الأقصى: 50MB)</span>
        </p>

        <div x-show="fileError" x-cloak style="text-align: center; margin-bottom: 1rem;">
            <div style="width: 60px; height: 60px; background: #fee2e2; border-radius: 50%; display: flex; align-items: center; justify-content: center; margin: 0 auto 1rem;">
                <svg xmlns="http://www.w3.org/2000/svg" width="30" height="30" viewBox="0 0 24 24" fill="none" stroke="#ef4444" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="8" x2="12" y2="12"></line><line x1="12" y1="16" x2="12.01" y2="16"></line></svg>
            </div>
            <h4 style="font-size: 1.1rem; font-weight: 700; color: #b91c1c; margin: 0;" x-text="fileError"></h4>
            <p style="color: #ef4444; font-size: 0.9rem; margin-top: 0.25rem;">يرجى اختيار ملف أصغر</p>
        </div>

        <div x-show="selectedFile" x-cloak style="background: white; padding: 1rem 2rem; border-radius: 12px; box-shadow: 0 4px 15px rgba(0,0,0,0.08); text-align: center; margin: 0 auto; display: inline-block;">
            <h4 style="font-size: 1.2rem; font-weight: 700; color: #10b981; margin: 0 0 0.25rem 0;" x-text="fileName"></h4>
            <p style="color: #64748b; margin: 0; font-size: 0.9rem;">
                ✓ تم اختيار الملف بنجاح (<span x-text="fileSize"></span>)
            </p>
        </div>
    </label>
</div>

<!-- Step 2: Category Selection -->
<div class="card" style="padding: 0; margin-bottom: 2rem; border-radius: 20px; overflow: hidden; border: none; box-shadow: var(--shadow-md);">
    <div style="background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%); padding: 1.25rem 1.5rem; display: flex; align-items: center; gap: 0.75rem;">
        <div style="width: 36px; height: 36px; background: rgba(255,255,255,0.2); border-radius: 10px; display: flex; align-items: center; justify-content: center;">
            <span style="font-size: 1.2rem; color: white;">②</span>
        </div>
        <h3 style="color: white; font-weight: 700; margin: 0; font-size: 1.1rem;">اختر تصنيف الملف</h3>
    </div>

    <div style="padding: 1.5rem; display: grid; grid-template-columns: repeat(auto-fit, minmax(120px, 1fr)); gap: 1rem;">

        <!-- Lectures -->
        <label class="category-card">
            <input type="radio" name="category" value="lectures" x-model="category">
            <div class="card-content" :class="category === 'lectures' ? 'active-blue' : ''">
                <div class="icon-box" :style="category === 'lectures' ? 'background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);' : ''">
                    <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2z"></path>
                        <path d="M22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z"></path>
                    </svg>
                </div>
                <span class="label">محاضرات</span>
            </div>
        </label>
    
        <!-- Summaries -->
        <label class="category-card">
            <input type="radio" name="category" value="summaries" x-model="category">
            <div class="card-content" :class="category === 'summaries' ? 'active-green' : ''">
                <div class="icon-box" :style="category === 'summaries' ? 'background: linear-gradient(135deg, #10b981 0%, #059669 100%);' : ''">
                    <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                        <polyline points="14 2 14 8 20 8"></polyline>
                        <line x1="16" y1="13" x2="8" y2="13"></line>
                        <line x1="16" y1="17" x2="8" y2="17"></line>
                    </svg>
                </div>
                <span class="label">ملخصات</span>
            </div>
        </label>
    
        <!-- Quizzes -->
        <label class="category-card">
            <input type="radio" name="category" value="quizzes" x-model="category">
            <div class="card-content" :class="category === 'quizzes' ? 'active-amber' : ''">
                <div class="icon-box" :style="category === 'quizzes' ? 'background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);' : ''">
                    <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <circle cx="12" cy="12" r="10"></circle>
                        <path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"></path>
                        <line x1="12" y1="17" x2="12.01" y2="17"></line>
                    </svg>
                </div>
                <span class="label">كويزات</span>
            </div>
        </label>
    
        <!-- Exams -->
        <label class="category-card">
            <input type="radio" name="category" value="exams" x-model="category">
            <div class="card-content" :class="category === 'exams' ? 'active-red' : ''">
                <div class="icon-box" :style="category === 'exams' ? 'background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%);' : ''">
                    <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M9 11l3 3L22 4"></path>
                        <path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"></path>
                    </svg>
                </div>
                <span class="label">اختبارات</span>
            </div>
        </label>
    
        <!-- Other -->
        <label class="category-card">
            <input type="radio" name="category" value="other" x-model="category">
            <div class="card-content" :class="category === 'other' ? 'active-gray' : ''">
                <div class="icon-box" :style="category === 'other' ? 'background: linear-gradient(135deg, #64748b 0%, #475569 100%);' : ''">
                    <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"></path>
                    </svg>
                </div>
                <span class="label">أخرى</span>
            </div>
        </label>
    </div>
    
    <!-- Sub-Category: Lectures -->
    <div x-show="category === 'lectures'" x-cloak x-transition style="padding: 1.5rem; border-top: 1px solid #f1f5f9; background: #fafbfc;">
        <label style="display: block; font-weight: 700; color: #1e40af; margin-bottom: 1rem; display: flex; align-items: center; gap: 0.5rem;">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="8" x2="12" y2="12"></line><line x1="12" y1="16" x2="12.01" y2="16"></line></svg>
            اختر نوع المحاضرة:
        </label>
        
        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(140px, 1fr)); gap: 0.75rem;">
            <!-- Theoretical -->
            <label style="cursor: pointer;">
                <input type="radio" name="sub_category" value="theoretical" x-model="subCategory" style="display: none;">
                <div class="sub-category-card" :class="subCategory === 'theoretical' ? 'active' : ''">
                    <div class="icon-circle">
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path><path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path></svg>
                    </div>
                    <span>نظري</span>
                </div>
            </label>

            <!-- Practical -->
            <label style="cursor: pointer;">
                <input type="radio" name="sub_category" value="practical" x-model="subCategory" style="display: none;">
                <div class="sub-category-card" :class="subCategory === 'practical' ? 'active' : ''">
                    <div class="icon-circle">
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M10 2v7"></path><path d="M14 2v7"></path><path d="M12 2v9"></path><path d="M4.5 11l15 0"></path><path d="M12 21a9 9 0 0 0 9-9h-18a9 9 0 0 0 9 9z"></path></svg>
                    </div>
                    <span>عملي</span>
                </div>
            </label>

            <!-- Seminar -->
            <label style="cursor: pointer;">
                <input type="radio" name="sub_category" value="seminar" x-model="subCategory" style="display: none;">
                <div class="sub-category-card" :class="subCategory === 'seminar' ? 'active' : ''">
                    <div class="icon-circle">
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path><circle cx="9" cy="7" r="4"></circle><path d="M23 21v-2a4 4 0 0 0-3-3.87"></path><path d="M16 3.13a4 4 0 0 1 0 7.75"></path></svg>
                    </div>
                    <span>سمنار</span>
                </div>
            </label>

            <!-- Other -->
            <label style="cursor: pointer;">
                <input type="radio" name="sub_category" value="other" x-model="subCategory" style="display: none;">
                <div class="sub-category-card" :class="subCategory === 'other' ? 'active' : ''">
                    <div class="icon-circle">
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><circle cx="12" cy="12" r="10"></circle><path d="M8 12h8"></path><path d="M12 8v8"></path></svg>
                    </div>
                    <span>أخرى</span>
                </div>
            </label>
        </div>
        
        <!-- Custom Lecture Type -->
        <div x-show="subCategory === 'other'" x-cloak x-transition style="margin-top: 1rem;">
            <div style="position: relative;">
                <input type="text" name="custom_category_type" placeholder="ما هو نوع المحاضرة؟"
                    style="width: 100%; height: 48px; background: white; border: 2px solid #3b82f6; border-radius: 12px; padding: 0 1rem; font-weight: 700; box-shadow: 0 4px 12px rgba(59, 130, 246, 0.1);">
                <div style="position: absolute; left: 12px; top: 50%; transform: translateY(-50%); color: #3b82f6;">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path></svg>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- Step 3: Details -->
<div class="card" style="padding: 0; margin-bottom: 2rem; border-radius: 20px; overflow: hidden; border: none; box-shadow: var(--shadow-md);">
    <div style="background: linear-gradient(135deg, #10b981 0%, #059669 100%); padding: 1.25rem 1.5rem; display: flex; align-items: center; gap: 0.75rem;">
        <div style="width: 36px; height: 36px; background: rgba(255,255,255,0.2); border-radius: 10px; display: flex; align-items: center; justify-content: center;">
            <span style="font-size: 1.2rem; color: white;">③</span>
        </div>
        <h3 style="color: white; font-weight: 700; margin: 0; font-size: 1.1rem;">تفاصيل الملف</h3>
    </div>

    <div style="padding: 1.5rem; display: grid; grid-template-columns: 1fr 1fr; gap: 1.5rem;">
        <!-- Subject -->
        <div style="grid-column: span {{ isset($isLibrary) && $isLibrary ? '1' : '2' }};">
            <label style="display: block; font-weight: 700; color: var(--text-primary); margin-bottom: 0.5rem;">المادة الدراسية <span style="color: #ef4444;">*</span></label>
            <div style="position: relative;">
                <select name="subject_id" required style="width: 100%; height: 50px; background: #f8fafc; border: 2px solid #e2e8f0; border-radius: 12px; padding: 0 2.5rem 0 1rem; font-weight: 600;">
                    <option value="">اختر المادة</option>
                    @foreach($subjects as $subject)
                    <option value="{{ $subject->id }}" {{ (isset($selectedSubjectId) && $selectedSubjectId == $subject->id) ? 'selected' : '' }}>{{ $subject->name }}</option>
                    @endforeach
                </select>
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#64748b" stroke-width="2" style="position: absolute; left: 14px; top: 15px; pointer-events: none;"><polyline points="6 9 12 15 18 9"></polyline></svg>
            </div>
        </div>

        @if(isset($isLibrary) && $isLibrary)
        <!-- Semester / System -->
        <div style="grid-column: span 1;">
            <label style="display: block; font-weight: 700; color: var(--text-primary); margin-bottom: 0.5rem;">الفصل أو السستم <span style="color: #ef4444;">*</span></label>
            <input type="text" name="semester_info" required placeholder="مثال: الفصل الأول / الجهاز التنفسي" style="width: 100%; height: 50px; background: #f8fafc; border: 2px solid #e2e8f0; border-radius: 12px; padding: 0 1rem; font-weight: 600;">
        </div>

        <!-- Unit Coordinator -->
        <div style="grid-column: span 1;">
            <label style="display: block; font-weight: 700; color: var(--text-primary); margin-bottom: 0.5rem;">اسم منسق الوحدة</label>
            <input type="text" name="unit_coordinator" placeholder="اختياري" style="width: 100%; height: 50px; background: #f8fafc; border: 2px solid #e2e8f0; border-radius: 12px; padding: 0 1rem; font-weight: 600;">
        </div>

        <!-- Clinical Unit -->
        <div style="grid-column: span 1;">
            <label style="display: block; font-weight: 700; color: var(--text-primary); margin-bottom: 0.5rem;">اسم الوحدة السريرية</label>
            <input type="text" name="clinical_unit" placeholder="اختياري" style="width: 100%; height: 50px; background: #f8fafc; border: 2px solid #e2e8f0; border-radius: 12px; padding: 0 1rem; font-weight: 600;">
        </div>
        @endif

        <!-- Lecturer Name -->
        <div style="grid-column: span {{ isset($isLibrary) && $isLibrary ? '1' : '2' }};">
            <label style="display: block; font-weight: 700; color: var(--text-primary); margin-bottom: 0.5rem;">اسم الدكتور مقدم المحاضرة</label>
            <input type="text" name="lecturer_name" placeholder="اختياري" style="width: 100%; height: 50px; background: #f8fafc; border: 2px solid #e2e8f0; border-radius: 12px; padding: 0 1rem; font-weight: 600;">
        </div>

        <!-- Title -->
        <div style="grid-column: span 2;">
            <label style="display: block; font-weight: 700; color: var(--text-primary); margin-bottom: 0.5rem;">عنوان الملف <span style="color: #ef4444;">*</span></label>
            <input type="text" name="title" required placeholder="مثال: فسيولوجيا القلب - الجزء الأول" style="width: 100%; height: 50px; background: #f8fafc; border: 2px solid #e2e8f0; border-radius: 12px; padding: 0 1rem; font-weight: 600;">
        </div>

        @if(isset($isLibrary) && $isLibrary)
            @if(auth()->user()->hasRole('doctor'))
                <input type="hidden" name="visibility" value="everyone">
            @else
                <!-- Visibility -->
                <div style="grid-column: span 2; background: #f0f9ff; padding: 1.25rem; border-radius: 15px; border: 1px solid #bae6fd;">
                    <label style="display: block; font-weight: 700; color: #0369a1; margin-bottom: 1rem; display: flex; align-items: center; gap: 0.5rem;">
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path></svg>
                        خصوصية الملف: من يمكنه رؤية هذا الملف؟
                    </label>
                    <div style="display: flex; gap: 1.5rem; flex-wrap: wrap;">
                        <label style="display: flex; align-items: center; gap: 0.5rem; cursor: pointer; font-weight: 600; color: #0c4a6e;">
                            <input type="radio" name="visibility" value="batch" x-model="visibility" style="width: 18px; height: 18px; accent-color: #0284c7;">
                            زملائي في الدفعة فقط
                        </label>
                        <label style="display: flex; align-items: center; gap: 0.5rem; cursor: pointer; font-weight: 600; color: #0c4a6e;">
                            <input type="radio" name="visibility" value="college" x-model="visibility" style="width: 18px; height: 18px; accent-color: #0284c7;">
                            طلاب الكلية
                        </label>
                        <label style="display: flex; align-items: center; gap: 0.5rem; cursor: pointer; font-weight: 600; color: #0c4a6e;">
                            <input type="radio" name="visibility" value="everyone" x-model="visibility" style="width: 18px; height: 18px; accent-color: #0284c7;">
                            الجميع (يشمل الدكاترة)
                        </label>
                    </div>
                </div>
            @endif
        @endif

        <!-- Description -->
        <div style="grid-column: span 2;">
            <label style="display: block; font-weight: 700; color: var(--text-primary); margin-bottom: 0.5rem;">ملاحظات إضافية</label>
            <textarea name="description" rows="3" placeholder="أضف أي تفاصيل أخرى تساعد الزملاء..." style="width: 100%; background: #f8fafc; border: 2px solid #e2e8f0; border-radius: 12px; padding: 1rem; font-weight: 500; resize: none;"></textarea>
        </div>
    </div>
</div>

<!-- Submit Button -->
<button type="submit" class="upload-btn" :disabled="!selectedFile || !!fileError" :style="(!selectedFile || !!fileError) ? 'opacity: 0.6; cursor: not-allowed; filter: grayscale(1);' : ''"
    style="width: 100%; height: 60px; background: linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%); color: white; border: none; border-radius: 16px; font-size: 1.2rem; font-weight: 800; cursor: pointer; display: flex; align-items: center; justify-content: center; gap: 0.75rem; box-shadow: 0 15px 35px -5px rgba(79, 70, 229, 0.4); transition: all 0.3s ease;">
    <svg xmlns="http://www.w3.org/2000/svg" width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
        <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
        <polyline points="17 8 12 3 7 8"></polyline>
        <line x1="12" y1="3" x2="12" y2="15"></line>
    </svg>
    رفع الملف الآن
</button>

<style>
    @keyframes pulse {
        0%, 100% { transform: scale(1); opacity: 1; }
        50% { transform: scale(1.05); opacity: 0.8; }
    }

    input:focus, select:focus, textarea:focus {
        outline: none;
        border-color: var(--primary-color) !important;
        background: white !important;
        box-shadow: 0 0 0 4px rgba(79, 70, 229, 0.1);
    }

    .upload-btn:hover:not(:disabled) {
        transform: translateY(-3px);
        box-shadow: 0 20px 40px -5px rgba(79, 70, 229, 0.5);
    }

    .upload-btn:active:not(:disabled) {
        transform: translateY(-1px);
    }

    /* Category Cards Styling */
    .category-card { cursor: pointer; display: block; }
    .category-card input { display: none; }

    .category-card .card-content {
        padding: 1.5rem 0.5rem;
        border-radius: 16px;
        text-align: center;
        transition: all 0.3s ease;
        border: 2px solid #e2e8f0;
        background: #f8fafc;
    }

    .category-card:hover .card-content {
        transform: translateY(-3px);
        box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.05);
    }

    .category-card .icon-box {
        width: 56px;
        height: 56px;
        margin: 0 auto 0.75rem;
        border-radius: 14px;
        display: flex;
        align-items: center;
        justify-content: center;
        background: #e2e8f0;
        color: #64748b;
        transition: all 0.3s ease;
    }

    .category-card .label {
        font-weight: 700;
        font-size: 0.95rem;
        color: #64748b;
        display: block;
    }

    /* Active States */
    .card-content.active-blue { background: linear-gradient(135deg, #eff6ff 0%, #dbeafe 100%); border-color: #3b82f6; }
    .card-content.active-blue .icon-box { color: white; }
    .card-content.active-blue .label { color: #1e40af; }

    .card-content.active-amber { background: linear-gradient(135deg, #fffbeb 0%, #fef3c7 100%); border-color: #f59e0b; }
    .card-content.active-amber .icon-box { color: white; }
    .card-content.active-amber .label { color: #92400e; }

    .card-content.active-green { background: linear-gradient(135deg, #ecfdf5 0%, #d1fae5 100%); border-color: #10b981; }
    .card-content.active-green .icon-box { color: white; }
    .card-content.active-green .label { color: #065f46; }

    .card-content.active-red { background: linear-gradient(135deg, #fef2f2 0%, #fecaca 100%); border-color: #ef4444; }
    .card-content.active-red .icon-box { color: white; }
    .card-content.active-red .label { color: #991b1b; }

    .card-content.active-gray { background: linear-gradient(135deg, #f8fafc 0%, #e2e8f0 100%); border-color: #64748b; }
    .card-content.active-gray .icon-box { color: white; }
    .card-content.active-gray .label { color: #334155; }

    /* Sub-Category Cards Styling */
    .sub-category-card {
        padding: 0.75rem;
        background: white;
        border: 2px solid #e2e8f0;
        border-radius: 14px;
        display: flex;
        align-items: center;
        gap: 0.75rem;
        transition: all 0.2s ease;
        color: #64748b;
        font-weight: 700;
        font-size: 0.95rem;
    }

    .sub-category-card .icon-circle {
        width: 36px;
        height: 36px;
        background: #f1f5f9;
        border-radius: 10px;
        display: flex;
        align-items: center;
        justify-content: center;
        transition: all 0.2s ease;
    }

    .sub-category-card:hover {
        border-color: #93c5fd;
        background: #f0f9ff;
        transform: translateY(-2px);
    }

    .sub-category-card.active {
        background: #eff6ff;
        border-color: #3b82f6;
        color: #1e40af;
        box-shadow: 0 4px 12px rgba(59, 130, 246, 0.1);
    }

    .sub-category-card.active .icon-circle {
        background: #3b82f6;
        color: white;
    }

    [x-cloak] { display: none !important; }

    @media (max-width: 640px) {
        .category-card .card-content { padding: 1rem 0.25rem; }
        .category-card .icon-box { width: 44px; height: 44px; margin-bottom: 0.5rem; }
        .category-card .label { font-size: 0.8rem; }
    }
</style>
