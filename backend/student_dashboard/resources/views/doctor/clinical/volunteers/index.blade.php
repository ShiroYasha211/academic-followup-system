@extends('layouts.doctor')

@section('title', 'سجل المتطوعين السريريين')

@section('content')
<style>
    /* Premium UI Variables - Refined Scale */
    :root {
        --card-radius: 24px;
        --accent-gradient: linear-gradient(135deg, #6366f1 0%, #a855f7 100%);
        --glass-bg: #ffffff;
        --text-main: #0f172a;
        --text-muted: #64748b;
    }

    /* Balanced Grid - Not too wide, not too narrow */
    .volunteers-grid {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
        gap: 1.5rem;
    }

    /* Refined Premium Card */
    .premium-volunteer-card {
        background: var(--glass-bg);
        border: 1px solid #e2e8f0;
        border-radius: var(--card-radius);
        position: relative;
        transition: all 0.5s cubic-bezier(0.16, 1, 0.3, 1);
        display: flex;
        flex-direction: column;
        overflow: hidden;
        box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);
    }

    .premium-volunteer-card:hover {
        transform: translateY(-8px);
        box-shadow: 0 20px 25px -5px rgba(99, 102, 241, 0.1);
        border-color: rgba(99, 102, 241, 0.3);
    }

    /* Smart Status Tag - More compact */
    .status-tag {
        position: absolute;
        top: 15px;
        left: 15px;
        padding: 5px 12px;
        background: #f1f5f9;
        border-radius: 12px;
        display: flex;
        align-items: center;
        gap: 8px;
        z-index: 2;
        border: 1px solid rgba(0,0,0,0.05);
    }

    .status-tag.available { background: #dcfce7; color: #166534; }
    .status-tag.unavailable { background: #f1f5f9; color: #475569; }

    .pulse-dot-small {
        width: 8px;
        height: 8px;
        border-radius: 50%;
        background-color: currentColor;
    }

    .status-tag.available .pulse-dot-small {
        animation: pulseSmall 2s infinite;
    }

    @keyframes pulseSmall {
        0% { transform: scale(0.9); box-shadow: 0 0 0 0 rgba(22, 163, 74, 0.4); }
        70% { transform: scale(1); box-shadow: 0 0 0 6px rgba(22, 163, 74, 0); }
        100% { transform: scale(0.9); box-shadow: 0 0 0 0 rgba(22, 163, 74, 0); }
    }

    .status-label {
        font-size: 0.7rem;
        font-weight: 800;
        text-transform: uppercase;
    }

    /* Optimized Content Area */
    .card-content {
        padding: 2.25rem 1.5rem 1.25rem;
        flex-grow: 1;
    }

    .v-header {
        margin-bottom: 1.25rem;
        margin-top: 1rem;
    }

    .v-name {
        font-size: 1.35rem;
        font-weight: 900;
        color: var(--text-main);
        line-height: 1.2;
        margin-bottom: 0.4rem;
    }

    .v-diagnosis-pill {
        display: inline-flex;
        align-items: center;
        gap: 6px;
        background: #f0f9ff;
        color: #0369a1;
        padding: 4px 10px;
        border-radius: 8px;
        font-size: 0.75rem;
        font-weight: 800;
        border: 1px solid rgba(3, 105, 161, 0.1);
    }

    /* Compact Detail Section */
    .clinical-brief {
        background: #f8fafc;
        padding: 0.85rem 1rem;
        border-radius: 14px;
        margin-bottom: 1.25rem;
        border-right: 3px solid #6366f1;
    }

    .clinical-brief p {
        font-size: 0.85rem;
        font-weight: 700;
        color: #334155;
        line-height: 1.5;
        margin: 0;
    }

    /* Contact Strips - Efficiency First */
    .contact-strips {
        display: flex;
        flex-direction: column;
        gap: 0.75rem;
    }

    .strip-item {
        display: flex;
        align-items: center;
        gap: 10px;
    }

    .strip-icon {
        width: 30px;
        height: 30px;
        background: white;
        border-radius: 8px;
        display: flex;
        align-items: center;
        justify-content: center;
        color: #6366f1;
        font-size: 0.8rem;
        border: 1px solid #e2e8f0;
    }

    .strip-text {
        font-size: 0.85rem;
        font-weight: 700;
        color: #475569;
    }

    /* Refined Integrated Action Deck */
    .card-footer {
        padding: 1.25rem 1.5rem;
        background: #fafafa;
        border-top: 1px solid #f1f5f9;
        display: flex;
        flex-direction: column;
        gap: 1rem;
    }

    .primary-row {
        display: flex;
        gap: 0.75rem;
    }

    .secondary-row {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding-top: 0.75rem;
        border-top: 1px solid #f1f5f9;
    }

    .btn-compact {
        height: 38px;
        border-radius: 10px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: 800;
        font-size: 0.8rem;
        transition: all 0.2s;
        text-decoration: none;
        border: none;
    }

    .btn-call {
        background: #6366f1;
        color: white;
        flex: 1;
        gap: 6px;
    }

    .btn-wa {
        background: #25d366;
        color: white;
        width: 38px; /* Icon only for space */
    }

    .btn-wa:hover, .btn-call:hover { transform: translateY(-2px); box-shadow: 0 4px 12px rgba(0,0,0,0.1); }

    .manage-group {
        display: flex;
        gap: 0.5rem;
    }

    .btn-icon {
        width: 34px;
        height: 34px;
        border-radius: 8px;
        background: white;
        border: 1px solid #e2e8f0;
        color: #64748b;
        display: flex;
        align-items: center;
        justify-content: center;
        transition: all 0.2s;
    }

    .btn-icon:hover { background: #f1f5f9; color: var(--text-main); }
    .btn-icon.edit:hover { color: #f59e0b; border-color: #fcd34d; }
    .btn-icon.delete:hover { color: #ef4444; border-color: #fecaca; }
    .btn-icon.toggle:hover { color: #10b981; border-color: #a7f3d0; }

</style>

<div class="dashboard-header mb-4 d-flex flex-column flex-md-row justify-content-between align-items-md-center gap-3">
    <div class="welcome-text">
        <h1 class="fw-900 mb-1" style="font-size: 1.8rem;">سجل المتطوعين السريريين</h1>
        <p class="text-secondary fw-700 m-0">قاعدة بيانات خاصة وآمنة للمرضى المتطوعين.</p>
    </div>
    <a href="{{ route('doctor.clinical.volunteers.create') }}" class="btn btn-primary px-4 py-3 rounded-4 shadow-sm fw-900 d-flex align-items-center gap-2" style="background: var(--accent-gradient); border: none;">
        <i class="fa-solid fa-plus-circle"></i> إضافة متطوع
    </a>
</div>

<div class="volunteers-grid">
    @forelse($volunteers as $volunteer)
    <div class="premium-volunteer-card">
        <div class="status-tag {{ $volunteer->is_available ? 'available' : 'unavailable' }}">
            <span class="pulse-dot-small"></span>
            <span class="status-label">{{ $volunteer->is_available ? 'متاح' : 'غير متاح' }}</span>
        </div>

        <div class="card-content">
            <div class="v-header">
                <h3 class="v-name">{{ $volunteer->name }}</h3>
                <div class="v-diagnosis-pill">
                    <i class="fa-solid fa-notes-medical"></i>
                    {{ $volunteer->diagnosis }}
                </div>
            </div>

            <div class="clinical-brief">
                <p>{{ Str::limit($volunteer->clinical_signs ?? 'لا ملاحظات سريرية.', 75) }}</p>
            </div>

            <div class="contact-strips">
                <div class="strip-item">
                    <div class="strip-icon"><i class="fa-solid fa-phone"></i></div>
                    <span class="strip-text">{{ $volunteer->contact_info }}</span>
                </div>
                @if($volunteer->phone_secondary)
                <div class="strip-item">
                    <div class="strip-icon"><i class="fa-solid fa-mobile-button"></i></div>
                    <span class="strip-text">{{ $volunteer->phone_secondary }}</span>
                </div>
                @endif
                @if($volunteer->email)
                <div class="strip-item">
                    <div class="strip-icon"><i class="fa-solid fa-at"></i></div>
                    <span class="strip-text" title="{{ $volunteer->email }}">{{ Str::limit($volunteer->email, 22) }}</span>
                </div>
                @endif
            </div>
        </div>

        <div class="card-footer">
            <div class="primary-row">
                <a href="tel:{{ $volunteer->contact_info }}" class="btn-compact btn-call">
                    <i class="fa-solid fa-phone-flip"></i> اتصال سريع
                </a>
                <a href="https://wa.me/{{ preg_replace('/[^0-9]/', '', $volunteer->contact_info) }}" target="_blank" class="btn-compact btn-wa" title="واتساب الأساسي">
                    <i class="fa-brands fa-whatsapp"></i>
                </a>
                @if($volunteer->phone_secondary)
                <a href="https://wa.me/{{ preg_replace('/[^0-9]/', '', $volunteer->phone_secondary) }}" target="_blank" class="btn-compact btn-wa" title="واتساب الإضافي" style="background: #128c7e;">
                    <i class="fa-brands fa-whatsapp"></i>
                </a>
                @endif
            </div>

            <div class="secondary-row">
                <div class="email-action">
                    @if($volunteer->email)
                    <a href="mailto:{{ $volunteer->email }}" class="btn-icon" title="إرسال إيميل"><i class="fa-solid fa-paper-plane"></i></a>
                    @endif
                </div>

                <div class="manage-group">
                    <form action="{{ route('doctor.clinical.volunteers.toggle', $volunteer->id) }}" method="POST">
                        @csrf @method('PATCH')
                        <button type="submit" class="btn-icon toggle" title="تغيير التوفر">
                            <i class="fa-solid {{ $volunteer->is_available ? 'fa-eye-slash' : 'fa-eye' }}"></i>
                        </button>
                    </form>
                    <a href="{{ route('doctor.clinical.volunteers.edit', $volunteer->id) }}" class="btn-icon edit" title="تعديل"><i class="fa-solid fa-pen-to-square"></i></a>
                    <form action="{{ route('doctor.clinical.volunteers.destroy', $volunteer->id) }}" method="POST" onsubmit="return confirm('حذف المتطوع؟')">
                        @csrf @method('DELETE')
                        <button type="submit" class="btn-icon delete" title="حذف"><i class="fa-solid fa-trash-can"></i></button>
                    </form>
                </div>
            </div>
        </div>
    </div>
    @empty
    <div class="col-12 text-center py-5">
        <p class="text-secondary fw-800">لا يوجد متطوعين حالياً في سجلك الخاص.</p>
        <a href="{{ route('doctor.clinical.volunteers.create') }}" class="btn btn-primary px-4 py-2 rounded-3">إضافة أول متطوع</a>
    </div>
    @endforelse
</div>

<div class="mt-4 d-flex justify-content-center">
    {{ $volunteers->links() }}
</div>
@endsection
