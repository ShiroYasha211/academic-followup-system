@extends('layouts.doctor')

@section('title', 'أرشيف الحالات النادرة')

@section('content')
<style>
    .dashboard-header {
        margin-bottom: 2rem;
        display: flex;
        justify-content: space-between;
        align-items: center;
    }

    .welcome-text h1 {
        font-size: 1.75rem;
        font-weight: 800;
        color: var(--text-primary);
        margin-bottom: 0.25rem;
    }

    .btn-create {
        background: var(--primary-color);
        color: white;
        padding: 0.75rem 1.5rem;
        border-radius: 12px;
        font-weight: 700;
        text-decoration: none;
        display: flex;
        align-items: center;
        gap: 0.5rem;
        transition: all 0.2s;
        box-shadow: 0 4px 6px rgba(79, 70, 229, 0.2);
    }

    .btn-create:hover {
        background: #4338ca;
        transform: translateY(-2px);
        color: white;
    }

    .case-card {
        background: white;
        border-radius: 16px;
        border: 1px solid #e2e8f0;
        padding: 1.5rem;
        margin-bottom: 1.5rem;
        transition: all 0.3s;
        position: relative;
        overflow: hidden;
    }

    .case-card:hover {
        box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
        border-color: var(--primary-color);
    }

    .status-badge {
        position: absolute;
        top: 1.5rem;
        left: 1.5rem;
        padding: 0.4rem 1rem;
        border-radius: 10px;
        font-weight: 700;
        font-size: 0.85rem;
    }

    .status-active { background: #f0fdf4; color: #16a34a; }
    .status-inactive { background: #f1f5f9; color: #64748b; }

    .case-info h3 {
        font-weight: 800;
        font-size: 1.3rem;
        margin-bottom: 1rem;
        color: var(--text-primary);
        display: flex;
        align-items: center;
        gap: 0.75rem;
    }

    .info-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
        gap: 1.25rem;
        background: #f8fafc;
        padding: 1.25rem;
        border-radius: 12px;
        margin-bottom: 1rem;
    }

    .info-item {
        display: flex;
        flex-direction: column;
        gap: 0.25rem;
    }

    .info-label {
        font-size: 0.8rem;
        color: #64748b;
        font-weight: 600;
    }

    .info-value {
        font-weight: 700;
        color: var(--text-primary);
        font-size: 1rem;
    }

    .signs-text {
        font-size: 0.95rem;
        color: #475569;
        line-height: 1.6;
        margin-top: 1rem;
        border-right: 4px solid var(--primary-color);
        padding-right: 1rem;
    }

    .attachment-preview {
        width: 100px;
        height: 100px;
        border-radius: 12px;
        object-fit: cover;
        cursor: pointer;
        transition: transform 0.2s;
    }

    .attachment-preview:hover {
        transform: scale(1.05);
    }

    .card-actions {
        display: flex;
        justify-content: flex-end;
        gap: 0.75rem;
        margin-top: 1.5rem;
        padding-top: 1rem;
        border-top: 1px solid #f1f5f9;
    }

    .btn-action {
        padding: 0.5rem 1rem;
        border-radius: 8px;
        font-weight: 600;
        font-size: 0.9rem;
        cursor: pointer;
        border: none;
        transition: all 0.2s;
        display: flex;
        align-items: center;
        gap: 0.4rem;
    }

    .btn-status { background: #eff6ff; color: #2563eb; }
    .btn-status:hover { background: #dbeafe; }
    
    .btn-delete { background: #fff1f2; color: #e11d48; }
    .btn-delete:hover { background: #ffe4e6; }

</style>

<div class="dashboard-header">
    <div class="welcome-text">
        <h1>أرشيف الحالات النادرة</h1>
        <p>إدارة الحالات التي قمت بمشاركتها مع الطلاب</p>
    </div>
    <a href="{{ route('doctor.clinical.rare-cases.create') }}" class="btn-create">
        <i class="fa-solid fa-plus"></i>
        إعلان حالة جديدة
    </a>
</div>

@if($cases->count() > 0)
    @foreach($cases as $case)
    <div class="case-card">
        <span class="status-badge {{ $case->is_active ? 'status-active' : 'status-inactive' }}">
            {{ $case->is_active ? 'إعلان نشط' : 'مؤرشف' }}
        </span>

        <div class="case-info">
            <h3>
                <i class="fa-solid fa-notes-medical text-primary"></i>
                {{ $case->diagnosis }}
            </h3>

            <div class="info-grid">
                <div class="info-item">
                    <span class="info-label">المستشفى</span>
                    <span class="info-value">{{ $case->hospital }}</span>
                </div>
                <div class="info-item">
                    <span class="info-label">القسم</span>
                    <span class="info-value">{{ $case->department }}</span>
                </div>
                <div class="info-item">
                    <span class="info-label">الغرفة</span>
                    <span class="info-value">{{ $case->room_number ?? 'غير محدد' }}</span>
                </div>
                <div class="info-item">
                    <span class="info-label">تاريخ الإعلان</span>
                    <span class="info-value">{{ $case->created_at->format('Y-m-d') }}</span>
                </div>
            </div>

            @if($case->clinical_signs)
            <div class="signs-text">
                <strong>العلامات الحيوية:</strong><br>
                {{ $case->clinical_signs }}
            </div>
            @endif

            @if($case->attachment_path)
            <div class="mt-3">
                <span class="info-label mb-2 d-block">الملف المرفق:</span>
                <a href="{{ asset('storage/' . $case->attachment_path) }}" target="_blank">
                    <img src="{{ asset('storage/' . $case->attachment_path) }}" class="attachment-preview" alt="Attachment">
                </a>
            </div>
            @endif
        </div>

        <div class="card-actions">
            <form action="{{ route('doctor.clinical.rare-cases.toggle', $case) }}" method="POST">
                @csrf
                @method('PATCH')
                <button type="submit" class="btn-action btn-status">
                    <i class="fa-solid {{ $case->is_active ? 'fa-eye-slash' : 'fa-eye' }}"></i>
                    {{ $case->is_active ? 'إيقاف الإعلان' : 'تفعيل الإعلان' }}
                </button>
            </form>

            <form action="{{ route('doctor.clinical.rare-cases.destroy', $case) }}" method="POST" onsubmit="return confirm('هل أنت متأكد من حذف هذا الإعلان نهائياً؟')">
                @csrf
                @method('DELETE')
                <button type="submit" class="btn-action btn-delete">
                    <i class="fa-solid fa-trash-can"></i>
                    حذف الإعلان
                </button>
            </form>
        </div>
    </div>
    @endforeach

    <div class="mt-4">
        {{ $cases->links() }}
    </div>
@else
    <div class="text-center py-5 bg-white rounded-4 border">
        <i class="fa-solid fa-magnifying-glass-chart mb-3" style="font-size: 4rem; color: #e2e8f0;"></i>
        <h3 class="text-secondary fw-bold">لا يوجد حالات نادرة معلنة حالياً</h3>
        <p class="text-muted mb-4">أرشد طلابك لأهم الحالات السريرية في المستشفيات عبر هذه الميزة</p>
        <a href="{{ route('doctor.clinical.rare-cases.create') }}" class="btn-create d-inline-flex">إعلان الحالة الأولى</a>
    </div>
@endif
@endsection
