@extends('layouts.doctor')

@section('title', 'رفع ملف جديد')

@section('content')

<div style="max-width: 800px; margin: 0 auto;" x-data="{ 
    selectedFile: null, 
    fileName: '', 
    fileSize: '', 
    fileError: null,
    category: 'lectures', 
    dragActive: false,
    handleFile(f) {
        if (!f) return;
        if (f.size > 50 * 1024 * 1024) {
            this.fileError = 'حجم الملف (' + this.formatSize(f.size) + ') يتجاوز الحد المسموح به (50MB)';
            this.selectedFile = null;
            this.fileName = '';
            this.fileSize = '';
            return;
        }
        this.fileError = null;
        this.selectedFile = f;
        this.fileName = f.name;
        this.fileSize = this.formatSize(f.size);
    },
    formatSize(bytes) {
        if (bytes < 1024) return bytes + ' B';
        if (bytes < 1048576) return (bytes / 1024).toFixed(1) + ' KB';
        return (bytes / 1048576).toFixed(1) + ' MB';
    }
}">

    <!-- Page Header -->
    <div style="margin-bottom: 2rem;">
        <a href="{{ route('doctor.resources.index') }}" style="display: inline-flex; align-items: center; gap: 0.5rem; color: var(--primary-color); text-decoration: none; font-weight: 600; margin-bottom: 1rem; transition: opacity 0.2s;" onmouseover="this.style.opacity='0.7'" onmouseout="this.style.opacity='1'">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <line x1="5" y1="12" x2="19" y2="12"></line>
                <polyline points="12 5 19 12 12 19"></polyline>
            </svg>
            العودة للمصادر
        </a>
        <h1 style="font-size: 2rem; font-weight: 800; color: var(--text-primary); margin: 0; letter-spacing: -0.5px;">📤 رفع مصادر تعليمية</h1>
        <p style="color: var(--text-secondary); margin-top: 0.5rem; font-size: 1.05rem;">أضف المحاضرات والمراجع لطلابك في المكتبة المشتركة</p>
    </div>

    <form action="{{ route('doctor.resources.store') }}" method="POST" enctype="multipart/form-data">
        @csrf

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
                required accept=".pdf,.ppt,.pptx,.doc,.docx,.xls,.xlsx,.jpg,.jpeg,.png,.zip,.rar">

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
                        <div class="icon-box" :style="category === 'lectures' ? 'background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%); box-shadow: 0 8px 20px -4px rgba(59, 130, 246, 0.5);' : ''">
                            <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2z"></path>
                                <path d="M22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z"></path>
                            </svg>
                        </div>
                        <span class="label">محاضرات</span>
                    </div>
                </label>

                <!-- References -->
                <label class="category-card">
                    <input type="radio" name="category" value="references" x-model="category">
                    <div class="card-content" :class="category === 'references' ? 'active-amber' : ''">
                        <div class="icon-box" :style="category === 'references' ? 'background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%); box-shadow: 0 8px 20px -4px rgba(245, 158, 11, 0.5);' : ''">
                            <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path>
                                <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path>
                            </svg>
                        </div>
                        <span class="label">مراجع</span>
                    </div>
                </label>

                <!-- Summaries -->
                <label class="category-card">
                    <input type="radio" name="category" value="summaries" x-model="category">
                    <div class="card-content" :class="category === 'summaries' ? 'active-green' : ''">
                        <div class="icon-box" :style="category === 'summaries' ? 'background: linear-gradient(135deg, #10b981 0%, #059669 100%); box-shadow: 0 8px 20px -4px rgba(16, 185, 129, 0.5);' : ''">
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

                <!-- Exams -->
                <label class="category-card">
                    <input type="radio" name="category" value="exams" x-model="category">
                    <div class="card-content" :class="category === 'exams' ? 'active-red' : ''">
                        <div class="icon-box" :style="category === 'exams' ? 'background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%); box-shadow: 0 8px 20px -4px rgba(239, 68, 68, 0.5);' : ''">
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
                        <div class="icon-box" :style="category === 'other' ? 'background: linear-gradient(135deg, #64748b 0%, #475569 100%); box-shadow: 0 8px 20px -4px rgba(100, 116, 139, 0.5);' : ''">
                            <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"></path>
                            </svg>
                        </div>
                        <span class="label">أخرى</span>
                    </div>
                </label>
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

            <div style="padding: 1.5rem; display: grid; grid-template-columns: 1fr 1fr; gap: 1.25rem;">
                <!-- Subject -->
                <div style="grid-column: span 2;">
                    <label style="display: block; font-weight: 700; color: var(--text-primary); margin-bottom: 0.5rem;">
                        المادة الدراسية <span style="color: #ef4444;">*</span>
                    </label>
                    <div style="position: relative;">
                        <select name="subject_id" required style="width: 100%; height: 52px; background: #f8fafc; border: 2px solid #e2e8f0; border-radius: 12px; padding: 0 2.5rem 0 1rem; font-weight: 600; font-size: 1rem; cursor: pointer; appearance: none; transition: all 0.2s;">
                            <option value="">اختر المادة</option>
                            @foreach($subjects as $subject)
                            <option value="{{ $subject->id }}">{{ $subject->name }} ({{ $subject->code }})</option>
                            @endforeach
                        </select>
                        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#64748b" stroke-width="2" style="position: absolute; left: 14px; top: 50%; transform: translateY(-50%); pointer-events: none;">
                            <polyline points="6 9 12 15 18 9"></polyline>
                        </svg>
                    </div>
                </div>

                <!-- Title -->
                <div style="grid-column: span 2;">
                    <label style="display: block; font-weight: 700; color: var(--text-primary); margin-bottom: 0.5rem;">
                        عنوان الملف <span style="color: #ef4444;">*</span>
                    </label>
                    <input type="text" name="title" required placeholder="مثال: مهارات الفحص السريري - المحاضرة الأولى"
                        style="width: 100%; height: 52px; background: #f8fafc; border: 2px solid #e2e8f0; border-radius: 12px; padding: 0 1rem; font-weight: 600; font-size: 1rem; transition: all 0.2s;">
                </div>

                <!-- Description -->
                <div style="grid-column: span 2;">
                    <label style="display: block; font-weight: 700; color: var(--text-primary); margin-bottom: 0.5rem;">
                        ملاحظات <span style="color: #94a3b8; font-weight: 400;">(اختياري)</span>
                    </label>
                    <textarea name="description" rows="3" placeholder="أضف وصفاً أو تعليمات للطلاب بخصوص هذا الملف..."
                        style="width: 100%; background: #f8fafc; border: 2px solid #e2e8f0; border-radius: 12px; padding: 0.85rem 1rem; font-weight: 500; font-size: 1rem; resize: none; transition: all 0.2s;"></textarea>
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
    </form>
</div>

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

    [x-cloak] { display: none !important; }

    @media (max-width: 640px) {
        .category-card .card-content { padding: 1rem 0.25rem; }
        .category-card .icon-box { width: 44px; height: 44px; margin-bottom: 0.5rem; }
        .category-card .label { font-size: 0.8rem; }
    }
</style>

@endsection
