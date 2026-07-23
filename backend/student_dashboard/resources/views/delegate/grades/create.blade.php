@extends('layouts.delegate')

@section('title', 'إضافة درجات')

@section('content')

<style>
    /* Tabs */
    .tabs-container {
        display: flex;
        gap: 0;
        margin-bottom: 0;
        border-bottom: 2px solid #e2e8f0;
    }

    .tab-btn {
        padding: 1rem 2rem;
        background: none;
        border: none;
        font-weight: 700;
        color: var(--text-secondary);
        cursor: pointer;
        position: relative;
        transition: all 0.2s;
        display: flex;
        align-items: center;
        gap: 0.5rem;
    }

    .tab-btn:hover {
        color: var(--primary-color);
    }

    .tab-btn.active {
        color: var(--primary-color);
    }

    .tab-btn.active::after {
        content: '';
        position: absolute;
        bottom: -2px;
        left: 0;
        right: 0;
        height: 3px;
        background: var(--primary-color);
        border-radius: 3px 3px 0 0;
    }

    /* Form Card */
    .form-card {
        background: white;
        border-radius: 20px;
        padding: 2rem;
        border: 1px solid #e2e8f0;
    }

    /* Upload Zone */
    .upload-zone {
        border: 2px dashed #e2e8f0;
        border-radius: 16px;
        padding: 3rem;
        text-align: center;
        transition: all 0.3s;
        cursor: pointer;
        background: #fafafa;
    }

    .upload-zone:hover,
    .upload-zone.dragover {
        border-color: var(--primary-color);
        background: #f8fafc;
    }

    .upload-zone.has-file {
        border-color: #10b981;
        background: #ecfdf5;
    }

    /* Quick Entry Table */
    .quick-entry-table {
        width: 100%;
        border-collapse: separate;
        border-spacing: 0;
    }

    .quick-entry-table thead th {
        background: #f8fafc;
        padding: 1rem;
        text-align: right;
        font-weight: 700;
        color: var(--text-secondary);
        font-size: 0.85rem;
        border-bottom: 2px solid #e2e8f0;
        position: sticky;
        top: 0;
    }

    .quick-entry-table tbody td {
        padding: 0.75rem 1rem;
        border-bottom: 1px solid #f1f5f9;
    }

    .quick-entry-table tbody tr:hover {
        background: #f8fafc;
    }

    .grade-input {
        width: 100px;
        padding: 0.5rem 0.75rem;
        border: 2px solid #e2e8f0;
        border-radius: 10px;
        text-align: center;
        font-weight: 700;
        font-size: 1rem;
        transition: all 0.2s;
    }

    .grade-input:focus {
        outline: none;
        border-color: var(--primary-color);
        box-shadow: 0 0 0 3px rgba(79, 70, 229, 0.1);
    }

    /* Preview Table */
    .preview-table {
        width: 100%;
        border-collapse: collapse;
        margin-top: 1rem;
    }

    .preview-table th,
    .preview-table td {
        padding: 0.75rem;
        border: 1px solid #e2e8f0;
        text-align: right;
    }

    .preview-table th {
        background: #f8fafc;
        font-weight: 700;
    }

    .preview-table tbody tr:nth-child(even) {
        background: #fafafa;
    }

    .table-wrapper {
        max-height: 400px;
        overflow-y: auto;
        border: 1px solid #e2e8f0;
        border-radius: 12px;
    }
</style>

