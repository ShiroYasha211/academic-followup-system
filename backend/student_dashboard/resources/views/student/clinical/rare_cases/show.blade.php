@extends('layouts.student')

@section('title', 'تفاصيل الحالة النادرة')

@section('content')
<style>
    .case-detail-container {
        max-width: 900px;
        margin: 0 auto;
        background: white;
        border-radius: 20px;
        border: 1px solid #e2e8f0;
        overflow: hidden;
        box-shadow: 0 4px 6px rgba(0,0,0,0.05);
    }

    .detail-header {
        background: linear-gradient(135deg, var(--primary-color) 0%, #4338ca 100%);
        padding: 2.5rem;
        color: white;
        position: relative;
    }

    .detail-header h1 {
        font-weight: 800;
        font-size: 1.8rem;
        margin-bottom: 0.5rem;
    }

    .header-meta {
        display: flex;
        gap: 1.5rem;
        opacity: 0.9;
        font-weight: 600;
        font-size: 0.95rem;
    }

    .detail-body {
        padding: 2.5rem;
    }

    .section-title {
        font-weight: 800;
        font-size: 1.2rem;
        color: var(--text-primary);
        margin-bottom: 1.25rem;
        display: flex;
        align-items: center;
        gap: 0.5rem;
    }

    .info-card {
        background: #f8fafc;
        border-radius: 12px;
        padding: 1.5rem;
        margin-bottom: 2rem;
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
        gap: 2rem;
    }

    .info-block label {
        display: block;
        font-size: 0.85rem;
        color: #64748b;
        font-weight: 700;
        margin-bottom: 0.4rem;
    }

    .info-block span {
        font-weight: 800;
        color: var(--text-primary);
        font-size: 1.1rem;
    }

    .signs-content {
        line-height: 1.8;
        font-size: 1.1rem;
        color: #334155;
        background: #fff;
        border-right: 4px solid var(--primary-color);
        padding: 1.5rem;
        border-radius: 0 8px 8px 0;
        box-shadow: 0 2px 4px rgba(0,0,0,0.02);
    }

    .attachment-img {
        width: 100%;
        border-radius: 16px;
        margin-top: 1rem;
        border: 1px solid #e2e8f0;
        box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
    }

    .btn-back {
        background: #f1f5f9;
        color: var(--text-primary);
        padding: 0.75rem 1.5rem;
        border-radius: 10px;
        font-weight: 700;
        text-decoration: none;
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
        margin-top: 1rem;
    }
</style>

<div class="mb-4">
    <a href="{{ route('student.clinical.rare-cases.index') }}" class="btn-back">
        <i class="fa-solid fa-arrow-right"></i> العودة للجدول الزمني
    </a>
</div>

<div class="case-detail-container">
    <div class="detail-header">
        <h1>{{ $case->diagnosis }}</h1>
        <div class="header-meta">
            <span>By: Dr. {{ $case->doctor->name }}</span>
            <span>• Published {{ $case->created_at->format('Y-m-d') }}</span>
        </div>
    </div>

    <div class="detail-body">
        <div class="section-title">
            <i class="fa-solid fa-circle-info text-primary"></i> معلومات الموقع
        </div>
        
        <div class="info-card">
            <div class="info-block">
                <label>المستشفى / المركز</label>
                <span>{{ $case->hospital }}</span>
            </div>
            <div class="info-block">
                <label>القسم</label>
                <span>{{ $case->department }}</span>
            </div>
            <div class="info-block">
                <label>رقم الغرفة / الموقع</label>
                <span>{{ $case->room_number ?? 'غير متوفر' }}</span>
            </div>
        </div>

        @if($case->clinical_signs)
        <div class="section-title">
            <i class="fa-solid fa-magnifying-glass-plus text-primary"></i> العلامات السريرية والملاحظات
        </div>
        <div class="signs-content mb-4">
            {!! nl2br(e($case->clinical_signs)) !!}
        </div>
        @endif

        @if($case->attachment_path)
        <div class="section-title">
            <i class="fa-solid fa-image text-primary"></i> المرفقات التوضيحية
        </div>
        <img src="{{ asset('storage/' . $case->attachment_path) }}" class="attachment-img" alt="Case Attachment">
        @endif
    </div>
</div>
@endsection
