@extends('layouts.delegate')

@section('title', 'رفع ملف جديد')

@section('content')

<div style="max-width: 800px; margin: 0 auto;" x-data="{
    selectedFile: null,
    fileName: '',
    fileSize: '',
    fileError: null,
    category: 'lectures',
    subCategory: 'theoretical',
    customType: '',
    dragActive: false,
    visibility: 'batch',
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
        <a href="{{ route('delegate.resources.index') }}" style="display: inline-flex; align-items: center; gap: 0.5rem; color: var(--primary-color); text-decoration: none; font-weight: 600; margin-bottom: 1rem; transition: opacity 0.2s;" onmouseover="this.style.opacity='0.7'" onmouseout="this.style.opacity='1'">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <line x1="19" y1="12" x2="5" y2="12"></line>
                <polyline points="12 19 5 12 12 5"></polyline>
            </svg>
            العودة لمصادر المقرر
        </a>
        <h1 style="font-size: 2rem; font-weight: 800; color: var(--text-primary); margin: 0; letter-spacing: -0.5px;">📤 رفع ملف جديد للمقرر</h1>
        <p style="color: var(--text-secondary); margin-top: 0.5rem; font-size: 1.05rem;">شارك المعرفة مع زملائك في الدفعة</p>
    </div>

    <form action="{{ route('delegate.resources.store') }}" method="POST" enctype="multipart/form-data">
        @csrf

        @include('partials.library._upload_form', [
            'isLibrary' => false,
            'subjects' => $subjects
        ])
    </form>
</div>

<style>
    @keyframes pulse {

        0%,
        100% {
            transform: scale(1);
            opacity: 1;
        }

        50% {
            transform: scale(1.05);
            opacity: 0.8;
        }
    }

    input:focus,
    select:focus,
    textarea:focus {
        outline: none;
        border-color: var(--primary-color) !important;
        background: white !important;
        box-shadow: 0 0 0 4px rgba(79, 70, 229, 0.1);
    }

    .upload-btn:hover {
        transform: translateY(-3px);
        box-shadow: 0 20px 40px -5px rgba(79, 70, 229, 0.5);
    }

    .upload-btn:active {
        transform: translateY(-1px);
    }

    /* Category Cards Styling */
    .category-card {
        cursor: pointer;
        display: block;
    }

    .category-card input {
        display: none;
    }

    .category-card .card-content {
        padding: 1.5rem 0.75rem;
        border-radius: 16px;
        text-align: center;
        transition: all 0.3s ease;
        border: 2px solid #e2e8f0;
        background: #f8fafc;
    }

    .category-card:hover .card-content {
        transform: translateY(-3px);
        box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.1);
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
    .card-content.active-blue {
        background: linear-gradient(135deg, #eff6ff 0%, #dbeafe 100%);
        border-color: #3b82f6;
    }

    .card-content.active-blue .icon-box {
        color: white;
    }

    .card-content.active-blue .label {
        color: #1e40af;
    }

    .card-content.active-amber {
        background: linear-gradient(135deg, #fffbeb 0%, #fef3c7 100%);
        border-color: #f59e0b;
    }

    .card-content.active-amber .icon-box {
        color: white;
    }

    .card-content.active-amber .label {
        color: #92400e;
    }

    .card-content.active-green {
        background: linear-gradient(135deg, #ecfdf5 0%, #d1fae5 100%);
        border-color: #10b981;
    }

    .card-content.active-green .icon-box {
        color: white;
    }

    .card-content.active-green .label {
        color: #065f46;
    }

    .card-content.active-red {
        background: linear-gradient(135deg, #fef2f2 0%, #fecaca 100%);
        border-color: #ef4444;
    }

    .card-content.active-red .icon-box {
        color: white;
    }

    .card-content.active-red .label {
        color: #991b1b;
    }

    .card-content.active-gray {
        background: linear-gradient(135deg, #f8fafc 0%, #e2e8f0 100%);
        border-color: #64748b;
    }

    .card-content.active-gray .icon-box {
        color: white;
    }

    .card-content.active-gray .label {
        color: #334155;
    }

    [x-cloak] {
        display: none !important;
    }

    @media (max-width: 768px) {
        div[style*="grid-template-columns: repeat(5"] {
            grid-template-columns: repeat(3, 1fr) !important;
        }

        div[style*="grid-template-columns: 1fr 1fr"] {
            grid-template-columns: 1fr !important;
        }
    }
</style>

@endsection