<div class="container" x-data="gradesManager()">

    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 2rem;">
        <div>
            <h1 style="font-size: 1.75rem; font-weight: 800; color: var(--text-primary);">إضافة درجات</h1>
            <p style="color: var(--text-secondary);">اختر طريقة الإدخال المناسبة لك.</p>
        </div>
        <a href="{{ route('delegate.grades.index') }}" class="btn btn-secondary" style="display: flex; align-items: center; gap: 0.5rem;">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <line x1="19" y1="12" x2="5" y2="12"></line>
                <polyline points="12 19 5 12 12 5"></polyline>
            </svg>
            العودة
        </a>
    </div>

    @if(session('error'))
    <div class="alert alert-danger mb-4" style="border-radius: 12px;">
        {{ session('error') }}
    </div>
    @endif

    <!-- Tabs -->
    <div class="form-card" style="padding: 0; overflow: hidden;">
        <div class="tabs-container">
            <button class="tab-btn" :class="{ 'active': activeTab === 'quick' }" @click="activeTab = 'quick'">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                    <polyline points="14 2 14 8 20 8"></polyline>
                    <line x1="16" y1="13" x2="8" y2="13"></line>
                    <line x1="16" y1="17" x2="8" y2="17"></line>
                </svg>
                إدخال سريع
            </button>
            <button class="tab-btn" :class="{ 'active': activeTab === 'excel' }" @click="activeTab = 'excel'">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                    <polyline points="17 8 12 3 7 8"></polyline>
                    <line x1="12" y1="3" x2="12" y2="15"></line>
                </svg>
                رفع Excel
            </button>
        </div>

        <div style="padding: 2rem;">

            <!-- Quick Entry Tab -->
            <div x-show="activeTab === 'quick'">
                <form action="{{ route('delegate.grades.storeQuick') }}" method="POST">
                    @csrf

                    <div class="row g-4 mb-4">
                        <div class="col-md-4">
                            <label class="form-label fw-bold">المادة</label>
                            <select name="subject_id" class="form-select" required>
                                <option value="">اختر المادة...</option>
                                @foreach($subjects as $subject)
                                <option value="{{ $subject->id }}" {{ $selectedSubject == $subject->id ? 'selected' : '' }}>{{ $subject->name }}</option>
                                @endforeach
                            </select>
                        </div>
                        <div class="col-md-3">
                            <label class="form-label fw-bold">نوع الدرجة</label>
                            <select name="type" class="form-select" required>
                                <option value="continuous">محصلة (40%)</option>
                                <option value="final">نهائي (60%)</option>
                            </select>
                        </div>
                        <div class="col-md-3">
                            <label class="form-label fw-bold">التصنيف (اختياري)</label>
                            <input type="text" name="category" class="form-control" placeholder="مثال: اختبار نصفي">
                        </div>
                        <div class="col-md-2">
                            <label class="form-label fw-bold">الدرجة الكاملة</label>
                            <input type="number" name="max_score" class="form-control" value="100" min="1" max="100" required>
                        </div>
                    </div>

                    <div class="table-wrapper">
                        <div class="table-responsive">
<table class="quick-entry-table">
                            <thead>
                                <tr>
                                    <th style="width: 50px;">#</th>
                                    <th>اسم الطالب</th>
                                    <th>رقم القيد</th>
                                    <th style="width: 150px; text-align: center;">الدرجة</th>
                                </tr>
                            </thead>
                            <tbody>
                                @foreach($students as $index => $student)
                                <tr>
                                    <td style="color: var(--text-secondary);">{{ $index + 1 }}</td>
                                    <td style="font-weight: 700;">{{ $student->name }}</td>
                                    <td style="font-family: monospace; color: var(--text-secondary);">{{ $student->student_number }}</td>
                                    <td style="text-align: center;">
                                        <input type="hidden" name="grades[{{ $index }}][student_id]" value="{{ $student->id }}">
                                        <input type="number" name="grades[{{ $index }}][score]" class="grade-input" min="0" max="100" step="0.5" placeholder="-">
                                    </td>
                                </tr>
                                @endforeach
                            </tbody>
                        </table>
