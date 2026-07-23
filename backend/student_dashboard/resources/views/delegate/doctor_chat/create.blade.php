@extends('layouts.delegate')

@section('title', 'محادثة جديدة مع دكتور')

@section('content')

<style>
    .page-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 2rem;
    }

    .page-title {
        font-size: 1.75rem;
        font-weight: 800;
        color: var(--text-primary);
        display: flex;
        align-items: center;
        gap: 0.75rem;
    }

    .back-btn {
        display: flex;
        align-items: center;
        gap: 0.5rem;
        color: var(--text-secondary);
        text-decoration: none;
        font-weight: 600;
        transition: color 0.2s;
    }

    .back-btn:hover {
        color: var(--primary-color);
    }

    .doctors-grid {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
        gap: 1rem;
    }

    .doctor-card {
        background: white;
        border-radius: 16px;
        border: 1px solid #e2e8f0;
        padding: 1.25rem;
        display: flex;
        align-items: center;
        gap: 1rem;
        text-decoration: none;
        color: inherit;
        transition: all 0.2s;
        cursor: pointer;
    }

    .doctor-card:hover {
        border-color: var(--success-color);
        box-shadow: 0 4px 12px -4px rgba(16, 185, 129, 0.2);
        transform: translateY(-2px);
    }

    .doctor-avatar {
        width: 50px;
        height: 50px;
        border-radius: 12px;
        background: linear-gradient(135deg, #dcfce7 0%, #bbf7d0 100%);
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: 700;
        color: #166534;
        font-size: 1.1rem;
        flex-shrink: 0;
    }

    .doctor-info h4 {
        font-weight: 700;
        color: var(--text-primary);
        margin: 0 0 0.25rem 0;
    }

    .doctor-info span {
        font-size: 0.85rem;
        color: var(--text-secondary);
    }

    .start-icon {
        margin-right: auto;
        color: var(--success-color);
        opacity: 0;
        transition: opacity 0.2s;
    }

    .doctor-card:hover .start-icon {
        opacity: 1;
    }

    .empty-state {
        text-align: center;
        padding: 4rem 2rem;
        background: white;
        border-radius: 20px;
        border: 1px solid #e2e8f0;
    }
</style>

<div class="page-header">
    <a href="{{ route('delegate.doctor-chat.index') }}" class="back-btn">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <polyline points="15 18 9 12 15 6"></polyline>
        </svg>
        العودة للمحادثات
    </a>
    <h1 class="page-title">
        <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="color: #10b981;">
            <path d="M22 10v6M2 10l10-5 10 5-10 5z"></path>
            <path d="M6 12v5c3 3 9 3 12 0v-5"></path>
        </svg>
        اختر دكتور للمحادثة
    </h1>
</div>

@if($doctors->count() > 0)
<div class="doctors-grid">
    @foreach($doctors as $doctor)
    <form action="{{ route('delegate.doctor-chat.store') }}" method="POST" style="display: contents;">
        @csrf
        <input type="hidden" name="doctor_id" value="{{ $doctor->id }}">
        <button type="submit" class="doctor-card" style="border: 1px solid #e2e8f0;">
            <div class="doctor-avatar">{{ mb_substr($doctor->name, 0, 1) }}</div>
            <div class="doctor-info">
                <h4>د. {{ $doctor->name }}</h4>
                <span>دكتور</span>
            </div>
            <div class="start-icon">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <line x1="22" y1="2" x2="11" y2="13"></line>
                    <polygon points="22 2 15 22 11 13 2 9 22 2"></polygon>
                </svg>
            </div>
        </button>
    </form>
    @endforeach
</div>
@else
<div class="empty-state">
    <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="color: #cbd5e1; margin-bottom: 1rem;">
        <path d="M22 10v6M2 10l10-5 10 5-10 5z"></path>
        <path d="M6 12v5c3 3 9 3 12 0v-5"></path>
    </svg>
    <h3 style="font-size: 1.25rem; font-weight: 700; margin-bottom: 0.5rem;">لا يوجد دكاترة</h3>
    <p style="color: var(--text-secondary);">لا يوجد دكاترة لمقررات شعبتك حالياً.</p>
</div>
@endif

@endsection