</div>
                    </div>

                    <div style="display: flex; justify-content: flex-end; margin-top: 2rem; padding-top: 1.5rem; border-top: 1px dashed #e2e8f0;">
                        <button type="submit" class="btn btn-primary" style="padding: 0.75rem 2rem; border-radius: 12px; font-weight: 700; display: flex; align-items: center; gap: 0.5rem;">
                            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"></path>
                                <polyline points="17 21 17 13 7 13 7 21"></polyline>
                                <polyline points="7 3 7 8 15 8"></polyline>
                            </svg>
                            حفظ جميع الدرجات
                        </button>
                    </div>
                </form>
            </div>

            <!-- Excel Upload Tab -->
            <div x-show="activeTab === 'excel'" style="display: none;">
                <form action="{{ route('delegate.grades.storeExcel') }}" method="POST" @submit="submitExcelForm($event)">
                    @csrf

                    <div class="row g-4 mb-4">
                        <div class="col-md-4">
                            <label class="form-label fw-bold">المادة</label>
                            <select name="subject_id" class="form-select" required>
                                <option value="">اختر المادة...</option>
                                @foreach($subjects as $subject)
                                <option value="{{ $subject->id }}" {{ $selectedSubject == $subject->id ? 'selected' : '' }}>{{ $subject->name }}</option>
                                @endforeach
                            </select>
                        </div>
                        <div class="col-md-3">
                            <label class="form-label fw-bold">نوع الدرجة</label>
                            <select name="type" class="form-select" required>
                                <option value="continuous">محصلة (40%)</option>
                                <option value="final">نهائي (60%)</option>
                            </select>
                        </div>
                        <div class="col-md-3">
                            <label class="form-label fw-bold">التصنيف (اختياري)</label>
                            <input type="text" name="category" class="form-control" placeholder="مثال: اختبار نصفي">
                        </div>
                        <div class="col-md-2">
                            <label class="form-label fw-bold">الدرجة الكاملة</label>
                            <input type="number" name="max_score" class="form-control" value="100" min="1" max="100" required>
                        </div>
                    </div>

                    <input type="hidden" name="excel_data" x-model="excelDataJson">

                    <div class="upload-zone"
                        :class="{ 'has-file': fileName, 'dragover': isDragging }"
                        @click="$refs.fileInput.click()"
                        @dragover.prevent="isDragging = true"
                        @dragleave.prevent="isDragging = false"
                        @drop.prevent="handleDrop($event)">
                        <input type="file" x-ref="fileInput" @change="handleFileSelect($event)" accept=".xlsx,.xls,.csv" style="display: none;">

                        <div x-show="!fileName" style="color: var(--text-secondary);">
                            <div style="margin-bottom: 1rem;">
                                <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="#10b981" stroke-width="1.5">
                                    <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                                    <polyline points="14 2 14 8 20 8"></polyline>
                                    <line x1="16" y1="13" x2="8" y2="13"></line>
                                    <line x1="16" y1="17" x2="8" y2="17"></line>
                                </svg>
                            </div>
                            <div style="font-weight: 700; font-size: 1.1rem; margin-bottom: 0.5rem;">اسحب ملف Excel هنا أو اضغط للاختيار</div>
                            <div style="font-size: 0.9rem; margin-bottom: 1rem;">يجب أن يحتوي الملف على عمود <strong>رقم القيد</strong> وعمود <strong>الدرجة</strong></div>
                            <a href="{{ route('delegate.grades.downloadTemplate') }}" @click.stop class="btn btn-success btn-sm" style="display: inline-flex; align-items: center; gap: 0.5rem; border-radius: 10px;">
                                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                                    <polyline points="7 10 12 15 17 10"></polyline>
                                    <line x1="12" y1="15" x2="12" y2="3"></line>
                                </svg>
                                تنزيل قالب جاهز
                            </a>
                        </div>

                        <div x-show="fileName" style="color: #10b981;">
                            <div style="margin-bottom: 0.5rem;">
                                <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
                                    <polyline points="22 4 12 14.01 9 11.01"></polyline>
                                </svg>
                            </div>
                            <div style="font-weight: 700;" x-text="fileName"></div>
                            <div style="font-size: 0.9rem; margin-top: 0.25rem;" x-text="excelData.length + ' سجل'"></div>
                            <button type="button" @click.stop="clearFile()" style="margin-top: 0.75rem; background: #fef2f2; color: #ef4444; border: none; padding: 0.4rem 1rem; border-radius: 8px; font-size: 0.85rem; cursor: pointer;">إزالة الملف</button>
                        </div>
                    </div>

                    <!-- Preview -->
                    <div x-show="excelData.length > 0" style="margin-top: 2rem;">
                        <h4 style="font-weight: 700; margin-bottom: 1rem;">معاينة البيانات (أول 10 سجلات)</h4>
                        <div class="table-wrapper" style="max-height: 300px;">
                            <div class="table-responsive">
<table class="preview-table">
                                <thead>
                                    <tr>
                                        <th>#</th>
                                        <th>رقم القيد</th>
                                        <th>الدرجة</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <template x-for="(row, index) in excelData.slice(0, 10)" :key="index">
                                        <tr>
                                            <td x-text="index + 1"></td>
                                            <td x-text="row.student_number" style="font-family: monospace;"></td>
                                            <td x-text="row.score" style="font-weight: 700;"></td>
                                        </tr>
                                    </template>
                                </tbody>
                            </table>
</div>
                        </div>
                        <div x-show="excelData.length > 10" style="text-align: center; padding: 0.75rem; background: #f8fafc; color: var(--text-secondary); font-size: 0.9rem;">
                            ... و <span x-text="excelData.length - 10"></span> سجل آخر
                        </div>
                    </div>

                    <div x-show="excelData.length > 0" style="display: flex; justify-content: flex-end; margin-top: 2rem; padding-top: 1.5rem; border-top: 1px dashed #e2e8f0;">
                        <button type="submit" class="btn btn-primary" style="padding: 0.75rem 2rem; border-radius: 12px; font-weight: 700; display: flex; align-items: center; gap: 0.5rem;">
                            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"></path>
                                <polyline points="17 21 17 13 7 13 7 21"></polyline>
                                <polyline points="7 3 7 8 15 8"></polyline>
                            </svg>
                            استيراد <span x-text="excelData.length"></span> درجة
                        </button>
                    </div>
                </form>
            </div>

        </div>
    </div>

</div>

<!-- SheetJS Library for Excel Parsing -->
<script src="https://cdn.sheetjs.com/xlsx-0.20.0/package/dist/xlsx.full.min.js"></script>

<script>
    function gradesManager() {
        return {
            activeTab: 'quick',
            fileName: '',
            excelData: [],
            excelDataJson: '',
            isDragging: false,

            handleFileSelect(event) {
                const file = event.target.files[0];
                if (file) this.parseFile(file);
            },

            handleDrop(event) {
                this.isDragging = false;
                const file = event.dataTransfer.files[0];
                if (file) {
                    this.$refs.fileInput.files = event.dataTransfer.files;
                    this.parseFile(file);
                }
            },

            parseFile(file) {
                this.fileName = file.name;
                const reader = new FileReader();

                reader.onload = (e) => {
                    const data = new Uint8Array(e.target.result);
                    const workbook = XLSX.read(data, {
                        type: 'array'
                    });
                    const sheetName = workbook.SheetNames[0];
                    const worksheet = workbook.Sheets[sheetName];
                    const jsonData = XLSX.utils.sheet_to_json(worksheet, {
                        header: 1
                    });

                    // Find column indices
                    const headers = jsonData[0] || [];
                    let studentNumCol = -1;
                    let scoreCol = -1;

                    headers.forEach((h, i) => {
                        const header = String(h).toLowerCase().trim();
                        if (header.includes('قيد') || header.includes('رقم') || header.includes('student') || header.includes('id') || header.includes('number')) {
                            studentNumCol = i;
                        }
                        if (header.includes('درجة') || header.includes('score') || header.includes('grade') || header.includes('mark')) {
                            scoreCol = i;
                        }
                    });

                    // If not found, assume first two columns
                    if (studentNumCol === -1) studentNumCol = 0;
                    if (scoreCol === -1) scoreCol = 1;

                    // Parse data rows
                    this.excelData = [];
                    for (let i = 1; i < jsonData.length; i++) {
                        const row = jsonData[i];
                        if (row && row[studentNumCol]) {
                            this.excelData.push({
                                student_number: String(row[studentNumCol]).trim(),
                                score: parseFloat(row[scoreCol]) || 0
                            });
                        }
                    }

                    this.excelDataJson = JSON.stringify(this.excelData);
                };

                reader.readAsArrayBuffer(file);
            },

            clearFile() {
                this.fileName = '';
                this.excelData = [];
                this.excelDataJson = '';
                this.$refs.fileInput.value = '';
            },

            submitExcelForm(event) {
                if (this.excelData.length === 0) {
                    event.preventDefault();
                    alert('يرجى رفع ملف Excel أولاً');
                    return false;
                }
                this.excelDataJson = JSON.stringify(this.excelData);
                return true;
            }
        }
    }
</script>

@endsection